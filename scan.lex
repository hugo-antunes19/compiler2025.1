%{
#include <string>
#include <vector>

using namespace std;

string lexema;

/*
 * Função auxiliar para processar literais de string.
 */
string processar_string(const char* texto) {
    string s = "";
    for (int i = 1; texto[i] != '\0' && texto[i+1] != '\0'; i++) {
        if (texto[i] == '\\' && texto[i+1] != '\0') {
            i++; // Pula a barra e processa o próximo caractere
            switch (texto[i]) {
                case 'n': s += '\n'; break;
                case 't': s += '\t'; break;
                // CORREÇÃO: Removida a contrabarra '\' do final do comentário abaixo
                default: s += texto[i]; break; // Para \" adiciona ", para \\ adiciona
            }
        } else {
            s += texto[i];
        }
    }
    return s;
}
%}

/* Definições Regulares (Aliases) */
WS			[ \t\n]+
DIGITO		[0-9]
LETRA		[a-zA-Z]
ID_START	({LETRA}|_)
ID_CHARS	({LETRA}|{DIGITO}|_)
ID_NORMAL	{ID_START}{ID_CHARS}*
ID_DOLAR	\${ID_CHARS}+

%%

{WS}				{ /* Ignora whitespace */ }

	/* --- Comentários (usando Regex completo) --- */
"//".*				{ lexema = yytext; return _COMENTARIO; }
\/\*([^*]|\*+[^*/])*\*+\/	{ lexema = yytext; return _COMENTARIO; }

	/* --- Strings (usando Regex completo) --- */
\"([^"\\]|\\.)*\"	{ lexema = processar_string(yytext); return _STRING; }
\'([^'\\]|\\.)*\'	{ lexema = processar_string(yytext); return _STRING; }
\`\`([^\`\\]|\\.)*\`\`	{ lexema = processar_string(yytext); return _STRING2; }

	/* --- Palavras-chave --- */
[fF][oO][rR]		{ lexema = yytext; return _FOR; }
[iI][fF]			{ lexema = yytext; return _IF; }

	/* --- Operadores --- */
">="				{ lexema = yytext; return _MAIG; }
"<="				{ lexema = yytext; return _MEIG; }
"=="				{ lexema = yytext; return _IG; }
"!="				{ lexema = yytext; return _DIF; }

	/* --- Números (_FLOAT antes de _INT) --- */
{DIGITO}+\.{DIGITO}*([eE][+-]?{DIGITO}+)?	{ lexema = yytext; return _FLOAT; }
{DIGITO}+[eE][+-]?{DIGITO}+				{ lexema = yytext; return _FLOAT; }
{DIGITO}+			{ lexema = yytext; return _INT; }

	/* --- Identificadores --- */
{ID_DOLAR}|{ID_NORMAL} { lexema = yytext; return _ID; }

	/* --- Regra Final para caracteres únicos --- */
.					{ return *yytext; }

%%
/*
 * Esta seção fica VAZIA.
 * A função main() e outras necessárias estão no seu arquivo main.cc.
 */