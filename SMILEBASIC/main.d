import std.stdio;
import std.utf;
import std.conv;
import std.file;
import otya.smilebasic.parser;
import otya.smilebasic.error;
import otya.smilebasic.petitcomputer;
import std.getopt;

int main(string[] argv)
{
    bool nodirectmode;
    string inputfile;
    auto helpInformation = getopt(argv, "no-direct-mode", &nodirectmode, "file", &inputfile);
    if (helpInformation.helpWanted)
    {
        defaultGetoptPrinter("Some information about the program.",
                             helpInformation.options);
        return 0;
    }
    //try
    {
        auto pc = new PetitComputer();
        pc.run(nodirectmode, inputfile);
    }
    /*(Throwable t)
    {
        writeln(std.windows.charset.toMBSz(t.to!string).to!string);
        readln();
    }*/
    return 0;
}
