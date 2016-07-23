
#include "decafcomp-defs.h"
#include <list>
#include <ostream>
#include <iostream>
#include <sstream>

#ifndef YYTOKENTYPE
#include "decafcomp.tab.h"
#endif

extern symbol_table_list* symtbl;
using namespace std;



/// decafAST - Base class for all abstract syntax tree nodes.
class decafAST {
public:
  virtual ~decafAST() {}
  virtual string str() { return string(""); }
  virtual llvm::Value *Codegen() = 0;
};

string getString(decafAST *d) {
	if (d != NULL) {
		return d->str();
	} else {
		return string("None");
	}
}

template <class T>
string commaList(list<T> vec) {
    string s("");
    for (typename list<T>::iterator i = vec.begin(); i != vec.end(); i++) { 
        s = s + (s.empty() ? string("") : string(",")) + (*i)->str(); 
    }   
    if (s.empty()) {
        s = string("None");
    }   
    return s;
}

template <class T>
llvm::Value *listCodegen(list<T> vec) {
	llvm::Value *val = NULL;
	for (typename list<T>::iterator i = vec.begin(); i != vec.end(); i++) { 
		llvm::Value *j = (*i)->Codegen();
		if (j != NULL) { val = j; }
	}	
	return val;
}

llvm::Type *gen_type(string argType){
	llvm::Type *val = NULL;
	if(argType=="IntType") val = Builder.getInt32Ty();
	else if(argType=="StringType") val = Builder.getInt8PtrTy();
	else if(argType=="BoolType") val = Builder.getInt1Ty();
	else val = Builder.getVoidTy();
	return val;
}


/// decafStmtList - List of Decaf statements
class decafStmtList : public decafAST {
	list<decafAST *> stmts;
public:
	decafStmtList() {}
	~decafStmtList() {
		for (list<decafAST *>::iterator i = stmts.begin(); i != stmts.end(); i++) { 
			delete *i;
		}
	}
	int size() { return stmts.size(); }
	void push_front(decafAST *e) { stmts.push_front(e); }
	void push_back(decafAST *e) { stmts.push_back(e); }
	string str() { return commaList<class decafAST *>(stmts); }
	llvm::Value *Codegen() { 
		return listCodegen<decafAST *>(stmts); 
	}
	list<decafAST *> getStmts() {
		return stmts;
	}
};

class PackageAST : public decafAST {
	string Name;
	decafStmtList *FieldDeclList;
	decafStmtList *MethodDeclList;
public:
	PackageAST(string name, decafStmtList *fieldlist, decafStmtList *methodlist) 
		: Name(name), FieldDeclList(fieldlist), MethodDeclList(methodlist) {}
	~PackageAST() { 
		if (FieldDeclList != NULL) { delete FieldDeclList; }
		if (MethodDeclList != NULL) { delete MethodDeclList; }
	}
	string str() { 
		return string("Package") + "(" + Name + "," + getString(FieldDeclList) + "," + getString(MethodDeclList) + ")";
	}
	llvm::Value *Codegen() { 
		llvm::Value *val = NULL;
		TheModule->setModuleIdentifier(llvm::StringRef(Name)); 
		//if (NULL != FieldDeclList) {
		//	val = FieldDeclList->Codegen();
		//}
		///if (NULL != MethodDeclList) {
		//	val = MethodDeclList->Codegen();
		//} 
		// Q: should we enter the class name into the symbol table?
		return val; 
	}
};

class ExternType : public decafAST {
        string type;
public:
        ExternType(string type) :type(type) {}

        string str() {
                return string("VarDef") + "(" + type + ")";
        }
        llvm::Value *Codegen() {
        		return (llvm::Value*)gen_type(type);
        }
	string getType() { return type; }
};

class ExternFuncAST : public decafAST {
	string name;
	string returnType;
	decafStmtList* typelist;
public:
	ExternFuncAST(string name, string rType, decafStmtList* aType) :name(name), returnType(rType), typelist(aType){Codegen();}

