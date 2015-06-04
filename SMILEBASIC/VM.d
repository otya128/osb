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
    Value[] stack;
    this(Code[] code)
    {
        this.code = code;
        this.stack = new Value[1024 * 1024];
    }
    void run()
    {
        for(int i = 0; i < this.code.length; i++)
        {
            code[i].execute(this);
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
}
enum CodeType
{
    Push,
    Operate,
    Return,
    Goto,
    Gosub,
    Print,
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
                    write(arg.stringValue.to!string);
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
        vm.pop(l);
        vm.pop(r);
        //とりあえずInteger
        l.integerValue += r.integerValue;
        vm.push(l);
    }
}
class Goto : Code
{

}
class Gosub : Code
{

}
