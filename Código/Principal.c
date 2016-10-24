#include <stdio.h>
#include <stdlib.h>


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

void geraMatrizDefault( float *m, float *n, int tamanho )
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

void imprimeMatriz( float *a, int tamanho )
{
	int i = 0;
	int j = 0;

	for ( i = 0; i < tamanho; ++i )
	{
		for ( j = 0; j < tamanho; ++j )
		{
			printf("%.2f ", a[ i + j ]);
		}
		printf("\n");

	}

	

}

void criaMatrizesFloat( float **m, float **n, float **p, int tamanho )
{
	int N = tamanho * tamanho;
	(*m) = (float *)malloc( sizeof( float ) * N );
	(*n) = (float *)malloc( sizeof( float ) * N );
	(*p) = (float *)malloc( sizeof( float ) * N );
}

int main( int argc, char *argv[] )
{
	int tamanho;
	float *m = NULL;
	float *n = NULL;
	float *p = NULL;
	if ( argc < 2 )
	{
		tamanho = 1000;
	}
	else
	{
		tamanho = atoi( argv[ 1 ] );
	}
	
	criaMatrizesFloat( &m, &n, &p, tamanho );
	geraMatrizDefault( m, n, tamanho );
	multiplicacaoMatrizFloat( m, n, p, tamanho );
	imprimeMatriz( m, tamanho );
	printf("------------------------------------\n\n");
	imprimeMatriz( n, tamanho );
	printf("------------------------------------\n\n");
	imprimeMatriz( p, tamanho );	
	return 0;
}
