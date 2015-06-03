import std.stdio;
import otya.smilebasic.parser;
int main(string[] argv)
{
    writeln("Hello D-World!");
    auto parser = new Parser("ADD(ADD(1,2,3,4,5,6),2,3,4,5,6)");
    writeln(parser.calc());
    readln();
    return 0;
}
