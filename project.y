%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include "project.h"
#include <string.h>

/* prototypes */
nodeType *opr(int oper, int nops, ...);
nodeType *atomicOpr(int oper, int nops, ...);
nodeType *oprNew(int oper, nodeType * nt1, nodeType *nt2);
int getVarTypeFromNode(nodeType *n);
nodeType *id(int i);
nodeType *con(void *ptr,int type);
nodeType *idWithDatatype(int,int);
nodeType* declarationWithOperation(int i, int type, nodeType *nt);
void printOpr(nodeType *n);
void freeNode(nodeType *p);
int yylex(void);
void yyerror(char *s);
conNodeType* sym[100];                    /* symbol table */
char* name[100];                         // maps the   
int  available[100];
int globalIndex;

char currentVariable[100];//for quadruples it will be set when the lexical sees a variable
int temp=0;
int currentVariableFlag=0;
%}


%union {
    int iValue;                 /* integer value */ //also for char
    float fValue;               // float value
    char* sValue;               // String value
    char sIndex;                /* symbol table index */
    nodeType *nPtr;             /* node pointer */
};

%token <iValue> INTEGER
%token <iValue> CHAR
%token <fValue> FLOAT
%token <sValue> STRING
%token <sIndex> VARIABLE
%token INTDATATYPE STRINGDATATYPE FLOATDATATYPE CHARDATATYPE
%token PRINT 
%token ATOMICPLUS ATOMICMINUS ATOMICDIV ATOMICMULT
%nonassoc IFX
%nonassoc ELSE

%left GE LE EQ NE '>' '<'
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type <nPtr> stmt expr stmt_list

%%

program:
        function                { exit(0); }
        ;

function:
          function stmt         { freeNode($2); }
        | /* NULL */
        ;

stmt:
          ';'                                                               { $$ = opr(';', 2, NULL, NULL); }
        | INTDATATYPE VARIABLE '=' expr';'                                  { $$ = declarationWithOperation($2,0,$4); }
        | FLOATDATATYPE VARIABLE '=' expr';'                                { $$ = declarationWithOperation($2,1,$4); }
        | STRINGDATATYPE VARIABLE '=' expr';'                               { $$ = declarationWithOperation($2,2,$4); }
        | CHARDATATYPE VARIABLE '=' expr';'                                 { $$ = declarationWithOperation($2,3,$4); }
        | INTDATATYPE VARIABLE';'                                           { $$ = idWithDatatype($2,0);}
        | FLOATDATATYPE VARIABLE';'                                         { $$ = idWithDatatype($2,1);}
        | STRINGDATATYPE VARIABLE';'                                        { $$ = idWithDatatype($2,2);}
        | CHARDATATYPE VARIABLE';'                                          { $$ = idWithDatatype($2,3);}
        | expr ';'                                                          { $$ = $1; }
        | PRINT expr ';'                                                    { printOpr($2); $$ = $2;}
        | VARIABLE '=' expr ';'                                             { $$ = opr('=', 2, id($1), $3); }
        | VARIABLE ATOMICPLUS expr ';'                                      { $$ = atomicOpr('+'+'=', 2, id($1), $3); }
        | VARIABLE ATOMICMINUS expr ';'                                     { $$ = atomicOpr('-'+'=', 2, id($1), $3); }
        | VARIABLE ATOMICDIV expr ';'                                       { $$ = atomicOpr('/'+'=', 2, id($1), $3); }
        | VARIABLE ATOMICMULT expr ';'                                      { $$ = atomicOpr('*'+'=', 2, id($1), $3); }
        | '{' stmt_list '}'                                                 { $$ = $2; }
        ;



stmt_list:
          stmt                  { $$ = $1; }
        | stmt_list stmt        { $$ = opr(';', 2, $1, $2); }
        ;

expr:
          INTEGER               { $$ = con(&$1,0); }
        | FLOAT                 { $$ = con(&$1,1); }
        | STRING                { $$ =  con($1,2); }
        | CHAR                  { $$ =  con(&$1,3); }
        | VARIABLE              { $$ = id($1); }
        | '-' expr %prec UMINUS { $$ = oprNew('-', NULL, $2); }
        | expr '+' expr         { $$ = oprNew('+', $1, $3); }
        | expr '-' expr         { $$ = oprNew('-', $1, $3); }
        | expr '*' expr         { $$ = oprNew('*', $1, $3); }
        | expr '/' expr         { $$ = oprNew('/', $1, $3); }
        | '(' expr ')'          { $$ = $2; }
        ;

