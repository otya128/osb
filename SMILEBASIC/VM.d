module otya.smilebasic.vm;
import otya.smilebasic.type;
import otya.smilebasic.token;
import otya.smilebasic.error;
import otya.smilebasic.compiler;
import otya.smilebasic.petitcomputer;
import std.uni;
import std.utf;
import std.conv;
import std.stdio;
struct VMVariable
{
    int index;
    ValueType type;
    this(int index, ValueType type)
    {
        this.index = index;
        this.type = type;
    }
}
class VM
{
    Code[] code;
    int stacki;
    int pc;
    Value[] stack;
    Value[] global;
    VMVariable[wstring] globalTable;
    Function[wstring] functions;
    int bp;
    PetitComputer petitcomputer;
    this(Code[] code, int len, VMVariable[wstring] globalTable, Function[wstring] functions)
    {
        this.code = code;
        this.stack = new Value[16384];
        this.global = new Value[len];
        this.globalTable = globalTable;
        foreach(wstring k, VMVariable v ; globalTable)
        {
            this.global[v.index] = Value(v.type);
        }
        this.functions = functions;
    }
    void run()
    {
        bp = 0;//globalを実行なのでbaseは0(グローバル変数をスタックに取るようにしない限り)(挙動的にスタックに確保していなさそう)
        for(pc = 0; pc < this.code.length; pc++)
        {
            code[pc].execute(this);
        }
        if(stacki != 0)
        {
            stderr.writeln("CompilerBug?:stack");
        }
    }
    void init(PetitComputer petitcomputer)
    {
        this.petitcomputer = petitcomputer;
        bp = 0;//globalを実行なのでbaseは0(グローバル変数をスタックに取るようにしない限り)(挙動的にスタックに確保していなさそう)
    }
    bool runStep()
    {
        if(pc < this.code.length)
        {
            code[pc].execute(this);
            pc++;
            return true;
        }
        return false;
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
        return global[globalTable[name].index];
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
    PushL,
    Operate,
    Return,
    Goto,
    Gosub,
    Print,
    PopG,
    PopL,
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
                    if(vm.petitcomputer)
                        vm.petitcomputer.printConsole(arg.integerValue);
                    break;
                case ValueType.Double:
                    write(arg.doubleValue);
                    if(vm.petitcomputer)
                        vm.petitcomputer.printConsole(arg.doubleValue);
                    break;
                case ValueType.String:
                    write(arg.stringValue);
                    if(vm.petitcomputer)
                        vm.petitcomputer.printConsole(arg.stringValue);
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
        if(g.type == ValueType.Void)
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
class PushL : Code
{
    int var;
    this(int var)
    {
        this.type = CodeType.PushL;
        this.var = var;
    }
    override void execute(VM vm)
    {
        vm.push(vm.stack[vm.bp + var]);
    }
}
class PopL : Code
{
    int var;
    this(int var)
    {
        this.type = CodeType.PopL;
        this.var = var;
    }
    override void execute(VM vm)
    {
        Value v;
        Value g = vm.stack[vm.bp + var];
        vm.pop(v);
        if(v.type == ValueType.Integer && g.type == ValueType.Double)
        {
            vm.stack[vm.bp + var] = Value(cast(double)v.integerValue);
            return;
        }
        if(g.type == ValueType.Integer && v.type == ValueType.Double)
        {
            vm.stack[vm.bp + var] = Value(cast(int)v.doubleValue);
            return;
        }
        if(g.type == ValueType.Void)
        {
            vm.stack[vm.bp + var] = v;
            return;
        }
        if(v.type != g.type)
        {
            throw new TypeMismatch();
        }
        vm.stack[vm.bp + var] = v;
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
    int size;
    int[] dim;
    this(ValueType type, int size)
    {
        dim = new int[size];
        this.size = size;
        this.type = type;
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
        Value array;
        switch(type)
        {
            case ValueType.Integer:
                array.type = ValueType.IntegerArray;
                array.integerArray = new Array!int(dim);
                break;
            case ValueType.Double:
                array.type = ValueType.DoubleArray;
                array.doubleArray = new Array!double(dim);
                break;
            case ValueType.String:
                array.type = ValueType.StringArray;
                array.stringArray = new Array!wstring(dim);
                break;
            default:
                throw new TypeMismatch();
                break;
        }
        vm.push(array);
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
class PopArray : Code
{
    int var;
    int dim;
    bool local;
    this(int var, int dim, bool local)
    {
        this.var = var;
        this.dim = dim;
        this.local = local;
    }
    override void execute(VM vm)
    {
        Value array;
        if(local)
        {
            array = vm.stack[vm.bp + var];
        }
        else
        {
            array = vm.global[var];
        }
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
        Value retexpr;
        if(func.returnExpr)
        {
            vm.pop(retexpr);
        }
        vm.stacki = vm.bp + 2;
        Value bp, pc;
        vm.pop(pc);
        vm.pop(bp);
        vm.stacki -= func.argCount;
        if(func.returnExpr)
        {
            vm.push(retexpr);
        }
        else
        {
            //OUTの実装
            for(int i = 0; i < func.outArgCount; i++)
            {
                vm.push(vm.stack[vm.bp + i + 2]);
            }
        }
        vm.pc = pc.integerValue;
        vm.bp = bp.integerValue;
    }
}
class CallFunctionCode : Code
{
    wstring name;
    int argCount;
    int outArgCount;
    this(wstring name, int argCount)
    {
        this.name = name;
        this.argCount = argCount;
        this.outArgCount = 1;
    }
    this(wstring name, int argCount, int outArgCount)
    {
        this.name = name;
        this.argCount = argCount;
        this.outArgCount = outArgCount;
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
        if(func.outArgCount != this.outArgCount)
        {
            throw new IllegalFunctionCall();
        }
        //TODO:args
        auto bp = vm.stacki;
        vm.push(Value(vm.bp));
        vm.push(Value(vm.pc));
        vm.bp = bp;
        vm.pc = func.address - 1;
        vm.stacki += func.variableIndex - 1;
        foreach(wstring k, VMVariable v ; func.variable)
        {
            if(v.index > 0)
            {
                vm.stack[bp + v.index] = Value(v.type);
            }
        }
    }
}
import otya.smilebasic.builtinfunctions;
class CallBuiltinFunction : Code
{
    BuiltinFunction func;
    int argcount;
    int outcount;
    this(BuiltinFunction func, int argcount, int outcount/+可変長引数用+/)
    {
        this.func = func;
        this.argcount = argcount;
        this.outcount = outcount;
    }
    override void execute(VM vm)
    {
        Value[] arg;
        Value[] result;
        if(func.hasSkipArgument)
        {
            arg = vm.stack[vm.stacki - func.argments.length..vm.stacki];
            result = vm.stack[vm.stacki - func.argments.length..vm.stacki - func.argments.length + outcount];//雑;
        }
        else
        {
            arg = vm.stack[vm.stacki - argcount..vm.stacki];
            result = vm.stack[vm.stacki - argcount..vm.stacki - argcount + outcount];//雑;
        }
        func.func(vm.petitcomputer, arg, result);
    }
}
