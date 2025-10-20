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

map< string, Simbolo > ts; // Tabela de símbolos

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

string define_label( string label) {
  return ":" + label;
}

%}

%token ID IF ELSE LET CONST VAR PRINT FOR WHILE
%token CDOUBLE CSTRING CINT
%token AND OR ME_IG MA_IG DIF IGUAL
%token MAIS_IGUAL MAIS_MAIS MENOS_IGUAL MENOS_MENOS

%right '=' MAIS_IGUAL MENOS_IGUAL
%nonassoc '<' '>' ME_IG MA_IG IGUAL DIF
%left '+' '-'
%left '*' '/' '%'
%precedence UNARIO
%left '[' '.'

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
    | ';' { $$.c.clear(); }
    ;

CMD_LET : LET LET_VARs { $$.c = $2.c; };
LET_VARs : LET_VAR ',' LET_VARs { $$.c = $1.c + $3.c; } | LET_VAR;
LET_VAR : LVALUE { $$.c = declara_var( Let, $1 ).c; }
        | LVALUE '=' E { $$.c = declara_var( Let, $1 ).c + $1.c + $3.c + "=" + "^"; }
        ;
  
CMD_VAR : VAR VAR_VARs { $$.c = $2.c; };
VAR_VARs : VAR_VAR ',' VAR_VARs { $$.c = $1.c + $3.c; } | VAR_VAR;
VAR_VAR : LVALUE { $$.c = declara_var( Var, $1 ).c; }
        | LVALUE '=' E { $$.c = declara_var( Var, $1 ).c + $1.c + $3.c + "=" + "^"; }
        ;

CMD_CONST: CONST CONST_VARs { $$.c = $2.c; };
CONST_VARs : CONST_VAR ',' CONST_VARs { $$.c = $1.c + $3.c; } | CONST_VAR;
CONST_VAR : LVALUE '=' E { $$.c = declara_var( Const, $1 ).c + $1.c + $3.c + "=" + "^"; };

CMD_IF : IF '(' E ')' CMD
         {
           string lbl_fim = gera_label( "lbl_fim" );
           $$.c = $3.c + "!" + lbl_fim + "?" + $5.c + "^" + (":" + lbl_fim);
         }
        | IF '(' E ')' CMD ELSE CMD
          {
            string lbl_else = gera_label( "lbl_else" );
            string lbl_fim = gera_label( "lbl_fim" );
          
            $$.c = $3.c                                // Condição
                  + "!" + lbl_else + "?"              // Se falsa, pula para o else
                  + $5.c                              // Corpo do IF
                  + lbl_fim + "#"                     // << PULO INCONDICIONAL PARA O FIM
                  + (":" + lbl_else)                  // Início do ELSE
                  + $7.c                              // Corpo do ELSE
                  + (":" + lbl_fim);                  // Fim de tudo
          }
       ;

CMD_WHILE: WHILE '(' E ')' CMD {
           string lbl_ini = gera_label("lbl_ini_while");
           string lbl_fim = gera_label("lbl_fim_while");
           $$.c = ":" + lbl_ini + $3.c + lbl_fim + "?" + $5.c + lbl_ini + "#" + ":" + lbl_fim;
         };

CMD_FOR: FOR '(' E_opt ';' E_opt ';' E_opt ')' CMD {
            string lbl_ini = gera_label("lbl_ini_for");
            string lbl_fim = gera_label("lbl_fim_for");
            $$.c = $3.c + "^" + ":" + lbl_ini + $5.c + lbl_fim + "?" + $9.c + $7.c + "^" + lbl_ini + "#" + ":" + lbl_fim;
        };

E_opt : E { $$.c = $1.c; } | { $$.c.clear(); };
        
LVALUE : ID;

LVALUEPROP : E '[' E ']' { $$.c = $1.c + $3.c; }
           | E '.' ID { $$.c = $1.c + $3.c; }
           ;
           
E : LVALUE '=' E { checa_simbolo( $1.c[0], true ); $$.c = $1.c + $3.c + "="; }
  | LVALUE MAIS_IGUAL E 
    {
      checa_simbolo( $1.c[0], true );
      $$.c = $1.c + $1.c + "@" + $3.c + "+" + "=";
    }
| LVALUE MAIS_MAIS 
  {
      checa_simbolo( $1.c[0], true );
      $$.c = $1.c + "@" + $1.c + $1.c + "@" + "1" + "+" + "=";
    }
  | LVALUEPROP '=' E { $$.c = $1.c + $3.c + "[]="; }
  | LVALUEPROP MAIS_IGUAL E { $$.c = $1.c + "[@]" + $3.c + "+" + $1.c + "[]="; }
| LVALUEPROP MAIS_MAIS 
    {
      $$.c = $1.c + "[@]" + " " +
             $1.c + " " + $1.c + "[@]" + " 1" + " + " + "[]=";                                    // (3) Limpeza
    }
  | '(' E ')' { $$.c = $2.c; }
  | LVALUEPROP { $$.c = $1.c + "[@]"; }
  | LVALUE { checa_simbolo( $1.c[0], false ); $$.c = $1.c + "@"; }
  | E '<' E { $$.c = $1.c + $3.c + $2.c; }
  | E '>' E { $$.c = $1.c + $3.c + $2.c; }
  | E ME_IG E { $$.c = $1.c + $3.c + $2.c; }
  | E MA_IG E { $$.c = $1.c + $3.c + $2.c; }
  | E IGUAL E { $$.c = $1.c + $3.c + $2.c; }
  | E DIF E { $$.c = $1.c + $3.c + $2.c; }
  | E '+' E { $$.c = $1.c + $3.c + $2.c; }
  | E '-' E { $$.c = $1.c + $3.c + $2.c; }
  | E '*' E { $$.c = $1.c + $3.c + $2.c; }
  | E '/' E { $$.c = $1.c + $3.c + $2.c; }
  | E '%' E { $$.c = $1.c + $3.c + $2.c; }
  | '-' E %prec UNARIO { $$.c = $2.c + "neg"; }
  | CINT | CDOUBLE 
  | CSTRING
    {
      string s = $1.c[0];                       // 1. Get the raw string (e.g., "'world'")
      s = s.substr(1, s.length() - 2);        // 2. Remove the original quotes -> world
      $$.c = vector<string>{"\"" + s + "\""};  // 3. Wrap in double quotes -> "world"
    }
  | '{' '}'
    { $$.c.clear(); $$.c.push_back("{}"); } // Gera o token único "{}"
  | '[' ']'
    { $$.c.clear(); $$.c.push_back("[]"); } // Gera o token único "[]"
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
    cerr << "Erro: a variável '" << nome << "' não pode ser modificada." << endl;
    exit( 1 );     
  }
}

void yyerror( const char* st ) {
   fprintf( stderr, "syntax error\n" );
   fprintf( stderr, "Proximo a: %s\n", yytext );
   exit( 1 );
}

int main( int argc, char* argv[] ) {
  yyparse();
  return 0;
}