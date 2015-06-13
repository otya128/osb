module otya.smilebasic.vm;
import otya.smilebasic.type;
import otya.smilebasic.token;
import otya.smilebasic.error;
import otya.smilebasic.compiler;
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
    int[wstring] globalTable;
    Function[wstring] functions;
    int bp;
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
                return ValueType.Double;//DEFINT時
        }
    }
    this(Code[] code, int len, int[wstring] globalTable, Function[wstring] functions)
    {
        this.code = code;
        this.stack = new Value[16384];
        this.global = new Value[len];
        this.globalTable = globalTable;
        foreach(wstring k, int v ; globalTable)
        {
            this.global[v] = Value(getType(k));
        }
        this.functions = functions;
    }
    void run()
    {
        bp = 0;//globalを実行なのでbaseは0(グローバル変数をスタックに取るようにしない限り)
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
    bool canPop()
    {
        return stacki > bp;
    }
    void pop(out Value value)
    {
        if(stacki <= bp)
        {
            writeln("Stack underflow");
            readln();
        }
        value = stack[--stacki];
    }
    Value testGetGlobalVariable(wstring name)
    {
        return global[globalTable[name]];
    }
    void end()
    {
        pc = code.length;
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
    GosubS,
    ReturnSubroutine,
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
                case ValueType.Double:
                    write(arg.doubleValue);
                    break;
                case ValueType.String:
                    write(arg.stringValue);
                    break;
                default:
                    //type mismatch
                    throw new TypeMismatch();
            }
        }
        stdout.flush();
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
        Value v;
        Value g = vm.global[var];
        vm.pop(v);
        if(v.type == ValueType.Integer && g.type == ValueType.Double)
        {
            vm.global[var] = Value(cast(double)v.integerValue);
            return;
        }
        if(g.type == ValueType.Integer && v.type == ValueType.Double)
        {
            vm.global[var] = Value(cast(int)v.doubleValue);
            return;
        }
        if(v.type == ValueType.Void)
        {
            vm.global[var] = v;
            return;
        }
        if(v.type != g.type)
        {
            throw new TypeMismatch();
        }
        vm.global[var] = v;
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
        int ri = r.integerValue;
        double rd = r.integerValue;
        bool numf = r.type == ValueType.Double || r.type == ValueType.Integer; 
        if(r.type == ValueType.Double)
        {
            ri = cast(int)r.doubleValue;
            rd = r.doubleValue;
        }
        switch(operator)
        {
            //単項演算子
            case TokenType.Not:
                if(numf)
                    vm.push(Value(~ri));
                else
                    throw new TypeMismatch();
                return;
            case TokenType.LogicalNot:
                if(numf)
                    vm.push(Value(!ri));
                else
                    throw new TypeMismatch();
                return;
            default:
                break;
        }
        vm.pop(l);
        if(l.type == ValueType.IntegerArray)
            //l.type == ValueType.StringArray || l.type == ValueType.DoubleArray)
        {
            if(operator != TokenType.LBracket)
            {
                throw new TypeMismatch();
            }
            vm.push(Value(l.integerArray[ri]));
            return;
        }
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
                        throw new TypeMismatch();
                }
            }
            if(r.type == ValueType.Integer || r.type == ValueType.Double)
            {
                switch(operator)
                {
                    //数値 * 文字列だとエラー
                    case TokenType.Mul:
                        {
                            wstring delegate(wstring, wstring, int) mul;
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
                    case TokenType.LBracket:
                        vm.push(Value(ls[ri].to!wstring));
                        return;
                    default:
                        //type mismatch
                        throw new TypeMismatch();
                }
            }
        }
        int li = l.integerValue;
        double ld = l.integerValue;
        if(l.type == ValueType.Double)
        {
            li = cast(int)l.doubleValue;
            ld = l.doubleValue;
        }
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
            case TokenType.IntDiv:
                //TODO:範囲外だとOverflow
                vm.push(Value(cast(int)(ld / rd)));
                return;
            case TokenType.Mod:
                ld %= rd;
                break;
            case TokenType.And:
                vm.push(Value(li & ri));
                return;
            case TokenType.Or:
                vm.push(Value(li | ri));
                return;
            case TokenType.LogicalAnd:
                vm.push(Value(li && ri));
                return;
            case TokenType.LogicalOr:
                vm.push(Value(li || ri));
                return;
            case TokenType.Xor:
                vm.push(Value(li ^ ri));
                return;
            case TokenType.Equal:
                vm.push(Value(li == ri));
                return;
            case TokenType.NotEqual:
                vm.push(Value(li != ri));
                return;
            case TokenType.Less:
                vm.push(Value(li < ri));
                return;
            case TokenType.LessEqual:
                vm.push(Value(li <= ri));
                return;
            case TokenType.Greater:
                vm.push(Value(li > ri));
                return;
            case TokenType.GreaterEqual:
                vm.push(Value(li >= ri));
                return;
            case TokenType.LeftShift:
                vm.push(Value(li << ri));
                return;
            case TokenType.RightShift:
                vm.push(Value(li >> ri));
                return;
            default:
                writeln("NotImpl: ", operator);
                break;
        }
        l.type = ValueType.Double;
        l.doubleValue = ld;
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
class GosubAddr : Code
{
    int address;
    this(int addr)
    {
        this.type = CodeType.Gosub;
        address = addr;
    }
    override void execute(VM vm)
    {
        vm.push(Value(vm.pc));
        vm.pc = address - 1;
    }
}
class GosubS : Code
{
    wstring label;
    this(wstring label)
    {
        this.type = CodeType.GosubS;
        this.label = label;
    }
    override void execute(VM vm)
    {
        stderr.writeln("can't execute");
    }
}
class ReturnSubroutine : Code
{
    this()
    {
        this.type = CodeType.ReturnSubroutine;
    }
    override void execute(VM vm)
    {
        Value pc;
        if(!vm.canPop())
        {
            throw new ReturnWithoutGosub();
        }
        vm.pop(pc);
        if(pc.type != ValueType.Integer || pc.integerValue < 0 || pc.integerValue >= vm.code.length)
        {
            stderr.writeln("Internal error:Compiler bug?");
            readln();
            return;
        }
        vm.pc = pc.integerValue;
    }
}
class EndVM : Code
{
    this()
    {
    }
    override void execute(VM vm)
    {
        vm.end();
    }
}
class NewArray : Code
{
    ValueType type;
    int index;
    int size;
    int[] dim;
    this(ValueType type, int size, int index)
    {
        dim = new int[size];
        this.size = size;
        this.type = type;
        this.index = index;
    }
    override void execute(VM vm)
    {
        for(int i = size - 1; i >= 0; i--)
        {
            Value v;
            vm.pop(v);
            if(v.type == ValueType.Double)
            {
                dim[i] = cast(int)v.doubleValue;
                continue;
            }
            if(v.type == ValueType.Integer)
            {
                dim[i] = v.integerValue;
                continue;
            }
            throw new TypeMismatch();
        }
        switch(type)
        {
            case ValueType.Integer:
                vm.global[index].type = ValueType.IntegerArray;
                vm.global[index].integerArray = new Array!int(dim);
                break;
            case ValueType.Double:
                vm.global[index].type = ValueType.DoubleArray;
                vm.global[index].doubleArray = new Array!double(dim);
                break;
            case ValueType.String:
                vm.global[index].type = ValueType.StringArray;
                vm.global[index].stringArray = new Array!wstring(dim);
                break;
            default:
                throw new TypeMismatch();
                break;
        }
    }
}
class PushArray : Code
{
    int dim;
    this(int dim)
    {
        this.dim = dim;
    }
    override void execute(VM vm)
    {
        int[4] index;
        for(int i = 0; i < dim; i++)
        {
            Value v;
            vm.pop(v);
            if(v.type == ValueType.Integer)
            {
                index[i] = v.integerValue;
                continue;
            }
            if(v.type == ValueType.Double)
            {
                index[i] = cast(int)v.doubleValue;
                continue;
            }
            throw new TypeMismatch();
        }
        Value array;
        vm.pop(array);
        if(!array.isArray)
        {
            throw new TypeMismatch();
        }
        if(array.type == ValueType.IntegerArray)
        {
            vm.push(Value(array.integerArray[index[0..dim]]));
            return;
        }
        if(array.type == ValueType.DoubleArray)
        {
            vm.push(Value(array.doubleArray[index[0..dim]]));
            return;
        }
        if(array.type == ValueType.StringArray)
        {
            vm.push(Value(array.stringArray[index[0..dim]]));
            return;
        }
        if(array.type == ValueType.String)
        {
            if(dim != 1)
            {
                //TODO:syntaxError
                throw new TypeMismatch();
            }
            vm.push(Value(array.stringValue[index[0]].to!wstring));
            return;
        }
        throw new TypeMismatch();
    }
}
class PopGArray : Code
{
    int var;
    int dim;
    this(int var, int dim)
    {
        this.var = var;
        this.dim = dim;
    }
    override void execute(VM vm)
    {
        Value array = vm.global[var];
        if(!array.isArray)
        {
            throw new TypeMismatch();
        }
        int[4] index;
        for(int i = 0; i < dim; i++)
        {
            Value v;
            vm.pop(v);
            if(v.type == ValueType.Integer)
            {
                index[i] = v.integerValue;
                continue;
            }
            if(v.type == ValueType.Double)
            {
                index[i] = cast(int)v.doubleValue;
                continue;
            }
            throw new TypeMismatch();
        }
        Value assign;
        vm.pop(assign);
        if(array.type == ValueType.IntegerArray && assign.isNumber)
        {
            array.integerArray[index[0..dim]] = assign.castInteger();
            return;
        }
        if(array.type == ValueType.DoubleArray && assign.isNumber)
        {
            array.doubleArray[index[0..dim]] = assign.castDouble();
            return;
        }
        if(array.type == ValueType.StringArray && assign.type == ValueType.String)
        {
            array.stringArray[index[0..dim]] = assign.stringValue;
            return;
        }
        if(array.type == ValueType.String && assign.type == ValueType.String)
        {
            if(dim != 1)
            {
                //TODO:syntaxError
                throw new TypeMismatch();
            }
            //TODO:文字列の挙動
            throw new TypeMismatch();
            //array.stringValue[index[0]] = assign.stringValue[0];
            return;
        }
        throw new TypeMismatch();
    }
}
class ReturnFunction : Code
{
    Function func;
    this(Function func)
    {
        this.func = func;
    }
    override void execute(VM vm)
    {
        int oldstacki = vm.stacki;
        vm.stacki = vm.bp + 2;
        Value bp, pc;
        vm.pop(pc);
        vm.pop(bp);
        vm.push(Value(235));
        vm.pc = pc.integerValue;
        vm.bp = bp.integerValue;
    }
}
class CallFunctionCode : Code
{
    wstring name;
    int argCount;
    this(wstring name, int argCount)
    {
        this.name = name;
        this.argCount = argCount;
    }
    override void execute(VM vm)
    {
        Function func = vm.functions[name];
        if(!func)
        {
            throw new SyntaxError();
        }
        if(func.argCount != this.argCount)
        {
            throw new IllegalFunctionCall();
        }
        //TODO:args
        vm.push(Value(vm.bp));
        vm.push(Value(vm.pc));
        vm.bp = vm.stacki - 2;
        vm.pc = func.address - 1;
    }
}
