%{
using namespace std;
string lexema;

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

	/* --- Regra de Erro para Identificadores Inválidos --- */
{ID_INVALIDO_A}|{ID_INVALIDO_DOLAR}	{ printf("Erro: Identificador invalido: %s\n", yytext); }

	/* --- Comentários e Palavras-chave --- */
"//".*				{ lexema = yytext; return _COMENTARIO; }
\/\*([^*]|\*+[^*/])*\*+\/	{ lexema = yytext; return _COMENTARIO; }
[fF][oO][rR]		{ lexema = yytext; return _FOR; }
[iI][fF]			{ lexema = yytext; return _IF; }

	/* --- Operadores --- */
">="				{ lexema = yytext; return _MAIG; }
"<="				{ lexema = yytext; return _MEIG; }
"=="				{ lexema = yytext; return _IG; }
"!="				{ lexema = yytext; return _DIF; }

	/* --- Números (_FLOAT antes de _INT) --- */
{DIGITO}+\.{DIGITO}*([eE][+-]?{DIGITO}+)? { lexema = yytext; return _FLOAT; }
{DIGITO}+[eE][+-]?{DIGITO}+				{ lexema = yytext; return _FLOAT; }
{DIGITO}+			{ lexema = yytext; return _INT; }

	/* --- Identificadores Válidos --- */
\${ID_CHARS}+		{ lexema = yytext; return _ID; }
\$					{ lexema = yytext; return _ID; }
{ID_NORMAL}			{ lexema = yytext; return _ID; }

{SIMBOLOS}			{ lexema = yytext; return yytext[0]; }


	/* --- STRING PADRÃO --- */
(\"([^\\"\n]|\\.|\"\")*\") {
	string s = "";
	const char delimitador = yytext[0];
	const int len = yyleng;
	for (int i = 1; i < len - 1; i++) {
		if (yytext[i] == '\\') {
			if (i + 1 < len - 1) { 
				i++;
				switch (yytext[i]) {
					case 'n': s += "\\n"; break; 
					case 't': s += "\\t"; break;
					case '"': s += '"';  break;
					case '\'': s += '\''; break;
					case '\\': s += "\\\\"; break;
					default: s += '\\'; s += yytext[i]; break;
				} 
			} else { s += '\\'; }
		} else if (yytext[i] == delimitador && (i + 1 < len - 1) && yytext[i+1] == delimitador) {
			s += delimitador; i++;
		} else { s += yytext[i]; }
	}
	lexema = s;
	return _STRING;
}

(\'([^\\'\n]|\\.|\'\')*\') {
	string s = "";
	const char delimitador = yytext[0];
	const int len = yyleng;
	for (int i = 1; i < len - 1; i++) {
		if (yytext[i] == '\\') {
			if (i + 1 < len - 1) { 
				i++; // Avança para o caractere escapado
				switch (yytext[i]) {
					case 'n': s += "\\n"; break;
					case 't': s += "\\t"; break;
					case '"': s += '"';  break;
					case '\'': s += '\''; break;
					case '\\': s += "\\\\"; break;
					default: s += '\\'; s += yytext[i]; break;
				} 
			} else { s += '\\'; }
		} else if (yytext[i] == delimitador && (i + 1 < len - 1) && yytext[i+1] == delimitador) {
			s += delimitador; i++;
		} else { s += yytext[i]; }
	}
	lexema = s;
	return _STRING;
}

	/* --- STRING 2 --- */
\`([^\\`]|\\.)*\` {
	string content(yytext + 1, yyleng - 2);
	string buffer = "";

	for (int i = 0; i < content.length(); ++i) {
		if (content[i] == '$' && i + 1 < content.length() && content[i+1] == '{') {
			if (!buffer.empty()) {
				printf("%d %s\n", _STRING2, buffer.c_str());
				buffer = "";
			}

			i += 2; 
			int start_expr = i;
			int brace_count = 1;

			while (i < content.length()) {
				if (content[i] == '{') brace_count++;
				else if (content[i] == '}') brace_count--;
				
				if (brace_count == 0) break;
				i++;
			}

			if (brace_count == 0) {
				string var = content.substr(start_expr, i - start_expr);
				printf ( "%d %s\n", _EXPR, var.c_str() );
			}

		} else {
			buffer += content[i];
		}
	}

	if (!buffer.empty()) {
		printf("%d %s\n", _STRING2, buffer.c_str());
	}
}

	/* --- Regra Final para outros caracteres inválidos --- */
. { fprintf(stderr, "Erro lexico na linha %d: Caractere invalido '%s'\n", yylineno, yytext); }

%%

int yywrap() {
	return 1;
}