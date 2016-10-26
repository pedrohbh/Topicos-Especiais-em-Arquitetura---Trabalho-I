#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <locale.h>


void multiplicacaoMatrizFloat( float *m, float *n, float *p, int tamanho )
{
	int i;
	int j;
	int k;
	for ( i = 0; i < tamanho; ++i )
		for ( j = 0; j < tamanho; ++j )
		{
			float soma = 0;
			for ( k = 0; k < tamanho; ++k )
			{
				float a = m[ i * tamanho + k ];
				float b = n[ k * tamanho + j ];
				soma += a * b;
			}
			p[ i * tamanho + j ] = soma;
		}
}

void multiplicacaoMatrizDouble( double *m, double *n, double *p, int tamanho )
{
	int i;
	int j;
	int k;
	for ( i = 0; i < tamanho; ++i )
		for ( j = 0; j < tamanho; ++j )
		{
			double soma = 0;
			for ( k = 0; k < tamanho; ++k )
			{
				double a = m[ i * tamanho + k ];
				double b = n[ k * tamanho + j ];
				soma += a * b;
			}
			p[ i * tamanho + j ] = soma;
		}
}

void geraMatrizDefaultFloat( float *m, float *n, int tamanho )
{
	int i = 0;
	int j = 0;

	for ( i = 0; i < tamanho; ++i )
	{
		for ( j = 0; j < tamanho; ++j )
		{
			m[ i*tamanho + j ] = 4;
			n[ i*tamanho + j ] = 5;
		}

	}

}

void geraMatrizDefaultDouble( double *m, double *n, int tamanho )
{
	int i = 0;
	int j = 0;

	for ( i = 0; i < tamanho; ++i )
	{
		for ( j = 0; j < tamanho; ++j )
		{
			m[ i*tamanho + j ] = 4;
			n[ i*tamanho + j ] = 5;
		}

	}

}

void imprimeMatrizFloat( float *a, int tamanho )
{
	int i = 0;
	int j = 0;

	for ( i = 0; i < tamanho; ++i )
	{
		for ( j = 0; j < tamanho; ++j )
		{
			printf("%.2f ", a[ i*tamanho + j ]);
		}
		printf("\n");

	}
}

void imprimeMatrizDouble( double *a, int tamanho )
{
	int i = 0;
	int j = 0;

	for ( i = 0; i < tamanho; ++i )
	{
		for ( j = 0; j < tamanho; ++j )
		{
			printf("%.2lf ", a[ i * tamanho + j ]);
		}
		printf("\n");

	}
}


void criaMatrizesDouble( double **m, double **n, double **p, int tamanho )
{
	int N = tamanho * tamanho;
	(*m) = (double *)malloc( sizeof( double ) * N );
	(*n) = (double *)malloc( sizeof( double ) * N );
	(*p) = (double *)malloc( sizeof( double ) * N );
	if ( m == NULL || n == NULL || p == NULL )
	{
		puts("Erro ao alocar as matrizes");
		exit( 1 );
	}
}

void criaMatrizesFloat( float **m, float **n, float **p, int tamanho )
{
	int N = tamanho * tamanho;
	(*m) = (float *)malloc( sizeof( float ) * N );
	(*n) = (float *)malloc( sizeof( float ) * N );
	(*p) = (float *)malloc( sizeof( float ) * N );
	if ( m == NULL || n == NULL || p == NULL )
	{
		puts("Erro ao alocar as matrizes");
		exit( 1 );
	}
}

void geraMatrizesFloatRandomico( float *m, float *n, int tamanho )
{
	int i = 0;
	int j = 0;
	srand( time( 0 ) );

	for ( i = 0; i < tamanho; ++i )
	{
		for ( j = 0; j < tamanho; ++j )
		{
			m[ i*tamanho + j ] = (rand() % 1001) / (float)1000;
			n[ i*tamanho + j ] = (rand() % 1001) / (float)1000;
		}

	}

}

FILE *abreArquivo( char *nomeArquivo )
{
	FILE *novoArquivo = fopen( nomeArquivo, "w" );
	if ( novoArquivo == NULL )
	{
		puts("Erro ao abrir/criar o arquivo de entrada");
		exit( 1 );
	}
	fprintf(novoArquivo, "Tamanho;Tempo Total(s)\n");
	return novoArquivo;
}

void escreveResultadoArquivo( FILE *arquivo, int tamanho, double tempo )
{
	setlocale(LC_NUMERIC, "");
	fprintf( arquivo, "%d;%lf\n", tamanho, tempo );
}

void testesSerialFloat()
{
	float *m = NULL;
	float *n = NULL;
	float *p = NULL;
	clock_t tempoInicial;
	clock_t tempoFinal;
	double tempoDecorrido;
	
	int i;
	int j;
	int tamanhoMatriz;
	FILE *arquivoEntrada = abreArquivo( "ResultadosSerialFloat.txt" );
	
	for ( i = 10; i <= 100; i += 10 )
	{
		tempoDecorrido = 0;
		tamanhoMatriz = i;
		criaMatrizesFloat( &m, &n, &p, tamanhoMatriz );
		geraMatrizesFloatRandomico( m, n,  tamanhoMatriz );
		for ( j = 0; j < 3; ++j )
		{
			tempoInicial = clock();
			multiplicacaoMatrizFloat( m, n, p, tamanhoMatriz );
			tempoFinal = clock();
			tempoDecorrido += (double)(tempoFinal - tempoInicial) / CLOCKS_PER_SEC;
		}
		tempoDecorrido /= 3;
		escreveResultadoArquivo( arquivoEntrada, tamanhoMatriz, tempoDecorrido );
		free( m );
		free( n );
		free( p );	
		
		
	}
	fclose(arquivoEntrada);

}

void testesSerialDouble();

int main( int argc, char *argv[] )
{
	testesSerialFloat();
	/*int tamanho;
	float *m = NULL;
	float *n = NULL;
	float *p = NULL;
	/*double *m = NULL;
	double *n = NULL;
	double *p = NULL;
	
	if ( argc < 2 )
	{
		tamanho = 1000;
	}
	else
	{
		tamanho = atoi( argv[ 1 ] );
	}
	
	criaMatrizesFloat( &m, &n, &p, tamanho );
	//geraMatrizDefaultFloat( m, n, tamanho );
	geraMatrizesFloatRandomico( m, n, tamanho );
	//imprimeMatrizFloat( p, tamanho );
	multiplicacaoMatrizFloat( m, n, p, tamanho );

	/*criaMatrizesDouble( &m, &n, &p, tamanho );
	geraMatrizDefaultDouble( m, n, tamanho );
	multiplicacaoMatrizDouble( m, n, p, tamanho );	

	imprimeMatrizDouble( m, tamanho );
	printf("------------------------------------\n\n");
	imprimeMatrizDouble( n, tamanho );
	printf("------------------------------------\n\n");
	imprimeMatrizDouble( p, tamanho );
	
	imprimeMatrizFloat( m, tamanho );
	printf("------------------------------------\n\n");
	imprimeMatrizFloat( n, tamanho );
	printf("------------------------------------\n\n");
	imprimeMatrizFloat( p, tamanho );*/
	return 0;
}
