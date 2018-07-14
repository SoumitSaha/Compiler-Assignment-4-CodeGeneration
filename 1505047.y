%{
#include<iostream>
#include<cstdlib>
#include<cstring>
#include <limits>
#include<stack>
#include<cmath>
#include <vector>
#include "SymTab.h"


using namespace std;

int yyparse(void);
int yylex(void);
extern FILE *yyin;

string lastVarType;
extern int line_count;
extern int err_count;
int semErrors;
int IDarguments = 0;
vector<string> argumentlist;
int warnings = 0;
int argset = 0;
int paraset = 0;
vector<string>asmdatavars;


void yyerror(const char *s){
}

ofstream logFile, errorFile;

SymbolTable table(15);
vector<SymbolInfo> parameters;

int labelCount=0;
int tempCount=0;

char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	return t;
}

#include "actionFuncs.h"


%}

%union { SymbolInfo* value; }
%token <value> IF
%token <value> ELSE
%token <value> FOR
%token <value> WHILE
%token <value> DO
%token <value> INT
%token <value> CHAR
%token <value> FLOAT
%token <value> DOUBLE
%token <value> VOID
%token <value> RETURN
%token <value> PRINTLN
%token <value> INCOP
%token <value> DECOP
%token <value> NOT
%token <value> LPAREN
%token <value> RPAREN
%token <value> LCURL
%token <value> RCURL
%token <value> LTHIRD
%token <value> RTHIRD
%token <value> COMMA
%token <value> SEMICOLON
%token <value> STRING
%token <value> COMMENT
%token <value> ASSIGNOP
%token <value> ADDOP
%token <value> LOGICOP
%token <value> MULOP
%token <value> RELOP
%token <value> ID
%token <value> CONST_INT
%token <value> CONST_FLOAT
%token <value> CONST_CHAR

%type <value>type_specifier expression logic_expression rel_expression simple_expression term unary_expression factor variable program unit var_declaration func_declaration func_definition parameter_list compound_statement statements declaration_list statement expression_statement argument_list arguments

%nonassoc second_precedence
%nonassoc ELSE
%error-verbose

%%

start : program				{	//writelog("start : program");			
			}
	;