%%


nodeType* declarationWithOperation(int i, int type, nodeType *n)
{
    nodeType *p;

    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    /* copy information */
    conNodeType* nt=malloc(sizeof(conNodeType*));
    if(n->type==typeCon)
    {
        nt=&n->con;
    }
    else if (n->type == typeId)
    {
        int j=n->id.i;
        if (available[j] == 1)
        {
            yyerror("Use of undeclared variable");
            exit(0);
        }
        nt=sym[j];
    }
    else
    {
        // type operation
        for (int k = 0; k < n->opr.nops; k++)
        {
            if (n->opr.op[k]->type == typeId && available[n->opr.op[k]->id.i] == 1)
            {
                yyerror("Variable used without being initialized");
                exit(0);
            }
        }
        nt->type = getVarTypeFromNode(n->opr.op[0]);
    }
    

    if (type != nt->type)
    {
        if (!((type == typeInt && nt->type == typeChar) || (type == typeChar && nt->type == typeInt))) // to account for char=int or int = char
        {
            yyerror("type mismatch");
            exit(0);
        }
    }

    if (available[i] != 1)
    {
        yyerror("Variable redeclared\n");
        exit(0);
    }
    available[i] = 0;
    p->type = typeId;
    p->id.i = i;
    sym[i]->type = type;
    
    if (type == 0)
    {
        // int
        sym[i]->intValue = nt->intValue;
    }
    else if (type == 1)
    {
        sym[i]->floatValue = nt->floatValue;
    }
    else if(type == 2)
    {
        strcpy(sym[i]->stringValue, nt->stringValue);
    }
    else
    {
        sym[i]->intValue = nt->intValue;
    }

    return opr('=', 2, p, n);
}


nodeType *con(void *ptr,int type) {
    
    nodeType *p;
    /* allocate node */
    if ((p = (nodeType*)malloc(sizeof( nodeType))) == NULL)
    {
        yyerror("out of memory");
    }
    // int
   
    if(type==0)
    {
    	/* copy information */
    	p->type = typeCon;
        p->con.type=typeInt;
    	p->con.intValue = *(int*)ptr;
    }

    // float
    else if(type==1)
    {
    	/* copy information */
    	p->type = typeCon;
        p->con.type=typeFloat;
    	p->con.floatValue = *(float*)ptr;
    }
    // String
    else if(type==2)
    {
    	/* copy information */
    	p->type = typeCon;
        p->con.type=typeString;
        strcpy(p->con.stringValue, (char *)ptr);
    }
    else
    {
        /* copy information */
    	p->type = typeCon;
        p->con.type=typeChar;
    	p->con.intValue = *(char*)ptr;
    }
    return p;
}

nodeType *id(int i) {

    nodeType *p;

    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeId;
    p->id.i = i;
    
    return p;
}

nodeType *idWithDatatype(int i,int dataType) {
    
    nodeType *p;

    /* allocate node */
    if ((p = malloc(sizeof(nodeType))) == NULL)
        yyerror("out of memory");

    if (available[i] != 1)
    {
        yyerror("Variable redeclared\n");
        exit(0);
    }
    available[i] = 0;
    /* copy information */
    p->type = typeId;
    p->id.i = i;
    sym[i]->type=dataType;
    currentVariableFlag=0;//reseting it for the quadruples
    return p;
}

