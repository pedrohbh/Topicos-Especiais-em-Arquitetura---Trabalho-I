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
	multiplicacaoMatrizFloat( m, n, p, tamanho );
	
	return 0;
}
