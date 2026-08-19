#include <stdio.h>

int bin2Bcd(int);

int main() {
    int num = 548;
    int bcd = bin2Bcd(num);

    printf("%d post binario a bcd: %X\n", num, bcd);
    return 0;
}

int bin2Bcd(int s0) {
    int s1;

    int digit;
    int lim = 32;
    int i;
    int j;

    for (i=0; i < lim; i=i+1) {
        for (j=0; j < lim; j=j+1) {
            // TODO:
            // Poner digito bien
            digit = s1 << 4*j;
            if (digit >= 5) {
                s1[j : j+3] = s1[j : j+3] + 3;
            }
        }

        // TODO:
        // Poner s1 correcto
        s1 = s0 << 1;
    }
}
