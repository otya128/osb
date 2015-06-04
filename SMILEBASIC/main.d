import std.stdio;
import otya.smilebasic.parser;
int main(string[] argv)
{
    writeln("Hello D-World!");
    version(none)
    {
        auto parser = new Parser("ADD(ADD(1,2,3,4,5,6),2,3,4,5,6)");
        writeln(parser.calc());
    }

    auto parser = new Parser("PRINT 1+1");
    parser.compile();
    readln();
    return 0;
}
