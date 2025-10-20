%{
#include <iostream>
#include <string>
#include <vector>
#include <map>

using namespace std;

int linha = 1, coluna = 0; 

struct Atributos {
  vector<string> c;
  int linha = 0, coluna = 0;
  void clear() { c.clear(); linha = 0; coluna = 0; }
};

enum TipoDecl { Let = 1, Const, Var };

struct Simbolo {
  TipoDecl tipo;
  int linha;
  int coluna;
};

map< string, Simbolo > ts;

Atributos declara_var( TipoDecl tipo, Atributos atrib );
void checa_simbolo( string nome, bool modificavel );

#define YYSTYPE Atributos

extern "C" int yylex();
int yyparse();
void yyerror(const char *);

vector<string> operator+( vector<string> a, vector<string> b ) {
  a.insert( a.end(), b.begin(), b.end() );
  return a;
}

vector<string> operator+( vector<string> a, string b ) {
  a.push_back( b );
  return a;
}

vector<string> operator+( string a, vector<string> b ) {
  return vector<string>{ a } + b;
}

vector<string> resolve_enderecos( vector<string> entrada ) {
  map<string,int> label;
  vector<string> saida;
  for( int i = 0; i < entrada.size(); i++ ) 
    if( entrada[i][0] == ':' ) 
        label[entrada[i].substr(1)] = saida.size();
    else
      saida.push_back( entrada[i] );
  
  for( int i = 0; i < saida.size(); i++ ) 
    if( label.count( saida[i] ) > 0 )
        saida[i] = to_string(label[saida[i]]);
        
  return saida;
}

string gera_label( string prefixo ) {
  static int n = 0;
  return prefixo + "_" + to_string( ++n );
}

void print( vector<string> codigo ) {
  for( string s : codigo )
    cout << s << " ";
  cout << endl;  
}

%}

/* Definição dos Tokens */
%token ID IF ELSE LET CONST VAR PRINT FOR WHILE
%token CDOUBLE CSTRING CINT
%token AND OR ME_IG MA_IG DIF IGUAL
%token MAIS_IGUAL MAIS_MAIS MENOS_IGUAL MENOS_MENOS

/* Precedência e Associatividade dos Operadores */
%right '=' MAIS_IGUAL MENOS_IGUAL
%nonassoc IGUAL DIF
%nonassoc '<' '>' ME_IG MA_IG
%left '+' '-'
%left '*' '/' '%'
%right MAIS_MAIS MENOS_MENOS
%precedence UNARIO
%left '.' '[' '(' 

%%

S : CMDs { if(!$1.c.empty()) print( resolve_enderecos( $1.c + "." ) ); }
  | { /* Programa vazio */ }
  ;

CMDs : CMDs CMD { $$.c = $1.c + $2.c; }
     | CMD
     ;
     
CMD : CMD_LET ';'
    | CMD_VAR ';'
    | CMD_CONST ';'
    | CMD_IF
    | CMD_WHILE
    | CMD_FOR
    | PRINT E ';' { $$.c = $2.c + "println" + "#"; }
    | E ';' { $$.c = $1.c + "^"; }
    | '{' CMDs '}' { $$.c = $2.c; }
    | ';' { $$.clear(); }
    ;

/* Declarações de Variáveis */
CMD_LET : LET LET_VARs { $$.c = $2.c; };
LET_VARs : LET_VAR ',' LET_VARs { $$.c = $1.c + $3.c; } | LET_VAR;
LET_VAR : ID { $$.c = declara_var( Let, $1 ).c; }
        | ID '=' E { $$.c = declara_var( Let, $1 ).c + $1.c + $3.c + "=" + "^"; }
        ;
  
CMD_VAR : VAR VAR_VARs { $$.c = $2.c; };
VAR_VARs : VAR_VAR ',' VAR_VARs { $$.c = $1.c + $3.c; } | VAR_VAR;
VAR_VAR : ID { $$.c = declara_var( Var, $1 ).c; }
        | ID '=' E { $$.c = declara_var( Var, $1 ).c + $1.c + $3.c + "=" + "^"; }
        ;

CMD_CONST: CONST CONST_VARs { $$.c = $2.c; };
CONST_VARs : CONST_VAR ',' CONST_VARs { $$.c = $1.c + $3.c; } | CONST_VAR;
CONST_VAR : ID '=' E { $$.c = declara_var( Const, $1 ).c + $1.c + $3.c + "=" + "^"; };

/* Estruturas de Controle */
CMD_IF : IF '(' E ')' CMD {
            string lbl_fim = gera_label( "if_fim" );
            $$.c = $3.c + "!" + lbl_fim + "?" + $5.c + (":" + lbl_fim);
         }
       | IF '(' E ')' CMD ELSE CMD {
            string lbl_else = gera_label( "if_else" );
            string lbl_fim = gera_label( "if_fim" );
            $$.c = $3.c + "!" + lbl_else + "?" + $5.c + lbl_fim + "#" + 
                   (":" + lbl_else) + $7.c + (":" + lbl_fim);
         }
       ;

