module otya.smilebasic.parser;
import otya.smilebasic.token;
import otya.smilebasic.type;
import otya.smilebasic.node;
import std.ascii;
import std.stdio;
class Lexical
{
    TokenType[] table;
    wstring code;
    int index;
    this(wstring input)
    {
        this.code = input;
        table = new TokenType[256];
        for(int i = 0;i<256;i++)
        {
            table[i] = TokenType.Unknown;
        }
        table['+'] = TokenType.Plus;
        table['-'] = TokenType.Minus;
        table['*'] = TokenType.Mul;
        table['/'] = TokenType.Div;
        table['('] = TokenType.LParen;
        table[')'] = TokenType.RParen;
    }
    bool empty()
    {
        return index >= code.length;
    }
    Token token;
    void popFront()
    {
        if(empty())
        {
            token = Token(TokenType.Unknown);
            return;
        }
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
            if(table[cast(char)c] == TokenType.Unknown)
            {
                //error
            }
            token = Token(table[cast(char)c]);
            i++;
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
        assert(lex.empty() == true);
    }
    {
        auto lex = new Lexical("12345");
        assert(lex.empty() == false);
        lex.popFront();
        auto token = lex.front();
        assert(token.type == TokenType.Integer);
        assert(token.value.integerValue == 12345);
        assert(lex.empty() == true);
    }
    {
        auto lex = new Lexical("12345 67890");
        assert(lex.empty() == false);
        lex.popFront();
        auto token = lex.front();
        assert(token.type == TokenType.Integer);
        assert(token.value.integerValue == 12345);
        assert(lex.empty() == false);
        lex.popFront();
        token = lex.front();
        assert(token.type == TokenType.Integer);
        assert(token.value.integerValue == 67890);
        assert(lex.empty() == true);
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
            return 3;//*,/,DIV,MOD
//            return 2;//-,NOT,!
//            return 1;//()
            default:
                return 0;//TODO:エラーにすべきかは実装次第
        }
    }
    int calc()
    {
        lex.popFront();
        auto exp = expression();
        writeln();
        return calc(exp);
    }
    int calc(Expression exp)
    {
        switch(exp.type)
        {
            case NodeType.Constant:
                return (cast(Constant)exp).value.integerValue;
            case NodeType.BinaryOperator:
                {
                    auto binop = cast(BinaryOperator)exp;
                    auto i1 = calc(binop.item1);
                    auto i2 = calc(binop.item2);
                    switch(binop.operator)
                    {
                        case TokenType.Plus:
                            return i1 + i2;
                        case TokenType.Minus:
                            return i1 - i2;
                        case TokenType.Mul:
                            return i1 * i2;
                        case TokenType.Div:
                            return i1 / i2;
                        default:
                            return - - -1;
                    }
                }
                break;
            default:
                return - - -1;
        }
    }
    Expression expression()
    {
        Expression node = null;
        return term(8, node);
    }
    Expression term(int order, Expression node)
    {
        if(order == 1)
        {
            return factor();
        }
        Expression exp = term(order - 1, node);
        auto token = lex.front();
        if(order == getOPRank(token.type))
        {
            BinaryOperator op = new BinaryOperator(exp);
            while(order == getOPRank(token.type))
            {
                auto tt = token.type;
                op.operator = token.type;
                lex.popFront();
                op.item2 = term(order - 1, node);
                token = lex.front();
                write(tt, " ");
                if(order == getOPRank(token.type))
                {
                    BinaryOperator op2 = new BinaryOperator(op);
                    op.item1 = op2;
                }
                stdout.flush();
            }
            return op;
        }
        return exp;
    }
    Expression factor()
    {
        auto token = lex.front();
        Expression node = null;
        switch(token.type)
        {
            case TokenType.Integer:
                write(token.value.integerValue, ' ');
                stdout.flush();
                node = new Constant(Value(token.value.integerValue));
                break;
            case TokenType.LParen:
                lex.popFront();
                node = expression();
                token = lex.front();
                if(token.type != TokenType.RParen)
                    //error
                {}
                break;
            default:
                return node;
        }
        if(!lex.empty())
            lex.popFront();
        return node;
    }
}
void test(wstring exp, int result)
{
    auto parser = new Parser(exp);
    assert(parser.calc() == result);
}
//D言語の式の評価結果と同じか検証
void Test(const char[] V)()
{
    mixin("writeln(\""~V~"\",\" = \" ,"~V~");test(\""~V~"\", "~V~");");
}
unittest
{
    Test!"2+20/5*3"();
    Test!"2-3*4-5"();
}
