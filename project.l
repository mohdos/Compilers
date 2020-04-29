%{
#include <stdlib.h>
#include "project.h"
#include "y.tab.h"
#include <string.h>
#include <time.h>
void yyerror(char *);
%}

%%
[+][=]      {
                return ATOMICPLUS;
            }

[-][=]      {
                return ATOMICMINUS;
            }

[*][=]      {
                return ATOMICMULT;
            }

[/][=]      {
                return ATOMICDIV;
            }

0           {
                yylval.iValue = atoi(yytext);
                return INTEGER;
            }

[1-9][0-9]* {
                yylval.iValue = atoi(yytext);
                return INTEGER;
            }

[0-9]+"."[0-9]+ {
                   yylval.fValue=atof(yytext);
		           return FLOAT;
                 }

[-()<>=+*/;{}.,] {
                return *yytext;
             }


"print"         return PRINT;


"int"          return INTDATATYPE;
"string"       return STRINGDATATYPE;
"float"        return FLOATDATATYPE;
"char"         return CHARDATATYPE;

[ \t\n]+        ;       /* ignore whitespace */

[a-zA-Z][a-zA-Z0-9_]* {
			// we put it here, to be able to match our keywords without any conflict
                int i;
                        for(i=0;i<globalIndex;i++) // search for it in the symbol table
                        {
                            if(!strcmp(name[i],yytext)) // found it in the symbol table
                            {
                                yylval.sIndex = i;
                                // START
                                if(!currentVariableFlag)
                                {
                                    strcpy(currentVariable,name[i]);
                                    currentVariableFlag=1;
                                }
                                // END
                                return VARIABLE;
                            }
                        }
                        name[globalIndex]=malloc(sizeof(char*));
                        sym[globalIndex]=malloc(sizeof(conNodeType*));
                        sym[globalIndex]->initialized = 0;
                        strcpy(name[globalIndex],yytext);
                        sym[globalIndex]->type=NONE; //to initialise the type
                        yylval.sIndex = globalIndex;
                        
                        if(!currentVariableFlag)
                        {
                            strcpy(currentVariable,name[globalIndex]);
                            currentVariableFlag=1;
                        }

                        globalIndex++; 
                	return VARIABLE;	
			}
\"[^"\n]*["\n] {
			// we put it here, to be able to match our keywords without any conflict
                    char *tempC = yytext+1;
                    tempC[strlen(tempC)-1] = 0;
                    yylval.sValue = tempC;
                	return STRING;
			}

\'[^'\n]['\n] {
			        // we put it here, to be able to match our keywords without any conflict
                    char *tempC = yytext+1;
                    tempC[strlen(tempC)-1] = 0;
                    yylval.iValue = *(int *)tempC;
                	return CHAR;	
			}

[/][/][^\n]*\n                ;

.               yyerror("Unknown character");
%%
int yywrap(void) {
    return 1;
}