CMD_WHILE: WHILE '(' E ')' CMD {
            string lbl_ini = gera_label("while_ini");
            string lbl_fim = gera_label("while_fim");
            $$.c = (":" + lbl_ini) + $3.c + "!" + lbl_fim + "?" + $5.c + lbl_ini + "#" + (":" + lbl_fim);
         };

/* Nova regra para a inicialização do FOR */
FOR_INIT : CMD_LET { $$ = $1; }
         | CMD_VAR { $$ = $1; }
         | E { $$.c = $1.c + "^"; }
         | /* empty */ { $$.c.clear(); }
         ;

/* Regra CMD_FOR atualizada */
CMD_FOR: FOR '(' FOR_INIT ';' E_opt ';' E_opt ')' CMD {
            string lbl_ini = gera_label("for_ini");
            string lbl_fim = gera_label("for_fim");
            $$.c = $3.c +
                   (":" + lbl_ini) + 
                   $5.c + "!" + lbl_fim + "?" +
                   $9.c + 
                   $7.c + "^" +
                   lbl_ini + "#" + 
                   (":" + lbl_fim);
        };
E_opt : E { $$ = $1; } | { $$.c.clear(); };
        
LVALUE : ID;

LVALUEPROP : E '.' ID { $$.c = $1.c + ("\"" + $3.c[0] + "\""); }
           | E '[' E ']' { $$.c = $1.c + $3.c; }
           ;

E : LVALUE '=' E { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "="; }
  | LVALUE MAIS_IGUAL E { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $1.c + "@" + $3.c + "+" + "="; }
  | LVALUEPROP '=' E { $$.c = $1.c + $3.c + "[=]"; }
  | LVALUEPROP MAIS_IGUAL E { $$.c = $1.c + $1.c + "[@]" + $3.c + "+" + "[=]"; }
  | E '<' E { $$.c = $1.c + $3.c + "<"; }
  | E '>' E { $$.c = $1.c + $3.c + ">"; }
  | E ME_IG E { $$.c = $1.c + $3.c + "<="; }
  | E MA_IG E { $$.c = $1.c + $3.c + ">="; }
  | E IGUAL E { $$.c = $1.c + $3.c + "=="; }
  | E DIF E { $$.c = $1.c + $3.c + "!="; }
  | E '+' E { $$.c = $1.c + $3.c + "+"; }
  | E '-' E { $$.c = $1.c + $3.c + "-"; }
  | E '*' E { $$.c = $1.c + $3.c + "*"; }
  | E '/' E { $$.c = $1.c + $3.c + "/"; }
  | E '%' E { $$.c = $1.c + $3.c + "%"; }
  | '-' E %prec UNARIO { $$.c = "0" + $2.c + "-"; }
  | '(' E ')' { $$.c = $2.c; }
  | LVALUE { checa_simbolo( $1.c[0], false ); $$.c = $1.c + "@"; }
  | LVALUEPROP { $$.c = $1.c + "[@]"; }
  | CINT 
  | CDOUBLE 
  | CSTRING { string s = $1.c[0]; s = s.substr(1, s.length() - 2); $$.c = vector<string>{"\"" + s + "\""}; }
  | '{' '}' { $$.c.clear(); $$.c.push_back("{}"); }
  | '[' ']' { $$.c.clear(); $$.c.push_back("[]"); }
  | LVALUE MAIS_MAIS { 
      checa_simbolo( $1.c[0], true );
      $$.c = $1.c + "@" + $1.c + $1.c + "@" + "1" + "+" + "=" + "^";
    }
  | MAIS_MAIS LVALUE {
      checa_simbolo( $2.c[0], true );
      $$.c = $2.c + $2.c + "@" + "1" + "+" + "=";
    }
  ;

%%

#include "lex.yy.c"

Atributos declara_var( TipoDecl tipo, Atributos atrib ) {
  string nome_var = atrib.c[0];
  if (tipo != Var && ts.count(nome_var) > 0) {
    cerr << "Erro: a variável '" << nome_var << "' ja foi declarada na linha " << ts[nome_var].linha << "." << endl;
    exit(1);
  }
  ts[nome_var] = { tipo, atrib.linha, atrib.coluna };
  atrib.c = atrib.c + "&";
  return atrib;
}

void checa_simbolo( string nome, bool modificavel ) {
  if( ts.count( nome ) == 0 ) {
    cerr << "Erro: a variável '" << nome << "' não foi declarada." << endl;
    exit( 1 );     
  }
  if( modificavel && ts[nome].tipo == Const ) {
    cerr << "Erro: a variável constante '" << nome << "' não pode ser modificada." << endl;
    exit( 1 );     
  }
}

void yyerror( const char* st ) {
   fprintf( stderr, "Erro de sintaxe próximo a: %s (linha %d)\n", yytext, linha );
   exit( 1 );
}

int main( int argc, char* argv[] ) {
  yyparse();
  return 0;
}