module otya.smilebasic.compiler;
import otya.smilebasic.node;
import otya.smilebasic.token;
import otya.smilebasic.vm;
import otya.smilebasic.type;
import otya.smilebasic.error;
import std.stdio;
class Scope
{
    GotoAddr breakAddr;
    GotoAddr continueAddr;
    Function func;
    this()
    {
    }
    this(GotoAddr breakAddr, GotoAddr continueAddr, Scope parent)
    {
        this.breakAddr =  breakAddr;
        this.continueAddr = continueAddr;
        this.func = parent.func;
    }
    this(Function func)
    {
        this.func = func;
    }
}
class Function
{
    int address;
    wstring name;
    int argCount;
    int argumentIndex;
    int variableIndex;
    VMVariable[wstring] variable;
    int[wstring] label;
    bool returnExpr;
    int outArgCount;
    this(int address, wstring name, bool returnExpr, int argCount)
    {
        this.address = address;
        this.name = name;
        this.returnExpr = returnExpr;
        this.argCount = argCount;
        this.variableIndex = 1;//0,bp,1,pc
        if(returnExpr)
        {
            outArgCount = 1;
        }
    }
    int getLocalVarIndex(wstring name, Compiler c)
    {
        int var = this.variable.get(name, VMVariable()).index;
        if(var == 0)
        {
            //local変数をあたる
            //それでもだめならOPTION STRICTならエラー
            this.variable[name] = VMVariable(var = ++variableIndex, c.getType(name));
        }
        return var;
    }
    int hasLocalVarIndex(wstring name)
    {
        int var = this.variable.get(name, VMVariable()).index;
        return var;
    }
    int defineLocalVarIndex(wstring name, Compiler c)
    {
        int var = this.variable.get(name, VMVariable()).index;
        if(var == 0)
        {
            this.variable[name] = VMVariable(var = ++variableIndex, c.getType(name));
        }
        else
        {
            //error:二重定義
            throw new DuplicateVariable();
        }
        return var;
    }
    int defineLocalVarIndexVoid(wstring name, Compiler c)
    {
        int var = this.variable.get(name, VMVariable()).index;
        if(var == 0)
        {
            this.variable[name] = VMVariable(var = ++variableIndex, ValueType.Void);
        }
        else
        {
            //error:二重定義
            throw new DuplicateVariable();
        }
        return var;
    }
    int defineArgumentIndex(wstring name, Compiler c)
    {
        int var = this.variable.get(name, VMVariable()).index;
        if(var == 0)
        {
            this.variable[name] = VMVariable(var = --argumentIndex, c.getType(name));
        }
        else
        {
            //error:二重定義
            //TODO:3.1ではエラーにならない
        }
        return var;
    }
}
class Compiler
{
    ValueType getType(wstring name)
    {
        wchar s = name[name.length - 1];
        switch(s)
        {
            case '$':
                return ValueType.String;
            case '#':
                return ValueType.Double;
            case '%':
                return ValueType.Integer;
            default:
                return ValueType.Integer;//DEFINT時
        }
    }
    Statements statements;
    this(Statements statements)
    {
        this.statements = statements;
        code = new Code[0];
    }

