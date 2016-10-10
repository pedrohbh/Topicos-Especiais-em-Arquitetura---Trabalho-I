#include <stdio.h>


void multiplicacaoMatrixFloat( float *m, float *n, float *p, int tamanho )
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


int main()
{

	return 0;
}