	~ExternFuncAST() {
		if (typelist != NULL) { delete typelist; }
	}

	string str() {
		return string("ExternFunction") + "(" + name + "," + returnType + "," + getString(typelist) + ")";
	}
	llvm::Value *Codegen() {
			descriptor* funcLookup=access_symtbl(name);
			if(funcLookup!=NULL){ 
				TheFunction=(llvm::Function*)funcLookup->getAddress();
				verifyFunction(*TheFunction);
				return TheFunction;

			} else{
				if(name=="print_string"){
					TheFunction=genPrintStringDef(); symtbl->back()[name] = new descriptor(lineno, TheFunction); 
					verifyFunction(*TheFunction);
					return TheFunction;
				}
				if(name=="print_int"){
					TheFunction=genPrintIntDef(); symtbl->back()[name] = new descriptor(lineno, TheFunction);
					verifyFunction(*TheFunction);
					return TheFunction;
				}
				if(name=="read_int"){
					TheFunction=genReadIntDef(); symtbl->back()[name] = new descriptor(lineno, TheFunction);
					verifyFunction(*TheFunction);
					return TheFunction;
				}
			}

			vector<llvm::Type *> args;
			llvm::Type *returnTy;
			if (typelist!=NULL) {
				for (decafAST *types : typelist->getStmts()) {
					args.push_back((llvm::Type*)types->Codegen());
				}
			}
			returnTy=gen_type(returnType);
			llvm::FunctionType *FT = llvm::FunctionType::get(returnTy, args, false);
  			TheFunction = llvm::Function::Create(FT, llvm::Function::ExternalLinkage, name, TheModule);

  			if (TheFunction == 0) {
    				throw runtime_error("empty function block");
  			}
			verifyFunction(*TheFunction);
			return TheFunction;
	}
};

class FieldDeclAST : public decafAST {
	string name;
	string type;
	string sizeType;
	string declareType;
	int size;
	int value;
public:
	FieldDeclAST(string declareType, string name, string type, string sizeType, int size, int value=0) : declareType(declareType), name(name), type(type), sizeType(sizeType), size(size), value(value) {symtbl->back()[name] = new descriptor(lineno,name,type); Codegen();}

	string str() {
		string collection = "";
		istringstream ss(name);
		string token;

		while (getline(ss, token, ',')) {
			collection+= string(declareType) + "(" + token + "," + type + "," + sizeType + "),";
		}
		return collection.substr(0, collection.length() - 1);
	}
	llvm::Value *Codegen() {
		llvm::GlobalVariable *gl;
		if(declareType=="Scalar" || declareType=="AssignGlobalVar"){

			gl = new llvm::GlobalVariable(
		    *TheModule, 
		    gen_type(type), 
		    false,  // variable is mutable
		    llvm::GlobalValue::InternalLinkage, 
			(type=="IntType")?Builder.getInt32(value):Builder.getInt1(value), 
			name
		  );
		}else{

			llvm::ArrayType *arrayIorB = llvm::ArrayType::get((type=="IntType")?Builder.getInt32Ty():Builder.getInt1Ty(), size);
			llvm::Constant *zeroInit = llvm::Constant::getNullValue(arrayIorB);
			gl = new llvm::GlobalVariable(
			*TheModule, 
			arrayIorB, 
			false, 
			llvm::GlobalValue::ExternalLinkage, 
			zeroInit,
			name
			);			
		}
			symtbl->back()[name]->setAddress(gl);
			return gl;
		}
};


class TypedSymbol : public decafAST {
private:
	string name;
	string type;
public:
	TypedSymbol(string name, string type): name(name), type(type){symtbl->back()[name] = new descriptor(lineno,name,type);}
	string str() {
		return string("VarDef") + "(" + name + "," + type + ")";
	}
	
