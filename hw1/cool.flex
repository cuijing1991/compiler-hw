/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
 
#define ERROR(msg) do { cool_yylval.error_msg = (msg); return (ERROR);} while (0)
#define string_buf_push(c) \
	if(string_buf_ptr - string_buf >= MAX_STR_CONST) \
  ERROR("String constant too long"); \
	*string_buf_ptr++ = (c);

%}

/*
 * Define names for regular expressions here.
 */


CLASS           (?i:class)
ELSE            (?i:else)
FI              (?i:fi)
IF              (?i:if)
IN              (?i:in)
INHERITS        (?i:inherits)
LET             (?i:let)
LOOP            (?i:loop)
POOL            (?i:pool)
THEN            (?i:then)
WHILE           (?i:while)
CASE            (?i:case)
ESAC            (?i:esac)
OF              (?i:of)
NEW             (?i:new)
ISVOID          (?i:isvoid)
NOT             (?i:not)

TRUE            t[Rr][Uu][Ee]
FALSE           f[Aa][Ll][Ss][Ee]

DIGIT	 	        [0-9]+

TYPEID          [A-Z][_0-9a-zA-Z]*
OBJECTID        [a-z][_0-9a-zA-Z]*

DARROW          =>
ASSIGN          <-
LE              <=
OPS 		        [-=:;.(){}@,~+*/<]

NEW_LINE	      \n
SPACE 		      [ \t\v\f\r]*

%x comment
%{
	int comment_level;
	void start_comment();
	void end_comment();
%}
LINE_COMMENT 	  --[^\n]*
COMMENT_START   \(\*
COMMENT_END 	  \*\)

%x str
STR_START       \"
STR_NULL        \0
STR_NL          \\\n
STR_UNESP_NL    \n
STR_CHAR        [^"\\\n]
STR_END         \"

%%



 /*
  *  Nested comments
  */

{LINE_COMMENT}  { }

<comment>{COMMENT_START}			      {
                                      int c;
                                      comment_level = 0;
                                      start_comment();
                    	                while ((c = yyinput()) != 0)
                    	                {
                                        if (c == '\n')
                    			              curr_lineno++;
                    		                else if (c == '*')
                    		                {
                                          int cc = yyinput();
                    			                if (cc == ')')
                    			                {
                                            end_comment();
                                            if (comment_level == 0) break;
                    		              	  }
                    		                	else
                                            unput(cc);
                    		                }
                    		                else if (c == '(')
                    		                {
                    			                int cc = yyinput();
                    			                if (cc == '*')
                    				                 comment_level++;
                    			                else
                                            unput(cc);
                    		                }
                    		                if (EOF == c)
                    		                {
                    			                ERROR("EOF in comment");
                    		                }
                    	                }
                                      if (c == 0)
                                         ERROR("Null character in comment");
                    			          } // end of comments

<comment>{COMMENT_END} 			        { ERROR("Unmatched *)"); }


 /*
  *  The multiple-character operators.
  */

{DARROW}        { return (DARROW); }
{ASSIGN}		    { return (ASSIGN); }
{LE}		        { return (LE); }
{OPS} 			    { return *yytext; }

{DIGIT}			    { yylval.symbol = inttable.add_string(yytext); return (INT_CONST); }

{NEW_LINE}      { ++curr_lineno; }
{SPACE} 		    { }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}          { return (CLASS); }
{ELSE}           { return (ELSE); }
{FI}             { return (FI); }
{IF}             { return (IF); }
{IN}             { return (IN); }
{INHERITS}       { return (INHERITS); }
{LET}            { return (LET); }
{LOOP}           { return (LOOP); }
{POOL}           { return (POOL); }
{THEN}           { return (THEN); }
{WHILE}          { return (WHILE); }
{CASE}           { return (CASE); }
{ESAC}           { return (ESAC); }
{OF}             { return (OF); }
{NEW}            { return (NEW); }
{ISVOID}         { return (ISVOID); }
{NOT}            { return (NOT); }

{TRUE}           { yylval.boolean = 1; return (BOOL_CONST); }
{FALSE}          { yylval.boolean = 0; return (BOOL_CONST); }

{TYPEID}         { yylval.symbol = idtable.add_string(yytext); return (TYPEID); }
{OBJECTID}       { yylval.symbol = idtable.add_string(yytext); return (OBJECTID); }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

{STR_START}           { string_buf_ptr = string_buf; BEGIN(str); }
<str>STR_NULL		      { ERROR("String contains null character"); }
<str>{STR_NL}         {
	                      string_buf_push('\n');
	                      ++curr_lineno;
                      }
<str>{STR_UNESP_NL}   {
	                      ++curr_lineno;
	                      BEGIN(INITIAL);
	                      ERROR("Unterminated string constant");
                      }
<str><<EOF>>		      { ERROR("EOF in string constant");}
<str>\\n		          { string_buf_push('\n'); }
<str>\\t		          { string_buf_push('\t'); }
<str>\\b		          { string_buf_push('\b'); }
<str>\\f		          { string_buf_push('\f'); }

<str>{STR_CHAR}		      { string_buf_push(yytext[0]); }
<str>{STR_END}        {
	                      *string_buf_ptr++ = '\0';
	                      cool_yylval.symbol = stringtable.add_string(string_buf);
	                      BEGIN(INITIAL);
	                      return (STR_CONST);
                      }
.			                { ERROR(yytext); }

%%

void start_comment()
{
	if (comment_level == 0)
	{
		BEGIN(comment);
	}
	++comment_level;
}
void end_comment()
{
	--comment_level;
	if (comment_level == 0)
	{
		BEGIN(INITIAL);
	}
}