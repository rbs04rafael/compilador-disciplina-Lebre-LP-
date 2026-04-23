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

struct info_var{
	string temp;
	string tipo;
};

map<string, info_var> tabela_simbolos; // agora é info_var pois precisa guarda o tipo também

struct atributos
{
	string label;
	string traducao;
	string tipo; // cada expressão precisa carregar o tipo com ela
};

int yylex(void);
void yyerror(string);
string gentempcode();
%}

%token TK_NUM TK_ID TK_INT TK_FLOAT TK_CHAR TK_CHARLITERAL TK_BOOL TK_BOOLLIT


%start S

%right '='
%left '+' '-'
%left '*' '/'

%%

S           : LISTA_STMT
            {
                codigo_gerado = "/*Compilador FOCA*/\n"
                                "#include <stdio.h>\n"
                                "int main(void) {\n";

                codigo_gerado += declaracoes + "\n" + $1.traducao;

                codigo_gerado += "\treturn 0;"
                            "\n}\n";
            }
            ;

LISTA_STMT  : LISTA_STMT DEC
            {
                $$.traducao = $1.traducao;
            }
            | LISTA_STMT E ';'
            {
                $$.traducao = $1.traducao + $2.traducao;
            }
            | LISTA_STMT E
            {
                $$.traducao = $1.traducao + $2.traducao;
            }
            | /* vazio */
            {
                $$.traducao = "";
            }
            ;
DEC 		: TK_INT TK_ID ';'
			{
				string temp = gentempcode();
				tabela_simbolos[$2.label] = {temp, "int"};
				declaracoes += "\tint " + temp + ";\n";
			}
			| TK_FLOAT TK_ID ';'
			{
				string temp = gentempcode();
				tabela_simbolos[$2.label] = {temp, "float"};
				declaracoes += "\tfloat " + temp + ";\n";
			}
			|
			TK_CHAR TK_ID ';'
			{
				string temp = gentempcode();
				tabela_simbolos[$2.label] = {temp, "char"};
				declaracoes += "\tchar " + temp + ";\n";
			
			}
			| TK_BOOL TK_ID ';'
			{	
				string temp = gentempcode();
				tabela_simbolos[$2.label] = {temp, "int"};
				declaracoes += "\tint " + temp + ";\n";
			}
			;
E 			: E '+' E
			{
				$$.label = gentempcode();

				if ($1.tipo == "float" || $3.tipo == "float") 
            		$$.tipo = "float";
       			else 
           			 $$.tipo = "int";
       				 
				declaracoes += "\t" + $$.tipo + " " + $$.label + ";\n";
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $1.label + " + " + $3.label + ";\n";
			}
			| E '-' E
			{
				$$.label = gentempcode();

				if ($1.tipo == "float" || $3.tipo == "float") 
            		$$.tipo = "float";
       			else 
           			 $$.tipo = "int";
       				 
				declaracoes += "\t" + $$.tipo + " " + $$.label + ";\n";
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $1.label + " - " + $3.label + ";\n";
			}
			| E '*' E
			{
				$$.label = gentempcode();

				if ($1.tipo == "float" || $3.tipo == "float") 
            		$$.tipo = "float";
       			else 
           			 $$.tipo = "int";

				declaracoes += "\t" + $$.tipo + " " + $$.label + ";\n";
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $3.label + " * " + $1.label + ";\n";
			}
			| E '/' E
			{
				$$.label = gentempcode();

				if ($1.tipo == "float" || $3.tipo == "float")
            		$$.tipo = "float";
       			else 
           			 $$.tipo = "int";
       				 

				declaracoes += "\t" + $$.tipo + " " + $$.label + ";\n";
				$$.traducao = $1.traducao + $3.traducao + "\t" + $$.label +
					" = " + $1.label + " / " + $3.label + ";\n";
			}
			| '(' E ')'
			{
				$$.label = $2.label;
				$$.traducao = $2.traducao;
				$$.tipo = $2.tipo;
			}
			| TK_ID '=' E
			{
				if(tabela_simbolos.count($1.label)){
					auto info = tabela_simbolos[$1.label];
					$$.label = info.temp;
					$$.tipo = info.tipo;
					$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
				}
				else{
					$$.label = $1.label;
					$$.tipo = $3.tipo;
					$$.traducao = $3.traducao + "\t" + $1.label + " = " + $3.label + ";\n";	
				}
			}
			| TK_ID
			{
				if(tabela_simbolos.count($1.label)){
					auto info = tabela_simbolos[$1.label];
					$$.label = info.temp;
					$$.tipo = info.tipo;
					$$.traducao = "";
				}
				else{
					$$.label = gentempcode();
					$$.tipo = "int"; // Considerei int por padrão
					$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
				}
			}
			| TK_NUM
			{
				$$.label = gentempcode();
				$$.tipo = $1.tipo;

				if ($$.tipo == "float") 
       				 declaracoes += "\tfloat " + $$.label + ";\n";
				else 
        			declaracoes += "\tint " + $$.label + ";\n";

				$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
			}
			| TK_CHARLITERAL
			{
				$$.label = $1.label;
				$$.tipo = "char";
				$$.traducao = ""; 
			}
			| TK_BOOLLIT
			{
				$$.label = $1.label;
				$$.tipo = "int";
				$$.traducao = "";
			}
			;

%%

#include "lex.yy.c"

int yyparse();

string gentempcode()
{
	var_temp_qnt++;
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
