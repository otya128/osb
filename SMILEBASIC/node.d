module otya.smilebasic.node;
import otya.smilebasic.type;
import otya.smilebasic.token;
enum NodeType
{
    Node = 0b1,
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
        this.value = v;
    }
}
class BinaryOperator : Expression
{
    Expression item1;
    TokenType operator;
    Expression item2;
    this(Expression i1, TokenType o, Expression i2)
    {
        this.type = NodeType.BinaryOperator;
        this.item1 = i1;
        this.operator = o;
        this.item2 = i2;
    }
}
