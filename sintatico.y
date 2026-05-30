%{
#include <iostream>
#include <string>
#include <map>
#include <vector>

#define YYSTYPE atributos

using namespace std;

int var_temp_qnt;
int label_count = 0;
int linha = 1;
int erro_count = 0; 
int nivel_escopo = 0;
string codigo_gerado;
string declaracoes;
vector<string> declaracoes_anterior;
vector<string> pilha_switch_temp;
vector<string> pilha_break;
vector<string> pilha_continue;

struct info_var{
	string temp;
	string tipo;
};

vector<map<string, info_var>> tabela_escopos; //vetor de tabela de simbolos para blocos

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
bool cast_valido(string destino, string origem); //função que determina se um cast é válido ou não, usada para validar o cast explícito
void declarar_variavel(string nome, string tipo);
info_var consultar_variavel(string nome);
string gen_label();
%}

%token TK_NUM TK_CHARLITERAL TK_BOOLLIT TK_STRINGLITERAL
%token TK_INT TK_FLOAT TK_CHAR TK_BOOL TK_STRING TK_ID
%token TK_MAI TK_MEI  TK_II TK_DF
%token TK_AND TK_OR
%token TK_IF TK_ELSE TK_ELSE_IF
%token TK_PRINT TK_SCAN
%token TK_WHILE TK_DO_WHILE TK_FOR TK_INC
%token TK_SWITCH TK_CASE TK_DEFAULT TK_BREAK TK_CONTINUE

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
                codigo_gerado = "\n/*Compilador FOCA*/\n"
                                "#include <stdio.h>\n"
								"#include <stdlib.h>\n"
								"#include <string.h>\n\n"
								"int tamString(char* s){\n"
									"\tint i = 0;\n"
									"\twhile(s[i] != '\\0')\n"
										"\t\ti++;\n"
						
									"\treturn i;\n"
								"}\n\n"
								"int comparaString(char* s1, char* s2){\n"
								"	int t_idx = 0;\n"
								"	char t_c1;\n"
								"	char t_c2;\n"
								"	int t_diff;\n"
								"	int t_fim;\n"
								"	int t_soma;\n"
								"L_inicio:\n"
								"	t_c1 = s1[t_idx];\n"
								"	t_c2 = s2[t_idx];\n"
								"	t_diff = t_c1 != t_c2;\n"
								"	if(!t_diff) goto L_continua;\n"
								"	return 0;\n"
								"L_continua:\n"
								"	t_fim = t_c1 == 0;\n"
								"	if(!t_fim) goto L_proximo;\n"
								"	return 1;\n"
								"L_proximo:\n"
								"	t_soma = t_idx + 1;\n"
								"	t_idx = t_soma;\n"
								"	goto L_inicio;\n"
								"}\n\n"

                                "int main(void) {\n";

                codigo_gerado += declaracoes + "\n" + $1.traducao;

                codigo_gerado += "\n\treturn 0;"
                            "\n}\n\n";
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
            | LISTA_DEC BLOCO
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			| LISTA_DEC CTRL
			{
				$$.traducao = $1.traducao + $2.traducao;
			}
			| LISTA_DEC TK_PRINT '(' E ')' ';'
			{
				$$.label = "";
				$$.tipo = "";

				if($4.tipo == "int")
					$$.traducao = $1.traducao + $4.traducao + "\tprintf(\"%d\\n\", " + $4.label + ");\n";
				else if($4.tipo == "float")
					$$.traducao = $1.traducao + $4.traducao + "\tprintf(\"%f\\n\", " + $4.label + ");\n";
				else if($4.tipo == "char")
					$$.traducao = $1.traducao + $4.traducao + "\tprintf(\"%c\\n\", " + $4.label + ");\n";
				else if($4.tipo == "bool")
					$$.traducao = $1.traducao + $4.traducao + "\tprintf(\"%d\\n\", " + $4.label + ");\n";
				else if($4.tipo == "string")
					$$.traducao = $1.traducao + $4.traducao + "\tprintf(\"%s\\n\", " + $4.label + ");\n";
			}
			| LISTA_DEC TK_SCAN '(' TK_ID ')' ';'
			{
				auto info = consultar_variavel($4.label);

				if(info.tipo == "int")
					$$.traducao = $1.traducao + "\tscanf(\"%d\", &" + info.temp + ");\n";
				else if(info.tipo == "float")
					$$.traducao = $1.traducao + "\tscanf(\"%f\", &" + info.temp + ");\n";
				else if(info.tipo == "char")
					$$.traducao = $1.traducao + "\tscanf(\"%c\", &" + info.temp + ");\n";
				else if(info.tipo == "bool")
					$$.traducao = $1.traducao + "\tscanf(\"%d\", &" + info.temp + ");\n";
				else if(info.tipo == "string")
					$$.traducao = $1.traducao + "\t" + info.temp + " = (char*) malloc(256);\n"
					+ "\tscanf(\" %[^\\n]\", " + info.temp + ");\n";
			}
			| /* vazio */
            {
                $$.traducao = "";
            }
            ;


