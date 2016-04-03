#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <math.h>
#include "qdbmp.h"
#include "qdbmp.c"


__global__
void process (int *tabela, int*output, int* random, int vrsta, int pixlov, int offset) {
	int sosedi[3][4];
	int stBarv=-1;
	// x - index pixla -> Blok(vrsta) * število niti v bloku(širina) + zaporedna nit v vrsti
	int	x =  blockIdx.x*blockDim.x*3 + threadIdx.x*3;

	//sinhronizacija niti - verjentu nepotrebna
	__syncthreads();

	// Iskanje levega pixla
	if((x % (vrsta * 3)) != 0){
		stBarv++;
		sosedi[0][stBarv]= tabela[x-3];
		sosedi[1][stBarv]= tabela[x-2];
		sosedi[2][stBarv]= tabela[x-1];
	}

	// Iskanje zgornjega pixla
	if(x >= (vrsta * 3)){
		stBarv++;
		sosedi[0][stBarv]= tabela[x-(vrsta*3)];
		sosedi[1][stBarv]= tabela[x+1-(vrsta*3)];
		sosedi[2][stBarv]= tabela[x+2-(vrsta*3)];
	}

	// Iskanje desnega pixla
	//if( (x == 0) || (x % ((vrsta)*3) != (vrsta-1)*3)){
	if (((x + 3) % (vrsta * 3)) != 0) {
		stBarv++;
		sosedi[0][stBarv]= tabela[x+3];
		sosedi[1][stBarv]= tabela[x+4];
		sosedi[2][stBarv]= tabela[x+5];
	}

	// Iskanje spodnjega pixla
	//if(x < ((pixlov * 3) - (vrsta * 3))){
	if (x < ((vrsta - 1) * (vrsta * 3))) {
		stBarv++;
		sosedi[0][stBarv]= tabela[x+(vrsta*3)];
		sosedi[1][stBarv]= tabela[x+1+(vrsta*3)];
		sosedi[2][stBarv]= tabela[x+2+(vrsta*3)];
	}

	// če je index na intervalu slike v tabeli - zaradi Cude treba baje prevert da ne uzame krnek
	if(x < pixlov*3) {
		// random int iz tabele, vzamemo i-ti element (index pixla) + offset, da ni vedno isti random na pixlu
		int ran = random[blockIdx.x*blockDim.x + threadIdx.x + offset]%(stBarv+1);
		output[x] = sosedi[0][ran];
		output[x+1] = sosedi[1][ran];
		output[x+2] = sosedi[2][ran];
		//printf("%d\n", ran);

		// Izpis za debuggiranje
		/*printf("pixel: (%d, %d) r:%d sosedi: %d ->  [%d %d %d; %d %d %d; %d %d %d; %d %d %d] -> [%d %d %d]\n", blockIdx.x*blockDim.x, threadIdx.x, ran, stBarv+1,
			sosedi[0][0], sosedi[1][0], sosedi[2][0], sosedi[0][1], sosedi[1][1], sosedi[2][1],
			sosedi[0][2], sosedi[1][2], sosedi[2][2], sosedi[0][3], sosedi[1][3], sosedi[2][3],
			output[x], output[x+1], output[x+2]);
		*/
	}

}

int main(int argc, char* argv[]) {

	// Štoparica
	double diff = 0.0;
	time_t start;
    time_t stop;
    time(&start);


	BMP* bmp;
	BMP* nova;
	unsigned char r, g, b;
	int width, height;
	int x, y;

	printf("Vnesi stevilo iteraciji na GPU:\n");
	long cudaIteracije;
	scanf("%ld", &cudaIteracije);

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
	cudaMalloc(&cudaRandom, (cudaIteracije+width*height)*sizeof(int));
	cudaMalloc(&cudaOutput, width*height*3*sizeof(int));
	cudaMalloc(&cudaInput, width*height*3*sizeof(int));

	//preberi RGB vrednosti vsakega pixla na sliki v 1D tabelo
	int j=0;
	for(y = 0; y < height; y++) {
		for(x = 0; x < width; x++) {
			BMP_GetPixelRGB( bmp, x, y, &r, &g, &b );
			/*printf("%d) %u %u %u\n", j, r, g, b);
			j+=3;*/
			tabela1D[y*width*3+x*3] = (int)r;
			tabela1D[y*width*3+x*3+1] = (int)g;
			tabela1D[y*width*3+x*3+2] = (int)b;
		}
	}

	// Generiranje random intov v tabelo, ki jo poščjemo na gpu
	for(j = 0; j < height*width+cudaIteracije; j++) {
		random[j] = rand();
	}

	//prenos podatkov iz Hosta na GPU
	cudaMemcpy(cudaInput, tabela1D, width*height*3*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(cudaRandom, random, (cudaIteracije + width*height)*sizeof(int), cudaMemcpyHostToDevice);


	long i = 0;
	char name[64];
	char datoteka[64];
	int counter = 1;

	// Klicanje glavne metode v zanki
	for(i = 0; i < cudaIteracije; i++) {
		//printf("iteracija: %d\n", i+1);
		process<<<height, width>>>(cudaInput, cudaOutput, cudaRandom, width, width*height, i);

		// Prenesemo generirano sliko iz GPU na Host in jo nazaj pošjemo kot izvirno sliko
		cudaMemcpy(rezultat, cudaOutput, width*height*3*sizeof(int), cudaMemcpyDeviceToHost);
		cudaMemcpy(cudaInput, rezultat, width*height*3*sizeof(int), cudaMemcpyHostToDevice);
		/*j = 0;
		for(x = 0; x < height*width*3; x++) {
			printf("%d ", rezultat[x]);
			j++;
			if(j == 3) {
				j = 0;
				printf("\n");
			}
		}
		printf("------------------------\n");*/

		// Shranimo vsako 5 sliko v mapo Izhodi
		if(i != 0 && i%5 == 0 ) {
			nova = BMP_Create(width, height, 24);
			for(y = 0; y < height; y++) {
				for(x = 0; x < width; x++) {
					BMP_SetPixelRGB(nova, x, y, (unsigned char)rezultat[y*width*3+x*3],
												(unsigned char)rezultat[y*width*3+x*3+1],
												(unsigned char)rezultat[y*width*3+x*3+2]);
				}
			}

			strcpy(name, "Vojne/izhodi/");
			sprintf(datoteka, "%d", i);
			strcat(name, datoteka);
			strcat(name, ".bmp");

			BMP_WriteFile( nova, name);
			}
	}

	//Shranjevanje zadnje slike - nepotrebno, če shranjujemo sproti
	/*cudaMemcpy(rezultat, cudaOutput, width*height*3*sizeof(int), cudaMemcpyDeviceToHost);


	nova = BMP_Create(width, height, 24);


	for(y = 0; y < height; y++) {
		for(x = 0; x < width; x++) {
			BMP_SetPixelRGB(nova, x, y, (unsigned char)rezultat[y*width*3+x*3],
										(unsigned char)rezultat[y*width*3+x*3+1],
										(unsigned char)rezultat[y*width*3+x*3+2]);
		}
	}

	BMP_WriteFile(nova, argv[2]);
	BMP_CHECK_ERROR(stdout, -2);*/

	// Sprostimo pomnilnik
	free(tabela1D);
	free(random);
	cudaFree(cudaRandom);
	cudaFree(cudaInput);
	cudaFree(cudaOutput);

	// Ustavimo štoparico
	time(&stop);
  	diff = difftime(stop, start);
  	printf("Runtime: %g\n", diff);

	return 0;
}