%{
#include <string>
%}

%option noyywrap

ESPACO [ \t]
DIGITO [0-9]
FLUTUANTE \.[0-9]+
ID [a-zA-Z_][a-zA-Z0-9_]*
LETRA [a-zA-Z]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}{FLUTUANTE}
CARACTERE '{LETRA}?'

TEXTO ["][^"]*["]

%%

"\n"		{ linha++; }

{DELIM} 	{}

"//".*     { /* Nao faz nada, apenas ignora o texto */ }

"<="        { return TK_MEI; }
">="        { return TK_MAI; }
"=="        { return TK_II; }
"!="        { return TK_DF; }

"&&"        { return TK_AND; }
"||"        { return TK_OR; }

"+="        { return TK_MAIS_IGUAL; }
"-="        { return TK_MENOS_IGUAL; }
"*="        { return TK_VEZES_IGUAL; }
"/="        { return TK_DIV_IGUAL; }

[-+*/()=;><!{}:,\[\]%]	{ return *yytext; }

"real"      { return TK_FLOAT; }
"inteiro"   { return TK_INT; }
"caractere" { return TK_CHAR; }
"logico"    { return TK_BOOL; }
"texto"     { return TK_STRING; }
"vazio"     { return TK_VOID; }
"var"       { return TK_VAR; }

"se"        { return TK_IF; }
"senao"     { return TK_ELSE; }
"senao"[ \t\n]+"se"  { return TK_ELSE_IF; }

"escolha"   { return TK_SWITCH; }
"caso"      { return TK_CASE; }
"padrao"    { return TK_DEFAULT; }
"pare"      { return TK_BREAK; }
"pare_tudo" { return TK_BREAK_ALL; }
"continua"  { return TK_CONTINUE; }

"enquanto"  { return TK_WHILE; }
"faca"[ \t\n]+"enquanto" { return TK_DO_WHILE; }
"para"      { return TK_FOR; }
"++"        { return TK_INC; }
"--"        { return TK_DEC; }

"imprima"   { return TK_PRINT; }
"leia"      { return TK_SCAN; }

"retorna"   { return TK_RETORNA; }    

"verdadeiro"    { yylval.label = "1"; yylval.tipo = "bool"; return TK_BOOLLIT;}
"falso"         { yylval.label = "0"; yylval.tipo = "bool"; return TK_BOOLLIT;}

{REAL}      { yylval.label = yytext; yylval.tipo = "float"; return TK_NUM;}
{NUM}		{ yylval.label = yytext; yylval.tipo = "int"; return TK_NUM; }
{CARACTERE} { yylval.label = yytext; yylval.tipo = "char"; return TK_CHARLITERAL; }
{TEXTO}     { yylval.label = yytext; yylval.tipo = "string"; return TK_STRINGLITERAL; }

{ID}        { yylval.label = yytext; return TK_ID; }

.			{ fprintf(stderr, "Caractere nao reconhecido na linha %d: %s\n", linha, yytext); }

%%
