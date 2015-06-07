import std.stdio;
import otya.smilebasic.parser;
int main(string[] argv)
{
    version(none)
    {
        auto parser = new Parser("ADD(ADD(1,2,3,4,5,6),2,3,4,5,6)");
        writeln(parser.calc());
    }

    auto parser = new Parser(
//"@A\nA=1+2+3+4\nPRINT 1+1,2+3;10-5,A:A=A*2 PRINT A
"IF 1 THEN PRINT 2
IF 0 THEN PRINT 4 ELSE PRINT 5
IF 0 THEN
 PRINT 111
ELSE
 PRINT 222
ENDIF

FOR I=-2 TO -9 STEP -2
 PRINT I
NEXT
?I
");
    auto vm = parser.compile();
    vm.run();
    readln();
    return 0;
}
