%{
#include "decafcomp-defs.h"
#include "decafcomp.tab.h"
#include <cstring>
#include <string>
#include <sstream>
#include <iostream>

using namespace std;

int lineno = 1;
int tokenpos = 1;
%}

%%
  /*
    Pattern definitions for all tokens 
  */

func                       { return T_FUNC; }
return                     { return T_RETURN; }
int                        { yylval.typeval=new string(yytext); return T_INTTYPE; }
string                     { yylval.typeval=new string(yytext); return T_STRINGTYPE; }
var                        { return T_VAR; }
void                       { yylval.typeval=new string(yytext); return T_VOID; }
null                       { return T_NULL; }
package			   { return T_PACKAGE; }
continue                   { return T_CONTINUE; }
break                      { return T_BREAK; }
for                        { return T_FOR; }
while                      { return T_WHILE; }
bool                       { yylval.typeval=new string(yytext); return T_BOOLTYPE; }
false                      { yylval.ival = 0; return T_FALSE; }
true                       { yylval.ival = 1; return T_TRUE; }
extern                     { return T_EXTERN; }
if                         { return T_IF; }
else                       { return T_ELSE; }
\/{2}.*\n                  { lineno++;}
(\')(\\[abtvfrn\\\'\"]|[^\n\\\'])(\')     { if (strlen(yytext)>3) {
						switch (yytext[2]) {
						case 'n': yylval.ival = int('\n'); break;
						case 'r': yylval.ival = int('\r'); break;
						case 't': yylval.ival = int('\t'); break;
						case 'v': yylval.ival = int('\v'); break;
						case 'f': yylval.ival = int('\f'); break;
						case 'a': yylval.ival = int('\a'); break;
						case 'b': yylval.ival = int('\b'); break;
						case '\'': yylval.ival = int('\''); break;
						case '"': yylval.ival = int('\"'); break;
                                                case '\\': yylval.ival = int('\\'); break;

						}
					  } else yylval.ival = int(yytext[1]); return T_CHARCONSTANT; }
[0-9]|[1-9][0-9]+|0(x|X)[0-9a-fA-F]+      { 
						if(yytext[1]=='x' || yytext[1]=='X')  yylval.ival = std::stoi(yytext, nullptr, 16);
						else yylval.ival = std::stoi(yytext);
						return T_INTCONSTANT; 

					}
\"(\\[abtvfrn\\\'\"]|[^\\\n\"])*\"        { yylval.sval = new string(yytext); return T_STRINGCONSTANT; }
\[                         { return T_LSB; }
\]                         { return T_RSB; }
\{                         { return T_LCB; }
\}                         { return T_RCB; }
\(                         { return T_LPAREN; }
\)                         { return T_RPAREN; }
[a-zA-Z\_][a-zA-Z\_0-9]*   { yylval.idval = new string(yytext); return T_ID; } /* note that identifier pattern must be after all keywords */
[\t\r\a\v\b ]+             { } 
\n			   {++lineno;}/* ignore whitespace */
==                         { return T_EQ; }
=                          { return T_ASSIGN; }
!=                         { return T_NEQ; }
!                          { return T_NOT; }
&&                         { return T_AND; }
\|\|                       { return T_OR; }
,                          { return T_COMMA; }
>=                         { return T_GEQ; }
>>                         { return T_RIGHTSHIFT; }
>                          { return T_GT; }
\<\=                       { return T_LEQ; }
\<\<                        { return T_LEFTSHIFT; }
\<                          { return T_LT; }
\/                          { return T_DIV; }
\+                          { return T_PLUS; }
\-                          { return T_MINUS; }
\*                          { return T_MULT; }
\%                          { return T_MOD; }
\;                          { return T_SEMICOLON; }
\.                          { return T_DOT; }
.                          { cerr << "Error: unexpected character in input" << endl; return -1; }
%%

int yyerror(const char *s) {
  cerr << lineno << ": " << s << " at char " << tokenpos << endl;
//  descriptor* errorReport = symtbl.back()[lastId];
//  cerr << "defined variable: "+ lastId +", with type: "+ errorReport->type +", on line number: "+ lineno;
  return 1;
}

