%skeleton "lalr1.cc"
%require  "3.0"
%debug
%defines
%define api.namespace {negatron}
//%define parser_class_name {Parser}
%define api.parser.class {Parser}
%define parse.error verbose
%output "parser.cc"
%token-table

%code requires{
   #include <list>
   #include "tokens.hpp"
   #include "ast.hpp"
   namespace negatron {
      class Scanner;
   }

// The following definitions is missing when %locations isn't used
# ifndef YY_NULLPTR
#  if defined __cplusplus && 201103L <= __cplusplus
#   define YY_NULLPTR nullptr
#  else
#   define YY_NULLPTR 0
#  endif
# endif

}

%parse-param { negatron::Scanner  &scanner  }
%parse-param { negatron::ProgramNode** root }

%code{
   #include <iostream>
   #include <cstdlib>
   #include <fstream>

   /* include for interoperation between scanner/parser */
   #include "scanner.hpp"

#undef yylex
#define yylex scanner.yylex
}

/*
The %union directive is a way to specify the
set of possible types that might be used as
translation attributes in the syntax-directed
translations.
*/
%union {
  bool                                  transBool;
  negatron::Token *                     transToken;
  negatron::IDToken *                   transIDToken;
  negatron::ProgramNode *               transProgram;
  std::list<negatron::DeclNode *> *     transDeclList;
  negatron::DeclNode *                  transDecl;
  negatron::VarDeclNode *               transVarDecl;
  negatron::TypeNode *                  transType;
  negatron::IDNode *                    transID;
}

/* Nonterminals
*  TODO: You will need to add more nonterminals
*  to this list as you add productions to the grammar
*  below (along with indicating the appropriate translation
*  attribute type). Note that the specifier in brackets
*  indicates the type of the translation attribute using
*  the names defined in the %union directive above
*/
/*    (attribute type)    (nonterminal)    */
%type <transProgram>      program
%type <transDeclList>     globals
%type <transDecl>         decl
%type <transVarDecl>      varDecl
%type <transType>         type
%type <transID>           id
%type <transBool>         maybeRef


/* TODO you will have to
   add an attribute type for
   a couple of the tokens below
*/
%token               END    0     "end of file"
%token               REF
%token <transToken>  BOOL
%token <transToken>  INT
%token <transToken>  VOID
%token               FALSE
%token               STRUCT
%token               NULLREF
%token               OUTPUT
%token               INPUT
%token               IF
%token               ELSE
%token               WHILE
%token               RETURN
%token <transIDToken> ID
%token               INTLITERAL
%token               STRLITERAL
%token               LCURLY
%token               RCURLY
%token               LPAREN
%token               RPAREN
%token               SEMICOLON
%token               COMMA
%token               DOT
%token               DASHDASH
%token               DASH
%token               STAR
%token               SLASH
%token               NOT
%token               NOTEQUALS
%token               LESS
%token               LESSEQ
%token               ASSIGN
%token               AND
%token               OR



/* TODO: Make sure to add precedence and associativity
 * declarations!
*/

%%

/* TODO: fill out the rest of the productions/SDD rules */
program 	: globals
	{
	$$ = new ProgramNode($1);
	*root = $$;
	}
  	;

globals 	: globals decl
	{
	$$ = $1;
	DeclNode * aGlobalDecl = $2;
	$1->push_back(aGlobalDecl);
	}
	| /* epsilon */
	{
	std::list<DeclNode *> * startingGlobals;
	startingGlobals = new std::list<DeclNode *>();
	$$ = startingGlobals;
	}
	;

decl : varDecl
	{
	//Make sure to fill out this rule
	// (as well as any other empty rule!)
	}

varDecl : type id SEMICOLON
	{
	size_t typeLine = $1->line();
	size_t typeCol = $1->col();
	$$ = new VarDeclNode(typeLine, typeCol, $1, $2);
	}

type 	: INT maybeRef
	{
	bool isRef = $2;
	$$ = new IntTypeNode($1->line(), $1->col(), isRef);
	}
  | BOOL maybeRef
  {
  bool isRef = $2;
  $$ = new BoolTypeNode($1->line(), $1->col(), isRef);
  }
  | VOID
  {
    // bool isRef = false;
    $$ = new VoidTypeNode($1->line(),$1->col(), false);
  }


	/*
	Note that there are a lot more types for you to fill in!
	*/

/* This production is a good example of recognizing an optional token:
   the programmer could declare int a; or int & b; matching the type
   production above. In the former declaration, maybeRef produces epsilon
   and has its attribute translation set to false. .
   In the latter declaration, maybeRef matches the REF token and has its
   translation attribute set to true.
*/
maybeRef : REF
	{ $$ = true; }
	| /* epsilon */
	{ $$ = false; }
	;

id : ID { $$ = new IDNode($1); }
%%
void
negatron::Parser::error(const std::string &err_message )
{
   /* For project grading, only report "syntax error"
      if a program has bad syntax. However, you will
      probably want better output for debugging. Thus,
      this error function prints a verbose message to
      stdout, but only prints "syntax error" to stderr
   */
   std::cout << err_message << std::endl;
   std::cerr << "syntax error" << std::endl;
}
