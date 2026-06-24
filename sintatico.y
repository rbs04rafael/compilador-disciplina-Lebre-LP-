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
vector<string> pilha_break;
vector<string> pilha_continue;
vector<string> pilha_switch_temp;
vector<string> pilha_switch_tipo;
vector<string> lista_erros; 
string codigo_gerado;
string declaracoes;
string declaracoes_globais;
string tipo_retorno_atual; 
bool teve_retorno = false;
vector<string> declaracoes_anterior;
vector<string> tipos_parametros_atual;
string tipo_atual_decl;

struct info_var{
	string temp;
	string tipo;
	string dim = "";
};

vector<map<string, info_var>> tabela_escopos; 

// Estrutura para guardar a assinatura da função
struct info_funcao {
    string tipo_retorno;
    vector<string> tipos_parametros;
};

// Tabela global de funções (Nome da Função -> Informações)
map<string, info_funcao> tabela_funcoes;

// Nova string para guardar as funções fora do main
string codigo_funcoes = "";

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
void add_declaracao(string dec);
void declarar_variavel(string nome, string tipo);
void declarar_vetor(string nome, string tipo, string tamanho);
void declarar_matriz(string nome, string tipo, string tam1, string tam2);
info_var consultar_variavel(string nome);
string gen_label();
void atribuicao_composta(atributos& res, atributos& id, atributos& expressao, string operador);
void incremento_unario(atributos& res, atributos& id, string operador, bool eh_pre);
%}

%token TK_NUM TK_CHARLITERAL TK_BOOLLIT TK_STRINGLITERAL
%token TK_FLOAT TK_INT TK_CHAR TK_BOOL TK_STRING TK_VOID TK_VAR TK_ID
%token TK_MAI TK_MEI  TK_II TK_DF
%token TK_AND TK_OR
%token TK_IF TK_ELSE TK_ELSE_IF
%token TK_PRINT TK_SCAN
%token TK_WHILE TK_DO_WHILE TK_FOR TK_INC TK_DEC
%token TK_SWITCH TK_CASE TK_DEFAULT TK_BREAK TK_BREAK_ALL TK_CONTINUE
%token TK_RETORNA
%token TK_MAIS_IGUAL TK_MENOS_IGUAL TK_VEZES_IGUAL TK_DIV_IGUAL

%start S

%right '=' TK_MAIS_IGUAL TK_MENOS_IGUAL TK_VEZES_IGUAL TK_DIV_IGUAL
%left TK_OR
%left TK_AND
%left TK_II TK_DF '<' '>' TK_MEI TK_MAI
%left '+' '-'
%left '*' '/' '%'
%right '!'

%%

S           : LISTA_DEC
            {
                codigo_gerado = "\n/*Compilador FOCA*/\n"
                                "#include <stdio.h>\n"
								"#include <stdlib.h>\n"
								"#include <string.h>\n\n"
								"char* boolParaString(int b){\n"
                                "	if(b) return \"verdadeiro\";\n"
                                "	return \"falso\";\n"
                                "}\n\n"
								"int tamString(char* s){\n"
									"\tint t_len = 0;\n"
									"\tchar t_char;\n"
									"\tint t_cond;\n"
								"L_LOOP_STR:\n"
									"\tt_char = s[t_len];\n"
									"\tt_cond = t_char != '\\0';\n"
									"\tif (!t_cond) goto L_FIM_STR;\n"
									"\tt_len = t_len + 1;\n"
									"\tgoto L_LOOP_STR;\n"
								"L_FIM_STR:\n"
									"\treturn t_len;\n"
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
								"char* leiaString(){\n"
								"	int t_cap = 16;\n"
								"	int t_len = 0;\n"
								"	char* t_str;\n"
								"	int t_ch;\n"
								"	int t_cond1;\n"
								"	int t_cond2;\n"
								"	int t_soma;\n"
								"	t_str = (char*) malloc(t_cap);\n"
								"L_LEIA_LOOP:\n"
								"	t_ch = getchar();\n"
								"	t_cond1 = t_ch == '\\n';\n"
								"	if (t_cond1) goto L_LEIA_FIM;\n"
								"	t_cond2 = t_ch == -1;\n"
								"	if (t_cond2) goto L_LEIA_FIM;\n"
								"	t_str[t_len] = t_ch;\n"
								"	t_soma = t_len + 1;\n"
								"	t_len = t_soma;\n"
								"	t_cond1 = t_len == t_cap;\n"
								"	if (!t_cond1) goto L_LEIA_LOOP;\n"
								"	t_cap = t_cap * 2;\n"
								"	t_str = (char*) realloc(t_str, t_cap);\n"
								"	goto L_LEIA_LOOP;\n"
								"L_LEIA_FIM:\n"
								"	t_str[t_len] = '\\0';\n"
								"	return t_str;\n"
								"}\n\n";

                codigo_gerado += declaracoes_globais + "\n" + codigo_funcoes + "int main(void) {\n";

                codigo_gerado += declaracoes + "\n" + $1.traducao;

                codigo_gerado += "\n\treturn 0;"
                            "\n}\n\n";
            }
            ;

LISTA_DEC  : LISTA_DEC DEC
            {
                $$.traducao = $1.traducao + $2.traducao;
            }
            | LISTA_DEC E ';'
            {
                $$.traducao = $1.traducao + $2.traducao;
            }
			| LISTA_DEC FUNC
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
			| LISTA_DEC TK_PRINT '(' PRINT_ARGS ')' ';'
			{
				$$.traducao = $1.traducao + $4.traducao;
			}
			| LISTA_DEC TK_SCAN '(' SCAN_ARGS ')' ';'
			{
				$$.traducao = $1.traducao + $4.traducao;
			}
			| /* vazio */
            {
                $$.traducao = "";
            }
            ;
 FUNC       : TIPO_DECL TK_ID '('                                                                                                                                                                                 
                {                                                                                                                                                                                                
                    tipo_retorno_atual = $1.label;                                                                                                                                                               
                    teve_retorno = false;
                    tipos_parametros_atual.clear();                                                                                                                                                                                                                                                                          
                    declaracoes_anterior.push_back(declaracoes);
                    declaracoes = "";
                    tabela_escopos.push_back(map<string, info_var>());
                    nivel_escopo++;
                }
                PARAMETROS ')' '{' LISTA_DEC '}'
                {
                    if (tipo_retorno_atual != "void" && !teve_retorno) {
                        yyerror("Erro Semantico: A funcao " + $2.label + " exige um retorno, mas voce esqueceu do comando 'retorna'!");
                    }
                	tabela_funcoes[$2.label] = {$1.label, tipos_parametros_atual};

                    string tipo_c = ($1.label == "bool") ? "int" : ($1.label == "string") ? "char*" : ($1.label == "void") ? "void" : $1.label;

                    codigo_funcoes += tipo_c + " " + $2.label + "(" + $5.traducao + ") {\n" + declaracoes + $8.traducao + "}\n\n";

 					$$.traducao = "";
    				nivel_escopo--;
    				declaracoes = declaracoes_anterior.back();
    				declaracoes_anterior.pop_back();
					tabela_escopos.pop_back();
                }
				;
