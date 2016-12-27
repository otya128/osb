module otya.smilebasic.program;
import std.container;

struct Slot
{
    DList!wstring program;
    void load(wstring data)
    {
        import std.algorithm;
        program.clear();
        foreach(l; splitter(data, "\n"))
        {
            program.insertBack(l ~ '\n');
        }
    }
    wchar[] text()
    {
        import std.algorithm.iteration, std.outbuffer;
        auto buffer = new OutBuffer();
        buffer.reserve(program.opSlice.map!"(a.length + 1) * 2".sum);

        foreach(line; program)
        {
            buffer.write(line);
        }
        ubyte[] progbuff = buffer.toBytes;
        wchar[] progbuff2 = (cast(wchar*)progbuff.ptr)[0..progbuff.length / 2];
        return progbuff2;
    }
    import otya.smilebasic.token;
    wstring getLine(SourceLocation loc)
    {
        import std.string;
        int i;
        foreach (line; program)
        {
            i++;
            if (i == loc.line)
                return line;
        }
        return "";
    }
}

class Program
{
    Slot[] slot;
    int currentSlot;
    int currentLine = 1;
    int slotSize = 4;
    this()
    {
        slot = new Slot[5];
    }
}
