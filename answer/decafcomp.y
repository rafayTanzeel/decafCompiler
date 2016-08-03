%{
#include <iostream>
#include <ostream>
#include <string>
#include <cstdlib>
#include "decafcomp-defs.h"
#include <list>
int yylex(void);
int yyerror(char *);
string bufferedType;

// print AST?
bool printAST = false;

using namespace std;

map<string, bool> checker;

static llvm::Module *TheModule;

static llvm::IRBuilder<> Builder(llvm::getGlobalContext());

static llvm::Function *TheFunction = NULL;


llvm::Function *genPrintIntDef() {
  // create a extern definition for print_int
  std::vector<llvm::Type*> args;
  args.push_back(Builder.getInt32Ty()); // print_int takes one i32 argument
  return llvm::Function::Create(llvm::FunctionType::get(Builder.getVoidTy(), args, false), llvm::Function::ExternalLinkage, "print_int", TheModule);
}

llvm::Function *genPrintStringDef() {
  // create a extern definition for print_string
  std::vector<llvm::Type*> args;
  args.push_back(Builder.getInt8PtrTy()); // print_string takes one string argument
  return llvm::Function::Create(llvm::FunctionType::get(Builder.getVoidTy(), args, false), llvm::Function::ExternalLinkage, "print_string", TheModule);
}

llvm::Function *genReadIntDef() {
  // create a extern definition for print_string
  std::vector<llvm::Type*> args;
  //args.push_back(Builder.getVoidTy());
  return llvm::Function::Create(llvm::FunctionType::get(Builder.getInt32Ty(), args, false), llvm::Function::ExternalLinkage, "read_int", TheModule);
}



symbol_table_list* symtbl;

extern int lineno;

descriptor* access_symtbl(string ident) {
	descriptor* find_ident=NULL;
	for (symbol_table_list::iterator i = symtbl->begin(); i != symtbl->end(); ++i) {
		if (i->find(ident) != i->end()) find_ident = i->find(ident)->second;
	}
	return find_ident;
}


#include "decafcomp.cc"



%}

%union{
    class decafAST *ast;
    class ExpressionAST *east;
    std::string *idval;
    std::string *sval;
    std::string *typeval;
    int ival;
 }

%token T_FUNC
%token T_RETURN
%token <typeval> T_INTTYPE
%token <typeval> T_STRINGTYPE
%token T_VAR
%token <typeval> T_VOID
%token T_NULL
%token T_PACKAGE
%token T_CONTINUE
%token T_BREAK
%token T_FOR
%token T_WHILE
%token <typeval> T_BOOLTYPE
%token <ival> T_FALSE
%token <ival> T_TRUE
%token T_EXTERN
%token T_IF
%token T_ELSE
%token <ival> T_CHARCONSTANT
%token <ival> T_INTCONSTANT
%token <sval> T_STRINGCONSTANT
%token T_LSB
%token T_RSB
%token T_LCB
%token T_RCB
%token T_LPAREN
%token T_RPAREN
%token T_EQ
%token T_ASSIGN
%token T_NEQ
%token T_NOT
%token T_AND
%token T_OR
%token T_COMMA
%token T_GEQ
%token T_RIGHTSHIFT
%token T_GT
%token T_LEQ
%token T_LEFTSHIFT
%token T_LT
%token T_DIV
%token T_PLUS
%token T_MINUS
%token T_MULT
%token T_MOD
%token T_SEMICOLON
%token T_DOT
%token <idval> T_ID

%type <ast> extern_list extern_def extern_type comma_sep_extern_types extern_types_func decafpackage field_decls field_decl method_arg method_list_arg method_decls method_decl main_method_decl comma_sep_id_type comma_sep_method_arg idtypes_func_args var_decls var_decl block statements statement method_call method_block  assign break_statement continue_statement while_statement Lvalue for_statement init post return_statement if_statement
%type <sval> extra_id_comma id_queried  method_type type
%type <east> expr exprConstant check rtrop rtropin rvalue

%nonassoc "if_then"
%nonassoc T_ELSE

%left T_OR
%left T_AND
%left T_EQ T_NEQ T_LT T_LEQ T_GT T_GEQ
%left T_PLUS T_MINUS
%left T_MULT T_DIV T_MOD T_LEFTSHIFT T_RIGHTSHIFT
%left UnaryNot
%right UnaryMinus


%%

start: program

