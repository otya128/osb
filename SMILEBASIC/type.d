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
    StringArrayReference,
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
        Array!wchar stringValue;
        Array!int integerArray;
        Array!double doubleArray;
        Array!(Array!wchar) stringArray;
        VMAddress internalAddress;
        Value* reference;
        ArrayReference!int integerReference;
        ArrayReference!double doubleReference;
        ArrayReference!wchar stringReference;
        ArrayReference!(Array!wchar) stringArrayReference;
    }
    this(int value)
    {
        this.type = ValueType.Integer;
        integerValue = value;
    }
    this(bool value)
    {
        this(cast(int)value);
    }
    this(double value)
    {
        this.type = ValueType.Double;
        doubleValue = value;
    }
    this(wstring value)
    {
        this.type = ValueType.String;
        stringValue = new Array!wchar(cast(wchar[])value.dup);
    }
    this(wchar[] value)
    {
        this.type = ValueType.String;
        stringValue = new Array!wchar(value);
    }
    this(wchar value)
    {
        this.type = ValueType.String;
        stringValue = new Array!wchar([value]);
    }
    this(Array!wchar value)
    {
        this.type = ValueType.String;
        stringValue = value;
    }
    this(ValueType type)
    {
        this.type = type;
        if(type == ValueType.String)
        {
            stringValue = new Array!wchar(0);
        }
    }
    this(Value* r)
    {
        this.type = ValueType.Reference;
        reference = r;
    }
    this(ArrayReference!int r)
    {
        this.type = ValueType.IntegerReference;
        integerReference = r;
    }
    this(ArrayReference!double r)
    {
        this.type = ValueType.DoubleReference;
        doubleReference = r;
    }
    this(ArrayReference!wchar r)
    {
        this.type = ValueType.StringReference;
        stringReference = r;
    }
    this(ArrayReference!(Array!wchar) r)
    {
        this.type = ValueType.StringArrayReference;
        stringArrayReference = r;
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
    Array!wchar castString()
    {
        if (this.type == ValueType.String)
            return this.stringValue;
        throw new TypeMismatch();
    }
    wstring castDString()
    {
        if (this.type == ValueType.String)
            return cast(immutable)this.stringValue.array;
        throw new TypeMismatch();
    }
    string toString()
    {
        import std.conv, std.format;
        switch(this.type)
        {
            case ValueType.Void:
                return "void";
            case ValueType.Integer:
                return this.integerValue.to!string;
            case ValueType.String:
                return this.stringValue.array.to!string;
            case ValueType.IntegerArray:
                return format("integerarray[%s]", length);
            case ValueType.DoubleArray:
                return format("doublearray[%s]", length);
            case ValueType.StringArray:
                return format("doublearray[%s]", length);
            case ValueType.InternalAddress:
                return format("internal address slot=%d, address=0x%x", internalAddress.slot, internalAddress.address);
            default:
                return type.to!string;
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
    @property void length(int len)
    {
        switch(this.type)
        {
            case ValueType.String:
                stringValue.length = len;
                return;
            case ValueType.IntegerArray:
                integerArray.length = len;
                return;
            case ValueType.DoubleArray:
                doubleArray.length = len;
                return;
            case ValueType.StringArray:
                stringArray.length = len;
                return;
            default:
                throw new TypeMismatch();
        }
    }
    @property int dimCount()
    {
        switch(this.type)
        {
            case ValueType.String:
                return stringValue.dimCount;
            case ValueType.IntegerArray:
                return integerArray.dimCount;
            case ValueType.DoubleArray:
                return doubleArray.dimCount;
            case ValueType.StringArray:
                return stringArray.dimCount;
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
                stringValue[i] = v.castString;
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
    ValueType elementType()
    {
        switch(this.type)
        {
            case ValueType.String:
                return ValueType.String;
            case ValueType.IntegerArray:
                return ValueType.Integer;
            case ValueType.DoubleArray:
                return ValueType.Double;
            case ValueType.StringArray:
                return ValueType.String;
            default:
                throw new TypeMismatch();
        }
    }
    bool canCast(ValueType t)
    {
        return t == this.type || ((t == ValueType.Integer || t == ValueType.Double) && isNumber);
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
    static if (!is(T == int))
    {
        this(T[] array)
        {
            dim[0] = cast(int)array.length;
            dim[1] = 0;
            dim[2] = 0;
            dim[3] = 0;
            this.array = array;
            dimCount = 1;
        }
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
        if(i1 >= dim[1] || i2 >= dim[0]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] + i2];
    }
    ref T opIndex(int i1, int i2, int i3)
    {
        if(dimCount != 3) throw new SyntaxError();
        if(i1 >= dim[2] || i2 >= dim[1] || i3 >= dim[0]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] * dim[1] + i2 * dim[0] + i3];
    }
    ref T opIndex(int i1, int i2, int i3, int i4)
    {
        if(dimCount != 4) throw new SyntaxError();
        if(i1 >= dim[3] || i2 >= dim[2] || i3 >= dim[1] || i4 >= dim[0]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] * dim[1] * dim[2] + i2 * dim[0] * dim[1] + i3 * dim[0] + i4];
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
        if(i1 >= dim[1] || i2 >= dim[0]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] + i2] = v;
    }
    T opIndexAssign(T v, int i1, int i2, int i3)
    {
        if(dimCount != 3) throw new SyntaxError();
        if(i1 >= dim[2] || i2 >= dim[1] || i3 >= dim[0]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] * dim[1] + i2 * dim[0] + i3] = v;
    }
    T opIndexAssign(T v, int i1, int i2, int i3, int i4)
    {
        if(dimCount != 4) throw new SyntaxError();
        if(i1 >= dim[3] || i2 >= dim[2] || i3 >= dim[1] || i4 >= dim[0]) throw new SubscriptOutOfRange();
        return array[i1 * dim[0] * dim[1] * dim[2] + i2 * dim[0] * dim[1] + i3 * dim[0] + i4] = v;
    }
    void push(T v)
    {
        if (dimCount != 1)
        {
            throw new TypeMismatch();
        }
        array ~= v;
        dim[0]++;
    }
    void push(Array!T v)
    {
        if (dimCount != 1)
        {
            throw new TypeMismatch();
        }
        array ~= v.array;
        dim[0] = cast(int)length;
    }
    T pop()
    {
        if (dimCount != 1)
        {
            throw new TypeMismatch();
        }
        auto last = array[$ - 1];
        array.length--;
        dim[0]--;
        return last;
    }
    void unshift(T v)
    {
        if (dimCount != 1)
        {
            throw new TypeMismatch();
        }
        array = v ~ array;
        dim[0]++;
    }
    void unshift(Array!T v)
    {
        if (dimCount != 1)
        {
            throw new TypeMismatch();
        }
        array = v.array ~ array;
        dim[0] = cast(int)length;
    }
    T shift()
    {
        if (dimCount != 1)
        {
            throw new TypeMismatch();
        }
        auto l = array[0];
        array = array[1..$];
        dim[0]--;
        return l;
    }
    @property void length(int size)
    {
        if (dimCount != 1)
        {
            throw new TypeMismatch();
        }
        array.length = size;
        static if (is(T == double))
        {
            array[array.length - size..$] = 0;
        }
        dim[0] = size;
    }
    void append(Array!T input)
    {
        if (dimCount != 1 || input.dimCount != 1)
        {
            throw new TypeMismatch();
        }
        array ~= input.array;
        dim[0] = cast(int)array.length;
    }
    void opIndexAssign(Array!T v, int i1)
    {
        if(dimCount != 1 || v.dimCount != 1 ) throw new SyntaxError();
        if(i1 >= dim[0]) throw new SubscriptOutOfRange();
        array = array[0..i1] ~ v.array ~ array[i1 + 1..$];
        dim[0] = cast(int)array.length;
    }
    Array!T opOpAssign(string op = "~")(Array!T v)
    {
        if(dimCount != 1 || v.dimCount != 1 ) throw new SyntaxError();
        array ~= v.array;
        dim[0] = cast(int)array.length;
        return this;
    }
    int calcIndex(int[] index)
    {
        if(dimCount != index.length) throw new SyntaxError();
        import core.exception;
        switch(index.length)
        {
            case 1:
                return index[0];
            case 2:
                return index[0] * dim[0] + index[1];
            case 3:
                return index[0] * dim[0] * dim[1] + index[1] * dim[0] + index[2];
            case 4:
                return index[0] * dim[0] * dim[1] * dim[2] + index[1] * dim[0] * dim[1] + index[2] * dim[0] + index[3];
            default:
                throw new RangeError();
        }
    }
    ArrayReference!T reference(int[] index)
    {
        auto i = calcIndex(index);
        return ArrayReference!T(this, i);
    }
    void insert(Array!T ary, int index)
    {
        if(dimCount != 1 || ary.dimCount != 1 ) throw new SyntaxError();
        if(index >= dim[0]) throw new SubscriptOutOfRange();
        array = array[0..index] ~ ary.array ~ array[index + 1..$];
        dim[0] = cast(int)array.length;
    }
    protected this(Array!T a)
    {
        this.dim = a.dim;
        this.dimCount = a.dimCount;
        this.array = a.array.dup;
    }
    Array!T dup()
    {
        return new Array!T(this);
    }

}
struct ArrayReference(T)
{
    Array!T reference;
    int index;
    T opAssign(T v)
    {
        return reference.array[index] = v;
    }
    static if (is(T == wchar))
    {
        void opAssign(Array!T ary)
        {
            reference.insert(ary, index);
        }
    }
    T opOpAssign(string op)(T v)
    {
        mixin("return reference.array[index]" ~ op ~ "=v;");
    }
    T opBinary(string op)(T v)
    {
        mixin("return reference.array[index]" ~ op ~ "v;");
    }
    T2 opCast(T2)()
    {
        return cast(T2)reference.array[index];
    }
    void swap(T2)(ArrayReference!T2 t2)
    {
        T temp = reference.array[index];
        reference.array[index] = cast(T)t2;
        t2 = cast(T2)temp;
    }
    void swap(T2)(ref T2 t2)
    if (!is(T2 T3 == ArrayReference!T3))
    {
        T temp = reference[index];
        reference[index] = t2;
        t2 = temp;
    }
}
