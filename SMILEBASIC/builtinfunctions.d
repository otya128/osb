module otya.smilebasic.builtinfunctions;

import std.conv;
import std.typecons;
import std.typetuple;
import std.traits;
import std.stdio;
import std.ascii;
import otya.smilebasic.error;
import otya.smilebasic.type;
import otya.smilebasic.petitcomputer;
//プチコンの引数省略は特殊なので
//LOCATE ,,0のように省略できる
struct DefaultValue(T, bool skippable = true)
{
    T value;
    bool isDefault;
    this(int v, bool f)
    {
        value = v;
        isDefault = f;
    }
    this(int v)
    {
        value = v;
        isDefault = false;
    }
    this(bool f)
    {
        isDefault = f;
    }
    void setDefaultValue(T v)
    {
        if(isDefault)
            value = v;
    }
    mixin Proxy!value;
}
alias ValueType = otya.smilebasic.type.ValueType;
struct BuiltinFunctionArgument
{
    ValueType argType;
    bool optionalArg;
    bool skipArg;
}
class BuiltinFunction
{
    BuiltinFunctionArgument[] argments;
    ValueType result;
    void function(PetitComputer, Value[], Value[]) func;
    int startskip;
    this(BuiltinFunctionArgument[] argments, ValueType result, void function(PetitComputer, Value[], Value[]) func, int startskip)
    {
        this.argments = argments;
        this.result = result;
        this.func = func;
        this.startskip = startskip;
    }
    bool hasSkipArgument()
    {
        return this.startskip != this.argments.length;
    }
    import std.math;
    /*
    static pure double ABS(double a)
    {
        return a < 0 ? -a : a;
    }*/
    static double function(double) ABS = &abs!double;
    //static ABS = function double(double x) => abs(this.result == ValueType.Double ? 1 : 0);
    static void LOCATE(PetitComputer p, DefaultValue!int x, DefaultValue!int y, DefaultValue!(int, false) z)
    {
        x.setDefaultValue(p.CSRX);
        y.setDefaultValue(p.CSRY);
        z.setDefaultValue(p.CSRZ);
        p.CSRX = cast(int)x;
        p.CSRY = cast(int)y;
        p.CSRZ = cast(int)z;
    }
    static void COLOR(PetitComputer p, DefaultValue!int fore, DefaultValue!(int, false) back)
    {
        fore.setDefaultValue(p.consoleForeColor);
        back.setDefaultValue(p.consoleBackColor);
        p.consoleForeColor = cast(int)fore;
        p.consoleBackColor = cast(int)back;
    }
    static void VSYNC(PetitComputer p, DefaultValue!int time)
    {
        time.setDefaultValue(1);
        p.vsync(cast(int)time);
    }
    //TODO:プチコンのCLSには引数の個数制限がない
    static void CLS(PetitComputer p/*vaarg*/)
    {
        p.cls;
    }
    static void ASSERT__(PetitComputer p, int cond, wstring message)
    {
        if(!cond)
        {
            p.printConsole("Assertion failed: ", message, "\n");
        }
        assert(cond, message.to!string);
    }
    //alias void function(PetitComputer, Value[], Value[]) BuiltinFunc;
    static BuiltinFunction[wstring] builtinFunctions;
    static this()
    {
        foreach(name; __traits(derivedMembers, BuiltinFunction))
        {
            writeln(name);
            static if(/*__traits(isStaticFunction, __traits(getMember, BuiltinFunction, name)) && */name[0].isUpper)
            {
                builtinFunctions[name] = new BuiltinFunction(
                                                                  GetFunctionParamType!(BuiltinFunction, name),
                                                                  GetFunctionReturnType!(BuiltinFunction, name),
                                                                  mixin(AddFunc!(BuiltinFunction, name)),
                                                                  GetStartSkip!(BuiltinFunction, name),
                                                                  );
                writeln(AddFunc!(BuiltinFunction, name));
            }
        }
    }

}
template GetStartSkip(T, string N)
{
    private template SkipSkip(int I, P...)
    {
        static if(P.length <= I)
        {
            enum SkipSkip = I - is(P[0] == PetitComputer);
        }
        else static if(is(P[I] == DefaultValue!(int, false)))
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else
        {
            enum SkipSkip = SkipSkip!(I + 1, P);
        }
    }
    enum GetStartSkip = SkipSkip!(0, ParameterTypeTuple!(__traits(getMember, T, N)));
}
template GetFunctionReturnType(T, string N)
{
    static if(is(ReturnType!(__traits(getMember, T, N)) == double))
    {
        enum GetFunctionReturnType = ValueType.Double;
    }
    else static if(is(ReturnType!(__traits(getMember, T, N)) == void))
    {
        enum GetFunctionReturnType = ValueType.Void;
    }
    else
    {
        enum GetFunctionReturnType = ValueType.Void;
        static assert(false, "Invalid type");
    }
}
template AddFunc(T, string N)
{
    static if(is(ReturnType!(__traits(getMember, T, N)) == double))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall();}ret[0] = Value(" ~ N ~ "(" ~
            AddFuncArg!(ParameterTypeTuple!(__traits(getMember, T, N)).length - 1, 0, 0, ParameterTypeTuple!(__traits(getMember, T, N))) ~ "));}";
    }
    else static if(is(ReturnType!(__traits(getMember, T, N)) == void))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 0){throw new IllegalFunctionCall();}" ~ N ~ "(" ~
            AddFuncArg!(ParameterTypeTuple!(__traits(getMember, T, N)).length - 1, 0, 0, ParameterTypeTuple!(__traits(getMember, T, N))) ~ ");}";
    }
    else
    {
        const string AddFunc = "";
        static assert(false, "Invalid type");
    }
}
DefaultValue!int fromIntToDefault(Value v)
{
    if(v.isNumber)
        return DefaultValue!int(v.castInteger());
    else
        return DefaultValue!int(true);
}
DefaultValue!(int, false) fromIntToSkip(Value v)
{
    if(v.isNumber)
        return DefaultValue!(int, false)(v.castInteger());
    else
        return DefaultValue!(int, false)(true);
}
template GetFunctionParamType(T, string N)
{
    enum GetFunctionParamType = mixin("[" ~ Array!(ParameterTypeTuple!(__traits(getMember, T, N))) ~ "]");
    private template Array(P...)
    {
        static if(P.length == 0)
        {
            const string arg = "";
            enum Array = "";
        }
        else
        {
            static if(is(P[0] == double))
            {
                const string arg = "ValueType.Double, false";
            }
            else static if(is(P[0] == int))
            {
                const string arg = "ValueType.Integer, false";
            }
            else static if(is(P[0] == wstring))
            {
                const string arg = "ValueType.String, false";
            }
            else static if(is(P[0] == DefaultValue!int))
            {
                const string arg = "ValueType.Integer, true";
            }
            else static if(is(P[0] == DefaultValue!(int, false)))
            {
                const string arg = "ValueType.Integer, true";
            }
            else static if(is(P[0] == PetitComputer))
            {
                static if(P.length != 0)
                {
                    enum Array = Array!(P[1..$]);
                }
                else
                {
                    enum Array = "";
                }
            }
            static if(1 == P.length && !is(P[0] == PetitComputer))
            {
                enum Array = "BuiltinFunctionArgument(" ~ arg ~ ")";
            }
            else static if(!is(P[0] == PetitComputer))
            {
                enum Array = "BuiltinFunctionArgument(" ~ arg ~ ")," ~ Array!(P[1..$]);
            }
        }
    }
}
template AddFuncArg(int L, int N, int M, P...)
{
    enum I = L - N;
    static if(is(P[0] == double))
    {
        enum add = 1;
        const string arg = "arg[" ~ I.to!string ~ "].castDouble";
    }
    else static if(is(P[0] == PetitComputer))
    {
        enum add = 0;
        const string arg = "p";
    }
    else static if(is(P[0] == int))
    {
        enum add = 1;
        const string arg = "arg[" ~ I.to!string ~ "].castInteger";
    }
    else static if(is(P[0] == wstring))
    {
        enum add = 1;
        const string arg = "arg[" ~ I.to!string ~ "].castString";
    }
    else static if(is(P[0] == DefaultValue!int))
    {
        enum add = 1;
        const string arg = "fromIntToDefault(arg[" ~ I.to!string ~ "])";
    }
    else static if(is(P[0] == DefaultValue!(int, false)))
    {
        enum add = 1;
        const string arg = "fromIntToSkip(arg[" ~ I.to!string ~ "])";
    }
    else
    {
        enum add = 1;
        static assert(false, "Invalid type");
        const string arg = "";
    }
    static if(1 == P.length)
    {
        const string AddFuncArg = arg;
    }
    else
    {
        const string AddFuncArg = arg ~ ", " ~ AddFuncArg!(L - !add, N + add, M + 1, P[1..$]);
    }
}
