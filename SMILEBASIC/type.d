module otya.smilebasic.type;
enum ValueType : byte
{
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
        int[] intArray;
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
