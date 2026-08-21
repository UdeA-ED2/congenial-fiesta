#include <stdio.h>

void bin2Bcd(int, int *const , const int);
const int DIVISOR[10] = {
    1000000000,
    100000000,
    10000000,
    1000000,
    100000,
    10000,
    1000,
    100,
    10,
    1,
};

int main() {
    int num = 548;
    const int len_digits = 10;
    // int digits[len_digits];
    int digits[10] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    bin2Bcd(num, digits, len_digits);

    printf("Numero original: %d\n\n", num);
    for(int i = 0; i < len_digits; i++) {
        printf("Digito %d post binario a bcd: %X\n", i+1, digits[i]);
    }
    return 0;
}

// TODO:
// Compilar y probar esta vaina
void bin2Bcd(int num, int *const  digits, const int len_digits) {
    int i;
    int j;

    for (j=0; j < len_digits; j++) {
        for (i=0; num >= DIVISOR[j]; i=i+1) {
            digits[j] += 1;
            num -= DIVISOR[j];
        }
    }
}
