
#include "qdbmp.h"
#include <stdio.h>
#include "qdbmp.c"
#include <time.h>

int main(int argc, char const *argv[])
{
	UCHAR	r, g, b;
	//UINT	width, height;
	UINT	x, y;
	BMP*	bmp;

	unsigned int width, height;
	int rgb[3];
	printf("Vnesi verjetnosti R, G, B v %%\n");
	scanf("%d", &rgb[0]);
	scanf("%d", &rgb[1]);
	scanf("%d", &rgb[2]);

	printf("Vnesi sirino in visino:\n");
	scanf("%u", &width);
	scanf("%u", &height);

	unsigned char barve[3][3] = {{250, 0, 0}, {124, 252, 0}, {0, 0, 255}};
	srand(time(NULL));

	bmp = BMP_Create(width, height, 24);

	for (x = 0 ; x < width; x++) {
		for ( y = 0 ; y < height ; y++) {
			//printf("y:%d x:%d\n", y,x);
			int r = rand() % 100;
			if(r < rgb[0]) {
				BMP_SetPixelRGB(bmp, x, y, barve[0][0], barve[0][1], barve[0][2]);
			}
			else if(r >= rgb[0] && r < rgb[0] + rgb[1]){
				BMP_SetPixelRGB(bmp, x, y, barve[1][0], barve[1][1], barve[1][2]);
			}
			else {
				BMP_SetPixelRGB(bmp, x, y, barve[2][0], barve[2][1], barve[2][2]);
			}
		}
	}

	/* Save result */
	BMP_WriteFile(bmp, "random.bmp");
	BMP_CHECK_ERROR( stdout, -2 );


	/* Free all memory allocated for the image */
	BMP_Free(bmp);


	return 0;
}