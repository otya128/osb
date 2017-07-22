module otya.smilebasic.builtinfunctions;

import std.conv;
import std.typecons;
import std.typetuple;
import std.traits;
import std.stdio;
import std.ascii;
import std.range;
import std.string;
import std.algorithm;
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
struct BasicName
{
    wstring naame;
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
    BuiltinFunction overloadResolution(size_t argc, size_t outargc)
    {
        BuiltinFunction va;
        //とりあえず引数の数で解決させる,というよりコンパイル時に型を取得する方法がない
        foreach(f; func)
        {
            if(f.startskip <= argc && f.argments.length >= argc)
                if((f.outoptional != 0 && f.outoptional <= outargc && f.results.length >= outargc) || f.results.length == outargc)
                return f;
            if(f.variadic)
                va = f;
        }
        //一応可変長は最後
        if(va && ((va.outoptional != 0 && va.outoptional <= outargc && va.results.length >= outargc) || va.results.length == outargc)) return va;
        writeln("====function overloads===");
        writefln("func = %s argc = %d outargc = %d", func[0].name, argc, outargc);
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
template smilebasicFunctionName(string func = __FUNCTION__)
{
    static fn = func[func.lastIndexOf('.') + 1..$];
    auto smilebasicFunctionName()
    {
        return fn;
    }
}
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
    static Value ABS(Value arg1)
    {
        if (arg1.isInteger)
        {
            return Value(abs(arg1.integerValue));
        }
        else
        {
            return Value(abs(arg1.castDouble));
        }
    }
    static pure nothrow @nogc @trusted int SGN(double arg1)
    {
        if (isNaN(arg1))
        {
            return 1;
        }
        return arg1 > 0 ? 1 : arg1 ? -1 : 0;
    }
    static pure nothrow double SIN(double arg1)
    {
        return sin(arg1);
    }
    static double ASIN(double arg1)
    {
        if (arg1 >= -1 && arg1 <= 1)
        {
            return asin(arg1);
        }
        else
        {
            throw new OutOfRange();
        }
    }
    static pure nothrow double SINH(double arg1)
    {
        return sinh(arg1);
    }
    static pure nothrow double COS(double arg1)
    {
        return cos(arg1);
    }
    static double ACOS(double arg1)
    {
        if (arg1 >= -1 && arg1 <= 1)
        {
            return acos(arg1);
        }
        else
        {
            throw new OutOfRange();
        }
    }
    static pure nothrow double COSH(double arg1)
    {
        return cosh(arg1);
    }
    static pure nothrow double TAN(double arg1)
    {
        return tan(arg1);
    }
    static pure nothrow double ATAN(double arg1, DefaultValue!(double, false) arg2)
    {
        if(arg2.isDefault)
        {
            return atan(arg1);
        }
        return atan2(arg1, cast(double)arg2);
    }
    static pure nothrow double TANH(double arg1)
    {
        return tanh(arg1);
    }
    enum Classify
    {
        NORMAL = 0,
        INFINITY = 1,
        NAN = 2,
    }
    static pure nothrow int CLASSIFY(double arg)
    {
        if (arg.isNaN)
        {
            return Classify.NAN;
        }
        if (arg.isInfinity)
        {
            return Classify.INFINITY;
        }
        return Classify.NORMAL;
    }
    static pure nothrow double RAD(double arg1)
    {
        return arg1 * std.math.PI / 180;
    }
    static pure nothrow double DEG(double arg1)
    {
        return arg1 * 180 / std.math.PI;
    }
    static pure nothrow double PI()
    {
        return std.math.PI;
    }
    //static ABS = function double(double x) => abs(this.result == ValueType.Double ? 1 : 0);
    static void LOCATE(PetitComputer p, DefaultValue!int x, DefaultValue!int y, int z)
    {
        if (!x.isDefault && x < 0 || x >= p.console.consoleWidthC)
            throw new OutOfRange(smilebasicFunctionName, 1);
        if (!y.isDefault && y < 0 || y >= p.console.consoleHeightC)
            throw new OutOfRange(smilebasicFunctionName, 2);
        x.setDefaultValue(p.console.CSRX);
        y.setDefaultValue(p.console.CSRY);
        if (z < -256 || z > 1024)
            throw new OutOfRange(smilebasicFunctionName, 3);
        p.console.CSRX = cast(int)x;
        p.console.CSRY = cast(int)y;
        p.console.CSRZ = cast(int)z;
    }
    static void LOCATE(PetitComputer p, DefaultValue!int x, DefaultValue!int y)
    {
        if (!x.isDefault && x < 0 || x >= p.console.consoleWidthC)
            throw new OutOfRange(smilebasicFunctionName, 1);
        if (!y.isDefault && y < 0 || y >= p.console.consoleHeightC)
            throw new OutOfRange(smilebasicFunctionName, 2);
        x.setDefaultValue(p.console.CSRX);
        y.setDefaultValue(p.console.CSRY);
        p.console.CSRX = cast(int)x;
        p.console.CSRY = cast(int)y;
    }
    static void COLOR(PetitComputer p, DefaultValue!int fore, DefaultValue!(int, false) back)
    {
        fore.setDefaultValue(p.console.foreColor);
        back.setDefaultValue(p.console.backColor);
        p.console.foreColor = cast(int)fore;
        p.console.backColor = cast(int)back;
    }
    static void ATTR(PetitComputer p, int attr)
    {
        if (attr < 0 || attr > 15)
            throw new OutOfRange("ATTR", 1);
        p.console.attr = cast(otya.smilebasic.console.ConsoleAttribute)attr;
    }
    static void WIDTH(PetitComputer p, int width)
    {
        if (width != 8 && width != 16)
        {
            throw new IllegalFunctionCall("WIDTH", 1);
        }
        p.console.width = width;
    }
    static int WIDTH(PetitComputer p)
    {
        return p.console.width;
    }
    static void VSYNC(PetitComputer p)
    {
        VSYNC(p, 1);
    }
    static void VSYNC(PetitComputer p, int time)
    {
        p.vsync(time);
    }
    static void WAIT(PetitComputer p, DefaultValue!int time)
    {
        time.setDefaultValue(1);
        p.wait(cast(int)time);
    }
    //TODO:プチコンのCLSには引数の個数制限がない
    static void CLS(PetitComputer p/*vaarg*/)
    {
        p.console.cls;
    }
    static void ASSERT__(PetitComputer p, int cond, wstring message)
    {
        if(!cond)
        {
            p.console.print("Assertion failed: ", message, "\n");
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
    static void BREPEAT(PetitComputer p, int btnid, int startTime, int interval)
    {
        stderr.writefln("NOTIMPL:BREPEAT %d, %d, %d", btnid, startTime, interval);
    }
    static void VISIBLE(PetitComputer p, int console, int graphic, int BG, int sprite)
    {
        import std.exception : enforce;
        enforce(console == 0 || console == 1, new OutOfRange("VISIBLE", 1));
        enforce(graphic == 0 || graphic == 1, new OutOfRange("VISIBLE", 2));
        enforce(BG == 0 || BG == 1, new OutOfRange("VISIBLE", 3));
        enforce(sprite == 0 || sprite == 1, new OutOfRange("VISIBLE", 4));
        p.console.visible = cast(bool)console;
        p.graphic.visible = cast(bool)graphic;
        p.BGvisible = cast(bool)BG;
        p.sprite.visible = cast(bool)sprite;
    }
    static void BACKCOLOR(PetitComputer p, int color)
    {
        p.backcolor = color;
    }
    static int BACKCOLOR(PetitComputer p)
    {
        return p.backcolor;
    }
    static void TOUCH(PetitComputer p, out int tm, out int tchx, out int tchy)
    {
        auto pos = p.touchPosition;
        tm = pos.tm;
        if (p.x.mode == PetitComputer.XMode.WIIU)
        {
            tchx = pos.display1X;
            tchy = pos.display1Y;
        }
        else
        {
            tchx = pos.x;
            tchy = pos.y;
        }
    }
    static void TOUCH(PetitComputer p, int id, out int tm, out int tchx, out int tchy)
    {
        //BIG
        if (p.x.mode == PetitComputer.XMode.WIIU)
        {
            auto pos = p.touchPosition;
            tm = pos.tm;
            if (id == 0)
            {
                tchx = pos.display1X;
                tchy = pos.display1Y;
            }
            else
            {
                tchx = pos.gamepadX;
                tchy = pos.gamepadY;
            }
        }
        else
        {
            writeln("NOTIMPL:TOUCH MPID");
            tm = tchx = tchy = 0;
        }
    }
    static void XSCREEN(PetitComputer p, int mode, int tv, int gamepad, int sp, int bg)
    {
        if (p.x.mode != PetitComputer.XMode.WIIU || mode != 6)
        {
            throw new IllegalFunctionCall("XSCREEN");
        }
        p.xscreen(mode, tv, gamepad, sp, bg);
    }
    static void XSCREEN(PetitComputer p, int mode, int tv, int sp, int bg)
    {
        if (p.x.mode != PetitComputer.XMode.WIIU || mode != 5)
        {
            throw new IllegalFunctionCall("XSCREEN");
        }
        p.xscreen(mode, tv, sp, bg);
    }
    static void XSCREEN(PetitComputer p, int mode, int tv)
    {
        XSCREEN(p, mode, tv, 4096, 4);
    }
    static void XSCREEN(PetitComputer p, int mode)
    {
        if(mode == 2 || mode == 3)
        {
            p.xscreen(mode, 256, 2);
        }
        else
        {
            p.xscreen(mode, 512, 4);
        }
    }
    static void XSCREEN(PetitComputer p, int mode, int sp, int bg)
    {
        if (mode == 6)
        {
            XSCREEN(p, mode, sp, bg, 2048, 2);
            return;
        }
        p.xscreen(mode, sp, bg);
    }
    static void DISPLAY(PetitComputer p, int display)
    {
        if (p.currentDisplay.count <= display || display < 0)
            throw new OutOfRange("DISPLAY", 1);
        p.display(display);
    }
    static int DISPLAY(PetitComputer p)
    {
        return p.displaynum;
    }
    static void GCLS(PetitComputer p)
    {
        p.graphic.gcls(p.graphic.useGRP, 0);
    }
    static void GCLS(PetitComputer p, int color)
    {
        p.graphic.gcls(p.graphic.useGRP, color);
    }
    static void GPSET(PetitComputer p, int x, int y, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gpset(p.graphic.useGRP, x, y, cast(int)color);
    }
    static void GLINE(PetitComputer p, int x, int y, int x2, int y2, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gline(p.graphic.useGRP, x, y, x2, y2, cast(int)color);
    }
    static void GBOX(PetitComputer p, int x, int y, int x2, int y2, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gbox(p.graphic.useGRP, x, y, x2, y2, cast(int)color);
    }
    static void GFILL(PetitComputer p, int x, int y, int x2, int y2, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gfill(p.graphic.useGRP, x, y, x2, y2, cast(int)color);
    }
    //X,Y,R[,COLOR]
    //X,Y,R,SR,ER[,COLOR]
    static void GCIRCLE(PetitComputer p, int x, int y, int r, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gcircle(p.graphic.useGRP, x, y, r, cast(int)color);
    }
    static void GCIRCLE(PetitComputer p, int x, int y, int r, int sr, int er, DefaultValue!(int, false) flag, DefaultValue!(int, false) color)
    {
        color.setDefaultValue(p.graphic.gcolor);
        flag.setDefaultValue(0);
        p.graphic.gcircle(p.graphic.useGRP, x, y, r, sr, er, cast(int)flag, cast(int)color);
    }
    static void GCOLOR(PetitComputer p, int color)
    {
        p.graphic.gcolor = color;
    }
    static int GCOLOR(PetitComputer p)
    {
        return p.graphic.gcolor;
    }
    static void GPRIO(PetitComputer p, int z)
    {
        p.graphic.gprio = z;
    }
    static void GPAGE(PetitComputer p, int showPage, int usePage)
    {
        p.graphic.showGRP = showPage;
        p.graphic.useGRP = usePage;
    }
    static void GPAGE(PetitComputer p, out int showPage, out int usePage)
    {
        showPage = p.graphic.showGRP;
        usePage = p.graphic.useGRP;
    }
    static void GCLIP(PetitComputer p, int clipmode)
    {
        p.graphic.clip(cast(bool)clipmode/*not checked*/);
    }
    static void GCLIP(PetitComputer p, int clipmode, int sx, int sy, int ex, int ey)
    {
        if (sx < 0 || sy < 0 || ex < 0 || ey < 0)
            throw new OutOfRange("GCLIP");
        if (clipmode)
        {
            if (sx >= p.graphic.width || sy >= p.graphic.height || ex >= p.graphic.width || ey >= p.graphic.height)
                throw new OutOfRange("GCLIP");
        }
        if (sx > ex)
        {
            swap(sx, ex);
        }
        if (sy > ey)
        {
            swap(sy, ey);
        }
        int x = sx;
        int y = sy;
        int w = ex - sx + 1;
        int h = ey - sy + 1;
        p.graphic.clip(cast(bool)clipmode/*not checked*/, x, y, w, h);
    }
    static void GPAINT(PetitComputer p, int x, int y, DefaultValue!(int, false) color, DefaultValue!(int, false) color2)
    {
        color.setDefaultValue(p.graphic.gcolor);
        p.graphic.gpaint(p.graphic.useGRP, x, y, cast(int)color);
    }
    static void GPUTCHR(PetitComputer p, int x, int y, Value str)
    {
        GPUTCHR(p, x, y, str, 1, 1, p.graphic.gcolor);
    }
    static void GPUTCHR(PetitComputer p, int x, int y, Value str, int color)
    {
        GPUTCHR(p, x, y, str, 1, 1, color);
    }
    static void GPUTCHR(PetitComputer p, int x, int y, Value str, int scalex, int scaley)
    {
        GPUTCHR(p, x, y, str, scalex, scaley, p.graphic.gcolor);
    }
    static void GPUTCHR(PetitComputer p, int x, int y, Value str, int scalex, int scaley, int color)
    {
        if (str.isNumber)
        {
            p.graphic.gputchr(p.graphic.useGRP, x, y, str.castInteger, scalex, scaley, color);
        }
        else if (str.isString)
        {
            p.graphic.gputchr(p.graphic.useGRP, x, y, str.castDString, scalex, scaley, color);
        }
        else
        {
            throw new TypeMismatch("GPUTCHR", 3);
        }
    }
    static int GSPOIT(PetitComputer p, int x, int y)
    {
        return p.graphic.gspoit(p.graphic.useGRP, x, y);
    }
    static void GSAVE(PetitComputer p, int savepage, int x, int y, int w, int h, Value ary, int flag)
    {
        if (w < 0)
            throw new OutOfRange("GSAVE", 4);
        if (h < 0)
            throw new OutOfRange("GSAVE", 5);
        if (!ary.isNumberArray)
            throw new TypeMismatch("GSAVE", 6);
        int size = w * h;
        if (ary.dimCount != 1 && size > ary.length)
        {
            throw new SubscriptOutOfRange("GSAVE", 6);
        }
        if (ary.type == ValueType.IntegerArray)
        {
            if (size > ary.length)
            {
                if (ary.dimCount == 1)
                {
                    ary.integerArray.length = size;
                }
            }
            p.graphic.gsave(savepage, x, y, w, h, ary.integerArray.array, flag);
        }
        else if (ary.type == ValueType.DoubleArray)
        {
            if (size > ary.length)
            {
                if (ary.dimCount == 1)
                {
                    ary.doubleArray.length = size;
                }
            }
            p.graphic.gsave(savepage, x, y, w, h, ary.doubleArray.array, flag);
        }   
    }
    static void GSAVE(PetitComputer p, int x, int y, int w, int h, Value ary, int flag)
    {
        if (w < 0)
            throw new OutOfRange("GSAVE", 3);
        if (h < 0)
            throw new OutOfRange("GSAVE", 4);
        if (!ary.isNumberArray)
            throw new TypeMismatch("GSAVE", 5);
        int size = w * h;
        if (ary.dimCount != 1 && size > ary.length)
        {
            throw new SubscriptOutOfRange("GSAVE", 5);
        }
        GSAVE(p, p.graphic.useGRP, x, y, w, h, ary, flag);
    }
    static void GSAVE(PetitComputer p, int savepage, Value ary, int flag)
    {
        if (!ary.isNumberArray)
            throw new TypeMismatch("GSAVE", 2);
        auto writeArea = p.graphic.writeArea[p.displaynum];
        int size = writeArea.w * writeArea.h;
        if (ary.dimCount != 1 && size > ary.length)
        {
            throw new SubscriptOutOfRange("GSAVE", 2);
        }
        GSAVE(p, savepage, writeArea.x, writeArea.y, writeArea.w, writeArea.h, ary, flag);
    }
    static void GSAVE(PetitComputer p, Value ary, int flag)
    {
        if (!ary.isNumberArray)
            throw new TypeMismatch("GSAVE", 1);
        auto writeArea = p.graphic.writeArea[p.displaynum];
        int size = writeArea.h * writeArea.h;
        if (ary.dimCount != 1 && size > ary.length)
        {
            throw new SubscriptOutOfRange("GSAVE", 1);
        }
        GSAVE(p, p.graphic.useGRP, ary, flag);
    }
    static void GLOAD(PetitComputer p, int x, int y, int w, int h, Value ary, Value flagOrPalette, int copymode)
    {
        if (!ary.isNumberArray)
        {
            throw new TypeMismatch("GLOAD", 5);
        }
        if (w < 0)
            throw new OutOfRange("GLOAD", 3);
        if (h < 0)
            throw new OutOfRange("GLOAD", 4);
        if (w * h > ary.length)
        {
            throw new SubscriptOutOfRange("GLOAD", 5);
        }
        if (flagOrPalette.isNumber)
        {
            int colorflag = flagOrPalette.castInteger;
            if (ary.type == ValueType.IntegerArray)
            {
                p.graphic.gload(p.graphic.useGRP, x, y, w, h, ary.integerArray.array, colorflag, copymode);
            }
            if (ary.type == ValueType.DoubleArray)
            {
                p.graphic.gload(p.graphic.useGRP, x, y, w, h, ary.doubleArray.array, colorflag, copymode);
            }
        }
        else if (flagOrPalette.isNumberArray)
        {
            if (ary.type == ValueType.IntegerArray)
            {
                if (flagOrPalette.type == ValueType.IntegerArray)
                {
                    p.graphic.gloadPalette(x, y, w, h, ary.integerArray.array, flagOrPalette.integerArray.array, copymode);
                }
                if (flagOrPalette.type == ValueType.DoubleArray)
                {
                    p.graphic.gloadPalette(x, y, w, h, ary.integerArray.array, flagOrPalette.doubleArray.array, copymode);
                }
            }
            if (ary.type == ValueType.DoubleArray)
            {
                if (flagOrPalette.type == ValueType.IntegerArray)
                {
                    p.graphic.gloadPalette(x, y, w, h, ary.doubleArray.array, flagOrPalette.integerArray.array, copymode);
                }
                if (flagOrPalette.type == ValueType.DoubleArray)
                {
                    p.graphic.gloadPalette(x, y, w, h, ary.doubleArray.array, flagOrPalette.doubleArray.array, copymode);
                }
            }
        }
        else
        {
            throw new TypeMismatch("GLOAD", 6);
        }
    }
    static void GLOAD(PetitComputer p, Value ary, Value flagOrPalette, int copymode)
    {
        if (!ary.isNumberArray)
        {
            throw new TypeMismatch("GLOAD", 1);
        }
        auto writeArea = p.graphic.writeArea[p.displaynum];
        if (writeArea.w * writeArea.h > ary.length)
        {
            throw new SubscriptOutOfRange("GLOAD", 1);
        }
        if (!flagOrPalette.isNumber && !flagOrPalette.isNumberArray)
        {
            throw new TypeMismatch("GLOAD", 2);
        }
        GLOAD(p, writeArea.x, writeArea.y, writeArea.w, writeArea.h, ary, flagOrPalette, copymode);
    }
    static void GCOPY(PetitComputer p, int srcpage, int x, int y, int x2, int y2, int x3, int y3, int cpmode)
    {
        p.graphic.gcopy(srcpage, x, y, x2, y2, x3, y3, cpmode);
    }
    static void GCOPY(PetitComputer p, int x, int y, int x2, int y2, int x3, int y3, int cpmode)
    {
        GCOPY(p, p.graphic.useGRP, x, y, x2, y2, x3, y3, cpmode);
    }
    static void GTRI(PetitComputer p, int x1, int y1, int x2, int y2, int x3, int y3, int color)
    {
        p.graphic.gtri(x1, y1, x2, y2, x3, y3, color);
    }
    static void GTRI(PetitComputer p, int x1, int y1, int x2, int y2, int x3, int y3)
    {
        p.graphic.gtri(x1, y1, x2, y2, x3, y3, p.graphic.gcolor);
    }
    static void BGMPLAY(PetitComputer p, Value numberOrMML)
    {
        if (numberOrMML.isNumber)
        {
            int number = numberOrMML.castInteger;
        }
        else if (numberOrMML.isString)
        {
            wstring mml = numberOrMML.castDString;
        }
        else
        {
            throw new TypeMismatch("BGMPLAY", 1);
        }
    }
    static void BGMPLAY(PetitComputer p, int track, int number)
    {
    }
    static void BGMPLAY(PetitComputer p, int track, int number, int volume)
    {
    }
    static void BEEP(PetitComputer p, DefaultValue!(int, false) beep, DefaultValue!(int, false) pitch, DefaultValue!(int, false) volume, DefaultValue!(int, false) pan)
    {
    }
    static void STICK(PetitComputer p, DefaultValue!(int, false) mp, out double x, out double y)
    {
        auto s = p.stick(0);
        x = s.x;
        y = s.y;
    }
    static void STICKEX(PetitComputer p, DefaultValue!(int, false) mp, out double x, out double y)
    {
        auto s = p.stick(1);
        x = s.x;
        y = s.y;
    }
    static pure nothrow int RGB(int R, int G, int B, DefaultValue!(int, false) _)
    {
        if(!_.isDefault)
        {
            //やや強引なオーバーロード
            return PetitComputer.RGB(cast(ubyte)R, cast(ubyte)G, cast(ubyte)B, cast(ubyte)_);
        }
        return PetitComputer.RGB(cast(ubyte)R, cast(ubyte)G, cast(ubyte)B);
    }
    static pure nothrow void RGBREAD(int color, out int R, out int G, out int B)
    {
        int _;
        PetitComputer.RGBRead(color, R, G, B, _);
    }
    static pure nothrow void RGBREAD(int color, out int A, out int R, out int G, out int B)
    {
        PetitComputer.RGBRead(color, R, G, B, A);
    }
    static void RANDOMIZE(PetitComputer p, int seedid)
    {
        p.random.randomize(seedid);
    }
    static void RANDOMIZE(PetitComputer p, int seedid, int seed)
    {
        p.random.randomize(seedid, seed);
    }
    static int RND(PetitComputer p, int seedid, int max)
    {
        return p.random.random(seedid, 0, max);
    }
    static double RNDF(PetitComputer p, int seedid)
    {
        return p.random.RNDF(seedid);
    }
    static int RND(PetitComputer p, int max)
    {
        return p.random.random(0, 0, max);
    }
    static double RNDF(PetitComputer p)
    {
        return p.random.RNDF(0);
    }
    @StartOptional("W")
    static void DTREAD(out int Y, out int M, out int D, out int W)
    {
        import std.datetime;
        auto currentTime = Clock.currTime();
        Y = currentTime.year;
        M = currentTime.month;
        D = currentTime.day;
        W = cast(int)currentTime.dayOfWeek;//Represents the 7 days of the Gregorian week (Sunday is 0).
    }
    @StartOptional("W")
    static void DTREAD(wstring date, out int Y, out int M, out int D, out int W)
    {
        import std.datetime;
        import std.format;
        auto v = date;
        formattedRead(v, "%d/%d/%d", &Y, &M, &D);
        W = cast(int)DateTime(Y, M, D).dayOfWeek;
    }
    static void TMREAD(out int H, out int M, out int S)
    {
        import std.datetime;
        auto currentTime = Clock.currTime();
        H = currentTime.hour;
        M = currentTime.minute;
        S = currentTime.second;
    }
    static void TMREAD(wstring time, out int H, out int M, out int S)
    {
        import std.datetime;
        import std.format;
        try
        {
            formattedRead(time, "%d:%d:%d", &H, &M, &S);
        }
        catch (Throwable)
        {
            throw new IllegalFunctionCall("TMREAD", 1);
        }
        if (!time.empty)
        {
            throw new IllegalFunctionCall("TMREAD", 1);
        }
        if (H < 0 || M < 0 || S < 0 || H > 99 || M > 99 || S > 99)
            throw new IllegalFunctionCall("TMREAD", 1);
    }
    static int LEN(Value ary)
    {
        return ary.length;
    }

    static bool tryParse(Target, Source)(ref Source p, out Target result)
        if (isInputRange!Source && isSomeChar!(ElementType!Source) && !is(Source == enum) &&
            isFloatingPoint!Target && !is(Target == enum))
        {
            static import core.stdc.math;
            static immutable real[14] negtab =
            [ 1e-4096L,1e-2048L,1e-1024L,1e-512L,1e-256L,1e-128L,1e-64L,1e-32L,
            1e-16L,1e-8L,1e-4L,1e-2L,1e-1L,1.0L ];
            static immutable real[13] postab =
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
                    if(p.empty) return 0;
                    //enforce(!p.empty, bailOut());
                    break;
                case '+':
                    p.popFront();
                    if(p.empty) return 0;
                    //enforce(!p.empty, bailOut());
                    break;
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

    /// ditto
    static bool tryParse(Target, Source)(ref Source s, uint radix, out Target result)
        if (isSomeChar!(ElementType!Source) &&
            isIntegral!Target && !is(Target == enum))
    {
        if (!(radix >= 2 && radix <= 36))
        {
            result = 0;
            return false;
        }
        import core.checkedint : mulu, addu;

        immutable uint beyond = (radix < 10 ? '0' : 'a'-10) + radix;

        Target v = 0;
        bool atStart = true;

        for (; !s.empty; s.popFront())
        {
            uint c = s.front;
            if (c < '0')
                break;
            if (radix < 10)
            {
                if (c >= beyond)
                    break;
            }
            else
            {
                if (c > '9')
                {
                    c |= 0x20;//poorman's tolower
                    if (c < 'a' || c >= beyond)
                        break;
                    c -= 'a'-10-'0';
                }
            }

            bool overflow = false;
            auto nextv = v.mulu(radix, overflow).addu(c - '0', overflow);
            if (overflow || nextv > Target.max)
                goto Loverflow;
            v = cast(Target) nextv;

            atStart = false;
        }
        if (atStart)
            goto Lerr;
        result = v;
        return true;

    Loverflow:
        result = 0;
        return false;
    Lerr:
        result = 0;
        return false;
    }
    static double VAL(wstring str)
    {
        munch(str, " ");
        if(str.length > 2 && str[0..2] == "&H")
        {
            uint r;
            str = str[2..$];
            if (tryParse!(uint, wstring)(str, 16, r))
            {
                if (!str.empty)
                    return 0;
                return cast(int)r;
            }
            else
            {
                return 0;
            }
        }
        if(str.length > 2 && str[0..2] == "&B")
        {
            uint r;
            str = str[2..$];
            if (tryParse!(uint, wstring)(str, 2, r))
            {
                if (!str.empty)
                    return 0;
                return cast(int)r;
            }
            else
            {
                return 0;
            }
        }
        double val;
        if(tryParse(str, val) && str.empty)
            return val;
        else
            return 0;
    }
    static Value FLOOR(Value val)
    {
        if (!val.isNumber)
        {
            throw new TypeMismatch("FLOOR");
        }
        if (val.isInteger)
        {
            return val;
        }

        return Value(val.doubleValue.floor);
    }
    static Value ROUND(Value val)
    {
        if (!val.isNumber)
        {
            throw new TypeMismatch("ROUND");
        }
        if (val.isInteger)
        {
            return val;
        }

        return Value(val.doubleValue.round);
    }
    static Value CEIL(Value val)
    {
        if (!val.isNumber)
        {
            throw new TypeMismatch("CEIL");
        }
        if (val.isInteger)
        {
            return val;
        }

        return Value(val.doubleValue.ceil);
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
        if (len >= str.length)
        {
            return str;
        }
        return str[0..len];
    }
    static wstring RIGHT(wstring str, int len)
    {
        if (len >= str.length)
        {
            return str;
        }
        return str[$ - len..$];
    }
    static wstring SUBST(wstring str, int i, Value alen, DefaultValue!(Value,false) areplace)
    {
        int len = 1;
        wstring replace = "";
        if(alen.isNumber)
        {
            len = alen.castInteger;
            replace = areplace.castDString;
        }
        else
        {
            replace = alen.castDString;
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
        int start = 0;
        wstring str1, str2;
        if(!vstr2.isDefault)
        {
            start = vstart.castInteger;
            str1 = vstr1.castDString;
            str2 = cast(wstring)vstr2;
        }
        else
        {
            str1 = vstart.castDString;
            str2 = vstr1.castDString;
        }
        ptrdiff_t index = str1[start..$].indexOf(str2);
        if (index == -1)
            return -1;
        else
            return cast(int)(index + start);
    }
    static int ASC(wstring str)
    {
        if(str.empty)
            throw new IllegalFunctionCall("ASC");
        return cast(int)str[0];
    }
    static wstring STR(double val)
    {
        return val.to!wstring;
    }
    static wstring STR(double val, int digits)
    {
        //formatだとうまくいかない
        if(digits > 63 || digits < 0)
        {
            throw new OutOfRange();
        }
        auto str = val.to!wstring;
        if (str.length >= digits)
            return str;
        wchar[64] str2;
        str2[0..digits - str.length] = ' ';
        str2[digits - str.length..digits] = str;
        return str2[0..digits].to!wstring;
    }
    /+
    HEX$(1,0)=>1
    HEX$(1)=>1
    HEX$(1,)=>1(???)
    HEX$(1,2)=>01
    +/
    static wstring HEX(int val, DefaultValue!(int, false) digits)
    {
        import std.format;
        if(digits > 8 || digits < 0)
        {
            throw new OutOfRange("HEX$", 2);
        }
        FormatSpec!char f;
        f.spec = 'X';
        f.flZero = !digits.isDefault;
        f.width = cast(int)digits;
        auto w = appender!wstring();
        formatValue(w, val, f);
        return cast(immutable)(w.data);
    }
    /+
    BIN$(1,0)=>1
    BIN$(1)=>1
    BIN$(1,)=>Type mismatch(BIN$:2)
    BIN$(1,2)=>01
    +/
    static wstring BIN(int val)
    {
        return val.to!wstring(2);
    }
    static wstring BIN(int val, int digits)
    {
        import std.format;
        if(digits > 32 || digits < 0)
        {
            throw new OutOfRange("BIN$", 2);
        }
        FormatSpec!char f;
        f.spec = 'b';
        f.flZero = true;
        f.width = digits;
        auto w = appender!wstring();
        formatValue(w, val, f);
        return cast(immutable)(w.data);
    }
    static void SPSET(PetitComputer p, int id, int defno)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isValidDef(defno))
        {
            throw new OutOfRange(smilebasicFunctionName, 2);
        }
        p.sprite.spset(id, defno);
    }
    static void SPSET(PetitComputer p, int id, int U, int V)
    {
        SPSET(p, id, U, V, 16, 16, 1);
    }
    static void SPSET(PetitComputer p, int id, int U, int V, int ATTR)
    {
        SPSET(p, id, U, V, 16, 16, ATTR);
    }
    static void SPSET(PetitComputer p, int id, int U, int V, int W, int H)
    {
        SPSET(p, id, U, V, W, H, 1);
    }
    static void SPSET(PetitComputer p, int id, int u, int v, int w, int h, int attr)
    {
        if (!p.sprite.isValidSpriteId(id))
            throw new OutOfRange(smilebasicFunctionName, 1);
        if (u < 0)
            throw new OutOfRange(smilebasicFunctionName, 2);
        if (v < 0)
            throw new OutOfRange(smilebasicFunctionName, 3);
        if (w > p.graphic.width || w < 0)
            throw new OutOfRange(smilebasicFunctionName, 4);
        if (h > p.graphic.height || h < 0)
            throw new OutOfRange(smilebasicFunctionName, 5);
        if (u + w > p.graphic.width)
            throw new OutOfRange(smilebasicFunctionName);
        if (v + h > p.graphic.height)
            throw new OutOfRange(smilebasicFunctionName);
        p.sprite.spset(id, u, v, w, h, cast(SpriteAttr)attr);
    }
    static void SPSET(PetitComputer p, int lower, int upper, int defno, out int ix)
    {
        if (!p.sprite.isValidSpriteId(upper))
            throw new OutOfRange("SPSET", 1);
        if (!p.sprite.isValidSpriteId(lower))
            throw new OutOfRange("SPSET", 2);
        if (upper < lower)
            throw new IllegalFunctionCall("SPSET", 2);
        if (!p.sprite.isValidDef(defno))
        {
            throw new OutOfRange(smilebasicFunctionName, 3);
        }
        ix = p.sprite.allocSprite(lower, upper);
        if (ix == -1)
            return;
        p.sprite.spset(ix, defno);
    }
    static void SPSET(PetitComputer p, int upper, int lower, int u, int v, out int ix)
    {
        SPSET(p, upper, lower, u, v, 16, 16, 0x01, ix);
    }
    static void SPSET(PetitComputer p, int upper, int lower, int u, int v, int w, int h, out int ix)
    {
        SPSET(p, upper, lower, u, v, w, h, 0x01, ix);
    }
    static void SPSET(PetitComputer p, int lower, int upper, int u, int v, int w, int h, int attr, out int ix)
    {
        if (!p.sprite.isValidSpriteId(upper))
            throw new OutOfRange("SPSET", 1);
        if (!p.sprite.isValidSpriteId(lower))
            throw new OutOfRange("SPSET", 2);
        if (upper < lower)
            throw new IllegalFunctionCall("SPSET", 2);
        if (u < 0)
            throw new OutOfRange(smilebasicFunctionName, 3);
        if (v < 0)
            throw new OutOfRange(smilebasicFunctionName, 4);
        if (w > p.graphic.width || w < 0)
            throw new OutOfRange(smilebasicFunctionName, 5);
        if (h > p.graphic.height || h < 0)
            throw new OutOfRange(smilebasicFunctionName, 6);
        if (u + w > p.graphic.width)
            throw new OutOfRange(smilebasicFunctionName);
        if (v + h > p.graphic.height)
            throw new OutOfRange(smilebasicFunctionName);
        ix = p.sprite.allocSprite(lower, upper);
        if (ix == -1)
            return;
        p.sprite.spset(ix, u, v, w, h, cast(SpriteAttr)attr);
    }
    static void SPSET(PetitComputer p, int defno, out int ix)
    {
        if (!p.sprite.isValidDef(defno))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        ix = p.sprite.allocSprite();
        if (ix == -1)
            return;
        p.sprite.spset(ix, defno);
    }
    static void SPSET(PetitComputer p, int u, int v, int w, int h, int attr, out int ix)
    {
        if (u < 0)
            throw new OutOfRange(smilebasicFunctionName, 1);
        if (v < 0)
            throw new OutOfRange(smilebasicFunctionName, 2);
        if (w > p.graphic.width || w < 0)
            throw new OutOfRange(smilebasicFunctionName, 3);
        if (h > p.graphic.height || h < 0)
            throw new OutOfRange(smilebasicFunctionName, 4);
        if (u + w > p.graphic.width)
            throw new OutOfRange(smilebasicFunctionName);
        if (v + h > p.graphic.height)
            throw new OutOfRange(smilebasicFunctionName);
        ix = p.sprite.allocSprite();
        if (ix == -1)
            return;
        p.sprite.spset(ix, u, v, w, h, cast(SpriteAttr)attr);
    }
    static void SPCHR(PetitComputer p, int id, int defno)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isValidDef(defno))
        {
            throw new OutOfRange(smilebasicFunctionName, 2);
        }
        p.sprite.spchr(id, defno);
    }
    static void SPCHR(PetitComputer p, int id, int U, int V)
    {
        SPCHR(p, id, U, V, 16, 16, 1);
    }
    static void SPCHR(PetitComputer p, int id, int U, int V, int ATTR)
    {
        SPCHR(p, id, U, V, 16, 16, ATTR);
    }
    static void SPCHR(PetitComputer p, int id, int U, int V, int W, int H)
    {
        SPCHR(p, id, U, V, W, H, 1);
    }
    static void SPCHR(PetitComputer p, int id, int u, int v, int w, int h, int attr)
    {
        if (!p.sprite.isValidSpriteId(id))
            throw new OutOfRange(smilebasicFunctionName, 1);
        if (!p.sprite.isSpriteDefined(id))
            throw new IllegalFunctionCall(smilebasicFunctionName, 1);
        if (u < 0)
            throw new OutOfRange(smilebasicFunctionName, 2);
        if (v < 0)
            throw new OutOfRange(smilebasicFunctionName, 3);
        if (w > p.graphic.width || w < 0)
            throw new OutOfRange(smilebasicFunctionName, 4);
        if (h > p.graphic.height || h < 0)
            throw new OutOfRange(smilebasicFunctionName, 5);
        if (u + w > p.graphic.width)
            throw new OutOfRange(smilebasicFunctionName);
        if (v + h > p.graphic.height)
            throw new OutOfRange(smilebasicFunctionName);
        p.sprite.spchr(id, u, v, w, h, cast(SpriteAttr)attr);
    }
    static void SPCHR(PetitComputer p, int id, out int defno)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isValidDef(defno))
        {
            throw new OutOfRange(smilebasicFunctionName, 2);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCHR", 1);
        }
        p.sprite.getSpchr(id, defno);
    }
    static void SPCHR(PetitComputer p, int id, out int u, out int v, out int w, out int h, out int attr)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCHR", 1);
        }
        SpriteAttr spriteattr;
        p.sprite.getSpchr(id, u, v, w, h, spriteattr);
        attr = cast(int)spriteattr;
    }
    static void SPCHR(PetitComputer p, int id, out int u, out int v)
    {
        int w, h, attr;
        SPCHR(p, id, u, v, w, h , attr);
    }
    static void SPCHR(PetitComputer p, int id, out int u, out int v, out int attr)
    {
        int w, h;
        SPCHR(p, id, u, v, w, h , attr);
    }
    static void SPCHR(PetitComputer p, int id, out int u, out int v, out int w, out int h)
    {
        int attr;
        SPCHR(p, id, u, v, w, h , attr);
    }
    static void SPHIDE(PetitComputer p, int id)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPHIDE", 1);
        }
        p.sprite.sphide(id);
    }
    static void SPSHOW(PetitComputer p, int id)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPSHOW", 1);
        }
        p.sprite.spshow(id);
    }
    static void SPOFS(PetitComputer p, int id, DefaultValue!double x, DefaultValue!double y, double z)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPOFS", 1);
        }
        if (x.isDefault || y.isDefault)
        {
            double x_, y_, z_;
            p.sprite.getspofs(id, x_, y_, z_);
            x.setDefaultValue(x_);
            y.setDefaultValue(y_);
        }
        p.sprite.spofs(id, cast(double)x, cast(double)y, z);
    }
    static void SPOFS(PetitComputer p, int id, DefaultValue!double x, DefaultValue!double y)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPOFS", 1);
        }
        if (x.isDefault || y.isDefault)
        {
            double x_, y_, z_;
            p.sprite.getspofs(id, x_, y_, z_);
            x.setDefaultValue(x_);
            y.setDefaultValue(y_);
        }
        p.sprite.spofs(id, cast(double)x, cast(double)y);
    }
    @StartOptional("z")
    static void SPOFS(PetitComputer p, int id, out double x, out double y, out double z)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPOFS", 1);
        }
        p.sprite.getspofs(id, x, y, z);
    }
    static void SPANIM(PetitComputer p, Value[] va_args)
    {
        //TODO:配列
        auto args = retro(va_args);
        int no = args[0].castInteger;
        if (!p.sprite.isValidSpriteId(no))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(no))
        {
            throw new IllegalFunctionCall("SPANIM", 1);
        }
        double[] animdata;
        if(args[2].isString)
        {
            VM vm = p.vm;
            vm.restoreData(args[2].castDString);
            int keyframe = vm.readData.castInteger;
            auto target = p.sprite.getSpriteAnimTarget(args[1].castDString);
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
            if(args.length > 3)
                animdata[j] = args[3].castInteger;
            else
                animdata[j] = 1;//loop count
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
            p.sprite.spanim(no, args[1].castDString, animdata);
        if(args[1].isNumber)
            p.sprite.spanim(no, cast(SpriteAnimTarget)(args[1].castInteger), animdata);
    }
    static void SPDEF(PetitComputer p, int id, out int U, out int V)
    {
        if (!p.sprite.isValidDef(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        int dummy;
        p.sprite.getspdef(id, U, V, dummy, dummy, dummy, dummy, dummy);
    }
    static void SPDEF(PetitComputer p, int id, out int U, out int V, out int A)
    {
        if (!p.sprite.isValidDef(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        int dummy;
        p.sprite.getspdef(id, U, V, dummy, dummy, dummy, dummy, A);
    }
    static void SPDEF(PetitComputer p, int id, out int U, out int V, out int W, out int H)
    {
        if (!p.sprite.isValidDef(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        int dummy;
        p.sprite.getspdef(id, U, V, W, H, dummy, dummy, dummy);
    }
    static void SPDEF(PetitComputer p, int id, out int U, out int V, out int W, out int H, out int A)
    {
        if (!p.sprite.isValidDef(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        int dummy;
        p.sprite.getspdef(id, U, V, W, H, dummy, dummy, A);
    }
    static void SPDEF(PetitComputer p, int id, out int U, out int V, out int W, out int H, out int HX, out int HY)
    {
        if (!p.sprite.isValidDef(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        int dummy;
        p.sprite.getspdef(id, U, V, W, H, HX, HY, dummy);
    }
    static void SPDEF(PetitComputer p, int id, out int U, out int V, out int W, out int H, out int HX, out int HY, out int A)
    {
        if (!p.sprite.isValidDef(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
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
                        vm.restoreData(va_args[0].castDString);
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
                        return;
                    }
                    throw new IllegalFunctionCall("SPDEF");
                }
            default:
        }
        {
            int defno = va_args[0].castInteger;
            if (!p.sprite.isValidDef(defno))
            {
                throw new OutOfRange(smilebasicFunctionName, 1);
            }
            int U = va_args[1].castInteger;
            int V = va_args[2].castInteger;
            int W = 16, H = 16, HX = 0, HY = 0, ATTR = 1;
            if (va_args.length == 4)
            {
                ATTR = va_args[3].castInteger;
            }
            else if (va_args.length == 5)
            {
                W = va_args[3].castInteger;
                H = va_args[4].castInteger;
            }
            else if (va_args.length == 6)
            {
                W = va_args[3].castInteger;
                H = va_args[4].castInteger;
                ATTR = va_args[5].castInteger;
            }
            else if (va_args.length == 7)
            {
                W = va_args[3].castInteger;
                H = va_args[4].castInteger;
                HX = va_args[5].castInteger;
                HY = va_args[6].castInteger;
            }
            else if (va_args.length == 8)
            {
                W = va_args[3].castInteger;
                H = va_args[4].castInteger;
                HX = va_args[5].castInteger;
                HY = va_args[6].castInteger;
                ATTR = va_args[7].castInteger;
            }
            else
            {
                throw new IllegalFunctionCall("SPDEF");
            }
            p.sprite.SPDEFTable[defno] = SpriteDef(U, V, W, H, HX, HY, cast(SpriteAttr)ATTR);
        }
    }
    static void SPCLR(PetitComputer p, DefaultValue!(int, false) i)
    {
        //spset is not checked
        if(i.isDefault)
            p.sprite.spclr();
        else
        {
            if (!p.sprite.isValidSpriteId(cast(int)i))
            {
                throw new OutOfRange(smilebasicFunctionName, 1);
            }
            p.sprite.spclr(cast(int)i);
        }
    }
    static void SPHOME(PetitComputer p, int i, int hx, int hy)
    {
        if (!p.sprite.isValidSpriteId(i))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(i))
        {
            throw new IllegalFunctionCall("SPHOME", 1);
        }
        p.sprite.sphome(i, hx, hy);
    }
    static void SPHOME(PetitComputer p, int i, out int hx, out int hy)
    {
        if (!p.sprite.isValidSpriteId(i))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(i))
        {
            throw new IllegalFunctionCall("SPHOME", 1);
        }
        p.sprite.getsphome(i, hx, hy);
    }
    static void SPSCALE(PetitComputer p, int i, double x, double y)
    {
        if (!p.sprite.isValidSpriteId(i))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(i))
        {
            throw new IllegalFunctionCall("SPSCALE", 1);
        }
        p.sprite.spscale(i, x, y);
    }
    static void SPSCALE(PetitComputer p, int i, out double x, out double y)
    {
        if (!p.sprite.isValidSpriteId(i))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(i))
        {
            throw new IllegalFunctionCall("SPSCALE", 1);
        }
        p.sprite.getspscale(i, x, y);
    }
    static void SPROT(PetitComputer p, int i, double rot)
    {
        if (!p.sprite.isValidSpriteId(i))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(i))
        {
            throw new IllegalFunctionCall("SPROT", 1);
        }
        p.sprite.sprot(i, rot);
    }
    static void SPROT(PetitComputer p, int i, out double rot)
    {
        if (!p.sprite.isValidSpriteId(i))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(i))
        {
            throw new IllegalFunctionCall("SPROT", 1);
        }
        p.sprite.getsprot(i, rot);
    }
    static void SPCOLOR(PetitComputer p, int id, int color)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCOLOR", 1);
        }
        p.sprite.spcolor(id, cast(uint)color);
    }
    static void SPCOLOR(PetitComputer p, int id, out int color)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCOLOR", 1);
        }
        p.sprite.getspcolor(id, color);
    }
    static void SPLINK(PetitComputer p, int child, int parent)
    {
        if (!p.sprite.isValidSpriteId(child))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isValidSpriteId(parent))
        {
            throw new OutOfRange(smilebasicFunctionName, 2);
        }
        p.sprite.splink(child, parent);
    }
    static int SPLINK(PetitComputer p, int id)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange("SPLINK", 1);
        }
        return p.sprite.splink(id);
    }
    static void SPUNLINK(PetitComputer p, int id)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPUNLINK", 1);
        }
        p.sprite.spunlink(id);
    }
    static void SPCOL(PetitComputer p, int id, DefaultValue!(int, false) scale)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCOL", 1);
        }
        scale.setDefaultValue(false);
        p.sprite.spcol(id, cast(bool)scale);
    }
    static void SPCOL(PetitComputer p, int id, DefaultValue!int scale, int mask)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCOL", 1);
        }
        scale.setDefaultValue(false);
        p.sprite.spcol(id, cast(bool)scale, mask);
    }
    static void SPCOL(PetitComputer p, int id, int x, int y, int w, int h, int scale)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCOL", 1);
        }
        p.sprite.spcol(id, cast(short)x, cast(short)y, cast(ushort)w, cast(ushort)h, cast(bool)scale, -1);
    }
    static void SPCOL(PetitComputer p, int id, int x, int y, int w, int h, DefaultValue!int scale, int mask)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCOL", 1);
        }
        scale.setDefaultValue(false);
        p.sprite.spcol(id, cast(short)x, cast(short)y, cast(ushort)w, cast(ushort)h, cast(bool)scale, mask);
    }
    static void SPCOL(PetitComputer p, int id, int x, int y, int w, int h, DefaultValue!int scale)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCOL", 1);
        }
        scale.setDefaultValue(false);
        p.sprite.spcol(id, cast(short)x, cast(short)y, cast(ushort)w, cast(ushort)h, cast(bool)scale, -1);
    }
    static void SPCOL(PetitComputer p, int id, int x, int y, int w, int h)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCOL", 1);
        }
        p.sprite.spcol(id, cast(short)x, cast(short)y, cast(ushort)w, cast(ushort)h, false, -1);
    }

    @StartOptional("mask")
    static void SPCOL(PetitComputer p, int id, out int scalable, out int mask)
    {
        int dummy;
        SPCOL(p, id, dummy, dummy, dummy, dummy, scalable, mask);
    }
    @StartOptional("scalable")
    static void SPCOL(PetitComputer p, int id, out int x, out int y, out int w, out int h, out int scalable, out int mask)
    {
        bool s;
        p.sprite.getspcol(id, x, y, w, h, s, mask);
        scalable = cast(int)(s);
    }
    static int SPHITSP(PetitComputer p, int id)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        //spset is not checked
        return p.sprite.sphitsp(id);
    }
    static int SPHITSP(PetitComputer p, int id, int min)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        return p.sprite.sphitsp(id, min, 511);//?
    }
    static int SPHITSP(PetitComputer p, int id, int min, int max)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        return p.sprite.sphitsp(id, min, max);
    }
    static void SPVAR(PetitComputer p, int id, int var, double val)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        //spset is not checked
        p.sprite.spvar(id, var, val);
    }
    static double SPVAR(PetitComputer p, int id, int var)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        return p.sprite.spvar(id, var);
    }
    static int SPCHK(PetitComputer p, int id)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPCHK", 1);
        }
        return p.sprite.spchk(id);
    }
    static void SPPAGE(PetitComputer p, int page)
    {
        if (!p.isValidGraphicPage(page))
        {
            throw new OutOfRange("SPPAGE", 1);
        }
        p.sprite.sppage[p.displaynum] = page;
    }
    static int SPPAGE(PetitComputer p)
    {
        return p.sprite.sppage[p.displaynum];
    }
    static void SPCLIP(PetitComputer p)
    {
        p.sprite.spclip;
    }
    static void SPCLIP(PetitComputer p, int x1, int y1, int x2, int y2)
    {
        p.sprite.spclip(x1, y1, x2, y2);
    }
    static int SPUSED(PetitComputer p, int id)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange("SPUSED", 1);
        }
        return p.sprite.spused(id);
    }
    static void SPFUNC(PetitComputer p, int id, wstring func)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange("SPFUNC", 1);
        }
        /*
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPFUNC", 1);
        }*/
        auto callback = p.vm.createCallback(func);
        if (callback.type == CallbackType.none)
            throw new IllegalFunctionCall("SPFUNC"/*, 2*/);
        p.sprite.spfunc(id, callback);
    }
    static void SPSTART(PetitComputer p, int id)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange("SPSTART", 1);
        }
        
        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPSTART", 1);
        }
        p.sprite.spstart(id);
    }
    static void SPSTART(PetitComputer p)
    {
        p.sprite.spstart();
    }
    static void SPSTOP(PetitComputer p, int id)
    {
        if (!p.sprite.isValidSpriteId(id))
        {
            throw new OutOfRange("SPSTOP", 1);
        }

        if (!p.sprite.isSpriteDefined(id))
        {
            throw new IllegalFunctionCall("SPSTOP", 1);
        }
        p.sprite.spstop(id);
    }
    static void SPSTOP(PetitComputer p)
    {
        p.sprite.spstop();
    }
    static void SPHITINFO(PetitComputer p, out double tm)
    {
        tm = p.sprite.spriteHitInfo.time;
    }
    static void SPHITINFO(PetitComputer p, out double tm, out double x1, out double y1, out double x2, out double y2)
    {
        tm = p.sprite.spriteHitInfo.time;
        x1 = p.sprite.spriteHitInfo.x1;
        y1 = p.sprite.spriteHitInfo.y1;
        x2 = p.sprite.spriteHitInfo.x2;
        y2 = p.sprite.spriteHitInfo.y2;
    }
    static void SPHITINFO(PetitComputer p, out double tm, out double x1, out double y1, out double vx1, out double vy1, out double x2, out double y2, out double vx2, out double vy2)
    {
        tm = p.sprite.spriteHitInfo.time;
        x1 = p.sprite.spriteHitInfo.x1;
        y1 = p.sprite.spriteHitInfo.y1;
        x2 = p.sprite.spriteHitInfo.x2;
        y2 = p.sprite.spriteHitInfo.y2;
        vx1 = p.sprite.spriteHitInfo.vx1;
        vy1 = p.sprite.spriteHitInfo.vy1;
        vx2 = p.sprite.spriteHitInfo.vx2;
        vy2 = p.sprite.spriteHitInfo.vy2;
    }
    static void BGMSTOP(PetitComputer p)
    {
        writeln("NOTIMPL:BGMSTOP");
    }
    static void BGMSTOP(PetitComputer p, int track)
    {
        writefln("NOTIMPL:BGMSTOP %d", track);
    }
    static void BGMSTOP(PetitComputer p, int track, int fade)
    {
        writefln("NOTIMPL:BGMSTOP %d,%d", track, fade);
    }
    static int BGMCHK(PetitComputer p)
    {
        writeln("NOTIMPL:BGMCHK");
        return false;
    }
    static void BGMSETD(int no, wstring label)
    {
        writefln("NOTIMPL:BGMSETD %d,%s", no, label);
    }
    static void BGMSET(int no, wstring mml)
    {
        writefln("NOTIMPL:BGMSET %d,%s", no, mml);
    }
    static int CHKCHR(PetitComputer p, int x, int y)
    {
        return cast(int)(p.console.console[p.displaynum][y][x].character);
    }
    struct FixedBuffer(T, size_t S)
    {
        T[S] buffer = void;
        size_t length;
        void put(T v)
        {
            if (buffer.length <= length)
            {
                throw new StringTooLong("FORMAT$", 2);
            }
            buffer[length++] = v;
        }
    }
    static wstring FORMAT(PetitComputer p, Value[] va_args)
    {
        alias retro!(Value[]) VaArgs;
        auto args = retro(va_args);
        auto format = args[0].castDString;
        import std.array : appender;
        import std.format;
        FixedBuffer!(wchar, 1024) buffer;//String too long
        int j = 1;
        for(int i = 0; i < format.length; i++)
        {
            auto f = format[i];
            if(f == '%')
            {
                i = i + 1;
                bool sign = false;//+
                bool left = false;//-
                bool space = false;//' '
                bool zero = false;
                for(; i < format.length; i++)
                {
                    auto c = format[i];
                    if (c == '+')
                    {
                        sign = true;
                    }
                    else if (c == ' ')
                    {
                        space = true;
                    }
                    else if (c == '-')
                    {
                        left = true;
                    }
                    else if (c == '0')
                    {
                        zero = true;
                    }
                    else
                    {
                        break;
                    }
                }
                int d1, d2 = 6;
                bool d2f;
                wstring a1 = format[i..$];
                if (a1[0] >= '0' && a1[0] <= '9')
                {
                    d1 = parse!(int, wstring)(a1);
                }
                if (a1[0] == '.')
                {
                    a1 = a1[1..$];
                    if (a1[0] >= '0' && a1[0] <= '9')
                    {
                        d2 = parse!(int, wstring)(a1);
                        d2f = true;
                    }
                }
                wstring buf;
                FormatSpec!wchar spec;
                switch (a1[0])
                {
                    case 'S', 's':
                        {
                            auto val = args[j].castDString;
                            spec.width = d1;
                            spec.flDash = left;
                            spec.flZero = zero;
                            spec.flPlus = sign;
                            spec.flSpace = space;
                            formatValue(&buffer, val, spec);
                            break;
                        }
                    case 'X', 'x':
                        spec.spec = 'X';
                        goto caseInteger;
                    case 'B', 'b':
                        spec.spec = 'b';
                        goto caseInteger;
                    case 'D', 'd':
                        spec.spec = 'd';
                        caseInteger:
                        {
                            auto val = args[j].castInteger;
                            spec.width = d1;
                            if (d2f)
                                spec.precision = d2;
                            spec.flDash = left;
                            spec.flZero = zero;
                            spec.flPlus = sign;
                            spec.flSpace = space;
                            formatValue(&buffer, val, spec);
                            break;
                        }
                    case 'F', 'f':
                        {
                            spec.spec = 'f';
                            auto val = args[j].castDouble;
                            spec.width = d1;
                            if (d2 < 1022)
                            {
                                spec.precision = d2;
                                spec.flDash = left;
                                spec.flZero = zero;
                                spec.flPlus = sign;
                                spec.flSpace = space;
                                formatValue(&buffer, val, spec);
                            }
                            break;
                        }
                    default:
                        throw new IllegalFunctionCall("FORMAT$");
                }
                j++;
                i = 0;
                format = a1;
                continue;
            }
            buffer.put(f);
        }
        wchar[] data = new wchar[buffer.length];
        data[] = buffer.buffer[0..buffer.length];
        return cast(immutable)data;
    }
    static wstring CHR(int code)
    {
        return (cast(wchar)code).to!wstring;
    }
    static pure nothrow double POW(double a1, double a2)
    {
        return a1 ^^ a2;
    }
    static double SQR(double a1)
    {
        if (a1 < 0)
        {
            throw new OutOfRange();
        }
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
        if (!p.isValidLayer(cast(int)layer))
        {
            throw new OutOfRange("BGCLR", 1);
        }
        p.getBG(cast(int)layer).clear;
    }
    static void BGSCREEN(PetitComputer p, int layer, int w, int h)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGSCREEN", 1);
        }
        p.getBG(layer).screen(w, h);
    }
    static void BGOFS(PetitComputer p, int layer, int x, int y, DefaultValue!(int, false) z)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGOFS", 1);
        }
        z.setDefaultValue(p.getBG(layer).offsetz);
        p.getBG(layer).ofs(x, y, cast(int)z);
    }
    static void BGCLIP(PetitComputer p, int layer)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGCLIP", 1);
        }
        p.getBG(layer).clip();
    }
    static void BGCLIP(PetitComputer p, int layer, int x, int y, int x2, int y2)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGCLIP", 1);
        }
        p.getBG(layer).clip(x, y, x2, y2);
    }
    static void BGPUT(PetitComputer p, int layer, int x, int y, int screendata)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGPUT", 1);
        }
        if (x < 0 || x >= p.getBG(layer).width)
        {
            throw new OutOfRange("BGPUT", 2);
        }
        if (y < 0 || y >= p.getBG(layer).height)
        {
            throw new OutOfRange("BGPUT", 3);
        }
        p.getBG(layer).put(x, y, screendata);
    }
    static void BGHOME(PetitComputer p, int layer, int x, int y)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGHOME", 1);
        }
        p.getBG(layer).home(x, y);
    }
    static void BGSCALE(PetitComputer p, int layer, double x, double y)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGSCALE", 1);
        }
        p.getBG(layer).scale(x, y);
    }
    static void BGSCALE(PetitComputer p, int layer, out double x, out double y)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGSCALE", 1);
        }
        p.getBG(layer).getScale(x, y);
    }
    static void BGROT(PetitComputer p, int layer, int rot)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGROT", 1);
        }
        p.getBG(layer).rot(rot);
    }
    static int BGROT(PetitComputer p, int layer)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange(smilebasicFunctionName, 1);
        }
        return p.getBG(layer).rot;
    }
    static void BGFILL(PetitComputer p, int layer, int x, int y, int x2, int y2, Value sd)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGFILL", 1);
        }
        if (sd.type == ValueType.String)
        {
            wstring screendata = sd.castDString;
            if (screendata.length % 4 != 0)
            {
                throw new IllegalFunctionCall("BGFILL", 6);
            }
            ushort[] screendatas = new ushort[screendata.length / 4];
            for (int i = 0; i < screendata.length; i += 4)
            {
                ushort a;
                auto b = screendata[i..i + 4];
                if (!tryParse(b, 16, a))
                {
                    throw new IllegalFunctionCall("BGFILL", 6);
                }
                screendatas[i / 4] = a;
            }
            p.getBG(layer).fill(x, y, x2, y2, screendatas);
        }
        else if (sd.isNumber)
        {
            p.getBG(layer).fill(x, y, x2, y2, sd.castInteger);
        }
        else
        {
            throw new TypeMismatch("BGFILL", 6);
        }
    }
    static void BGPAGE(PetitComputer p, int page)
    {
        if (!p.isValidGraphicPage(page))
        {
            throw new OutOfRange("BGPAGE", 1);
        }
        p.bgpage[p.displaynum] = page;
    }
    static int BGPAGE(PetitComputer p)
    {
        return p.bgpage[p.displaynum];
    }
    static void BGSHOW(PetitComputer p, int layer)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGSHOW", 1);
        }
        p.getBG(layer).show = true;
    }
    static void BGHIDE(PetitComputer p, int layer)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGHIDE", 1);
        }
        p.getBG(layer).show = false;
    }
    static int BGGET(PetitComputer p, int layer, int x, int y)
    {
        return BGGET(p, layer, x, y, 0);
    }
    static int BGGET(PetitComputer p, int layer, int x, int y, int flag)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGGET", 1);
        }
        return p.getBG(layer).get(x, y, flag);
    }
    static void BGSAVE(PetitComputer p, int layer, int x, int y, int w, int h, Value ary)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGSAVE", 1);
        }
        if (w < 1)
        {
            throw new OutOfRange("BGSAVE", 4);
        }
        if (h < 1)
        {
            throw new OutOfRange("BGSAVE", 4);
        }
        if (!ary.isNumberArray)
        {
            throw new TypeMismatch("BGSAVE", 6);
        }
        if (ary.type == ValueType.IntegerArray)
        {
            if (w * h > ary.length)
                ary.integerArray.length = w * h;
            p.getBG(layer).save(x, y, w, h, ary.integerArray.array);
        }
        if (ary.type == ValueType.DoubleArray)
        {
            if (w * h > ary.length)
                ary.doubleArray.length = w * h;
            p.getBG(layer).save(x, y, w, h, ary.doubleArray.array);
        }
        
    }
    static void BGSAVE(PetitComputer p, int layer, Value ary)
    {
        if (!ary.isNumberArray)
        {
            throw new TypeMismatch("BGSAVE", 2);
        }
        BGSAVE(p, layer, 0, 0, p.getBG(layer).width, p.getBG(layer).height, ary);
    }
    static void BGLOAD(PetitComputer p, int layer, int x, int y, int w, int h, Value ary, int bgcharoffset)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGLOAD", 1);
        }
        if (w < 1)
        {
            throw new OutOfRange("BGLOAD", 4);
        }
        if (h < 1)
        {
            throw new OutOfRange("BGLOAD", 4);
        }
        if (!ary.isNumberArray)
        {
            throw new TypeMismatch("BGLOAD", 6);
        }
        if (ary.type == ValueType.IntegerArray)
        {
            if (w * h > ary.length)
                ary.integerArray.length = w * h;
            p.getBG(layer).load(x, y, w, h, ary.integerArray.array, bgcharoffset);
        }
        if (ary.type == ValueType.DoubleArray)
        {
            if (w * h > ary.length)
                ary.doubleArray.length = w * h;
            p.getBG(layer).load(x, y, w, h, ary.doubleArray.array, bgcharoffset);
        }

    }
    static void BGLOAD(PetitComputer p, int layer, int x, int y, int w, int h, Value ary)
    {
        BGLOAD(p, layer, x, y, w, h, ary, 0);
    }
    static void BGLOAD(PetitComputer p, int layer, Value ary)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGLOAD", 1);
        }
        if (!ary.isNumberArray)
        {
            throw new TypeMismatch("BGLOAD", 2);
        }
        BGLOAD(p, layer, 0, 0, p.getBG(layer).width, p.getBG(layer).height, ary, 0);
    }
    static void BGFUNC(PetitComputer p, int layer, wstring func)
    {
        if (!p.isValidLayer(layer))
        {
            throw new OutOfRange("BGFUNC", 1);
        }
        auto callback = p.vm.createCallback(func);
        if (callback.type == CallbackType.none)
            throw new IllegalFunctionCall("BGUNC"/*, 2*/);
        p.getBG(layer).callback = callback;
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
        if(args.length > 5 || args.length < 2)
        {
            throw new IllegalFunctionCall("COPY");
        }
        if (!args[0].isArray)
        {
            throw new TypeMismatch("COPY", 1);
        }
        //COPY string, string->文字列COPY
        //COPY array, string->DATA COPY
        Value dst = args[0];
        int dstoffset = 0;
        int sourceArrayIndex = 1;
        if (!args[1].isArray)
        {
            if (!args[1].isNumber)
                throw new TypeMismatch("COPY", 2);
            dstoffset = args[1].castInteger;
            sourceArrayIndex = 2;
        }

        int srcoffset = 0;
        int len = dst.length - dstoffset;//省略時はコピー元の末尾まで
        if(args[sourceArrayIndex].isString && !args[0].isString)
        {
            if (args.length > sourceArrayIndex + 2)
            {
                throw new SyntaxError();//syntax error?why???
            }
            if (args.length == sourceArrayIndex + 2)
            {
                if (!args[sourceArrayIndex + 1].isNumber)
                    throw new TypeMismatch("COPY", sourceArrayIndex + 2);
                len = args[sourceArrayIndex + 1].castInteger;
            }

            //DATAから
            VM vm = p.vm;
            vm.restoreData(args[sourceArrayIndex].castDString);
            for(int i = 0; i < len; i++)
            {
                Value data = vm.readData();
                dst[dstoffset++] = data;
            }
            return;
        }
        if (!args[sourceArrayIndex].isArray)
        {
            throw new TypeMismatch("COPY", sourceArrayIndex + 1);
        }
        Value src = args[sourceArrayIndex];
        if (args.length > sourceArrayIndex + 3)
        {
            throw new SyntaxError();//syntax error?why???
        }
        if (args.length == sourceArrayIndex + 3)
        {
            if (!args[sourceArrayIndex + 1].isNumber)
                throw new TypeMismatch("COPY", sourceArrayIndex + 2);
            srcoffset = args[sourceArrayIndex + 1].castInteger;
            if (!args[sourceArrayIndex + 2].isNumber)
                throw new TypeMismatch("COPY", sourceArrayIndex + 3);
            len = args[sourceArrayIndex + 2].castInteger;
        }
        else if (args.length == sourceArrayIndex + 2)
        {
            if (!args[sourceArrayIndex + 1].isNumber)
                throw new TypeMismatch("COPY", sourceArrayIndex + 2);
            len = args[sourceArrayIndex + 1].castInteger;
        }
        else
        {
            len = src.length - srcoffset;
        }
        if (dst.length < len + dstoffset)
        {
            if (dst.dimCount != 1)
            {
                throw new SubscriptOutOfRange("COPY");
            }
            dst.length = len + dstoffset;
        }
        if (src.type == ValueType.StringArray && dst.type == ValueType.StringArray)
        {
            for(int i = 0; i < len; i++)
            {
                dst.stringArray.array[i + dstoffset] = src.stringArray.array[i + srcoffset].dup;
            }
        }
        else
        {
            for(int i = 0; i < len; i++)
            {
                dst[i + dstoffset] = src[i + srcoffset];
            }
        }
    }
    @BasicName("LOAD")
    static Value LOAD1(PetitComputer p, wstring name, DefaultValue!(int, false) flag)
    {
        import otya.smilebasic.project;
        flag.setDefaultValue(0);
        auto type = Projects.splitResourceName(name);
        wstring txt;
        wstring resname = type[0];
        wstring projectname = type[1];
        wstring filename = type[2];
        if (!Projects.isValidFileName(filename))
        {
            throw new IllegalFunctionCall("LOAD");
        }
        if(projectname != "" && projectname.toUpper != "SYS")
        {
            throw new IllegalFunctionCall("LOAD");
        }
        if(projectname == "")
        {
            projectname = p.project.currentProject;
        }
        if(resname == "TXT")
        {
            if(p.project.loadFile(projectname, resname, filename, txt))
            {
                return Value(txt);
            }
            //not exist
            return Value("");
        }
        throw new IllegalFunctionCall("LOAD");
    }
    //LOAD"TXT:HOGE",ARRAY Type mismatch(LOAD:2)
    //LOAD"TXT:HOGE",STR$ Type mismatch(LOAD:2)
    //LOAD"DAT:HOGE",STR$ Type mismatch(LOAD:2)
    static void LOAD(PetitComputer p, wstring name)
    {
        LOAD(p, name, Value(0));
    }
    static void LOAD(PetitComputer p, wstring name, Value data)
    {
        void LOAD2(PetitComputer p, wstring name, int flag)
        {
            import otya.smilebasic.project;
            auto type = Projects.splitResourceName(name);
            wstring txt;
            wstring resname = type[0].toUpper;
            wstring projectname = type[1];
            wstring filename = type[2];
            auto file = Projects.parseFileName(name);
            if (!Projects.isValidFileName(filename))
            {
                throw new IllegalFunctionCall("LOAD");
            }
            if(projectname != "" && projectname.toUpper != "SYS")
            {
                throw new IllegalFunctionCall("LOAD");
            }
            if(projectname == "")
            {
                projectname = p.project.currentProject;
            }
            if(resname == "" || resname.indexOf("PRG") == 0)
            {
                int lot = 0/*always 0...?*/;
                if(resname != "" && resname != "PRG")
                {
                    auto num = resname[3..$];
                    lot = num.to!int;
                }
                if(!p.project.loadFile(projectname, "TXT", filename, txt))
                {
                    //not exist
                    return;
                }
                p.program.slot[lot].load(filename, txt);
                return;
            }
            if(file.resource == Resource.graphic || file.resource == Resource.graphicFont)
            {
                auto r = file.resourceNumber;
                if (file.resource == Resource.graphicFont)
                {
                    r = -1;
                }
                else if (!file.hasResourceNumber)
                    throw new IllegalFunctionCall("LOAD");
                import otya.smilebasic.data;
                DataHeader header;
                Value data = Value(new Array!int([0, 0]));
                if (!p.project.loadDataFile(file, data.integerArray, header))
                    return;
                if (header.type == DataType.double_)
                    throw new IllegalFileFormat("LOAD");
                p.graphic.gload(r, 0, 0, data.integerArray.dim[0], data.integerArray.dim[1], data.integerArray.array, 1, 1);
                return;
            }
            throw new IllegalFunctionCall("LOAD");
        }
        if (data.isNumber)
        {
            LOAD2(p, name, data.castInteger);
            return;
        }
        LOAD(p, name, data, 0);
    }
    static void LOAD(PetitComputer p, wstring name, Value data, int flag)
    {
        auto file = Projects.parseFileName(name);
        if (file.resource != Resource.data)
        {
            throw new IllegalFunctionCall("LOAD", 2);
        }
        if (data.isNumberArray)
        {
            if (data.type == ValueType.IntegerArray)
                p.project.loadDataFile(file, data.integerArray);
            else if (data.type == ValueType.DoubleArray)
                p.project.loadDataFile(file, data.doubleArray);
            else
                throw new TypeMismatch("LOAD", 2);
        }
        else
        {
            throw new TypeMismatch("LOAD", 2);
        }
    }
    static void SAVE(PetitComputer p, wstring name)
    {
        auto file = Projects.parseFileName(name);
        if (file.resource != Resource.program && file.resource != Resource.none)
        {
            throw new IllegalFunctionCall("SAVE"/*, 1*/);
        }
        auto slot = 0/*always 0...?*/;
        if (file.hasResourceNumber)
        {
            slot = file.resourceNumber;
        }
        if (slot >= p.program.slotSize)
        {
            throw new IllegalFunctionCall("SAVE"/*, 1*/);
        }
        auto str = cast(immutable)p.program.slot[slot].text;
        p.project.saveTextFile(file, str);
    }
    static void SAVE(PetitComputer p, wstring name, Value data)
    {
        auto file = Projects.parseFileName(name);
        if (file.resource != Resource.data && file.resource != Resource.text)
        {
            throw new IllegalFunctionCall("SAVE"/*, 1*/);
        }
        if (file.resource == Resource.text && data.isString)
        {
            p.project.saveTextFile(file, data.castDString);
        }
        else if (file.resource == Resource.data && data.isNumberArray)
        {
            if (data.type == ValueType.IntegerArray)
                p.project.saveDataFile(file, data.integerArray);
            else if (data.type == ValueType.DoubleArray)
                p.project.saveDataFile(file, data.doubleArray);
            else
                throw new TypeMismatch("SAVE", 2);
        }
        else
        {
            throw new TypeMismatch("SAVE", 2);
        }
    }
    static void PROJECT(PetitComputer p, wstring name)
    {
        //DirectMode only
        if(p.isRunningDirectMode)
        {
            if(!p.project.isValidProjectName(name))
            {
                throw new IllegalFunctionCall("PROJECT");
            }
            p.project.currentProject = name;
            return;
        }
        throw new CantUseInProgram("PROJECT");
    }
    static void PROJECT(PetitComputer p, out Array!wchar name)
    {
        name = new Array!wchar(cast(wchar[])p.project.currentProject.dup);
    }
    //FILES TYPE$
    //((TXT|DAT):)?\w+/?
    static void FILES(PetitComputer p)
    {
        FILES(p, Value(cast(wchar[])p.project.currentProject));
    }
    static void FILES(PetitComputer p, Value nameOrArray)
    {
        import otya.smilebasic.project;
        if(nameOrArray.isString)
        {
            auto t = Projects.splitResourceName(nameOrArray.castDString);
            auto res = t[0];
            if(t[1].length && t[2].length)
            {
                throw new IllegalFunctionCall("FILES");
            }
            if(t[2].length && nameOrArray.castDString.indexOf("/") != -1)
            {
                //"TXT:A":OK
                //"TXT:A/":OK
                //"TXT:/A":X
                //"TXT:A/A":X
                throw new IllegalFunctionCall("FILES");
            }
            auto project = t[1].length ? t[1] : t[2];
            //project:.->hidden project
            //project:/->project list
            auto l = p.project.getFileList(project, res);
            p.console.print(res, "\t", project, "\n");
            foreach(i; l)
            {
                p.console.print(i, "\n");
            }
        }
        else if (nameOrArray.type == ValueType.StringArray)
        {
            FILES(p, p.project.currentProject, nameOrArray);
        }
        else
        {
            throw new TypeMismatch("FILES"/*, 1*/);
        }
    }
    static void FILES(PetitComputer p, wstring name, Value array)
    {
        import otya.smilebasic.project;
        if (array.type != ValueType.StringArray)
        {
            throw new TypeMismatch("FILES"/*, 1*/);
        }
        auto t = Projects.splitResourceName(name);
        auto res = t[0];
        if(t[1].length && t[2].length)
        {
            throw new IllegalFunctionCall("FILES");
        }
        if(t[2].length && name.indexOf("/") != -1)
        {
            throw new IllegalFunctionCall("FILES");
        }
        auto project = t[1].length ? t[1] : t[2];
        auto l = p.project.getFileList(project, res);
        if (l.length > array.length)
        {
            array.length = cast(int)l.length;
        }
        foreach (i, j; l)
        {
            array[cast(int)i] = Value(j);
        }
    }
    static int CHKFILE(PetitComputer p, wstring file)
    {
        return p.project.chkfile(file);
    }
    static void ACLS(PetitComputer p)
    {
        p.acls(true, true, true);
    }
    static void ACLS(PetitComputer p, int gr, int sp, int fn)
    {
        p.acls(cast(bool)gr, cast(bool)sp, cast(bool)fn);
    }
    static int CHKCALL(PetitComputer p, wstring func)
    {
        func = func.toUpper;
        return p.vm.chkcall(func);
    }
    static int CHKLABEL(PetitComputer p, wstring label, DefaultValue!(int, false) global)
    {
        label = label.toUpper;
        global.setDefaultValue(0);
        return p.vm.chklabel(label, cast(bool)global);
    }
    static int CHKVAR(PetitComputer p, wstring var)
    {
        var = var.toUpper;
        return p.vm.chkvar(var);
    }
    static wstring INKEY(PetitComputer p)
    {
        return p.inkey();
    }
    static auto getSortArgument(Value[] arg, out int start, out int count)
    {
        auto args = retro(arg);
        //引数何も指定しなくても実行前エラーは出ない
        if (args.length < 1)
            throw new IllegalFunctionCall("");
        if (args.length > 2)
        {
            if (args[0].isNumber || args[1].isNumber)
            {
                if (args[0].isNumber && args[1].isNumber)
                {
                    start = args[0].castInteger();
                    count = args[1].castInteger();
                    args = args[2..$];
                }
                else
                {
                    throw new IllegalFunctionCall("");
                }
            }
            else
            {
                start = 0;
                count = args[0].length;
            }
        }
        else
        {
            start = 0;
            count = args[0].length;
        }
        if (args.length > 8)
            throw new IllegalFunctionCall("");
        foreach (ref a; args)
        {
            if (a.isString || !a.isArray)
            {
                throw new TypeMismatch();
            }
        }
        return args;
    }
    struct wrappeeer
    {
        Value value;
        union
        {
            int[] integerArray;
            double[] doubleArray;
            Array!wchar[] stringArray;
        }
        this(ref Value v)
        {
            value = v;
            if (value.type == ValueType.IntegerArray)
            {
                integerArray = value.integerArray.array;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray = value.doubleArray.array;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray = value.stringArray.array;
            }
        }
        private void slice(int x, int y)
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray = integerArray[x..y];
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray = doubleArray[x..y];
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray = stringArray[x..y];
            }
        }
        size_t length()
        {
            if (value.type == ValueType.IntegerArray)
            {
                return integerArray.length;
            }
            if (value.type == ValueType.DoubleArray)
            {
                return doubleArray.length;
            }
            if (value.type == ValueType.StringArray)
            {
                return stringArray.length;
            }
            throw new TypeMismatch();
        }
        bool empty()
        {
            if (value.type == ValueType.IntegerArray)
            {
                return integerArray.empty;
            }
            if (value.type == ValueType.DoubleArray)
            {
                return doubleArray.empty;
            }
            if (value.type == ValueType.StringArray)
            {
                return stringArray.empty;
            }
            throw new TypeMismatch();
        }
        void popFront()
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray.popFront;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray.popFront;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray.popFront;
            }
        }
        void front(Value v)
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray.front = v.castInteger;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray.front = v.castDouble;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray.front = v.castString;
            }
        }
        void popBack()
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray.popBack;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray.popBack;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray.popBack;
            }
        }
        Value back()
        {
            if (value.type == ValueType.IntegerArray)
            {
                return Value(integerArray.back);
            }
            if (value.type == ValueType.DoubleArray)
            {
                return Value(doubleArray.back);
            }
            if (value.type == ValueType.StringArray)
            {
                return Value(stringArray.back);
            }
            throw new TypeMismatch();
        }
        void back(Value v)
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray.back = v.castInteger;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray.back = v.castDouble;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray.back = v.castString;
            }
        }
        typeof(this) save()
        {
            return this;
        }
        Value front()
        {
            if (value.type == ValueType.IntegerArray)
            {
                return Value(integerArray.front);
            }
            if (value.type == ValueType.DoubleArray)
            {
                return Value(doubleArray.front);
            }
            if (value.type == ValueType.StringArray)
            {
                return Value(stringArray.front);
            }
            throw new TypeMismatch();
        }
        void opIndexAssign(Value v, size_t index)
        {
            if (value.type == ValueType.IntegerArray)
            {
                integerArray[index] = v.castInteger;
                return;
            }
            if (value.type == ValueType.DoubleArray)
            {
                doubleArray[index] = v.castDouble;
                return;
            }
            if (value.type == ValueType.StringArray)
            {
                stringArray[index] = v.castString;
                return;
            }
            throw new TypeMismatch();
        }
        Value opIndex(size_t index)
        {
            if (value.type == ValueType.IntegerArray)
            {
                return Value(integerArray[index]);
            }
            if (value.type == ValueType.DoubleArray)
            {
                return Value(doubleArray[index]);
            }
            if (value.type == ValueType.StringArray)
            {
                return Value(stringArray[index]);
            }
            throw new TypeMismatch();
        }
        wrappeeer opSlice(size_t x, size_t y)
        {
            wrappeeer aa = wrappeeer(value);
            if (value.type == ValueType.IntegerArray)
            {
                aa.integerArray = integerArray[x..y];
            }
            if (value.type == ValueType.DoubleArray)
            {
                aa.doubleArray = doubleArray[x..y];
            }
            if (value.type == ValueType.StringArray)
            {
                aa.stringArray = stringArray[x..y];
            }
            return aa;
        }
    }
    static string sortGenerator(int count, string less)()
    {
        string buf = "switch(args.length){";
        string args = "";
        for (int i = 0; i < count; i++)
        {
            args ~= ",wrappeeer(args[" ~ (i + 1).to!string ~ "])[start..start + count]";
            buf ~= "case " ~ (i + 2).to!string ~ ":";
            buf ~= "if(args[0].type==ValueType.IntegerArray){sort!(" ~ less ~ ", SwapStrategy.stable)(zip(iarray" ~ args ~ "));}";
            buf ~= "else if(args[0].type==ValueType.DoubleArray){sort!(" ~ less ~ ", SwapStrategy.stable)(zip(darray" ~ args ~ "));}";
            buf ~= "else if(args[0].type==ValueType.StringArray){sort!(" ~ less ~ ", SwapStrategy.stable)(zip(sarray" ~ args ~ "));}";
            buf ~= "break;";
        }
        buf ~= "default:}";
        return buf;
    }
    //もう少しまともな実装できそう
    static void SORT(Value[] arg)
    {
        import std.range;
        int start, count;
        auto args = getSortArgument(arg, start, count);

        int[] iarray;
        double[] darray;
        Array!wchar[] sarray;
        if (args[0].type == ValueType.IntegerArray)
        {
            iarray = args[0].integerArray.array[start..start + count];
        }
        if (args[0].type == ValueType.DoubleArray)
        {
            darray = args[0].doubleArray.array[start..start + count];
        }
        if (args[0].type == ValueType.StringArray)
        {
            sarray = args[0].stringArray.array[start..start + count];
        }
        if (args.length > 1)
        {
            mixin(sortGenerator!(8, "\"a[0]<b[0]\""));
            /*
            if (args[0].type == ValueType.IntegerArray)
            {
                sort!("a[0] < b[0]", SwapStrategy.stable)(zip(args[0].integerArray.array, wrappeeer(args[1])));
            }
            if (args[0].type == ValueType.DoubleArray)
            {
                sort!("a[0] < b[0]", SwapStrategy.stable)(zip(args[0].doubleArray.array, wrappeeer(args[1])));
            }
            if (args[0].type == ValueType.StringArray)
            {
                sort!("a[0] < b[0]", SwapStrategy.stable)(zip(args[0].stringArray.array, wrappeeer(args[1])));
            }*/
        }
        else
        {
            if (args[0].type == ValueType.IntegerArray)
            {
                sort!("a < b", SwapStrategy.stable)(iarray);
            }
            if (args[0].type == ValueType.DoubleArray)
            {
                sort!("a < b", SwapStrategy.stable)(darray);
            }
            if (args[0].type == ValueType.StringArray)
            {
                sort!("a < b", SwapStrategy.stable)(sarray);
            }
        }
    }
    static void RSORT(Value[] arg)
    {
        import std.range;
        int start, count;
        auto args = getSortArgument(arg, start, count);

        int[] iarray;
        double[] darray;
        Array!wchar[] sarray;
        if (args[0].type == ValueType.IntegerArray)
        {
            iarray = args[0].integerArray.array[start..start + count];
        }
        if (args[0].type == ValueType.DoubleArray)
        {
            darray = args[0].doubleArray.array[start..start + count];
        }
        if (args[0].type == ValueType.StringArray)
        {
            sarray = args[0].stringArray.array[start..start + count];
        }
        if (args.length > 1)
        {
            mixin(sortGenerator!(8, "\"a[0]>b[0]\""));
        }
        else
        {
            if (args[0].type == ValueType.IntegerArray)
            {
                sort!("a > b", SwapStrategy.stable)(iarray);
            }
            if (args[0].type == ValueType.DoubleArray)
            {
                sort!("a > b", SwapStrategy.stable)(darray);
            }
            if (args[0].type == ValueType.StringArray)
            {
                sort!("a > b", SwapStrategy.stable)(sarray);
            }
        }
    }
    static double MAX(Value array)
    {
        if (array.type == ValueType.IntegerArray)
        {
            return minPos!"a > b"(array.integerArray.array)[0];
        }
        if (array.type == ValueType.DoubleArray)
        {
            return minPos!"a > b"(array.doubleArray.array)[0];
        }
        throw new TypeMismatch();
    }
    static double MAX(Value[] args)
    {
        if (args.length == 0)
        {
            throw new IllegalFunctionCall("MAX");
        }
        return minPos!"a.castDouble > b.castDouble"(args)[0].castDouble;
    }
    static double MIN(Value array)
    {
        if (array.type == ValueType.IntegerArray)
        {
            return minPos!"a < b"(array.integerArray.array)[0];
        }
        if (array.type == ValueType.DoubleArray)
        {
            return minPos!"a < b"(array.doubleArray.array)[0];
        }
        throw new TypeMismatch();
    }
    static double MIN(Value[] args)
    {
        if (args.length == 0)
        {
            throw new IllegalFunctionCall("MIN");
        }
        return minPos!"a.castDouble < b.castDouble"(args)[0].castDouble;
    }
    //MAX(2,0)*&H7FFFFFFFF!=MAX(2,0,0)*&H7FFFFFFFF
    static Value MAX(Value a1, Value a2)
    {
        if (a1.type == ValueType.Integer && a2.type == ValueType.Integer)
        {
            return Value(a1.integerValue > a2.integerValue ? a1.integerValue : a2.integerValue);
        }
        return Value(a1.castDouble > a2.castDouble ? a1.castDouble : a2.castDouble);
    }
    static Value MIN(Value a1, Value a2)
    {
        if (a1.type == ValueType.Integer && a2.type == ValueType.Integer)
        {
            return Value(a1.integerValue < a2.integerValue ? a1.integerValue : a2.integerValue);
        }
        return Value(a1.castDouble < a2.castDouble ? a1.castDouble : a2.castDouble);
    }
    static pure nothrow @nogc @safe double EXP()
    {
        return std.math.E;
    }
    static pure nothrow @nogc @safe double EXP(double d)
    {
        return std.math.exp(d);
    }
    static double LOG(double a)
    {
        if (a <= 0)
        {
            throw new OutOfRange();
        }
        return std.math.log(a);
    }
    static double LOG(double a, double b)
    {
        if (a <= 0)
        {
            throw new OutOfRange();
        }
        if (b <= 1)
        {
            throw new OutOfRange();
        }
        return std.math.log(a) / std.math.log(b);
    }
    static void PUSH(Value ary, Value exp)
    {
        if (!ary.isArray)
        {
            throw new TypeMismatch("PUSH", 1);
        }
        if (!exp.canCast(ary.elementType))
        {
            throw new TypeMismatch("PUSH");
        }
        switch (ary.type)
        {
            case ValueType.String:
                if (ary.stringValue.dimCount != 1)
                    throw new TypeMismatch("PUSH", 1);
                ary.stringValue.push(exp.castString);
                break;
            case ValueType.IntegerArray:
                if (ary.integerArray.dimCount != 1)
                    throw new TypeMismatch("PUSH", 1);
                ary.integerArray.push(exp.castInteger);
                break;
            case ValueType.DoubleArray:
                if (ary.doubleArray.dimCount != 1)
                    throw new TypeMismatch("PUSH", 1);
                ary.doubleArray.push(exp.castDouble);
                break;
            case ValueType.StringArray:
                if (ary.stringArray.dimCount != 1)
                    throw new TypeMismatch("PUSH", 1);
                ary.stringArray.push(exp.castString);
                break;
            default:
                throw new TypeMismatch();
        }
    }
    static Value POP(Value ary)
    {
        if (!ary.isArray)
        {
            throw new TypeMismatch("POP", 1);
        }
        if (ary.length == 0)
        {
            throw new SubscriptOutOfRange("POP");
        }
        switch (ary.type)
        {
            case ValueType.String:
                if (ary.stringValue.dimCount != 1)
                    throw new TypeMismatch("POP", 1);
                return Value(ary.stringValue.pop());
            case ValueType.IntegerArray:
                if (ary.integerArray.dimCount != 1)
                    throw new TypeMismatch("POP", 1);
                return Value(ary.integerArray.pop());
            case ValueType.DoubleArray:
                if (ary.doubleArray.dimCount != 1)
                    throw new TypeMismatch("POP", 1);
                return Value(ary.doubleArray.pop());
            case ValueType.StringArray:
                if (ary.stringArray.dimCount != 1)
                    throw new TypeMismatch("POP", 1);
                return Value(ary.stringArray.pop());
            default:
                throw new TypeMismatch();
        }
    }
    static void UNSHIFT(Value ary, Value exp)
    {
        if (!ary.isArray)
        {
            throw new TypeMismatch("UNSHIFT", 1);
        }
        if (!exp.canCast(ary.elementType))
        {
            throw new TypeMismatch("UNSHIFT");
        }
        if (ary.dimCount != 1)
            throw new TypeMismatch("UNSHIFT", 1);
        switch (ary.type)
        {
            case ValueType.String:
                ary.stringValue.unshift(exp.castString);
                break;
            case ValueType.IntegerArray:
                ary.integerArray.unshift(exp.castInteger);
                break;
            case ValueType.DoubleArray:
                ary.doubleArray.unshift(exp.castDouble);
                break;
            case ValueType.StringArray:
                ary.stringArray.unshift(exp.castString);
                break;
            default:
                throw new TypeMismatch();
        }
    }
    static Value SHIFT(Value ary)
    {
        if (!ary.isArray)
        {
            throw new TypeMismatch("SHIFT", 1);
        }
        if (ary.dimCount != 1)
            throw new TypeMismatch("SHIFT", 1);
        if (ary.length == 0)
        {
            throw new SubscriptOutOfRange("SHIFT");
        }
        switch (ary.type)
        {
            case ValueType.String:
                return Value(ary.stringValue.shift());
            case ValueType.IntegerArray:
                return Value(ary.integerArray.shift());
            case ValueType.DoubleArray:
                return Value(ary.doubleArray.shift());
            case ValueType.StringArray:
                return Value(ary.stringArray.shift());
            default:
                throw new TypeMismatch();
        }
    }
    static void BACKTRACE(PetitComputer p)
    {
        auto bt = p.vm.backTrace;
        foreach (t; bt)
        {
            p.console.print(t.slot, ":\t", t.line, ":\t", t.name, "\n");
            //TODO:=== Press ENTER ===
        }
    }
    static void FILL(Value array, Value value)
    {
        if (array.isString || !array.isArray)
            throw new TypeMismatch("FILL", 1);
        FILL(array, value, 0, array.length);
    }
    static void FILL(Value array, Value value, int offset)
    {
        if (array.isString || !array.isArray)
            throw new TypeMismatch("FILL", 1);
        FILL(array, value, offset, array.length - offset);
    }
    static void FILL(Value array, Value value, int offset, int len)
    {
        if (array.isString || !array.isArray)
            throw new TypeMismatch("FILL", 1);
        if (!value.canCast(array.elementType))
            throw new TypeMismatch("FILL"/*no argument number*/);
        if (offset < 0)
            throw new OutOfRange("FILL", 3);
        if (array.length < offset + len)
            throw new OutOfRange("FILL", 4);
        if (array.type == ValueType.StringArray)
        {
            for (int i = 0; i < len; i++)
            {
                array.stringArray.array[offset + i] = value.castString.dup/*copy*/;
            }
        }
        if (array.type == ValueType.IntegerArray)
        {
            array.integerArray.array[offset..offset + len] = value.castInteger;
        }
        if (array.type == ValueType.DoubleArray)
        {
            array.doubleArray.array[offset..offset + len] = value.castDouble;
        }
    }
    static void KEY(PetitComputer p, int index, wstring key)
    {
        index--;
        if (index < 0 || index >= p.functionKey.length)
            throw new OutOfRange("KEY", 1);
        p.functionKey[index] = key.dup;
    }
    static void KEY(PetitComputer p, int index, out Array!wchar key)
    {
        index--;
        if (index < 0 || index >= p.functionKey.length)
            throw new OutOfRange("KEY", 1);
        key = new Array!wchar(cast(wchar[])p.functionKey[index]);
    }
    import otya.smilebasic.dialog;
    import otya.smilebasic.project;
    static void DIALOG(PetitComputer p, wstring text, out int result)
    {
        auto dialog = new Dialog(p);
        result = p.project.result = cast(DialogResult)dialog.show(text);
    }
    static void DIALOG(PetitComputer p, wstring text, DefaultValue!int selType, out int result)
    {
        selType.setDefaultValue(0);
        auto dialog = new Dialog(p);
        result = p.project.result = cast(DialogResult)dialog.show(text, cast(SelectionType)selType);
    }
    static void DIALOG(PetitComputer p, wstring text, DefaultValue!int selType, DefaultValue!wstring cap, out int result)
    {
        selType.setDefaultValue(0);
        cap.setDefaultValue("■DIALOG");
        auto dialog = new Dialog(p);
        result = p.project.result = cast(DialogResult)dialog.show(text, cast(SelectionType)selType, cast(wstring)cap);
    }
    static void DIALOG(PetitComputer p, wstring text, DefaultValue!int selType, DefaultValue!wstring cap, DefaultValue!int timeout, out int result)
    {
        selType.setDefaultValue(0);
        cap.setDefaultValue("■DIALOG");
        timeout.setDefaultValue(0);
        auto dialog = new Dialog(p);
        result = p.project.result = cast(DialogResult)dialog.show(text, cast(SelectionType)selType, cast(wstring)cap, cast(int)timeout);
    }
    static void DIALOG(PetitComputer p, wstring text)
    {
        auto dialog = new Dialog(p);
        p.project.result = cast(DialogResult)dialog.show(text);
    }
    static void DIALOG(PetitComputer p, wstring text, DefaultValue!int selType)
    {
        selType.setDefaultValue(0);
        auto dialog = new Dialog(p);
        p.project.result = cast(DialogResult)dialog.show(text, cast(SelectionType)selType);
    }
    static void DIALOG(PetitComputer p, wstring text, DefaultValue!int selType, DefaultValue!wstring cap)
    {
        selType.setDefaultValue(0);
        cap.setDefaultValue("■DIALOG");
        auto dialog = new Dialog(p);
        p.project.result = cast(DialogResult)dialog.show(text, cast(SelectionType)selType, cast(wstring)cap);
    }
    static void DIALOG(PetitComputer p, wstring text, DefaultValue!int selType, DefaultValue!wstring cap, DefaultValue!int timeout)
    {
        selType.setDefaultValue(0);
        cap.setDefaultValue("■DIALOG");
        timeout.setDefaultValue(0);
        auto dialog = new Dialog(p);
        p.project.result = cast(DialogResult)dialog.show(text, cast(SelectionType)selType, cast(wstring)cap, cast(int)timeout);
    }
    static void PRGEDIT(PetitComputer p, int slot)
    {
        PRGEDIT(p, slot, 1);
    }
    static void PRGEDIT(PetitComputer p, int slot, int line)
    {
        if (slot < 0 || p.program.slotSize <= slot)
            throw new OutOfRange("PRGEDIT", 1);
        if (line < -1 || line == 0)
            throw new OutOfRange("PRGEDIT"/*, 2*/);
        p.program.edit(slot, line);
    }
    static wstring PRGGET(PetitComputer p)
    {
        return p.program.get();
    }
    static void PRGSET(PetitComputer p, wstring x)
    {
        p.program.set(x.dup);
    }
    static void PRGINS(PetitComputer p, wstring line)
    {
        p.program.insert(line, false);
    }
    static void PRGINS(PetitComputer p, wstring line, int isBack)
    {
        p.program.insert(line, cast(bool)isBack);
    }
    static void PRGDEL(PetitComputer p)
    {
        PRGDEL(p, 1);
    }
    static void PRGDEL(PetitComputer p, int count)
    {
        if (count == 0)
        {
            throw new OutOfRange("PRGDEL", 1);
        }
        p.program.delete_(count);
    }
    static int PRGSIZE(PetitComputer p)
    {
        return PRGSIZE(p, p.vm.currentSlotNumber, 0);
    }
    static int PRGSIZE(PetitComputer p, int slot)
    {
        return PRGSIZE(p, slot, 0);
    }
    static int PRGSIZE(PetitComputer p, int slot, int type)
    {
        import otya.smilebasic.program;
        return p.program.size(slot, cast(SizeType)type);
    }
    static wstring PRGNAME(PetitComputer p)
    {
        return p.program.name(p.vm.currentSlotNumber);
    }
    static wstring PRGNAME(PetitComputer p, int slot)
    {
        return p.program.name(slot);
    }
    static auto split2(R)(R range, size_t size)
    {
        return Split2!R(range, size);
    }
    unittest
    {
        struct IR
        {
            void popFront()
            {
            }
            bool empty()
            {
                return true;
            }
            int front()
            {
                return 1;
            }
        }
        static assert(isInputRange!(Split2!IR));
        static assert(isInputRange!(Split2!(int[])));
    }
    struct Split2(R)
    if (isInputRange!R)
    {
        R range;
        size_t size;
        ElementType!(R)[] item;
        bool isEmpty;
        this(R range, size_t size)
        {
            this.range = range;
            this.size = size;
            popFront();
        }
        void popFront()
        {
            isEmpty = range.empty;
            if (isEmpty)
                return;
            static if (hasSlicing!R && is(range[0..size] == item))
            {
                item = range[0..size];
                popFrontN(item, size);
            }
            else
            {
                item = new ElementType!(R)[size];
                for (size_t i = 0; i < size; i++)
                {
                    item[i] = range.front();
                    range.popFront();
                }
            }
        }
        auto front()
        {
            return item;
        }
        bool empty()
        {
            return isEmpty;
        }
    }
    static void FONTDEF(PetitComputer p, int icode, Value array)
    {
        if (icode < 0 || icode > 0xFFFF)
        {
            throw new OutOfRange("FONTDEF", 1);
        }
        ushort code = cast(ushort)icode;
        if (!p.console.canDefine(code))
        {
            throw new IllegalFunctionCall("FONTDEF"/*, 1*/);
        }
        int color = 4;
        if (array.isString)
        {
            wstring definition = array.castDString;
            //FONTDEF 0,"0000"*65'=>OK
            if (definition.length < p.console.fontDefWidth * p.console.fontDefHeight * color)
            {
                throw new IllegalFunctionCall("FONTDEF", 2);
            }
            int[] font = new int[p.console.fontDefWidth * p.console.fontDefHeight * color];
            try
            {
                p.console.define(code, split2(definition, 4).map!(x => x.to!int(16)).array);
            }
            catch (ConvException)
            {
                throw new IllegalFunctionCall("FONTDEF", 2);
            }
            return;
        }
        //DIM A$[63]
        //FONTDEF 0,A$'=>Subscript out of range(FONTDEF:2)
        //DIM A$[64]
        //FONTDEF 0,A$'=>Type mismatch(FONTDEF:2)
        //FONTDEF 0,1'=>Type mismatch(FONTDEF:2)

        if (!array.isArray)
            throw new TypeMismatch("FONTDEF", 2);
        if (array.length < p.console.fontDefWidth * p.console.fontDefHeight)
            throw new SubscriptOutOfRange("FONTDEF", 2);
        if (!array.isNumberArray)
            throw new TypeMismatch("FONTDEF", 2);
        if (array.type == ValueType.IntegerArray)
        {
            p.console.define(code, array.integerArray.array);
        }
        else if (array.type == ValueType.DoubleArray)
        {
            p.console.define(code, array.doubleArray.array);
        }
    }
    static void FONTDEF(PetitComputer p)
    {
        p.console.initGRPF();
    }
    static void SCROLL(PetitComputer p, int x, int y)
    {
        p.console.scroll(x, y);
    }
    static void CLIPBOARD(PetitComputer p, wstring value)
    {
        p.clipboard = value;
    }
    static wstring CLIPBOARD(PetitComputer p)
    {
        return p.clipboard;
    }
    static void FADE(PetitComputer p, int color)
    {
        p.fade.fade(color);
    }
    static void FADE(PetitComputer p, int color, int time)
    {
        p.fade.fade(color, time);
    }
    static int FADE(PetitComputer p)
    {
        return p.fade.fade();
    }

    //alias void function(PetitComputer, Value[], Value[]) BuiltinFunc;
    static BuiltinFunctions[wstring] builtinFunctions;
    static wstring getBasicName(BFD)(const wstring def)
    {
        enum attr = __traits(getAttributes, __traits(getOverloads, BFD.C_, BFD.N)[BFD.I_]);
        wstring r = def;
        foreach(i; attr)
        {
            if(__traits(compiles, i.naame))
            {
                r = (cast(BasicName)i).naame;
            }
        }
        return r;
    }

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
                    alias BFD = BuiltinFunctionData!(BuiltinFunction, name, i);
                    wstring name2 = getBasicName!BFD(name ~ suffix);
                    auto func = builtinFunctions.get(name2, null);
                    //pragma(msg, AddFunc!BFD);
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
            auto result = 0;
            int k;
            foreach (j, i; ParameterIdentifierTuple!(__traits(getOverloads, BFD.C_, BFD.N)[BFD.I_]))
            {
                if(i == so.name)
                {
                    result = k;
                    break;
                }
                else if(BFD.ParameterStorageClass[j] & ParameterStorageClass.out_)
                {
                    k++;
                }
            }
            return result;
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
        else static if(is(P[I] == Value[]))
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
    else static if(is(P[0] == Array!wchar))
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
    else static if(is(BFD.ReturnType == Value))
    {
        const string AddFunc = "function void(PetitComputer p, Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall(\"" ~ BFD.N ~ "\");}ret[0] = " ~ BFD.N ~ "(" ~
            AddFuncArg!(/*ParameterTypeTuple!(__traits(getMember, T, N)).length*/GetArgumentCount!(BFD) - 1, 0, 0, 0, BFD,
                        BFD.ParameterType) ~ ");}";
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
        return DefaultValue!wstring(v.castDString());
    else
        return DefaultValue!wstring(true);
}
DefaultValue!(wstring, false) fromStringToSkip(Value v)
{
    if(v.type == ValueType.String)
        return DefaultValue!(wstring, false)(v.castDString());
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
                enum Array = arg.empty ? "" : "BuiltinFunctionArgument(" ~ arg ~ ")";
            }
            else static if(!is(P[0] == PetitComputer))
            {
                enum Array = (arg.empty ? "" : "BuiltinFunctionArgument(" ~ arg ~ ")," )~ Array!(I + 1, P[1..$]);
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
            static if(storage & ParameterStorageClass.out_)
            {
                static assert(false, "Invalid argument out wstring");
            }
            else
            {
                enum add = 1;
                enum outadd = 0;
                const string arg = "arg[" ~ I.to!string ~ "].castDString";
            }
        }
        else static if(is(P[0] == Array!wchar))
        {
            static if(storage & ParameterStorageClass.out_)
            {
                enum add = 0;
                enum outadd = 1;
                const string arg = "ret[" ~ O.to!string ~ "].stringValue";
            }
            else
            {
                enum add = 1;
                enum outadd = 0;
                const string arg = "arg[" ~ I.to!string ~ "].castString";
            }
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
            else static if(is(param[I] == wstring))
            {
                enum ret2 = "ValueType.String;";
            }
            else static if(is(param[I] == Array!wchar))
            {
                enum ret2 = "ValueType.String;";
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

