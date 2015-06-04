module otya.smilebasic.compiler;
import otya.smilebasic.node;
import otya.smilebasic.vm;
import std.stdio;
class Compiler
{
    Statements statements;
    this(Statements statements)
    {
        this.statements = statements;
    }

    void compile()
    {
        Code[] code = new Code[0];
        foreach(Statement i ; statements.statements)
        {
            switch(i.type)
            {
                default:
                    stderr.writeln("Compile:NotImpl ", i.type);
            }
        }
    }
}
