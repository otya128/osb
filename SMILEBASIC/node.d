module otya.smilebasic.node;
import otya.smilebasic.type;
import otya.smilebasic.token;
enum NodeType
{
    Node,
    Expression,
    Constant,
    BinaryOperator,
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
