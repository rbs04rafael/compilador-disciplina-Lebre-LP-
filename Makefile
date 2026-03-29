SCANNER := flex
SCANNER_PARAMS := lexico.l
PARSER := bison
PARSER_PARAMS := -d --yacc sintatico.y
CXXFLAGS := -Wno-free-nonheap-object

all: glf translate

compile: glf

glf: y.tab.c lex.yy.c
		g++ $(CXXFLAGS) -o glf y.tab.c

lex.yy.c: lexico.l
		$(SCANNER) $(SCANNER_PARAMS)

y.tab.c y.tab.h: sintatico.y
		$(PARSER) $(PARSER_PARAMS)

run: 	glf
		clear
		$(MAKE) compile
		$(MAKE) translate

debug:	PARSER_PARAMS += -Wcounterexamples
debug: 	all

translate: glf
		./glf < exemplo.foca

clean:
	rm -f y.tab.c
	rm -f y.tab.h
	rm -f lex.yy.c
	rm -f glf
