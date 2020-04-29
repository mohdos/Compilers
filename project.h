typedef enum { typeCon, typeId, typeOpr } nodeEnum;
typedef enum { typeInt, typeFloat,typeString,typeChar,NONE } conEnum;

/* constants */
typedef struct conNodeTypeStruct {
    conEnum type;  //None is used for variables that wasn't defined with a data type
    //char* name;
    int initialized;
    union{
        int intValue;
        float floatValue;
        char stringValue[100];
    };                 /* value of constant */
} conNodeType;


/* identifiers */
typedef struct {
    int i;                      /* subscript to sym array */
} idNodeType;

/* operators */
typedef struct {
    int oper;                   /* operator */
    int nops;                   /* number of operands */
    struct nodeTypeTag *op[1];	/* operands, extended at runtime */
} oprNodeType;

typedef struct nodeTypeTag {
    nodeEnum type;              /* type of node */

    union {
        
        idNodeType id;          /* identifiers */
        oprNodeType opr;        /* operators */
        conNodeType con;        /* constants */
    };
} nodeType;

extern conNodeType* sym[100];
extern int globalIndex;
extern char* name[100];
extern int available[100];
extern char currentVariable[100];
extern int currentVariableFlag;