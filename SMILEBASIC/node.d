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
    Input,
    RepeatUntil,
    Option,
}
abstract class Node
{
    NodeType type;
    //式は複数行に渡って描けないのでStatementに置くべき
    SourceLocation location;
}
abstract class Expression : Node
{
}
class Constant : Expression
{
    Value value;
    this(Value v, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Constant;
        this.value = v;
    }
}
class BinaryOperator : Expression
{
    Expression item1;
    TokenType operator;
    Expression item2;
    this(BinaryOperator bop, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.BinaryOperator;
        this.item1 = bop.item1;
        this.operator = bop.operator;
        this.item2 = bop.item2;
    }
    this(Expression i1, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.BinaryOperator;
        this.item1 = i1;
    }
    this(Expression i1, TokenType o, Expression i2, SourceLocation loc)
    {
        super.location = loc;
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
    this(TokenType o, Expression i, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.UnaryOperator;
        this.operator = o;
        this.item = i;
    }
}
class Variable : Expression
{
    wstring name;
    this(wstring n, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Variable;
        this.name = n;
    }
}
class CallFunction : Expression
{
    wstring name;
    Expression[] args;
    this(wstring n, SourceLocation loc)
    {
        super.location = loc;
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
    this(SourceLocation loc)
    {
        super.location = loc;
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
    this(SourceLocation loc)
    {
        super.location = loc;
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
    this(SourceLocation loc)
    {
        super.location = loc;
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
    this(wstring name, Expression expr, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Assign;
        this.name = name;
        this.expression = expr;
    }
}
class Label : Statement
{
    wstring label;
    this(wstring name, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Label;
        this.label = name;
    }
}
class Goto : Statement
{
    wstring label;
    this(wstring name, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Goto;
        this.label = name;
    }
    Expression labelexpr;
    this(Expression expr, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Goto;
        this.labelexpr = expr;
    }
}
class If : Statement
{
    import std.typecons;
    Expression condition;
    Statements then;
    Statements else_;
    Tuple!(Statements, Expression)[] elseif;
    this(Expression condition, Statements t, Statements e, Tuple!(Statements, Expression)[] elif, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.If;
        this.condition = condition;
        this.then = t;
        this.else_ = e;
        this.elseif = elif;
    }
    bool hasElse()
    {
        return !(else_ is null) && else_.statements.length != 0;
    }
    bool hasElseif()
    {
        return !(elseif is null) && elseif.length != 0;
    }
}
class For : Statement
{
    Assign initExpression;
    Expression toExpression;
    Expression stepExpression;
    Statements statements;
    this(Assign assign, Expression toExpression, Expression stepExpression, Statements statements, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.For;
        this.initExpression = assign;
        this.toExpression = toExpression;
        this.stepExpression = stepExpression;
        this.statements = statements;
    }
    this(Assign assign, Expression toExpression, Statements statements, SourceLocation loc)
    {
        super.location = loc;
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
    this(wstring name, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Gosub;
        this.label = name;
    }
    Expression labelexpr;
    this(Expression expr, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Gosub;
        this.labelexpr = expr;
    }
}
class Return : Statement
{
    Expression expression;
    this(Expression expression, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Return;
        this.expression = expression;
    }
}
class End : Statement
{
    this(SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.End;
    }
}
class Break : Statement
{
    this(SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Break;
    }
}
class Continue : Statement
{
    this(SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Continue;
    }
}
class Var : Statement
{
    Statement[] define;
    this(SourceLocation loc)
    {
        super.location = loc;
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
    this(wstring name, Expression expr, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.DefineVariable;
        this.name = name;
        this.expression = expr;
    }
}
class DefineArray : Statement
{
    wstring name;
    IndexExpressions dim;
    this(wstring name, IndexExpressions dim, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.DefineArray;
        this.name = name;
        this.dim = dim;
    }
}
class IndexExpressions : Expression
{
    Expression[] expressions;
    this(SourceLocation loc)
    {
        super.location = loc;
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
    this(wstring name, IndexExpressions expr, Expression assign, SourceLocation loc)
    {
        super.location = loc;
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
    this(wstring name, bool returnExpr, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.DefineFunction;
        this.name = name;
        this.returnExpr = returnExpr;
    }
    this(wstring name, SourceLocation loc)
    {
        super.location = loc;
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
    Expression[] outVariable;
    this(wstring n, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.CallFunctionStatement;
        this.name = n;
        args = new Expression[0];
    }
    void addArg(Expression arg)
    {
        args ~= arg;
    }
    void addOut(Expression var)
    {
        outVariable ~= var;
    }
}
class While : Statement
{
    Expression condExpression;
    Statements statements;
    this(Expression condExpression, Statements statements, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.While;
        this.condExpression = condExpression;
        this.statements = statements;
    }
}
class Inc : Statement
{
    Expression name;
    Expression expression;
    this(Expression name, Expression expr, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Inc;
        this.name = name;
        this.expression = expr;
    }
}
class Data : Statement
{
    Value[] data;
    this(SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Data;
        this.data = new Value[0];
    }
    void addData(Value v)
    {
        data ~= v;
    }
}
class Read : Statement
{
    Expression[] variables;
    this(SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Read;
    }
    void addVariable(Expression lvalue)
    {
        variables ~= lvalue;
    }
}
class Restore : Statement
{
    Expression label;
    this(Expression label, SourceLocation loc)
    {
        super.location = loc;
        this.label = label;
        this.type = NodeType.Restore;
    }
}
class On : Statement
{
    Expression condition;
    bool isGosub;
    wstring[] labels;
    this(Expression expr, bool isgosub, SourceLocation loc)
    {
        super.location = loc;
        this.condition = expr;
        this.isGosub = isgosub;
        this.labels = new wstring[0];
        this.type = NodeType.On;
    }
    void addLabel(wstring label)
    {
        this.labels ~= label;
    }
}
class Input : Statement
{
    Expression message;
    bool question;
    Expression[] variables;
    this(Expression message, bool question, SourceLocation loc)
    {
        super.location = loc;
        this.message = message;
        this.question = question;
        this.variables = new Expression[0];
        this.type = NodeType.Input;
    }
    void addVariable(Expression lvalue)
    {
        variables ~= lvalue;
    }
}

class RepeatUntil : Statement
{
    Expression condExpression;
    Statements statements;
    this(Expression condExpression, Statements statements, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.RepeatUntil;
        this.condExpression = condExpression;
        this.statements = statements;
    }
}

class Option : Statement
{
    wstring argument;
    this(wstring arg, SourceLocation loc)
    {
        super.location = loc;
        this.type = NodeType.Option;
        argument = arg;
    }
}
