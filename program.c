/**************************************************************

	Program prebere vhodno sliko in na podlagi danih n
	korakov zgenerira novo sliko, kjer se slikovne pike
	spreminjajo glede na sosedne pike, ki jih obdajajo.

	Avtor: Žiga Kljun

**************************************************************/


#include "qdbmp.h" 
#include <stdio.h> 
#include "qdbmp.c"
#include <stdlib.h>
#include <time.h>
#include <stdint.h>

int main( int argc, char* argv[] ) { 

	double diff = 0.0;
	time_t start;
    time_t stop;
    time(&start);

	BMP* bmp;
	BMP* nova;
	UCHAR r, g, b; 
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
	
	width = BMP_GetWidth( bmp );
	height = BMP_GetHeight( bmp );

	nova= BMP_Create(width, height, 24);
	BMP_CHECK_ERROR( stderr, -1 );

	srand ( time(NULL) );
  	
	/* Definiramo tabelo sosedov, ki jo bomo kasneje uporabljali
	   za shranjevanje barv sosednjih pik */
  	UCHAR tabela_sosedov[ 4 ][3];
  	int stBarv=0;
  	int random_number=0;
  	int koraki=0;
  	
  	printf("Vneste stevilo korakov, ki jih zelite izvesti \n");
	int stKorakov;
  	scanf ("%d", &stKorakov);

  	int rdeca = 0;
  	int modra = 0;
  	int zelena = 0;
	int orazna=0;
  	FILE *f;
  	f = fopen("barve.txt", "a");
  	
  	/* Z zanko se zapeljemo cez vse korake in v vsakem od njih
  	   izvedemo spreminjanje barv */
  	while(koraki<stKorakov){
  	//while(rdeca < width*height && zelena < width*height && modra < width*height) {
  		rdeca = 0;
		modra = 0;
		zelena = 0;
		orazna=0;
  		for ( y = 0 ; y < height ; y++ )
		{
			for ( x = 0 ; x < width ; x++ )
			{
				stBarv=-1;
				
				if((x-1)>=0){
					/* Preberemo RGB vrednosti x-1, y pike */
					BMP_GetPixelRGB( bmp, x-1, y, &r, &g, &b );
					stBarv++;
					tabela_sosedov[stBarv][0]=r;
					tabela_sosedov[stBarv][1]=g;
					tabela_sosedov[stBarv][2]=b;
				}
				
				if((y-1)>=0){
					BMP_GetPixelRGB( bmp, x, y-1, &r, &g, &b );
					stBarv++;
					tabela_sosedov[stBarv][0]=r;
					tabela_sosedov[stBarv][1]=g;
					tabela_sosedov[stBarv][2]=b;
				}
				
				if((x+1)<width){
					BMP_GetPixelRGB( bmp, x+1, y, &r, &g, &b );
					stBarv++;
					tabela_sosedov[stBarv][0]=r;
					tabela_sosedov[stBarv][1]=g;
					tabela_sosedov[stBarv][2]=b;
				}
				
				if((y+1)<height){
					BMP_GetPixelRGB( bmp, x, y+1, &r, &g, &b );
					stBarv++;
					tabela_sosedov[stBarv][0]=r;
					tabela_sosedov[stBarv][1]=g;
					tabela_sosedov[stBarv][2]=b;
				}
				
				/* Zgeneriramo nakljucno stevilo po modulu, ki je
				   enak stevilu sosedov */
				random_number = rand()%(stBarv+1);
				
				/* Nastavimo RGB vrednost novi sliki */
				BMP_SetPixelRGB( nova, x, y, tabela_sosedov[random_number][0], 
					tabela_sosedov[random_number][1], 
					tabela_sosedov[random_number][2]);
				if((int)tabela_sosedov[random_number][0] == 250) rdeca++;
				else if ((int)tabela_sosedov[random_number][0] > 0 &&random_number][0] < 150) zelena++;
				else if ((int)tabela_sosedov[random_number][0]> 200) oranzna++;
				else modra++;
			}
		}
		BMP_WriteFile( nova, argv[2]);
		BMP_CHECK_ERROR( stdout, -2 );

		//printf("R:%d G:%d B:%d\n", rdeca, zelena, modra);
		fprintf(f, "%d %d %d %d\n", rdeca, zelena, modra, oranzna);


		bmp=nova;
  		koraki++;
  	}

  	/* Shranimo novo sliko */
	

	/* Sprostimo spomin */
	BMP_Free(bmp);

	fclose(f);

	time(&stop);
  	diff = difftime(stop, start);
  	printf("Runtime: %g\n", diff);

	return 0;
}
