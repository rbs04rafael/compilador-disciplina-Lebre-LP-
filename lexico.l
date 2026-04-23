%{
#include <string>
%}

%option noyywrap

ESPACO [ \t]
DIGITO [0-9]
FLUTUANTE \.[0-9]+
ID [a-zA-Z_][a-zA-Z0-9]*

DELIM {ESPACO}+
NUM {DIGITO}+
REAL {NUM}{FLUTUANTE}

%%

"\n"		{ linha++; }

{DELIM} 	{}

[-+*/()=;]			{ return *yytext; }

{REAL}      { yylval.label = yytext; yylval.tipo = "float"; return TK_NUM;}

"float"     { return TK_FLOAT; }

{NUM}		{ yylval.label = yytext; yylval.tipo = "int"; return TK_NUM; }

"int"       { return TK_INT; }

{ID}        { yylval.label = yytext; return TK_ID; }

.			{ fprintf(stderr, "Caractere nao reconhecido na linha %d: %s\n", linha, yytext); }

%%
