import std.stdio;
import std.utf;
import std.conv;
import std.file;
import otya.smilebasic.parser;
import otya.smilebasic.error;
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
?\"Hello, World!!\"
?\"A\"*4
FOR I=0 TO 100
 IF I MOD 3==0 AND I MOD 5==0 THEN
  ?\"FIZZBUZZ\"
 ELSE
  IF I MOD 3==0 THEN
   ?\"FIZZ\"
  ELSE
   IF I MOD 5==0 THEN
    ?\"BUZZ\"
   ELSE
    ?I
   ENDIF
  ENDIF
 ENDIF
NEXT
?1 AND 1 OR 1 AND 0
?(1 OR 2 XOR 3)
?(1 OR 2 XOR 3 OR 4)
?@HELLOWORLD
FOR I=0 TO 10
 IF I==4 THEN BREAK
 IF I==1 THEN CONTINUE
 ?I
NEXT
VAR V[10]
?V[0]
?\"ABC\"[1][0]
GOSUB @A
END
@A
?\"SUBROUTINE TEST\"
RETURN
");
    version(none) auto parser = new Parser(readText("FIZZBUZZ.TXT").to!wstring);
    auto vm = parser.compile();
    try
    {
        vm.run();
    }
    catch(SmileBasicError sbe)
    {
        writeln(sbe);
    }
    readln();
    return 0;
}
