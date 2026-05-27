
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
	char* t1;

	t1 = "oi";
	printf("%s\n", t1);

	return 0;
}