    Code[] code;
    VMVariable[wstring] global;
    int[wstring] globalLabel;
    Function[wstring] functions;
    int globalIndex = 0;
    void genCode(Code c)
    {
        code ~= c;
    }
    void genCodeImm(Value value)
    {
        code ~= new Push(value);
    }
    void genCodePushGlobal(int ind)
    {
        code ~= new PushG(ind);
    }
    void genCodePopGlobal(int ind)
    {
        code ~= new PopG(ind);
    }
    void genCodePushVar(wstring name, Scope sc)
    {
        auto global = hasGlobalVarIndex(name);
        if(sc.func)
        {
            code ~= new PushL(sc.func.getLocalVarIndex(name, this));
            return;
        }
        if(global)
        {
            code ~= new PushG(global);
            return;
        }
        code ~= new PushG(getGlobalVarIndex(name));
    }
    void genCodePopVar(wstring name, Scope sc)
    {
        auto global = hasGlobalVarIndex(name);
        if(sc.func)
        {
            code ~= new PopL(sc.func.getLocalVarIndex(name, this));
            return;
        }
        if(global)
        {
            code ~= new PopG(global);
            return;
        }
        code ~= new PopG(getGlobalVarIndex(name));
    }
    void genCodeOP(TokenType op)
    {
        code ~= new Operate(op);
    }
    void genCodeGoto(wstring label)
    {
        code ~= new GotoS(label);
    }
    void genCodeGosub(wstring label)
    {
        code ~= new GosubS(label);
    }
    GotoAddr genCodeGoto()
    {
        auto c = new GotoAddr(-1);
        code ~= c;
        return c;
    }
    GotoAddr genCodeGoto(int addr)
    {
        auto c = new GotoAddr(addr);
        code ~= c;
        return c;
    }
    GotoTrue genCodeGotoTrue()
    {
        auto c = new GotoTrue(-1);
        code ~= c;
        return c;
    }
    GotoFalse genCodeGotoFalse()
    {
        auto c = new GotoFalse(-1);
        code ~= c;
        return c;
    }
    int defineGlobalVarIndex(wstring name)
    {
        int global = this.global.get(name, VMVariable()).index;
        if(global == 0)
        {
            this.global[name] = VMVariable(global = ++globalIndex, getType(name));
        }
        else
        {
            //error:二重定義
            throw new DuplicateVariable();
        }
        return global;
    }
    int defineVarIndex(wstring name, Scope sc)
    {
        if(sc.func)
        {
            return sc.func.defineLocalVarIndex(name, this);
        }
        return defineGlobalVarIndex(name);
    }
    int defineVarIndexVoid(wstring name, Scope sc)
    {
        if(sc.func)
        {
            return sc.func.defineLocalVarIndexVoid(name, this);
        }
        int global = this.global.get(name, VMVariable()).index;
        if(global == 0)
        {
            this.global[name] = VMVariable(global = ++globalIndex, ValueType.Void);
        }
        else
        {
            //error:二重定義
            throw new DuplicateVariable();
        }
        return global;
    }
    int getGlobalVarIndex(wstring name)
    {
        int global = this.global.get(name, VMVariable()).index;
        if(global == 0)
        {
            //local変数をあたる
            //それでもだめならOPTION STRICTならエラー
            this.global[name] = VMVariable(global = ++globalIndex, getType(name));
        }
        return global;
    }
    int hasGlobalVarIndex(wstring name)
    {
        int global = this.global.get(name, VMVariable()).index;
        return global;
    }
    int getLocalVarIndex(wstring name, Scope sc)
    {
        if(sc.func)
        {
            int global = hasGlobalVarIndex(name);
            if(global) return global;
            int local = sc.func.getLocalVarIndex(name, this);
            return local;
        }
        return 0;
    }
    void compileExpression(Expression exp, Scope sc)
    {
        if(!exp)
        {
            genCodeImm(Value(ValueType.Void));
            return;
        }
        switch(exp.type)
        {
            case NodeType.Constant:
                genCodeImm((cast(Constant)exp).value);
                break;
            case NodeType.BinaryOperator:
                {
                    auto binop = cast(BinaryOperator)exp;
                    compileExpression(binop.item1, sc);
                    compileExpression(binop.item2, sc);
                    if(binop.operator == TokenType.LBracket)
                    {
                        IndexExpressions ie = cast(IndexExpressions)binop.item2;
                        if(ie)
                        {
                            genCode(new PushArray(ie.expressions.length));
                        }
                        else
                        {
                            genCode(new PushArray(1));
                        }
                        break;
                    }
                    genCodeOP(binop.operator);
                }
                break;
            case NodeType.UnaryOperator:
                {
                    auto una = cast(UnaryOperator)exp;
                    compileExpression(una.item, sc);
                    genCodeOP(una.operator);
                }
                break;
            case NodeType.Variable:
                auto var = cast(Variable)exp;
                genCodePushVar(var.name, sc);
                break;
            case NodeType.CallFunction:
                {
                    auto func = cast(CallFunction)exp;
                    auto bfun = otya.smilebasic.builtinfunctions.BuiltinFunction.builtinFunctions.get(func.name, null);
                    if(bfun)
                    {
                        auto k = bfun.argments.length - func.args.length;
                        foreach(l;0..k)
                        {
                            genCodeImm(Value(ValueType.Void));
                        }
                    }
                    foreach_reverse(Expression i ; func.args)
                    {
                        compileExpression(i, sc);
                    }
                    if(bfun)
                    {
                        genCode(new CallBuiltinFunction(bfun, func.args.length, 1));
                    }
                    else
                    {
                        genCode(new CallFunctionCode(func.name, func.args.length));
                    }
                }
                break;
            case NodeType.IndexExpressions://[expr,expr,expr,expr]用
                {
                    auto index = cast(IndexExpressions)exp;
                    int count = 0;
                    foreach_reverse(Expression i; index.expressions)
                    {
                        compileExpression(i, sc);
                        count++;
                        if(count >= 4) break;//念のため
                    }
                }
                break;
            default:
                stderr.writeln("Compile:NotImpl ", exp.type);
                break;
        }
    }
    void compileIf(If node, Scope sc)
    {
        compileExpression(node.condition, sc);
        //条件式がfalseならendif or elseに飛ぶ
        auto else_ = genCodeGotoFalse();
        compileStatements(node.then, sc);
        //もしelseもあるのならば、endifに飛ぶ
        GotoAddr then;
        if(node.hasElse)
        {
            then = genCodeGoto();
            else_.address = code.length;
            compileStatements(node.else_, sc);
            then.address = code.length;
        }
        else
        {
            //endifに飛ばす
            else_.address = code.length;
        }
    }
    void compileFor(For node, Scope s)
    {
        compileStatement(node.initExpression, s);
        auto forstart = code.length;
        compileExpression(node.stepExpression, s);
        genCodeImm(Value(0));
        //step>=0
        genCodeOP(TokenType.GreaterEqual);
        auto positiveZero = genCodeGotoTrue();//正の値または0
        //stepが負の値の時の処理
        //toよりcounterが小さい場合はBREAK
        //to==counterの時はBREAKしない
        //t c
        //0>0 false
        //FOR I=0 TO -1 STEP -1
        //-1>0 false
        //1>0 true
        compileExpression(node.toExpression, s);
        genCodePushVar(node.initExpression.name, s);
        genCodeOP(TokenType.Greater);
        auto breakAddr = genCodeGotoTrue();
        auto forAddr = genCodeGoto();
        positiveZero.address = code.length;
        //stepが正の値の時の処理
        //toよりcounterが大きい場合はBREAK
        //t c
        //0<0 false
        //1<0 false
        //0<1 true break
        compileExpression(node.toExpression, s);
        genCodePushVar(node.initExpression.name, s);
        genCodeOP(TokenType.Less);
        genCode(breakAddr);
        forAddr.address = code.length;
        s = new Scope(new GotoAddr(-1), new GotoAddr(-1), s);
        compileStatements(node.statements, s);
        s.continueAddr.address = code.length;
        //counterに加算する
        genCodePushVar(node.initExpression.name, s);
        compileExpression(node.stepExpression, s);
        genCodeOP(TokenType.Plus);
        genCodePopVar(node.initExpression.name, s);
        genCodeGoto(forstart);
        breakAddr.address = code.length;
        s.breakAddr.address = code.length;
    }
    void compileWhile(While node, Scope s)
    {
        auto whilestart = code.length;
        s = new Scope(new GotoAddr(-1), new GotoAddr(whilestart), s);
        compileExpression(node.condExpression, s);
        auto breakAddr = genCodeGotoFalse();
        compileStatements(node.statements, s);
        genCode(s.continueAddr);
        s.breakAddr.address = code.length;
        breakAddr.address = code.length;
    }
    void compileVar(Var node, Scope sc)
    {
        foreach(Statement v ; node.define)
        {
            if(v.type == NodeType.DefineVariable)
            {
                DefineVariable var = cast(DefineVariable)v;
                defineVarIndex(var.name, sc);
                continue;
            }
            if(v.type == NodeType.DefineArray)
            {
                DefineArray var = cast(DefineArray)v;
                int siz = 0;
                foreach_reverse(Expression expr; var.dim.expressions)
                {
                    compileExpression(expr, sc);
                    siz++;
                    if(siz == 4)
                        break;//4次元まで(パーサーで除去するけど万が一に備えて
                }
                defineVarIndexVoid(var.name, sc);
                genCode(new NewArray(getType(var.name), var.dim.expressions.length));
                genCodePopVar(var.name, sc);
                continue;
            }
        }
    }
    void compileStatements(Statements statements, Scope sc)
    {
        foreach(Statement s ; statements.statements)
        {
            compileStatement(s, sc);
        }
    }
    void compileDefineFunction(DefineFunction node)
    {
        auto skip = genCodeGoto();
        Function func = new Function(this.code.length, node.name, node.returnExpr, node.arguments.length);
        Scope sc = new Scope(func);
        foreach(wstring arg; node.arguments)
        {
            func.defineArgumentIndex(arg, this);
        }
        foreach(wstring arg; node.outArguments)
        {
            func.defineLocalVarIndexVoid(arg, this);
        }
        if(!func.returnExpr)
            func.outArgCount = node.outArguments.length;
        compileStatements(node.functionBody, sc);
        if(func.returnExpr)
            genCodeImm(Value(ValueType.Void));
        genCode(new ReturnFunction(func));
        skip.address = this.code.length;
        this.functions[func.name] = func;
    }
    void compileStatement(Statement i, Scope s)
    {
        switch(i.type)
        {
            case NodeType.Print:
                {
                    auto print = cast(Print)i;
                    foreach_reverse(PrintArgument j ; print.args)
                    {
                        switch(j.type)
                        {
                            case PrintArgumentType.Expression:
                                compileExpression(j.expression, s);
                                break;
                            case PrintArgumentType.Line:
                                genCodeImm(Value("\n"));
                                break;
                            case PrintArgumentType.Tab:
                                genCodeImm(Value("\t"));
                                break;
                            default:
                                break;
                        }
                    }
                    code ~= new PrintCode(print.args.length);
                }
                break;
            case NodeType.Assign:
                {
                    auto assign = cast(Assign)i;
                    compileExpression(assign.expression, s);
                    genCodePopVar(assign.name, s);
                }
                break;
            case NodeType.Label:
                {
                    auto label = cast(Label)i;
                    globalLabel[label.label] = code.length;
                }
                break;
            case NodeType.Goto:
                {
                    genCodeGoto((cast(Goto)i).label);
                }
                break;
            case NodeType.If:
                compileIf(cast(If)i, s);
                break;
            case NodeType.For:
                compileFor(cast(For)i, s);
                break;
            case NodeType.Gosub:
                {
                    auto gosub = cast(Gosub)i;
                    genCodeGosub(gosub.label);
                }
                break;
            case NodeType.Return:
                {
                    auto ret = cast(Return)i;
                    if(s.func is null)
                    {
                        if(ret.expression is null)
                            genCode(new ReturnSubroutine());
                        else
                            throw new SyntaxError();
                    }
                    else
                    {
                        //値を返せる関数
                        if(s.func.returnExpr)
                        {
                            compileExpression(ret.expression, s);
                            genCode(new ReturnFunction(s.func));
                        }
                        else
                        {
                            genCode(new ReturnFunction(s.func));
                        }
                    }
                }
                break;
            case NodeType.End:
                genCode(new EndVM());
                break;
            case NodeType.Break:
                if(s.breakAddr is null)
                {
                    //syntax-error
                    break;
                }
                genCode(s.breakAddr);
                break;
            case NodeType.Continue:
                if(s.continueAddr is null)
                {
                    //syntax-error
                    break;
                }
                genCode(s.continueAddr);
                break;
            case NodeType.Var:
                compileVar(cast(Var)i, s);
                break;
            case NodeType.ArrayAssign:
                {
                    auto assign = cast(ArrayAssign)i;
                    compileExpression(assign.assignExpression, s);
                    compileExpression(assign.indexExpression, s);
                    genCode(new PopArray(getGlobalVarIndex(assign.name), assign.indexExpression.expressions.length, !(s.func is null)));
                }
                break;
            case NodeType.CallFunctionStatement:
                {
                    auto func = cast(CallFunctionStatement)i;
                    auto bfun = otya.smilebasic.builtinfunctions.BuiltinFunction.builtinFunctions.get(func.name, null);
                    if(bfun)
                    {
                        int k = bfun.argments.length - func.args.length;
                        foreach(l;0..k)
                        {
                            genCodeImm(Value(ValueType.Void));
                        }
                    }
                    foreach_reverse(Expression j ; func.args)
                    {
                        compileExpression(j, s);
                    }
                    if(bfun)
                    {
                        genCode(new CallBuiltinFunction(bfun, func.args.length, func.outVariable.length));
                    }
                    else
                    {
                        genCode(new CallFunctionCode(func.name, func.args.length, func.outVariable.length));
                    }
                    //TODO:OUT
                    foreach_reverse(wstring var; func.outVariable)
                    {
                        genCodePopVar(var, s);
                    }
                }
                break;
            case NodeType.While:
                compileWhile(cast(While)i, s);
                break;
            default:
                stderr.writeln("Compile:NotImpl ", i.type);
        }
    }
    VM compile()
    {
        Scope s = new Scope();
        foreach(Statement i ; statements.statements)
        {
            if(i.type == NodeType.DefineFunction)
            {
                compileDefineFunction(cast(DefineFunction)i);
                continue;
            }
            compileStatement(i, s);
        }
        foreach(int i, Code c; code)
        {
            if(c.type == CodeType.GotoS)
            {
                code[i] = new GotoAddr(globalLabel[(cast(GotoS)c).label]);
            }
            if(c.type == CodeType.GosubS)
            {
                code[i] = new GosubAddr(globalLabel[(cast(GosubS)c).label]);
            }
        }
        return new VM(code, globalIndex + 1, global, functions);
    }
}

unittest
{
    import otya.smilebasic.parser;
    auto parser = new Parser("A=1+2+3+4*5/4-5+(6+6)*7");
    auto vm = parser.compile();
    vm.run();
    writeln(vm.testGetGlobalVariable("A").castDouble);
    assert(vm.testGetGlobalVariable("A").castDouble == 1+2+3+4*5/4-5+(6+6)*7);
}
