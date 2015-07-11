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
struct DefaultValue(T)
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
    mixin Proxy!value;
}
alias ValueType = otya.smilebasic.type.ValueType;
struct BuiltinFunctionArgument
{
    ValueType argType;
    bool optionalArg;
}
class BuiltinFunction
{
    BuiltinFunctionArgument[] argments;
    ValueType result;
    void function(PetitComputer, Value[], Value[]) func;
    this(BuiltinFunctionArgument[] argments, ValueType result, void function(PetitComputer, Value[], Value[]) func)
    {
        this.argments = argments;
        this.result = result;
        this.func = func;
    }
    import std.math;
    /*
    static pure double ABS(double a, double b)
    {
        return a < 0 ? -a : a;
    }*/
    static ABS = function(double x) => abs(x);
    static void LOCATE(PetitComputer p, DefaultValue!int x, DefaultValue!int y, DefaultValue!int z)
    {
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
                                                                  mixin(AddFunc!(BuiltinFunction, name))
                                                                  );
                writeln(AddFunc!(BuiltinFunction, name));
            }
        }
    }

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
            AddFuncArg!(0, 0, ParameterTypeTuple!(__traits(getMember, T, N))) ~ "));}";
    }
    else static if(is(ReturnType!(__traits(getMember, T, N)) == void))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall();}" ~ N ~ "(" ~
            AddFuncArg!(0, 0, ParameterTypeTuple!(__traits(getMember, T, N))) ~ ");}";
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
template GetFunctionParamType(T, string N)
{
    enum GetFunctionParamType = mixin("[" ~ Array!(ParameterTypeTuple!(__traits(getMember, T, N))) ~ "]");
    private template Array(P...)
    {
        static if(is(P[0] == double))
        {
            const string arg = "ValueType.Double, false";
        }
        else static if(is(P[0] == int))
        {
            const string arg = "ValueType.Integer, false";
        }
        else static if(is(P[0] == DefaultValue!int))
        {
            const string arg = "ValueType.Integer, true";
        }
        else static if(is(P[0] == PetitComputer))
        {
            enum Array = Array!(P[1..$]);
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
template AddFuncArg(int N, int M, P...)
{
    static if(is(P[0] == double))
    {
        enum add = 1;
        const string arg = "arg[" ~ N.to!string ~ "].castDouble";
    }
    else static if(is(P[0] == PetitComputer))
    {
        enum add = 0;
        const string arg = "p";
    }
    else static if(is(P[0] == int))
    {
        enum add = 1;
        const string arg = "arg[" ~ N.to!string ~ "].castInteger";
    }
    else static if(is(P[0] == DefaultValue!int))
    {
        enum add = 1;
        const string arg = "fromIntToDefault(arg[" ~ N.to!string ~ "])";
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
        const string AddFuncArg = arg ~ ", " ~ AddFuncArg!(N + add, M + 1, P[1..$]);
    }
}
