#include <stdio.h>

int main(void) {
        int t1;
        int t2;
        int t3;
        int t4;
        int t5;
        int t6;
        int t8;
        int t10;

        t2 = 5;
        t1 = t2;
        t4 = 2;
        t3 = t4;
        t5 = t1 == t3;
        if (t5) {
            printf("E igual");
        }
        else {
        t6 = t1 < t3;
                if(t6) {
        printf("E menor");
        int t7;
        }
        else {
        t8 = t1 > t3;
                if(t8) {
        printf("E maior");
        int t9;
        }
        else {
        t10 = t1 != t3;
                if(t10) {
        printf("E diferente");
        int t11;
        }
                else {
        printf("Else");
        int t12;
        }
        }
        }
        }
        return 0;
}