BLOCO 		: '{' 
			{
				declaracoes_anterior.push_back(declaracoes);
				declaracoes = "";
				tabela_escopos.push_back(map<string, info_var>());
				nivel_escopo++;
			}
			LISTA_DEC '}'
			{
				nivel_escopo--; 
				$$.traducao = declaracoes +  $3.traducao;

				declaracoes = declaracoes_anterior.back();
				declaracoes_anterior.pop_back();
				tabela_escopos.pop_back();
			}
			;

CTRL 		: TK_IF '(' E ')' BLOCO //para if sem else
			{
				if ($3.tipo != "bool") 
        			yyerror("A condicao do 'se' nao foi do tipo logico!");
				
				string label_fim = gen_label();
				$$.traducao = $3.traducao + "\tif (!" + $3.label + ") goto " + label_fim + ";\n"
				+ $5.traducao 
				+ label_fim + ":\n";
			}
			| TK_IF '(' E ')' BLOCO TK_ELSE BLOCO //para if c/ 1 else
			{
				if ($3.tipo != "bool") 
        			yyerror("A condicao do 'se/senao' nao foi do tipo logico!");
				
				string label_else = gen_label();
				string label_fim = gen_label();

				$$.traducao = $3.traducao + "\tif (!" + $3.label + ") goto " + label_else + ";\n"
				+ $5.traducao + "\tgoto "+ label_fim + ";\n"
				+ label_else + ":\n" + $7.traducao
				+ label_fim + ":\n";
			}
			| TK_IF '(' E ')' BLOCO ELSE_IF //para else if
			{
				if ($3.tipo != "bool") 
        			yyerror("A condicao do 'se/senao se' nao foi do tipo logico!");

				string label_else = gen_label();
				string label_fim = gen_label();

				$$.traducao = $3.traducao + "\tif (!" + $3.label + ") goto " + label_else + ";\n"
				+ $5.traducao + "\tgoto " + label_fim + ";\n"
				+ label_else + ":\n" + $6.traducao
				+ label_fim + ":\n";
			}
			| TK_WHILE '(' E ')' 
			{
				pilha_continue.push_back(gen_label());
				pilha_break.push_back(gen_label());
			}
			BLOCO
			{
				if($3.tipo != "bool")
					yyerror("A condicao do 'enquanto' nao foi do tipo logico!");
				string label_inicio = pilha_continue.back();
				string label_fim = pilha_break.back();
				
				$$.traducao = label_inicio + ":\n" + $3.traducao + "\tif (!" + $3.label + ") goto " +
				 label_fim + ";\n" + $6.traducao + "\tgoto " + label_inicio + ";\n"
				 + label_fim + ":\n"; 
				pilha_continue.pop_back();
				pilha_break.pop_back();
			}
			| TK_DO_WHILE '(' E ')'
			{
				pilha_continue.push_back(gen_label());
				pilha_break.push_back(gen_label());
			}
			BLOCO
			{
				if($3.tipo != "bool")
					yyerror("A condicao do 'faca enquanto' nao foi do tipo logico!");
				string label_inicio = gen_label();
				string label_fim = pilha_break.back();
				
				$$.traducao = label_inicio + ":\n" + $6.traducao + pilha_continue.back() + ":\n" +
				 $3.traducao + "\tif (!" + $3.label + ") goto " + label_fim + ";\n" + 
				 "\tgoto " + label_inicio + ";\n" + label_fim + ":\n"; 
				pilha_continue.pop_back();
				pilha_break.pop_back();
			}
			| TK_FOR '(' ATRIBUICAO ';' E ';' ATRIBUICAO ')' 
			{
				pilha_continue.push_back(gen_label());
				pilha_break.push_back(gen_label());
			}
			BLOCO
			{
				if($5.tipo != "bool")
					yyerror("A condicao do 'para' nao foi do tipo logico!");

				string label_inicio = gen_label();
				string label_fim = pilha_break.back();
				
				$$.traducao = $3.traducao + label_inicio + ":\n"
				+ $5.traducao + "\tif (!" + $5.label + ") goto " + label_fim + ";\n"
				+ $10.traducao + pilha_continue.back() + ":\n" + $7.traducao
				+ "\tgoto " + label_inicio + ";\n"
				+ label_fim + ":\n"; 
				pilha_continue.pop_back();
				pilha_break.pop_back();
			}
			| TK_SWITCH '(' E ')' '{' 
			{
    			pilha_switch_temp.push_back($3.label);
    			pilha_break.push_back(gen_label());
			} 
			CASOS '}'
			{
    		$$.traducao = $3.traducao + $7.traducao + pilha_break.back() + ":\n";
    		pilha_switch_temp.pop_back();
    		pilha_break.pop_back();
			}
			| TK_BREAK ';'
        	{
        		if (pilha_break.empty()) 
        			yyerror("O 'pare' so pode ser usado dentro de um laco ou escolha");
				else 
        			$$.traducao = "\tgoto " + pilha_break.back() + ";\n";
      		}
			| TK_CONTINUE ';'
			{
				if(pilha_continue.empty()){
					yyerror("O 'continua' so pode ser usado dentro de um laco");
				}
				else{
					$$.traducao = "\tgoto " + pilha_continue.back() + ";\n";
				}
			}
			;