nodeType *atomicOpr(int oper, int nops, ...)
{
    va_list ap;
    va_start(ap, nops);
    if (oper == '+' + '=')
    {
        nodeType *p0 = va_arg(ap, nodeType *);
        nodeType *p1 = va_arg(ap, nodeType *);

        nodeType *n1 = oprNew('+', p0, p1);
        nodeType *t = opr('=', 2, p0, n1);
        return t;
    }
    else if (oper == '-' + '=')
    {
        nodeType *p0 = va_arg(ap, nodeType *);
        nodeType *p1 = va_arg(ap, nodeType *);

        nodeType *n1 = oprNew('-', p0, p1);
        return opr('=', 2, p0, n1);
    }
    else if (oper == '*' + '=')
    {
        nodeType *p0 = va_arg(ap, nodeType *);
        nodeType *p1 = va_arg(ap, nodeType *);

        nodeType *n1 = oprNew('*', p0, p1);
        return opr('=', 2, p0, n1);
    }
    else if (oper == '/' + '=')
    {
        nodeType *p0 = va_arg(ap, nodeType *);
        nodeType *p1 = va_arg(ap, nodeType *);

        nodeType *n1 = oprNew('/', p0, p1);
        return opr('=', 2, p0, n1);
    }
    va_end(ap);
}

nodeType *opr(int oper, int nops, ...) {

    va_list ap;

    nodeType *p;
    int i;
    /* allocate node, extending op array */
    if ((p = malloc(sizeof(nodeType) + (nops-1) * sizeof(nodeType *))) == NULL)
        yyerror("out of memory");

    /* copy information */
    p->type = typeOpr;
    p->opr.oper = oper;
    p->opr.nops = nops;
    va_start(ap, nops);


    p->opr.op[0] = va_arg(ap, nodeType*);

    int opr_i = p->opr.op[0]->id.i;
    if (available[opr_i] == 1)
    {
        yyerror("Use of undeclared variable\n");
        exit(0);
    }

    int originalType = getVarTypeFromNode(p->opr.op[0]);

    for (i = 1; i < nops; i++)
    {
        p->opr.op[i] = va_arg(ap, nodeType*);
        int type = getVarTypeFromNode(p->opr.op[i]);
        if (type != originalType)
        {
            if (!((originalType == typeInt && type == typeChar) || (originalType == typeChar && type == typeInt))) // to account for char=int or int = char
            {
                yyerror("type mismatch\n");
                exit(0);
            }
        }
    }
    va_end(ap);

    int symi = p->opr.op[0]->id.i;
    if (oper == '=')
    {
        // the following prints are for the quadruples
        sym[symi]->initialized = 1;
        
        if (sym[symi]->type == typeInt)
        {
            if (p->opr.op[1]->type == typeCon)
            {
                sym[symi]->intValue = p->opr.op[1]->con.intValue;
                if(!temp)
                {
                    printf("=\t");
                    printf("\t\t%d",p->opr.op[1]->con.intValue);
                }
            }
            else
            {
                if (sym[p->opr.op[1]->id.i]->initialized == 0)
                {
                    yyerror("Variable used without being initialized");
                    exit(0);
                }
                sym[symi]->intValue = sym[p->opr.op[1]->id.i]->intValue;
                if(!temp)
                {
                    printf("=\t");
                    printf("\t\t%s",name[p->opr.op[1]->id.i]);
                }
            }
        }
        else if (sym[symi]->type == typeFloat)
        {
            if (p->opr.op[1]->type == typeCon)
            {
                sym[symi]->floatValue = p->opr.op[1]->con.floatValue;
                if(!temp)
                {
                    printf("=\t");
                    printf("\t\t%f",p->opr.op[1]->con.floatValue);
                }

            }
            else
            {
                if (sym[p->opr.op[1]->id.i]->initialized == 0)
                {
                    yyerror("Variable used without being initialized");
                    exit(0);
                }

                sym[symi]->floatValue = sym[p->opr.op[1]->id.i]->floatValue;
                if(!temp)
                {
                    printf("=\t");
                    printf("\t\t%s",name[p->opr.op[1]->id.i]);
                }
            }
        }
        else if (sym[symi]->type == typeString)
        {
            if (p->opr.op[1]->type == typeCon)
            {
                strcpy(sym[symi]->stringValue, p->opr.op[1]->con.stringValue);

                if(!temp)
                {
                    printf("=\t");
                    printf("\t\t%s",p->opr.op[1]->con.stringValue);
                }
            }
            else
            {
                if (sym[p->opr.op[1]->id.i]->initialized == 0)
                {
                    yyerror("Variable used without being initialized");
                    exit(0);
                }
                strcpy(sym[symi]->stringValue, sym[p->opr.op[1]->id.i]->stringValue);
                if(!temp)
                {
                    printf("=\t");
                    printf("\t\t%s",name[p->opr.op[1]->id.i]);
                }
            }
        }
        else
        {
            // char
            if (p->opr.op[1]->type == typeCon)
            {
                sym[symi]->intValue = p->opr.op[1]->con.intValue;
                if(!temp)
                {
                    printf("=\t");
                    printf("\t\t%c",(char)p->opr.op[1]->con.intValue);
                }
            }
            else{
                if (sym[p->opr.op[1]->id.i]->initialized == 0)
                {
                    yyerror("Variable used without being initialized");
                    exit(0);
                }
                sym[symi]->intValue = sym[p->opr.op[1]->id.i]->intValue;
                if(!temp)
                {
                    printf("=\t");
                    printf("\t\t%s",name[p->opr.op[1]->id.i]);
                }
            }
        }
    }
    if(!temp)
        printf("\t\t\t\t%s\n",name[symi]);
    temp=0; // reset the temp
    currentVariableFlag=0;

    // p->type = typeId;
    // p->id.i = symi;
    
    return p;
}

