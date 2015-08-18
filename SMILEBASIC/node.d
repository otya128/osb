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
    UnaryOperator,
    IndexExpressions,

    Statements,
    FunctionBody,
    Assign,
    CallFunctionStatement,
    Print,
    Label,
    Goto,
    If,
    For,
    Gosub,
    Return,
    End,
    Break,
    Continue,
    Var,
    DefineVariable,
    DefineArray,
    ArrayAssign,
    DefineFunction,
    While,
    Inc,
    Data,
    Read,
    Restore,
    On,
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
class UnaryOperator : Expression
{
    TokenType operator;
    Expression item;
    this(TokenType o, Expression i)
    {
        this.type = NodeType.UnaryOperator;
        this.operator = o;
        this.item = i;
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
    static Statement NOP = null;
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
class Assign : Statement
{
    wstring name;
    Expression expression;
    this(wstring name, Expression expr)
    {
        this.type = NodeType.Assign;
        this.name = name;
        this.expression = expr;
    }
}
class Label : Statement
{
    wstring label;
    this(wstring name)
    {
        this.type = NodeType.Label;
        this.label = name;
    }
}
class Goto : Statement
{
    wstring label;
    this(wstring name)
    {
        this.type = NodeType.Goto;
        this.label = name;
    }
}
class If : Statement
{
    Expression condition;
    Statements then;
    Statements else_;
    this(Expression condition, Statements t, Statements e)
    {
        this.type = NodeType.If;
        this.condition = condition;
        this.then = t;
        this.else_ = e;
    }
    bool hasElse()
    {
        return !(else_ is null) && else_.statements.length != 0;
    }
}
class For : Statement
{
    Assign initExpression;
    Expression toExpression;
    Expression stepExpression;
    Statements statements;
    this(Assign assign, Expression toExpression, Expression stepExpression, Statements statements)
    {
        this.type = NodeType.For;
        this.initExpression = assign;
        this.toExpression = toExpression;
        this.stepExpression = stepExpression;
        this.statements = statements;
    }
    this(Assign assign, Expression toExpression, Statements statements)
    {
        this.type = NodeType.For;
        this.initExpression = assign;
        this.toExpression = toExpression;
        this.stepExpression = null;
        this.statements = statements;
    }
}
class Gosub : Statement
{
    wstring label;
    this(wstring name)
    {
        this.type = NodeType.Gosub;
        this.label = name;
    }
}
class Return : Statement
{
    Expression expression;
    this(Expression expression)
    {
        this.type = NodeType.Return;
        this.expression = expression;
    }
}
class End : Statement
{
    this()
    {
        this.type = NodeType.End;
    }
}
class Break : Statement
{
    this()
    {
        this.type = NodeType.Break;
    }
}
class Continue : Statement
{
    this()
    {
        this.type = NodeType.Continue;
    }
}
class Var : Statement
{
    Statement[] define;
    this()
    {
        this.type = NodeType.Var;
        this.define = new Statement[0];
    }
    void addDefineVar(DefineVariable dv)
    {
        this.define ~= dv;
    }
    void addDefineArray(DefineArray da)
    {
        this.define ~= da;
    }
}
class DefineVariable : Statement
{
    wstring name;
    Expression expression;
    this(wstring name, Expression expr)
    {
        this.type = NodeType.DefineVariable;
        this.name = name;
        this.expression = expr;
    }
}
class DefineArray : Statement
{
    wstring name;
    IndexExpressions dim;
    this(wstring name, IndexExpressions dim)
    {
        this.type = NodeType.DefineArray;
        this.name = name;
        this.dim = dim;
    }
}
class IndexExpressions : Expression
{
    Expression[] expressions;
    this()
    {
        this.type = NodeType.IndexExpressions;
        this.expressions = new Expression[0];
    }
    void addExpression(Expression expr)
    {
        this.expressions ~= expr;
    }
}
class ArrayAssign : Statement
{
    wstring name;
    IndexExpressions indexExpression;
    Expression assignExpression;
    this(wstring name, IndexExpressions expr, Expression assign)
    {
        this.type = NodeType.ArrayAssign;
        this.name = name;
        this.indexExpression = expr;
        this.assignExpression = assign;
    }
}
class DefineFunction : Statement
{
    wstring[] arguments;
    wstring[] outArguments;
    wstring name;
    Statements functionBody;
    bool returnExpr;
    this(wstring name, bool returnExpr)
    {
        this.type = NodeType.DefineFunction;
        this.name = name;
        this.returnExpr = returnExpr;
    }
    this(wstring name)
    {
        this.type = NodeType.DefineFunction;
        this.name = name;
        this.returnExpr = false;
    }
    void addArgument(wstring name)
    {
        this.arguments ~= name;
    }
    void addOutArgument(wstring name)
    {
        this.outArguments ~= name;
    }
}
class CallFunctionStatement : Statement
{
    wstring name;
    Expression[] args;
    wstring[] outVariable;
    this(wstring n)
    {
        this.type = NodeType.CallFunctionStatement;
        this.name = n;
        args = new Expression[0];
    }
    void addArg(Expression arg)
    {
        args ~= arg;
    }
    void addOut(wstring var)
    {
        outVariable ~= var;
    }
}
class While : Statement
{
    Expression condExpression;
    Statements statements;
    this(Expression condExpression, Statements statements)
    {
        this.type = NodeType.While;
        this.condExpression = condExpression;
        this.statements = statements;
    }
}
class Inc : Statement
{
    wstring name;
    Expression expression;
    this(wstring name, Expression expr)
    {
        this.type = NodeType.Inc;
        this.name = name;
        this.expression = expr;
    }
}
class Data : Statement
{
    Value[] data;
    this()
    {
        this.type = NodeType.Data;
        this.data = new Value[0];
    }
    void addData(Value v)
    {
        data ~= v;
    }
}
class On : Statement
{
    bool isGosub;
    wstring[] labels;
    this(bool isgosub)
    {
        this.isGosub = isgosub;
        this.labels = new wstring[0];
    }
    void addLabel(wstring label)
    {
        this.labels ~= label;
    }
}