	llvm::Value *Codegen() {
			llvm::Value *temp=(gen_type(type)==Builder.getInt32Ty())?Builder.getInt32(0):Builder.getInt1(0);
			llvm::AllocaInst *Alloca = Builder.CreateAlloca(temp->getType(), nullptr, name);

			symtbl->back()[name]=new descriptor(lineno, Alloca);
			return Alloca;
		}
	string getType(){return type;}
	string getName(){return name;}
};



class MethodDeclAST : public decafAST {
	string name;
	string returnType;
	decafStmtList * paramList;
	decafStmtList * methodBlock;
public:
	MethodDeclAST(string name, string returnType, decafStmtList* paramList, decafStmtList * methodBlock): name(name), returnType(returnType), paramList(paramList), methodBlock(methodBlock){}

	~MethodDeclAST() {
		if (methodBlock != NULL) delete methodBlock;
		if (paramList != NULL) delete paramList;
	}
	string str() {
		return string("Method") + "(" + name + "," + returnType + ',' + getString(paramList) + ',' + getString(methodBlock) + ")";
	}
	llvm::Value *Codegen() { 
				llvm::Value *val = NULL;
				
				llvm::Type *returnTy;
				std::vector<llvm::Type *> args;
				std::list<string> argNames;
				if(paramList!=NULL){
					
		        		for (decafAST *types : paramList->getStmts()) {
						args.push_back(gen_type(((TypedSymbol*)types)->getType()));
						//args.push_back(types->Codegen()->getType());
						argNames.push_back(((TypedSymbol*)types)->getName());
					}
				}
				

				returnTy=gen_type(returnType);
				llvm::FunctionType *FT = llvm::FunctionType::get(returnTy, args, false);
				TheFunction = llvm::Function::Create(FT, llvm::Function::ExternalLinkage, name, TheModule);
				if (TheFunction == 0) {
					throw runtime_error("empty function block");
				}
				llvm::BasicBlock *BB = llvm::BasicBlock::Create(llvm::getGlobalContext(), "entry", TheFunction);
				Builder.SetInsertPoint(BB);

				map<string, llvm::AllocaInst *> bufferAlloc;
				for (auto &Arg : TheFunction->args()){
					Arg.setName(argNames.front());
					llvm::AllocaInst *Alloca = Builder.CreateAlloca(Arg.getType(), nullptr, Arg.getName());
					Builder.CreateStore(&Arg, Alloca);
					access_symtbl(argNames.front())->setAddress(Alloca);
					argNames.pop_front();

				}
	
				symtbl->back()[name] = new descriptor(lineno,name,returnType);
				symtbl->back()[name]->setAddress(TheFunction);

				symtbl->push_back(*(new symbol_table));
				
				if(methodBlock!=NULL){
					methodBlock->Codegen();
				}else{
					throw runtime_error("empty method block");
				}
				symtbl->pop_back();

				verifyFunction(*TheFunction);
				return TheFunction;
		}

};


class MethodBlockAST : public decafAST {
	decafStmtList * var_decl_list;
	decafStmtList * statement_list;
public:
	MethodBlockAST(decafStmtList * var_decl_list, decafStmtList * statement_list) :var_decl_list(var_decl_list), statement_list(statement_list) {}

	~MethodBlockAST() {
		if (var_decl_list != NULL) delete var_decl_list;
		if (statement_list != NULL) delete statement_list;
	}

	string str() {
		return string("MethodBlock") + "(" + getString(var_decl_list) + ',' + getString(statement_list) + ")";
	}
	llvm::Value *Codegen() {
                        llvm::Value *val = NULL;
			if (NULL != var_decl_list) {
				val = var_decl_list->Codegen();
			}
			if (NULL != statement_list) {
				val = statement_list->Codegen();
			}
			llvm::BasicBlock *CurBB = Builder.GetInsertBlock();
			llvm::Function *func = Builder.GetInsertBlock()->getParent();
			if(symtbl->back()["return"]==NULL){
			if(func->getReturnType()==Builder.getInt32Ty()) {Builder.CreateRet(Builder.getInt32(0));}
			else if(func->getReturnType()==Builder.getInt1Ty()) {Builder.CreateRet(Builder.getInt1(1));}
			else Builder.CreateRet(NULL);}
			return val;
		}
};

