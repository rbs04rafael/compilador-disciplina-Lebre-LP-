%{
#include <string>
%}

%option noyywrap

ESPACO [ \t]
DIGITO [0-9]
FLUTUANTE \.[0-9]+
ID [a-zA-Z_][a-zA-Z0-9]*
LETRA [a-zA-Z]

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}{FLUTUANTE}
CARACTERE '{LETRA}?'

TEXTO ["][^"]*["]

%%

"\n"		{ linha++; }

{DELIM} 	{}

"<="        { return TK_MEI; }
">="        { return TK_MAI; }
"=="        { return TK_II; }
"!="        { return TK_DF; }

"&&"        { return TK_AND; }
"||"        { return TK_OR; }

[-+*/()=;><!{}]	{ return *yytext; }

"real"      { return TK_FLOAT; }
"inteiro"   { return TK_INT; }
"caractere" { return TK_CHAR; }
"logico"    { return TK_BOOL; }
"texto"     { return TK_STRING; }

"se"        { return TK_IF; }
"senao"     { return TK_ELSE; }
"senao se"  { return TK_ELSE_IF; }

"enquanto"  { return TK_WHILE; }
"faca enquanto" { return TK_DO_WHILE; }
"para"      { return TK_FOR; }
"++"        { return TK_INC; }

"imprima"   { return TK_PRINT; }
"leia"      { return TK_SCAN; }

"verdadeiro"    { yylval.label = "1"; yylval.tipo = "bool"; return TK_BOOLLIT;}
"falso"         { yylval.label = "0"; yylval.tipo = "bool"; return TK_BOOLLIT;}

{REAL}      { yylval.label = yytext; yylval.tipo = "float"; return TK_NUM;}
{NUM}		{ yylval.label = yytext; yylval.tipo = "int"; return TK_NUM; }
{CARACTERE} { yylval.label = yytext; yylval.tipo = "char"; return TK_CHARLITERAL; }
{TEXTO}     { yylval.label = yytext; yylval.tipo = "string"; return TK_STRINGLITERAL; }

{ID}        { yylval.label = yytext; return TK_ID; }

.			{ fprintf(stderr, "Caractere nao reconhecido na linha %d: %s\n", linha, yytext); }

%%
