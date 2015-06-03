import std.stdio;
import otya.smilebasic.parser;
int main(string[] argv)
{
    writeln("Hello D-World!");
    auto parser = new Parser("1+2*3+4");
    writeln(parser.calc());
    writeln(1+2*3+4);
    readln();
    return 0;
}