CASO   	: TK_CASE E ':' LISTA_DEC
			{
				string temp_switch = pilha_switch_temp.back();
				string temp_cmp = gentempcode();
				declaracoes += "\tint " + temp_cmp + ";\n";

				string label_proximo = gen_label();

				$$.traducao = $2.traducao + "\t" + temp_cmp + " = " + temp_switch + " == " + $2.label + ";\n"
				+ "\tif (!" + temp_cmp + ") goto " + label_proximo + ";\n" 
				+ $4.traducao + label_proximo + ":\n";
			}
			;
CASOS  		: CASO CASOS
			{
    			$$.traducao = $1.traducao + $2.traducao;
			}
			| CASO
			{
				$$.traducao = $1.traducao;
			}
			| TK_DEFAULT ':' LISTA_DEC
			{
				$$.traducao = $3.traducao;
			}
			;
ATRIBUICAO  : TK_ID '=' E 
			{
				auto info = consultar_variavel($1.label); 
        			$$.label = info.temp;
        			$$.tipo = info.tipo;

					if(info.tipo == "string"){
						$$.traducao = $3.traducao + "\t" + $$.label + " = " + "(char*) malloc(tamString(" + $3.label+ ") + 1);\n" 
						+ "\tstrcpy(" + $$.label + ", " + $3.label + ");\n";

					}else{
        			// Verifica se os tipos são diferentes 
        			if (info.tipo != $3.tipo) {
            			if (info.tipo == "float" && $3.tipo == "int") 
                			$3.label = castGerar("float", $3.label, $3.traducao); 
            			else if (info.tipo == "int" && $3.tipo == "float") 
                			$3.label = castGerar("int", $3.label, $3.traducao);
						else 
						 yyerror("tipos incompativeis para atribuicao"); 
						}	
        			$$.traducao = $3.traducao + "\t" + $$.label + " = " + $3.label + ";\n";
					}
			}
			| TK_ID TK_INC
			{
				auto info = consultar_variavel($1.label);
				$$.traducao = "\t" + info.temp + " = " + info.temp + " + 1;\n";
			}
			;

ELSE_IF 	: TK_ELSE_IF '(' E ')' BLOCO //para 1 else if
			{
				if ($3.tipo != "bool") 
					yyerror("A condicao usada nao foi do tipo logico!");

    			string label_fim = gen_label();

				$$.traducao = $3.traducao + "\tif (!" + $3.label + ") goto " + label_fim + ";\n" + 
                  $5.traducao + label_fim + ":\n";
			}
			| TK_ELSE_IF '(' E ')' BLOCO ELSE_IF//para diversos else if
			{
				if ($3.tipo != "bool") 
					yyerror("A condicao usada nao foi do tipo logico!");

				string label_else = gen_label();
    			string label_fim = gen_label();

				$$.traducao = $3.traducao + "\tif (!" + $3.label + ") goto " + label_else + ";\n" + 
                  $5.traducao + "\tgoto " + label_fim + ";\n" 
				  + label_else + ":\n" + $6.traducao 
				  + label_fim + ":\n";
			}
			| TK_ELSE_IF '(' E ')' BLOCO TK_ELSE BLOCO //para else if c/ else
			{
				if ($3.tipo != "bool") 
        			yyerror("A condicao do 'se' nao foi do tipo logico!");
				
				string label_else = gen_label();
				string label_fim = gen_label();

				$$.traducao = $3.traducao + "\tif (!" + $3.label + ") goto " + label_else + ";\n"
				+ $5.traducao + "\tgoto "+ label_fim + ";\n"
				+ label_else + ":\n" + $7.traducao
				+ label_fim + ":\n";
			}
			;

