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
import otya.smilebasic.vm;
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
struct StartOptional
{
    const char[] name;
}
alias ValueType = otya.smilebasic.type.ValueType;
struct BuiltinFunctionArgument
{
    ValueType argType;
    bool optionalArg;
    bool skipArg;
}
//オーバーロード用
class BuiltinFunctions
{
    private BuiltinFunction[] func;
    this(BuiltinFunction f)
    {
        func = new BuiltinFunction[1];
        func[0] = f;
    }
    void addFunction(BuiltinFunction func)
    {
        this.func ~= func;
    }
    BuiltinFunction overloadResolution(int argc, int outargc)
    {
        BuiltinFunction va;
        //とりあえず引数の数で解決させる,というよりコンパイル時に型を取得する方法がない
        foreach(f; func)
        {
            if(f.startskip <= argc && f.argments.length >= argc && f.outoptional <= outargc && f.results.length >= outargc)
                return f;
            if(f.variadic)
                va = f;
        }
        //一応可変長は最後
        if(va) return va;
        writeln("====function overloads===");
        foreach(f; func)
        {
            writefln("name=\"%s\", argments=%s, results = %s, variadic = %s, startoptional = %d, function pointer=%s", f.name, f.argments, f.results, f.variadic, f.startskip, f.func);
        }
        //引数数ちがうのは実行前にエラー
        throw new IllegalFunctionCall(func[0].name);
    }
}
alias DefaultValue!(int, false) optionalint;
alias DefaultValue!(int, false) optionaldouble;
alias DefaultValue!(int, false) optionalstring;
/**
ここに関数を定義すればコンパイル時にBuiltinFunctionに変換してくれる便利なクラス
*/
class BuiltinFunction
{
    BuiltinFunctionArgument[] argments;
    BuiltinFunctionArgument[] results;
    void function(PetitComputer, Value[], Value[]) func;
    int startskip;
    int outoptional;
    bool variadic;
    string name;
    this(BuiltinFunctionArgument[] argments, BuiltinFunctionArgument[] results, void function(PetitComputer, Value[], Value[]) func, int startskip,
         bool variadic, string name, int outoptional)
    {
        this.argments = argments;
        this.results = results;
        this.func = func;
        this.startskip = startskip;
        this.variadic = variadic;
        this.name = name;
        this.outoptional = outoptional;
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
    //static double function(double) ABS = &abs!double;
    //static double function(double) SGN = &sgn!double;
    static double ABS(double arg1)
    {
        return abs(arg1);
    }
    static double SGN(double arg1)
    {
        return sgn(arg1);
    }
    static double SIN(double arg1)
    {
        return sin(arg1);
    }
    static double ASIN(double arg1)
    {
        return asin(arg1);
    }
    static double SINH(double arg1)
    {
        return sinh(arg1);
    }
    static double COS(double arg1)
    {
        return cos(arg1);
    }
    static double ACOS(double arg1)
    {
        return acos(arg1);
    }
    static double COSH(double arg1)
    {
        return cosh(arg1);
    }
    static double TAN(double arg1)
    {
        return tan(arg1);
    }
    static double ATAN(double arg1, DefaultValue!(double, false) arg2)
    {
        if(arg2.isDefault)
        {
            return atan(arg1);
        }
        return atan2(arg1, cast(double)arg2);
    }
    static double TANH(double arg1)
    {
        return tanh(arg1);
    }
    static double RAD(double arg1)
    {
        return arg1 * std.math.PI / 180;
    }
    static double DEG(double arg1)
    {
        return arg1 * 180 / std.math.PI;
    }
    static double PI()
    {
        return std.math.PI;
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
    static void WAIT(PetitComputer p, DefaultValue!int time)
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
    static int BUTTON(PetitComputer p, DefaultValue!(int, false) mode, DefaultValue!(int, false) mp)
    {
        if(!mp.isDefault)
        {
            writeln("NOTIMPL:BUTTON(ID, MPID)");
        }
        return p.button;
    }
    static void VISIBLE(PetitComputer p, DefaultValue!(int) console, DefaultValue!(int) graphic, DefaultValue!(int) BG, DefaultValue!(int) sprite)
    {
    }
    static void XON(PetitComputer p, Value mode/*!?!???!?*/)
    {
    }
    static void XOFF(PetitComputer p, Value mode/*!?!???!?*/)
    {
    }
    static void TOUCH(PetitComputer p, DefaultValue!(int, false) id, out int tm, out int tchx, out int tchy)
    {
        if(!id.isDefault)
        {
            writeln("NOTIMPL:TOUCH MPID");
        }
        tm = 0;
        tchx = 0;
        tchy = 0;
    }
    static void XSCREEN(PetitComputer p, int mode, DefaultValue!(int, false) a, DefaultValue!(int, false) b)
    {
        a.setDefaultValue(512);
        b.setDefaultValue(4);
        if(mode == 2 || mode == 3)
        {
            a.setDefaultValue(256);
            b.setDefaultValue(2);
        }
        p.xscreen(mode, cast(int)a, cast(int)b);
    }
    static void DISPLAY(PetitComputer p, int display)
    {
        p.display(display);
    }
    static void GCLS(PetitComputer p, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(0);
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
    static void GCIRCLE(PetitComputer p, Value[])
    {
        //color.setDefaultValue(p.gcolor);
        //p.gfill(p.useGRP, x, y, x2, y2, cast(int)color);
    }
    static void GCOLOR(PetitComputer p, int color)
    {
        p.gcolor = color;
    }
    static void GPRIO(PetitComputer p, int z)
    {
        p.gprio = z;
    }
    static void GPAGE(PetitComputer p, int showPage, int usePage)
    {
        p.showGRP = showPage;
        p.useGRP = usePage;
    }
    static void GPAINT(PetitComputer p, int x, int y, DefaultValue!(int, false) color, DefaultValue!(int, false) color2)
    {
        color.setDefaultValue(p.gcolor);
        p.gpaint(p.useGRP, x, y, cast(int)color);
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
    static void STICKEX(PetitComputer p, DefaultValue!(int, false) mp, out int x, out int y)
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
        return uniform(0, max - 1 + 1);
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
        return cast(int)str.length;
    }

    static bool tryParse(Target, Source)(ref Source p, out Target result)
        if (isInputRange!Source && isSomeChar!(ElementType!Source) && !is(Source == enum) &&
            isFloatingPoint!Target && !is(Target == enum))
        {
            static immutable real negtab[14] =
            [ 1e-4096L,1e-2048L,1e-1024L,1e-512L,1e-256L,1e-128L,1e-64L,1e-32L,
            1e-16L,1e-8L,1e-4L,1e-2L,1e-1L,1.0L ];
            static immutable real postab[13] =
            [ 1e+4096L,1e+2048L,1e+1024L,1e+512L,1e+256L,1e+128L,1e+64L,1e+32L,
            1e+16L,1e+8L,1e+4L,1e+2L,1e+1L ];
            // static immutable string infinity = "infinity";
            // static immutable string nans = "nans";

            /*ConvException bailOut(string msg = null, string fn = __FILE__, size_t ln = __LINE__)
            {
                if (!msg)
                    msg = "Floating point conversion error";
                return new ConvException(text(msg, " for input \"", p, "\"."), fn, ln);
            }*/
            if(p.empty) return 0;
            //enforce(!p.empty, bailOut());

            char sign = 0;                       /* indicating +                 */
            switch (p.front)
            {
                case '-':
                    sign++;
                    p.popFront();
                    if(p.empty) return 0;
                    //enforce(!p.empty, bailOut());
                    if (std.ascii.toLower(p.front) == 'i')
                        goto case 'i';
                    if(p.empty) return 0;
                    //enforce(!p.empty, bailOut());
                    break;
                case '+':
                    p.popFront();
                    if(p.empty) return 0;
                    //enforce(!p.empty, bailOut());
                    break;
                case 'i': case 'I':
                    p.popFront();
                    if(p.empty) return 0;
                    //enforce(!p.empty, bailOut());
                    if (std.ascii.toLower(p.front) == 'n')
                    {
                        p.popFront();
                        if(p.empty) return 0;
                        if(std.ascii.toLower(p.front) == 'f')
                        {
                            // 'inf'
                            p.popFront();
                            result = sign ? -Target.infinity : Target.infinity;
                            return 0;
                        }
                    }
                    goto default;
                default: {}
            }

            bool isHex = false;
            bool startsWithZero = p.front == '0';
            if(startsWithZero)
            {
                p.popFront();
                if(p.empty)
                {
                    result = (sign) ? -0.0 : 0.0;
                    return true;
                }

                isHex = p.front == 'x' || p.front == 'X';
            }

            real ldval = 0.0;
            char dot = 0;                        /* if decimal point has been seen */
            int exp = 0;
            long msdec = 0, lsdec = 0;
            ulong msscale = 1;

            if (isHex)
            {
                int guard = 0;
                int anydigits = 0;
                uint ndigits = 0;

                p.popFront();
                while (!p.empty)
                {
                    int i = p.front;
                    while (isHexDigit(i))
                    {
                        anydigits = 1;
                        i = std.ascii.isAlpha(i) ? ((i & ~0x20) - ('A' - 10)) : i - '0';
                        if (ndigits < 16)
                        {
                            msdec = msdec * 16 + i;
                            if (msdec)
                                ndigits++;
                        }
                        else if (ndigits == 16)
                        {
                            while (msdec >= 0)
                            {
                                exp--;
                                msdec <<= 1;
                                i <<= 1;
                                if (i & 0x10)
                                    msdec |= 1;
                            }
                            guard = i << 4;
                            ndigits++;
                            exp += 4;
                        }
                        else
                        {
                            guard |= i;
                            exp += 4;
                        }
                        exp -= dot;
                        p.popFront();
                        if (p.empty)
                            break;
                        i = p.front;
                        if (i == '_')
                        {
                            p.popFront();
                            if (p.empty)
                                break;
                            i = p.front;
                        }
                    }
                    if (i == '.' && !dot)
                    {       p.popFront();
                        dot = 4;
                    }
                    else
                        break;
                }

                // Round up if (guard && (sticky || odd))
                if (guard & 0x80 && (guard & 0x7F || msdec & 1))
                {
                    msdec++;
                    if (msdec == 0)                 // overflow
                    {   msdec = 0x8000000000000000L;
                        exp++;
                    }
                }

                if(!anydigits) return 0;
                //enforce(anydigits, bailOut());
                if(!(!p.empty && (p.front == 'p' || p.front == 'P'))) return 0;
                //enforce(!p.empty && (p.front == 'p' || p.front == 'P'),
                //        bailOut("Floating point parsing: exponent is required"));
                char sexp;
                int e;

                sexp = 0;
                p.popFront();
                if (!p.empty)
                {
                    switch (p.front)
                    {   case '-':    sexp++;
                        goto case;
                    case '+':    p.popFront(); 
                        if(p.empty) return 0;
                        //enforce(!p.empty,
                        //            new ConvException("Error converting input"
                        //            " to floating point"));
                        break;
                    default: {}
                    }
                }
                ndigits = 0;
                e = 0;
                while (!p.empty && isDigit(p.front))
                {
                    if (e < 0x7FFFFFFF / 10 - 10) // prevent integer overflow
                    {
                        e = e * 10 + p.front - '0';
                    }
                    p.popFront();
                    ndigits = 1;
                }
                exp += (sexp) ? -e : e;
                if(p.empty) return 0;
                //enforce(ndigits, new ConvException("Error converting input"
                //" to floating point"));

                if (msdec)
                {
                    int e2 = 0x3FFF + 63;

                    // left justify mantissa
                    while (msdec >= 0)
                    {   msdec <<= 1;
                        e2--;
                    }

                    // Stuff mantissa directly into real
                    *cast(long *)&ldval = msdec;
                    (cast(ushort *)&ldval)[4] = cast(ushort) e2;

                    // Exponent is power of 2, not power of 10
                    ldval = ldexp(ldval,exp);
                }
                goto L6;
            }
            else // not hex
            {
                if (std.ascii.toUpper(p.front) == 'N' && !startsWithZero)
                {
                    // nan
                    if(!((p.popFront(), !p.empty && std.ascii.toUpper(p.front) == 'A') &&
                         (p.popFront(), !p.empty && std.ascii.toUpper(p.front) == 'N'))) return 0;
                    //enforce((p.popFront(), !p.empty && std.ascii.toUpper(p.front) == 'A')
                    //        && (p.popFront(), !p.empty && std.ascii.toUpper(p.front) == 'N'),
                    //       new ConvException("error converting input to floating point"));
                    // skip past the last 'n'
                    p.popFront();
                    result = typeof(result).nan;
                    return true;
                }

                bool sawDigits = startsWithZero;

                while (!p.empty)
                {
                    int i = p.front;
                    while (isDigit(i))
                    {
                        sawDigits = true;        /* must have at least 1 digit   */
                        if (msdec < (0x7FFFFFFFFFFFL-10)/10)
                            msdec = msdec * 10 + (i - '0');
                        else if (msscale < (0xFFFFFFFF-10)/10)
                        {   lsdec = lsdec * 10 + (i - '0');
                            msscale *= 10;
                        }
                        else
                        {
                            exp++;
                        }
                        exp -= dot;
                        p.popFront();
                        if (p.empty)
                            break;
                        i = p.front;
                        if (i == '_')
                        {
                            p.popFront();
                            if (p.empty)
                                break;
                            i = p.front;
                        }
                    }
                    if (i == '.' && !dot)
                    {
                        p.popFront();
                        dot++;
                    }
                    else
                    {
                        break;
                    }
                }
                if(!sawDigits) return 0;
                //enforce(sawDigits, new ConvException("no digits seen"));
            }
            if (!p.empty && (p.front == 'e' || p.front == 'E'))
            {
                char sexp;
                int e;

                sexp = 0;
                p.popFront();
                if(p.empty) return false;
                //enforce(!p.empty, new ConvException("Unexpected end of input"));
                switch (p.front)
                {   case '-':    sexp++;
                    goto case;
                case '+':    p.popFront();
                    break;
                default: {}
                }
                bool sawDigits = 0;
                e = 0;
                while (!p.empty && isDigit(p.front))
                {
                    if (e < 0x7FFFFFFF / 10 - 10)   // prevent integer overflow
                    {
                        e = e * 10 + p.front - '0';
                    }
                    p.popFront();
                    sawDigits = 1;
                }
                exp += (sexp) ? -e : e;
                if(!sawDigits) return 0;
                //enforce(sawDigits, new ConvException("No digits seen."));
            }

            ldval = msdec;
            if (msscale != 1)               /* if stuff was accumulated in lsdec */
                ldval = ldval * msscale + lsdec;
            if (ldval)
            {
                uint u = 0;
                int pow = 4096;

                while (exp > 0)
                {
                    while (exp >= pow)
                    {
                        ldval *= postab[u];
                        exp -= pow;
                    }
                    pow >>= 1;
                    u++;
                }
                while (exp < 0)
                {
                    while (exp <= -pow)
                    {
                        ldval *= negtab[u];
                        if(ldval == 0) return 0;
                        //enforce(ldval != 0, new ConvException("Range error"));
                        exp += pow;
                    }
                    pow >>= 1;
                    u++;
                }
            }
        L6: // if overflow occurred
            if(ldval == core.stdc.math.HUGE_VAL) return 0;
            //enforce(ldval != core.stdc.math.HUGE_VAL, new ConvException("Range error"));

        L1:
            result = (sign) ? -ldval : ldval;
            return true;
        }
    static double VAL(wstring str)
    {
        try
        {
            if(str.empty) return 0;
            if(str.length > 2 && str[0..2] == "&H")
            {
                return str[2..$].to!int(16);
            }
            if(str.length > 2 && str[0..2] == "&B")
            {
                return str[2..$].to!int(2);
            }
            import std.string : munch;
            munch(str, " ");
            if(str.empty) return 0;
            /*
            wchar c = str[0];
            if((c > '9' || c < '0') && (c != '-' && c != '+' && c != '.'))
                return 0;*/
            double val;
            if(tryParse(str, val))
                return val;
            else
                return 0;
            //例外は遅い
            //TryParse欲しい...
            //double val = str.to!double;
            //return val;
        }
        catch(Exception e)
        {
            return 0;//toriaezu
        }
    }
    static double FLOOR(double val)
    {
        return val.floor;
    }
    static double ROUND(double val)
    {
        return val.round;
    }
    static double CEIL(double val)
    {
        return val.ceil;
    }
    static wstring MID(wstring str, int i, int len)
    {
        if(i + len > str.length)
        {
            if(i >= str.length)
            {
                return "";//範囲外で空文字
            }
            return str[i..$];//iがまだ範囲内なら最後まで
        }
        //挙動未定
        return str[i..i + len];
    }
    //INSTRSUSBTLEFT
    static wstring LEFT(wstring str, int len)
    {
        return str[0..len];
    }
    static wstring RIGHT(wstring str, int len)
    {
        return str[$ - len..$];
    }
    static wstring SUBST(wstring str, int i, Value alen, DefaultValue!(Value,false) areplace)
    {
        int len = 1;
        wstring replace = "";
        if(alen.isNumber)
        {
            len = alen.castInteger;
            replace = areplace.castString;
        }
        else
        {
            replace = alen.castString;
            //省略されたらi以降の全文字を置換
            return str[0..i] ~ replace;
        }
        if(str.length <= i + len)
        {
            return str[0..i] ~ replace;
        }
        str.replaceInPlace(i, i + len, replace);
        return str;
    }
    static int INSTR(Value vstart, Value vstr1, DefaultValue!(wstring, false) vstr2)
    {
        import std.string;
        int start = 0;
        wstring str1, str2;
        if(!vstr2.isDefault)
        {
            start = vstart.castInteger;
            str1 = vstr1.castString;
            str2 = cast(wstring)vstr2;
        }
        else
        {
            str1 = vstart.castString;
            str2 = vstr1.castString;
        }
        return cast(int)(str1[start..$].indexOf(str2, CaseSensitive.no));
    }
    static int ASC(wstring str)
    {
        return cast(int)str[0];
    }
    static wstring STR(int val)
    {
        return val.to!wstring;
    }
    static wstring HEX(int val, DefaultValue!(int, false) digits)
    {
        import std.format;
        if(digits > 8)
        {
            throw new OutOfRange();
        }
        FormatSpec!char f;
        f.spec = 'X';
        f.flZero = !digits.isDefault;
        f.width = cast(int)digits;
        auto w = appender!wstring();
        formatValue(w, val, f);
        return cast(immutable)(w.data);
    }
    static void SPSET(PetitComputer p, int id, int defno, DefaultValue!(int, false) V, DefaultValue!(int, false) W, DefaultValue!(int, false) H, DefaultValue!(int, false) ATTR)
    {
        if(!V.isDefault && !W.isDefault)
        {
            int u = defno;
            int v = cast(int)V;
            int w = 16, h = 16, attr = 1;
            if(!ATTR.isDefault)
            {
                w = cast(int)W;
                h = cast(int)H;
                attr = cast(int)ATTR;
            }
            else
            {
                if(!W.isDefault && !H.isDefault)
                {
                    w = cast(int)W;
                    h = cast(int)H;
                }
                if(!W.isDefault && H.isDefault)
                {
                    attr = cast(int)W;
                }
            }
            p.sprite.spset(id, u, v, w, h, cast(SpriteAttr)attr);
            return;
        }
        p.sprite.spset(id, defno);
    }
    static void SPCHR(PetitComputer p, int id, int defno, DefaultValue!(int, false) V, DefaultValue!(int, false) W, DefaultValue!(int, false) H, DefaultValue!(int, false) ATTR)
    {
        if(!V.isDefault && !W.isDefault)
        {
            int u = defno;
            int v = cast(int)V;
            int w = 16, h = 16, attr = 1;
            if(!ATTR.isDefault)
            {
                w = cast(int)W;
                h = cast(int)H;
                attr = cast(int)ATTR;
            }
            else
            {
                if(!W.isDefault && !H.isDefault)
                {
                    w = cast(int)W;
                    h = cast(int)H;
                }
                if(!W.isDefault && H.isDefault)
                {
                    attr = cast(int)W;
                }
            }
            p.sprite.spchr(id, u, v, w, h, cast(SpriteAttr)attr);
            return;
        }
        p.sprite.spchr(id, defno);
    }
    static void SPHIDE(PetitComputer p, int id)
    {
        p.sprite.sphide(id);
    }
    static void SPSHOW(PetitComputer p, int id)
    {
        p.sprite.spshow(id);
    }
    static void SPOFS(PetitComputer p, int id, double x, double y, DefaultValue!(int, false) z)
    {
        if(z.isDefault)
        {
            p.sprite.spofs(id, x, y);
        }
        else
        {
            p.sprite.spofs(id, x, y, cast(int)z);
        }
    }
    @StartOptional("z")
    static void SPOFS(PetitComputer p, int id, out double x, out double y, out int z)
    {
        p.sprite.getspofs(id, x, y, z);
    }
    static void SPANIM(PetitComputer p, Value[] va_args)
    {
        //TODO:配列
        auto args = retro(va_args);
        int no = args[0].castInteger;
        double[] animdata;
        if(args[2].isString)
        {
            VM vm = p.vm;
            vm.pushDataIndex();
            vm.restoreData(args[2].castString);
            int keyframe = vm.readData.castInteger;
            auto target = p.sprite.getSpriteAnimTarget(args[1].castString);
            int item = 2;
            if((target & 7) == SpriteAnimTarget.XY || (target & 7) == SpriteAnimTarget.UV) item++;
            animdata = new double[item * keyframe + 1];
            int j;
            for(int i = 0; i < keyframe; i++)
            {
                animdata[j] = vm.readData.castDouble;
                animdata[j + 1] = vm.readData.castDouble;
                if(item == 3)
                    animdata[j + 2] = vm.readData.castDouble;
                j += item;
            }
            if(args.length > 2)
                animdata[j] = args[3].castInteger;
            vm.popDataIndex();
        }
        else
        {
            int i;
            animdata = new double[args.length - 2];
            foreach(a; args[2..$])
            {
                animdata[i++] = a.castDouble;
            }
        }
        if(args[1].isString)
            p.sprite.spanim(no, args[1].castString, animdata);
        if(args[1].isNumber)
            p.sprite.spanim(no, cast(SpriteAnimTarget)(args[1].castInteger), animdata);
    }
    @StartOptional("W")
    static void SPDEF(PetitComputer p, int id, out int U, out int V, out int W, out int H, out int HX, out int HY, out int A)
    {
        p.sprite.getspdef(id, U, V, W, H, HX, HY, A);
    }
    static void SPDEF(PetitComputer p, Value[] va_args2)
    {
        auto va_args = retro(va_args2);
        switch(va_args.length)
        {
            case 0:
                p.sprite.spdef();//初期化
                return;
            case 1://array
                {
                    if(va_args[0].isNumberArray)
                    {
                        writeln("NOTIMPL:SPDEF ARRAY");
                        //return;
                    }
                    if(va_args[0].isString)
                    {
                        VM vm = p.vm;
                        vm.pushDataIndex();
                        vm.restoreData(va_args[0].castString);
                        auto count = vm.readData().castInteger;//読み込むスプライト数
                        int defno = 0;//?
                        for(int i = 0; i < count; i++)
                        {
                            int U = vm.readData().castInteger;
                            int V = vm.readData().castInteger;
                            int W = vm.readData().castInteger;
                            int H = vm.readData().castInteger;
                            int HX = vm.readData().castInteger;
                            int HY = vm.readData().castInteger;
                            int ATTR = vm.readData().castInteger;
                            p.sprite.SPDEFTable[defno] = SpriteDef(U, V, W, H, HX, HY, cast(SpriteAttr)ATTR);
                            defno++;
                        }
                        vm.popDataIndex();
                        return;
                    }
                    throw new IllegalFunctionCall("SPDEF");
                }
            default:
        }
        {
            int defno = va_args[0].castInteger;
            int U = va_args[1].castInteger;
            int V = va_args[2].castInteger;
            int W = 16, H = 16, HX = 0, HY = 0, ATTR = 1;
            if(va_args.length > 3)
            {
                W = va_args[3].castInteger;
            }
            if(va_args.length > 4)
            {
                H = va_args[4].castInteger;
            }
            if(va_args.length > 5)
            {
                HX = va_args[5].castInteger;
            }
            if(va_args.length > 6)
            {
                HY = va_args[6].castInteger;
            }
            if(va_args.length > 7)
            {
                ATTR = va_args[7].castInteger;
            }
            p.sprite.SPDEFTable[defno] = SpriteDef(U, V, W, H, HX, HY, cast(SpriteAttr)ATTR);
        }
    }
    static void SPCLR(PetitComputer p, DefaultValue!(int, false) i)
    {
        if(i.isDefault)
            p.sprite.spclr();
        else
            p.sprite.spclr(cast(int)i);
    }
    static void SPHOME(PetitComputer p, int i, int hx, int hy)
    {
        p.sprite.sphome(i, hx, hy);
    }
    static void SPSCALE(PetitComputer p, int i, double x, double y)
    {
        p.sprite.spscale(i, x, y);
    }
    static void SPROT(PetitComputer p, int i, double rot)
    {
        p.sprite.sprot(i, rot);
    }
    static void SPCOLOR(PetitComputer p, int id, int color)
    {
        p.sprite.spcolor(id, cast(uint)color);
    }
    static void SPLINK(PetitComputer p, int child, int parent)
    {
        p.sprite.splink(child, parent);
    }
    static void SPUNLINK(PetitComputer p, int id)
    {
        p.sprite.spunlink(id);
    }
    static void SPCOL(PetitComputer p, int id, DefaultValue!(int, false) scale)
    {
        scale.setDefaultValue(true);
        p.sprite.spcol(id, cast(bool)scale);
    }
    static void SPCOL(PetitComputer p, int id, DefaultValue!int scale, int mask)
    {
        scale.setDefaultValue(true);
        p.sprite.spcol(id, cast(bool)scale, mask);
    }
    static void SPCOL(PetitComputer p, int id, int x, int y, int w, int h, int scale)
    {
        p.sprite.spcol(id, cast(short)x, cast(short)y, cast(ushort)w, cast(ushort)h, cast(bool)scale, -1);
    }
    static void SPCOL(PetitComputer p, int id, int x, int y, int w, int h, DefaultValue!int scale, int mask)
    {
        scale.setDefaultValue(true);
        p.sprite.spcol(id, cast(short)x, cast(short)y, cast(ushort)w, cast(ushort)h, cast(bool)scale, mask);
    }
    static int SPHITSP(PetitComputer p, int id)
    {
        return p.sprite.sphitsp(id);
    }
    static int SPHITSP(PetitComputer p, int id, int min)
    {
        return p.sprite.sphitsp(id, min, 511);//?
    }
    static int SPHITSP(PetitComputer p, int id, int min, int max)
    {
        return p.sprite.sphitsp(id, min, max);
    }
    static void SPVAR(PetitComputer p, int id, int var, double val)
    {
        p.sprite.spvar(id, var, val);
    }
    static double SPVAR(PetitComputer p, int id, int var)
    {
        return p.sprite.spvar(id, var);
    }
    static int SPCHK(PetitComputer p, int id)
    {
        return p.sprite.spchk(id);
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
                int d = cast(int)indexOf(format, 'D', CaseSensitive.yes);
                if(d != -1)
                {
                    auto spec = singleSpec(format[i .. d + 1]);
                    spec.spec = 'd';
                    formatValue(w, args[j].castInteger, spec);
                    j++;
                    i = d;
                    continue;
                }
                d = cast(int)indexOf(format, 'X', CaseSensitive.yes);
                if(d != -1)
                {
                    auto spec = singleSpec(format[i .. d + 1]);
                    spec.spec = cast(char)format[d];
                    formatValue(w, args[j].castInteger, spec);
                    j++;
                    i = d;
                    continue;
                }
                d = cast(int)indexOf(format, 'S', CaseSensitive.yes);
                if(d != -1)
                {
                    auto spec = singleSpec(format[i .. d + 1]);
                    spec.spec = 's';
                    formatValue(w, args[j].castString, spec);
                    j++;
                    i = d;
                    continue;
                }
                d = cast(int)indexOf(format, 'F', CaseSensitive.yes);
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
    //GalateaTalk利用面倒くさい...
    static void TALK(wstring a1)
    {
    }
    static void BGCLR(PetitComputer p, DefaultValue!(int, false) layer)
    {
        if(layer.isDefault)
        {
            foreach(bg; p.allBG)
            {
                bg.clear;
            }
            return;
        }
        p.getBG(cast(int)layer).clear;
    }
    static void BGSCREEN(PetitComputer p, int layer, int w, int h)
    {
        p.getBG(layer).screen(w, h);
    }
    static void BGOFS(PetitComputer p, int layer, int x, int y, DefaultValue!(int, false) z)
    {
        z.setDefaultValue(p.getBG(layer).offsetz);
        p.getBG(layer).ofs(x, y, cast(int)z);
    }
    static void BGCLIP(PetitComputer p, int layer, DefaultValue!(int, false) x, DefaultValue!(int, false) y,
                       DefaultValue!(int, false) x2, DefaultValue!(int, false) y2)
    {
        if(x.isDefault && y.isDefault && x2.isDefault && y2.isDefault)
        {
            p.getBG(layer).clip();
        }
        if(x.isDefault || y.isDefault || x2.isDefault || y2.isDefault)
        {
            throw new IllegalFunctionCall("BGCLIP");
        }
        p.getBG(layer).clip(cast(int)x, cast(int)y, cast(int)x2, cast(int)y2);
    }
    static void BGPUT(PetitComputer p, int layer, int x, int y, int screendata)
    {
        p.getBG(layer).put(x, y, screendata);
    }
    static void BGHOME(PetitComputer p, int layer, int x, int y)
    {
        p.getBG(layer).home(x, y);
    }
    static void BGSCALE(PetitComputer p, int layer, double x, double y)
    {
        p.getBG(layer).scale(x, y);
    }
    static void BGROT(PetitComputer p, int layer, double rot)
    {
        p.getBG(layer).rot(rot);
    }
    static void BGFILL(PetitComputer p, int layer, int x, int y, int x2, int y2, int screendata)
    {
        p.getBG(layer).fill(x, y, x2, y2, screendata);
    }
    static void EFCON()
    {
    }
    static void EFCOFF()
    {
    }
    static void EFCSET(Value[])
    {
    }
    static void EFCWET(Value[])
    {
    }
    static void COPY(PetitComputer p, Value[] rawargs)
    {
        auto args = retro(rawargs);
        //文字列はリテラル渡すとType mismatch
        if(args.length > 5 || args.length < 2 || !args[0].isArray)
        {
            throw new IllegalFunctionCall("COPY");
        }
        //COPY string, string->文字列COPY
        //COPY array, string->DATA COPY
        Value dst = args[0];
        int dstoffset = 0;
        int srcoffset = 0;
        int len = dst.length;//省略時はコピー元の末尾まで
        if(args[1].isString && !args[0].isString)
        {
            //DATAから
            VM vm = p.vm;
            vm.pushDataIndex();
            vm.restoreData(args[1].castString);
            for(int i = 0; i < len; i++)
            {
                Value data = vm.readData();
                dst[dstoffset++] = data;
            }
            vm.popDataIndex();
            return;
        }
        throw new IllegalFunctionCall("COPY (Not implemented error)");
    }
    //alias void function(PetitComputer, Value[], Value[]) BuiltinFunc;
    static BuiltinFunctions[wstring] builtinFunctions;
    static this()
    {
        foreach(name; __traits(derivedMembers, BuiltinFunction))
        {
            //writeln(name);
            static if(/*__traits(isStaticFunction, __traits(getMember, BuiltinFunction, name)) && */name[0].isUpper)
            {
                foreach(i, F; __traits(getOverloads, BuiltinFunction, name))
                {
                    //pragma(msg, AddFunc!(BuiltinFunction, name));
                    wstring suffix = "";
                    if(is(ReturnType!(__traits(getMember, BuiltinFunction, name)) == wstring))
                    {
                        suffix = "$";
                    }
                    wstring name2 = name ~ suffix;
                    auto func = builtinFunctions.get(name2, null);
                    alias BFD = BuiltinFunctionData!(BuiltinFunction, name, i);
                    pragma(msg, AddFunc!BFD);
                    auto f = new BuiltinFunction(
                                                 GetFunctionParamType!(BFD),
                                                 GetFunctionReturnType!(BFD),
                                                 mixin(AddFunc!(BFD)),
                                                 GetStartSkip!(BFD),
                                                 IsVariadic!(BFD),
                                                 name,
                                                 GetOutStartSkip!(BFD)
                                                 );
                    if(func)
                    {
                        builtinFunctions[name2].addFunction(f);
                    }
                    else
                    {
                        builtinFunctions[name2] = new BuiltinFunctions(f);
                    }
                    //writeln(AddFunc!(BuiltinFunction, name));
                }
            }
        }
    }

}
template GetOutStartSkip(BFD)
{
    static if(__traits(getAttributes, __traits(getOverloads, BFD.C_, BFD.N)[BFD.I_]).length == 1 &&
              is(typeof(__traits(getAttributes, __traits(getOverloads, BFD.C_, BFD.N)[BFD.I_])[0]) == StartOptional))
    {
        enum so = __traits(getAttributes, __traits(getOverloads, BFD.C_, BFD.N)[BFD.I_])[0];
        int GetOutStartSkip()
        {
            int k;
            foreach (j, i; ParameterIdentifierTuple!(__traits(getOverloads, BFD.C_, BFD.N)[BFD.I_]))
            {
                if(i == so.name)
                {
                    return k;
                }
                else if(BFD.ParameterStorageClass[j] & ParameterStorageClass.out_)
                {
                    k++;
                }
            }
            return 0;
        }
    }
    else
    {
        int GetOutStartSkip()
        {
            return 0;
        }
    }
}
template GetStartSkip(BFD)
{
    private template SkipSkip(int I, P...)
    {
        static if(P.length <= I)
        {
            enum SkipSkip = I - is(P[0] == PetitComputer);
        }
        else static if(BFD.ParameterStorageClass[I] & ParameterStorageClass.out_)
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else static if(is(P[I] == DefaultValue!(int, false)))
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else static if(is(P[I] == DefaultValue!(double, false)))
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else static if(is(P[I] == DefaultValue!(wstring, false)))
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else static if(is(P[I] == DefaultValue!(Value, false)))
        {
            enum SkipSkip = I - is(P[0] : PetitComputer);
        }
        else
        {
            enum SkipSkip = SkipSkip!(I + 1, P);
        }
    }
    enum GetStartSkip = SkipSkip!(0, BFD.ParameterType);
}
template GetBuiltinFunctionArgment(P...)
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
    else static if(is(P[0] == OptionalOutValue!int))
    {
        const string arg = "ValueType.Integer, true";
    }
    else static if(is(P[0] == DefaultValue!double))
    {
        const string arg = "ValueType.Double, true";
    }
    else static if(is(P[0] == DefaultValue!(double, false)))
    {
        const string arg = "ValueType.Double, true";
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
    else static if(is(P[0] == DefaultValue!(Value)) || is(P[0] == Value))
    {
        const string arg = "ValueType.Void, false";
    }
    else static if(is(P[0] == DefaultValue!(Value, false)))
    {
        const string arg = "ValueType.Void, true";
    }
    else static if(is(P[0] == void))
    {
        const string arg = "";
    }
    else
    {
        static assert(false, "Invalid type");
    }
    static if(is(P[0] == void))
    {
        enum GetBuiltinFunctionArgment = "";
    }
    else
    {
        enum GetBuiltinFunctionArgment = "BuiltinFunctionArgument(" ~ arg ~ ")";
    }
}
template BuiltinFunctionData(C, string NAME, int I)
{
    //struct BuiltinFunctionData
    //{
        //enum P = ParameterStorageClassTuple!(__traits(getOverloads, C, N)[I]);
    struct BuiltinFunctionData
    {
        alias P = std.traits.ParameterStorageClassTuple!(__traits(getOverloads, C, NAME)[I]);
        alias T = std.traits.ParameterTypeTuple!(__traits(getOverloads, C, NAME)[I]);
        alias R = std.traits.ReturnType!(__traits(getOverloads, C, NAME)[I]);
        alias ParameterStorageClass = std.traits.ParameterStorageClassTuple!(__traits(getOverloads, C, NAME)[I]);
        alias ParameterType = std.traits.ParameterTypeTuple!(__traits(getOverloads, C, NAME)[I]);
        alias ReturnType = std.traits.ReturnType!(__traits(getOverloads, C, NAME)[I]);
        enum F = &__traits(getOverloads, C, NAME)[I];
        alias N = NAME;
        alias C_ = C;
        alias I_ = I;
    }
}
template GetOutArgment(C, string N)
{
    alias T = ParameterTypeTuple!(__traits(getMember, C, N));
    string GetOutArgment2()
    {
        string arg = "";
        foreach(i, J; T)
        {
            enum P = ParameterStorageClassTuple!(__traits(getMember, C, N))[i];
            static if(P & ParameterStorageClass.out_)
            {
                arg ~= GetBuiltinFunctionArgment!(J) ~ ",";
            }
        }
        return arg;
    }
    enum GetOutArgment = GetOutArgment2();
}
template GetOutArgment2(BFD)
{
    alias T = BFD.T;
    string GetOutArgment22()
    {
        string arg = "";
        foreach(i, J; T)
        {
            //enum P = ParameterStorageClassTuple!(__traits(getMember, C, N))[i];
            static if(BFD.P[i] & ParameterStorageClass.out_)
            {
                arg ~= GetBuiltinFunctionArgment!(J) ~ ",";
            }
        }
        return arg;
    }
    enum GetOutArgment2 = GetOutArgment22();
}
//template GetOutArgment2(T2)
//{
//}
template GetFunctionReturnType(BFD)
{
    static if(is(BFD.R == void))
    {
        enum GetFunctionReturnType = 
           mixin("[" ~ GetOutArgment2!(BFD) ~ "]");
    }
    else
    {
        enum GetFunctionReturnType = 
           mixin("[" ~ GetBuiltinFunctionArgment!(BFD.R) ~ "]");
    }
}
template AddFunc(BFD)
{
    static if(is(BFD.ReturnType == double) || is(BFD.ReturnType == int))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall(\"" ~ BFD.N ~ "\");}ret[0] = Value(" ~ BFD.N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(BFD) - 1, 0, 0, 0, BFD,
                         BFD.ParameterType) ~ "));}";
    }
    else static if(is(BFD.ReturnType == void))
    {
        //pragma(msg, GetArgumentCount!(T,N));
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){/*if(ret.length != 0){throw new IllegalFunctionCall(\"" ~ BFD.N ~ "\");}*/" ~ OutArgsInit!(BFD) ~ BFD.N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(BFD) - 1, 0, 0, 0, BFD,
                        BFD.ParameterType) ~ ");}";
    }
    else static if(is(BFD.ReturnType == wstring))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall(\"" ~ BFD.N ~ "\");}ret[0] = Value(" ~ BFD.N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(BFD) - 1, 0, 0, 0, BFD,
                        BFD.ParameterType) ~ "));}";
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
DefaultValue!double fromDoubleToDefault(Value v)
{
    if(v.isNumber)
        return DefaultValue!double(v.castDouble());
    else
        return DefaultValue!double(true);
}
DefaultValue!(double, false) fromDoubleToSkip(Value v)
{
    if(v.isNumber)
        return DefaultValue!(double, false)(v.castDouble());
    else
        return DefaultValue!(double, false)(true);
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
DefaultValue!Value fromValueToDefault(Value v)
{
    if(v.type != ValueType.Void)
        return DefaultValue!Value(v);
    else
        return DefaultValue!Value(true);
}
DefaultValue!(Value, false) fromValueToSkip(Value v)
{
    if(v.type != ValueType.Void)
        return DefaultValue!(Value, false)(v);
    else
        return DefaultValue!(Value, false)(true);
}
template GetFunctionParamType(BFD)
{
    enum GetFunctionParamType = mixin("[" ~ Array!(0, BFD.T) ~ "]");
    private template Array(int I, P...)
    {
        static if(P.length == 0)
        {
            const string arg = "";
            enum Array = "";
        }
        else static if(BFD.ParameterStorageClass[I] & ParameterStorageClass.out_)
        {
            static if(1 == P.length && !is(P[0] == PetitComputer))
            {
                enum Array = "";
            }
            else static if(!is(P[0] == PetitComputer))
            {
                enum Array = Array!(I + 1, P[1..$]);
            }
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
            else static if(is(P[0] == DefaultValue!double))
            {
                const string arg = "ValueType.Double, true";
            }
            else static if(is(P[0] == DefaultValue!(double, false)))
            {
                const string arg = "ValueType.Double, true";
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
            else static if(is(P[0] == DefaultValue!(Value)) || is(P[0] == Value))
            {
                const string arg = "ValueType.Void, false";
            }
            else static if(is(P[0] == DefaultValue!(Value, false)))
            {
                const string arg = "ValueType.Void, true";
            }
            else static if(is(P[0] == PetitComputer))
            {
                static if(P.length != 0)
                {
                    enum Array = Array!(I + 1, P[1..$]);
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
                enum Array = "BuiltinFunctionArgument(" ~ arg ~ ")," ~ Array!(I + 1, P[1..$]);
            }
        }
    }
}
template AddFuncArg(int L, int N, int M, int O, BFD, P...)
{
    enum I = L - N;
    static if(BFD.ParameterStorageClass.length <= M)
    {
        const string AddFuncArg = "";
    }
    else
    {
        enum storage = BFD.ParameterStorageClass[M];
        static if(is(P[0] == double))
        {
            static if(storage & ParameterStorageClass.out_)
            {
                enum add = 0;
                enum outadd = 1;
                const string arg = "ret[" ~ O.to!string ~ "].doubleValue";
            }
            else
            {
                enum add = 1;
                enum outadd = 0;
                const string arg = "arg[" ~ I.to!string ~ "].castDouble";
            }
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
                const string arg = "fromIntToDefault(arg[" ~ I.to!string ~ "])";
            }
        }
        else static if(is(P[0] == DefaultValue!(int, false)))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromIntToSkip(arg[" ~ I.to!string ~ "])";
        }
        else static if(is(P[0] == DefaultValue!double))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromDoubleToDefault(arg[" ~ I.to!string ~ "])";
        }
        else static if(is(P[0] == DefaultValue!(double, false)))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromDoubleToSkip(arg[" ~ I.to!string ~ "])";
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
        else static if(is(P[0] == Value))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "arg[" ~ I.to!string ~ "]";
        }
        else static if(is(P[0] == DefaultValue!Value))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromValueToDefault(arg[" ~ I.to!string ~ "])";
        }
        else static if(is(P[0] == DefaultValue!(Value, false)))
        {
            enum add = 1;
            enum outadd = 0;
            const string arg = "fromValueToSkip(arg[" ~ I.to!string ~ "])";
        }
        else
        {
            enum add = 1;
            enum outadd = 0;
            pragma(msg, P[0]);
            static assert(false, "Invalid type");
            const string arg = "";
        }
        static if(1 == P.length)
        {
            const string AddFuncArg = arg;
        }
        else
        {
            const string AddFuncArg = arg ~ ", " ~ AddFuncArg!(L - !add, N + add, M + 1, O + outadd, BFD, P[1..$]);
        }
    }
}
template OutArgsInit(BFD, int I = 0, int J = 0)
{
    alias param = BFD.ParameterType;
    static if(!param.length)
    {
        enum OutArgsInit = "";
    }
    else
    {
        enum tuple = BFD.ParameterStorageClass[I];
        static if(tuple & ParameterStorageClass.out_)
        {
            enum add = 1;
            enum ret1 = "ret[" ~ J.to!string ~ "].type = ";
            static if(is(param[I] == int))
            {
                enum ret2 = "ValueType.Integer;";
            }
            else static if(is(param[I] == DefaultValue!int))
            {
                enum ret2 = "ValueType.Integer;";
            }
            //else static if(is(param[I] == OptionalOutValue!int))
            //{
            //    enum ret2 = "ValueType.Integer;";
            //}
            else static if(is(param[I] == double))
            {
                enum ret2 = "ValueType.Double;";
            }
            else static if(is(param[I] == Value[]))
            {
                enum ret2 = "ValueType.Void;";
            }
            else
            {
                static assert(false, "invalid type " ~ param[I].stringof); 
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
            enum OutArgsInit = result ~ OutArgsInit!(BFD, I + 1, J + add);
        }
        else
        {
            enum OutArgsInit = result;
        }
    }
}
template GetArgumentCount(BFD, int I = 0)
{
    alias param = BFD.ParameterType;
    static if(param.length <= I)
    {
        enum GetArgumentCount = 0;
    }
    else
    {
        enum tuple = BFD.ParameterStorageClass[I];
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
            enum GetArgumentCount = add + GetArgumentCount!(BFD, I + 1);
        }
        else
        {
            enum GetArgumentCount = add;
        }
    }
}
template IsVariadic(BFD, int I = 0)
{
    alias param = BFD.ParameterType;
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
        enum IsVariadic = IsVariadic!(BFD, I + 1);
    }
}