program: extern_list decafpackage
    { 
        ProgramAST *prog = new ProgramAST((decafStmtList *)$1, (PackageAST *)$2); 
		if (printAST) {
			cout << getString(prog) << endl;
		}
        try {
            prog->Codegen();
        } 
        catch (std::runtime_error &e) {
            cout << "semantic error: " << e.what() << endl;
            //cout << prog->str() << endl; 
            exit(EXIT_FAILURE);
        }
        delete prog;
    }


decafpackage: T_PACKAGE T_ID begin_block field_decls method_decls end_block
    { $$ = new PackageAST(*$2, (decafStmtList *)$4, (decafStmtList *)$5); delete $2; }
   // | error {throw runtime_error("no package definition in decaf program");}

extern_list: extern_def extern_list { 
		decafStmtList *slist = new decafStmtList(); slist->push_back($1); if($2!=NULL) slist->push_back($2); $$ = slist;} 
	   | { $$ = NULL;}
    ;


extern_def: T_EXTERN T_FUNC T_ID T_LPAREN extern_types_func T_RPAREN method_type T_SEMICOLON { 


		$$=new ExternFuncAST(*$3,*$7,(decafStmtList*)$5); 
		
		//$$->Codegen();

		delete $3; delete $7;


}
    ;


extern_types_func: {$$=new decafStmtList();} | comma_sep_extern_types
    ;


comma_sep_extern_types: extern_type T_COMMA comma_sep_extern_types {decafStmtList *slist = new decafStmtList(); slist->push_back($1); slist->push_back($3); $$=slist;}
                      | extern_type {decafStmtList *slist = new decafStmtList(); slist->push_back($1); $$=slist;}

	
extern_type: T_STRINGTYPE {$$=new ExternType("StringType");} | type {$$=new ExternType(*$1); delete $1;}

method_type: T_VOID {$$=new string("VoidType");} | type

type: T_INTTYPE {$$=new string("IntType");} | T_BOOLTYPE {$$=new string("BoolType");} 

extra_id_comma : extra_id_comma T_COMMA T_ID { $$=new string(*$1+','+*$3);} | T_COMMA T_ID { $$=new string(','+*$2);}

id_queried: {$$=new string("");} | extra_id_comma


//Field Declaration
field_decls: {$$ = NULL;} | field_decls field_decl { 


decafStmtList *slist = new decafStmtList(); if($1!=NULL) slist->push_back($1); slist->push_back($2); $$ = slist;}


field_decl: T_VAR T_ID T_LSB T_INTCONSTANT T_RSB type T_SEMICOLON {


stringstream ss; ss<<"Array("<<$4<<")"; 


$$ = (decafAST*) new FieldDeclAST("FieldDecl", *$2, *$6, ss.str(), $4);
//symtbl->back()[*$2]->setAddress($$->Codegen());

}


| T_VAR T_ID T_COMMA T_ID id_queried T_LSB T_INTCONSTANT T_RSB type T_SEMICOLON {


stringstream ss; ss<<"Array("<<$7<<")"; 

string token;
stringstream sName(*$2+','+*$4+*$5);
decafStmtList *slist = new decafStmtList();
while (getline(sName, token, ',')) {
	slist->push_back(new FieldDeclAST("FieldDecl", token, *$9, ss.str(), $7));
}

$$ = slist;


}


| T_VAR T_ID type T_SEMICOLON {


$$ = (decafAST*)new FieldDeclAST("FieldDecl", *$2, *$3, "Scalar", 0);


}



| T_VAR T_ID T_COMMA T_ID id_queried type T_SEMICOLON {

string token;
stringstream sName(*$2+','+*$4+*$5);
decafStmtList *slist = new decafStmtList();
while (getline(sName, token, ',')) {
	slist->push_back(new FieldDeclAST("FieldDecl", token, *$6, "Scalar", 0));
}

$$ = slist;

}
	  

| T_VAR T_ID type T_ASSIGN expr T_SEMICOLON {


$$ = (decafAST*)new FieldDeclAST("AssignGlobalVar", *$2, *$3, $5->str(), 0, $5->getResult());


}





idtypes_func_args: {$$=new decafStmtList();} | comma_sep_id_type
    ;


comma_sep_id_type: T_ID type T_COMMA comma_sep_id_type {
	
	decafStmtList *slist =((decafStmtList*)$4);
	slist->push_front(new TypedSymbol(*$1, *$2, false)); 
	

	$$=$4;
	
	delete $1; delete $2;

}
         | T_ID type {

	decafStmtList *slist = new decafStmtList();
	slist->push_front(new TypedSymbol(*$1, *$2, false));
	
	$$=slist; 

	delete $1;  delete $2;

}







