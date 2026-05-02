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

map<string, info_var> tabela_simbolos;

//armazena as informações para o cast
struct info_cast{
	string resultado;
	string cast_esq;
	string cast_dir;
};

//tabela_consultas é um mapa onde a chave é um par<string, string>
//e o retorno é info_cast. passo os tipos de $1 e $3 e tenho como retorno
//os tipos que cada uma das variáveis $$, $1 e $2 devem assumir após o cast
map<pair<string, string>, info_cast> tabela_consulta{
	{{"int", "int"}, {"int", "", ""}},
	{{"int", "float"}, {"float", "float", ""}},
	{{"float", "int"}, {"float", "", "float"}},
	{{"float", "float"}, {"float", "", ""}},
	
};

string tipos_numericos[] = {"int", "float"};
int tam_tipos_numericos = 2;

struct atributos
{
	string label;
	string traducao;
	string tipo; 
};

int yylex(void);
void yyerror(string);
string gentempcode();
string castGerar(string, string, string&); //função responsável pelo cast
void operacoes(atributos&, atributos&, atributos&, string, string); //função responsável pelas operações artiméticas e relacionais
void op_logicos(atributos&, atributos&, atributos&, string); //função responsável pelas operações lógicas
bool eh_tipo_numerico(atributos&); //função que determina se $1 e $3 são valores numéricos para relaizar operações aritméticas e relacionais
%}

%token TK_NUM TK_CHARLITERAL TK_BOOLLIT
%token TK_INT TK_FLOAT TK_CHAR TK_BOOL TK_ID
%token TK_MAI TK_MEI  TK_II TK_DF
%token TK_AND TK_OR

%start S

%right '='
%left TK_AND TK_OR
%left '!'
%left TK_II TK_DF '<' '>' TK_MEI TK_MAI
%left '+' '-'
%left '*' '/'

%%

S           : LISTA_DEC
            {
                codigo_gerado = "/*Compilador FOCA*/\n"
                                "#include <stdio.h>\n"
                                "int main(void) {\n";

                codigo_gerado += declaracoes + "\n" + $1.traducao;

                codigo_gerado += "\treturn 0;"
                            "\n}\n";
            }
            ;

LISTA_DEC  : LISTA_DEC DEC
            {
                $$.traducao = $1.traducao;
            }
            | LISTA_DEC E ';'
            {
                $$.traducao = $1.traducao + $2.traducao;
            }
            | LISTA_DEC E
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
				tabela_simbolos[$2.label] = {temp, "bool"};
				declaracoes += "\tint " + temp + ";\n";
			}
			;

E 			: E '+' E
			{
				operacoes($$, $1, $3, "+", "arit");
			}
			| E '-' E
			{
				operacoes($$, $1, $3, "-", "arit");
			}
			| E '*' E
			{
				operacoes($$, $1, $3, "*", "arit");
			}
			| E '/' E
			{
				operacoes($$, $1, $3, "/", "arit");
			}
			| E '<' E
			{
				operacoes($$, $1, $3, "<", "rel");
			}
			| E '>' E
			{
				operacoes($$, $1, $3, ">", "rel");
			}
			| E TK_MAI E
			{
				operacoes($$, $1, $3, ">=", "rel");
			}
			| E TK_MEI E
			{
				operacoes($$, $1, $3, "<=", "rel");
			}
			| E TK_DF E
			{
				operacoes($$, $1, $3, "!=", "rel");
			}
			| E TK_II E
			{
				operacoes($$, $1, $3, "==", "rel");
			}
			| E TK_AND E
			{
				op_logicos($$, $1, $3, "&&");
			}
			| E TK_OR E
			{
				op_logicos($$, $1, $3, "||");
			}
			| '!'E
			{
				if ($2.tipo == "bool"){
					$$.label = gentempcode();
					$$.tipo = "bool";
					declaracoes += "\tint " + $$.label + ";\n";
					$$.traducao = $2.traducao + "\t" + $$.label + 
						" = !" + $2.label + ";\n";
				}
				else{ 
					yyerror("ERRO: você está fazendo operações lógicas com tipos não booleanos");
				}
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
				declaracoes += "\t" + $$.tipo + " " + $$.label + ";\n";
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

//funcao que fica responsável por fazer o cast
string castGerar(string cast_tipo, string label, string& cast_traducao){
	string temp = gentempcode(); //gera a string temporaria q vai receber o resultado do cast
	declaracoes += "\t" + cast_tipo + " " + temp + ";\n"; //faz a declaracao dessa nova string temporaria
	cast_traducao += + "\t" + temp + " = " + "(" + cast_tipo + 
	")" + label + ";\n"; //faz a traducao para p codigo em c da nova string temporaria. Ex: t2 = (float)t1;
	return temp; //retorna o novo label para um dos "E", pois um deles sofre o cast e muda o nome da variável
}

void operacoes(atributos& dd, atributos& d1, atributos& d3, string op, string op_tipo){
	if(eh_tipo_numerico(d1) && eh_tipo_numerico(d3)){
		auto cast = tabela_consulta[{d1.tipo, d3.tipo}]; //consulta a tabela para saber se será necessário fazer cast
		if(op_tipo == "arit"){
			dd.tipo = cast.resultado; //define o tipo de $$ conforme a necessidade de fazer cast ou n	
		}
		else{
			dd.tipo = "bool"; //se for operação relacional, o tipo de $$(dd) sempre será bool
		}
		dd.label = gentempcode(); 
		string cast_traducao = d1.traducao + d3.traducao; 
		if(cast.cast_esq != ""){
			d1.label = castGerar(cast.cast_esq, d1.label, cast_traducao); //chama a função q faz o cast caso seja necessário
		}
		if(cast.cast_dir != ""){
			d3.label = castGerar(cast.cast_dir, d3.label, cast_traducao); 
		}
		if(op_tipo == "arit"){
			declaracoes += "\t" + dd.tipo + " " + dd.label + ";\n";	
		}
		else{
			declaracoes += "\tint " + dd.label + ";\n";	//tratamento especial para o tipo bool pq ele n existe em C
		}
		
		dd.traducao = cast_traducao + "\t" + dd.label +
		" = " + d1.label + " " + op + " " + d3.label + ";\n";
	}
	else{
		yyerror("ERRO: você está tentando operar com tipos nao numericos");
	}
}

bool eh_tipo_numerico(atributos& d){
	for(int i = 0; i < tam_tipos_numericos; i++){
		if(d.tipo == tipos_numericos[i]){
			return true;
		}
	}
	return false;
}

void op_logicos(atributos& dd, atributos& d1, atributos& d3, string op){
	if (d1.tipo == "bool" && d3.tipo == "bool"){
		dd.label = gentempcode();
		dd.tipo = "bool";
		declaracoes += "\tint " + dd.label + ";\n";
		dd.traducao = d1.traducao + d3.traducao + 
		"\t" + dd.label + " = " + d1.label + " " + op + " " + d3.label + ";\n";
	}
	else{ 
		yyerror("ERRO: você está fazendo operações lógicas com tipos não booleanos");
	}
}