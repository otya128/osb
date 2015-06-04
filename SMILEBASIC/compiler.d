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
    void genCodeImm(Value value)
    {
        code ~= new Push(value);
    }
    void genCodeOP(TokenType op)
    {
        code ~= new Operate(op);
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
                default:
                    stderr.writeln("Compile:NotImpl ", i.type);
            }
        }
        return new VM(code);
    }
}