//Method Declaration
method_decls: main_method_decl { if(TheMainFunction==NULL) throw runtime_error("main method not found"); if(mainValidity) ((decafStmtList*)$1)->push_back(TheMainFunction); mainValidity=false; $$=$1;}

main_method_decl : {$$ = new decafStmtList();} | method_decl method_decls { decafStmtList *slist = new decafStmtList(); if($1!=NULL) slist->push_back($1); if($2!=NULL) slist->push_back($2); $$ = slist; }

method_decl: T_FUNC T_ID T_LPAREN idtypes_func_args T_RPAREN method_type method_block {

	if(*$2=="main") {

		if(*$6!="IntType"){ throw runtime_error("main type should be int"); } 

		TheMainFunction=(decafAST*)new MethodDeclAST(*$2, *$6, (decafStmtList*)$4, (decafStmtList*)$7);

	} 

	else {
		methDeclare[*$2]=new MethodDeclAST(*$2, *$6, (decafStmtList*)$4, (decafStmtList*)$7);

	} 

	$$=NULL;

}

method_block: T_LCB var_decls statements T_RCB {$$=new MethodBlockAST((decafStmtList*)$2,(decafStmtList*)$3); }









//Variable Declaration
var_decls: {$$=NULL;} | var_decl var_decls{ decafStmtList *slist = new decafStmtList(); slist->push_back($1); if($2!=NULL) slist->push_back($2); $$=slist; }
var_decl: T_VAR T_ID type T_SEMICOLON {

	decafStmtList *slist = new decafStmtList(); 

	
	slist->push_back(new TypedSymbol(*$2, *$3)); 


	delete $2, delete $3; $$=slist;

}

	| T_VAR T_ID T_COMMA T_ID id_queried type T_SEMICOLON {

	decafStmtList *slist = new decafStmtList(); 


	slist->push_back(new TypedSymbol(*$2, *$6));
	slist->push_back(new TypedSymbol(*$4, *$6)); 

	istringstream ss(*$5);
	string token;
	while (getline(ss, token, ',')) {
		if(token!=""){
			slist->push_back(new TypedSymbol(token, *$6));
		}
	}
	
	delete $2, $4; $$=slist;
	}
;





statements: {$$=new decafStmtList();} | statement statements { decafStmtList *slist = new decafStmtList(); slist->push_back($1); if($2!=NULL) slist->push_back($2); $$=slist;}


statement: block
	 | method_call T_SEMICOLON
	 | if_statement
	 | assign T_SEMICOLON //{decafStmtList *slist = new decafStmtList(); slist->push_back($1); $$=$1;}
	 | break_statement T_SEMICOLON 
	 | continue_statement T_SEMICOLON
	 | while_statement
	 | for_statement
	 | return_statement T_SEMICOLON


if_statement: T_IF T_LPAREN expr T_RPAREN block %prec "if_then" {$$=new ifStatmentAST((ExpressionAST*)$3, (BlockAST*)$5, NULL);}
	    | T_IF T_LPAREN expr T_RPAREN block T_ELSE block {$$=new ifStatmentAST((ExpressionAST*)$3, (BlockAST*)$5, (BlockAST*)$7);}


//Forloop Statements
for_statement: T_FOR T_LPAREN init T_SEMICOLON check T_SEMICOLON post T_RPAREN block {$$=new forStatmentAST($5,(decafStmtList*)$3,(decafStmtList*)$7, (decafStmtList*)$9);}
init: init T_COMMA assign {decafStmtList *slist = new decafStmtList(); slist->push_back($3); slist->push_back($1); $$=slist;}
    | assign
check: expr
post: post T_COMMA assign {decafStmtList *slist = new decafStmtList(); slist->push_back($3); slist->push_back($1); $$=slist;}
    | assign


//Whileloop Statements
while_statement: T_WHILE T_LPAREN expr T_RPAREN block {$$=new whileStatementAST($3, (decafStmtList*)$5);}

break_statement: T_BREAK {$$=new BreakStatementAST();}

continue_statement: T_CONTINUE {$$=new ContinueStatementAST;}



//Return Statements
return_statement: T_RETURN rtrop {$$=new ReturnStatementAST((ExpressionAST*)$2);}
rtrop: {$$=new ExpressionAST("None");} | T_LPAREN rtropin T_RPAREN {$$=$2;}
rtropin: {$$=new ExpressionAST("None");} | expr





//Block Statements
block: begin_block var_decls statements end_block {$$=new BlockAST((decafStmtList*)$2,(decafStmtList*)$3);}
begin_block: T_LCB 
end_block: T_RCB




