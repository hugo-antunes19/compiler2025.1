%{
#include <string>

using namespace std;

string lexema;
string buffer;
%}

%option noyywrap
%x COMMENT DQUOTE SQUOTE BSTR

DIGITO      [0-9]
LETRA       [a-zA-Z]
ID_START    ({LETRA}|_)
ID_CHARS    ({LETRA}|{DIGITO}|_)
ID_NORMAL   {ID_START}{ID_CHARS}*
ID_DOLAR    \${ID_CHARS}+

%%
[ \t\r]+    /* Ignorado */
\n          /* Ignorado */

"//".* { lexema = yytext; return _COMENTARIO; }

"/*"        { buffer.clear(); BEGIN(COMMENT); }
<COMMENT>"*/" { lexema = buffer; BEGIN(INITIAL); return _COMENTARIO; }
<COMMENT>\n { buffer += yytext; }
<COMMENT>.  { buffer += yytext; }

\"                  { buffer.clear(); BEGIN(DQUOTE); }
<DQUOTE>\"\"        { buffer += '"'; }
<DQUOTE>\\\"        { buffer += '"'; }
<DQUOTE>\\n         { buffer += '\n'; }
<DQUOTE>\\[^"]      { buffer += yytext[1]; }
<DQUOTE>[^"\\\n]+   { buffer += yytext; }
<DQUOTE>\"          { lexema = buffer; BEGIN(INITIAL); return _STRING; }
<DQUOTE>\n          { printf("Erro: String nao pode quebrar linha.\n"); BEGIN(INITIAL); }

\'                  { buffer.clear(); BEGIN(SQUOTE); }
<SQUOTE>\'\'        { buffer += '\''; }
<SQUOTE>\\\'        { buffer += '\''; }
<SQUOTE>\\n         { buffer += '\n'; }
<SQUOTE>\\[^']      { buffer += yytext[1]; }
<SQUOTE>[^'\\\n]+   { buffer += yytext; }
<SQUOTE>\'          { lexema = buffer; BEGIN(INITIAL); return _STRING; }
<SQUOTE>\n          { printf("Erro: String nao pode quebrar linha.\n"); BEGIN(INITIAL); }


\`\`                  { buffer.clear(); BEGIN(BSTR); }
<BSTR>\`\`            { lexema = buffer; BEGIN(INITIAL); return _STRING2; }
<BSTR>\\`\`           { buffer += '`'; }
<BSTR>\\.            { buffer += yytext[1]; }
<BSTR>[^`\`\\]+       { buffer += yytext; } /* Esta era a linha mais problemática */
<BSTR>\n             { buffer += '\n'; }


[fF][oO][rR]  { lexema = yytext; return _FOR; }
[iI][fF]      { lexema = yytext; return _IF; }

">="          { lexema = yytext; return _MAIG; }
"<="          { lexema = yytext; return _MEIG; }
"=="          { lexema = yytext; return _IG; }
"!="          { lexema = yytext; return _DIF; }

{DIGITO}+\.{DIGITO}*([eE][+-]?{DIGITO}+)? { lexema = yytext; return _FLOAT; }
{DIGITO}+[eE][+-]?{DIGITO}+              { lexema = yytext; return _FLOAT; }
{DIGITO}+     { lexema = yytext; return _INT; }

{ID_DOLAR}|{ID_NORMAL} { lexema = yytext; return _ID; }

.   { printf("Caractere invalido: '%s'\n", yytext); }

%%
void yyerror(const char* s) {  
  fprintf( stderr, "Erro: %s\n", s );
}