void freeNode(nodeType *p) {
    int i;

    if (!p) return;
    if (p->type == typeOpr) {
        for (i = 0; i < p->opr.nops; i++)
            freeNode(p->opr.op[i]);
    }
    free (p);
}

int getVarTypeFromNode(nodeType *n)
{
    if (n->type == typeCon)
    {
        return n->con.type;
    }
    else if (n->type == typeId)
    {
        return sym[n->id.i]->type;
    }
    else
    {
        // type operation
        int originalType = getVarTypeFromNode(n->opr.op[0]);
        return originalType;
    }
}





nodeType *oprNew(int oper, nodeType * nt1, nodeType *nt2) {
    
    temp=1;  // set temp for quadruples
    nodeType *p;
    int i;
    /* allocate node, extending op array */
    if ((p = malloc(sizeof(nodeType) )) == NULL)
        yyerror("out of memory");

    /* copy information */

    int type1;
    int type2;

    if (nt1 == NULL)
    {
        // type = nt2->
    }
    else if(nt1->type==typeId )
    {
        int opr_i = nt1->id.i;
        if (available[opr_i] == 1)
        {
            yyerror("Use of undeclared variable\n");
            exit(0);
        }
        else if (sym[opr_i]->initialized == 0)
        {
            yyerror("Variable used without being initialized");
            exit(0);
        }
        int i=nt1->id.i;
        type1=sym[i]->type;

    }
    else
    {
        type1=nt1->con.type;
    }

    if(nt2->type==typeId )
    {
        int opr_i = nt2->id.i;
        if (available[opr_i] == 1)
        {
            yyerror("Use of undeclared variable\n");
            exit(0);
        }
        else if (sym[opr_i]->initialized == 0)
        {
            yyerror("Variable used without being initialized");
            exit(0);
        }

        int i=nt2->id.i;
        type2=sym[i]->type;

    }
    else
    {
        type2=nt2->con.type;
    }

    if (nt1 == NULL)
    {
        type1 = type2;
    }
  
    if (type1!= type2)
    {
        yyerror("Type mismatch\n");
        exit(0);
        return p;
    }
    p->con.type = type1;
    p->type = typeCon;

    int integer1;
    float f1;
    char c1;
    char s1[50];
    int integer2;
    float f2;
    char c2;
    char s2[50];
    if(type1==0) // int value
    {
        if (nt1 == NULL) // Unary minus
        {
            integer1 = 0;
        }
        else if(nt1->type==typeId)
        {
            int i=nt1->id.i;
            integer1 = sym[i]->intValue;
        }
        else
        {
            integer1 = nt1->con.intValue;
        }

        if(nt2->type==typeId)
        {
            int i=nt2->id.i;
            integer2 = sym[i]->intValue;
        }
        else
        {
            integer2 = nt2->con.intValue;
        }
    }
    else if(type1==1) // float value
    {
        if (nt1 == NULL) // Unary minus
        {
            integer1 = 0.0;
        }
        if(nt1->type==typeId)
        {
            int i=nt1->id.i;
            f1=sym[i]->floatValue;
        }
        else
        {
            f1 = nt1->con.floatValue;
        }

        if(nt2->type==typeId)
        {
            int i=nt2->id.i;
            f2=sym[i]->floatValue;
        }
        else
        {
            f2 = nt2->con.floatValue;
        }
    }
    else if(type1==2)
    {
        if (nt1 == NULL)
        {
            yyerror("The negation operator can only be done to intgers and floats");
            exit(0);
        }
        if(nt1->type==typeId)
        {
            int i=nt1->id.i;
            // s1=sym[i]->stringValue;
            strcpy(s1, sym[i]->stringValue);
        }
        else
        {
            // s1 = nt1->con.stringValue;
            strcpy(s1, nt1->con.stringValue);
        }

        if(nt2->type==typeId)
        {
            int i=nt2->id.i;
            // s2=sym[i]->stringValue;
            strcpy(s2, sym[i]->stringValue);
        }
        else
        {
            // s2 = nt2->con.stringValue;
            strcpy(s2, nt2->con.stringValue);
        }
    }
    else
    {
        if (nt1 == NULL)
        {
            yyerror("The negation operator can only be done to intgers and floats");
            exit(0);
        }
        else if(nt1->type==typeId)
        {
            int i=nt1->id.i;
            c1=sym[i]->intValue;
        }
        else
        {
            c1 = nt1->con.intValue;
        }

        if(nt2->type==typeId)
        {
            int i=nt2->id.i;
            c2=sym[i]->intValue;
        }
        else
        {
            c2 = nt2->con.intValue;
        }
    }
    if (oper == '+')
    {
        switch(p->con.type)
        {
            case typeInt:
                    p->con.intValue = integer1 + integer2;
                    break;
            case typeFloat:
                    p->con.floatValue = f1 + f2;
                    break;
            case typeString:
                    {
                        strcpy(p->con.stringValue, s1);
                        strcat(p->con.stringValue, s2);
                        break;
                    }
                    
            case typeChar:
                    p->con.intValue = c1 + c2;
                    break;
        }
    }
    else if (oper == '-')
    {
        switch(p->con.type)
        {
            case typeInt:
                    p->con.intValue = integer1 - integer2;
                    break;
            case typeFloat:
                    p->con.floatValue = f1 - f2;
                    break;
            case typeString:
                    {
                        yyerror("This operator cannot be applied to strings\n");
                        exit(0);
                    }
            case typeChar:
                    p->con.intValue = c1 - c2;
                    break;
        }
    }
    else if (oper == '*')
    {
        switch(p->con.type)
        {
            case typeInt:
                    p->con.intValue = integer1 * integer2;
                    break;
            case typeFloat:
                    p->con.floatValue = f1 * f2;
                    break;
            case typeString:
                    {
                        yyerror("This operator cannot be applied to strings\n");
                        exit(0);
                    }
            case typeChar:
                    p->con.intValue = c1 * c2;
                    break;
        }
    }
    else if (oper == '/')
    {
        switch(p->con.type)
        {
            case typeInt:
                    p->con.intValue = integer1 / integer2;
                    break;
            case typeFloat:
                    p->con.floatValue = f1 / f2;
                    break;
            case typeString:
                    {
                        yyerror("This operator cannot be applied to strings\n");
                        exit(0);
                    }
            case typeChar:
                    p->con.intValue = c1 / c2;
                    break;
        }
    }
   
   
    // printing quadruples
    if (nt1 == NULL)
    {
        if (nt2->type == typeCon)
        {
            if (nt2->con.type == typeInt)
            {
                // int
                printf("%c\t\t\t%d\t\t\t\t%s\t\t\n", '-', nt2->con.intValue, currentVariable);
            }
            else if (nt2->con.type == typeFloat)
            {
                // float
                printf("%c\t\t\t%f\t\t\t\t%s\t\t\n", '-', nt2->con.floatValue, currentVariable);
            }
            else
            {
                yyerror("Negation can only be applied to integers and floats");
                exit(0);
            }
        }
        else
        {
            // id
            if (sym[nt2->id.i]->type == typeInt)
            {
                // int
                printf("%c\t\t\t%s\t\t\t\t%s\t\t\n", '-', name[nt2->id.i], currentVariable);
            }
            else if (sym[nt2->id.i]->type == typeFloat)
            {
                // float
                printf("%c\t\t\t%s\t\t\t\t%s\t\t\n", '-', name[nt2->id.i], currentVariable);
            }
            else
            {
                yyerror("Negation can only be applied to integers and floats");
                exit(0);
            }
        }
        
    }
    else if(nt1->type==typeId && nt2->type==typeId)
    {
        int i1=nt1->id.i;
        int i2=nt2->id.i;
        printf("%c\t\t\t%s\t\t%s\t\t%s\t\t\n",(char)oper,name[i1],name[i2],currentVariable);
    }
    else if(nt1->type==typeId && nt2->type==typeCon)
    {
        int i1=nt1->id.i;
        if(type2==0)
        {
            printf("%c\t\t\t%s\t\t%d\t\t%s\t\t\n",(char)oper,name[i1],integer2,currentVariable);
        }
        else if(type2==1)
        {
            printf("%c\t\t\t%s\t\t%f\t\t%s\t\t\n",(char)oper,name[i1],f2,currentVariable);
        }

        else if(type2==3)
        {
            printf("%c\t\t\t%s\t\t%c\t\t%s\t\t\n",(char)oper,name[i1],c2,currentVariable);
        }
        else
        {
            printf("%c\t\t\t%s\t\t%s\t\t%s\t\t\n",(char)oper,name[i1],s2,currentVariable);
        }
        
    }

    else if(nt1->type==typeCon && nt2->type==typeId)
    {
        int i2=nt2->id.i;
        if(type1==0)
        {
            printf("%c\t\t\t%d\t\t%s\t\t%s\t\t\n",(char)oper,integer1,name[i2],currentVariable);
        }
        else if(type1==1)
        {
            printf("%c\t\t\t%f\t\t%s\t\t%s\t\t\n",(char)oper,f1,name[i2],currentVariable);
        }

        else if(type1==3)
        {
            printf("%c\t\t\t%c\t\t%s\t\t%s\t\t\n",(char)oper,c1,name[i2],currentVariable);
        }
        else
        {
            printf("%c\t\t\t%s\t\t%s\t\t%s\t\t\n",(char)oper,s1,name[i2],currentVariable);
        }
    }
    else if(nt1->type==typeCon && nt2->type==typeCon)
    {
        if(type1==0)
        {
            printf("%c\t\t\t%d\t\t%d\t\t%s\t\t\n",(char)oper,integer1,integer2,currentVariable);
        }
        else if(type1==1)
        {
            printf("%c\t\t\t%f\t\t%f\t\t%s\t\t\n",(char)oper,f1,f2,currentVariable);
        }

        else if(type1==3)
        {
            printf("%c\t\t\t%c\t\t%c\t\t%s\t\t\n",(char)oper,c1,c2,currentVariable);
        }
        else
        {
            printf("%c\t\t\t%s\t\t%s\t\t%s\t\t\n",(char)oper,s1,s2,currentVariable);
        }
    }
    return p;
}


