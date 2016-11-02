// System includes
#include <stdio.h>
#include <assert.h>
#include <time.h>

int qtdite = 1;

// CUDA runtime
#include <cuda_runtime.h>

// Helper functions and utilities to work with CUDA
#include <helper_functions.h>


typedef struct {
    int width;
    int height;
    int stride; 
    double* elements;
} Matrix;

// Get a matrix element
__device__ double GetElement(const Matrix A, int row, int col)
{
    return A.elements[row * A.stride + col];
}

// Set a matrix element
__device__ void SetElement(Matrix A, int row, int col,
                           double value)
{
    A.elements[row * A.stride + col] = value;
}

// tamanho do bloco de thread
#define BLOCK_SIZE 32

// Get the BLOCK_SIZExBLOCK_SIZE sub-matrix Asub of A that is
// located col sub-matrices to the right and row sub-matrices down
// from the upper-left corner of A
 __device__ Matrix GetSubMatrix(Matrix A, int row, int col) 
{
    Matrix Asub;
    Asub.width    = BLOCK_SIZE;
    Asub.height   = BLOCK_SIZE;
    Asub.stride   = A.stride;
    Asub.elements = &A.elements[A.stride * BLOCK_SIZE * row
                                         + BLOCK_SIZE * col];
    return Asub;
}



// Forward declaration of the matrix multiplication kernel
__global__ void MatMulKernel(const Matrix, const Matrix, Matrix);

// Matrix multiplication - Host code
// Matrix dimensions are assumed to be multiples of BLOCK_SIZE
void MatMul(const Matrix A, const Matrix B, Matrix C)
{
    // Load A and B to device memory
    Matrix d_A;

    d_A.width  = d_A.stride = A.width; d_A.height = A.height;
    size_t size = A.width * A.height * sizeof(double);

     cudaError_t error;
    error = cudaMalloc(&d_A.elements, size);

    //testa se a matriz conseguiu ser alocada na memoria
    if (error != cudaSuccess)
    {
        printf("falha ao alocar a memoria da matriz. (code %d), line(%d)\n",  error, __LINE__);
        exit(EXIT_FAILURE);
    }

    error = cudaMemcpy(d_A.elements, A.elements, size, cudaMemcpyHostToDevice);

    if (error != cudaSuccess)
    {
        printf("falha ao copia a matriz para a GPU  (code %d), line(%d)\n", error,  __LINE__);
        exit(EXIT_FAILURE);
    }

    Matrix d_B;
    d_B.width = d_B.stride = B.width; d_B.height = B.height;
    size = B.width * B.height * sizeof(double);

    error = cudaMalloc(&d_B.elements, size);
    if (error != cudaSuccess)
    {
        printf("erro ao locar a memoria na GPU  (code %d), line(%d)\n", error,  __LINE__);
        exit(EXIT_FAILURE);
    }

    error= cudaMemcpy(d_B.elements, B.elements, size, cudaMemcpyHostToDevice);
    if (error != cudaSuccess)
    {
        printf("falha ao alocar a memoria da matriz  (code %d), line(%d)\n", error,  __LINE__);
        exit(EXIT_FAILURE);
    }

    // Allocate C in device memory
    Matrix d_C;
    d_C.width = d_C.stride = C.width; d_C.height = C.height;
    size = C.width * C.height * sizeof(double);
    cudaMalloc(&d_C.elements, size);

    // Invoke kernel
    // O tipo dim3 'e usado pelo Cuda para definir a estrutura das threads e dos blocos

    dim3 dimBlock(BLOCK_SIZE, BLOCK_SIZE,1);
    dim3 dimGrid(B.width / dimBlock.x, A.height / dimBlock.y);

    /// declara as avriaveis para medir o tempo em CUDA
    cudaEvent_t start,stop;

    //declara variaveis do tempo em C
//    clock_t tinicial,tfinal;

    error = cudaEventCreate(&start);
    error = cudaEventCreate(&stop);
    if (error != cudaSuccess)
    {
        printf("Erro ao startar o evento\n");
        exit(EXIT_FAILURE);
    }

    //inicia
    error = cudaEventRecord(start, NULL);

//    tinicial = clock();

    for (int t=0; t<qtdite; ++t)
    {
      // printf("executando a iteracao %d\n",t);
       MatMulKernel<<<dimGrid, dimBlock>>>(d_A, d_B, d_C);
    }


    // Wait for the stop event to complete

    error = cudaEventRecord(stop, NULL);

    error = cudaEventSynchronize(stop);

    if (error != cudaSuccess)
    {
        printf("erro ao startar o evento\n");
        exit(EXIT_FAILURE);
    }

    float msecTotal = 0.0f;
    error = cudaEventElapsedTime(&msecTotal, start, stop);
//    tfinal = clock();
//    double tempoemC = (double)((tfinal - tinicial) / CLOCKS_PER_SEC);
//    double tempoemC = (double)((tfinal - tinicial) );

    error = cudaEventDestroy(start);
    error = cudaEventDestroy(stop);


// Compute and print the performance
    double  msectotal        = msecTotal;
    double msecPerMatrixMul  = msecTotal /qtdite;
    double flopsPerMatrixMul = 2.0 * (double)A.height * (double)A.width * (double)B.height;
    double gigaFlops = (flopsPerMatrixMul * 1.0e-9f) / (msecPerMatrixMul / 1000.0f);
    printf("\e[H\e[2J");
    printf("                        ************ Resultados *****************\n\n");
    printf("Tamanho da matriz utilizada.............= (%i) x (%i) \n",d_A.width,d_A.width);
    printf("Tamanho do bloco theads e ladrilho......= (32 x 32)\n");
    printf("Numero de iteracoes executadas..........= %i \n\n",qtdite);
    printf("Performance ............................= %.2f GFlop/s \n",gigaFlops);
    printf("Tempo Total (Pelo cudaEventElapsedTime) = %.4f segundos \n\n\n",msectotal/1000);



    // Read C from device memory
    cudaMemcpy(C.elements, d_C.elements, size, cudaMemcpyDeviceToHost);

    // Free device memory
    cudaFree(d_A.elements);
    cudaFree(d_B.elements);
    cudaFree(d_C.elements);
}

