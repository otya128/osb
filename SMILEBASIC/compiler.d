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
    this()
    {
    }
    this(GotoAddr breakAddr, GotoAddr continueAddr)
    {
        this.breakAddr =  breakAddr;
        this.continueAddr = continueAddr;
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
    int[wstring] global;
    int[wstring] globalLabel;
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
        int global = this.global.get(name, 0);
        if(global == 0)
        {
            this.global[name] = global = ++globalIndex;
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
        int global = this.global.get(name, 0);
        if(global == 0)
        {
            //local変数をあたる
            //それでもだめならOPTION STRICTならエラー
            this.global[name] = global = ++globalIndex;
        }
        return global;
    }
    void compileExpression(Expression exp)
    {

        switch(exp.type)
        {
            case NodeType.Constant:
                genCodeImm((cast(Constant)exp).value);
                break;
            case NodeType.BinaryOperator:
                {
                    auto binop = cast(BinaryOperator)exp;
                    compileExpression(binop.item1);
                    compileExpression(binop.item2);
                    genCodeOP(binop.operator);
                }
                break;
            case NodeType.UnaryOperator:
                {
                    auto una = cast(UnaryOperator)exp;
                    compileExpression(una.item);
                    genCodeOP(una.operator);
                }
                break;
            case NodeType.Variable:
                auto var = cast(Variable)exp;
                genCodePushGlobal(getGlobalVarIndex(var.name));
                break;
            case NodeType.CallFunction:
                {
                    auto func = cast(CallFunction)exp;
                    if(func.name == "ADD")
                    {
                        foreach_reverse(Expression i ; func.args)
                        {
                            compileExpression(i);
                        }
                    }
                }
                break;
            case NodeType.IndexExpressions://[expr,expr,expr,expr]用
                {
                    auto index = cast(IndexExpressions)exp;
                    int count = 0;
                    foreach_reverse(Expression i; index.expressions)
                    {
                        compileExpression(i);
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
        compileExpression(node.condition);
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
        compileExpression(node.stepExpression);
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
        compileExpression(node.toExpression);
        genCodePushGlobal(getGlobalVarIndex(node.initExpression.name));
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
        compileExpression(node.toExpression);
        genCodePushGlobal(getGlobalVarIndex(node.initExpression.name));
        genCodeOP(TokenType.Less);
        genCode(breakAddr);
        forAddr.address = code.length;
        s = new Scope(new GotoAddr(-1), new GotoAddr(-1));
        compileStatements(node.statements, s);
        s.continueAddr.address = code.length;
        //counterに加算する
        genCodePushGlobal(getGlobalVarIndex(node.initExpression.name));
        compileExpression(node.stepExpression);
        genCodeOP(TokenType.Plus);
        genCodePopGlobal(getGlobalVarIndex(node.initExpression.name));
        genCodeGoto(forstart);
        breakAddr.address = code.length;
        s.breakAddr.address = code.length;
    }
    void compileVar(Var node, Scope sc)
    {
        foreach(Statement v ; node.define)
        {
            if(v.type == NodeType.DefineVariable)
            {
                DefineVariable var = cast(DefineVariable)v;
                //TODO:local variable
                defineGlobalVarIndex(var.name);
                continue;
            }
            if(v.type == NodeType.DefineArray)
            {
                DefineArray var = cast(DefineArray)v;
                int siz = 0;
                foreach_reverse(Expression expr; var.dim)
                {
                    compileExpression(expr);
                    siz++;
                    if(siz == 4)
                        break;//4次元まで(パーサーで除去するけど万が一に備えて
                }
                genCode(new NewArray(getType(var.name), var.dim.length, defineGlobalVarIndex(var.name)));
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
                                compileExpression(j.expression);
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
                    compileExpression(assign.expression);
                    genCodePopGlobal(getGlobalVarIndex(assign.name));
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
                    if(ret.expression is null)
                        genCode(new ReturnSubroutine());
                    else
                    {
                        //関数未実装:error
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
                    compileExpression(assign.assignExpression);
                    compileExpression(assign.indexExpression);
                    genCode(new PopGArray(getGlobalVarIndex(assign.name), assign.indexExpression.expressions.length));
                }
            default:
                stderr.writeln("Compile:NotImpl ", i.type);
        }
    }
    VM compile()
    {
        Scope s = new Scope();
        foreach(Statement i ; statements.statements)
        {
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
        return new VM(code, globalIndex + 1, global);
    }
}

unittest
{
    import otya.smilebasic.parser;
    auto parser = new Parser("A=1+2+3+4*5/4-5+(6+6)*7");
    auto vm = parser.compile();
    vm.run();
    writeln(vm.testGetGlobalVariable("A").integerValue);
    assert(vm.testGetGlobalVariable("A").integerValue == 1+2+3+4*5/4-5+(6+6)*7);
}
