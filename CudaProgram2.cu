
#include <stdio.h>
#include <time.h>
#include <stdlib.h>
#include <math.h>
#include "qdbmp.h"
#include "qdbmp.c"


__global__
void process (int *tabela, int* random, int vrsta, int pixlov, int randOffset) {
	int sosedi[3][4];	
	int stBarv=-1;
	long zamik = pixlov*3 * randOffset;
	// x - index pixla -> Blok(vrsta) * število niti v bloku(širina) + zaporedna nit v vrsti
	long	x =  blockIdx.x*blockDim.x*3 + threadIdx.x*3 + pixlov*3 * (randOffset-1);
	long y = blockIdx.x*blockDim.x*3 + threadIdx.x*3;
	//printf("blockIdx.x: %d; blockDim.x: %d; threadIdx.x: %d -> x: %d\n", blockIdx.x, blockDim.x, threadIdx.x, x);

	// Iskanje levega pixla
	if(y % (vrsta*3) != 0){
		stBarv++;
		sosedi[0][stBarv]= tabela[x-3];
		sosedi[1][stBarv]= tabela[x-2];
		sosedi[2][stBarv]= tabela[x-1];
	}
	//else printf("Levi rob %d %% %d == 0\n", y, vrsta*3);
		
	// Iskanje zgornjega pixla		
	if(y >= vrsta*3){
		stBarv++;
		sosedi[0][stBarv]= tabela[x-(vrsta*3)];
		sosedi[1][stBarv]= tabela[x+1-(vrsta*3)];
		sosedi[2][stBarv]= tabela[x+2-(vrsta*3)];
	}
	//else printf("Zgornji rob x:%d\n", y);

	// Iskanje desnega pixla
	if( (y == 0) || (y % ((vrsta)*3) != (vrsta-1)*3)){
		stBarv++;
		sosedi[0][stBarv]= tabela[x+3];
		sosedi[1][stBarv]= tabela[x+4];
		sosedi[2][stBarv]= tabela[x+5];
	}
	//else printf("Desni rob x:%d\n", y);

	// Iskanje spodnjega pixla
	if(y < pixlov*3 - vrsta*3){
		stBarv++;
		sosedi[0][stBarv]= tabela[x+(vrsta*3)];
		sosedi[1][stBarv]= tabela[x+1+(vrsta*3)];
		sosedi[2][stBarv]= tabela[x+2+(vrsta*3)];
	}
	//else printf("Spodnji rob x: %d\n", y);

	// če je index na intervalu slike v tabeli - zaradi Cude treba baje prevert da ne uzame krnek
	//if(x < pixlov*3*(randOffset+1)) {
		// random int iz tabele, vzamemo i-ti element (index pixla) + offset, da ni vedno isti random na pixlu
		int ran = random[blockIdx.x*blockDim.x + threadIdx.x + (randOffset-1)]%(stBarv+1);
		tabela[pixlov*3 + x] = sosedi[0][ran];
		tabela[pixlov*3 + x+1] = sosedi[1][ran];
		tabela[pixlov*3 + x+2] = sosedi[2][ran];
		//printf("%d\n", ran);

		// Izpis za debuggiranje
		/*if (true) {
			printf("[%d] pixel: (%d, %d) r:%d sosedi: %d ->  [%d %d %d; %d %d %d; %d %d %d; %d %d %d] -> [%d %d %d] --> Zamik: %d Zapis v: %d,%d,%d\n", randOffset, blockIdx.x, threadIdx.x, ran, stBarv+1,
				sosedi[0][0], sosedi[1][0], sosedi[2][0], sosedi[0][1], sosedi[1][1], sosedi[2][1], 
				sosedi[0][2], sosedi[1][2], sosedi[2][2], sosedi[0][3], sosedi[1][3], sosedi[2][3],
				tabela[zamik + x], tabela[zamik + x + 1], tabela[zamik + x + 2], zamik, zamik + x,  zamik + x+1, zamik + x+2);
		}
		*/		
	//}

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
	int *cudaTabela;

	tabela1D = (int*)malloc(width*height*3*sizeof(int));
	rezultat = (int*)malloc((cudaIteracije+1) * width*height*3*sizeof(int));
	random = (int*)malloc(width*height*3*sizeof(int));
	cudaMalloc(&cudaRandom, (cudaIteracije+width*height)*sizeof(int));
	cudaMalloc(&cudaTabela, (cudaIteracije+1) * width*height*3*sizeof(int));

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
	cudaMemcpy(cudaTabela, tabela1D, width*height*3*sizeof(int), cudaMemcpyHostToDevice);
	cudaMemcpy(cudaRandom, random, (cudaIteracije + width*height)*sizeof(int), cudaMemcpyHostToDevice);


	long i = 0;
	char name[64];
	char datoteka[64];
	int counter = 1;
	int rdeca = 0;
  	int modra = 0;
  	int zelena = 0;

	// Klicanje glavne metode v zanki
	for(i = 1; i <= cudaIteracije; i++) {
		//printf("iteracija: %d\n", i+1);
		process<<<height, width>>>(cudaTabela, cudaRandom, width, width*height, i);

	}

	cudaMemcpy(rezultat, cudaTabela, (cudaIteracije+1)* width*height*3*sizeof(int), cudaMemcpyDeviceToHost);


	nova = BMP_Create(width, height, 24);

	for(i = 0; i < cudaIteracije+1; i++) {
		int offset = i*width*height*3;
		if(i%200 == 0) {
			for(y = 0; y < height; y++) {
				for(x = 0; x < width; x++) {
					BMP_SetPixelRGB(nova, x, y, (unsigned char)rezultat[offset + y*width*3+x*3], 
												(unsigned char)rezultat[offset + y*width*3+x*3+1], 
												(unsigned char)rezultat[offset + y*width*3+x*3+2]);
				/*printf("[%d, %d, %d]\n", (unsigned char)rezultat[offset + y*width*3+x*3], 
											(unsigned char)rezultat[offset + y*width*3+x*3+1], 
											(unsigned char)rezultat[offset + y*width*3+x*3+2]);*/
				}
			}
			strcpy(name, "Vojne/izhodi/");
			sprintf(datoteka, "%d", i);
			strcat(name, datoteka);
			strcat(name, ".bmp");
			BMP_WriteFile( nova, name);
			BMP_CHECK_ERROR(stdout, -2);
		}
	}

	

	// Sprostimo pomnilnik
	free(tabela1D);
	free(random);
	cudaFree(cudaRandom);
	cudaFree(cudaTabela);
	BMP_Free(nova);

	// Ustavimo štoparico
	time(&stop);
  	diff = difftime(stop, start);
  	printf("St. iteracij: %ld Runtime: %g\n", i, diff);

	return 0;
}