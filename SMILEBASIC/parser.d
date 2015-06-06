module otya.smilebasic.parser;
import otya.smilebasic.token;
import otya.smilebasic.type;
import otya.smilebasic.node;
import otya.smilebasic.compiler;
import std.ascii;
import std.stdio;
class Lexical
{
    TokenType[] table;
    TokenType[wstring] reserved;
    wstring code;
    int index;
    int line;
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
        table[','] = TokenType.Comma;
        table[':'] = TokenType.Colon;
        table[';'] = TokenType.Semicolon;
        table['\r'] = TokenType.NewLine;
        table['\n'] = TokenType.NewLine;
        table['?'] = TokenType.Print;
        table['='] = TokenType.Assign;
        reserved["OR"] = TokenType.Or;
        reserved["AND"] = TokenType.And;
        reserved["XOR"] = TokenType.Xor;
        reserved["NOT"] = TokenType.Not;
        reserved["PRINT"] = TokenType.Print;
        reserved["GOTO"] = TokenType.Goto;
        reserved["IF"] = TokenType.If;
        reserved["THEN"] = TokenType.Then;
        reserved["ELSE"] = TokenType.Else;
        reserved["ENDIF"] = TokenType.Endif;
        reserved.rehash();
        line = 1;
    }
    bool empty()
    {
        return index >= code.length;
    }
    bool isSmileBasicSuffix(wchar c)
    {
        return c == '$' || c == '%' || c == '#';
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
            if(c.isAlpha())
            {
                wstring iden;
                for(;i < code.length;i++)
                {
                    c = code[i];
                    if(!c.isAlpha())
                    {
                        break;
                    }
                    iden ~= c;
                }
                if(isSmileBasicSuffix(c))
                {
                    iden ~= c;
                    i++;
                }
                else//変数が予約語であることはありえない
                {
                    auto r = reserved.get(iden, TokenType.Unknown);
                    if(r != TokenType.Unknown)
                    {
                        token = Token(r);
                        break;
                    }
                }
                token = Token(TokenType.Iden, Value(iden));
                break;
            }
            if(c == '@')
            {
                //ラベル(もしくは文字列)
                wstring iden;
                iden ~= c;
                i++;
                for(;i < code.length;i++)
                {
                    c = code[i];
                    if(!c.isAlpha())
                    {
                        break;
                    }
                    iden ~= c;
                }
                token = Token(TokenType.Label, Value(iden));
                break;
            }

            if(table[cast(char)c] == TokenType.Unknown)
            {
                //error
            }
            token = Token(table[cast(char)c]);
            i++;
            if(token.type == TokenType.NewLine)
            {
                line++;
            if(c == '\n')
            {
                //CRLF
                if(i < code.length && code[i] == '\r')
                {
                    i++;
                }
            }
            }
            break;
        }
        index = i;
    }
    Token front()
    {
        return token;
    }
    int getLine()
    {
        return line;
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
    /*
    テスト用
    */
    int calc()
    {
        lex.popFront();
        auto exp = expression();
        version(none)writeln();
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
            case NodeType.Variable:
                return 100;
            case NodeType.CallFunction:
                {
                    auto func = cast(CallFunction)exp;
                    int result = 100;
                    if(func.name == "ADD")
                    {
                        result = 0;
                        foreach(Expression i ; func.args)
                        {
                            result += calc(i);
                        }
                    }
                    return result;
                }
            default:
                return - - -1;
        }
    }
    auto compile()
    {
        auto compiler = new Compiler(parseProgram());
        return compiler.compile();
    }
    Statements parseProgram()
    {
        lex.popFront();
        auto statements = new Statements();
        while(!lex.empty())
        {
            //if token == DEF
            //
            auto statement = statement();
            if(statement != Statement.NOP)
            {
                statements.addStatement(statement);
            }
        }
        return statements;
    }
    Statements ifstatements()
    {
        auto statements = new Statements();
        while(!lex.empty())
        {
            auto type = lex.front().type;
            if(type == TokenType.NewLine) break;
            if(type == TokenType.Else) break;
            if(type == TokenType.Endif) break;
            auto statement = statement();
            if(statement != Statement.NOP)
            {
                statements.addStatement(statement);
            }
        }
        return statements;
    }
    void syntaxError()
    {
        stderr.writeln("Syntax error (", lex.getLine(), ')', " Mysterious ", lex.front().type);
    }
    //statement
    Statement statement()
    {
        auto token = lex.front();
        Statement node = null;
        switch(token.type)
        {
            case TokenType.Print:
                node = print();
                return node;
            case TokenType.Iden:
                {
                    wstring name = token.value.stringValue;
                    lex.popFront();
                    token = lex.front();
                    if(token.type == TokenType.Assign)
                    {
                        node = assign(name);
                        break;
                    }
                    //命令呼び出し
                }
                break;
            case TokenType.Colon:
            case TokenType.NewLine:
                break;
            case TokenType.Label:
                node = new Label(token.value.stringValue);
                break;
            case TokenType.Goto:
                lex.popFront();
                token = lex.front();
                node = new Goto(token.value.stringValue);
                break;
            case TokenType.If:
                node = if_();
                return node;
            default:
                syntaxError();
                break;
        }
        lex.popFront();
        return node;
    }
    If if_()
    {
        lex.popFront();
        auto token = lex.front();
        auto expr = expression();
        if(expr is null)
        {
            syntaxError();
            return null;
        }
        token = lex.front();
        if(token.type != TokenType.Then)
        {
            if(token.type != TokenType.Goto)
            {
                //IF expr GOSUBは不可
                syntaxError();
                return null;
            }
        }
        if(token.type != TokenType.Goto)
        {
            lex.popFront();
            token = lex.front();
        }
        if(token.type == TokenType.NewLine)
        {
            writeln("NotImpl: Multi line if");
            syntaxError();
            return null;
        }
        auto then = ifstatements();
        token = lex.front();
        lex.popFront();
        Statements else_;
        if(token.type == TokenType.Else)
        {
            if(lex.front().type == TokenType.NewLine)
            {
                //3.1現在だとエラー
                syntaxError();
            }
            else_ = ifstatements();
        }
        auto if_ = new If(expr, then, else_);
        return if_;
    }
    Assign assign(wstring name)
    {
        lex.popFront();
        auto token = lex.front();//=の次
        Expression expr = expression();
        if(expr is null) return null;
        auto a = new Assign(name, expr);
        return a;
    }
    Print print()
    {
        auto print = new Print();
        bool addline = true;
        lex.popFront();
        auto token = lex.front();
        while(true)
        {
            //3号から厳密になって必ずいる
            if(token.type == TokenType.Colon || token.type == TokenType.NewLine)
            {
                print.addLine();
                break;
            }
            addline = true;
            auto exp = expression();
            if(exp is null)
            {
                syntaxError();
                continue;
            }
            print.addArgument(exp);
            token = lex.front();
            if(lex.empty())
            {
                print.addLine();
                break;
            }
            if(token.type != TokenType.Colon && token.type != TokenType.NewLine && 
               token.type != TokenType.Semicolon && token.type != TokenType.Comma &&
               token.type != TokenType.Else && token.type != TokenType.Endif)
            {
                syntaxError();
            }
            else
            {
                if(token.type == TokenType.Colon || token.type == TokenType.NewLine ||
                   token.type == TokenType.Else || token.type == TokenType.Endif)
                {
                    print.addLine();
                    break;
                }
                lex.popFront();
                if(token.type == TokenType.Semicolon)
                {
                    addline = false;
                    continue;
                }
                if(token.type == TokenType.Comma) 
                {
                    print.addTab();
                    addline = false;
                    continue;
                }
                token = lex.front();
            }
        }
        return print;
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
                version(none)
                    write(tt, " ");
                if(order == getOPRank(token.type))
                {
                    BinaryOperator op2 = new BinaryOperator(op);
                    op.item1 = op2;
                }
                version(none)stdout.flush();
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
                version(none)write(token.value.integerValue, ' ');
                version(none)stdout.flush();
                node = new Constant(Value(token.value.integerValue));
                break;
            case TokenType.Iden:
                if(!lex.empty())
                    lex.popFront();
                if(lex.front().type == TokenType.LParen)
                {
                    auto func = new CallFunction(token.value.stringValue);
                    node = func;
                    //関数呼び出しだった
                    while(true)
                    {
                        lex.popFront();
                        token = lex.front();
                        
                        if(token.type == TokenType.Comma)
                        {
                            func.addArg(new VoidExpression());
                            lex.popFront();
                            token = lex.front();
                        }
                        else
                        func.addArg(expression());
                        if(lex.front().type == TokenType.RParen) break;
                    }
                }
                else
                {
                    return new Variable(token.value.stringValue);
                }
                break;
            case TokenType.LParen:
                lex.popFront();
                node = expression();
                token = lex.front();
                if(token.type != TokenType.RParen)
                    //error
                {}
                break;
            case TokenType.Label://3.1
                //文字列リテラル

                break;
            default:
                return node;
        }
        if(!lex.empty())
            lex.popFront();
        return node;
    }
}
private void test(wstring exp, int result)
{
    auto parser = new Parser(exp);
    assert(parser.calc() == result);
}
//D言語の式の評価結果と同じか検証
private void Test(const char[] V)()
{
    mixin("writeln(\""~V~"\",\" = \" ,"~V~");test(\""~V~"\", "~V~");");
}
unittest
{
    struct Eval
    {
        wstring val;
        this(wstring val)
        {
            this.val = val;
        }
        bool opAssign(int result)
        {
            auto parser = new Parser(val);
            try
            {
                assert(parser.calc() == result);
            }
            catch(Exception e)
            {
                assert(false, e.toString());
            }
            return false;
        }
    }
    test("1+1", 2);//1+1は2
    test("2*3+2", 8);//2*3+2は8
    test("2*3+2+1", 9);//2*3+2+1は9
    Eval("2+3*4+2") = 2+3*4+2;
    Eval("2+3*4*5+6*7+8") = 2+3*4*5+6*7+8;
    Eval("2+3*4*5") = 2+3*4*5;
    Eval("(2+3)*4*5") = (2+3)*4*5;
    Eval("(1)+(2)") = (1)+(2);
    Test!"2+(3+4)*5"();
    Test!"2+20/5*3"();
    //Eval("test(2+5)") = 2+5;
    //Eval("test(2+5, test(2, 3+5))") = 3+5;
    Test!"2-3*4-5"();
    Test!"1+2+3+4*5/4-5+(6+6)*7"();
}
