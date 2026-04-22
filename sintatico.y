%{
#include <iostream>
#include <string>
#include <map>

#define YYSTYPE atributos

using namespace std;

int var_temp_qnt;
int linha = 1;
string codigo_gerado;
string declaracoes;
map<string,string> tabela_simbolos; //é global para q tds regras possam acessar

struct atributos
{
	string label;
	string traducao;
};

int yylex(void);
void yyerror(string);
string gentempcode();
%}

%token TK_NUM TK_ID TK_INT

%start S

%right '='
%left '+' '-'
%left '*' '/'

%%

S 			: LISTA_DEC E
			{
				codigo_gerado = "/*Compilador FOCA*/\n"
								"#include <stdio.h>\n"
								"int main(void) {\n";
				
				codigo_gerado += declaracoes + "\n" + $2.traducao;

				codigo_gerado += "\treturn 0;"
							"\n}\n";
			}
			;

LISTA_DEC	: LISTA_DEC DEC
			| /* vazio (epsilon) */
			;

DEC 		: TK_INT TK_ID ';'
			{
				string temp = gentempcode();
				tabela_simbolos[$2.label] = temp;
			}
			;


E 			: E '+' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $1.label + " + " + $3.label + ";\n";
			}
			| E '-' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $1.label + " - " + $3.label + ";\n";
			}
			| E '*' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $1.label + " * " + $3.label + ";\n";
			}
			| E '/' E
			{
				$$.label = gentempcode();
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $1.label + " / " + $3.label + ";\n";
			}
			| '(' E ')'
			{
				$$.label = $2.label;
				$$.traducao = $2.traducao;
			}
			| TK_ID '=' E
			{
				if(tabela_simbolos.count($1.label)){
					string temp = tabela_simbolos[$1.label];
					$$.label = temp;
					$$.traducao = $3.traducao + "\t" + temp + " = " + $3.label + ";\n";
				}
				else{
					$$.label = $1.label;
					$$.traducao = $3.traducao + "\t" + $1.label + " = " + $3.label + ";\n";	
				}
			}
			| TK_ID
			{
				if(tabela_simbolos.count($1.label)){
					$$.label = tabela_simbolos[$1.label];
					$$.traducao = "";
				}
				else{
					$$.label = gentempcode();
					$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";	
				}
			}
			| TK_NUM
			{
				$$.label = gentempcode();
				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			;

%%

#include "lex.yy.c"

int yyparse();

string gentempcode()
{
	var_temp_qnt++;
	declaracoes += "\tint t" + to_string(var_temp_qnt) + ";\n";
	return "t" + to_string(var_temp_qnt);
}

int main(int argc, char* argv[])
{
	var_temp_qnt = 0;

	if (yyparse() == 0)
		cout << codigo_gerado;

	return 0;
}

void yyerror(string MSG)
{
	cerr << "Erro na linha " << linha << ": " << MSG << endl;
}
