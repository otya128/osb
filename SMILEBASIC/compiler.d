module otya.smilebasic.compiler;
import otya.smilebasic.node;
import otya.smilebasic.token;
import otya.smilebasic.vm;
import otya.smilebasic.type;
import std.stdio;
class Compiler
{
    Statements statements;
    this(Statements statements)
    {
        this.statements = statements;
        code = new Code[0];
    }

    Code[] code;
    int[wstring] global;
    int globalIndex = 0;
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
    int defineGlobalVarIndex(wstring name)
    {
        int global = this.global.get(name, 0);
        if(global == 0)
        {
            this.global[name] = ++globalIndex = global;
        }
        else
        {
            //error:二重定義
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
            this.global[name] = ++globalIndex = global;
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
            default:
                break;
        }
    }
    VM compile()
    {
        foreach(Statement i ; statements.statements)
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
                default:
                    stderr.writeln("Compile:NotImpl ", i.type);
            }
        }
        return new VM(code, globalIndex + 1);
    }
}
