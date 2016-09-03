module otya.smilebasic.type;
import otya.smilebasic.error;
enum ValueType : byte
{
    Void,//DEF A()ENDの返り値とか未初期化の変数とか
    Integer,
    Double,
    String,
    Array,
    IntegerArray,
    DoubleArray,
    StringArray,
    InternalAddress,
    InternalSlotAddress,
    Reference,
    IntegerReference,
    DoubleReference,
    StringReference,
}
struct VMAddress
{
    byte slot;
    uint address;
}
struct Value
{
    ValueType type;
    union
    {
        int integerValue;
        double doubleValue;
        //TODO:Array!wchar stringValue;にしたい
        wstring stringValue;
        Array!int integerArray;
        Array!double doubleArray;
        Array!wstring stringArray;
        VMAddress internalAddress;
        Value* reference;
        int* integerReference;
        double* doubleReference;
        wstring* stringReference;
    }
    this(int value)
    {
        this.type = ValueType.Integer;
        integerValue = value;
    }
    this(double value)
    {
        this.type = ValueType.Double;
        doubleValue = value;
    }
    this(wstring value)
    {
        this.type = ValueType.String;
        stringValue = value;
    }
    this(ValueType type)
    {
        this.type = type;
        if(type == ValueType.String)
        {
            stringValue = "";
        }
    }
    this(Value* r)
    {
        this.type = ValueType.Reference;
        reference = r;
    }
    this(int* r)
    {
        this.type = ValueType.IntegerReference;
        integerReference = r;
    }
    this(double* r)
    {
        this.type = ValueType.DoubleReference;
        doubleReference = r;
    }
    this(wstring* r)
    {
        this.type = ValueType.StringReference;
        stringReference = r;
    }
    void castOp(ValueType type)
    {
        switch(type)
        {
            case ValueType.Double:
                
                break;
            default:
                break;
        }
    }
    bool boolValue()
    {
        switch(type)
        {
            case ValueType.Double:
                return this.doubleValue != 0;
            case ValueType.Integer:
                return this.integerValue != 0;
            case ValueType.String:
                return true;//3.1現在では文字列はtrue(ただし!"A"などは動かない)
            default:
                //配列はtype mismatch
                return false;
        }
    }
    bool isArray()
    {
        return this.type == ValueType.IntegerArray || this.type == ValueType.DoubleArray ||
            this.type == ValueType.StringArray || this.type == ValueType.String;
    }
    bool isNumberArray()
    {
        return this.type == ValueType.IntegerArray || this.type == ValueType.DoubleArray;
    }
    bool isNumber()
    {
        return this.type == ValueType.Integer || this.type == ValueType.Double;
    }
    bool isInteger()
    {
        return this.type == ValueType.Integer;
    }
    bool isDouble()
    {
        return this.type == ValueType.Double;
    }
    bool isString()
    {
        return this.type == ValueType.String;
    }
    int castInteger()
    {
        if (this.type == ValueType.Integer)
        {
            return this.integerValue;
        }
        if (this.type == ValueType.Double)
        {
            return cast(int)this.doubleValue;
        }
        throw new TypeMismatch();
    }
    double castDouble()
    {
        if (this.type == ValueType.Integer)
        {
            return this.integerValue;
        }
        if (this.type == ValueType.Double)
        {
            return this.doubleValue;
        }
        throw new TypeMismatch();
    }
    wstring castString()
    {
        if (this.type == ValueType.String)
            return this.stringValue;
        throw new TypeMismatch();
    }
    string toString()
    {
        import std.conv;
        switch(this.type)
        {
            case ValueType.Void:
                return "void";
            case ValueType.Integer:
                return this.integerValue.to!string;
            case ValueType.String:
                return this.stringValue.to!string;
            default:
                return "default";
        }
    }
    @property int length()
    {
        switch(this.type)
        {
            case ValueType.String:
                return cast(int)stringValue.length;
            case ValueType.IntegerArray:
                return cast(int)integerArray.length;
            case ValueType.DoubleArray:
                return cast(int)doubleArray.length;
            case ValueType.StringArray:
                return cast(int)stringArray.length;
            default:
                throw new TypeMismatch();
        }
    }
    void opIndexAssign(Value v, int i)
    {
        switch(this.type)
        {
            //とりあえず破壊的に書き換えた
            //どのみちこれだと文字数を増やすことができないのでArray!wcharで管理させたい
            case ValueType.String:
                (cast(wchar[])stringValue)[i] = v.castString[0];
                break;
            case ValueType.IntegerArray:
                integerArray.array[i] = v.castInteger;
                break;
            case ValueType.DoubleArray:
                doubleArray.array[i] = v.castDouble;
                break;
            case ValueType.StringArray:
                stringArray.array[i] = v.castString;
                break;
            default:
                throw new TypeMismatch();
        }
    }
    Value opIndex(int i)
    {
        switch(this.type)
        {
            //とりあえず破壊的に書き換えた
            //どのみちこれだと文字数を増やすことができないのでArray!wcharで管理させたい
            case ValueType.String:
                return Value(stringValue[i]);
            case ValueType.IntegerArray:
                return Value(integerArray.array[i]);
            case ValueType.DoubleArray:
                return Value(doubleArray.array[i]);
            case ValueType.StringArray:
                return Value(stringArray.array[i]);
            default:
                throw new TypeMismatch();
        }
    }
}
//import std.experimental.ndslice;
//ndsliceがこれに相当?
class Array(T)
{
    T[] array;
    //最大要素数2^^31
    //4次元配列
    int[4] dim;
    int dimCount;
    this(int len)
    {
        dim[0] = len;
        dim[1] = 0;
        dim[2] = 0;
        dim[3] = 0;
        array = new T[len];
        static if(is(T == double))
        {
            array[] = 0;
        }
        dimCount = 1;
    }
    @property size_t length()
    {
        return array.length;
    }
    this(int[] dim)
    {
        int len = 1;
        foreach(int i, j; dim)
        {
            len *= j;
            this.dim[i] = dim[i];
        }
        array = new T[len];
        static if(is(T == double))
        {
            array[] = 0;
        }
        dimCount = cast(int)dim.length;
    }
    T opIndexAssign(T v, int[] dim)
    {
        import core.exception;
        switch(dim.length)
        {
            case 1:
                 return this[dim[0]] = v;
            case 2:
                return this[dim[0], dim[1]] = v;
            case 3:
                return this[dim[0], dim[1], dim[2]] = v;
            case 4:
                return this[dim[0], dim[1], dim[2], dim[3]] = v;
            default:
                throw new RangeError();
        }
    }
    ref T opIndex(int[] dim)
    {
        import core.exception;
        switch(dim.length)
        {
            case 1:
                return this[dim[0]];
            case 2:
                return this[dim[0], dim[1]];
            case 3:
                return this[dim[0], dim[1], dim[2]];
            case 4:
                return this[dim[0], dim[1], dim[2], dim[3]];
            default:
                throw new RangeError();
        }
    }
    ref T opIndex(int i1)
    {
        if(dimCount != 1) throw new SyntaxError();
        if(i1 >= dim[0]) throw new SubscriptOutOfRange();
        return array[i1];
    }
    ref T opIndex(int i1, int i2)
    {
        if(dimCount != 2) throw new SyntaxError();
        if(i1 >= dim[0] && i2 >= dim[1]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] + i2];
    }
    ref T opIndex(int i1, int i2, int i3)
    {
        if(dimCount != 3) throw new SyntaxError();
        if(i1 >= dim[0] && i2 >= dim[1] && i3 >= dim[2]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] * dim[1] + i2 * dim[1] + i3];
    }
    ref T opIndex(int i1, int i2, int i3, int i4)
    {
        if(dimCount != 4) throw new SyntaxError();
        if(i1 >= dim[0] && i2 >= dim[1] && i3 >= dim[2] && i4 >= dim[3]) throw new SubscriptOutOfRange();
        return array[i1];//array[i1 * dim[0] * dim[1] * dim[2] + i2 * dim[1] + i3];
    }
    T opIndexAssign(T v, int i1)
    {
        if(dimCount != 1) throw new SyntaxError();
        if(i1 >= dim[0]) throw new SubscriptOutOfRange();
        return array[i1] = v;
    }
    T opIndexAssign(T v, int i1, int i2)
    {
        if(dimCount != 2) throw new SyntaxError();
        if(i1 >= dim[0] && i2 >= dim[1]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] + i2] = v;
    }
    T opIndexAssign(T v, int i1, int i2, int i3)
    {
        if(dimCount != 3) throw new SyntaxError();
        if(i1 >= dim[0] && i2 >= dim[1] && i3 >= dim[2]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] * dim[1] + i2 * dim[1] + i3] = v;
    }
    T opIndexAssign(T v, int i1, int i2, int i3, int i4)
    {
        if(dimCount != 4) throw new SyntaxError();
        if(i1 >= dim[0] && i2 >= dim[1] && i3 >= dim[2] && i4 >= dim[3]) throw new SubscriptOutOfRange();
        return array[i1] = v;//array[i1 * dim[0] * dim[1] * dim[2] + i2 * dim[1] + i3] = v;
    }

}