//Assign Statements
assign: Lvalue T_ASSIGN expr {((assignAST*)$1)->setexprVal($3); $$=$1;}


Lvalue: T_ID {

	$$=new assignAST(*$1, NULL); 

	delete $1;

}

| T_ID T_LSB expr T_RSB {

	$$=new assignAST(*$1, $3); 

	delete $1;

}

comma_sep_method_arg: method_arg T_COMMA comma_sep_method_arg {((decafStmtList*)$3)->push_front($1); $$=$3;}
		    | method_arg {decafStmtList *slist = new decafStmtList(); slist->push_front($1); $$=slist;}



//Method Call
method_list_arg: {$$=new decafStmtList();} | comma_sep_method_arg
method_call: T_ID T_LPAREN method_list_arg T_RPAREN {

	decafStmtList *slist = new decafStmtList();

	
	$$=new MethodCall(*$1, (decafStmtList*)$3);

	
}
method_arg: expr {

		$$=new MethodArg($1->str(), $1); 
}
	 | T_STRINGCONSTANT {
		
		$$=new MethodArg(*$1); 

		delete $1;

}



exprConstant: T_INTCONSTANT {$$=new ExpressionAST("NumberExpr",$1);}
            | T_CHARCONSTANT {$$=new ExpressionAST("NumberExpr",$1);}
            | T_FALSE {$$=new ExpressionAST("BoolExpr",0);}
	    | T_TRUE {$$=new ExpressionAST("BoolExpr",1);}

rvalue: T_ID T_LSB expr T_RSB {$$=new ExpressionAST("ArrayLocExpr",*$1, $3); delete $1;}
      | T_ID {$$=new ExpressionAST("VariableExpr", *$1); delete $1;}


expr: rvalue
      | method_call 					{$$ = new ExpressionAST("MethodCall", (MethodCall*)$1); }
      | exprConstant					
      | T_NOT expr	%prec UnaryNot			{$$=new ExpressionAST("Not", $2);}
      | T_MINUS expr	%prec UnaryMinus 		{$$=new ExpressionAST("UnaryMinus", $2);}
      | T_LPAREN expr T_RPAREN				{$$ = $2;}
      | expr T_PLUS expr				{$$=new ExpressionAST("Plus", $1, $3);}
      | expr T_MINUS expr				{$$=new ExpressionAST("Minus", $1, $3);}
      | expr T_MULT expr				{$$=new ExpressionAST("Mult", $1, $3);}
      | expr T_DIV expr					{$$=new ExpressionAST("Div", $1, $3);}
      | expr T_LEFTSHIFT expr				{$$=new ExpressionAST("Leftshift", $1, $3);}
      | expr T_RIGHTSHIFT expr				{$$=new ExpressionAST("Rightshift", $1, $3);}
      | expr T_MOD expr					{$$=new ExpressionAST("Mod", $1, $3);}
      | expr T_EQ expr					{$$=new ExpressionAST("Eq", $1, $3);}
      | expr T_NEQ expr					{$$=new ExpressionAST("Neq", $1, $3);}
      | expr T_LT expr					{$$=new ExpressionAST("Lt", $1, $3);}
      | expr T_LEQ expr					{$$=new ExpressionAST("Leq", $1, $3);}
      | expr T_GT expr					{$$=new ExpressionAST("Gt", $1, $3);}
      | expr T_GEQ expr					{$$=new ExpressionAST("Geq", $1, $3);}
      | expr T_AND expr					{$$=new ExpressionAST("And", $1, $3);}
      | expr T_OR expr					{$$=new ExpressionAST("Or", $1, $3);}
    ; 
%%

int main() {
  // initialize LLVM
  llvm::LLVMContext &Context = llvm::getGlobalContext();
  // Make the module, which holds all the code.
  TheModule = new llvm::Module("Test", Context);
  // set up symbol table
  symtbl=new symbol_table_list();
  symtbl->push_back(*(new symbol_table));

  //TheFunction = gen_main_def();
  // parse the input and create the abstract syntax tree
  int retval = yyparse();
  // remove symbol table
  delete symtbl;
  // Finish off the main function. (see the WARNING above)
  //TheFunction = gen_main_def();
  // return 0 from main, which is EXIT_SUCCESS
  //Builder.CreateRet(llvm::ConstantInt::get(llvm::getGlobalContext(), llvm::APInt(32, 0)));
  // Validate the generated code, checking for consistency.
  verifyFunction(*TheFunction);
  // Print out all of the generated code to stderr
  TheModule->dump();
  return(retval >= 1 ? EXIT_FAILURE : EXIT_SUCCESS);
}
