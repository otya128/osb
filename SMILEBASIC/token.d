module otya.smilebasic.token;
import otya.smilebasic.type;
import std.exception;
enum TokenType
{
    Unknown,
    Integer,
    Double,
    String,
    Plus,
    Minus,
    Mul,
    Div,
    Mod,
    Or,
    And,
    Xor,
    Not,
    Print,
    If,
    LParen,
    RParen,
    Iden,
    Comma,
    Colon,
    Semicolon,
    NewLine,
    Assign,
    Label,
    Goto,
    Then,
    Else,
    Endif,
    For,
    Next,
    Equal,
    NotEqual,
    Less,//<
    Greater,//>
    LessEqual,
    GreaterEqual,
    LeftShift,//<<
    RightShift,//>>
    LogicalNot,//!
    LogicalAnd,//&&
    LogicalOr,//||
    IntDiv,//DIV
    Gosub,
    Return,
    End,
    Break,
    Continue,
    Var,
    LBracket,//[
    RBracket,//]
    Def,
    Out,
    While,
    WEnd,
    Inc,
    Dec,
    Data,
    Read,
    Restore,
    On,
    Input,
    True,
    False,
    Use,
    Exec,
    Call,
    Common,
    Elseif,
    Repeat,
    Until,
    Swap,
    Dim,
    Constant,
}

enum TokenValueType
{
    integer,
    double_,
    string_
}
struct TokenValue
{
    TokenValueType type;
    private union
    {
        int integer;
        wstring string_;
        double double_;
    }
    ref integerValue()
    {
        enforce(type == TokenValueType.integer);
        return integer;
    }
    int integerValue(int val)
    {
        enforce(type == TokenValueType.integer);
        return integer = val;
    }
    ref stringValue()
    {
        enforce(type == TokenValueType.string_);
        return string_;
    }
    wstring stringValue(wstring val)
    {
        enforce(type == TokenValueType.string_);
        return string_ = val;
    }
    ref doubleValue()
    {
        enforce(type == TokenValueType.double_);
        return double_;
    }
    double doubleValue(double val)
    {
        enforce(type == TokenValueType.double_);
        return double_ = val;
    }
    int castInteger()
    {
        switch (type)
        {
            case TokenValueType.integer:
                return integer;
            case TokenValueType.double_:
                return cast(int)double_;
            default:
                assert(false);
        }
    }
    double castDouble()
    {
        switch (type)
        {
            case TokenValueType.integer:
                return integer;
            case TokenValueType.double_:
                return double_;
            default:
                assert(false);
        }
    }
    wstring castString()
    {
        switch (type)
        {
            case TokenValueType.string_:
                return string_;
            default:
                assert(false);
        }
    }
    bool isNumber()
    {
        switch (type)
        {
            case TokenValueType.integer:
            case TokenValueType.double_:
                return true;
            default:
                return false;
        }
    }
    bool isString()
    {
        switch (type)
        {
            case TokenValueType.string_:
                return true;
            default:
                return false;
        }
    }
    this(int v)
    {
        type = TokenValueType.integer;
        integer = v;
    }
    this(wstring v)
    {
        type = TokenValueType.string_;
        string_ = v;
    }
    this(double v)
    {
        type = TokenValueType.double_;
        double_ = v;
    }
    Value toSBImm()
    {
        switch (type)
        {
            case TokenValueType.integer:
                return Value(integer);
            case TokenValueType.string_:
                return Value(string_);
            case TokenValueType.double_:
                return Value(double_);
            default:
                assert(false);
        }
    }
}

struct Token
{
    TokenType type;
    TokenValue value;
    this(TokenType t, TokenValue v)
    {
        type = t;
        value = v;
    }
    this(TokenType t)
    {
        type = t;
    }
}
struct SourceLocation
{
    int line;//何行目
    int pos;//何文字目
    int pos2;//全体から何文字目
}