class MethodCall : public decafAST {
	string name;
	decafStmtList* method_arg_list;
	
public:
	MethodCall(string name, decafStmtList* method_arg_list) : name(name), method_arg_list(method_arg_list) {}

	~MethodCall() {
		if (method_arg_list != NULL) delete method_arg_list;
	}
	string str() {
		return string("MethodCall") + "(" + name + ',' + getString(method_arg_list) + ")";
	}
	llvm::Value *Codegen() { 

			descriptor* func=access_symtbl(name);

			if(func==NULL) throw runtime_error("function not found"); 
			llvm::Function *call=(llvm::Function *)func->getAddress();

			llvm::Value *val;
			std::vector<llvm::Value *> args;

			if(method_arg_list!=NULL){
				for (decafAST *types : method_arg_list->getStmts()) {
						args.push_back(types->Codegen());
					}
			
			int i=0;
			for(llvm::Function::arg_iterator fargs = call->arg_begin(); fargs != call->arg_end(); fargs++, i++){
				if(args[i]->getType()==Builder.getInt1Ty() && fargs->getType()==Builder.getInt32Ty()){
					llvm::Value *promo = Builder.CreateZExt(args[i], fargs->getType(), "zexttmp");
					args[i]=promo;
				}
			}
		}

			
			bool isVoid = call->getReturnType()->isVoidTy();


			
			val = Builder.CreateCall(
				call,
				args,
				isVoid ? "" : "calltmp"
			);

			return val;
		}
};




class ExpressionAST : public decafAST {
private:
	string op;
	ExpressionAST* left_value;
	ExpressionAST* right_value;
	string expressionType;
	int result=0;
	llvm::Type* type;
	llvm::Value* valueStorage;
	string id;
	MethodCall* methodReturn;

	map<string, int> converter = { { "Plus", 1 },{ "Minus", 2 },{ "Mult", 3 },{ "Div", 4 },{ "Leftshift", 5 },{ "Rightshift", 6 },{ "Mod", 7 },{ "Eq", 8 },{ "Neq", 9 },{ "Lt", 10 },{ "Leq", 11 },{ "Gt", 12 },{ "Geq", 13 },{ "And", 14 },{ "Or", 15 }, { "UnaryMinus", 16 },{ "Not", 17 }};
public:

	ExpressionAST(string expr):expressionType(expr) {}


	//Method Call
	ExpressionAST(string mexpr, MethodCall* methodReturn) : op(mexpr), methodReturn(methodReturn){}

	//Constants 
	ExpressionAST(string opVal, int resultVal) :op(opVal), result(resultVal){
		if(opVal=="BoolExpr" && resultVal==1) {expressionType = op + "(True)"; type=Builder.getInt1Ty(); valueStorage=Builder.getInt1(result);}
		else if(opVal=="BoolExpr" && resultVal==0) {expressionType = op + "(False)"; type=Builder.getInt1Ty(); valueStorage=Builder.getInt1(result);}
		else {expressionType = op + "(" + to_string(result) + ")"; type=Builder.getInt32Ty(); valueStorage=Builder.getInt32(result);}
	}

	//rvalue 
	ExpressionAST(string opVal, string resultID) :op(opVal), id(resultID) {
		expressionType = op + "(" + resultID + ")";
	}

	//rvalue 
	ExpressionAST(string opVal, string resultID, ExpressionAST* exprIndex) :op(opVal), id(resultID) {
		expressionType = op + "(" + resultID + ','+ exprIndex->str() + ")";
	}

