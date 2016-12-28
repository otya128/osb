module otya.smilebasic.program;
import otya.smilebasic.error;
import std.range;
import std.container;
import std.algorithm;

unittest
{
    Slot slot;
    slot.init();
    slot.currentLine = 1;
    assert(slot.get() == "\n");
    slot.currentLine = 1;
    slot.set("1");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "1\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 2;
    slot.set("2");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "1\n");
    assert(slot.get() == "2\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    slot.set("A");
    assert(slot.get() == "2\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "A\n");
    assert(slot.get() == "2\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 2;
    slot.set("I\nJ");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");

    //PRGINS
    slot.currentLine = 1;
    slot.insert("3", false);
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "3\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");

    slot.currentLine = 1;
    slot.insert("4", true);
    assert(slot.get() == "4\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "3\n");
    assert(slot.get() == "4\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");

    slot.currentLine = 2;
    slot.insert("5", false);
    assert(slot.get() == "4\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "3\n");
    assert(slot.get() == "5\n");
    assert(slot.get() == "4\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");

    slot.currentLine = 2;
    slot.insert("6", true);
    assert(slot.get() == "6\n");
    assert(slot.get() == "4\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "3\n");
    assert(slot.get() == "5\n");
    assert(slot.get() == "6\n");
    assert(slot.get() == "4\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");

    //PRGDEL
    slot.currentLine = 1;
    slot.delete_(1);
    assert(slot.get() == "5\n");
    assert(slot.get() == "6\n");
    assert(slot.get() == "4\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "5\n");
    assert(slot.get() == "6\n");
    assert(slot.get() == "4\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 2;
    slot.delete_(2);
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "5\n");
    assert(slot.get() == "A\n");
    assert(slot.get() == "I\n");
    assert(slot.get() == "J\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");
    slot.delete_(-1);
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "\n");
    assert(slot.get() == "");

    slot.set("A");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "A\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");

    slot.delete_(1);
    slot.delete_(1);
    slot.delete_(1);
    slot.delete_(1);
    slot.currentLine = 1;
    slot.set("A");
    slot.set("B");
    slot.currentLine = 1;
    slot.set("A");
    slot.set("B");
    slot.currentLine = 1;
    assert(slot.get() == "A\n");
    assert(slot.get() == "B\n");
    assert(slot.get() == "\n");
    assert(slot.get() == "");

    assert(slot.size(SizeType.Line) == 3);
    slot.delete_(-1);
    assert(slot.size(SizeType.Line) == 0);

    slot.currentLine = 1;
    slot.set("A");
    slot.set("B");
    slot.delete_(1);
    assert(slot.get() == "B\n");
    assert(slot.get() == "");
    slot.currentLine = -1;
    assert(slot.get() == "B\n");
    assert(slot.get() == "");
    slot.currentLine = 1;
    assert(slot.get() == "A\n");
    assert(slot.get() == "B\n");
    assert(slot.get() == "");
    slot.currentLine = 2;
    slot.delete_(1);
    assert(slot.get() == "A\n");
    assert(slot.get() == "");

}

enum SizeType
{
    Line = 0,
    Char = 1,
    FreeChar = 2,
}

struct Slot
{
    private DList!wstring program;
    private DList!wstring.Range range;
    private DList!wstring.Range range2;
    wstring name;
    void init()
    {
        program = make!(DList!wstring)(["\n"w]);
        range = program[];
    }

    void load(wstring filename, wstring data)
    {
        name = filename;
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
        range2 = range.save;
        range.popFrontN(line - 1);
    }
    wstring get()
    {
        if (range.empty)
        {
            return "";
        }
        auto a = range.front;
        range2 = range.save;
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
                auto b = range.save;
                b.popFront();
                if (b.empty)
                {
                    program.insertBefore(range, l ~ "\n");
                }
                else
                {
                    range2 = range.save;
                    range.put(l ~ "\n");
                }
            }
            else
            {
                if (range.empty)
                {
                    if (!range2.empty)
                    {
                        range = range2;
                        program.insertBefore(range, l ~ "\n");
                        range2 = range.save;
                        range.popFront();
                        continue;
                    }
                    program.insertBefore(range, l ~ "\n");
                }
                else
                {
                    program.insertBefore(range, l ~ "\n");
                }
            }
            i++;
        }
    }
    void insert(wstring line, bool isBack)
    {
        typeof(range) backup;
        if (isBack)
        {
            backup = range.save;
            range.popFront();
        }
        foreach(l; splitter(line, "\n"))
        {
            if (isBack)
            {
                //backup = range.save;
                program.insertBefore(range, l ~ "\n");
            }
            else
            {
                program.insertBefore(range, l ~ "\n");
            }
        }
        if (isBack)
        {
            range = backup;
            range.popFront();
        }
        range2 = range.save;
    }
    void delete_(int count)
    {
        if (count < 0)
        {
            init();
            range.popFront();
        }
        else
        {
            if (range.empty)
            {
                for (int i = 0; i < count;i++)
                {
                    program.removeBack();
                }
            }
            else
            {
                range = program.linearRemove(range.take(count));
            }
            if (range.empty)
            {
                range = program[];
                if (range.empty)
                {
                    program.insertAfter(range, "\n"w);
                    range = program[];
                }
                else
                {
                    currentLine = -1;
                }
            }
        }
        range2 = range.save;
    }
    int memorySize = 1048476;//WiiU..?
    int size(SizeType type)
    {
        switch(type)
        {
            case SizeType.Line:
                {
                    auto a = cast(int)program[].walkLength;
                    if (a == 1 && program.front.length == 1 && program.front[0] == '\n'/*?*/)
                        return 0;
                    return a;
                }
            case SizeType.Char:
                return cast(int)program[].map!(x => x.length).sum;
            case SizeType.FreeChar:
                return cast(int)(memorySize - program[].map!(x => x.length).sum).max(0);
            default:
                throw new OutOfRange("PRGSIZE", 2);
        }
    }
}

class Program
{
    Slot[] slot;
    bool PRGEDITused;
    int currentSlot;
    int slotSize = 4;
    this()
    {
        slot = new Slot[5];
        foreach(ref s; slot)
        {
            s.init();
        }
    }
    void edit(int slot, int line)
    {
        PRGEDITused = true;
        this.currentSlot = slot;
        this.slot[slot].currentLine = line;
    }
    wstring get()
    {
        if (!PRGEDITused)
            throw new UsePRGEDITBeforeAnyPRGFunction("PRGGET$");
        return this.slot[currentSlot].get;
    }
    void set(wstring v)
    {
        if (!PRGEDITused)
            throw new UsePRGEDITBeforeAnyPRGFunction("PRGSET");
        this.slot[currentSlot].set = v;
    }
    void insert(wstring line, bool isBack)
    {
        if (!PRGEDITused)
            throw new UsePRGEDITBeforeAnyPRGFunction("PRGINS");
        this.slot[currentSlot].insert(line, isBack);
    }
    void delete_(int count)
    {
        if (!PRGEDITused)
            throw new UsePRGEDITBeforeAnyPRGFunction("PRGDEL");
        this.slot[currentSlot].delete_(count);
    }
    int size(int slot, SizeType st)
    {
        return this.slot[slot].size(st);
    }
    wstring name(int slot)
    {
        return this.slot[slot].name;
    }
}