PARAMETROS 		: PARAMETRO ',' PARAMETROS
                {
                    $$.traducao = $1.traducao + ", " + $3.traducao;
                }
                | PARAMETRO
                {
  					$$.traducao = $1.traducao;
                }
				| /* vazio */
				{
					$$.traducao = "";
				}
                ;

PARAMETRO   : TIPO TK_ID
                {
                    tipos_parametros_atual.push_back($1.label);

                    // Cadastra a variável no escopo da função, mas sem colocar na string "declaracoes" 
                    // (pois ela já será declarada dentro dos parênteses da função)
                    string temp = gentempcode();
                    tabela_escopos.back()[$2.label] = {temp, $1.label};

                    string tipo_c = ($1.label == "bool") ? "int" : ($1.label == "string") ? "char*" : $1.label;
                    $$.traducao = tipo_c + " " + temp;
                }
            | TIPO TK_ID '[' ']'
                {
                    tipos_parametros_atual.push_back($1.label + "[]");
                    
                    string temp = gentempcode();
                    tabela_escopos.back()[$2.label] = {temp, $1.label};
                    
                    string tipo_c = ($1.label == "bool") ? "int" : ($1.label == "string") ? "char*" : $1.label;
                    $$.traducao = tipo_c + " *" + temp;
                }
            | TIPO TK_ID '[' ']' '[' TK_NUM ']'
                {
                    tipos_parametros_atual.push_back($1.label + "[][]");
                    
                    string temp = gentempcode();
                    tabela_escopos.back()[$2.label] = {temp, $1.label, $6.label};
                    
                    string tipo_c = ($1.label == "bool") ? "int" : ($1.label == "string") ? "char*" : $1.label;
                    $$.traducao = tipo_c + " *" + temp;
                }
                ;
ARGS_CHAMADA : E ',' ARGS_CHAMADA
             {
                 $$.traducao = $1.traducao + $3.traducao;
                 $$.label = $1.label + ", " + $3.label;
                 $$.tipo = $1.tipo + "," + $3.tipo;
             }
             | E
             {
                 $$.traducao = $1.traducao;
                 $$.label = $1.label;
                 $$.tipo = $1.tipo;
             }
             | /* vazio */
             {
                 $$.traducao = "";
                 $$.label = "";
                 $$.tipo = "";
             }
             ;

VALOR_LITERAL : TK_NUM { $$.label = $1.label; }
              | TK_CHARLITERAL { $$.label = $1.label; }
              | TK_BOOLLIT { $$.label = $1.label; }
              | TK_STRINGLITERAL { $$.label = $1.label; }
              ;

VALORES_VETOR : VALORES_VETOR ',' VALOR_LITERAL
              {
                  $$.label = $1.label + ", " + $3.label;
              }
              | VALOR_LITERAL
              {
                  $$.label = $1.label;
              }
              ;

LINHA_MATRIZ : '{' VALORES_VETOR '}'
             {
                 $$.label = $2.label;
             }
             ;

VALORES_MATRIZ : VALORES_MATRIZ ',' LINHA_MATRIZ
               {
                   $$.label = $1.label + ", " + $3.label;
               }
               | LINHA_MATRIZ
               {
                   $$.label = $1.label;
               }
               ;

SCAN_VAR : TK_ID
        {
            auto info = consultar_variavel($1.label);
            string formato = "";
            if (info.tipo == "int" || info.tipo == "bool") formato = "%d";
            else if (info.tipo == "float") formato = "%f";
            else if (info.tipo == "char") formato = "%c";

            if(info.tipo == "string"){
                string temp_cond = gentempcode();
                string label_skip = gen_label();
                add_declaracao( "\tint " + temp_cond + ";\n");

                $$.traducao = "\t" + temp_cond + " = " + info.temp + " != NULL;\n" +
                "\tif (!" + temp_cond + ") goto " + label_skip + ";\n" +
                "\tfree(" + info.temp + ");\n" +
                label_skip + ":\n" +
                "\t" + info.temp + " = leiaString();\n";
            } else {
                $$.traducao = "\tscanf(\"" + formato + "\", &" + info.temp + ");\n";
            }
        }
        | TK_ID '[' E ']'
        {
            auto info = consultar_variavel($1.label);
            if ($3.tipo != "int") yyerror("Erro: O indice do vetor deve ser inteiro!");

            string tipo_c = (info.tipo == "bool") ? "int" : (info.tipo == "string") ? "char*" : info.tipo;
            string t_ptr = gentempcode();
            add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
            
            string addr_calc = $3.traducao + "\t" + t_ptr + " = " + info.temp + " + " + $3.label + ";\n";

            string formato = "";
            if (info.tipo == "int" || info.tipo == "bool") formato = "%d";
            else if (info.tipo == "float") formato = "%f";
            else if (info.tipo == "char") formato = "%c";

            if(info.tipo == "string"){
                string temp_cond = gentempcode();
                string label_skip = gen_label();
                add_declaracao( "\tint " + temp_cond + ";\n");
                $$.traducao = addr_calc + "\t" + temp_cond + " = *" + t_ptr + " != NULL;\n" +
                "\tif (!" + temp_cond + ") goto " + label_skip + ";\n" +
                "\tfree(*" + t_ptr + ");\n" +
                label_skip + ":\n" +
                "\t*" + t_ptr + " = leiaString();\n";
            } else {
                $$.traducao = addr_calc + "\tscanf(\"" + formato + "\", " + t_ptr + ");\n";
            }
        }
        | TK_ID '[' E ']' '[' E ']'
        {
            auto info = consultar_variavel($1.label);
            if ($3.tipo != "int" || $6.tipo != "int") yyerror("Erro: Os indices da matriz devem ser inteiros!");

            string tipo_c = (info.tipo == "bool") ? "int" : (info.tipo == "string") ? "char*" : info.tipo;
            string t_mult = gentempcode();
            string t_soma = gentempcode();
            string t_ptr = gentempcode();
            add_declaracao( "\tint " + t_mult + ";\n");
            add_declaracao( "\tint " + t_soma + ";\n");
            add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
            
            string addr_calc = $3.traducao + $6.traducao + 
                            "\t" + t_mult + " = " + $3.label + " * " + info.dim + ";\n" +
                            "\t" + t_soma + " = " + t_mult + " + " + $6.label + ";\n" +
                            "\t" + t_ptr + " = " + info.temp + " + " + t_soma + ";\n";

            string formato = "";
            if (info.tipo == "int" || info.tipo == "bool") formato = "%d";
            else if (info.tipo == "float") formato = "%f";
            else if (info.tipo == "char") formato = "%c";

            if(info.tipo == "string"){
                string temp_cond = gentempcode();
                string label_skip = gen_label();
                add_declaracao( "\tint " + temp_cond + ";\n");
                $$.traducao = addr_calc + "\t" + temp_cond + " = *" + t_ptr + " != NULL;\n" +
                "\tif (!" + temp_cond + ") goto " + label_skip + ";\n" +
                "\tfree(*" + t_ptr + ");\n" +
                label_skip + ":\n" +
                "\t*" + t_ptr + " = leiaString();\n";
            } else {
                $$.traducao = addr_calc + "\tscanf(\"" + formato + "\", " + t_ptr + ");\n";
            }
        }
        ;

