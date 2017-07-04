module otya.smilebasic.compiler;
import otya.smilebasic.node;
import otya.smilebasic.token;
import otya.smilebasic.vm;
import otya.smilebasic.type;
import otya.smilebasic.error;
import otya.smilebasic.systemvariable;
import std.stdio;
struct DebugData
{
    SourceLocation location;
    bool isBreakPoint;
}
class DebugInfo
{
    sizediff_t old;
    std.container.Array!DebugData location;
    std.container.Array!int line;
    this()
    {
    }
    void addLocation(SourceLocation loc, Code[] code)
    {
        while (line.length < loc.line)
        {
            import std.conv : to;
            line ~= location.length.to!int;
        }
        for(int i = 0; i < code.length - old; i++)
        {
            location ~= DebugData (loc, false);
        }
        old = location.length;
    }
    SourceLocation getLocationByAddress(int addr)
    {
        if(location.length <= addr) return SourceLocation(0, 0, 0);
        return location[addr].location;
    }
    void setBreakPoint(int line)
    {
        location[this.line[line - 1]].isBreakPoint = true;
    }
    bool isBreakPoint(int line)
    {
        return location[this.line[line - 1]].isBreakPoint;
    }
}
class Scope
{
    GotoAddr breakAddr;
    GotoAddr continueAddr;
    Function func;
    DataTable data;
    this()
    {
        this.data = new DataTable();
    }
    this(GotoAddr breakAddr, GotoAddr continueAddr, Scope parent)
    {
        this.breakAddr =  breakAddr;
        this.continueAddr = continueAddr;
        this.func = parent.func;
        this.data = parent.data;
    }
    this(Function func)
    {
        this();
        this.func = func;
        func.scope_ = this;
    }
}
class DataTable
{
    Value[] data;
    int[wstring] label;
    void addData(Value data)
    {
        this.data ~= data;
    }
    void addLabel(wstring label)
    {
        this.label[label] = cast(int)data.length;
    }
}
class Function
{
    static const frameSize = 4;
    int address;
    wstring name;
    int argCount;
    int argumentIndex;
    int variableIndex;
    VMVariable[wstring] variable;
    int[wstring] label;
    bool returnExpr;
    int outArgCount;
    Scope scope_;
    bool isCommon;
    VMSlot slot;
    bool isDead;
    /**
    0:bp
    1:pc
    2:data table(global)
    3:data index
    4:function pointer
    */
    this(int address, wstring name, bool returnExpr, int argCount, bool isCommon)
    {
        this.address = address;
        this.name = name;
        this.returnExpr = returnExpr;
        this.argCount = argCount;
        this.variableIndex = frameSize - 1;//1;//0,bp,1,pc
        if(returnExpr)
        {
            outArgCount = 1;
        }
        this.isCommon = isCommon;
    }
    int getLocalVarIndex(wstring name, Compiler c)
    {
        int var = this.variable.get(name, VMVariable()).index;
        if(var == 0)
        {
            //local変数をあたる
            //それでもだめならOPTION STRICTならエラー
            if (c.isStrictMode)
            {
                throw new UndefinedVariable();
            }
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
    bool isDirectMode;
    bool isDefint;
    bool isStrictMode;
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
                if (!isDefint)
                    return ValueType.Double;//非DEFINT時
                else
                    return ValueType.Integer;//DEFINT時
        }
    }
    Statements statements;
    DebugInfo debugInfo;
    this(Statements statements)
    {
        this.debugInfo = new DebugInfo;
        this.statements = statements;
        code = new Code[0];
        global["DATE$"] = VMVariable(-1);
        sysVariable["DATE$"] = new Date();
        global["TIME$"] = VMVariable(-1);
        sysVariable["TIME$"] = new Time();
        global["MAINCNT"] = VMVariable(-1);
        sysVariable["MAINCNT"] = new Maincnt();
        global["CSRX"] = VMVariable(-1);
        sysVariable["CSRX"] = new CSRX();
        global["CSRY"] = VMVariable(-1);
        sysVariable["CSRY"] = new CSRY();
        global["CSRZ"] = VMVariable(-1);
        sysVariable["CSRZ"] = new CSRZ();
        addSystemVariable("VERSION", new Version());
        addSystemVariable("FREEMEM", new FreeMem());
        addSystemVariable("TABSTEP", new TabStep());
        addSystemVariable("RESULT", new Result());
        addSystemVariable("HARDWARE", new Hardware());
        addSystemVariable("MILLISEC", new MilliSecond());
        addSystemVariable("PRGSLOT", new ProgramSlot());
        addSystemVariable("CALLIDX", new CallIndex());
    }
    void addSystemVariable(wstring name, SystemVariable var)
    {
        global[name] = VMVariable(-1);
        sysVariable[name] = var;
    }
    void registerSystemVariable(VM vm)
    {
        foreach(k, ref v; sysVariable)
        {
            v.vm = vm;
        }
    }
    SystemVariable[wstring] sysVariable;
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
    void genCodeImm(TokenValue value)
    {
        code ~= new Push(value.toSBImm);
    }
    void genCodePushGlobal(int ind)
    {
        code ~= new PushG(ind);
    }
    void genCodePopGlobal(int ind)
    {
        code ~= new PopG(ind);
    }
    SystemVariable getSystemVariable(wstring name)
    {
        auto var = sysVariable.get(name, null);
        return var;
    }
    void genCodePushSysVar(wstring name)
    {
        code ~= new PushSystemVariable(getSystemVariable(name));
    }
    void genCodePopSysVar(wstring name)
    {
        code ~= new PopSystemVariable(getSystemVariable(name));
    }
    void genCodePushVar(wstring name, Scope sc)
    {
        if(sc.func)
        {
            auto local = sc.func.hasLocalVarIndex(name);
            if(local)
            {
                code ~= new PushL(local);
                return;
            }
        }
        auto global = hasGlobalVarIndex(name);
        if(global)
        {
            if(global < 0)
            {
                genCodePushSysVar(name);
                return;
            }
            code ~= new PushG(global);
            return;
        }
        if(sc.func)
        {
            code ~= new PushL(sc.func.getLocalVarIndex(name, this));
            return;
        }
        code ~= new PushG(getGlobalVarIndex(name));
    }
    void genCodePushVarRef(wstring name, Scope sc)
    {
        if(sc.func)
        {
            auto local = sc.func.hasLocalVarIndex(name);
            if(local)
            {
                code ~= new PushLRef(local);
                return;
            }
        }
        auto global = hasGlobalVarIndex(name);
        if(global)
        {
            if(global < 0)
            {
                throw new SyntaxError();
            }
            code ~= new PushGRef(global);
            return;
        }
        if(sc.func)
        {
            code ~= new PushLRef(sc.func.getLocalVarIndex(name, this));
            return;
        }
        code ~= new PushGRef(getGlobalVarIndex(name));
    }
    void genCodePopVar(wstring name, Scope sc)
    {
        if(sc.func)
        {
            auto local = sc.func.hasLocalVarIndex(name);
            if(local)
            {
                code ~= new PopL(local);
                return;
            }
        }
        auto global = hasGlobalVarIndex(name);
        if(global)
        {
            if(global < 0)
            {
                genCodePopSysVar(name);
                return;
            }
            code ~= new PopG(global);
            return;
        }
        if(sc.func)
        {
            code ~= new PopL(sc.func.getLocalVarIndex(name, this));
            return;
        }
        code ~= new PopG(getGlobalVarIndex(name));
    }
    void getVarIndex(wstring name, Scope sc, out int index, out bool isLocal)
    {
        auto global = hasGlobalVarIndex(name);
        if(sc.func)
            isLocal = sc.func.hasLocalVarIndex(name) != 0;
        if(sc.func && isLocal)
        {
            index = sc.func.getLocalVarIndex(name, this);
            return;
        }
        if(global)
        {
            index = global;
            return;
        }
        index = getGlobalVarIndex(name);
    }
    void genCodeOP(TokenType op)
    {
        code ~= new Operate(op);
    }
    void genCodeGoto(wstring label, Scope sc)
    {
        code ~= new GotoS(label, sc);
    }
    void genCodeGosub(wstring label, Scope sc)
    {
        code ~= new GosubS(label, sc);
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
            if (isStrictMode)
            {
                throw new UndefinedVariable();
            }
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
            int local = sc.func.getLocalVarIndex(name, this);
            return local;
        }
        return 0;
    }
    void compileExpression(Expression exp, Scope sc)
    {
        if(!exp || exp.type == NodeType.VoidExpression)
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
                    if(binop.operator == TokenType.LogicalAnd)
                    {
                        compileExpression(binop.item1, sc);
                        auto jmp = new LogicalAnd();
                        genCode(jmp);
                        compileExpression(binop.item2, sc);
                        genCode(new ConvertBool());  
                        jmp.addr = cast(int)code.length;
                        break;
                    }
                    if (binop.operator == TokenType.LogicalOr)
                    {
                        compileExpression(binop.item1, sc);
                        auto jmp = new LogicalOr();
                        genCode(jmp);
                        compileExpression(binop.item2, sc);
                        jmp.addr = cast(int)code.length;
                        genCode(new ConvertBool());
                        break;
                    }
                    compileExpression(binop.item1, sc);
                    compileExpression(binop.item2, sc);
                    if(binop.operator == TokenType.LBracket)
                    {
                        IndexExpressions ie = cast(IndexExpressions)binop.item2;
                        if(ie)
                        {
                            genCode(new PushArray(cast(int)ie.expressions.length));
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
                    auto bfuns = otya.smilebasic.builtinfunctions.BuiltinFunction.builtinFunctions.get(func.name, null);
                    otya.smilebasic.builtinfunctions.BuiltinFunction bfun;
                    if(bfuns)
                    {
                        bfun = bfuns.overloadResolution(func.args.length, 1);
                        if(bfun.argments.length >= func.args.length)
                        {
                            auto k = bfun.argments.length - func.args.length;
                            foreach(l;0..k)
                            {
                                genCodeImm(Value(ValueType.Void));
                            }
                        }
                    }
                    foreach_reverse(Expression i ; func.args)
                    {
                        compileExpression(i, sc);
                    }
                    if(bfun)
                    {
                        genCode(new CallBuiltinFunction(bfun, cast(int)func.args.length, 1));
                    }
                    else if (func.name == "CALL")
                    {
                        if (func.args.length < 1)
                        {
                            throw new SyntaxError();
                        }
                        genCode(new CallFunctionS((cast(int)func.args.length) - 1, 1));
                    }
                    else
                    {
                        genCode(new CallFunctionCode(func.name, cast(int)func.args.length));
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
            case NodeType.VarRef:
                {
                    auto varref = cast(VarRef)exp;
                    compileExpression(varref.expression, sc);
                    genCode(new PushVarExpression());
                }
                break;
            default:
                stderr.writeln("Compile:NotImpl ", exp.type);
                break;
        }
    }
    void compilePushReference(Expression exp, Scope sc)
    {
        if(!exp)
        {
            genCodeImm(Value(ValueType.Void));
            return;
        }
        switch(exp.type)
        {
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
                            genCode(new PushArrayRef(cast(int)ie.expressions.length));
                        }
                        else
                        {
                            genCode(new PushArrayRef(1));
                        }
                        break;
                    }
                }
                break;
            case NodeType.Variable:
                auto var = cast(Variable)exp;
                genCodePushVarRef(var.name, sc);
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
            case NodeType.VarRef:
                {
                    auto varref = cast(VarRef)exp;
                    compileExpression(varref.expression, sc);
                    genCode(new PushVarRefExpression());
                }
                break;
            default:
                stderr.writeln("Compile:NotImpl ", exp.type);
                break;
        }
    }
    void compilePopVar(Expression expr, Scope sc)
    {
        switch(expr.type)
        {
            case NodeType.Variable:
                {
                    auto var = cast(Variable)expr;
                    genCodePopVar(var.name, sc);
                    //int index;
                    //bool local;
                    //getVarIndex(var.name, sc, index, local);
                    //genCode(local ? new PopL(index) : new PopG(index));
                }
                break;
            case NodeType.BinaryOperator:
                {
                    auto binop = cast(BinaryOperator)expr;
                    compileExpression(binop.item2, sc);
                    if(binop.operator == TokenType.LBracket)
                    {
                        IndexExpressions ie = cast(IndexExpressions)binop.item2;
                        auto var = cast(Variable)binop.item1;
                        int index;
                        bool local;
                        getVarIndex(var.name, sc, index, local);
                        if(ie)
                        {
                            genCode(new PopArray(index, cast(int)ie.expressions.length, local));
                        }
                        else
                        {
                            genCode(new PopArray(index, 1, local));
                        }
                        break;
                    }
                }
                goto default;
            case NodeType.VarRef:
                {
                    auto varref = cast(VarRef)expr;
                    compileExpression(varref.expression, sc);
                    genCode(new PopVarExpression());
                }
                break;
            case NodeType.VoidExpression:
                {
                    genCode(new Pop());
                }
                break;
            default:
                throw new SyntaxError();

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
        if (node.hasElseif)
        {
            then = genCodeGoto();
            else_.address = cast(int)code.length;
            GotoFalse else2;
            foreach(t; node.elseif)
            {
                compileExpression(t[1], sc);
                else2 = genCodeGotoFalse();
                compileStatements(t[0], sc);
                genCode(then);
                else2.address = cast(int)code.length;
            }
            if(node.hasElse)
                compileStatements(node.else_, sc);
            then.address = cast(int)code.length;
        }
        else if(node.hasElse)
        {
            then = genCodeGoto();
            else_.address = cast(int)code.length;
            compileStatements(node.else_, sc);
            then.address = cast(int)code.length;
        }
        else
        {
            //endifに飛ばす
            else_.address = cast(int)code.length;
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
        positiveZero.address = cast(int)code.length;
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
        forAddr.address = cast(int)code.length;
        s = new Scope(new GotoAddr(-1), new GotoAddr(-1), s);
        compileStatements(node.statements, s);
        s.continueAddr.address = cast(int)code.length;
        //counterに加算する
        genCodePushVar(node.initExpression.name, s);
        compileExpression(node.stepExpression, s);
        genCodeOP(TokenType.Plus);
        genCodePopVar(node.initExpression.name, s);
        genCodeGoto(cast(int)forstart);
        breakAddr.address = cast(int)code.length;
        s.breakAddr.address = cast(int)code.length;
    }
    void compileWhile(While node, Scope s)
    {
        auto whilestart = code.length;
        s = new Scope(new GotoAddr(-1), new GotoAddr(cast(int)whilestart), s);
        compileExpression(node.condExpression, s);
        auto breakAddr = genCodeGotoFalse();
        compileStatements(node.statements, s);
        genCode(s.continueAddr);
        s.breakAddr.address = cast(int)code.length;
        breakAddr.address = cast(int)code.length;
    }
    void compileRepeat(RepeatUntil node, Scope s)
    {
        auto start = cast(int)code.length;
        s = new Scope(new GotoAddr(-1), new GotoAddr(-1), s);
        compileStatements(node.statements, s);
        s.continueAddr.address = cast(int)code.length;
        compileExpression(node.condExpression, s);
        auto a = genCodeGotoFalse();
        a.address = start;
        s.breakAddr.address = cast(int)code.length;
    }
    void compileVar(Var node, Scope sc)
    {
        foreach(Statement v ; node.define)
        {
            if(v.type == NodeType.DefineVariable)
            {
                DefineVariable var = cast(DefineVariable)v;
                defineVarIndex(var.name, sc);
                if (var.expression)
                {
                    compileExpression(var.expression, sc);
                    genCodePopVar(var.name, sc);
                }
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
                genCode(new NewArray(getType(var.name), cast(int)var.dim.expressions.length));
                genCodePopVar(var.name, sc);
                continue;
            }
        }
    }
    void compileInc(Inc node, Scope sc)
    {
        compileExpression(node.expression, sc);
        compilePushReference(node.name, sc);
        genCode(new IncRef());
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
        if(isDirectMode)
        {
            throw new CantUseFromDirectMode();
        }
        auto skip = genCodeGoto();
        Function func = new Function(cast(int)this.code.length, node.name, node.returnExpr, cast(int)node.arguments.length, node.isCommon);
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
            func.outArgCount = cast(int)node.outArguments.length;
        compileStatements(node.functionBody, sc);
        if(func.returnExpr)
            genCodeImm(Value(ValueType.Void));
        genCode(new ReturnFunction(func));
        skip.address = cast(int)this.code.length;
        this.functions[func.name] = func;
    }
    void compileOn(On on, Scope sc)
    {
        compileExpression(on.condition, sc);
        genCode(new OnS(on.labels, on.isGosub, sc));
    }
    void compileInput(Input input, Scope sc)
    {
        if(input.question)
        {
            genCodeImm(Value("?\n"));
        }
        if(input.message)
        {
            compileExpression(input.message, sc);
        }
        genCode(new PrintCode((input.question ? 1 : 0) + (input.message ? 1 : 0)));
        foreach_reverse(i; input.variables)
        {
            compileExpression(i, sc);
        }
        genCode(new InputCode(cast(int)input.variables.length));
        foreach_reverse(i; input.variables)
        {
            compilePopVar(i, sc);
        }
    }
    void compileRead(Read read, Scope sc)
    {
        genCode(new ReadCode(cast(int)read.variables.length));
        foreach_reverse(i; read.variables)
        {
            compilePopVar(i, sc);
        }
    }
    void compileSwap(Swap swap, Scope sc)
    {
        compilePushReference(swap.item2, sc);
        compilePushReference(swap.item1, sc);
        genCode(new SwapCode());
    }
    void compileXOn(XOn x, Scope sc)
    {
        genCode(new SetX(x.func, true));
    }
    void compileXOff(XOff x, Scope sc)
    {
        genCode(new SetX(x.func, false));
    }
    void compileExec(otya.smilebasic.node.Exec exec, Scope sc)
    {
        compileExpression(exec.expression, sc);
        genCode(new otya.smilebasic.vm.Exec);
    }
    void compileUse(otya.smilebasic.node.Use use, Scope sc)
    {
        compileExpression(use.expression, sc);
        genCode(new otya.smilebasic.vm.Use);
    }
    void compileLinput(otya.smilebasic.node.Linput linput, Scope sc)
    {
        if (linput.hasGuide)
            compileExpression(linput.guide, sc);
        else
            genCodeImm(Value(""));
        genCode(new otya.smilebasic.vm.Linput);
        compilePopVar(linput.expression, sc);
    }
    void compileCallSprite(otya.smilebasic.node.CallSprite call, Scope sc)
    {
        genCode(new InitCallback);
        genCode(new otya.smilebasic.vm.CallSprite);
    }
    void compileCallBG(otya.smilebasic.node.CallBG call, Scope sc)
    {
        genCode(new InitCallback);
        genCode(new otya.smilebasic.vm.CallBG);
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
                    code ~= new PrintCode(cast(int)print.args.length);
                }
                break;
            case NodeType.Assign:
                {
                    auto assign = cast(Assign)i;
                    compileExpression(assign.expression, s);
                    genCodePopVar(assign.name, s);
                }
                break;
            case NodeType.AssignRef:
                {
                    auto assign = cast(AssignRef)i;
                    //right->left
                    compileExpression(assign.expression, s);
                    compilePushReference(assign.left, s);
                    genCode(new PopRererence());
                }
                break;
            case NodeType.Label:
                {
                    if (this.isDirectMode)
                    {
                        throw new CantUseFromDirectMode();
                    }
                    auto label = cast(Label)i;
                    if(s.func)
                    {
                        s.func.label[label.label] = cast(int)code.length;
                    }
                    else
                    {
                        globalLabel[label.label] = cast(int)code.length;
                    }
                    s.data.addLabel(label.label);
                }
                break;
            case NodeType.Goto:
                {
                    auto gotou = cast(Goto)i;
                    if(!gotou.label)
                    {
                        compileExpression(gotou.labelexpr, s);
                        genCode(new GotoExpr());
                    }
                    else
                    {
                        genCodeGoto(gotou.label, s);
                    }
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
                    if(gosub.label)
                    {
                        genCodeGosub(gosub.label, s);
                    }
                    else
                    {
                        compileExpression(gosub.labelexpr, s);
                        genCode(new GosubExpr());
                    }
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
                    int index;
                    bool local;
                    getVarIndex(assign.name, s, index, local);
                    genCode(new PopArray(index, cast(int)assign.indexExpression.expressions.length, local));
                }
                break;
            case NodeType.CallFunctionStatement:
                {
                    auto func = cast(CallFunctionStatement)i;
                    auto bfuns = otya.smilebasic.builtinfunctions.BuiltinFunction.builtinFunctions.get(func.name, null);
                    otya.smilebasic.builtinfunctions.BuiltinFunction bfun;
                    if(bfuns)
                    {
                        bfun = bfuns.overloadResolution(func.args.length, func.outVariable.length);
                        int k = cast(int)bfun.argments.length - cast(int)func.args.length;
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
                        genCode(new CallBuiltinFunction(bfun, cast(int)func.args.length, cast(int)bfun.results.length));//func.outVariable.length));
                    }
                    else if (func.name == "CALL")
                    {
                        genCode(new CallFunctionS((cast(int)func.args.length) - 1, cast(int)func.outVariable.length));
                    }
                    else
                    {
                        genCode(new CallFunctionCode(func.name, cast(int)func.args.length, cast(int)func.outVariable.length));
                    }
                    if(bfun)
                    {
                        int k = cast(int)bfun.results.length - cast(int)func.outVariable.length;
                        foreach(l;0..k)
                        {
                            genCode(new DecSP);
                        }
                    }
                    //TODO:OUT
                    foreach_reverse(var; func.outVariable)
                    {
                        compilePopVar(var, s);
                    }
                }
                break;
            case NodeType.While:
                compileWhile(cast(While)i, s);
                break;
            case NodeType.Inc:
                compileInc(cast(Inc)i, s);
                break;
            case NodeType.Data:
                {
                    auto data = cast(otya.smilebasic.node.Data)i;
                    foreach(j; data.data)
                        s.data.addData(j.toSBImm);
                }
                break;
            case NodeType.Read:
                compileRead(cast(Read)i, s);
                break;
            case NodeType.Restore:
                {
                    Restore restore = cast(Restore)i;
                    Expression label = restore.label;
                    if(label.type == NodeType.Constant)
                    {
                        Constant cons = cast(Constant)label;
                        if(cons.value.isString)
                        {
                            genCode(new RestoreCodeS(cons.value.stringValue, s));
                            break;
                            //文字列じゃないならば定数でも実行時エラー
                        }
                    }
                    compileExpression(label, s);
                    genCode(new RestoreExprCode(s.data));
                }
                break;
            case NodeType.On:
                compileOn(cast(On)i, s);
                break;
            case NodeType.Input:
                compileInput(cast(Input)i, s);
                break;
            case NodeType.RepeatUntil:
                compileRepeat(cast(RepeatUntil)i, s);
                break;
            case NodeType.Option:
                if(isDirectMode)
                {
                    throw new CantUseFromDirectMode();
                }
                else
                {
                    auto option = cast(Option)i;
                    if (option.argument == "STRICT")
                    {
                        isStrictMode = true;
                    }
                    else if (option.argument == "DEFINT")
                    {
                        isDefint = true;
                    }
                }
                break;
            case NodeType.Swap:
                compileSwap(cast(Swap)i, s);
                break;
            case NodeType.XOn:
                compileXOn(cast(XOn)i, s);
                break;
            case NodeType.XOff:
                compileXOff(cast(XOff)i, s);
                break;
            case NodeType.Exec:
                compileExec(cast(otya.smilebasic.node.Exec)i, s);
                break;
            case NodeType.Use:
                compileUse(cast(otya.smilebasic.node.Use)i, s);
                break;
            case NodeType.Linput:
                compileLinput(cast(otya.smilebasic.node.Linput)i, s);
                break;
            case NodeType.CallSprite:
                compileCallSprite(cast(otya.smilebasic.node.CallSprite)i, s);
                break;
            case NodeType.CallBG:
                compileCallBG(cast(otya.smilebasic.node.CallBG)i, s);
                break;
            default:
                stderr.writeln("Compile:NotImpl ", i.type);
        }
        this.debugInfo.addLocation(i.location, code);
    }
    Scope globalScope;
    Code[] compileProgram()
    {
        return compileProgram(new Scope());
    }
    Code[] compileProgram(Scope scope_)
    {
        Scope s = globalScope = scope_;
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
                auto label = cast(GotoS)c;
                if(label.sc.func)
                {
                    int addr = label.sc.func.label.get(label.label, int.min);
                    if (addr == int.min)
                    {
                        throw new UndefinedLabel(label.label);
                    }
                    code[i] = new GotoAddr(addr);
                }
                else
                {
                    int addr = globalLabel.get(label.label, int.min);
                    if (addr == int.min)
                    {
                        throw new UndefinedLabel(label.label);
                    }
                    code[i] = new GotoAddr(addr);
                }
            }
            if(c.type == CodeType.GosubS)
            {
                auto label = cast(GosubS)c;
                int addr;
                if(label.sc.func)
                {
                    addr = label.sc.func.label.get(label.label, int.min);
                }
                else
                {
                    addr = globalLabel.get(label.label, int.min);
                }
                if (addr == int.min)
                {
                    code[i] = new GosubUndefinedLabel(label.label);
                }
                else
                {
                    code[i] = new GosubAddr(addr);
                }
            }
            if(c.type == CodeType.OnS)
            {
                auto label = cast(OnS)c;
                int[] addresses = new int[label.labels.length];
                foreach(int index, wstring l; label.labels)
                {
                    if(label.sc.func)
                    {
                        addresses[index] = label.sc.func.label.get(l, int.min);
                    }
                    else
                    {
                        addresses[index] = globalLabel.get(l, int.min);
                    }
                }
                if(label.isGosub)
                {
                    code[i] = new OnGosub(addresses);
                }
                else
                {
                    code[i] = new OnGoto(addresses);
                }
            }
            if(c.type == CodeType.RestoreCodeS)
            {
                auto restore = cast(RestoreCodeS)c;
                auto label = restore.scope_.data.label.get(restore.label, int.min);
                if (label == int.min)
                {
                    code[i] = new RestoreUndefinedLabelCode(restore.label);
                }
                else
                {
                    code[i] = new RestoreCode(label, restore.scope_.data);
                }
            }
        }
        genCode(new EndVM());
        return code;
    }
    VM vm;
    void compileDirectMode(VM vm)
    {
        isDirectMode = true;
        global = vm.currentSlot.globalTable;
        auto start = vm.currentSlot.code.length;
        this.code = vm.currentSlot.code;
        globalIndex = cast(int)vm.currentSlot.global.length;
        functions = vm.currentSlot.functions;
        if (vm.currentFunction)
        {
            auto sc = new Scope(vm.currentFunction);
            sc.data = vm.currentData.table;
            compileProgram(sc);
        }
        else
            compileProgram();
        registerSystemVariable(vm);
        vm.directSlot(start, code, globalIndex + 1, global, functions, globalScope.data, globalLabel, debugInfo);
    }
    VM compile()
    {
        isDirectMode = false;
        VM vm = new VM();
        this.vm = vm;
        compileProgram();
        vm.loadSlot(0, code, globalIndex + 1, global, functions, globalScope.data, globalLabel, debugInfo);
        vm.setCurrentSlot(0);
        registerSystemVariable(vm);
        return vm;
    }
    void compile(VM vm, int slot)
    {
        isDirectMode = false;
        this.vm = vm;
        compileProgram();
        vm.loadSlot(slot, code, globalIndex + 1, global, functions, globalScope.data, globalLabel, debugInfo);
        registerSystemVariable(vm);
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
