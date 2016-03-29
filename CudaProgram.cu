#include <stdio.h>
#include <curand.h>
//#include <curand_kernel.h>
#include <time.h>
#include <stdlib.h>
#include <math.h>
#include "qdbmp.h"
#include "qdbmp.c"


__global__
void process (int *tabela, int*output, int* random, int vrsta, int pixlov) {
	//__shared__ int block[2*vrsta*3];
	int sosedi[3][4];
	int stBarv=-1;
	int	x =  blockIdx.x*blockDim.x + threadIdx.x;

	if((x-3)>=0){
		/* Preberemo RGB vrednosti x-1, y pike */
		stBarv++;
		sosedi[stBarv][0]= tabela[x-3];
		sosedi[stBarv][1]= tabela[x-2];
		sosedi[stBarv][2]= tabela[x-1];
	}
				
	if((x-(vrsta*3))>=0){
		stBarv++;
		sosedi[stBarv][0]= tabela[x-(vrsta*3)];
		sosedi[stBarv][1]= tabela[x+1-(vrsta*3)];
		sosedi[stBarv][2]= tabela[x+2-(vrsta*3)];
	}

	if((x+3) < pixlov){
		stBarv++;
		sosedi[stBarv][0]= tabela[x+3];
		sosedi[stBarv][1]= tabela[x+4];
		sosedi[stBarv][2]= tabela[x+5];
	}

	if((x+(vrsta*3)) < pixlov){
		stBarv++;
		sosedi[stBarv][0]= tabela[x+(vrsta*3)];
		sosedi[stBarv][1]= tabela[x+1+(vrsta*3)];
		sosedi[stBarv][2]= tabela[x+2+(vrsta*3)];
	}
	
	
	int ran = random[x];
	output[x] = sosedi[ran][0];
	output[x+1] = sosedi[ran][1];
	output[x+2] = sosedi[ran][2];


	}

int main(int argc, char* argv[]) {

	double diff = 0.0;
	time_t start;
    time_t stop;
    time(&start);


	BMP* bmp;
	BMP* nova;
	unsigned char r, g, b; 
	int width, height; 
	int x, y; 

	/* Preverimo, če je število vnešenih argumentov pravilno */
	if ( argc != 3 )
	{
		fprintf( stderr, "Uporaba: %s <vhodna slika> <izhodna slika>",
			argv[ 0 ] );
		return 0;
	}

	bmp = BMP_ReadFile( argv[ 1 ] );
	//BMP_CHECK_ERROR( stderr, -1 );
	
	width = BMP_GetWidth( bmp );
	height = BMP_GetHeight( bmp );

	srand ( time(NULL) );

	// alociranje pomnilnika
	int *tabela1D;
	int *rezultat;
	int *random;
	int *cudaRandom;
	int *cudaInput;
	int *cudaOutput;

	tabela1D = (int*)malloc(width*height*3*sizeof(int));
	rezultat = (int*)malloc(width*height*3*sizeof(int));
	random = (int*)malloc(width*height*3*sizeof(int));
	cudaMalloc(&cudaRandom, width*height*sizeof(int));
	cudaMalloc(&cudaOutput, width*height*3*sizeof(int));
	cudaMalloc(&cudaInput, width*height*3*sizeof(int));

	//preberi RGB vrednosti vsakega pixla na sliki v 1D tabelo
	for(y = 0; y < height; y++) {
		for(x = 0; x < width; x++) {
			BMP_GetPixelRGB( bmp, x, y, &r, &g, &b );
			// printf("%u %u %u\n", r, g, b);
			// printf("-> %d %d %d\n", (int)r, (int)g, (int)b);
			tabela1D[y*width+x*3] = (int)r;
			tabela1D[y*width+x*3+1] = (int)g;
			tabela1D[y*width+x*3+2] = (int)b;
			random[y*width+x] = rand()%4;
			//printf("%d, %d, %d\n", y*width+x*3, y*width+x*3+1, y*width+x*3+2);
		}
	}

	cudaMemcpy(cudaInput, tabela1D, width*height*3*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(cudaRandom, random, width*height*sizeof(int), cudaMemcpyHostToDevice);




	process<<<height , width*3>>>(cudaInput, cudaOutput, cudaRandom, width, width*height);

	cudaMemcpy(rezultat, cudaOutput, width*height*3*sizeof(int), cudaMemcpyDeviceToHost);


	nova = BMP_Create(width, height, 24);

	for(y = 0; y < height; y++) {
		for(x = 0; x < width; x++) {
			BMP_SetPixelRGB(nova, x, y, (unsigned char)rezultat[y*width+x*3], 
										(unsigned char)rezultat[y*width+x*3+1], 
										(unsigned char)rezultat[y*width+x*3+2]);
		}
	}

	BMP_WriteFile(nova, argv[2]);
	BMP_CHECK_ERROR(stdout, -2);

	free(tabela1D);
	free(random);
	cudaFree(cudaRandom);
	cudaFree(cudaInput);
	cudaFree(cudaOutput);

	time(&stop);
  	diff = difftime(stop, start);
  	printf("Runtime: %g\n", diff);

	return 0;
}