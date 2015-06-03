module otya.smilebasic.parser;
import otya.smilebasic.token;
import otya.smilebasic.type;
import otya.smilebasic.node;
import std.ascii;
class Lexical
{
    wstring code;
    int index;
    this(wstring input)
    {
        this.code = input;
    }
    bool empty()
    {
        return index >= code.length;
    }
    Token token;
    void popFront()
    {
        int i = index;
        for(;i < code.length;i++)
        {
            wchar c = code[i];
            if(c == ' ') continue;
            if(c.isDigit())
            {
                int num;
                for(;i < code.length;i++)
                {
                    c = code[i];
                    if(!c.isDigit())
                    {
                        break;
                    }
                    num = num * 10 + (c - '0');
                }
                token = Token(TokenType.Integer, Value(num));
                break;
            }
            //error
           
            break;
        }
        index = i;
    }
    Token front()
    {
        return token;
    }
}
unittest
{
    {
        auto lex = new Lexical("1");
        assert(lex.empty() == false);
        lex.popFront();
        auto token = lex.front();
        assert(token.type == TokenType.Integer);
        assert(token.value.integerValue == 1);
    }
    {
        auto lex = new Lexical("12345");
        assert(lex.empty() == false);
        lex.popFront();
        auto token = lex.front();
        assert(token.type == TokenType.Integer);
        assert(token.value.integerValue == 12345);
    }
}
class Parser
{
    wstring code;
    Lexical lex;
    this(wstring input)
    {
        this.code = input;
        lex = new Lexical(input);
    }
    int getOPRank(TokenType type)
    {
        switch(type)
        {
//            return 8;//&&,||
            case TokenType.And:
            case TokenType.Or:
            case TokenType.Xor:
            return 7;//AND,OR,XOR
            
//            return 6;//==,!=,<,<=,>,>=

//            return 5;//<<,>>
            case TokenType.Plus:
            case TokenType.Minus:
            return 4;//+,-(bin)
            case TokenType.Mul:
            case TokenType.Div:
//            return 3;//*,/,DIV,MOD
//            return 2;//-,NOT,!
//            return 1;//()
            default:
                return 0;//TODO:エラーにすべきかは実装次第
        }
    }
    void expression(Expression node)
    {
        term(8, node);
    }
    void term(int order, Expression node)
    {
        
    }
}