	//Binary Arith 
	ExpressionAST(string op, ExpressionAST* left_value, ExpressionAST* right_value) : op(op), left_value(left_value), right_value(right_value) {
		expressionType = "BinaryExpr(" + op + ',' + left_value->expressionType + ',' + right_value->expressionType + ")";
		switch (converter[op]) {
			case 1: result =  left_value->result + right_value->result; break;
			case 2: result = left_value->result - right_value->result;  break;
			case 3: result = left_value->result * right_value->result; break;
			case 4: result = left_value->result / right_value->result;  break;
			case 5: result = left_value->result << right_value->result; break;
			case 6: result = left_value->result >> right_value->result; break;
			case 7: result = left_value->result % right_value->result;  break;
			case 8: result = left_value->result == right_value->result; break;
			case 9: result = left_value->result != right_value->result; break;
			case 10: result = left_value->result < right_value->result; break;
			case 11: result = left_value->result <= right_value->result; break;
			case 12: result = left_value->result > right_value->result; break;
			case 13: result = left_value->result >= right_value->result; break;
			case 14: result = left_value->result && right_value->result; break;
			case 15: result = left_value->result || right_value->result; break;

		}
		
	}

	//UnaryMinus && Not
	ExpressionAST(string op, ExpressionAST* value) : op(op), right_value(value), left_value(value){
		expressionType = "UnaryExpr(" + op + ',' + value->expressionType + ")";
		if (op == "UnaryMinus") {result = -value->result; result=-1*value->result; valueStorage=Builder.getInt32(result); }
		else {result = !value->result; valueStorage=Builder.getInt1(result);}
	}

	int getResult() { return result; }
	
	llvm::Value *Codegen() {
		if(!id.empty()){
				descriptor* symtRef=access_symtbl(id);
				if(symtRef==NULL){
					throw runtime_error("identifier not defined"); 
				}

				llvm::Value* gl=symtRef->getAddress();
				if(gl==NULL){
					throw runtime_error("unable to get address"); 
				}
				valueStorage = Builder.CreateLoad(gl, id);
				return valueStorage;
		}
		if (op=="MethodCall") return methodReturn->Codegen();
		if(left_value == NULL || right_value == NULL) return valueStorage;
		
		llvm::Value *L = left_value->Codegen();
		llvm::Value *R = right_value->Codegen();

        	switch (converter[op]) {
			 case 1: return Builder.CreateAdd(L, R, "addtmp"); break;
			 case 2: return Builder.CreateSub(L, R, "subtmp"); break;
			 case 3: return Builder.CreateMul(L, R, "multmp"); break;
			 case 4: return Builder.CreateSDiv(L, R, "divtmp"); break;
			 case 5: return Builder.CreateShl(L, R, "shltmp"); break;
			 case 6: return Builder.CreateLShr(L, R, "shrtmp"); break;
			 case 7: return Builder.CreateSRem(L, R, "sremtmp"); break;
			 case 8: return Builder.CreateICmpEQ(L, R, "ICmpEQtmp"); break;
			 case 9: return Builder.CreateICmpNE(L, R, "CmpNEtmp"); break;
			 case 10: return Builder.CreateICmpSLT(L, R, "ICmpSLTtmp"); break;
			 case 11: return Builder.CreateICmpSLE(L, R, "ICmpSLEtmp"); break;
			 case 12: return Builder.CreateICmpSGT(L, R, "ICmpSGTtmp"); break;
			 case 13: return Builder.CreateICmpSGE(L, R, "ICmpSGEtmp"); break;
			 case 14: return Builder.CreateAnd(L, R, "andtmp"); break;
			 case 15: return Builder.CreateOr(L, R, "ortmp"); break;
			 case 16: return Builder.CreateNeg(R, "negtmp"); break;
			 case 17: return Builder.CreateNot(R, "nottmp"); break;
			default: throw runtime_error("expression is wrong"); break;
        	 }
	}

	string str() {
		return expressionType;
	}
};

