%{
#include <string>
#include <limits.h>

/* Get our custom yyFlexScanner subclass */
#include "scanner.hpp"
#undef YY_DECL
#define YY_DECL int negatron::Scanner::yylex(negatron::Parser::semantic_type * const lval)

using TokenKind = negatron::Parser::token;

/* define yyterminate as returning an EOF token (instead of NULL) */
#define yyterminate() return ( TokenKind::END )

/* exclude unistd.h for Visual Studio compatibility. */
#define YY_NO_UNISTD_H

%}

%option nodefault
%option yyclass="negatron::Scanner"
%option noyywrap
%option c++

DIGIT [0-9]
WHITESPACE [\040\t]
LETTER [a-zA-Z]
ESC_CHAR [nt'\"?\\]
NOT_NL_OR_ESC_CHAR [^\nnt'\"?\\]
NOT_NL_OR_QUOTE [^\n\"]
NOT_NL_OR_QUOTE_OR_ESC [^\n\"\\]

%%
%{
	this->yylval = lval;
%}

int  	{ return makeBareToken(TokenKind::INT); }
bool 	{ return makeBareToken(TokenKind::BOOL); }
void 	{ return makeBareToken(TokenKind::VOID); }
null 	{ return makeBareToken(TokenKind::NULLREF); }
if  	{ return makeBareToken(TokenKind::IF); }
else	{ return makeBareToken(TokenKind::ELSE); }
while	{ return makeBareToken(TokenKind::WHILE); }
return	{ return makeBareToken(TokenKind::RETURN); }
false  	{ return makeBareToken(TokenKind::FALSE); }
input	{ return makeBareToken(TokenKind::INPUT); }
output	{ return makeBareToken(TokenKind::OUTPUT); }
struct	{ return makeBareToken(TokenKind::STRUCT); }
nullref { return makeBareToken(TokenKind::NULLREF); }
"{"		{ return makeBareToken(TokenKind::LCURLY); }//Done
"}"		{ return makeBareToken(TokenKind::RCURLY); }//Done
"("		{ return makeBareToken(TokenKind::LPAREN); }//Done
")"		{ return makeBareToken(TokenKind::RPAREN); }//Done
";"		{ return makeBareToken(TokenKind::SEMICOLON); }
","		{ return makeBareToken(TokenKind::COMMA); }
"."		{ return makeBareToken(TokenKind::DOT); }
"--"	{ return makeBareToken(TokenKind::DASHDASH); }
"-"		{ return makeBareToken(TokenKind::DASH); } //Done
"*"		{ return makeBareToken(TokenKind::STAR); }//Done
"/"		{ return makeBareToken(TokenKind::SLASH); }//Done
"!"		{ return makeBareToken(TokenKind::NOT); }//Done
"&"	{ return makeBareToken(TokenKind::REF); }
"&&"	{ return makeBareToken(TokenKind::AND); }
"||"	{ return makeBareToken(TokenKind::OR); }
"!="	{ return makeBareToken(TokenKind::NOTEQUALS); }//Done
"<"		{ return makeBareToken(TokenKind::LESS); }//Done
"<="	{ return makeBareToken(TokenKind::LESSEQ); }//Done
"="		{ return makeBareToken(TokenKind::ASSIGN); }//Done
({LETTER}|_)({LETTER}|{DIGIT}|_)*		{
		yylval->transToken =
		    new IDToken(lineNum, charNum, yytext);
		charNum += yyleng;
		return TokenKind::ID;
		}

{DIGIT}+	{
			double asDouble = std::stod(yytext);
			int intVal = atoi(yytext);
			bool overflow = false;
			if (asDouble > INT_MAX){ overflow = true; }
			if (strlen(yytext) > 10){ overflow = true; }

			if (overflow){
				std::string msg = "Integer literal too"
				" large; using max value";
				Report::warn(lineNum, charNum, msg);
				intVal = INT_MAX;
			}
			yylval->transToken =
			  new IntLitToken(lineNum, charNum, intVal);
			charNum += yyleng;
			return TokenKind::INTLITERAL;
			}

\"({NOT_NL_OR_QUOTE_OR_ESC}|\\{ESC_CHAR})*\" {
		yylval->transToken = new StrToken(lineNum, charNum, yytext);
		this->charNum += yyleng;
		return TokenKind::STRLITERAL;
          }

\"({NOT_NL_OR_QUOTE_OR_ESC}|\\{ESC_CHAR})* {
		// unterminated string
		Report::fatal(lineNum, charNum,
		  "Unterminated string literal ignored");
		charNum += yyleng;
		}

\"({NOT_NL_OR_QUOTE_OR_ESC}|\\{ESC_CHAR})*\\{NOT_NL_OR_ESC_CHAR}({NOT_NL_OR_QUOTE})*\" {
		// bad escape character
		Report::fatal(lineNum, charNum,
		  "string literal with bad escaped character ignored");
		charNum += yyleng;
		}

\"({NOT_NL_OR_QUOTE_OR_ESC}|\\{ESC_CHAR})*(\\{NOT_NL_OR_ESC_CHAR})?({NOT_NL_OR_QUOTE_OR_ESC}|\\{ESC_CHAR})*\\? {
		// unterminated AND bad escape character
		std::string msg = "Unterminated string literal"
		" with bad escaped character ignored";
		Report::fatal(lineNum, charNum, msg);
		charNum += yyleng;
		}

\n|(\r\n)   {
		lineNum++;
		charNum = 1;
		}


[ \t]+	{
		charNum += yyleng;
	    }

("#")[^\n]*	{
		//Comment. Ignore. Don't need to update char num
		// since everything up to end of line will never by
		// part of a report
		}

.		{
		std::string msg = "Illegal character ";
		msg += yytext;
		Report::fatal(lineNum,charNum,msg);
		this->charNum += yyleng;
		}
%%