program : program unit 		{	
				writelog("program : program unit");		
				
				logline();
				string str = "";
				str.append($1->Ccode);
				//str.append(" ");
				str.append($2->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();
			}
	| unit					{	
				writelog("program : unit");
				
				logline();
				string str = "";
				str.append($1->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();	
			}
	;
	
unit : var_declaration 		{	
				writelog("unit : var_declaration");
				
				logline();
				string str = "";
				str.append($1->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();	
			}
     | func_declaration 	{	
     			writelog("unit : func_declaration");
     			
     			logline();
     			string str = "";
				str.append($1->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();		
     		}
     | func_definition 		{	
     			writelog("unit : func_definition");		
     			
     			logline();
     			string str = "";
				str.append($1->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();
     		}
     ;
     
func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON 	{
				writelog("func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON");
				func_dec($1,$2);
				
				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Getsname());
				str.append($3->Getsname());
				if(paraset == 1){
					str.append($4->Ccode);
				}
				str.append($5->Getsname());
				str.append($6->Getsname());
				str.append("\n");
				printstr(str);
				$$->Ccode = str;
				logline();
			}
		|type_specifier ID LPAREN parameter_list RPAREN error 	{
				writeerr("expected ;");
				
				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Getsname());
				str.append($3->Getsname());
				if(paraset == 1){
					str.append($4->Ccode);
				}
				str.append($5->Getsname());
				str.append("\n");
				printstr(str);
				$$->Ccode = str;
				logline();
			}
		;
		 
func_definition : type_specifier ID LPAREN parameter_list RPAREN { 
				writelog("func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement");
				func_def($1,$2);
			} compound_statement{
				
				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Getsname());
				str.append($3->Getsname());
				if(paraset == 1){
					str.append($4->Ccode);
				}
				str.append($5->Getsname());
				str.append($7->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();
			}
 		;				


parameter_list  : parameter_list COMMA type_specifier ID 	{
				writelog("parameter_list  : parameter_list COMMA type_specifier ID");
				argumentlist.push_back(lastVarType);
				IDarguments++;
				$4->kindofID = "VAR";
				$4->kindofVariable = lastVarType;
				SymbolInfo* temp = makenewSymInfobyname($4->Getsname(), $4->Getstype());
				temp->kindofID = "VAR";
				parameters.push_back(*temp);
				paraset = 1;
				
				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Getsname());
				str.append($3->Ccode);
				str.append($4->Getsname());
				printstr(str);
				$$->Ccode = str;
				logline();
			}
		| parameter_list COMMA type_specifier 	{
				writelog("parameter_list  : parameter_list COMMA type_specifier");
				argumentlist.push_back($3->kindofVariable);
				paraset = 1;

				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Getsname());
				str.append($3->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();
			}
 		| type_specifier ID 	{
 				writelog("parameter_list  : type_specifier ID");
				argumentlist.push_back(lastVarType);
				IDarguments++;
				$2->kindofID = "VAR";
				$2->kindofVariable = lastVarType;
				parameters.push_back(*$2);
				paraset = 1;

				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Getsname());
				printstr(str);
				$$->Ccode = str;
				logline();
 			}
		| type_specifier	{
				writelog("parameter_list  : type_specifier.");
				argumentlist.push_back(lastVarType);
				paraset = 1;

				logline();
				string str = "";
				str.append($1->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();
			}
		| 	{	
				writelog("parameter_list  : empty");
				paraset = 0;

			}
 		;

 		
compound_statement : LCURL	{
				writelog("compound_statement : LCURL statements RCURL");
				table.EnterScope(logFile);
				//table.PrintAllinFile(logFile);
				for(int i = 0; i<parameters.size(); i++) {
					table.Insert(parameters[i].Getsname(), parameters[i].Getstype());
					SymbolInfo* temp = table.LookUp(parameters[i].Getsname());
					temp->kindofID = parameters[i].kindofID;
					temp->kindofVariable = parameters[i].kindofVariable;
				}
				parameters.clear();
				//logFile << "After Inserting Parameters " << endl;
				//table.PrintAllinFile(logFile);
			}	statements 	{	table.PrintAllinFile(logFile);	} 	RCURL		{	
				table.ExitScope(logFile);

				logline();
				string str = "";
				str.append("\n");
				str.append($1->Getsname());
				str.append("\n");
				str.append($3->Ccode);
				str.append($5->Getsname());
				str.append("\n");
				printstr(str);
				$$->Ccode = str;
				logline();
			}		
 		    | LCURL RCURL 	{	
 		    	writelog("compound_statement : LCURL RCURL");

 		    	logline();
 		    	string str = "";
 		    	str.append($1->Getsname());
				str.append(" ");
				str.append($2->Getsname());
				printstr(str);
				$$->Ccode = str;
 		    	logline();
 		    }
 		    ;
 		    
var_declaration : type_specifier declaration_list SEMICOLON		{	
				writelog("var_declaration : type_specifier declaration_list SEMICOLON");

				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Ccode);
				str.append($3->Getsname());
				str.append("\n");
				printstr(str);
				$$->Ccode = str;
				logline();
			}
		| type_specifier declaration_list error 				{	
				writeerr("expected ;");

				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Ccode);
				str.append("\n");
				printstr(str);
				$$->Ccode = str;
				logline();	
			}
 		;
 		 
type_specifier	: INT{
				writelog("type_specifier : INT");
				SymbolInfo* s= makenewSymInfo("INT");
				lastVarType = "INT";
				$$ = s;

				logline();
				string str = "";
				str.append($1->Getsname());
				str.append(" ");
				printstr(str);
				$$->Ccode = str;
				logline();
			}
 		| FLOAT{
 				writelog("type_specifier : FLOAT");
				SymbolInfo* s= makenewSymInfo("FLOAT");
				lastVarType = "FLOAT";
				$$ = s;

				logline();
				string str = "";
				str.append($1->Getsname());
				str.append(" ");
				printstr(str);
				$$->Ccode = str;
				logline();
 			}
 		| VOID{
 				writelog("type_specifier : VOID");
				SymbolInfo* s= makenewSymInfo("VOID");
				lastVarType = "VOID";
				$$ = s;

				logline();
				string str = "";
				str.append($1->Getsname());
				str.append(" ");
				printstr(str);
				$$->Ccode = str;
				logline();
 			}
 		;
 		