class MethodArg : public decafAST {
	string arg;
	ExpressionAST* argValExpr;
public:
	MethodArg(string arg, ExpressionAST* argVal) : arg(arg), argValExpr(argVal){}
	MethodArg(string arg) : arg(arg){}
	string str() {
		return arg;
	}
	llvm::Value *Codegen() { 
			if(argValExpr==NULL){

				arg=arg.substr(1,arg.length()-2);

	 			stringstream ss;

				size_t size = arg.length();

				for(int i=0; i<size; i++){
				
				char c = arg[i];

				if(c!='\\'){
					ss<<c;
				}
				else{
			
					char c = arg[i + 1];

						switch (c) {
						   case 'n': ss<<'\n'; break;
						   case 'r': ss<<'\r'; break;
						   case 't': ss<<'\t'; break;
						   case 'v': ss<<'\v'; break;
						   case 'f': ss<<'\f'; break;
						   case 'a': ss<<'\a'; break;
						   case 'b': ss<<'\b'; break;
						   case '\'': ss<<'\''; break;
						   case '"': ss<<'"'; break;
						   default: ss<<'\\'; 
					  }
					i++;
				    }

				}

				arg = ss.str();

				llvm::Value *GlobalStr = Builder.CreateGlobalString(arg, "globalstring"); 

				llvm::Type *ty = GlobalStr->getType();

				llvm::Type *eltTy = llvm::cast<llvm::PointerType>(ty)->getElementType();

				llvm::Value *Cast = Builder.CreateConstGEP2_32(eltTy, GlobalStr, 0, 0, "cast");

				return Cast;

			}
			else{return argValExpr->Codegen();}
	
		}
};

class assignAST : public decafAST {
	string name;
	ExpressionAST* exprIndex;
	ExpressionAST* exprVal;

public:
	assignAST(string name, ExpressionAST* exprIndex) :name(name), exprIndex(exprIndex) {}

	void setexprVal(ExpressionAST* exprVal) { this->exprVal = exprVal; }

	assignAST(string name, ExpressionAST* exprIndex, ExpressionAST* exprVal) :name(name), exprIndex(exprIndex), exprVal(exprVal) {}

	string str() {
		if (!exprIndex) {
			return string("AssignVar") + "(" + name + ',' + getString(exprVal) + ")";
		}
		return string("AssignArrayLoc") + "(" + name + ',' + getString(exprIndex) + ',' + getString(exprVal) + ")";
	}

	llvm::Value *Codegen() {
		descriptor* desc=access_symtbl(name);
		//cout<<desc;
		if(desc==NULL){
			throw runtime_error("identifier not defined"); 
		}
		

		llvm::AllocaInst* laddr=(llvm::AllocaInst*)desc->getAddress();
		
		if(laddr==NULL) throw runtime_error("variable not allocated"); 
		llvm::Value *val;

		llvm::Value *exprValCG = exprVal->Codegen();
		if(exprValCG==NULL ) throw runtime_error("exprVal not inserted correctly"); 
	    	llvm::PointerType *ptrTy = exprValCG->getType()->getPointerTo();


        	if(ptrTy == laddr->getType()){
        		val = Builder.CreateStore(exprValCG, laddr);
        	}
        	else{
        		throw runtime_error("assignment of different types"); 
        	}
           	return val;
        }
};


class BreakStatementAST : public decafAST {
public:
	string str() { return "BreakStmt"; }
	llvm::Value *Codegen() { 
				llvm::Value *val = NULL;
				return val;
		}
};

class ContinueStatementAST : public decafAST {
public:
	string str() { return "ContinueStmt"; }
	llvm::Value *Codegen() { 
				llvm::Value *val = NULL;
				return val;
		}
};




class whileStatementAST : public decafAST {
	string condition;
	decafStmtList* while_block;

public:
	whileStatementAST(string condition, decafStmtList* while_block):condition(condition), while_block(while_block){}

	~whileStatementAST() {
		if (while_block != NULL) delete while_block;
	}

	string str() { 
		return string("WhileStmt") + "(" + condition + ',' + getString(while_block) + ")";
	}
	llvm::Value *Codegen() { 
				llvm::Value *val = NULL;
				return val;
		}
};


