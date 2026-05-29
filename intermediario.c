
/*Compilador FOCA*/
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int tamString(char* s){
	int i = 0;
	while(s[i] != '\0')
		i++;
	return i;
}

int main(void) {
	int t1;
	int t2;
	char* t3;
	char* t4;
	int t5;
	int t6;
	int t7;
	int t8;
	char* t10;

	t3 = "Quantas voltas quer dar no laco?";
	printf("%s\n", t3);
	scanf("%d", &t2);
	t4 = "Iniciando a contagem...";
	printf("%s\n", t4);
	t5 = 0;
	t1 = t5;
L0:
	t6 = t1 < t2;
	if (!t6) goto L1;
	char* t9;
	t9 = "Volta atual:";
	printf("%s\n", t9);
	printf("%d\n", t1);
	t7 = 2;
	t8 = t1 + t7;
	t1 = t8;
	goto L0;
L1:
	t10 = "Fim do laco!";
	printf("%s\n", t10);

	return 0;
}