declaration_list : declaration_list COMMA ID 	{
				writelog("declaration_list : 	declaration_list COMMA ID");
				declistcomid($3);

				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Getsname());
				str.append($3->Getsname());
				printstr(str);
				$$->Ccode = str;
				logline();
			}
 		| declaration_list COMMA ID LTHIRD CONST_INT RTHIRD		{
 				writelog("declaration_list : 	declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
				declistarr($3,$5);

				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Getsname());
				str.append($3->Getsname());
				str.append($4->Getsname());
				str.append($5->Getsname());
				str.append($6->Getsname());
				printstr(str);
				$$->Ccode = str;
				logline();
 			}
 		| ID 	{
 				writelog("declaration_list : ID");
				onlyid($1);

				logline();
				string str = "";
				str.append($1->Getsname());
				str.append(" ");
				printstr(str);
				$$->Ccode = str;
				logline();
 			}
 		| ID LTHIRD CONST_INT RTHIRD	{
 				writelog("declaration_list :	ID LTHIRD CONST_INT RTHIRD");
				onlyarray($1,$3);

				logline();
				string str = "";
				str.append($1->Getsname());
				str.append($2->Getsname());
				str.append($3->Getsname());
				str.append($4->Getsname());
				str.append(" ");
				printstr(str);
				$$->Ccode = str;
				logline();	
 			}
 		;
 		  
