module otya.smilebasic.token;
import otya.smilebasic.type;
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
}

struct Token
{
    TokenType type;
    Value value;
    this(TokenType t, Value v)
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
