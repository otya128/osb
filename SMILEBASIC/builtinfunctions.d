module otya.smilebasic.builtinfunctions;

import std.conv;
import std.typecons;
import std.typetuple;
import std.traits;
import std.stdio;
import std.ascii;
import std.range;
import otya.smilebasic.error;
import otya.smilebasic.type;
import otya.smilebasic.petitcomputer;
import otya.smilebasic.sprite;
//プチコンの引数省略は特殊なので
//LOCATE ,,0のように省略できる
struct DefaultValue(T, bool skippable = true)
{
    T value;
    bool isDefault;
    this(T v, bool f)
    {
        value = v;
        isDefault = f;
    }
    this(T v)
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
    bool variadic;
    this(BuiltinFunctionArgument[] argments, ValueType result, void function(PetitComputer, Value[], Value[]) func, int startskip,
         bool variadic)
    {
        this.argments = argments;
        this.result = result;
        this.func = func;
        this.startskip = startskip;
        this.variadic = variadic;
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
    static double function(double) SGN = &sgn!double;
    static double SIN(double arg1)
    {
        return sin(arg1);
    }
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
    static int BUTTON(PetitComputer p, DefaultValue!(int, false) mode)
    {
        return p.button;
    }
    static void VISIBLE(PetitComputer p, DefaultValue!(int) console, DefaultValue!(int) graphic, DefaultValue!(int) BG, DefaultValue!(int) sprite)
    {
    }
    static void XSCREEN(PetitComputer p, int mode, DefaultValue!(int, false) a, DefaultValue!(int, false) b)
    {
    }
    static void DISPLAY(PetitComputer p, DefaultValue!(int, false) display)
    {
    }
    static void GCLS(PetitComputer p, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.gcolor);
        p.gfill(p.useGRP, 0, 0, 511, 511, cast(int)color);
    }
    static void GPSET(PetitComputer p, int x, int y, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.gcolor);
        p.gpset(p.useGRP, x, y, cast(int)color);
    }
    static void GLINE(PetitComputer p, int x, int y, int x2, int y2, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.gcolor);
        p.gline(p.useGRP, x, y, x2, y2, cast(int)color);
    }
    static void GBOX(PetitComputer p, int x, int y, int x2, int y2, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.gcolor);
        p.gbox(p.useGRP, x, y, x2, y2, cast(int)color);
    }
    static void GFILL(PetitComputer p, int x, int y, int x2, int y2, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.gcolor);
        p.gfill(p.useGRP, x, y, x2, y2, cast(int)color);
    }
    static void GCOLOR(PetitComputer p, int color)
    {
        p.gcolor = color;
    }
    static void GPRIO(PetitComputer p, int z)
    {
    }
    static void BGMPLAY(PetitComputer p, int music)
    {
    }
    static void BEEP(PetitComputer p, DefaultValue!(int, false) beep, DefaultValue!(int, false) pitch, DefaultValue!(int, false) volume, DefaultValue!(int, false) pan)
    {
    }
    static void STICK(PetitComputer p, DefaultValue!(int, false) mp, out int x, out int y)
    {
        //JOYSTICK?
        x = 0;
        y = 0;
    }
    static int RGB(int R, int G, int B, DefaultValue!(int, false) _)
    {
        if(!_.isDefault)
        {
            //やや強引なオーバーロード
            return PetitComputer.RGB(cast(ubyte)R, cast(ubyte)G, cast(ubyte)B, cast(ubyte)_);
        }
        return PetitComputer.RGB(cast(ubyte)R, cast(ubyte)G, cast(ubyte)B);
    }
    static int RND(int max)
    {
        import std.random;
        return uniform(0, max - 1);
    }
    static void DTREAD(DefaultValue!(wstring, false) date, out int Y, out int M, out int D/*W*/)
    {
        import std.datetime;
        auto currentTime = Clock.currTime();
        if(date.isDefault)
        {
            Y = currentTime.year;
            M = currentTime.month;
            D = currentTime.day;
        }
        else
        {
            import std.format;
            auto v = date.value;
            formattedRead(v, "%d/%d/%d", &Y, &M, &D);
        }
    }
    //hairetuha?
    static int LEN(wstring str)
    {
        return str.length;
    }
    static double VAL(wstring str)
    {
        if(str[0..2] == "&H")
        {
            return str[2..$].to!int(16);
        }
        double val = str.to!double;
        return val;
    }
    static double FLOOR(double val)
    {
        return val.floor;
    }
    static wstring MID(wstring str, int i, int len)
    {
        //挙動未定
        return str[i..i + len];
    }
    static void SPSET(PetitComputer p, int id, int defno)
    {
        p.sprite.spset(id, defno);
    }
    static void SPHIDE(PetitComputer p, int id)
    {
        p.sprite.sphide(id);
    }
    static void SPSHOW(PetitComputer p, int id)
    {
        p.sprite.spshow(id);
    }
    static void SPOFS(PetitComputer p, int id, int x, int y, DefaultValue!(int, false) z)
    {
        p.sprite.spofs(id, x, y);
    }
    static void SPANIM(PetitComputer p, Value[] va_args)
    {
        writeln("NOTIMPL:SPANIM");
        auto args = retro(va_args);
        int no = args[0].castInteger;
        double[] animdata = new double[args.length - 2];
        int i;
        foreach(a; args[2..$])
        {
            animdata[i++] = a.castDouble;
        }
        if(args[1].isString)
            p.sprite.spanim(no, args[1].castString, animdata);
        if(args[1].isNumber)
            p.sprite.spanim(no, cast(SpriteAnimTarget)(args[1].castInteger), animdata);
    }
    static void BGMSTOP(PetitComputer p)
    {
        writeln("NOTIMPL:BGMSTOP");
    }
    static int BGMCHK(PetitComputer p)
    {
        writeln("NOTIMPL:BGMCHK");
        return false;
    }
    static int CHKCHR(PetitComputer p, int x, int y)
    {
        return cast(int)(p.console[y][x].character);
    }
    static wstring FORMAT(PetitComputer p, Value[] va_args)
    {
        alias retro!(Value[]) VaArgs;
        auto args = retro(va_args);
        auto format = args[0].castString;
        import std.array : appender;
        import std.format;
        import std.string;
        auto w = appender!wstring();
        int j = 1;
        for(int i = 0; i < format.length; i++)
        {
            auto f = format[i];
            if(f == '%')
            {
                int d = indexOf(format, 'D', CaseSensitive.yes);
                if(d != -1)
                {
                    auto spec = singleSpec(format[i .. d + 1]);
                    spec.spec = 'd';
                    formatValue(w, args[j].castInteger, spec);
                    j++;
                    i = d;
                    continue;
                }
                d = indexOf(format, 'X', CaseSensitive.yes);
                if(d != -1)
                {
                    auto spec = singleSpec(format[i .. d + 1]);
                    spec.spec = 'x';
                    formatValue(w, args[j].castDouble, spec);
                    j++;
                    i = d;
                    continue;
                }
                d = indexOf(format, 'S', CaseSensitive.yes);
                if(d != -1)
                {
                    auto spec = singleSpec(format[i .. d + 1]);
                    spec.spec = 's';
                    formatValue(w, args[j].castString, spec);
                    j++;
                    i = d;
                    continue;
                }
                d = indexOf(format, 'F', CaseSensitive.yes);
                if(d != -1)
                {
                    auto spec = singleSpec(format[i .. d + 1]);
                    spec.spec = 'f';
                    formatValue(w, args[j].castDouble, spec);
                    j++;
                    i = d;
                    continue;
                }
            }
            w ~= f;
        }
        //プチコン互換FOMA
        return cast(immutable)w.data();
    }
    static wstring CHR(int code)
    {
        return (cast(wchar)code).to!wstring;
    }
    static double POW(double a1, double a2)
    {
        return a1 ^^ a2;
    }
    static double SQR(double a1)
    {
        return sqrt(a1);
    }
    static void TALK(wstring a1)
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
                pragma(msg, AddFunc!(BuiltinFunction, name));
                wstring suffix = "";
                if(is(ReturnType!(__traits(getMember, BuiltinFunction, name)) == wstring))
                {
                    suffix = "$";
                }
                builtinFunctions[name ~ suffix] = new BuiltinFunction(
                                                                  GetFunctionParamType!(BuiltinFunction, name),
                                                                  GetFunctionReturnType!(BuiltinFunction, name),
                                                                  mixin(AddFunc!(BuiltinFunction, name)),
                                                                  GetStartSkip!(BuiltinFunction, name),
                                                                  IsVariadic!(BuiltinFunction, name),
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
    else static if(is(ReturnType!(__traits(getMember, T, N)) == int))
    {
        enum GetFunctionReturnType = ValueType.Integer;
    }
    else static if(is(ReturnType!(__traits(getMember, T, N)) == void))
    {
        enum GetFunctionReturnType = ValueType.Void;
    }
    else static if(is(ReturnType!(__traits(getMember, T, N)) == wstring))
    {
        enum GetFunctionReturnType = ValueType.String;
    }
    else
    {
        enum GetFunctionReturnType = ValueType.Void;
        static assert(false, "Invalid type");
    }
}
template AddFunc(T, string N)
{
    static if(is(ReturnType!(__traits(getMember, T, N)) == double) || is(ReturnType!(__traits(getMember, T, N)) == int))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall();}ret[0] = Value(" ~ N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(T,N) - 1, 0, 0, 0, T, N
                        , ParameterTypeTuple!(__traits(getMember, T, N))) ~ "));}";
    }
    else static if(is(ReturnType!(__traits(getMember, T, N)) == void))
    {

        pragma(msg, GetArgumentCount!(T,N));
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){/*if(ret.length != 0){throw new IllegalFunctionCall();}*/" ~ OutArgsInit!(T,N) ~ N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(T,N) - 1, 0, 0, 0, T, N,
                        ParameterTypeTuple!(__traits(getMember, T, N))) ~ ");}";
    }
    else static if(is(ReturnType!(__traits(getMember, T, N)) == wstring))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall();}ret[0] = Value(" ~ N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(T,N) - 1, 0, 0, 0, T, N
                        , ParameterTypeTuple!(__traits(getMember, T, N))) ~ "));}";
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
DefaultValue!wstring fromStringToDefault(Value v)
{
    if(v.type == ValueType.String)
        return DefaultValue!wstring(v.castString());
    else
        return DefaultValue!wstring(true);
}
DefaultValue!(wstring, false) fromStringToSkip(Value v)
{
    if(v.type == ValueType.String)
        return DefaultValue!(wstring, false)(v.castString());
    else
        return DefaultValue!(wstring, false)(true);
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
            else static if(is(P[0] == DefaultValue!(wstring)))
            {
                const string arg = "ValueType.String, false";
            }
            else static if(is(P[0] == DefaultValue!(wstring, false)))
            {
                const string arg = "ValueType.String, true";
            }
            else static if(is(P[0] == Value[]))
            {
                const string arg = "";
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
template AddFuncArg(int L, int N, int M, int O, T, string NAME, P...)
{
    enum I = L - N;
    enum storage = ParameterStorageClassTuple!(__traits(getMember, T, NAME))[M];
    static if(is(P[0] == double))
    {
        enum add = 1;
        enum outadd = 0;
        const string arg = "arg[" ~ I.to!string ~ "].castDouble";
    }
    else static if(is(P[0] == PetitComputer))
    {
        enum add = 0;
        enum outadd = 0;
        const string arg = "p";
    }
    else static if(is(P[0] == int))
    {
        static if(storage & ParameterStorageClass.out_)
        {
            enum add = 0;
            enum outadd = 1;
            const string arg = "ret[" ~ O.to!string ~ "].integerValue";
        }
        else
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "arg[" ~ I.to!string ~ "].castInteger";
        }
    }
    else static if(is(P[0] == wstring))
    {
        enum add = 1;
        enum outadd = 0;
        const string arg = "arg[" ~ I.to!string ~ "].castString";
    }
    else static if(is(P[0] == DefaultValue!int))
    {
        enum add = 1;
        enum outadd = 0;
        const string arg = "fromIntToDefault(arg[" ~ I.to!string ~ "])";
    }
    else static if(is(P[0] == DefaultValue!(int, false)))
    {
        enum add = 1;
        enum outadd = 0;
        const string arg = "fromIntToSkip(arg[" ~ I.to!string ~ "])";
    }
    else static if(is(P[0] == DefaultValue!wstring))
    {
        enum add = 1;
        enum outadd = 0;
        const string arg = "fromStringToDefault(arg[" ~ I.to!string ~ "])";
    }
    else static if(is(P[0] == DefaultValue!(wstring, false)))
    {
        enum add = 1;
        enum outadd = 0;
        const string arg = "fromStringToSkip(arg[" ~ I.to!string ~ "])";
    }
    else static if(is(P[0] == Value[]))
    {
        const string arg = "arg";
    }
    else
    {
        enum add = 1;
        enum outadd = 0;
        static assert(false, "Invalid type");
        const string arg = "";
    }
    static if(1 == P.length)
    {
        const string AddFuncArg = arg;
    }
    else
    {
        const string AddFuncArg = arg ~ ", " ~ AddFuncArg!(L - !add, N + add, M + 1, O + outadd, T, NAME, P[1..$]);
    }
}
template OutArgsInit(T, string N, int I = 0, int J = 0)
{
    enum tuple = ParameterStorageClassTuple!(__traits(getMember, T, N))[I];
    alias param = ParameterTypeTuple!(__traits(getMember, T, N));
    static if(!param.length)
    {
        enum OutArgsInit = "";
    }
    else
    {
        static if(tuple & ParameterStorageClass.out_)
        {
            enum add = 1;
            enum ret1 = "ret[" ~ J.to!string ~ "].type = ";
            static if(is(param[I] == int))
            {
                enum ret2 = "ValueType.Integer;";
            }
            enum result = ret1 ~ ret2;
        }
        else
        {
            enum add = 0;
            enum result = "";
        }
        static if(param.length > I + 1)
        {
            enum OutArgsInit = result ~ OutArgsInit!(T, N, I + 1, J + add);
        }
        else
        {
            enum OutArgsInit = result;
        }
    }
}
template GetArgumentCount(T, string N, int I = 0)
{
    enum tuple = ParameterStorageClassTuple!(__traits(getMember, T, N))[I];
    alias param = ParameterTypeTuple!(__traits(getMember, T, N));
    static if(is(param[I] == PetitComputer))
    {
        enum add = 0 + 1;
    }
    else
    {
        static if(tuple & ParameterStorageClass.out_)
        {
            enum add = 0;
        }
        else
        {
            enum add = 1;
        }
    }
    static if(param.length > I + 1)
    {
        enum GetArgumentCount = add + GetArgumentCount!(T, N, I + 1);
    }
    else
    {
        enum GetArgumentCount = add;
    }
}
template IsVariadic(T, string N, int I = 0)
{
    alias param = ParameterTypeTuple!(__traits(getMember, T, N));
    static if(param.length == 0 || param.length <= I)
    {
        enum IsVariadic = false;
    }
    else static if(is(param[I] == Value[]))
    {
        enum IsVariadic = true;
    }
    else
    {
        enum IsVariadic = IsVariadic!(T, N, I + 1);
    }
}