statements : statement 				{	
				writelog("statements : statement");

				logline();
				string str = "";
				str.append($1->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();
			}
	   | statements statement 		{	
	   			writelog("statements : statements statement");

	   			logline();
				string str = "";
	   			str.append($1->Ccode);
				str.append($2->Ccode);
				printstr(str);
				$$->Ccode = str;
	   			logline();	
	   		}
	   ;
	   
statement : var_declaration 	{	
				writelog("statement : var_declaration");	

				logline();
				string str = "";
				str.append($1->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();
			}
	  | expression_statement	{	
	  			writelog("statement : expression_statement");	

	  			logline();
				string str = "";
	  			str.append($1->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();	
	  		}
	  | compound_statement		{	
	  			writelog("statement : compound_statement");	

	  			logline();
				string str = "";
	  			str.append($1->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();	
	  		}
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement 	{	
	  			writelog("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement");

	  			logline();
				string str = "";
	  			str.append($1->Getsname());
				str.append($2->Getsname());
				str.append($3->Ccode);
				str.append(" ");
				str.append($4->Ccode);
				str.append(" ");
				str.append($5->Ccode);
				str.append($6->Getsname());
				str.append($7->Ccode);
				printstr(str);
				$$->Ccode = str;
				logline();

				
	  		}
	  | IF LPAREN expression RPAREN statement %prec second_precedence	{	
	  			writelog("statement : IF LPAREN expression RPAREN statement");	

	  			logline();
				string str = "";
	  			str.append($1->Getsname());
				str.append($2->Getsname());
				str.append($3->Getsname());
				str.append($4->Getsname());
				str.append($5->Getsname());
				printstr(str);
				$$->Setsname(str);
	  			logline();
	  		}
	  | IF LPAREN expression RPAREN statement ELSE statement 	{	
	  			writelog("statement : IF LPAREN expression RPAREN statement ELSE statement");

	  			logline();
				string str = "";
	  			str.append($1->Getsname());
				str.append($2->Getsname());
				str.append($3->Ccode);
				str.append($4->Getsname());
				str.append($5->Ccode);
				//str.append(" ");
				str.append($6->Getsname());
				str.append(" ");
				str.append($7->Ccode);
				printstr(str);
				$$->Ccode = str;
	  			logline();	
	  		}
	  | WHILE LPAREN expression RPAREN statement 	{	
	  			writelog("statement : WHILE LPAREN expression RPAREN statement");

	  			logline();
				string str = "";
	  			str.append($1->Getsname());
				str.append($2->Getsname());
				str.append($3->Ccode);
				str.append($4->Getsname());
				str.append($5->Ccode);
				printstr(str);
				$$->Ccode = str;
	  			logline();
	  		}
	  | PRINTLN LPAREN ID RPAREN SEMICOLON 		{	
	  			writelog("statement : PRINTLN LPAREN ID RPAREN SEMICOLON");

	  			logline();
				string str = "";
	  			str.append($1->Getsname());
				str.append($2->Getsname());
				str.append($3->Getsname());
				str.append($4->Getsname());
				str.append($5->Getsname());
				str.append("\n");
	  			printstr(str);
				$$->Ccode = str;
	  			logline();
	  		}
	  |	PRINTLN LPAREN ID RPAREN error 	{	
	  			writeerr("expected ;");

	  			logline();
				string str = "";
	  			str.append($1->Getsname());
				str.append(" ");
				str.append($2->Getsname());
				str.append(" ");
				str.append($3->Getsname());
				str.append(" ");
				str.append($4->Getsname());
				str.append("\n");
				printstr(str);
				$$->Ccode = str;
	  			logline();
	  		}
	  | RETURN expression SEMICOLON 	{	
	  			writelog("statement : RETURN expression SEMICOLON");

	  			logline();
				string str = "";
	  			str.append($1->Getsname());
				str.append(" ");
				str.append($2->Ccode);
				str.append(" ");
				str.append($3->Getsname());
	  			str.append("\n");
				printstr(str);
				$$->Ccode = str;
	  			logline();
	  		}
	  |	RETURN expression error 		{	
	  			writeerr("expected ;");

	  			logline();
				string str = "";
	  			str.append($1->Getsname());
				str.append(" ");
				str.append($2->Ccode);
	  			str.append("\n");
				printstr(str);
				$$->Ccode = str;
	  			logline();	
	  		}
	  ;
	  
expression_statement : SEMICOLON		{	
				writelog("expression_statement : SEMICOLON");

				logline();
				string str = "";
				str.append($1->Getsname());
				str.append("\n");
				printstr(str);
				$$->Ccode = str;
				logline();
			}
			| expression SEMICOLON 		{	
				writelog("expression_statement : expression SEMICOLON");

				logline();
				string str = "";
				str.append($1->Ccode);
				str.append($2->Getsname());
				str.append("\n");
				printstr(str);
				$$->Ccode = str;
				logline();
			}
			| expression error 			{	
				writeerr("expected ;");

				logline();
				string str = "";
				str.append($1->Ccode);
				str.append("\n");
				printstr(str);
				$$->Ccode = str;
				logline();
			}
			;
	  
variable : ID 	{
			writelog("variable : ID");
			SymbolInfo* temp = variabletoid($$,$1);
			if (temp != 0){
				$$ = temp;
			}

			logline();
			string str = "";
			str.append($1->Getsname());
			//str.append(" ");
			printstr(str);
			$$->Ccode = str;
			logline();

			if($$ != 0){
				$$->Setsname($$->Getsname() + to_string($$->tabid));
	 		}

		}	
	 | ID LTHIRD expression RTHIRD {
	 		writelog("variable : ID LTHIRD expression RTHIRD");
			SymbolInfo* temp = variabletoarray($$,$1,$3);
			if (temp != 0){
				$$ = temp;
			}

			logline();
			string str = "";
			str.append($1->Getsname());
			str.append($2->Getsname());
			str.append($3->Ccode);
			str.append($4->Getsname());
			str.append(" ");
			printstr(str);
			$$->Ccode = str;
			logline();

			if($$ != 0){
				$$->Setsname($$->Getsname() + to_string($$->tabid));
				$$->code = $3->code;
				$$->code.append("mov bx, ");
				$$->code.append($3->Getsname());
				$$->code.append("\n");
				$$->code.append("add bx, bx");
				$$->code.append("\n");
				$$->kindofID = "ARR";
	 		}
	 	}
	 ;
	 
expression : logic_expression	{
			writelog("expression : logic_expression");
			$$ = $1;

			logline();
			string str = "";
			str.append($1->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();
		}
	   	| variable ASSIGNOP logic_expression 	{
			writelog("expression : variable ASSIGNOP logic_expression");	
			SymbolInfo* temp = varassignlogic($$,$1,$3);
			if (temp != 0){
				$$ = temp;
			}

			logline();
			string str = "";
			str.append($1->Ccode);
			str.append($2->Getsname());
			str.append($3->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();

			$$->code = $3->code;
			$$->Setsname($1->Getsname());
			$$->code.append($1->code);
			$$->code.append("mov ax, ");
			$$->code.append($3->Getsname());
			$$->code.append("\n");
			if($$->kindofID == "ARR"){
				$$->code.append("mov " + $1->Getsname() + "[bx], ax\n");
			}
			else{
				$$->code.append("mov " + $1->Getsname() + ", ax\n");
			}
		}
	   ;
			
logic_expression : rel_expression 	{
			writelog("logic_expression : rel_expression");
			$$ = $1;

			logline();
			string str = "";
			str.append($1->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();
		}
		| rel_expression LOGICOP rel_expression 	{
			writelog("logic_expression : rel_expression LOGICOP rel_expression");
			SymbolInfo* temp1 = rellogicrel($$,$1,$2,$3);
			if (temp1 != 0){
				$$ = temp1;
			}

			logline();
			string str = "";
			str.append($1->Ccode);
			str.append($2->Getsname());
			str.append($3->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();

			//$$->Setsname($1->Getsname());
			$$->code = $1->code;
			$$->code.append($3->code);
			char *label1 = newLabel();
			char *label2 = newLabel();
			char *temp = newTemp();
			if($2->Getsname() == "&&"){
				$$->code.append("mov ax, " + $1->Getsname() + "\n");
				$$->code.append("cmp ax, 0\n");
				$$->code.append("je " + string(label1) + "\n");
				$$->code.append("mov ax, " + $3->Getsname() + "\n");
				$$->code.append("cmp ax, 0\n");
				$$->code.append("je " + string(label1) + "\n");
				$$->code.append("mov " + string(temp) + " , 1\n");
				$$->code.append("jmp " + string(label2) + "\n");
				$$->code.append(string(label1) + ":\n") ;
				$$->code.append("mov " + string(temp) + ", 0\n");
				$$->code.append(string(label2) + ":\n");
				$$->Setsname(temp);
			}
			else if($2->Getsname()=="||"){
				$$->code.append("mov ax , " + $1->Getsname() +"\n");
				$$->code.append("cmp ax , 0\n");
		 		$$->code.append("jne " + string(label1) +"\n");
				$$->code.append("mov ax , " + $3->Getsname() +"\n");
				$$->code.append("cmp ax , 0\n");
				$$->code.append("jne " + string(label1) +"\n");
				$$->code.append("mov " + string(temp) + " , 0\n");
				$$->code.append("jmp " + string(label2) + "\n");
				$$->code.append(string(label1) + ":\n" );
				$$->code.append("mov " + string(temp) + ", 1\n");
				$$->code.append(string(label2) + ":\n");
				$$->Setsname(temp);	
			}
		}
		;
			
rel_expression	: simple_expression 	{
			writelog("rel_expression : simple_expression");
			$$ = $1;

			logline();
			string str = "";
			str.append($1->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();
		}
		| simple_expression RELOP simple_expression		{
			writelog("rel_expression : simple_expression RELOP simple_expression");
			SymbolInfo* temp = simprelopsimp($$,$1,$2,$3);
			if (temp != 0){
				$$ = temp;
			}

			logline();
			string str = "";
			str.append($1->Ccode);
			str.append($2->Getsname());
			str.append($3->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();

			//$$ = $1;
			$$->Setsname($1->Getsname());
			$$->code = $1->code;
			$$->code.append($3->code);
			$$->code.append("mov ax, " + $1->Getsname()+"\n");
			$$->code.append("cmp ax, " + $3->Getsname()+"\n");
			char *temp1=newTemp();
			char *label1=newLabel();
			char *label2=newLabel();
			if($2->Getsname()=="<"){
				$$->code.append("jl " + string(label1)+"\n");
			}
			else if($2->Getsname()=="<="){
				$$->code.append("jle " + string(label1)+"\n");
			}
			else if($2->Getsname()==">"){
				$$->code.append("jg " + string(label1)+"\n");
			}
			else if($2->Getsname()==">="){
				$$->code.append("jge " + string(label1)+"\n");
			}
			else if($2->Getsname()=="=="){
				$$->code.append("je " + string(label1)+"\n");
			}
			else if($2->Getsname()=="!="){
				$$->code.append("jne " + string(label1)+"\n");
			}
			$$->code.append("mov "+string(temp1) +", 0\n");
			$$->code.append("jmp "+string(label2) +"\n");
			$$->code.append(string(label1)+":\n");
			$$->code.append("mov "+string(temp1)+", 1\n");
			$$->code.append(string(label2)+":\n");
			$$->Setsname(string(temp1));
			asmdatavars.push_back(string(temp1));
		}
		;
				
simple_expression : term {
			writelog("simple_expression : term");
			$$ = $1;

			logline();
			string str = "";
			str.append($1->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();
		}
		| simple_expression ADDOP term  {
			writelog("simple_expression : simple_expression ADDOP term");
			SymbolInfo* temp = simexpaddopterm($$,$1,$2,$3);
     		if (temp != 0){
				$$ = temp;
			}

			logline();
			string str = "";
			str.append($1->Ccode);
			str.append($2->Getsname());
			str.append($3->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();

			//$$ = $1;
			$$->Setsname($1->Getsname());
			$$->code = $1->code;
			$$->code.append($3->code);
			if($2->Getsname()=="+"){
				char* temp = newTemp();
				asmdatavars.push_back(string(temp));
				$$->code.append("mov ax, " + $1->Getsname() + "\n");
				$$->code.append("add ax, " + $3->Getsname() + "\n");
				$$->code.append("mov " + string(temp) +" , ax\n");
				$$->Setsname(string(temp));
			}
			else if($2->Getsname() == "-"){
				char* temp = newTemp();
				asmdatavars.push_back(string(temp));
				$$->code.append("mov ax, " + $1->Getsname() + "\n");
				$$->code.append("sub ax, " + $3->Getsname() + "\n");
				$$->code.append("mov " + string(temp) +" , ax\n");
				$$->Setsname(string(temp));
			}
		}
		;
					
term :	unary_expression 	{
			writelog("term : unary_expression");
			$$ = $1;

			logline();
			string str = "";
			str.append($1->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();
		}
     	| term MULOP unary_expression 	{
     		writelog("term : term MULOP unary_expression");
     		SymbolInfo* temp2 = termmulopunary($$,$1,$2,$3);
     		if (temp2 != 0){
				$$ = temp2;
			}

			logline();
			string str = "";
			str.append($1->Ccode);
			str.append($2->Getsname());
			str.append($3->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();

			//$$ = $1;
			$$->code = $1->code;
			$$->Setsname($1->Getsname());
			$$->code.append($3->code);
			$$->code.append("mov ax, "+ $1->Getsname()+"\n");
			$$->code.append("mov bx, "+ $3->Getsname() +"\n");
			char *temp=newTemp();
			asmdatavars.push_back(string(temp));
			if($2->Getsname()=="*"){
				$$->code.append("mul bx\n");
				$$->code.append("mov "+ string(temp) + ", ax\n");
				$$->Setsname(string(temp));
			}
			else if($2->Getsname()=="/"){
				$$->code.append("xor dx , dx\n");
				$$->code.append("div bx\n");
				$$->code.append("mov " + string(temp) + " , ax\n");
				$$->Setsname(string(temp));
			}
			else{
				$$->code.append("xor dx , dx\n");
				$$->code.append("div bx\n");
				$$->code.append("mov " + string(temp) + " , dx\n");
			}
			
     	}
     ;

unary_expression : ADDOP unary_expression  {
			writelog("unary_expression : ADDOP unary_expression");
			SymbolInfo* temp2 = addopuna($$,$1,$2);
     		if (temp2 != 0){
				$$ = temp2;
			}

			logline();
			string str = "";
			str.append($1->Getsname());
			str.append($2->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();

			if($1->Getsname() == "+") {
				//$$ = $2;
				$$->Setsname($2->Getsname());
				$$->code = $2->code;
			}
			else if($1->Getsname() == "-"){
				$$->Setsname($2->Getsname());
				$$->code = $2->code;
				$$->code.append("mov ax, " + $2->Getsname() + "\n");
				$$->code.append("neg ax\n");
				$$->code.append("mov " + $2->Getsname() + " , ax\n");
			}
		}
		| NOT unary_expression 	{
			writelog("unary_expression : NOT unary_expression");
			SymbolInfo* temp2 = notuna($$,$2);
     		if (temp2 != 0){
				$$ = temp2;
			}

			logline();
			string str = "";
			str.append($1->Getsname());
			str.append($2->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();

			//$$ = $2;
			$$->Setsname($2->Getsname());
			$$->code = $2->code;
			char *temp=newTemp();
			asmdatavars.push_back(string(temp));
			$$->code.append("mov ax, " + $2->Getsname() + "\n");
			$$->code.append("not ax\n");
			$$->code.append("mov "+string(temp)+", ax");
		} 
		| factor 	{
			writelog("unary_expression : factor");
			$$ = $1;

			logline();
			string str = "";
			str.append($1->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();
		}
		;
	
factor	: variable 	{	
			writelog("factor : variable");

			logline();
			string str = "";
			str.append($1->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();

			$$ = $1;
			$$->code = $1->code;
			if($1->kindofID == "ARR"){
				char *temp= newTemp();
				asmdatavars.push_back(string(temp));
				$$->code.append("mov ax, " + $1->Getsname() + "[bx]\n");
				$$->code.append("mov " + string(temp) + ", ax\n");
				$$->Setsname(string(temp));
			}
		}
	| ID LPAREN argument_list RPAREN {
			writelog("factor : ID LPAREN argument_list RPAREN");
			SymbolInfo *temp = makenewemptySymInfo();
			temp = table.LookUp($1->Getsname());
			if(temp == NULL){
				string str = "";
				str.append("Undeclared Function : ");
				str.append($1->Getsname());
				writeerr(str);
			}
			else if(temp->kindofID != "FUNC"){
				string str = "";
				str.append($1->Getsname());
				str.append(" is not a function");
				writeerr(str);
			}
			else if(temp->parameters.size() != IDarguments){
				string str = "";
				str.append($1->Getsname());
				str.append(" has inappropiate number of arguments");
				writeerr(str);
				argumentlist.clear();
				IDarguments = 0;
			}
			else{
				for(int i = 0; i<argumentlist.size(); i++){
					if(temp->parameters[i] != argumentlist[i]){
						string str = "";
						str.append($1->Getsname());
						str.append(" has inappropiate type in arguments");
						writeerr(str);
						break;
					}
				}
				argumentlist.clear();
				IDarguments = 0;
				if(temp->funcrettype == "VOID"){
					string str = "";
					str.append($1->Getsname());
					str.append(" returns void.");
					writeerr(str);
				}
				else{
					SymbolInfo *temp2 = makenewSymInfo($1->funcrettype);
					$$ = temp2;
				}
			}

			logline();
			string str = "";
			str.append($1->Getsname());
			str.append($2->Getsname());
			if(argset == 1){
				str.append($3->Ccode);
			}
			str.append($4->Getsname());
			printstr(str);
			$$->Ccode = str;
			logline();
		}	
	| LPAREN expression RPAREN 		{	
			writelog("factor : LPAREN expression RPAREN"); 
			$$=$2;

			logline();
			string str = "";
			str.append($1->Getsname());
			str.append($2->Ccode);
			str.append($3->Getsname());
			printstr(str);
			$$->Ccode = str;
			logline();
		}
	| CONST_INT  	{	
			writelog("factor : CONST_INT");
			$1->kindofVariable = "INT";
			$1->kindofID = "VAR";
			$$ = $1;	

			logline();
			string str = "";
			str.append($1->Getsname());
			//str.append(" ");
			printstr(str);
			$$->Ccode = str;
			logline();
		}
	| CONST_FLOAT	{	
			writelog("factor : CONST_FLOAT");
			$1->kindofVariable = "FLOAT";
			$1->kindofID = "VAR";
			$$ = $1;

			logline();
			string str = "";
			str.append($1->Getsname());
			//str.append(" ");
			printstr(str);
			$$->Ccode = str;
			logline();
		}
	| variable INCOP {
			writelog("factor : variable INCOP");
			SymbolInfo * temp = varinc($1);
			if(temp != 0) $$ = $1;

			logline();
			string str = "";
			str.append($1->Ccode);
			str.append($2->Getsname());
			printstr(str);
			$$->Ccode = str;
			logline();

			$$ = $1;
			$$->code.append("mov ax, ");	// mov ax, variable_tabid
			$$->code.append($1->Getsname());
			//$$->code.append($1->tabid);
			$$->code.append("\n");

			$$->code.append("add ax, 1\n"); // add ax, 1

			$$->code.append("mov "); //mov variable_tabid, ax
			$$->code.append($1->Getsname());
			//$$->code.append($1->tabid);
			$$->code.append(" , ax\n");
		}
	| variable DECOP {
			writelog("factor : variable DECOP");
			SymbolInfo * temp = vardec($1);
			if(temp != 0) $$ = $1;

			logline();
			string str = "";
			str.append($1->Ccode);
			str.append($2->Getsname());
			printstr(str);
			$$->Ccode = str;
			logline();

			$$ = $1;
			$$->code.append("mov ax, ");	// mov ax, variable_tabid
			$$->code.append($1->Getsname());
			//$$->code.append($1->tabid);
			$$->code.append("\n");

			$$->code.append("sub ax, 1\n"); // sub ax, 1

			$$->code.append("mov "); //mov variable_tabid, ax
			$$->code.append($1->Getsname());
			//$$->code.append($1->tabid);
			$$->code.append(" , ax\n");
		}
	;
	
argument_list : arguments 	{	
			writelog("argument_list : arguments");

			logline();
			string str = "";
			str.append($1->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();
		}
			  |	{	
			writelog("argument_list : empty");
			argset = 0;
		}
			  ;
	
arguments : arguments COMMA logic_expression	{	
			writelog("arguments : arguments COMMA logic_expression");
			argumentlist.push_back($3->kindofVariable);
			IDarguments++;
			argset = 1;

			logline();
			string str = "";
			str.append($1->Ccode);
			str.append($2->Getsname());
			str.append($3->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();
		}
	      | logic_expression 	{	
	      	writelog("arguments : logic_expression");
	      	argumentlist.push_back($1->kindofVariable);
			IDarguments++;
			argset = 1;

	      	logline();
			string str = "";
	      	str.append($1->Ccode);
			printstr(str);
			$$->Ccode = str;
			logline();
	    }
	      ;
 

%%
int main(int argc,char *argv[])
{

	if((yyin=fopen(argv[1],"r"))==NULL)
	{
		printf("Cannot Open Input File.\n");
		exit(1);
	}

	logFile.open("1505047_log.txt");
	errorFile.open("1505047_err.txt");
	yyparse();
	errorFile << "Total Lexical Errors 	: " << err_count << endl;
	errorFile << "Total Semantic Errors 	: " << semErrors << endl;
	errorFile << "Total Warnings 	: " << warnings << endl;

	logFile << "\t\tSymbol Table :" << endl;
	table.PrintAllinFile(logFile);

	logFile << "Total line 	: " << line_count << endl;
	logFile << "Total Lexical Errors 	: " << err_count << endl;
	logFile << "Total Semantic Errors 	: " << semErrors << endl;
	logFile << "Total Warnings 	: " << warnings << endl;

	logFile.close();
	errorFile.close();
	return 0;
}