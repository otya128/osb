module otya.smilebasic.type;
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
}
struct Value
{
    ValueType type;
    union
    {
        int integerValue;
        double doubleValue;
        wstring stringValue;
        Array!int integerArray;
        Array!double doubleArray;
        Array!wstring stringArray;
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
}
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
        dimCount = 1;
    }
    this(int[] dim)
    {
        int len = 1;
        foreach(int i; dim)
        {
            len *= i;
        }
        array = new T[len];
        dimCount = dim.length;
    }
    T opIndex(int i1)
    {
        return array[i1];
    }
    T opIndex(int i1, int i2)
    {
        return array[i1 * dim[0] + i2];
    }
    T opIndex(int i1, int i2, int i3)
    {
        return array[i1 * dim[0] * dim[1] + i2 * dim[1] + i3];
    }
    T opIndex(int i1, int i2, int i3, int i4)
    {
        return array[i1];//array[i1 * dim[0] * dim[1] * dim[2] + i2 * dim[1] + i3];
    }

}