// Matrix multiplication kernel called by MatMul()
 __global__ void MatMulKernel(Matrix A, Matrix B, Matrix C)
{
    // Block row and column
    int blockRow = blockIdx.y;
    int blockCol = blockIdx.x;

    // Each thread block computes one sub-matrix Csub of C
    Matrix Csub = GetSubMatrix(C, blockRow, blockCol);

    // Each thread computes one element of Csub
    // by accumulating results into Cvalue
    double Cvalue = 0;

    // Thread row and column within Csub
    int row = threadIdx.y;
    int col = threadIdx.x;

    // Loop over all the sub-matrices of A and B that are
    // required to compute Csub
    // Multiply each pair of sub-matrices together
    // and accumulate the results

//#pragma unroll 2

    for (int m = 0; m < (A.width / BLOCK_SIZE); ++m) 
      {

        // Get sub-matrix Asub of A
        Matrix Asub = GetSubMatrix(A, blockRow, m);

        // Get sub-matrix Bsub of B
        Matrix Bsub = GetSubMatrix(B, m, blockCol);

        // Shared memory used to store Asub and Bsub respectively
        __shared__ double As[BLOCK_SIZE][BLOCK_SIZE];
        __shared__ double Bs[BLOCK_SIZE][BLOCK_SIZE];

        // Load Asub and Bsub from device memory to shared memory
        // Each thread loads one element of each sub-matrix
        As[row][col] = GetElement(Asub, row, col);
        Bs[row][col] = GetElement(Bsub, row, col);

        // para esperar todas as threads terminarem o processamento
        __syncthreads();

        // Multiply Asub and Bsub together

//#pragma unroll 
        for (int e = 0; e < BLOCK_SIZE; ++e)
            Cvalue += As[row][e] * Bs[e][col];

        // Synchronize to make sure that the preceding
        // computation is done before loading two new
        // sub-matrices of A and B in the next iteration
        __syncthreads();
    }

    // Write Csub to device memory
    // Each thread writes one element
    SetElement(Csub, row, col, Cvalue);
}

