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

"<="        { return TK_MEI; }
">="        { return TK_MAI; }
"=="        { return TK_II; }
"!="        { return TK_DF; }

[-+*/()=;><]	{ return *yytext; }

"real"      { return TK_FLOAT; }
"inteiro"   { return TK_INT; }
"caractere" { return TK_CHAR; }
"logico"    { return TK_BOOL; }

"true"      { yylval.label = "1"; yylval.tipo = "int"; return TK_BOOLLIT;}
"false"     { yylval.label = "0"; yylval.tipo = "int"; return TK_BOOLLIT;}

{REAL}      { yylval.label = yytext; yylval.tipo = "float"; return TK_NUM;}
{NUM}		{ yylval.label = yytext; yylval.tipo = "int"; return TK_NUM; }
{CARACTERE} { yylval.label = yytext; yylval.tipo = "char"; return TK_CHARLITERAL; }

{ID}        { yylval.label = yytext; return TK_ID; }

.			{ fprintf(stderr, "Caractere nao reconhecido na linha %d: %s\n", linha, yytext); }

%%
