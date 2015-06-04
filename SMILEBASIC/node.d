module otya.smilebasic.node;
import otya.smilebasic.type;
import otya.smilebasic.token;
import std.container;

enum NodeType
{
    Node,
    Expression,
    Constant,
    BinaryOperator,
    Variable,
    CallFunction,
    VoidExpression,

    Statements,
    FunctionBody,
    Assign,
    CallFunctionStatement,
    Print,
}
abstract class Node
{
    NodeType type;
}
abstract class Expression : Node
{
}
class Constant : Expression
{
    Value value;
    this(Value v)
    {
        this.type = NodeType.Constant;
        this.value = v;
    }
}
class BinaryOperator : Expression
{
    Expression item1;
    TokenType operator;
    Expression item2;
    this(BinaryOperator bop)
    {
        this.type = NodeType.BinaryOperator;
        this.item1 = bop.item1;
        this.operator = bop.operator;
        this.item2 = bop.item2;
    }
    this(Expression i1)
    {
        this.type = NodeType.BinaryOperator;
        this.item1 = i1;
    }
    this(Expression i1, TokenType o, Expression i2)
    {
        this.type = NodeType.BinaryOperator;
        this.item1 = i1;
        this.operator = o;
        this.item2 = i2;
    }
}
class Variable : Expression
{
    wstring name;
    this(wstring n)
    {
        this.type = NodeType.Variable;
        this.name = n;
    }
}
class CallFunction : Expression
{
    wstring name;
    Expression[] args;
    this(wstring n)
    {
        this.type = NodeType.CallFunction;
        this.name = n;
        args = new Expression[0];
    }
    void addArg(Expression arg)
    {
        args ~= arg;
    }
}
class VoidExpression : Expression
{
    this()
    {
        this.type = NodeType.VoidExpression;
    }
}
abstract class Statement : Node
{
}
class Statements : Statement
{
    Statement[] statements;
    this()
    {
        this.type = NodeType.Statements;
        statements = new Statement[0];
    }
    void addStatement(Statement statement)
    {
        statements ~= statement;
    }
}

enum PrintArgumentType
{
    Expression,//exp
    Line,
    Tab,//,
}
/*
*;は基本無視
*/
struct PrintArgument
{
    PrintArgumentType type;
    Expression expression;
    this(PrintArgumentType type)
    {
        this.type = type;
        this.expression = null;
    }
    this(PrintArgumentType type, Expression expression)
    {
        this.type = type;
        this.expression = expression;
    }
}
/*
*PRINTは関数ではないしmkIIと違って必ず:がいる
*関数と違ってFUNC(,,,)のような記述はエラー
*と言っても3.2で上の記述もエラーになりうる
*/

class Print : Statement
{
    PrintArgument[] args;
    this()
    {
        this.type = NodeType.Print;
        args = new PrintArgument[0];
    }
    void addArgument(Expression expression)
    {
        args ~= PrintArgument(PrintArgumentType.Expression, expression);
    }
    void addTab()
    {
        args ~= PrintArgument(PrintArgumentType.Tab);
    }
    void addLine()
    {
        args ~= PrintArgument(PrintArgumentType.Line);
    }
}
