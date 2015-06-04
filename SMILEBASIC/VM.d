module otya.smilebasic.vm;
class VM
{
}
enum CodeType
{
    PushI,
    PushD,
    PushS,
    Operate,
    Return,
    Goto,
    Gosub,
}
abstract class Code
{
    CodeType type;
    abstract void execute(VM vm);
}
/*
* スタックにPush
*/
class Push : Code
{

}
class Operate : Code
{

}
class Goto : Code
{

}
class Gosub : Code
{

}
