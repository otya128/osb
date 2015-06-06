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
