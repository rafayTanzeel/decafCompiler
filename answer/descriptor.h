#ifndef _TYPE_INHERIT_DEFS
#define _TYPE_INHERIT_DEFS

#include <string>
#include <iostream>

using namespace std;

class descriptor {
private:
   // for debugging: line number where identifier was declared
 
  llvm::Value* addr;
  string type;
  bool spilled;
  int lineno;

public:
  
  descriptor(int num, string id, string t) { 
	lineno = num;
	if(t=="IntType") type = "int";
	else if(t=="StringType") type = "string";
	else if(t=="BoolType") type = "bool";
	else type = "void";
	//cout<<endl<<"TYPE : "<<type<<endl;
	//cerr << "defined variable: "<< id <<", with type: "<< type <<", on line number: "<< lineno<<endl;
 }

descriptor(int num, string id, string t, llvm::Value* address) { 
	lineno = num;
	addr=address;
	if(t=="IntType") type = "int";
	else if(t=="StringType") type = "string";
	else if(t=="BoolType") type = "bool";
	else type = "void";
	//cout<<endl<<"TYPE : "<<type<<endl;
	//cerr << "defined variable: "<< id <<", with type: "<< type <<", on line number: "<< lineno<<endl;
 }
  descriptor(int num, llvm::Value* address){lineno=num; addr=address;}
  descriptor(int num, string typeVal, llvm::Value* address){lineno=num; addr=address; type=typeVal;}
  void setAddress(llvm::Value *address){addr=address;}
  llvm::Value *getAddress(){return addr;}

};

extern "C"
{
  int yyerror(const char *);
  int yyparse(void);
  int yylex(void);  
  int yywrap(void);
}

#endif
