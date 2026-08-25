#include <stdio.h>

#define NUMS_SIZE 12
#define DIGITS_SIZE 10

void bin2Bcd(int num, int *const digits, const int len_digits);
void test_ind_bin2Bcd(const int num, int *const digits, const int digits_size);
void test_bin2Bcd(int const *const nums, const int nums_size);
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
    int num2 = 372;

    // Hay al menos un numero que termina con cada digito (0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
    // Contienen digitos que se repiten en diferentes posiciones
    // Hay numeros que no repiten ningun digito
    // const int nums_size = 12;
    const int nums[NUMS_SIZE] = {0, 4, 12, 548, 1589, 23741, 64279, 213400, 2396205, 57192836, 912348577, 1285633993};

    // const int digits_size = 10;
    // int digits[len_digits] = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0};
    int digits[DIGITS_SIZE] = {0};

    test_ind_bin2Bcd(num, digits, DIGITS_SIZE);
    printf("----------\n");
    test_ind_bin2Bcd(num2, digits, DIGITS_SIZE);
    test_bin2Bcd(nums, NUMS_SIZE);

    return 0;
}

void bin2Bcd(int num, int *const  digits, const int len_digits) {
    int i;
    int j;

    for (i=0; i < len_digits; i++) {
        digits[i] = 0;
    }

    for (j=0; j < len_digits; j++) {
        for (i=0; num >= DIVISOR[j]; i=i+1) {
            digits[j] += 1;
            num -= DIVISOR[j];
        }
    }
}

void test_bin2Bcd(int const *const nums, const int nums_size) {
    FILE* myFile = fopen("./out/test_nums.txt", "w");
    if (myFile == NULL) {
        printf("Error al abrir el archivo");
        return;
    }

    int digits[DIGITS_SIZE] = {0};

    fprintf(myFile, "Test bin2Bcd de varios numeros\n");

    for (int i=0; i < nums_size; i++) {
        bin2Bcd(nums[i], digits, DIGITS_SIZE);

        fprintf(myFile, "Numero original: %d\n\n", nums[i]);
        for (int i = 0; i < DIGITS_SIZE; i++) {
            fprintf(myFile, "Digito %d post binario a bcd: %X\n", i+1, digits[i]);
        }
        fprintf(myFile, "--------------------\n");
    }

    fclose(myFile);
}

void test_ind_bin2Bcd(const int num, int *const digits, const int digits_size) {
    bin2Bcd(num, digits, digits_size);

    printf("Numero original: %d\n\n", num);
    for (int i = 0; i < digits_size; i++) {
        printf("Digito %d post binario a bcd: %X\n", i+1, digits[i]);
    }
}
