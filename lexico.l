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

%%

"\n"		{ linha++; }

{DELIM} 	{}

[-+*/()=;]	{ return *yytext; }

{REAL}      { yylval.label = yytext; yylval.tipo = "float"; return TK_NUM;}

"float"     { return TK_FLOAT; }

{NUM}		{ yylval.label = yytext; yylval.tipo = "int"; return TK_NUM; }

"int"       { return TK_INT; }

{CARACTERE} { yylval.label = yytext; yylval.tipo = "char"; return TK_CHARLITERAL; }

"caractere" { return TK_CHAR; }

"true"      { yylval.label = "1"; yylval.tipo = "int"; return TK_BOOLLIT;}

"false"     { yylval.label = "0"; yylval.tipo = "int"; return TK_BOOLLIT;}

"logico"    { return TK_BOOL; }

"char"   { return TK_CHAR; } 
"bool"   { return TK_BOOL; }

{ID}        { yylval.label = yytext; return TK_ID; }

.			{ fprintf(stderr, "Caractere nao reconhecido na linha %d: %s\n", linha, yytext); }

%%
