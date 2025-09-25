%{
#include <iostream>
#include <string>
#include <stdexcept>

enum { ID = 256, NUM, STRING, PRINT };

int token;
std::string lexema;

void Stmt();
void E();
void E_linha();
void T();
void T_linha();
void Unary();
void Pow();
void Pow_linha();
void Fat();
void Fat_linha();
void F();
void Args();
void Args_linha();

int yylex();

void p(const std::string& s) {
    std::cout << s << " ";
}

void erro(const std::string& msg) {
    throw std::runtime_error(msg);
}

void casa(int esperado) {
    if (token == esperado) {
        token = yylex();
    } else {
        erro("Token inesperado.");
    }
}
%}

%option noyywrap

%%
" "|\t|\r|\n          ;

"print"                 { return PRINT; }

[a-zA-Z_][a-zA-Z0-9_]* { lexema = yytext; return ID; }

[0-9]+(\.[0-9]+)?       { lexema = yytext; return NUM; }

\"([^\"\n\\]|(\\\")|\"\"|"\\\\")*\"      { lexema = yytext; return STRING; }

"+"|"-"|"*"|"/"|"="|"^"|"!"|"("|")"|";"|"," { lexema = yytext; return yytext[0]; }

.                       { lexema = yytext; erro("Caractere desconhecido"); }

%%

void Stmt() {
    if (token == ID) {
        std::string temp = lexema;
        casa(ID);
        casa('=');
        p(temp);
        E();
        p("= ^");
    } else if (token == PRINT) {
        casa(PRINT);
        E();
        p("print #");
    }
}

void E() { T(); E_linha(); }

void E_linha() {
    if (token == '+') { casa('+'); T(); p("+"); E_linha(); } 
    else if (token == '-') { casa('-'); T(); p("-"); E_linha(); }
}

void T() { Unary(); T_linha(); }

void T_linha() {
    if (token == '*') { casa('*'); Unary(); p("*"); T_linha(); } 
    else if (token == '/') { casa('/'); Unary(); p("/"); T_linha(); }
}

void Unary() {
    if (token == '+') { casa('+'); Unary(); } 
    else if (token == '-') { casa('-'); p("0"); Unary(); p("-"); } 
    else { Pow(); }
}

void Pow() { Fat(); Pow_linha(); }

void Pow_linha() {
    if (token == '^') { casa('^'); Pow(); p("power #"); }
}

void Fat() { F(); Fat_linha(); }

void Fat_linha() {
    if (token == '!') { casa('!'); p("fat #"); }
}

void F() {
    switch (token) {
        case ID: {
            std::string temp = lexema;
            casa(ID);
            if (token == '(') {
                casa('(');
                if (token != ')') { Args(); }
                casa(')');
                p(temp); p("#");
            } else { p(temp); p("@"); }
            break;
        }
        case NUM: { p(lexema); casa(NUM); break; }
        case STRING: { p(lexema); casa(STRING); break; }
        case '(': { casa('('); E(); casa(')'); break; }
        default: erro("Fator inválido ou inesperado");
    }
}

void Args() { E(); Args_linha(); }

void Args_linha() {
    if (token == ',') { casa(','); E(); Args_linha(); }
}

int main() {
    try {
        token = yylex();
        while (token != 0) {
            if (token == ';') { token = yylex(); continue; }
            Stmt();
            if (token == 0) { break; }
            casa(';');
        }
        std::cout << std::endl;
    } catch (const std::runtime_error& e) {
        std::cerr << "Erro: " << e.what() << " (encontrado: '" << lexema << "')" << std::endl;
        return 1;
    }
    return 0;
}