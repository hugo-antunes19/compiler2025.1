%{
#include <string>
#include <cstdio>

using namespace std;

string lexema;

extern int yylineno;

string processar_string(const char* texto) {
    string s = "";
    char delimitador = texto[0]; // Captura o tipo de aspas ('"', '\'', ou '`')

    // Loop do segundo ao penúltimo caractere para ignorar as aspas externas
    for (int i = 1; texto[i] != '\0' && texto[i+1] != '\0'; i++) {
        // Trata escape com contrabarra (ex: \")
        if (texto[i] == '\\') {
            i++; // Pula a barra e pega o próximo caractere
            switch (texto[i]) {
                case 'n': s += '\n'; break;
                case 't': s += '\t'; break;
                // CORREÇÃO: Removida a contrabarra '\' do final do comentário
                default: s += texto[i]; break; // Para \" adiciona ", para \\ adiciona
            }
        } 
        // Trata escape com aspas duplas (ex: '')
        else if (texto[i] == delimitador && texto[i+1] == delimitador) {
            s += delimitador; // Adiciona uma das aspas
            i++;              // Pula a segunda aspa do par
        }
        // Caractere normal
        else {
            s += texto[i];
        }
    }
    return s;
}
%}

/* Definições Regulares */
WS			[ \t\n]+
DIGITO		[0-9]
LETRA		[a-zA-Z]
ID_START	({LETRA}|_)
ID_CHARS	({LETRA}|{DIGITO}|_)
ID_NORMAL	{ID_START}{ID_CHARS}*
SIMBOLOS	[=;(){}+*/<>-]
ID_INVALIDO_A	    {ID_NORMAL}\$[a-zA-Z0-9_\$]*
ID_INVALIDO_DOLAR   \${ID_CHARS}*\$[a-zA-Z0-9_\$]*

%%

{WS}				{ /* Ignora whitespace */ }

	/* --- Regra de Erro para Identificadores Inválidos (DEVE VIR PRIMEIRO) --- */
{ID_INVALIDO_A}|{ID_INVALIDO_DOLAR}	{ printf("Erro: Identificador invalido: %s\n", yytext); }

	/* --- Comentários e Palavras-chave --- */
"//".*				{ lexema = yytext; return _COMENTARIO; }
\/\*([^*]|\*+[^*/])*\*+\/	{ lexema = yytext; return _COMENTARIO; }
[fF][oO][rR]		{ lexema = yytext; return _FOR; }
[iI][fF]			{ lexema = yytext; return _IF; }

	/* --- STRING --- */
\"([^"\n\\]|\\.|"\"")*\"	{
	string s = "";
	char delimitador = yytext[0];

	for (int i = 1; yytext[i] != '\0' && yytext[i+1] != '\0'; i++) {
		if (yytext[i] == '\\') {
			i++;
			switch (yytext[i]) {
				case 'n': s += '\n'; break;
				case 't': s += '\t'; break;
				default: s += yytext[i]; break;
			}
		} 
		else if (yytext[i] == delimitador && yytext[i+1] == delimitador) {
			s += delimitador;
			i++;
		}
		else {
			s += yytext[i];
		}
	}
	lexema = s;
	return _STRING;
}

\'([^'\n\\]|\\.|'\'')*\'	{
	string s = "";
	char delimitador = yytext[0];

	for (int i = 1; yytext[i] != '\0' && yytext[i+1] != '\0'; i++) {
		if (yytext[i] == '\\') {
			i++;
			switch (yytext[i]) {
				case 'n': s += '\n'; break;
				case 't': s += '\t'; break;
				default: s += yytext[i]; break;
			}
		} 
		else if (yytext[i] == delimitador && yytext[i+1] == delimitador) {
			s += delimitador;
			i++;
		}
		else {
			s += yytext[i];
		}
	}
	lexema = s;
	return _STRING;
}

    /* --- STRING2 --- */

\`\`([^\`\\]|\\.)*\`\` {
	string s = "";
	for (int i = 1; yytext[i] != '\0' && yytext[i+1] != '\0'; i++) {
		if (yytext[i] == '\\') {
			i++;
			s += yytext[i];
		} else {
			s += yytext[i];
		}
	}
	lexema = s;
	return _STRING2;
}

	/* --- Operadores --- */
">="				{ lexema = yytext; return _MAIG; }
"<="				{ lexema = yytext; return _MEIG; }
"=="				{ lexema = yytext; return _IG; }
"!="				{ lexema = yytext; return _DIF; }

	/* --- Números (_FLOAT antes de _INT) --- */
{DIGITO}+\.{DIGITO}*([eE][+-]?{DIGITO}+)?	{ lexema = yytext; return _FLOAT; }
{DIGITO}+[eE][+-]?{DIGITO}+				{ lexema = yytext; return _FLOAT; }
{DIGITO}+			{ lexema = yytext; return _INT; }

	/* --- Identificadores Válidos --- */
\${ID_CHARS}+		{ lexema = yytext; return _ID; } 
\$					{ lexema = yytext; return _ID; } 
{ID_NORMAL}			{ lexema = yytext; return _ID; }

{SIMBOLOS}			{ lexema = yytext; return yytext[0]; }

	/* --- Regra Final para outros caracteres inválidos --- */
.					{ fprintf(stderr, "Erro lexico na linha %d: Caractere invalido '%s'\n", yylineno, yytext); }

%%

int yywrap() {
	return 1;
}