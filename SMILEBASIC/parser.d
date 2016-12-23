module otya.smilebasic.parser;
import otya.smilebasic.token;
import otya.smilebasic.type;
import otya.smilebasic.node;
import otya.smilebasic.compiler;
import std.ascii;
import std.stdio;
import std.conv;
import std.range;
class Lexical
{
    TokenType[] table;
    TokenType[wstring] reserved;
    wstring code;
    int index;
    int line;
    void initReservedWordsTable()
    {
        table = new TokenType[65536];
        for(int i = 0;i<65536;i++)
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
        table['<'] = TokenType.Less;
        table['>'] = TokenType.Greater;
        table['!'] = TokenType.LogicalNot;
        table['['] = TokenType.LBracket;
        table[']'] = TokenType.RBracket;
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
        reserved["FOR"] = TokenType.For;
        reserved["NEXT"] = TokenType.Next;
        reserved["MOD"] = TokenType.Mod;
        reserved["DIV"] = TokenType.IntDiv;
        reserved["GOSUB"] = TokenType.Gosub;
        reserved["RETURN"] = TokenType.Return;
        reserved["END"] = TokenType.End;
        reserved["BREAK"] = TokenType.Break;
        reserved["CONTINUE"] = TokenType.Continue;
        reserved["VAR"] = TokenType.Var;
        reserved["DIM"] = TokenType.Dim;
        reserved["DEF"] = TokenType.Def;
        reserved["OUT"] = TokenType.Out;
        reserved["out"] = TokenType.Out;//ekkitou
        reserved["WHILE"] = TokenType.While;
        reserved["WEND"] = TokenType.WEnd;
        reserved["INC"] = TokenType.Inc;
        reserved["DEC"] = TokenType.Dec;
        reserved["DATA"] = TokenType.Data;
        reserved["READ"] = TokenType.Read;
        reserved["RESTORE"] = TokenType.Restore;
        reserved["ON"] = TokenType.On;
        reserved["INPUT"] = TokenType.Input;
        reserved["TRUE"] = TokenType.True;
        reserved["FALSE"] = TokenType.False;
        reserved["CALL"] = TokenType.Call;
        reserved["COMMON"] = TokenType.Common;
        reserved["USE"] = TokenType.Use;
        reserved["EXEC"] = TokenType.Exec;
        reserved["ELSEIF"] = TokenType.Elseif;
        reserved["REPEAT"] = TokenType.Repeat;
        reserved["UNTIL"] = TokenType.Until;
        reserved["SWAP"] = TokenType.Swap;
        reserved.rehash();
    }
    this(wstring input)
    {
        initReservedWordsTable();
        this.code = input;
        line = 1;
    }
    this(Lexical lex)
    {
        this.code = lex.code;
        this.reserved = lex.reserved;
        this.table = lex.table;
        this.pos = lex.pos;
        this.token = lex.token;
        this.isEmpty = lex.isEmpty;
        this.index = lex.index;
        this.line = lex.line;
    }
    Lexical save()
    {
        return new Lexical(this);
    }
    bool empty()
    {
        return index >= code.length;
    }
    bool isSmileBasicSuffix(wchar c)
    {
        return c == '$' || c == '%' || c == '#';
    }
    SourceLocation location;
    Token token;
    private int pos;
    bool isEmpty;
    void popFront()
    {
        if(index >= code.length)
        {/*
            if(!isEmpty)
            {
                //token = Token(TokenType.NewLine);
                isEmpty = true;
                //return;
            }*/
            token = Token(TokenType.NewLine);
            return;
        }
        int i = index;
        for(;i < code.length;i++)
        {
            wchar c = code[i];
            if(c == ' ') continue;
            if(c == '\'')
            {
                for(;i < code.length;i++)
                {
                    c = code[i];
                    if(table[c] == TokenType.NewLine) break;
                }
                token = Token(TokenType.NewLine);
                if (i >= code.length)
                    break;
            }
            if(c.isDigit() || c == '.')
            {
                bool dot;
                int start = i;
                double num;
                for(;i < code.length;i++)
                {
                    c = code[i];
                    if(c == '.') 
                    {
                        if(dot) break;
                        dot = true;
                    }
                    if(!c.isDigit() && c != '.')
                    {
                        break;
                    }
                }
                wstring numstr = code[start..i];
                num = numstr.to!double;
                if(num <= int.max && num >= int.min && !dot)
                {
                    token = Token(TokenType.Integer, TokenValue(cast(int)num));
                }
                else
                {
                    token = Token(TokenType.Integer, TokenValue(num));
                }
                break;
            }
            if(c.isAlpha() || c == '_')
            {
                wstring iden;
                for(;i < code.length;i++)
                {
                    c = cast(wchar)code[i].toUpper;
                    if(!c.isAlpha() && !c.isDigit() && c != '_')
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
                    //TRUE/FALSEは3.1でもDATAに使える定数
                    if(r == TokenType.True)
                    {
                        token = Token(TokenType.Integer, TokenValue(1));
                        break;
                    }
                    if(r == TokenType.False)
                    {
                        token = Token(TokenType.Integer, TokenValue(0));
                        break;
                    }
                    if(r != TokenType.Unknown)
                    {
                        token = Token(r, TokenValue(iden));
                        break;
                    }
                }
                if (iden == "REM")
                {
                    for(;i < code.length;i++)
                    {
                        c = code[i];
                        if(table[c] == TokenType.NewLine) break;
                    }
                    token = Token(TokenType.NewLine);
                    if (i >= code.length)
                        break;
                }
                else
                {
                    token = Token(TokenType.Iden, TokenValue(iden));
                    break;
                }
            }
            if(c == '"')
            {
                i++;
                wstring str;
                for(;i < code.length;i++)
                {
                    c = code[i];
                    if(c == '"' || c == '\r' || c == '\n')//"を閉じない文も許容
                    {
                        i++;
                        if (c == '\r' || c == '\n') i--;
                        break;
                    }
                    str ~= c;
                }
                token = Token(TokenType.String, TokenValue(str));
                break;
            }
            if(c == '@' || c == '#')
            {
                //ラベル(もしくは文字列)
                wstring iden;
                bool isLabel = c == '@';
                if (isLabel)
                    iden ~= c;
                i++;
                for(;i < code.length;i++)
                {
                    c = code[i];
                    if(!c.isAlpha() && !c.isDigit() && c != '_')
                    {
                        break;
                    }
                    iden ~= c;
                }
                if (isLabel)
                {
                    token = Token(TokenType.Label, TokenValue(iden));
                }
                else
                {
                    token = Token(TokenType.Constant, TokenValue(std.uni.toUpper(iden)));
                }
                break;
            }
            if(c == '=' && i + 1 < code.length && code[i + 1] == '=')
            {
                token = Token(TokenType.Equal);
                i += 2;
                break;
            }
            if(c == '!' && i + 1 < code.length && code[i + 1] == '=')
            {
                token = Token(TokenType.NotEqual);
                i += 2;
                break;
            }
            if(c == '<' && i + 1 < code.length && code[i + 1] == '=')
            {
                token = Token(TokenType.LessEqual);
                i += 2;
                break;
            }
            if(c == '>' && i + 1 < code.length && code[i + 1] == '=')
            {
                token = Token(TokenType.GreaterEqual);
                i += 2;
                break;
            }
            if(c == '<' && i + 1 < code.length && code[i + 1] == '<')
            {
                token = Token(TokenType.LeftShift);
                i += 2;
                break;
            }
            if(c == '>' && i + 1 < code.length && code[i + 1] == '>')
            {
                token = Token(TokenType.RightShift);
                i += 2;
                break;
            }
            if(c == '&' && i + 1 < code.length)
            {
                if(code[i + 1].toUpper == 'H')
                {
                    i += 2;
                    int start = i;
                    for(;i < code.length;i++)
                    {
                        c = cast(wchar)(code[i].toUpper);
                        if(!c.isDigit() && (c < 'A' || c > 'F'))
                        {
                            break;
                        }
                    }
                    wstring numstr = code[start..i];
                    int num = numstr.to!uint(16);
                    token = Token(TokenType.Integer, TokenValue(num));
                    break;
                }
                if(code[i + 1].toUpper == 'B')
                {
                    i += 2;
                    int start = i;
                    for(;i < code.length;i++)
                    {
                        c = code[i];
                        if(c != '1' && c != '0')
                        {
                            break;
                        }
                    }
                    wstring numstr = code[start..i];
                    int num = numstr.to!uint(2);
                    token = Token(TokenType.Integer, TokenValue(num));
                    break;
                }
                if(code[i + 1] == '&')
                {
                    token = Token(TokenType.LogicalAnd);
                    i += 2;
                    break;
                }
            }
            if(c == '|' && i + 1 < code.length && code[i + 1] == '|')
            {
                token = Token(TokenType.LogicalOr);
                i += 2;
                break;
            }
            if(table[c] == TokenType.Unknown)
            {
                //error
            }
            token = Token(table[c]);
            i++;
            //CRLFだった
            if(token.type == TokenType.NewLine)
            {
                line++;
                if(c == '\r')
                {
                    //CRLF
                    if(i < code.length && code[i] == '\n')
                    {
                        i++;
                    }
                }
                pos = i;
            }
            break;
        }
        this.location.pos = i - this.pos;
        this.location.line = line;
        this.location.pos2 = index - 1;
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
    wstring getLine(SourceLocation loc)
    {
        import std.string;
        auto mae = code[0 .. loc.pos2].lastIndexOf('\n');
        mae++;
        auto ushiro = code[mae..$].indexOf('\n');
        if(ushiro == -1) ushiro = code.length;
        return code[mae .. mae + ushiro];
    }
    wstring code;
    Lexical lex;
    this(wstring input)
    {
        this.code = input;
        lex = new Lexical(input);
        initConstant();
    }
    const static int opMax = 11;
    int getOPRank(TokenType type)
    {
        switch(type)
        {
            version(none)
            {
            case TokenType.LogicalAnd:
            case TokenType.LogicalOr:
            return 8;//&&,||
            case TokenType.And:
            case TokenType.Or:
            case TokenType.Xor:
            return 7;//AND,OR,XOR
            }
            case TokenType.LogicalAnd:
                return 10;//&&,||
            case TokenType.LogicalOr:
                return 11;//&&,||
            case TokenType.And:
                return 7;//AND,OR,XOR
            case TokenType.Or:
                return 9;//AND,OR,XOR
            case TokenType.Xor:
                return 9;//AND,OR,XOR
            case TokenType.Equal:
            case TokenType.NotEqual:
            case TokenType.Less:
            case TokenType.LessEqual:
            case TokenType.Greater:
            case TokenType.GreaterEqual:
            return 6;//==,!=,<,<=,>,>=
            case TokenType.LeftShift:
            case TokenType.RightShift:
            return 5;//<<,>>
            case TokenType.Plus:
            case TokenType.Minus:
            return 4;//+,-(bin)
            case TokenType.Mul:
            case TokenType.Div:
            case TokenType.IntDiv:
            case TokenType.Mod:
            return 3;//*,/,DIV,MOD
            case TokenType.LBracket:
                return 2;//合ってるか不明
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
                return (cast(Constant)exp).value.castInteger;
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
    auto compiler()
    {
        auto compiler = new Compiler(parseProgram());
        return compiler;
    }
    auto compile()
    {
        auto compiler = new Compiler(parseProgram());
        return compiler.compile();
    }
    Statements parseProgram()
    {
        lex.popFront();
        auto statements = new Statements(lex.location);
        do
        {
            auto token = lex.front();
            Statement statement;
            if(token.type == TokenType.Common)
            {
                lex.popFront();
                token = lex.front();
                if (token.type != TokenType.Def)
                {
                    syntaxError();
                }
                else
                {
                    statement = defineFunction(true);
                }
            }
            else if(token.type == TokenType.Def)
            {
                statement = defineFunction(false);
            }
            else
            {
                statement = this.statement();
            }
            if(statement != Statement.NOP)
            {
                statements.addStatement(statement);
            }
        } while(!lex.empty());
        return statements;
    }
    bool isFuncReturnExpr = false;
    wstring getFunctionArgument()
    {
        auto token = lex.front();
        if(token.type != TokenType.Iden)
        {
            syntaxError();
            return "";
        }
        lex.popFront();
        if(lex.front().type == TokenType.LBracket)
        {
            lex.popFront();
            if(lex.front().type != TokenType.RBracket)
            {
                syntaxError();
                return "";
            }
            lex.popFront();
        }
        return token.value.stringValue;
    }
    DefineFunction defineFunction(bool isCommon)
    {
        lex.popFront();
        auto token = lex.front();
        if(token.type != TokenType.Iden)
        {
            syntaxError();
            return null;
        }
        DefineFunction node = new DefineFunction(token.value.stringValue, isCommon, lex.location);
        lex.popFront();
        token = lex.front();
        if(token.type == TokenType.LParen)
        {
            node.returnExpr = true;
            lex.popFront();
            //MEMO:引数に[]を付けようが扱いは同一
            while(true)
            {
                if(lex.front().type == TokenType.RParen)
                {
                    lex.popFront();
                    break;
                }
                wstring arg = getFunctionArgument();
                if(arg.length == 0)
                {
                    return null;
                }
                node.addArgument(arg);
                token = lex.front();
                if(token.type == TokenType.Comma)
                {
                    lex.popFront();
                    continue;
                }
                //MEMO:引数に[]を付けようが扱いは同一
                if(token.type == TokenType.RParen)
                {
                    lex.popFront();
                    break;
                }
                syntaxError();
                return null;
            }
        }
        else
        {
            //MEMO:引数に[]を付けようが扱いは同一
            token = lex.front();
            if(token.type == TokenType.Iden)
            {
                while(true)
                {
                    wstring arg = getFunctionArgument();
                    if(arg.length == 0)
                    {
                        return null;
                    }
                    node.addArgument(arg);
                    token = lex.front();
                    if(token.type == TokenType.Comma)
                    {
                        lex.popFront();
                        continue;
                    }
                    break;
                }
            }
            if(token.type == TokenType.Out)
            {
                lex.popFront();
                while(true)
                {
                    wstring arg = getFunctionArgument();
                    if(arg.length == 0)
                    {
                        return null;
                    }
                    node.addOutArgument(arg);
                    token = lex.front();
                    if(token.type == TokenType.Comma)
                    {
                        lex.popFront();
                        continue;
                    }
                    break;
                }
            }
            node.returnExpr = false;
            //void関数にRETURN核とsyntaxerror
        }
        isFuncReturnExpr = node.returnExpr;//面倒くさい
        node.functionBody = functionStatements();
        lex.popFront();
        isFuncReturnExpr = false;
        return node;
    }
    Statements functionStatements()
    {
        auto statements = new Statements(lex.location);
        while(true)
        {
            auto type = lex.front().type;
            if(type == TokenType.End) break;
            if(lex.empty())
            {
                //TODO:DEF without edn
                syntaxError();
                break;
            }
            auto statement = statement();
            if(statement != Statement.NOP)
            {
                statements.addStatement(statement);
            }
        }
        return statements;
    }
    Statements ifStatements()
    {
        auto statements = new Statements(lex.location);
        bool flag = true;
        while(!lex.empty())
        {
            auto type = lex.front().type;
            flag = false;
            if(type == TokenType.NewLine) break;
            if(type == TokenType.Else) break;
            if(type == TokenType.Elseif) break;
            if(type == TokenType.Endif) break;
            if(type == TokenType.Label)
            {
                statements.addStatement(new Goto(lex.front.value.stringValue, lex.location));
                lex.popFront;
                continue;
            }
            auto statement = statement();
            if(statement != Statement.NOP)
            {
                statements.addStatement(statement);
            }
        }
        return statements;
    }
    Statements multilineIfStatements()
    {
        auto statements = new Statements(lex.location);
        while(!lex.empty())
        {
            auto type = lex.front().type;
            if(type == TokenType.Else) break;
            if(type == TokenType.Elseif) break;
            if(type == TokenType.Endif) break;
            auto statement = statement();
            if(statement != Statement.NOP)
            {
                statements.addStatement(statement);
            }
        }
        return statements;
    }
    Statements forStatements()
    {
        auto statements = new Statements(lex.location);
        while(!lex.empty())
        {
            auto type = lex.front().type;
            if(type == TokenType.Next) break;
            auto statement = statement();
            if(statement != Statement.NOP)
            {
                statements.addStatement(statement);
            }
        }
        ignoreVarNext();
        return statements;
    }
    void ignoreVarNext()
    {
        lex.popFront();
        auto token = lex.front;
        if(token.type == TokenType.Iden)
        {
            //NEXT I[,J[,K...]]プチコン3号だと無視
            lex.popFront();
            token = lex.front;
            while(token.type == TokenType.Comma)
            {
                lex.popFront();
                token = lex.front;
                if(token.type != TokenType.Iden) break;
                lex.popFront();
                token = lex.front;
            }
        }
    }
    Statements whileStatements()
    {
        auto statements = new Statements(lex.location);
        while(!lex.empty())
        {
            auto type = lex.front().type;
            if(type == TokenType.WEnd) break;
            auto statement = statement();
            if(statement != Statement.NOP)
            {
                statements.addStatement(statement);
            }
        }
        lex.popFront();
        return statements;
    }
    Statements repeatStatements()
    {
        auto statements = new Statements(lex.location);
        while(!lex.empty())
        {
            auto type = lex.front().type;
            if(type == TokenType.Until) break;
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
        stderr.writeln(this.getLine(lex.location));
        try
        {
            throw new Exception("Stacktrace");
        }
        catch(Exception e)
        {
            writeln(e);
        }
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
            case TokenType.Call:
            case TokenType.Iden:
                {
                    wstring name = token.value.stringValue;
                    auto uname = std.uni.toUpper(name);
                    if (uname == "OPTION")
                    {
                        lex.popFront;
                        token = lex.front;
                        if (token.type != TokenType.Iden)
                        {
                            syntaxError();
                            return null;
                        }
                        auto arg = std.uni.toUpper(token.value.stringValue);
                        if (arg != "STRICT" && arg != "DEFINT" && arg != "TOOL")
                        {
                            syntaxError();
                            return null;
                        }
                        lex.popFront();
                        return new Option(arg, lex.location);
                    }
                    if (uname == "XON" || uname == "XOFF")
                    {
                        lex.popFront;
                        token = lex.front;
                        if (token.type != TokenType.Iden)
                        {
                            syntaxError();
                            return null;
                        }
                        auto arg = std.uni.toUpper(token.value.stringValue);
                        if (arg != "MOTION" && arg != "EXPAD" && arg != "MIC" && (uname == "XOFF" || (arg != "WIIU" && arg != "3DS" && arg != "COMPAT")))
                        {
                            syntaxError();
                            return null;
                        }
                        lex.popFront();
                        return uname == "XON" ? new XOn(arg, lex.location) : new XOff(arg, lex.location);
                    }
                    if (token.type != TokenType.Call)
                    {
                        auto old = lex.save;
                        auto expr = expression;
                        token = lex.front;
                        if (token.type == TokenType.Assign)
                        {
                            if (expr.type == NodeType.Variable)
                            {
                                auto variable = cast(Variable)expr;
                                node = assign(variable.name);
                                return node;
                            }
                            node = assign(expr);
                            return node;
                        }
                        else
                        {
                            lex = old;
                        }
                    }
                    lex.popFront();
                    //命令呼び出し
                    auto func = new CallFunctionStatement(name, lex.location);
                    node = func;
                    bool oldcomma;
                    while(true)
                    {
                        token = lex.front();

                        if(token.type == TokenType.Comma)
                        {
                            func.addArg(new VoidExpression(lex.location));
                            lex.popFront();
                            token = lex.front();
                        }
                        else
                        {
                            auto expr = expression();
                            if(expr || oldcomma || lex.front.type == TokenType.Comma)//if(expr)
                                func.addArg(expr);
                        }
                        if(lex.front().type == TokenType.Out) break;
                        if(lex.front().type != TokenType.Comma) break;
                        oldcomma = true;
                        lex.popFront();
                    }
                    if(lex.front().type == TokenType.Out)
                    {
                        lex.popFront();
                        token = lex.front();
                        while(true)
                        {
                            token = lex.front();
                            if (token.type == TokenType.Comma)
                            {
                                func.addOut(new VoidExpression(lex.location));
                            }
                            else
                            {
                                Expression arg = expression();
                                if (!arg)
                                {
                                    func.addOut(new VoidExpression(lex.location));
                                    break;
                                }
                                if(!isLValue(arg))
                                {
                                    //to support func args... OUT (no argument)
                                    if (!func.outVariable.length)
                                    {
                                        break;
                                    }
                                    syntaxError();
                                    return null;
                                }
                                func.addOut(arg);
                            }
                            token = lex.front();
                            if(token.type == TokenType.Comma)
                            {
                                lex.popFront();
                                continue;
                            }
                            break;
                        }
                    }
                    return node;
                }
                //break;
            case TokenType.Colon:
            case TokenType.NewLine:
                break;
            case TokenType.Label:
                node = new Label(token.value.stringValue, lex.location);
                break;
            case TokenType.Goto:
                lex.popFront();
                token = lex.front();
                if(token.type == TokenType.Label)
                    node = new Goto(token.value.stringValue, lex.location);
                else
                {
                    auto e = expression();
                    if(!e)
                        syntaxError();
                    node = new Goto(e, lex.location);
                    return node;
                }
                break;
            case TokenType.Gosub:
                lex.popFront();
                token = lex.front();
                if(token.type == TokenType.Label)
                    node = new Gosub(token.value.stringValue, lex.location);
                else
                {
                    auto e = expression();
                    if(!e)
                        syntaxError();
                    node = new Gosub(e, lex.location);
                    return node;
                }
                break;
            case TokenType.If:
                node = if_();
                return node;
            case TokenType.For:
                return forStatement();
            case TokenType.Return:
                lex.popFront();
                if(isFuncReturnExpr)
                {
                    node = new Return(expression(), lex.location);
                }
                else
                {
                    node = new Return(null, lex.location);
                }
                return node;
            case TokenType.End:
                node = new End(lex.location);
                break;
            case TokenType.Break:
                node = new Break(lex.location);
                break;
            case TokenType.Next:
                node = new Continue(lex.location);
                ignoreVarNext();
                return node;
            case TokenType.Continue:
                node = new Continue(lex.location);
                break;
            case TokenType.Var:
                {
                    auto old = lex.save;
                    lex.popFront();
                    token = lex.front;
                    if (token.type == TokenType.LParen)
                    {
                        lex = old;
                        token = lex.front;
                        goto case TokenType.Iden;
                    }
                    node = var();
                    return node;
                }
            case TokenType.Dim:
                lex.popFront();
                node = var();
                return node;
            case TokenType.While:
                node = whileStatement();
                break;
            case TokenType.Repeat:
                node = repeatStatement();
                break;
            case TokenType.Inc:
            case TokenType.Dec:
                return incStatement();
            case TokenType.Data:
                return dataStatement();
            case TokenType.Read:
                return readStatement();
            case TokenType.Restore:
                return restoreStatement();
            case TokenType.On:
                node = onStatement();
                break;
            case TokenType.Input:
                return inputStatement();
            case TokenType.Use:
                {
                    lex.popFront();
                    auto expr = expression();
                    if (!expr)
                    {
                        syntaxError();
                        return null;
                    }
                    return new Use(expr, lex.location);
                }
                break;
            case TokenType.Exec:
                {
                    lex.popFront();
                    auto expr = expression();
                    if (!expr)
                    {
                        syntaxError();
                        return null;
                    }
                    return new Exec(expr, lex.location);
                }
                break;
            case TokenType.Swap:
                return swapStatement();
            default:
                syntaxError();
                break;
        }
        lex.popFront();
        return node;
    }
    Swap swapStatement()
    {
        lex.popFront();
        auto expr1 = expression();
        if (lex.front.type == TokenType.Comma)
        {
            lex.popFront();
        }
        else
        {
            syntaxError();
        }
        auto expr2 = expression();
        if (!expr1 || !expr2)
        {
            syntaxError();
        }
        if (!isLValue(expr1) || !isLValue(expr2))
        {
            syntaxError();
        }
        return new Swap(expr1, expr2, lex.location);
    }
    //左辺値か
    bool isLValue(Expression expr)
    {
        if (!expr)
        {
            return false;
        }
        if(expr.type == NodeType.Variable)
        {
            return true;
        }
        if(expr.type == NodeType.VarRef)
        {
            return true;
        }
        if(expr.type == NodeType.BinaryOperator)
        {
            auto op = cast(BinaryOperator)expr;
            if(!isLValue(op.item1)) return false;
            return op.operator == TokenType.LBracket;
        }
        return false;
    }
    Input inputStatement()
    {
        lex.popFront();
        Expression message = expression();
        if(!message)
        {
            syntaxError();
            return null;
        }
        auto token = lex.front();
        if(token.type == TokenType.Semicolon || (token.type == TokenType.Comma && !isLValue(message)))
        {
            Input input = new Input(message, token.type == TokenType.Semicolon, lex.location);
            do
            {
                lex.popFront();
                auto expr = expression();
                if(!isLValue(expr))
                {
                    syntaxError();
                }
                input.addVariable(expr);
                token = lex.front();
            } while(token.type == TokenType.Comma);
            return input;
        }
        else
        {
            if(!isLValue(message))
            {
                   syntaxError();
                   return null;
            }
            Input input = new Input(null, true, lex.location);
            input.addVariable(message);
            do
            {
                lex.popFront();
                auto expr = expression();
                if(!isLValue(expr))
                {
                    syntaxError();
                }
                input.addVariable(expr);
                token = lex.front();
            } while(token.type == TokenType.Comma);

            return input;
        }
    }
    On onStatement()
    {
        lex.popFront();
        auto cond = expression();
        if(!cond) return null;
        auto token = lex.front();
        On on;
        if(token.type == TokenType.Gosub)
        {
            on = new On(cond, true, lex.location);//gosub
        }
        else if(token.type == TokenType.Goto)
        {
            on = new On(cond, false, lex.location);//gosub
        }
        else
        {
            //GOTO/GOSUBいる
            syntaxError();
            return null;
        }
        do
        {
            lex.popFront();
            token = lex.front();
            if(token.type != TokenType.Label)
            {
                syntaxError();
                return null;
            }
            on.addLabel(token.value.stringValue);
            lex.popFront();
            token = lex.front();
        } while(token.type == TokenType.Comma);
        return on;
    }
    Data dataStatement()
    {
        Data data = new Data(lex.location);
        lex.popFront();
        auto token = lex.front();
        while(true)
        {
            bool minusflag;
            auto expr = cast(Constant)expression();
            if (expr)
            {
                data.addData(expr.value);
            }
            else
            {
                syntaxError();
                return null;
            }
            token = lex.front();
            if(token.type == TokenType.Comma)
            {
                lex.popFront();
                token = lex.front();
                continue;
            }
            break;
        }
        return data;
    }
    Read readStatement()
    {
        Read read = new Read(lex.location);
        Token token;
        do
        {
            lex.popFront();
            auto expr = expression();
            if(!expr || !isLValue(expr))
            {
                syntaxError();
            }
            read.addVariable(expr);
            token = lex.front();
        } while(token.type == TokenType.Comma);
        return read;
    }
    Restore restoreStatement()
    {
        lex.popFront();
        auto label = expression();
        if(!label)
        {
            syntaxError();
            return null;
        }
        return new Restore(label, lex.location);
    }
    Inc incStatement()
    {
        auto token = lex.front();
        bool dec = token.type == TokenType.Dec;
        lex.popFront();
        token = lex.front();
        Expression var = expression();
        if(!isLValue(var))
        {
            syntaxError();
            return null;
        }
        token = lex.front();
        Expression expr;
        if(token.type == TokenType.Comma)
        {
            lex.popFront();
            expr = expression();
            if(!expr)
            {
                syntaxError();
                return null;
            }
        }
        else
        {
            expr = new Constant(TokenValue(1), lex.location);
        }
        if(dec)
        {
            expr = new BinaryOperator(new Constant(TokenValue(0), lex.location), TokenType.Minus, expr, lex.location);
        }
        return new Inc(var, expr, lex.location);
    }
    IndexExpressions indexExpressions()
    {
        IndexExpressions ie = new IndexExpressions(lex.location);
        int count = 0;
        while(true)
        {
            ie.addExpression(expression());
            count++;
            auto token = lex.front();
            if(token.type == TokenType.Comma)
            {
                lex.popFront();
                if(count >= 4)
                {
                    syntaxError();
                }
                continue;
            }
            if(token.type == TokenType.RBracket)
            {
                break;
            }
            syntaxError();
            break;
        }
        return ie;
    }
    ArrayAssign arrayAssign(wstring name)
    {
        lex.popFront();
        auto ie = indexExpressions();
        auto token = lex.front();
        if(token.type != TokenType.RBracket)
        {
            return null;
        }
        lex.popFront();
        token = lex.front();
        if(token.type != TokenType.Assign)
        {
            //=が欲しい
            syntaxError();
            return null;
        }
        lex.popFront();
        auto expr = expression();
        token = lex.front();
        auto node = new ArrayAssign(name, ie, expr, lex.location);
        return node;
    }
    Statement var()
    {
        Var var = new Var(lex.location);
        Token token;
        while(true)
        {
            token = lex.front();
            if(token.type != TokenType.Iden)
            {
                //TODO:VAR("A")の実装
                syntaxError();
                return null;
            }
            auto v = defineVar();
            if(v.type == NodeType.DefineVariable)
            {
                var.addDefineVar(cast(DefineVariable)v);
            }
            if(v.type == NodeType.DefineArray)
            {
                var.addDefineArray(cast(DefineArray)v);
            }
            token = lex.front();
            //VARの評価順は順番通り
            //VAR iden[=expr],
            if(token.type == TokenType.Comma)
            {
                lex.popFront();
            }
            else
            {
                break;
            }
        }
        return var;
    }
    Statement defineVar()
    {
        Token token = lex.front();
        wstring name = token.value.stringValue;
        lex.popFront();
        token = lex.front();
        Expression expr;
        //VAR iden[
        if(token.type == TokenType.LBracket)
        {
            lex.popFront();
            auto dim = indexExpressions();
            token = lex.front();
            if(token.type != TokenType.RBracket)
                return null;
            lex.popFront();
            DefineArray ary = new DefineArray(name, dim, lex.location);
            return ary;
        }
        else
        {
            //VAR iden=expr
            if(token.type == TokenType.Assign)
            {
                lex.popFront();
                expr = expression();
                token = lex.front();
            }
        }
        DefineVariable node = new DefineVariable(name, expr, lex.location);
        return node;
    }
    For forStatement()
    {
        For node;
        lex.popFront();
        Statement initStatement = statement();
        if(initStatement.type != NodeType.Assign)
        {
            syntaxError();
            return null;
        }
        Assign init = cast(Assign)initStatement;

        auto token = lex.front();
        //TO,STEPは予約語ではない
        if(token.type != TokenType.Iden || token.value.stringValue != "TO")
        {
            syntaxError();
            return null;
        }
        lex.popFront();
        Expression to = expression();
        token = lex.front();
        Expression step;
        //TO,STEPは予約語ではない
        if(token.type == TokenType.Iden && token.value.stringValue == "STEP")
        {
            lex.popFront();
            step = expression();
        }
        else
        {
            //とりあえず
            step = new Constant(TokenValue(1), lex.location);
        }
        token = lex.front();
        Statements statements = forStatements();
        node = new For(init, to, step, statements, lex.location);
        return node;
    }
    While whileStatement()
    {
        lex.popFront();
        auto expr = expression();
        if(expr is null)
        {
            syntaxError();
            return null;
        }
        Statements statements = whileStatements();
        auto node = new While(expr, statements, lex.location);
        return node;
    }
    RepeatUntil repeatStatement()
    {
        lex.popFront();
        Statements statements = repeatStatements();
        auto token = lex.front;
        if (token.type != TokenType.Until)
        {
            //TODO:REPEAT without UNTIL
            syntaxError();
            return null;
        }
        lex.popFront();
        auto expr = expression();
        if(expr is null)
        {
            syntaxError();
            return null;
        }
        auto node = new RepeatUntil(expr, statements, lex.location);
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
        Statements then;
        bool multiline = false;
        if(token.type == TokenType.NewLine)
        {
            multiline = true;
            lex.popFront();
            then = multilineIfStatements();
        }
        else
        {
            then = ifStatements();
        }
        token = lex.front();
        lex.popFront();
        import std.typecons;
        Tuple!(Statements, Expression)[] elseif = new Tuple!(Statements, Expression)[0];
        while(token.type == TokenType.Elseif)
        {
            token = lex.front();
            auto elseifcond = expression();
            if(elseifcond is null)
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
            if(!multiline && lex.front().type == TokenType.NewLine)
            {
                syntaxError();
            }
            if(multiline)
            {
                elseif ~= tuple(multilineIfStatements(), elseifcond);
            }
            else
            {
                elseif ~= tuple(ifStatements(), elseifcond);
            }
            token = lex.front();
            lex.popFront();
        }
        Statements else_;
        if(token.type == TokenType.Else)
        {
            if(!multiline && lex.front().type == TokenType.NewLine)
            {
                //3.1現在だとエラー
                syntaxError();
            }
            if(multiline)
            {
                else_ = multilineIfStatements();
            }
            else
            {
                else_ = ifStatements();
            }
            lex.popFront();
        }
        auto if_ = new If(expr, then, else_, elseif, lex.location);
        return if_;
    }
    Assign assign(wstring name)
    {
        lex.popFront();
        auto token = lex.front();//=の次
        Expression expr = expression();
        if(expr is null) return null;
        auto a = new Assign(name, expr, lex.location);
        return a;
    }
    AssignRef assign(Expression left)
    {
        lex.popFront();
        auto token = lex.front();//=の次
        Expression expr = expression();
        if(expr is null) return null;
        if (!isLValue(left))
        {
            syntaxError();
            return null;
        }
        auto a = new AssignRef(left, expr, lex.location);
        return a;
    }
    Print print()
    {
        auto print = new Print(lex.location);
        bool addline = true;
        lex.popFront();
        auto token = lex.front();
        while(true)
        {
            //3号から厳密になって必ずいる
            if(token.type == TokenType.Colon || token.type == TokenType.NewLine)
            {
                if(addline) print.addLine();
                break;
            }
            addline = true;
            auto exp = expression();
            if(exp is null)
            {
                syntaxError();
                lex.popFront();
                token = lex.front();
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
               token.type != TokenType.Else && token.type != TokenType.Endif &&
               token.type != TokenType.Elseif && token.type != TokenType.Print)
            {
                syntaxError();
            }
            else
            {
                if(token.type == TokenType.Colon || token.type == TokenType.NewLine ||
                   token.type == TokenType.Else || token.type == TokenType.Endif ||
                   token.type == TokenType.Elseif || token.type == TokenType.Print)
                {
                    print.addLine();
                    break;
                }
                lex.popFront();
                if(token.type == TokenType.Semicolon)
                {
                    addline = false;
                    token = lex.front();
                    continue;
                }
                if(token.type == TokenType.Comma) 
                {
                    print.addTab();
                    addline = false;
                    token = lex.front();
                    continue;
                }
                token = lex.front();
            }
        }
        return print;
    }
    //compilerでやるべきな気がする
    bool constcalc(TokenValue left, TokenValue right, TokenType type, out double result)
    {
        switch (type)
        {
            case TokenType.Plus:
                result = (left.castDouble + right.castDouble);
                return true;
            case TokenType.Minus:
                result = (left.castDouble - right.castDouble);
                return true;
            case TokenType.Mul:
                result = (left.castDouble * right.castDouble);
                return true;
            case TokenType.Div:
                result = (left.castDouble / right.castDouble);
                return true;
            case TokenType.IntDiv:
                //TODO:範囲外だとOverflow
                result = (left.castInteger / right.castInteger);
                return true;
            case TokenType.Mod:
                result = (left.castDouble % right.castDouble);
                return true;
            case TokenType.And:
                result = (left.castInteger & right.castInteger);
                return true;
            case TokenType.Or:
                result = (left.castInteger | right.castInteger);
                return true;
            case TokenType.Xor:
                result = (left.castInteger ^ right.castInteger);
                return true;
            case TokenType.LeftShift:
                result = (left.castInteger << right.castInteger);
                return true;
            case TokenType.RightShift:
                result = (left.castInteger >> right.castInteger);
                return true;
            default:
                result = double.init;
                return !true;
        }
    }
    Expression expression()
    {
        Expression node = null;
        return term(opMax, node);
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
            BinaryOperator op = new BinaryOperator(exp, lex.location);
            while(order == getOPRank(token.type))
            {
                auto tt = token.type;
                op.operator = token.type;
                lex.popFront();
                if(tt == TokenType.LBracket)
                {
                    op.item2 = indexExpressions();
                    //[演算子
                    if(lex.front().type != TokenType.RBracket) return null;
                    lex.popFront();
                }
                else
                {
                    op.item2 = term(order - 1, node);
                }
                token = lex.front();
                bool constexpr;
                if (op.item1.type == NodeType.Constant && op.item2.type == NodeType.Constant)
                {
                    double result;
                    Constant leftconst = (cast(Constant)op.item1), rightconst = (cast(Constant)op.item2);
                    if (rightconst.value.isNumber && leftconst.value.isNumber)
                    {
                        if (constcalc(leftconst.value, rightconst.value, op.operator, result))
                        {
                            auto l = new Constant(TokenValue(result), lex.location);
                            constexpr = true;
                            if(order != getOPRank(token.type))
                                return l;
                            op = new BinaryOperator(l, lex.location);
                            continue;
                        }
                    }
                }
                version(none)
                    write(tt, " ");
                if(order == getOPRank(token.type))
                {
                    BinaryOperator op2 = new BinaryOperator(op, lex.location);
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
            case TokenType.String:
            case TokenType.Integer:
                version(none)write(token.value.integerValue, ' ');
                version(none)stdout.flush();
                node = new Constant(token.value, lex.location);
                break;
            case TokenType.Var:
                if(!lex.empty())
                    lex.popFront();
                if(lex.front().type == TokenType.LParen)
                {
                    lex.popFront();
                    auto expr = expression;
                    node = new VarRef(expr, lex.location);
                    if(lex.front().type != TokenType.RParen)
                        syntaxError();
                }
                else
                {
                    syntaxError();
                    return null;
                }
                break;
            case TokenType.Call:
            case TokenType.Iden:
                if(!lex.empty())
                    lex.popFront();
                if(lex.front().type == TokenType.LParen)
                {
                    auto func = new CallFunction(token.value.stringValue, lex.location);
                    node = func;
                    //関数呼び出しだった
                    while(true)
                    {
                        lex.popFront();
                        token = lex.front();

                        if(token.type == TokenType.RParen) break;
                        if(token.type == TokenType.Comma)
                        {
                            func.addArg(new VoidExpression(lex.location));
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
                    return new Variable(token.value.stringValue, lex.location);
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
                node = new Constant(token.value, lex.location);
                break;
            case TokenType.Minus:
                //TODO:UnaryOperatorの実装
                //とりあえず0-exprを作成
                {
                    lex.popFront();
                    auto a = term(2/*array*/, null);
                    double result;
                    if (a.type == NodeType.Constant && constcalc(TokenValue(0), (cast(Constant)a).value, TokenType.Minus, result))
                    {
                        node = new Constant(TokenValue(result), lex.location);
                        return node;
                    }
                    else
                    {
                        node = new BinaryOperator(new Constant(TokenValue(0), lex.location), TokenType.Minus, a, lex.location);
                        return node;
                    }
                }
            case TokenType.LogicalNot:
            case TokenType.Not:
                lex.popFront();
                node = new UnaryOperator(token.type, term(2/*array*/, null), lex.location);
                return node;
            case TokenType.Constant:
                {
                    if (token.value.castString in constant)
                    {
                        node = new Constant(TokenValue(constant[token.value.castString]), lex.location);
                    }
                    else
                    {
                        syntaxError();
                    }
                }
                break;
            default:
                return node;
        }
        if(!lex.empty())
            lex.popFront();
        return node;
    }
    int[wstring] constant;
    void initConstant()
    {
        constant = [
            "ON" : 1,
            "OFF" : 0,
            "YES" : 1,
            "NO" : 0,
            "TRUE" : 1,
            "FALSE" : 0,

            "AQUA" : 0xFF00F8F8,
            "BLACK" : 0xFF000000,
            "BLUE" : 0xFF0000FF,
            "CYAN" : 0xFF0000F8,
            "FUCHSIA" : 0xFFF800F8,
            "GRAY" : 0xFF808080,
            "GREEN" : 0xFF008000,
            "LIME" : 0xFF00F800,
            "MAGENTA" : 0xFFF800F8,
            "MAROON" : 0xFF800000,
            "NAVY" : 0xFF000080,
            "OLIVE" : 0xFF808000,
            "PURPLE" : 0xFF800080,
            "RED" : 0xFFF80000,
            "SILVER" : 0xFFC0C0C0,
            "TEAL" : 0xFF008080,
            "WHITE" : 0xFFF8F8F8,
            "YELLOW" : 0xFFF8F800,

            "TBLACK" : 1,
            "TMAROON" : 2,
            "TRED" : 3,
            "TGREEN" : 4,
            "TLIME" : 5,
            "TOLIVE" : 6,
            "TYELLOW" : 7,
            "TNAVY" : 8,
            "TBLUE" : 9,
            "TPURPLE" : 10,
            "TMAGENTA" : 11,
            "TTEAL" : 12,
            "TCYAN" : 13,
            "TGRAY" : 14,
            "TWHITE" : 15,

            "UP" : 0x0001,
            "DOWN" : 0x0002,
            "LEFT" : 0x0004,
            "RIGHT" : 0x0008,
            "A" : 0x0010,
            "B" : 0x0020,
            "X" : 0x0040,
            "Y" : 0x0080,
            "L" : 0x0100,
            "R" : 0x0200,
            "ZL" : 0x0800,
            "ZR" : 0x1000,

            "TROT0" : 0x00,
            "TROT90" : 0x01,
            "TROT180" : 0x02,
            "TROT270" : 0x03,
            "TREVH" : 0x04,
            "TREVV" : 0x08,

            "SPSHOW" : 0x01,
            "SPROT0" : 0x00,
            "SPROT90" : 0x02,
            "SPROT180" : 0x04,
            "SPROT270" : 0x06,
            "SPREVH" : 0x08,
            "SPREVV" : 0x10,
            "SPADD" : 0x20,

            "BGROT0" : 0x0000,
            "BGROT90" : 0x1000,
            "BGROT180" : 0x2000,
            "BGROT270" : 0x3000,
            "BGREVH" : 0x4000,
            "BGREVV" : 0x8000,

            "CHKXY" : 0x01,
            "CHKZ" : 0x02,
            "CHKUV" : 0x04,
            "CHKI" : 0x08,
            "CHKR" : 0x10,
            "CHKS" : 0x20,
            "CHKC" : 0x40,
            "CHKV" : 0x80,

            "BQAPF" : 0,
            "BQLPF" : 1,
            "BQHPF" : 2,
            "BQBPF" : 3,
            "BQBSF" : 4,
            "BQLSF" : 5,
            "BQHSF" : 6,
            "BQPEQ" : 7,

            "WFRECT" : 0,
            "WFHAMM" : 1,
            "WFHANN" : 2,
            "WFBLKM" : 3,

            "AOPADD" : 0,
            "AOPSUB" : 1,
            "AOPMUL" : 2,
            "AOPDIV" : 3,
            "AOPMAD" : 4,
            "AOPLIP" : 5,
            "AOPCLP" : 6,
        ];
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
    Test!"1+2+3+4*5/4-5+(6+6)*7";
}