void printOpr(nodeType *n)
{
    if (n->type == typeCon)
    {
        if (n->con.type == typeInt)
        {
            printf("%d\n", n->con.intValue);
        }
        else if (n->con.type == typeFloat)
        {
            printf("%f\n", n->con.floatValue);
        }
        else if (n->con.type == typeString)
        {
            printf("%s\n", n->con.stringValue);
        }
        else
        {
            printf("%c\n", n->con.intValue);
        }
    }
    else if (n->type == typeId)
    {
        if (sym[n->id.i]->type == typeInt)
        {
            printf("%d\n", sym[n->id.i]->intValue);
        }
        else if (sym[n->id.i]->type == typeFloat)
        {
            printf("%f\n", sym[n->id.i]->floatValue);
        }
        else if (sym[n->id.i]->type == typeString)
        {
            printf("%s\n", sym[n->id.i]->stringValue);
        }
        else
        {
            printf("%c\n", sym[n->id.i]->intValue);
        }
    }
}




void yyerror(char *s) {
    fprintf(stdout, "%s\n", s);
}
int main(void) {
    
    //file 
    printf("This is the output quadruples: \n");

    printf("operator\t\top1\t\top2\t\tresult\n");
    
    
    //initialize available table with true;

    int i=0;
    globalIndex=0;
    for(i=0;i<100;i++)
    {
        available[i]=1;
    }

    yyparse();
    return 0;
}