SCAN_ARGS 	: SCAN_ARGS ',' SCAN_VAR
			{
				$$.traducao = $1.traducao + $3.traducao;
			}
			| SCAN_VAR
			{
				$$.traducao = $1.traducao;
			}
			;

PRINT_ARGS  : PRINT_ARGS ',' E
			{
    			string formato = "";
                string valor_impresso = $3.label;
                string prep_traducao = ""; 

    			if ($3.tipo == "int") formato = "%d\\n";
    			else if ($3.tipo == "float") formato = "%f\\n";
    			else if ($3.tipo == "string") formato = "%s\\n";
				else if ($3.tipo == "char") formato = "%c\\n";
                else if ($3.tipo == "bool") {
                    formato = "%s\\n";
                    string temp_str = gentempcode();
                    add_declaracao( "\tchar* " + temp_str + ";\n");
                    prep_traducao = "\t" + temp_str + " = boolParaString(" + $3.label + ");\n";
                    valor_impresso = temp_str;
                }

				string print_cmd = "\tprintf(\"" + formato + "\", " + valor_impresso + ");\n";

    			$$.traducao = $1.traducao + $3.traducao + prep_traducao + print_cmd;
			}
			| E
			{
   				string formato = "";
                string valor_impresso = $1.label;
                string prep_traducao = "";

    			if ($1.tipo == "int") formato = "%d\\n";
    			else if ($1.tipo == "float") formato = "%f\\n";
    			else if ($1.tipo == "string") formato = "%s\\n";
				else if ($1.tipo == "char") formato = "%c\\n";
                else if ($1.tipo == "bool") {
                    formato = "%s\\n";
                    string temp_str = gentempcode();
                    add_declaracao( "\tchar* " + temp_str + ";\n");
                    prep_traducao = "\t" + temp_str + " = boolParaString(" + $1.label + ");\n";
                    valor_impresso = temp_str;
                }
    
   				string print_cmd = "\tprintf(\"" + formato + "\", " + valor_impresso + ");\n";
				$$.traducao = $1.traducao + prep_traducao + print_cmd;
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

FOR_INIT : ATRIBUICAO
         {
             $$.traducao = $1.traducao;
         }
         | TIPO_DECL TK_ID '=' E
         {
             tipo_atual_decl = $1.label;
             declarar_variavel($2.label, tipo_atual_decl);
             auto info = consultar_variavel($2.label);
             $$.label = info.temp;
             $$.tipo = info.tipo;

             if (info.tipo != $4.tipo) {
                 if (info.tipo == "float" && $4.tipo == "int") 
                     $4.label = castGerar("float", $4.label, $4.traducao); 
                 else if (info.tipo == "int" && $4.tipo == "float") 
                     $4.label = castGerar("int", $4.label, $4.traducao);
                 else 
                     yyerror("tipos incompativeis para atribuicao"); 
             }
             $$.traducao = $4.traducao + "\t" + $$.label + " = " + $4.label + ";\n";
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
			| TK_DO_WHILE
			{
				pilha_continue.push_back(gen_label());
				pilha_break.push_back(gen_label());
			}
			BLOCO TK_WHILE '(' E ')' ';'
			{
				if($6.tipo != "bool")
					yyerror("A condicao do 'faca enquanto' nao foi do tipo logico!");
				string label_inicio = gen_label();
				string label_fim = pilha_break.back();
				
				$$.traducao = label_inicio + ":\n" 
				 + $3.traducao 
				 + pilha_continue.back() + ":\n" 
				 + $6.traducao 
				 + "\tif (!" + $6.label + ") goto " + label_fim + ";\n" 
				 + "\tgoto " + label_inicio + ";\n" 
				 + label_fim + ":\n"; 
				pilha_continue.pop_back();
				pilha_break.pop_back();
			}
			| TK_FOR '(' 
			{
				tabela_escopos.push_back(map<string, info_var>());
				nivel_escopo++;
			}
			FOR_INIT ';' E ';' ATRIBUICAO ')' 
			{
				pilha_continue.push_back(gen_label());
				pilha_break.push_back(gen_label());
			}
			BLOCO
			{
				if($6.tipo != "bool")
					yyerror("A condicao do 'para' nao foi do tipo logico!");

				string label_inicio = gen_label();
				string label_fim = pilha_break.back();
				
				$$.traducao = $4.traducao + label_inicio + ":\n"
				+ $6.traducao + "\tif (!" + $6.label + ") goto " + label_fim + ";\n"
				+ $11.traducao + pilha_continue.back() + ":\n" + $8.traducao
				+ "\tgoto " + label_inicio + ";\n"
				+ label_fim + ":\n"; 
				pilha_continue.pop_back();
				pilha_break.pop_back();

				tabela_escopos.pop_back();
				nivel_escopo--;
			}
			| TK_SWITCH '(' E ')' '{' 
			{
    			pilha_switch_temp.push_back($3.label);
    			pilha_switch_tipo.push_back($3.tipo);
    			pilha_break.push_back(gen_label());
			} 
			CASOS '}'
			{
    		$$.traducao = $3.traducao + $7.traducao + pilha_break.back() + ":\n";
    		pilha_switch_temp.pop_back();
    		pilha_switch_tipo.pop_back();
    		pilha_break.pop_back();
			}
			| TK_BREAK ';'
        	{
        		if (pilha_break.empty()) 
        			yyerror("O 'pare' so pode ser usado dentro de um laco ou escolha");
				else 
        			$$.traducao = "\tgoto " + pilha_break.back() + ";\n";
      		}
			| TK_BREAK TK_NUM ';'
			{
				int saltos = stoi($2.label);
				if (saltos <= 0 || saltos > pilha_break.size()) {
					yyerror("O numero de saltos no 'pare' e invalido para o contexto atual!");
					$$.traducao = "";
				} else {
					int indice_alvo = pilha_break.size() - saltos;
					$$.traducao = "\tgoto " + pilha_break[indice_alvo] + ";\n";
				}
			}
			| TK_BREAK_ALL ';'
        	{
        		if (pilha_break.empty()) 
        			yyerror("O 'pare_tudo' so pode ser usado dentro de um laco ou escolha");
				else 
        			$$.traducao = "\tgoto " + pilha_break.front() + ";\n";
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
			| TK_RETORNA ';'
			{
				teve_retorno = true;
				if (tipo_retorno_atual != "void") {
					yyerror("Erro: Esta funcao exige um retorno, mas voce usou um retorna vazio!");
				}
				$$.traducao = "\treturn;\n";
			}
			| TK_RETORNA E ';'
                {
					teve_retorno = true;
					if (tipo_retorno_atual == "void") {
						yyerror("Erro: Um procedimento (vazio) nao pode retornar valores!");
					}
                    else if ($2.tipo != tipo_retorno_atual) {
                        if (tipo_retorno_atual == "float" && $2.tipo == "int") 
                            $2.label = castGerar("float", $2.label, $2.traducao); 
                        else if (tipo_retorno_atual == "int" && $2.tipo == "float") 
                            $2.label = castGerar("int", $2.label, $2.traducao);
                        else 
                            yyerror("Tipo de retorno invalido!"); 
                    }
                    $$.traducao = $2.traducao + "\treturn " + $2.label + ";\n";
                }
			;
CASO   	: TK_CASE E ':' LISTA_DEC
			{
				string temp_switch = pilha_switch_temp.back();
				string tipo_switch = pilha_switch_tipo.back();
				string temp_cmp = gentempcode();
				add_declaracao( "\tint " + temp_cmp + ";\n");

				string label_proximo = gen_label();
				string condicao;

				if (tipo_switch != $2.tipo) {
					yyerror("Tipo do caso (" + $2.tipo + ") incompativel com o tipo do escolha (" + tipo_switch + ")!");
				}

				if (tipo_switch == "string" && $2.tipo == "string") {
					condicao = "\t" + temp_cmp + " = comparaString(" + temp_switch + ", " + $2.label + ");\n";
				} else {
					condicao = "\t" + temp_cmp + " = " + temp_switch + " == " + $2.label + ";\n";
				}

				$$.traducao = $2.traducao + condicao
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
						string temp_len = gentempcode();
						string temp_soma = gentempcode();
						string temp_malloc = gentempcode();
						string temp_cond = gentempcode();
						string label_skip = gen_label();
						
						add_declaracao( "\tint " + temp_len + ";\n");
						add_declaracao( "\tint " + temp_soma + ";\n");
						add_declaracao( "\tvoid* " + temp_malloc + ";\n");
						add_declaracao( "\tint " + temp_cond + ";\n");
						
						$$.traducao = $3.traducao + "\t" + temp_cond + " = " + $$.label + " != NULL;\n"
						+ "\tif (!" + temp_cond + ") goto " + label_skip + ";\n" 
						+ "\tfree(" + $$.label + ");\n" 
						+ label_skip + ":\n"
						+ "\t" + temp_len + " = tamString(" + $3.label + ");\n"
						+ "\t" + temp_soma + " = " + temp_len + " + 1;\n"
						+ "\t" + temp_malloc + " = malloc(" + temp_soma + ");\n" 
						+ "\t" + $$.label + " = (char*) " + temp_malloc + ";\n" 
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
			| TK_INC TK_ID  { incremento_unario($$, $2, "+", true);  }
			| TK_DEC TK_ID  { incremento_unario($$, $2, "-", true);  }
			| TK_ID TK_INC  { incremento_unario($$, $1, "+", false); }
			| TK_ID TK_DEC  { incremento_unario($$, $1, "-", false); }
			| TK_ID TK_MAIS_IGUAL E		 { atribuicao_composta($$, $1, $3, "+"); }
			| TK_ID TK_MENOS_IGUAL E	 { atribuicao_composta($$, $1, $3, "-"); }
			| TK_ID TK_VEZES_IGUAL E	 { atribuicao_composta($$, $1, $3, "*"); }
			| TK_ID TK_DIV_IGUAL E		 { atribuicao_composta($$, $1, $3, "/"); }
			| TK_ID '[' E ']' '=' E
            {
                auto info = consultar_variavel($1.label);
                if ($3.tipo != "int") yyerror("Erro: O indice do vetor deve ser inteiro!");

                if (info.tipo != $6.tipo) yyerror("Erro: Tipos incompativeis para atribuicao no vetor!");

                $$.tipo = info.tipo;
                string tipo_c = (info.tipo == "bool") ? "int" : (info.tipo == "string") ? "char*" : info.tipo;
                
                string t_ptr = gentempcode();
                add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
                
                if (info.tipo == "string") {
                    string temp_len = gentempcode();
                    string temp_soma = gentempcode();
                    string temp_malloc = gentempcode();
                    string temp_cond = gentempcode();
                    string label_skip = gen_label();
                    
                    add_declaracao( "\tint " + temp_len + ";\n");
                    add_declaracao( "\tint " + temp_soma + ";\n");
                    add_declaracao( "\tvoid* " + temp_malloc + ";\n");
                    add_declaracao( "\tint " + temp_cond + ";\n");
                    
                    $$.traducao = $3.traducao + $6.traducao 
                                + "\t" + t_ptr + " = " + info.temp + " + " + $3.label + ";\n"
                                + "\t" + temp_cond + " = *" + t_ptr + " != NULL;\n"
                                + "\tif (!" + temp_cond + ") goto " + label_skip + ";\n"
                                + "\tfree(*" + t_ptr + ");\n"
                                + label_skip + ":\n"
                                + "\t" + temp_len + " = tamString(" + $6.label + ");\n"
                                + "\t" + temp_soma + " = " + temp_len + " + 1;\n"
                                + "\t" + temp_malloc + " = malloc(" + temp_soma + ");\n"
                                + "\t*" + t_ptr + " = (char*) " + temp_malloc + ";\n"
                                + "\tstrcpy(*" + t_ptr + ", " + $6.label + ");\n";
                } else {
                    $$.traducao = $3.traducao + $6.traducao 
                                + "\t" + t_ptr + " = " + info.temp + " + " + $3.label + ";\n"
                                + "\t*" + t_ptr + " = " + $6.label + ";\n";
                }
            }
			| TK_ID '[' E ']' '[' E ']' '=' E
            {
                auto info = consultar_variavel($1.label);
                if ($3.tipo != "int" || $6.tipo != "int") yyerror("Erro: Os indices da matriz devem ser inteiros!");

                if (info.tipo != $9.tipo) yyerror("Erro: Tipos incompativeis para atribuicao na matriz!");

                $$.tipo = info.tipo;
                string tipo_c = (info.tipo == "bool") ? "int" : (info.tipo == "string") ? "char*" : info.tipo;
                
                string t_mult = gentempcode();
                string t_soma = gentempcode();
                string t_ptr = gentempcode();
                add_declaracao( "\tint " + t_mult + ";\n");
                add_declaracao( "\tint " + t_soma + ";\n");
                add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
                
                string calc = "\t" + t_mult + " = " + $3.label + " * " + info.dim + ";\n" +
                              "\t" + t_soma + " = " + t_mult + " + " + $6.label + ";\n" +
                              "\t" + t_ptr + " = " + info.temp + " + " + t_soma + ";\n";
                
                if (info.tipo == "string") {
                    string temp_len = gentempcode();
                    string temp_soma = gentempcode();
                    string temp_malloc = gentempcode();
                    string temp_cond = gentempcode();
                    string label_skip = gen_label();
                    
                    add_declaracao( "\tint " + temp_len + ";\n");
                    add_declaracao( "\tint " + temp_soma + ";\n");
                    add_declaracao( "\tvoid* " + temp_malloc + ";\n");
                    add_declaracao( "\tint " + temp_cond + ";\n");
                    
                    $$.traducao = $3.traducao + $6.traducao + $9.traducao + calc
                                + "\t" + temp_cond + " = *" + t_ptr + " != NULL;\n"
                                + "\tif (!" + temp_cond + ") goto " + label_skip + ";\n"
                                + "\tfree(*" + t_ptr + ");\n"
                                + label_skip + ":\n"
                                + "\t" + temp_len + " = tamString(" + $9.label + ");\n"
                                + "\t" + temp_soma + " = " + temp_len + " + 1;\n"
                                + "\t" + temp_malloc + " = malloc(" + temp_soma + ");\n"
                                + "\t*" + t_ptr + " = (char*) " + temp_malloc + ";\n"
                                + "\tstrcpy(*" + t_ptr + ", " + $9.label + ");\n";
                } else {
                    $$.traducao = $3.traducao + $6.traducao + $9.traducao + calc
                                + "\t*" + t_ptr + " = " + $9.label + ";\n";
                }
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

DEC 		: TIPO_DECL LISTA_VARIAVEIS ';'
			{
				$$.traducao = $2.traducao;
			}
			| TK_VAR TK_ID '=' E ';'
			{ 
				string tipo_inferido = $4.tipo;
				declarar_variavel($2.label, tipo_inferido);
				auto info = consultar_variavel($2.label); 
        		$$.label = info.temp;
        		$$.tipo = info.tipo;

				if(info.tipo == "string"){
					string temp_len = gentempcode();
					string temp_soma = gentempcode();
					string temp_malloc = gentempcode();
					string temp_cond = gentempcode();
					string label_skip = gen_label();
					
					add_declaracao( "\tint " + temp_len + ";\n");
					add_declaracao( "\tint " + temp_soma + ";\n");
					add_declaracao( "\tvoid* " + temp_malloc + ";\n");
					add_declaracao( "\tint " + temp_cond + ";\n");
					
					$$.traducao = $4.traducao + "\t" + temp_cond + " = " + $$.label + " != NULL;\n"
					+ "\tif (!" + temp_cond + ") goto " + label_skip + ";\n" 
					+ "\tfree(" + $$.label + ");\n" 
					+ label_skip + ":\n"
					+ "\t" + temp_len + " = tamString(" + $4.label + ");\n"
					+ "\t" + temp_soma + " = " + temp_len + " + 1;\n"
					+ "\t" + temp_malloc + " = malloc(" + temp_soma + ");\n" 
					+ "\t" + $$.label + " = (char*) " + temp_malloc + ";\n" 
					+ "\tstrcpy(" + $$.label + ", " + $4.label + ");\n";
				} else { 
        			$$.traducao = $4.traducao + "\t" + $$.label + " = " + $4.label + ";\n";
				}
			}
			;

LISTA_VARIAVEIS : VARIAVEL ',' LISTA_VARIAVEIS
                  { $$.traducao = $1.traducao + $3.traducao; }
                | VARIAVEL
                  { $$.traducao = $1.traducao; }
                ;

VARIAVEL    : TK_ID 
              { declarar_variavel($1.label, tipo_atual_decl); $$.traducao = ""; }
			| TK_ID '[' TK_NUM ']'
			{
                    if ($3.tipo != "int") 
						yyerror("O tamanho do vetor deve ser inteiro!");

                    declarar_vetor($1.label, tipo_atual_decl, $3.label);
                    $$.traducao = "";
			}
			| TK_ID '[' TK_NUM ']' '[' TK_NUM ']'
			{
                    if ($3.tipo != "int" || $6.tipo != "int") 
						yyerror("Os tamanhos da matriz devem ser inteiros!");

                    declarar_matriz($1.label, tipo_atual_decl, $3.label, $6.label);
                    $$.traducao = "";
			}
			| TK_ID '[' TK_NUM ']' '[' TK_NUM ']' '=' '{' VALORES_MATRIZ '}'
			{
                    if ($3.tipo != "int" || $6.tipo != "int") 
						yyerror("Os tamanhos da matriz devem ser inteiros!");

                    if(tabela_escopos.back().count($1.label)) {
                        yyerror("matriz " + $1.label + " ja declarada nesse escopo");
                    } else {
                        string temp = gentempcode();
                        tabela_escopos.back()[$1.label] = {temp, tipo_atual_decl, $6.label};
                        string tipo_c = (tipo_atual_decl == "bool") ? "int" : (tipo_atual_decl == "string") ? "char*" : tipo_atual_decl;
                        
                        int total = stoi($3.label) * stoi($6.label);
                        add_declaracao( "\t" + tipo_c + " " + temp + "[" + to_string(total) + "];\n");
                        
                        int limite = stoi($3.label) * stoi($6.label);
                        string values = $10.label;
                        string traducao_init = "";
                        int idx = 0;
                        size_t pos = 0;
                        while ((pos = values.find(',')) != string::npos) {
                            if (idx >= limite) {
                                yyerror("Erro Semantico: A matriz passou do limite de itens declarados!");
                                break;
                            }
                            string val = values.substr(0, pos);
                            string t_ptr = gentempcode();
                            add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
                            traducao_init += "\t" + t_ptr + " = " + temp + " + " + to_string(idx) + ";\n";
                            traducao_init += "\t*" + t_ptr + " = " + val + ";\n";
                            values.erase(0, pos + 1);
                            idx++;
                        }
                        if (!values.empty() && values != " ") {
                            if (idx >= limite) {
                                yyerror("Erro Semantico: A matriz passou do limite de itens declarados!");
                            } else {
                                string t_ptr = gentempcode();
                                add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
                                traducao_init += "\t" + t_ptr + " = " + temp + " + " + to_string(idx) + ";\n";
                                traducao_init += "\t*" + t_ptr + " = " + values + ";\n";
                            }
                        }
                        $$.traducao = traducao_init;
                    }
			}
			| TK_ID '[' TK_NUM ']' '=' '{' VALORES_VETOR '}'
			{
                    if ($3.tipo != "int") 
						yyerror("O tamanho do vetor deve ser inteiro!");

                    if(tabela_escopos.back().count($1.label)) {
                        yyerror("vetor " + $1.label + " ja declarado nesse escopo");
                    } else {
                        string temp = gentempcode();
                        tabela_escopos.back()[$1.label] = {temp, tipo_atual_decl, "1D"};
                        string tipo_c = (tipo_atual_decl == "bool") ? "int" : (tipo_atual_decl == "string") ? "char*" : tipo_atual_decl;
                        
                        add_declaracao( "\t" + tipo_c + " " + temp + "[" + $3.label + "];\n");
                        
                        int limite = stoi($3.label);
                        string values = $7.label;
                        string traducao_init = "";
                        int idx = 0;
                        size_t pos = 0;
                        while ((pos = values.find(',')) != string::npos) {
                            if (idx >= limite) {
                                yyerror("Erro Semantico: O vetor passou do limite de itens declarados!");
                                break;
                            }
                            string val = values.substr(0, pos);
                            string t_ptr = gentempcode();
                            add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
                            traducao_init += "\t" + t_ptr + " = " + temp + " + " + to_string(idx) + ";\n";
                            traducao_init += "\t*" + t_ptr + " = " + val + ";\n";
                            values.erase(0, pos + 1);
                            idx++;
                        }
                        if (!values.empty() && values != " ") {
                            if (idx >= limite) {
                                yyerror("Erro Semantico: O vetor passou do limite de itens declarados!");
                            } else {
                                string t_ptr = gentempcode();
                                add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
                                traducao_init += "\t" + t_ptr + " = " + temp + " + " + to_string(idx) + ";\n";
                                traducao_init += "\t*" + t_ptr + " = " + values + ";\n";
                            }
                        }
                        $$.traducao = traducao_init;
                    }
			}
			| TK_ID '=' E
			{ 
				declarar_variavel($1.label, tipo_atual_decl);
				auto info = consultar_variavel($1.label); 
        			$$.label = info.temp;
        			$$.tipo = info.tipo;

					if(info.tipo == "string"){
						string temp_len = gentempcode();
						string temp_soma = gentempcode();
						string temp_malloc = gentempcode();
						string temp_cond = gentempcode();
						string label_skip = gen_label();
						
						add_declaracao( "\tint " + temp_len + ";\n");
						add_declaracao( "\tint " + temp_soma + ";\n");
						add_declaracao( "\tvoid* " + temp_malloc + ";\n");
						add_declaracao( "\tint " + temp_cond + ";\n");
						
						$$.traducao = $3.traducao + "\t" + temp_cond + " = " + $$.label + " != NULL;\n"
						+ "\tif (!" + temp_cond + ") goto " + label_skip + ";\n" 
						+ "\tfree(" + $$.label + ");\n" 
						+ label_skip + ":\n"
						+ "\t" + temp_len + " = tamString(" + $3.label + ");\n"
						+ "\t" + temp_soma + " = " + temp_len + " + 1;\n"
						+ "\t" + temp_malloc + " = malloc(" + temp_soma + ");\n" 
						+ "\t" + $$.label + " = (char*) " + temp_malloc + ";\n" 
						+ "\tstrcpy(" + $$.label + ", " + $3.label + ");\n";
					}else{ 
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
			;

TIPO		: TK_INT 	{ $$.label = "int"; }
			| TK_FLOAT 	{ $$.label = "float"; }
			| TK_CHAR 	{ $$.label = "char"; }
			| TK_BOOL 	{ $$.label = "bool"; }
			| TK_STRING { $$.label = "string"; }
			| TK_VOID   { $$.label = "void"; }
			;

TIPO_DECL   : TIPO
            {
                tipo_atual_decl = $1.label;
                $$.label = $1.label;
            }
            ;

P       	: TK_NUM
        	{
        		$$.label = gentempcode();
        		$$.tipo = $1.tipo;
        		add_declaracao( "\t" + $$.tipo + " " + $$.label + ";\n");
        		$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
        	}
        	| TK_ID
        	{
        			auto info = consultar_variavel($1.label);
        			$$.label = info.temp;
                    if (info.dim == "1D") {
                        $$.tipo = info.tipo + "[]";
                    } else if (info.dim != "") {
                        $$.tipo = info.tipo + "[][]";
                    } else {
        			    $$.tipo = info.tipo;
                    }
        			$$.traducao = "";
        	}
        	| TK_ID '[' E ']'
        	{
            	auto info = consultar_variavel($1.label);
            	if ($3.tipo != "int") yyerror("Erro: O indice do vetor deve ser inteiro!");
            
            	$$.tipo = info.tipo;
            	$$.label = gentempcode();
            
            	string tipo_c = ($$.tipo == "bool") ? "int" : ($$.tipo == "string") ? "char*" : $$.tipo;
            	add_declaracao( "\t" + tipo_c + " " + $$.label + ";\n");
                
                string t_ptr = gentempcode();
                add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
            
            	$$.traducao = $3.traducao + "\t" + t_ptr + " = " + info.temp + " + " + $3.label + ";\n" 
                            + "\t" + $$.label + " = *" + t_ptr + ";\n";
        	}
        	| TK_ID '[' E ']' '[' E ']'
        	{
            	auto info = consultar_variavel($1.label);
            	if ($3.tipo != "int" || $6.tipo != "int") yyerror("Erro: Os indices da matriz devem ser inteiros!");
            
            	$$.tipo = info.tipo;
            	$$.label = gentempcode();
            
            	string tipo_c = ($$.tipo == "bool") ? "int" : ($$.tipo == "string") ? "char*" : $$.tipo;
            	add_declaracao( "\t" + tipo_c + " " + $$.label + ";\n");
            
                string t_mult = gentempcode();
                string t_soma = gentempcode();
                string t_ptr = gentempcode();
                add_declaracao( "\tint " + t_mult + ";\n");
                add_declaracao( "\tint " + t_soma + ";\n");
                add_declaracao( "\t" + tipo_c + " *" + t_ptr + ";\n");
                
                string calc = "\t" + t_mult + " = " + $3.label + " * " + info.dim + ";\n" +
                              "\t" + t_soma + " = " + t_mult + " + " + $6.label + ";\n" +
                              "\t" + t_ptr + " = " + info.temp + " + " + t_soma + ";\n";
            
            	$$.traducao = $3.traducao + $6.traducao + calc + "\t" + $$.label + " = *" + t_ptr + ";\n";
        	}
        	| TK_ID '(' ARGS_CHAMADA ')'
        	{
            	if (!tabela_funcoes.count($1.label)) {
                	yyerror("Erro: funcao " + $1.label + " nao declarada!");
            	} else {
                	auto info_func = tabela_funcoes[$1.label];
                    
                    vector<string> args_tipos;
                    string types_str = $3.tipo;
                    if (!types_str.empty()) {
                        size_t pos = 0;
                        while ((pos = types_str.find(',')) != string::npos) {
                            args_tipos.push_back(types_str.substr(0, pos));
                            types_str.erase(0, pos + 1);
                        }
                        args_tipos.push_back(types_str);
                    }
                    
                    if (args_tipos.size() != info_func.tipos_parametros.size()) {
                        yyerror("Erro Semantico: A funcao " + $1.label + " esperava " + to_string(info_func.tipos_parametros.size()) + " argumentos, mas recebeu " + to_string(args_tipos.size()) + "!");
                    } else {
                        for (size_t i = 0; i < args_tipos.size(); i++) {
                            if (args_tipos[i] != info_func.tipos_parametros[i]) {
                                bool cast_ok = (args_tipos[i] == "int" || args_tipos[i] == "float") && 
                                               (info_func.tipos_parametros[i] == "int" || info_func.tipos_parametros[i] == "float");
                                if (!cast_ok) {
                                    yyerror("Erro Semantico: O argumento " + to_string(i+1) + " da funcao " + $1.label + " tem tipo incompativel (esperado: " + info_func.tipos_parametros[i] + ", recebido: " + args_tipos[i] + ")!");
                                }
                            }
                        }
                    }

                	$$.tipo = info_func.tipo_retorno;
                	if ($$.tipo == "void") {
                	    $$.label = "";
                	    $$.traducao = $3.traducao + "\t" + $1.label + "(" + $3.label + ");\n";
                	} else {
                	    $$.label = gentempcode();
                	    string tipo_c = ($$.tipo == "bool") ? "int" : ($$.tipo == "string") ? "char*" : $$.tipo;
                	    add_declaracao( "\t" + tipo_c + " " + $$.label + ";\n");
                	    $$.traducao = $3.traducao + "\t" + $$.label + " = " + $1.label + "(" + $3.label + ");\n";
                	}
            	}
        	}
        	| TK_CHARLITERAL
        	{
        		$$.label = gentempcode();
        		$$.tipo = "char";
				add_declaracao( "\tchar " + $$.label + ";\n");
        		$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
        	}
        	| TK_BOOLLIT
        	{
        		$$.label = gentempcode();
        		$$.tipo = "bool";
				add_declaracao( "\tint " + $$.label + ";\n");
        		$$.traducao = "\t" + $$.label + " = " + $1.label + ";\n";
        	}
			| TK_STRINGLITERAL
        	{
        		$$.label = gentempcode();
        		$$.tipo = "string";
				add_declaracao( "\tchar* " + $$.label + ";\n");
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
        			add_declaracao( "\tint " + $$.label + ";\n");
        			$$.traducao = $2.traducao + "\t" + $$.label + " = !" + $2.label + ";\n";
        		}
        		else{
        			yyerror("você está fazendo operações lógicas com tipos não booleanos");
        		}
        	}
        	| '-' P
        	{
        		if ($2.tipo == "int" || $2.tipo == "float"){
        			$$.label = gentempcode();
        			$$.tipo = $2.tipo;
        			string tipo_c = ($$.tipo == "float") ? "float" : "int";
        			add_declaracao( "\t" + tipo_c + " " + $$.label + ";\n");
        			$$.traducao = $2.traducao + "\t" + $$.label + " = -" + $2.label + ";\n";
        		}
        		else{
        			yyerror("você está usando o operador unário negativo com tipos não numéricos");
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
				add_declaracao( "\t" + tipo_origem_c + " " + temp_original + ";\n"); // Declara a temporária original com o tipo do E

				string temp_cast = gentempcode(); // Cria temporária para o resultado do cast
				add_declaracao( "\t" + tipo_destino_c + " " + temp_cast + ";\n"); // Declara a temporária cast com o tipo do cast

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
			| E '%' E
			{
                if ($1.tipo != "int" || $3.tipo != "int") {
                    yyerror("O operador '%' so pode ser usado com inteiros!");
                    $$.tipo = "int";
                    $$.label = "0";
                    $$.traducao = "";
                } else {
				    operacoes($$, $1, $3, "%", "arit");
                }
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

	if (yyparse() == 0 && erro_count == 0) {
        cout << codigo_gerado;
	} else if (erro_count > 0) {
		cerr << "Falha na compilacao! Foram encontrados " << erro_count << " erro(s):" << endl;
		for (string erro : lista_erros) {
			cerr << erro << endl;
		}
	}

	return 0;
}

void yyerror(string MSG)
{
	erro_count++;
	lista_erros.push_back("Erro na linha " + to_string(linha) + ": " + MSG);
}

void add_declaracao(string dec) {
    if (nivel_escopo == 0) {
        declaracoes_globais += dec;
    } else {
        declaracoes += dec;
    }
}


//funcao que fica responsável por fazer o cast
string castGerar(string cast_tipo, string label, string& cast_traducao){
	string temp = gentempcode(); 
	//gera a string temporaria q vai receber o resultado do cast
	add_declaracao( "\t" + cast_tipo + " " + temp + ";\n");
	//faz a declaracao dessa nova string temporaria
	cast_traducao += "\t" + temp + " = " + "(" + cast_tipo + ") " + label + ";\n";
	 //faz a traducao para p codigo em c da nova string temporaria. Ex: t2 = (float)t1;
	return temp; 
	//retorna o novo label para um dos "E", pois um deles sofre o cast e 
	//muda o nome da variável
}

void operacoes(atributos& dd, atributos& d1, atributos& d3, string op, string op_tipo){
	if (d1.tipo == "string" && d3.tipo == "string" && op == "+") {
        string temp_len1 = gentempcode();
        string temp_len2 = gentempcode();
        string temp_soma_len = gentempcode();
        string temp_total = gentempcode();
        string temp_malloc = gentempcode();
        
        dd.label = gentempcode();
        dd.tipo = "string";

        add_declaracao( "\tint " + temp_len1 + ";\n");
        add_declaracao( "\tint " + temp_len2 + ";\n");
        add_declaracao( "\tint " + temp_soma_len + ";\n");
        add_declaracao( "\tint " + temp_total + ";\n");
        add_declaracao( "\tvoid* " + temp_malloc + ";\n");
        add_declaracao( "\tchar* " + dd.label + " = NULL;\n");

        dd.traducao = d1.traducao + d3.traducao +
                      "\t" + temp_len1 + " = tamString(" + d1.label + ");\n" +
                      "\t" + temp_len2 + " = tamString(" + d3.label + ");\n" +
                      "\t" + temp_soma_len + " = " + temp_len1 + " + " + temp_len2 + ";\n" +
                      "\t" + temp_total + " = " + temp_soma_len + " + 1;\n" + 
                      "\t" + temp_malloc + " = malloc(" + temp_total + ");\n" +
                      "\t" + dd.label + " = (char*) " + temp_malloc + ";\n" +
                      "\tstrcpy(" + dd.label + ", " + d1.label + ");\n" +
                      "\tstrcat(" + dd.label + ", " + d3.label + ");\n"; 
    }
	else if(eh_tipo_numerico(d1) && eh_tipo_numerico(d3)){
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
			add_declaracao( "\t" + dd.tipo + " " + dd.label + ";\n");	
		}
		else{
			add_declaracao( "\tint " + dd.label + ";\n");	
			//tratamento especial para o tipo bool pq ele n existe em C
		}
		
		dd.traducao = cast_traducao + "\t" + dd.label +
		" = " + d1.label + " " + op + " " + d3.label + ";\n";
	}
	else if(d1.tipo == "string" && d3.tipo == "string" && (op == "==" || op == "!=")){
		dd.tipo = "bool";
		dd.label = gentempcode();
		add_declaracao( "\tint " + dd.label + ";\n");
		if (op == "==") {
			dd.traducao = d1.traducao + d3.traducao + "\t" + dd.label + " = comparaString( " + d1.label + ", " + d3.label + " );\n";
		} else {
			dd.traducao = d1.traducao + d3.traducao + "\t" + dd.label + " = !comparaString( " + d1.label + ", " + d3.label + " );\n";
		}
	}
	else if(d1.tipo == "bool" && d3.tipo == "bool" && (op == "==" || op == "!=")){
		dd.tipo = "bool";
		dd.label = gentempcode();
		add_declaracao( "\tint " + dd.label + ";\n");
		dd.traducao = d1.traducao + d3.traducao + "\t" + dd.label + " = " + d1.label + " " + op + " " + d3.label + ";\n";
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
		add_declaracao( "\tint " + dd.label + ";\n");
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

		if (tipo == "string") 
			add_declaracao( "\t" + tipo_c + " " + temp + " = NULL;\n");
		else 
			add_declaracao( "\t" + tipo_c + " " + temp + ";\n");
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

void declarar_vetor(string nome, string tipo, string tamanho){
    if(tabela_escopos.back().count(nome))
         yyerror("vetor " + nome + " já declarado nesse escopo");
    else{
            string temp = gentempcode();
            tabela_escopos.back()[nome] = {temp, tipo, "1D"};
            string tipo_c = (tipo == "bool") ? "int" : (tipo == "string") ? "char*" : tipo;

            add_declaracao( "\t" + tipo_c + " " + temp + "[" + tamanho + "];\n");
        }
}

void declarar_matriz(string nome, string tipo, string tam1, string tam2){
    if(tabela_escopos.back().count(nome))
         yyerror("matriz " + nome + " já declarada nesse escopo");
    else{
            string temp = gentempcode();
            tabela_escopos.back()[nome] = {temp, tipo, tam2};
            string tipo_c = (tipo == "bool") ? "int" : (tipo == "string") ? "char*" : tipo;

            int total = stoi(tam1) * stoi(tam2);
            add_declaracao( "\t" + tipo_c + " " + temp + "[" + to_string(total) + "];\n");
        }
}

void atribuicao_composta(atributos& res, atributos& id, atributos& expressao, string operador) {
        auto info = consultar_variavel(id.label);
        res.label = info.temp;
        res.tipo = info.tipo;

        if (info.tipo != expressao.tipo) {
            if (info.tipo == "float" && expressao.tipo == "int")
                expressao.label = castGerar("float", expressao.label, expressao.traducao);
            else if (info.tipo == "int" && expressao.tipo == "float")
                expressao.label = castGerar("int", expressao.label, expressao.traducao);
            else
                yyerror("tipos incompativeis para atribuicao");
        }

        if (info.tipo == "string") {
            if (operador != "+") {
                yyerror("A operacao '" + operador + "=' nao e permitida para o tipo texto!");
                return;
            }
            string temp_len1 = gentempcode();
            string temp_len2 = gentempcode();
            string temp_soma = gentempcode();
            string temp_malloc = gentempcode();
            string temp_cond = gentempcode();
            string label_skip = gen_label();
            
            add_declaracao( "\tint " + temp_len1 + ";\n");
            add_declaracao( "\tint " + temp_len2 + ";\n");
            add_declaracao( "\tint " + temp_soma + ";\n");
            add_declaracao( "\tvoid* " + temp_malloc + ";\n");
            add_declaracao( "\tint " + temp_cond + ";\n");
            
            string operacao = "\t" + temp_len1 + " = tamString(" + res.label + ");\n" +
                              "\t" + temp_len2 + " = tamString(" + expressao.label + ");\n" +
                              "\t" + temp_soma + " = " + temp_len1 + " + " + temp_len2 + " + 1;\n" +
                              "\t" + temp_malloc + " = malloc(" + temp_soma + ");\n" +
                              "\tstrcpy((char*)" + temp_malloc + ", " + res.label + ");\n" +
                              "\tstrcat((char*)" + temp_malloc + ", " + expressao.label + ");\n";
            
            string atribuicao = "\t" + temp_cond + " = " + res.label + " != NULL;\n" +
                                "\tif (!" + temp_cond + ") goto " + label_skip + ";\n" +
                                "\tfree(" + res.label + ");\n" +
                                label_skip + ":\n" +
                                "\t" + res.label + " = (char*) " + temp_malloc + ";\n";
                                
            res.traducao = expressao.traducao + operacao + atribuicao;
            return;
        }

        //  Cria variável temporária para a operação
        string temp_operacao = gentempcode();
        string tipo_c = (info.tipo == "float") ? "float" : "int";
        add_declaracao( "\t" + tipo_c + " " + temp_operacao + ";\n");

        // Monta a string da operação matemática (temp = var OP expressao)
        string operacao = "\t" + temp_operacao + " = " + res.label + " " + operador + " " + expressao.label + ";\n";

        // Monta a string da atribuição final (var = temp)
        string atribuicao = "\t" + res.label + " = " + temp_operacao + ";\n";

        // 5. Unindo a tradução
        res.traducao = expressao.traducao + operacao + atribuicao;
    }

void incremento_unario(atributos& res, atributos& id, string operador, bool eh_pre) {
    auto info = consultar_variavel(id.label);
    res.tipo = info.tipo;
    res.label = gentempcode();
    string tipo_c = (info.tipo == "float") ? "float" : "int";
    add_declaracao( "\t" + tipo_c + " " + res.label + ";\n");

    if (eh_pre) {
        // Pré-incremento/decremento: faz a conta e depois passa pra temporária
        res.traducao = "\t" + info.temp + " = " + info.temp + " " + operador + " 1;\n" + 
                       "\t" + res.label + " = " + info.temp + ";\n";
    } else {
        // Pós-incremento/decremento: salva na temporária e depois faz a conta
        res.traducao = "\t" + res.label + " = " + info.temp + ";\n" + 
                       "\t" + info.temp + " = " + info.temp + " " + operador + " 1;\n";
    }
}