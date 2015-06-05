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
    void pop(out Value value)
    {
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
                    //type missmatch
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
            default:
                writeln("NotImpl: ", operator);
                break;
        }
        l.integerValue = cast(int)ld;
        vm.push(l);
    }
}
class Goto : Code
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
class Gosub : Code
{

}
