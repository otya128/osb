import std.stdio;
import otya.smilebasic.parser;
int main(string[] argv)
{
    writeln("Hello D-World!");
    auto parser = new Parser("1+2");
    writeln();
    writeln(parser.calc());
    readln();
    return 0;
}