DEC 		: TK_INT TK_ID ';'    { declarar_variavel($2.label, "int"); }
			| TK_FLOAT TK_ID ';'  { declarar_variavel($2.label, "float"); }
			| TK_CHAR TK_ID ';'   { declarar_variavel($2.label, "char"); }
			| TK_BOOL TK_ID ';'   { declarar_variavel($2.label, "bool"); }
			| TK_STRING TK_ID ';' { declarar_variavel($2.label, "string"); }
			;

TIPO		: TK_INT 	{ $$.label = "int"; }
			| TK_FLOAT 	{ $$.label = "float"; }
			| TK_CHAR 	{ $$.label = "char"; }
			| TK_BOOL 	{ $$.label = "bool"; }
			| TK_STRING { $$.label = "string"; }
			;

P       	: TK_NUM
        	{
        		$$.label = gentempcode();
        		$$.tipo = $1.tipo;
        		declaracoes += "\t" + $$.tipo + " " + $$.label + ";\n";
        		$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
        	}
        	| TK_ID
        	{
        			auto info = consultar_variavel($1.label);
        			$$.label = info.temp;
        			$$.tipo = info.tipo;
        			$$.traducao = "";
        	}
        	| TK_CHARLITERAL
        	{
        		$$.label = gentempcode();
        		$$.tipo = "char";
				declaracoes += "\tchar " + $$.label + ";\n";
        		$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
        	}
        	| TK_BOOLLIT
        	{
        		$$.label = gentempcode();
        		$$.tipo = "bool";
				declaracoes += "\tint " + $$.label + ";\n";
        		$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
        	}
			| TK_STRINGLITERAL
        	{
        		$$.label = gentempcode();
        		$$.tipo = "string";
				declaracoes += "\tchar* " + $$.label + ";\n";
        		$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
      		}
        	| '(' E ')'
        	{
        		$$.label = $2.label;
        		$$.tipo = $2.tipo;
        		$$.traducao = $2.traducao;
        	}
        	| '!' P
        	{
        		if ($2.tipo == "bool"){
        			$$.label = gentempcode();
        			$$.tipo = "bool";
        			declaracoes += "\tint " + $$.label + ";\n";
        			$$.traducao = $2.traducao + "\t" + $$.label + " = !" + $2.label + ";\n";
        		}
        		else{
        			yyerror("você está fazendo operações lógicas com tipos não booleanos");
        		}
        	}
			| '(' TIPO ')' P
			{
				if (!cast_valido($2.label, $4.tipo)){ //verifica se o cast é válido 
					yyerror("Conversão inválida de " + $4.tipo + " para " + $2.label);
				}
				else{
				string tipo_origem_c = ($4.tipo == "bool") ? "int" : ($4.tipo == "string") ? "char*" : $4.tipo;
				string tipo_destino_c = ($2.label == "bool") ? "int" : ($2.label == "string") ? "char*" : $2.label;

				string temp_original = gentempcode(); // Cria temporária para o tipo original
				declaracoes += "\t" + tipo_origem_c + " " + temp_original + ";\n"; // Declara a temporária original com o tipo do E

				string temp_cast = gentempcode(); // Cria temporária para o resultado do cast
				declaracoes += "\t" + tipo_destino_c + " " + temp_cast + ";\n"; // Declara a temporária cast com o tipo do cast

				$$.label = temp_cast; 
				$$.tipo = $2.label;

				$$.traducao = $4.traducao + 
				"\t" + temp_original + " = " + $4.label + ";\n" + // atribuição intermediária
				"\t" + $$.label + " = (" + $$.tipo + ") " + temp_original + ";\n"; // cast
				}
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
			| P
			{
				$$.label = $1.label;
				$$.tipo = $1.tipo;
				$$.traducao = $1.traducao;
			}
			| ATRIBUICAO 
			{
        		$$.label = $1.label;
                $$.tipo = $1.tipo;
                $$.traducao = $1.traducao;	
			}

%%

#include "lex.yy.c"

int yyparse();

string gentempcode()
{
	var_temp_qnt++;
	return "t" + to_string(var_temp_qnt);
}

string gen_label()
{
		return "L" + to_string(label_count++);
}

int main(int argc, char* argv[])
{
	var_temp_qnt = 0;
	erro_count = 0;

	tabela_escopos.push_back(map<string, info_var>()); //cria o escopo global

	if (yyparse() == 0 && erro_count == 0)
        cout << codigo_gerado;

	return 0;
}

void yyerror(string MSG)
{
	erro_count++;
	cerr << "Erro na linha " << linha << ": " << MSG << endl;
}

//funcao que fica responsável por fazer o cast
string castGerar(string cast_tipo, string label, string& cast_traducao){
	string temp = gentempcode(); 
	//gera a string temporaria q vai receber o resultado do cast
	declaracoes += "\t" + cast_tipo + " " + temp + ";\n";
	//faz a declaracao dessa nova string temporaria
	cast_traducao += "\t" + temp + " = " + "(" + cast_tipo + ") " + label + ";\n";
	 //faz a traducao para p codigo em c da nova string temporaria. Ex: t2 = (float)t1;
	return temp; 
	//retorna o novo label para um dos "E", pois um deles sofre o cast e 
	//muda o nome da variável
}

void operacoes(atributos& dd, atributos& d1, atributos& d3, string op, string op_tipo){
	if(eh_tipo_numerico(d1) && eh_tipo_numerico(d3)){
		auto cast = tabela_consulta[{d1.tipo, d3.tipo}]; 
		//consulta a tabela para saber se será necessário fazer cast
		if(op_tipo == "arit"){
			dd.tipo = cast.resultado; 
			//define o tipo de $$ conforme a necessidade de fazer cast ou n	
		}
		else{
			dd.tipo = "bool"; 
			//se for operação relacional, o tipo de $$(dd) sempre será bool
		}
		dd.label = gentempcode(); 
		string cast_traducao = d1.traducao + d3.traducao; 
		if(cast.cast_esq != ""){
			d1.label = castGerar(cast.cast_esq, d1.label, cast_traducao); 
			//chama a função q faz o cast caso seja necessário
		}
		if(cast.cast_dir != ""){
			d3.label = castGerar(cast.cast_dir, d3.label, cast_traducao); 
		}
		if(op_tipo == "arit"){
			declaracoes += "\t" + dd.tipo + " " + dd.label + ";\n";	
		}
		else{
			declaracoes += "\tint " + dd.label + ";\n";	
			//tratamento especial para o tipo bool pq ele n existe em C
		}
		
		dd.traducao = cast_traducao + "\t" + dd.label +
		" = " + d1.label + " " + op + " " + d3.label + ";\n";
	}
	else if(d1.tipo == "string" && d3.tipo == "string" && op == "=="){
		dd.tipo = "bool";
		dd.label = gentempcode();
		declaracoes += "\tint " + dd.label + ";\n";
		dd.traducao = d1.traducao + d3.traducao + "\t" + dd.label +
		 " = comparaString( " + d1.label + ", " + d3.label + " );\n";
	}
	else{
		yyerror("você está tentando operar com tipos nao numericos");
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
		yyerror("você está fazendo operações lógicas com tipos não booleanos");
	}
}

bool cast_valido(string destino, string origem) {

    if ((destino == "int" || destino == "float") && (origem == "int" || origem == "float")) 
        	return true;
			// Cast entre números é permitido

    return false; 
}

void declarar_variavel(string nome, string tipo){
	if(tabela_escopos.back().count(nome)){
		yyerror("variável " + nome + " já declarada nesse escopo");
	}
	else{
		string temp = gentempcode();
		tabela_escopos.back()[nome] = {temp, tipo};
		string tipo_c = (tipo == "bool") ? "int" : (tipo == "string") ? "char*" : tipo;
		declaracoes += "\t" + tipo_c +  " " + temp + ";\n";
	}

}

info_var consultar_variavel(string nome){
	for (int i = tabela_escopos.size() - 1; i >= 0; i--) {
    	if (tabela_escopos[i].count(nome)) {
        	auto info = tabela_escopos[i][nome];
         	return info;
    	}
	}
	yyerror("variável "+ nome +" não declarada");

	return {"", ""};
	}