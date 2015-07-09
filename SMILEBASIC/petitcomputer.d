module otya.smilebasic.petitcomputer;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import std.net.curl;
import std.file;
import std.stdio;
import std.conv;
import std.string;
import std.c.stdio;
import otya.smilebasic.parser;
class GraphicPage
{
    SDL_Surface* surface;
    SDL_Texture* texture;
    this(SDL_Surface* s)
    {
        surface = s;
    }
    void createTexture(SDL_Renderer* renderer)
    {
        texture = SDL_CreateTextureFromSurface(renderer, surface);
    }
}
class PetitComputer
{
    this()
    {
        new Test();
    }
    static const string resourceDirName = "resources";
    static const string resourcePath = "./resources";
    static const string fontFile = resourcePath ~ "/font.png";
    static const string spriteFile = resourcePath ~ "/defsp.png";
    static const string BGFile = resourcePath ~ "/defbg.png";
    static const string fontTableFile = resourcePath ~ "/fonttable.txt";
    int screenWidth;
    int screenHeight;
    int fontWidth;
    int fontHeight;
    int consoleWidth;
    int consoleHeight;
    wchar[][] console;
    GraphicPage[] grp;
    GraphicPage GRPF;
    //PNG画像から透過色のpixelを指定して透過しGRPを作る
    GraphicPage createGraphicPage(string file, int pixel)
    {
        SDL_RWops* stream = SDL_RWFromFile(toStringz(file), toStringz("rb"));
        auto surfacesrc = IMG_LoadPNG_RW(stream);
        SDL_Surface* surface = SDL_CreateRGBSurface(0, surfacesrc.w, surfacesrc.h, 32, 0, 0, 0, 0);
        SDL_Rect rect;
        rect.x = 0;
        rect.y = 0;
        rect.w = surfacesrc.w;
        rect.h = surfacesrc.h;
        int i = SDL_BlitSurface(surfacesrc, &rect, surface, &rect);
        SDL_SetColorKey(surface, SDL_TRUE, (cast(uint*)surface.pixels)[pixel]);
        auto grp = new GraphicPage(surface);
        SDL_FreeSurface(surfacesrc);
        SDL_RWclose(stream);
        return grp;
    }
    struct Point
    {
        int x, y;
        this(int x, int y)
        {
            this.x = x;
            this.y = y;
        }
    }
    SDL_Rect[] fontTable = new SDL_Rect[65536];
    void createFontTable()
    {
        string html = cast(string)get("http://smileboom.com/special/ptcm3/download/unicode/");
        int pos = 0, index;
        auto file = File(fontTableFile, "w");
        std.algorithm.fill(fontTable, SDL_Rect(488,120, 8, 8));//TODO:480,120とどっちが使われているかは要調査
        while(true)
        {
            pos = html.indexOf("<tr><th>U+");
            if(pos == -1) break;
            pos += "<tr><th>U+".length;
            html = html[pos..$];
            writeln(index = html.parse!int(16));
            file.write(index, ',');
            pos = html.indexOf("</td><td>(");
            if(pos == -1) break;
            pos += "</td><td>(".length;
            html = html[pos..$];
            writeln(fontTable[index].x = html.parse!int);
            file.write(fontTable[index].x, ',');
            pos = html.indexOf(',');
            html = html[pos + 1..$];
            munch(html, " ");
            writeln(fontTable[index].y = html.parse!int);
            file.write(fontTable[index].y, '\n');
            fontTable[index].w = 8;
            fontTable[index].h = 8;
        }
    }
    void loadFontTable()
    {
        import std.csv;
        import std.typecons;
        std.algorithm.fill(fontTable, SDL_Rect(488,120, 8, 8));//TODO:480,120とどっちが使われているかは要調査
        auto csv = csvReader!(Tuple!(int,int,int))(readText(fontTableFile));
        foreach(record; csv)
        {
            fontTable[record[0]].x = record[1];
            fontTable[record[0]].y = record[2];
            fontTable[record[0]].w = 8;
            fontTable[record[0]].h = 8;
        }
    }
    void init()
    {
        DerelictSDL2.load();
        DerelictSDL2Image.load();
        if(!exists(resourcePath))
        {
            writeln("create ./resources");
            mkdir(resourceDirName);
        }
        if(!exists(fontFile))
        {
            writeln("download font");
            download("http://smileboom.com/special/ptcm3/download/unicode/image/res_font_table-320.png",
                     fontFile);
        }
        GRPF = createGraphicPage(fontFile, 0);
        if(!exists(spriteFile))
        {
            writeln("download sprite");
            download("http://smileboom.com/special/ptcm3/image/ss-story-attachment-1.png",
                     spriteFile);
        }
        if(!exists(BGFile))
        {
            writeln("download BG");
            download("http://smileboom.com/special/ptcm3/image/ss-story-attachment-2.png",
                     BGFile);
        }
        if(!exists(fontTableFile))
        {
            writeln("create font table");
            //HTMLなんて解析したくないから適当
            createFontTable();
        }
        else
        {
            loadFontTable();
        }
        writeln("OK");
        screenWidth = 400;
        screenHeight = 240;
        fontWidth = 8;
        fontHeight = 8;
        consoleWidth = screenWidth / fontWidth;
        consoleHeight = screenHeight / fontHeight;
        console = new wchar[][consoleHeight];
        for(int i = 0; i < console.length; i++)
        {
            console[i] = new wchar[consoleWidth];
            for(int j = 0; j < console[i].length; j++)
                console[i][j] = '\0';
        }
    }
    SDL_Renderer* renderer;
    void run()
    {
        init();
        SDL_Init(SDL_INIT_VIDEO);
        SDL_Window* window = SDL_CreateWindow("SMILEBASIC", SDL_WINDOWPOS_UNDEFINED,
                                              SDL_WINDOWPOS_UNDEFINED, 400, 240,
                                              SDL_WINDOW_SHOWN);
        renderer = SDL_CreateRenderer(window, -1, 0);
        GRPF.createTexture(renderer);
        //とりあえず
        auto parser = new Parser(/*readText("FIZZBUZZ.TXT").to!wstring*/"

FOR I=0 TO 10
 ?I;\"!\",\"=\",FACT(I)
NEXT
DEF FACT(N)
 IF N<=1 THEN RETURN 1
 RETURN N*FACT(N-1)
END");
        auto vm = parser.compile();
        bool running = true;
        vm.init(this);
        while (true)
        {
            auto startTicks = SDL_GetTicks();
            uint elapse;
            do
            {
                try
                {
                    if(running) running = vm.runStep();
                }
                catch(SmileBasicError sbe)
                {
                    running = false;
                    try
                    {
                        printConsole(sbe.to!string);
                    }
                    catch
                    {
                    }
                }
                catch(Throwable t)
                {
                    running = false;
                    try
                    {
                        printConsole(t.to!string);
                    }
                    catch
                    {
                    }
                }
                elapse = SDL_GetTicks() - startTicks;
            } while(elapse <= 1000 / 60);
            SDL_Event event;
            SDL_SetRenderDrawColor(renderer, 0, 0, 0, 255);
            SDL_RenderClear(renderer);
            renderConsole;
            SDL_RenderPresent(renderer);
            while (SDL_PollEvent(&event))
            {
                switch (event.type)
                {
                    case SDL_QUIT:
                        SDL_DestroyWindow(window);
                        SDL_Quit();
                        return;

                    default:
                        break;
                }
            }
        }
        SDL_DestroyWindow(window);
        SDL_Quit();
    }
    int CSRX;
    int CSRY;
    int CSRZ;
    void renderConsole()
    {
        for(int y = 0; y < consoleHeight; y++)
            for(int x = 0; x < consoleWidth; x++)
            {
                SDL_Rect rect = SDL_Rect(x * 8, y * 8, 8, 8);
                SDL_RenderCopy(renderer, GRPF.texture, &fontTable[console[y][x]], &rect);
            }
    }
    void printConsole(T...)(T args)
    {
        foreach(i; args)
        {
            printConsoleString(i.to!wstring);
        }
    }
    void printConsoleString(wstring text)
    {
        foreach(wchar c; text)
        {
            if(CSRY >= consoleHeight)
            {
                CSRY = consoleHeight - 1;
            }
            if(c != '\r' && c != '\n')
            {
                console[CSRY][CSRX] = c;
            }
            CSRX++;
            if(CSRX >= consoleWidth || c == '\n' || c == '\r')
            {
                CSRX = 0;
                CSRY++;
            }
            if(CSRY >= consoleHeight)
            {
                auto tmp = console[0];
                for(int i = 0; i < consoleHeight - 1; i++)
                {
                    console[i] = console[i + 1];
                }
                console[consoleHeight - 1] = tmp;
                for(int j = 0; j < tmp.length; j++)
                    tmp[j] = '\0';
                assert(console[0] != console[2]);
                CSRY = consoleHeight - 1;
            }
        }
    }
}
import std.typecons;
import std.typetuple;
import std.traits;
import otya.smilebasic.error;
import otya.smilebasic.type;
static string func;
class Test
{
    import otya.smilebasic.type;
    int a;/*
    static Value abs(Value[] a)
    {
        return Value((a[0].castDouble < 0 ? -a[0].castDouble : a[0].castDouble));
    }*/
    static double ABS(double a)
    {
        return a < 0 ? -a : a;
    }
    wstring[] ah;
    void*[] ahe;
    alias void function(Value[], Value[]) BuiltinFunc;
    BuiltinFunc[] builtinFunctions;
    this()
    {
        foreach(name; __traits(derivedMembers, Test))
        {
            //writeln(name);
            ah ~= name;
            // foreach (t; __traits(getVirtualFunctions, Test, name))
            {
                static if(__traits(isStaticFunction, __traits(getMember, Test, name)))
                {
                    ahe ~= cast(void*)&__traits(getMember, Test, name);
                    writeln(name);
                    auto m = typeid(typeof(__traits(getMember, Test, name)));
                    writeln(m);
                    writeln(AddFunc!(Test,name));
                    builtinFunctions ~= mixin(AddFunc!(Test,name));
                }
            }
        }
    }

}
template AddFunc(T, string N)
{
    static if(is(ReturnType!(__traits(getMember, T, N)) == double))
    {
       const string AddFunc = "function void(Value[] arg, Value[] ret){if(ret.length != 1){throw new IllegalFunctionCall();}ret[0] = Value(" ~ N ~ "(" ~
           AddFuncArg!(Tuple!(ParameterTypeTuple!(__traits(getMember, T, N))), 0) ~ "));}";
    }
    else
    {
        const string AddFunc = "";
    }
}
template AddFuncArg(P, int N = 0)
{
    static if(is(typeof(P[N]) == double))
    {
        const string arg = "arg[" ~ N.to!string ~ "].castDouble";
    }
    else
    {
        const string arg = "";
        static assert(false, "Invalid type");
    }
    static if(N + 1 == P.length)
    {
        const string AddFuncArg = arg;
    }
    else
    {
        const string AddFuncArg = arg ~ ", " ~ AddFuncArg!(P, N + 1);
    }
}
