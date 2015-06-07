module otya.smilebasic.vm;
import otya.smilebasic.type;
import otya.smilebasic.token;
import std.uni;
import std.utf;
import std.conv;
import std.stdio;
class VM
{
    Code[] code;
    int stacki;
    int pc;
    Value[] stack;
    Value[] global;
    int[wstring] debugTable;
    this(Code[] code, int len, int[wstring] debugTable)
    {
        this.code = code;
        this.stack = new Value[1024 * 1024];
        this.global = new Value[len];
        this.debugTable = debugTable;
    }
    void run()
    {
        for(pc = 0; pc < this.code.length; pc++)
        {
            code[pc].execute(this);
        }
    }
    void push(ref Value value)
    {
        stack[stacki++] = value;
    }
    void push(Value value)
    {
        stack[stacki++] = value;
    }
    void pop(out Value value)
    {
        if(stacki <= 0)
        {
            writeln("Stack underflow");
            readln();
        }
        value = stack[--stacki];
    }
    Value testGetGlobaVariable(wstring name)
    {
        return global[debugTable[name]];
    }
}
enum CodeType
{
    Push,
    PushG,
    Operate,
    Return,
    Goto,
    Gosub,
    Print,
    PopG,
    GotoS,
    GotoFalse,
    GotoTrue,
}
abstract class Code
{
    CodeType type;
    abstract void execute(VM vm);
}
class PrintCode : Code
{
    int count;
    this(int count)
    {
        this.type = CodeType.Print;
        this.count = count;
    }
    override void execute(VM vm)
    {
        for(int i = 0;i < count; i++)
        {
            Value arg;
            vm.pop(arg);
            switch(arg.type)
            {
                case ValueType.Integer:
                    write(arg.integerValue);
                    break;
                case ValueType.String:
                    write(arg.stringValue);
                    break;
                default:
                    //type mismatch
                    break;
            }
        }
    }
}
/*
* スタックにPush
*/
class Push : Code
{
    Value imm;
    this(Value imm)
    {
        this.type = CodeType.Push;
        this.imm = imm;
    }
    override void execute(VM vm)
    {
        vm.push(imm);
    }
}

class PushG : Code
{
    int var;
    this(int var)
    {
        this.type = CodeType.PushG;
        this.var = var;
    }
    override void execute(VM vm)
    {
        vm.push(vm.global[var]);
    }
}
class PopG : Code
{
    int var;
    this(int var)
    {
        this.type = CodeType.PopG;
        this.var = var;
    }
    override void execute(VM vm)
    {
        vm.pop(vm.global[var]);
    }
}
class Operate : Code
{
    TokenType operator;
    this(TokenType op)
    {
        this.operator = op;
    }

    override void execute(VM vm)
    {
        Value l;
        Value r;
        vm.pop(r);
        vm.pop(l);
        if(l.type == ValueType.String)
        {
            wstring ls = l.stringValue;
            if(r.type == ValueType.String)
            {
                wstring rs = r.stringValue;
                switch(operator)
                {
                    case TokenType.Plus:
                        vm.push(Value(ls ~ rs));
                        return;
                    case TokenType.Equal:
                        vm.push(Value(ls == rs));
                        return;
                    case TokenType.NotEqual:
                        vm.push(Value(ls != rs));
                        return;
                    case TokenType.Less:
                        vm.push(Value(ls < rs));
                        return;
                    case TokenType.LessEqual:
                        vm.push(Value(ls <= rs));
                        return;
                    case TokenType.Greater:
                        vm.push(Value(ls > rs));
                        return;
                    case TokenType.GreaterEqual:
                        vm.push(Value(ls >= rs));
                        return;
                    default:
                        //type mismatch
                        stderr.writeln("Type mismatch");
                        return;
                }
            }
            if(r.type == ValueType.Integer || r.type == ValueType.Double)
            {
                double rd = r.integerValue;
                switch(operator)
                {
                    //数値 * 文字列だとエラー
                    case TokenType.Mul:
                        {
                            wstring delegate(wstring x, wstring y, int num) mul;
                            mul = (x, y, z) => z > 0 ? x ~ mul(x , y, z - 1) : "";
                            vm.push(Value(mul(ls, ls, cast(int)rd)));
                        }
                        return;
                    //3.1から?文字列と数値を比較すると3を返す
                    //(数値 compare 文字列だとエラー)
                    case TokenType.Equal:
                    case TokenType.NotEqual:
                    case TokenType.Less:
                    case TokenType.LessEqual:
                    case TokenType.Greater:
                    case TokenType.GreaterEqual:
                        vm.push(Value(3));
                        return;
                    default:
                        //type mismatch
                        stderr.writeln("Type mismatch");
                        return;
                }
            }
        }
        int li = l.integerValue;
        int ri = r.integerValue;
        double ld = l.integerValue;
        double rd = r.integerValue;
        //とりあえずInteger
        switch(operator)
        {
            case TokenType.Plus:
                ld += rd;
                break;
            case TokenType.Minus:
                ld -= rd;
                break;
            case TokenType.Mul:
                ld *= rd;
                break;
            case TokenType.Div:
                ld /= rd;
                break;
            case TokenType.Mod:
                ld %= rd;
                break;
            case TokenType.And:
                ld = li & ri;
                break;
            case TokenType.Or:
                ld = li | ri;
                break;
            case TokenType.Xor:
                ld = li ^ ri;
                break;
            case TokenType.Equal:
                ld = ld == rd;
                break;
            case TokenType.NotEqual:
                ld = ld != rd;
                break;
            case TokenType.Less:
                ld = ld < rd;
                break;
            case TokenType.LessEqual:
                ld = ld <= rd;
                break;
            case TokenType.Greater:
                ld = ld > rd;
                break;
            case TokenType.GreaterEqual:
                ld = ld >= rd;
                break;
            default:
                writeln("NotImpl: ", operator);
                break;
        }
        l.integerValue = cast(int)ld;
        vm.push(l);
    }
}
class GotoAddr : Code
{
    int address;
    this(int addr)
    {
        this.type = CodeType.Goto;
        address = addr;
    }
    override void execute(VM vm)
    {
        vm.pc = address - 1;
    }
}
class GotoS : Code
{
    wstring label;
    this(wstring label)
    {
        this.type = CodeType.GotoS;
        this.label = label;
    }
    override void execute(VM vm)
    {
        stderr.writeln("can't execute");
    }
}
class GotoTrue : Code
{
    int address;
    this(int addr)
    {
        this.type = CodeType.GotoTrue;
        address = addr;
    }
    override void execute(VM vm)
    {
        Value cond;
        vm.pop(cond);
        if(cond.boolValue)
            vm.pc = address - 1;
    }
}
class GotoFalse : Code
{
    int address;
    this(int addr)
    {
        this.type = CodeType.GotoFalse;
        address = addr;
    }
    override void execute(VM vm)
    {
        Value cond;
        vm.pop(cond);
        if(!cond.boolValue)
            vm.pc = address - 1;
    }
}
class Gosub : Code
{

}
