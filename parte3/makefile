all: mini_js codigo 
	echo "=== Execução ==="
	./mdp/interpretador < codigo 

codigo: mini_js entrada.txt
	./mini_js < entrada.txt > codigo
	echo "=== Codigo ==="
	cat codigo

mini_js: lex.yy.c y.tab.c
	g++  y.tab.c -o mini_js -lfl

lex.yy.c: mini_js.l 
	lex mini_js.l

y.tab.c: mini_js.y
	bison -d -v mini_js.y -o y.tab.c

clean: 
	rm -f lex.yy.c y.tab.c mini_js 