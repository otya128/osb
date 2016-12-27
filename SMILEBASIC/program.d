module otya.smilebasic.program;
import std.range;
import std.container;
import std.algorithm;

struct Slot
{
    DList!wstring program;
    DList!wstring.Range range;
    this(T)(T)
    {
        program = make!(DList!wstring);
        range = program[];
    }

    void load(wstring data)
    {
        program.clear();
        foreach(l; splitter(data, "\n"))
        {
            program.insertBack(l ~ '\n');
        }
        if (program.back == "\n")
        {
            program.removeBack();
        }
        range = program[];
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
    void currentLine(int line)
    {
        if (line == -1)
        {
            //range = DList!wstring.Range(program._last);
            range = program[];
            while (!range.empty)
            {
                auto old = range.save;
                range.popFront();
                if (range.empty)
                {
                    range = old;
                    break;
                }
            }
            return;
        }
        range = program[];
        range.popFrontN(line - 1);
    }
    wstring get()
    {
        if (range.empty)
        {
            return "";
        }
        auto a = range.front;
        range.popFront();
        return a;
    }
    void set(wstring v)
    {
        int i;
        foreach(l; splitter(v, "\n"))
        {
            if (!range.empty && i == 0)
            {
                range.put(l ~ "\n");
            }
            else
            {
                if (range.empty)
                {
                    program.insertAfter(range, l ~ "\n");
                }
                else
                {
                    program.insertBefore(range, l ~ "\n");
                }
            }
            i++;
        }
    }
}

class Program
{
    Slot[] slot;
    int currentSlot;
    int slotSize = 4;
    this()
    {
        slot = new Slot[5];
        foreach(ref s; slot)
        {
            s = Slot(slot);
        }
    }
    void edit(int slot, int line)
    {
        this.currentSlot = slot;
        this.slot[slot].currentLine = line;
    }
    wstring get()
    {
        return this.slot[currentSlot].get;
    }
    void set(wstring v)
    {
        this.slot[currentSlot].set = v;
    }
}