class forStatmentAST : public decafAST {
	string expr;
	decafStmtList* pre_assign_list;
	decafStmtList* loop_assign_list;
	decafStmtList* block;
public:
	forStatmentAST(string expr, decafStmtList* pre_assign_list, decafStmtList* loop_assign_list, decafStmtList* block) : expr(expr), pre_assign_list(pre_assign_list), loop_assign_list(loop_assign_list), block(block) {}
	
	string str() {
		return string("ForStmt") + "(" + getString(pre_assign_list) + ',' + expr + ',' + getString(loop_assign_list) + ',' + getString(block)+")";
	}
	llvm::Value *Codegen() { 
				llvm::Value *val = NULL;
				return val;
		}
};


class ifStatmentAST : public decafAST {
	string expr;
	decafAST* if_block;
	decafAST* else_block;
public:
	ifStatmentAST(string expr, decafAST* if_block, decafAST* else_block) : expr(expr), if_block(if_block), else_block(else_block) {}

	string str() {
		return string("IfStmt") + "(" + expr + ',' + getString(if_block) + ',' + getString(else_block) + ")";
	}
	llvm::Value *Codegen() { 
				llvm::Value *val = NULL;
				return val;
		}
};


class ReturnStatementAST : public decafAST {
	ExpressionAST* expr;

public:
	ReturnStatementAST(ExpressionAST* expr) : expr(expr) {}
	string str() {
		return string("ReturnStmt") + "(" + getString(expr) + ")";
	}
	llvm::Value *Codegen() {
		symtbl->back()["return"] = new descriptor(lineno, "return", "return");
		llvm::BasicBlock *CurBB = Builder.GetInsertBlock();
		llvm::Function *func = Builder.GetInsertBlock()->getParent();
		if(expr->str()!="None"){
			return Builder.CreateRet(expr->Codegen());
		}else{
		
		if(func->getReturnType()==Builder.getInt32Ty()) {return Builder.CreateRet(Builder.getInt32(0));}
		else if(func->getReturnType()==Builder.getInt1Ty()) {return Builder.CreateRet(Builder.getInt1(1));}
		else return Builder.CreateRet(NULL);
		}
		
	}
};

class BlockAST : public decafAST {
	decafStmtList * var_decl_list;
	decafStmtList * statement_list;
public:
	BlockAST(decafStmtList * var_decl_list, decafStmtList * statement_list) :var_decl_list(var_decl_list), statement_list(statement_list) {}

	~BlockAST() {
		if (var_decl_list != NULL) delete var_decl_list;
		if (statement_list != NULL) delete statement_list;
	}

	string str() {
		return string("Block") + "(" + getString(var_decl_list) + ',' + getString(statement_list) + ")";
	}
	llvm::Value *Codegen() { 
			symtbl->push_back(*(new symbol_table));

			llvm::Value *val = NULL;
			if (NULL != var_decl_list) {
				val = var_decl_list->Codegen();
			}
			if (NULL != statement_list) {
				val = statement_list->Codegen();
			}
			symtbl->pop_back();

			return val;
		}
};



/// ProgramAST - the decaf program
class ProgramAST : public decafAST {
	decafStmtList *ExternList;
	PackageAST *PackageDef;
public:
	ProgramAST(decafStmtList *externs, PackageAST *c) : ExternList(externs), PackageDef(c) {}
	~ProgramAST() { 
		if (ExternList != NULL) { delete ExternList; } 
		if (PackageDef != NULL) { delete PackageDef; }
	}
	string str() { return string("Program") + "(" + getString(ExternList) + "," + getString(PackageDef) + ")"; }
	llvm::Value *Codegen() { 
		llvm::Value *val = NULL;
		if (NULL != ExternList) {
			val = ExternList->Codegen();
		}
		if (NULL != PackageDef) {
			val = PackageDef->Codegen();
		} else {
			throw runtime_error("no package definition in decaf program");
		}
		return val; 
	}
};