/**
 * Program main
 */

int main(int argc, char **argv)
{
   Matrix A, B, C;
 
    if (checkCmdLineFlag(argc, (const char **)argv, "help") ||
        checkCmdLineFlag(argc, (const char **)argv, "?"))
    {
        // usa sempre matrizes quadraticas do mesmo tamanho
        printf("Use   -pla= \n");
        printf("      -tam= tamanho da matriz\n");
        printf("      -qtd= qtd de interacao\n");
        exit(EXIT_SUCCESS);
    }

    // define os valores default
    int tammatriz = 512; //tamanho padrao

    // By default, we use device 0, otherwise we override the device ID based on what is provided at the command line
    int devID = 0;

    if (checkCmdLineFlag(argc, (const char **)argv, "device"))
    {
        devID = getCmdLineArgumentInt(argc, (const char **)argv, "device");
        cudaSetDevice(devID);
    }

    cudaError_t error;
    cudaDeviceProp deviceProp;
    error = cudaGetDevice(&devID);

    if (error != cudaSuccess)
    {
        printf("cudaGetDevice returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
    }

    error = cudaGetDeviceProperties(&deviceProp, devID);

    if (deviceProp.computeMode == cudaComputeModeProhibited)
    {
        fprintf(stderr, "Error: device is running in <Compute Mode Prohibited>, no threads can use ::cudaSetDevice().\n");
        exit(EXIT_SUCCESS);
    }

    if (error != cudaSuccess)
    {
        printf("cudaGetDeviceProperties returned error %s (code %d), line(%d)\n", cudaGetErrorString(error), error, __LINE__);
    }
    else
    {
        printf("\n\nGPU Device %d: \"%s\" with compute capability %d.%d\n", devID, deviceProp.name, deviceProp.major, deviceProp.minor);
    }

    // tamanho matrizes
    if (checkCmdLineFlag(argc, (const char **)argv, "tam"))
    {
      tammatriz = getCmdLineArgumentInt(argc, (const char **)argv, "tam");
    }

    
    if (checkCmdLineFlag(argc, (const char **)argv, "qtd"))
    {
      qtdite = getCmdLineArgumentInt(argc, (const char **)argv, "qtd");
    }


   A.height = tammatriz;
   A.width  = tammatriz;
   A.elements = (double*)malloc(A.width * A.height * sizeof(double));

    //testa se a matriz conseguiu ser alocada na memoria do host
//    if (A = NULL)
//    {
//        fprintf(stderr, "Failed to allocate host matrix C!\n");
//        exit(EXIT_FAILURE);
//    }

   B.height = tammatriz;
   B.width = tammatriz;
   B.elements = (double*)malloc(B.width * B.height * sizeof(double));
   C.height = A.height;
   C.width = B.width;
   C.elements = (double*)malloc(C.width * C.height * sizeof(double));


//   preenche a matriz
   for(int i = 0; i < A.height; i++)
   {
     for(int j = 0; j < A.width; j++)
        A.elements[i*A.width + j] = -0.01f;
   }

   for(int i = 0; i < B.height; i++)
   {   for(int j = 0; j < B.width; j++)
        B.elements[i*B.width + j] = 0.02f;
   }


   MatMul(A, B, C);


//   for(int i = 0; i <  A.height; i++)
//   {
//    for(int j = 0; j <  A.width; j++)
//      printf("%f ", A.elements[i*A.width + j]);
//      printf("\n");
//   }

//   printf("\n");
//   for(int i = 0; i <  B.height; i++)
//   {
//     for(int j = 0; j < B.width; j++)
//      printf("%f ", B.elements[i*B.width + j]);
//      printf("\n");
//    }
//   printf("\n");

//   for(int i = 0; i <  C.height; i++)
//   {
//    for(int j = 0; j <  C.width; j++)
//     printf("%f ", C.elements[i*C.width + j]);
//      printf("\n");
//    }
//     printf("\n");


}
