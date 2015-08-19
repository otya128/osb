module otya.smilebasic.petitcomputer;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl;
import std.net.curl;
import std.file;
import std.stdio;
import std.conv;
import std.string;
import std.c.stdio;
import core.sync.mutex;
import otya.smilebasic.parser;
class GraphicPage
{
    static GLenum textureScaleMode = GL_NEAREST;
    SDL_Surface* surface;
    this(SDL_Surface* s)
    {
        surface = s;
    }
    GLuint glTexture;
    void createTexture(SDL_Renderer* renderer)
    {
        ubyte r,g,b,a;
        SDL_GetRGBA(*cast(uint*)surface.pixels, surface.format, &r, &g, &b, &a);
        GLenum texture_format;
        GLint  nOfColors;
        nOfColors = surface.format.BytesPerPixel;
        if (nOfColors == 4)     // contains an alpha channel
        {
            if (surface.format.Rmask == 0x000000ff)
                texture_format = GL_RGBA;
            else
                texture_format = GL_BGRA;
        } else if (nOfColors == 3)     // no alpha channel
        {
            if (surface.format.Rmask == 0x000000ff)
                texture_format = GL_RGB;
            else
                texture_format = GL_BGR;
        } else {
            //printf("warning: the image is not truecolor..  this will probably break\n");
            // this error should not go unhandled
        }
        // Have OpenGL generate a texture object handle for us
        glGenTextures( 1, &glTexture );
        // Bind the texture object
        glBindTexture( GL_TEXTURE_2D, glTexture );
        // Set the texture's stretching properties
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, textureScaleMode );
        glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, textureScaleMode );

        // Edit the texture object's image data using the information SDL_Surface gives us
        glTexImage2D( GL_TEXTURE_2D, 0, nOfColors, surface.w, surface.h, 0,
                      texture_format, GL_UNSIGNED_BYTE, surface.pixels );
    }
}
version(Windows)
{
    extern (Windows) static void* LoadLibraryA(in char*);
    extern (Windows) static bool FreeLibrary(void*);
    extern (Windows) static void* GetProcAddress(void*, in char*);
    alias extern (Windows) void* function(void*, void*) ImmAssociateContext;
    alias extern (Windows) int function(int) ImmDisableIME;
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
    int[] consoleColor = 
    [
        0x00000000,
        0xFF000000,
        0xFF7F0000,
        0xFFFF0000,
        0xFF007F00,
        0xFF00FF00,
        0xFF7F7F00,
        0xFFFFFF00,
        0xFF00007F,
        0xFF0000FF,
        0xFF7F007F,
        0xFFFF00FF,
        0xFF007F7F,
        0xFF00FFFF,
        0xFF7F7F7F,
        0xFFFFFFFF,
    ];
    int[] consoleColorGL = new int[16];
    uint toGLColor(uint color)
    {
        //ARGB -> ABGR
        return (color & 0xFF00FF00) | (color >> 16 & 0xFF) | ((color & 0xFF) << 16);
    }
    struct ConsoleCharacter
    {
        wchar charater;
        int foreColor;
        int backColor;
        byte attr;
    }
    SDL_Color PetitColor(byte r, byte g, byte b, byte a)
    {
        return SDL_Color(r >> 5 << 5, g >> 5 << 5, b >> 5 << 5, a == 255 ? 255 : 0);
    }
    ConsoleCharacter[][] console;
    GraphicPage[] grp;
    GraphicPage GRPF;
    GraphicPage[] GRPFColor;
    GraphicPage[][] GRPFColorFore;
    SDL_Surface* s8x8;
    SDL_Texture* t8x8;
    SDL_Surface* createSurfaceFromFile(string file)
    {
        SDL_RWops* stream = SDL_RWFromFile(toStringz(file), toStringz("rb"));
        auto surfacesrc = IMG_LoadPNG_RW(stream);
        SDL_RWclose(stream);
        return surfacesrc;
    }
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
        SDL_SetColorKey(surfacesrc, SDL_TRUE, (cast(uint*)surface.pixels)[pixel]);
        int i = SDL_BlitSurface(surfacesrc, &rect, surface, &rect);
        auto grp = new GraphicPage(surface);
        SDL_FreeSurface(surfacesrc);
        SDL_RWclose(stream);
        return grp;
    }
    GraphicPage createGRPF(string file)
    {
        SDL_RWops* stream = SDL_RWFromFile(toStringz(file), toStringz("rb"));
        auto src = IMG_LoadPNG_RW(stream);
        SDL_Surface* surface = SDL_CreateRGBSurface(0, src.w, src.h, 32, 0xff000000, 0x00ff0000, 0x0000ff00,  0xFF);
        SDL_Rect rect;
        rect.x = 0;
        rect.y = 0;
        rect.w = src.w;
        rect.h = src.h;
//        SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_BLEND);
//        SDL_SetSurfaceBlendMode(src, SDL_BLENDMODE_BLEND);
        SDL_SetColorKey(src, SDL_TRUE, (cast(uint*)src.pixels)[0]);
        SDL_SetColorKey(surface, SDL_TRUE, (cast(uint*)src.pixels)[0]);
        int i = SDL_BlitSurface(src, &rect, surface, &rect);
        auto srcpixels = (cast(uint*)src.pixels);
        auto pixels = (cast(uint*)surface.pixels);
        auto aaa = surface.format.Amask;
        //surface.format.Amask = 0xFF;
        /+for(int x = 0; x < src.w; x++)
        {
            for(int y = 0; y < src.h; y++)
            {
                ubyte r, g, b, a;
                write(x,y, ',');
                SDL_GetRGBA(*pixels, surface.format, &r, &g, &b, &a);
                if(r == 158 && g == 0 && b == 93)
                {
                    r = 0;
                    g = 0;
                    b = 0;
                    a = 0;
                    *pixels = 0;
                    *pixels = SDL_MapRGBA(surface.format, r, g, b, a);
                }/+
                else
                    *pixels = SDL_MapRGBA(surface.format, r, g, b, a);
                +/ubyte _r, _g, _b, _a;
                SDL_GetRGBA(*pixels, surface.format, &_r, &_g, &_b, &_a);
                pixels++;
            }
        }+/
        SDL_RWclose(stream);
        SDL_FreeSurface(src);
        return new GraphicPage(surface);
    }
    GraphicPage createGRPF(int color, SDL_Surface *src)
    {
        SDL_Surface* surface = SDL_CreateRGBSurface(0, src.w, src.h, 32, 0, 0, 0, 0);
        auto srcpixels = (cast(uint*)src.pixels);
        auto pixels = (cast(uint*)surface.pixels);
        for(int x = 0; x < src.w; x++)
        {
            for(int y = 0; y < src.h; y++)
            {
                ubyte r, g, b, a;
                SDL_GetRGBA(*srcpixels, src.format, &r, &g, &b, &a);
                //if(a == 0)
                {
                    auto back = consoleColor[color];
                    r = back >> 16 & 0xFF;
                    g = back >> 8 & 0xFF;
                    b = back & 0xFF;
                    a = back >> 24 & 0xFF;
                }
                *pixels = SDL_MapRGBA(surface.format, r, g, b, a);
                pixels++;
                srcpixels++;
            }
        }
        return new GraphicPage(surface);
    }
    GraphicPage createGRPF(int color, int colorFore, SDL_Surface *src)
    {
        SDL_Surface* surface = SDL_CreateRGBSurface(0, src.w, src.h, 32, 0, 0, 0, 0);
        auto srcpixels = (cast(uint*)src.pixels);
        auto pixels = (cast(uint*)surface.pixels);
        for(int x = 0; x < src.w; x++)
        {
            for(int y = 0; y < src.h; y++)
            {
                ubyte r, g, b, a;
                SDL_GetRGBA(*srcpixels, src.format, &r, &g, &b, &a);
                if(r == 158 && g == 0 && b == 93 && a == 255)
                {
                    auto back = consoleColor[color];
                    r = back >> 16 & 0xFF;
                    g = back >> 8 & 0xFF;
                    b = back & 0xFF;
                    a = back >> 24 & 0xFF;
                }
                else
                {
                    //雑
                    auto fore = consoleColor[colorFore];
                    r = fore >> 16 & 0xFF;
                    g = fore >> 8 & 0xFF;
                    b = fore & 0xFF;
                    a = fore >> 24 & 0xFF;
                }
                *pixels = SDL_MapRGBA(surface.format, r, g, b, a);
                pixels++;
                srcpixels++;
            }
        }
        return new GraphicPage(surface);
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
        DerelictGL.load();
        for(int i = 0; i < consoleColor.length; i++)
            consoleColorGL[i] = toGLColor(consoleColor[i]);
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
        GRPF = createGRPF(fontFile);//createGraphicPage(fontFile, 0);
        s8x8 = SDL_CreateRGBSurface(0, 8, 8, 32, 0, 0, 0, 0);
        auto pixels = (cast(uint*)s8x8.pixels);
        for(int x = 0; x < 8; x++)
        {
            for(int y = 0; y < 8; y++)
            {
                *pixels = SDL_MapRGBA(s8x8.format, 255, 255, 255, 255);
                pixels++;
            }
        }
        //GRPFColor = new GraphicPage[consoleColor.length];
        //GRPFColorFore = new GraphicPage[][consoleColor.length];
        //for(int i = 0; i < GRPFColor.length; i++)
        //{
        //    GRPFColor[i] = createGRPF(i, GRPF.surface);
        //}
        /+for(int i = 0; i < GRPFColor.length; i++)
        {
            GRPFColorFore[i] = new GraphicPage[consoleColor.length];
            for(int j = 0; j < GRPFColor.length; j++)
            {
                GRPFColorFore[i][j] = createGRPF(i, j, GRPF.surface);
            }
        }+/
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
        console = new ConsoleCharacter[][consoleHeight];
        consoleForeColor = 15;//#T_WHITE
        for(int i = 0; i < console.length; i++)
        {
            console[i] = new ConsoleCharacter[consoleWidth];
            console[i][] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
        }
    }
    void cls()
    {
        for(int i = 0; i < console.length; i++)
        {
            console[i][] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
        }
    }
    SDL_Renderer* renderer;
    int vsyncFrame;
    int vsyncCount;
    void vsync(int f)
    {
        vsyncCount = 0;
        vsyncFrame = f;
    }
    Mutex keybuffermutex;
    int keybufferpos;
    int keybufferlen;
    //解析した結果キー入力のバッファは127くらい
    wchar[] keybuffer = new wchar[128];
    void sendKey(wchar key)
    {
        keybuffer[keybufferpos] = cast(wchar)key;
        keybufferlen++;
        if(keybufferlen > keybuffer.length)
            keybufferlen = keybuffer.length;
        keybufferpos = (keybufferpos + 1) % keybuffer.length;
    }
    void render()
    {
        bool renderprofile;
        try
        {
            version(Windows)
            {
                auto imm32 = LoadLibraryA("imm32.dll".toStringz);
                ImmDisableIME ImmDisableIME = cast(ImmDisableIME)GetProcAddress(imm32, "ImmDisableIME".toStringz);
                ImmDisableIME(0);
            }
            SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
            window = SDL_CreateWindow("SMILEBASIC", SDL_WINDOWPOS_UNDEFINED,
                                      SDL_WINDOWPOS_UNDEFINED, 400, 240,
                                      SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);
            renderer = SDL_CreateRenderer(window, -1, 0);
            SDL_Event event;
            SDL_GLContext context;
            context = SDL_GL_CreateContext(window);
            if (!context) return;
            GRPF.createTexture(renderer);
            glViewport(0, 0, 400, 240);
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
            glEnable(GL_DEPTH_TEST);
            version(Windows)
            {
                SDL_SysWMinfo wm;
                if(SDL_GetWindowWMInfo(window, &wm))
                {
                    ImmAssociateContext ImmAssociateContext = cast(ImmAssociateContext)GetProcAddress(imm32, "ImmAssociateContext".toStringz);
                    auto aa = wm.info.win.window;
                    auto c = ImmAssociateContext(wm.info.win.window, null);
                }
            }
            int loopcnt;
            while(true)
            {
                auto profile = SDL_GetTicks();
                if(showCursor)
                {
                    loopcnt++;
                    //30フレームに一回
                    if(loopcnt >= 30)
                    {
                        animationCursor = !animationCursor;
                        loopcnt = 0;
                    }
                }
                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
                renderConsoleGL();
                SDL_GL_SwapWindow(window);
                auto renderticks = (SDL_GetTicks() - profile);
                if(renderprofile) writeln(renderticks);
                while (SDL_PollEvent(&event))
                {
                    switch (event.type)
                    {
                        case SDL_QUIT:
                            SDL_DestroyWindow(window);
                            SDL_Quit();
                            return;
                        case SDL_KEYDOWN:
                            auto key = event.key.keysym.sym;
                            if(key == SDLK_BACKSPACE)
                            {
                                keybuffermutex.lock();
                                sendKey('\u0008');
                                keybuffermutex.unlock();
                            }
                            if(key == SDLK_RETURN)
                            {
                                keybuffermutex.lock();
                                sendKey('\u000D');
                                keybuffermutex.unlock();
                            }
                            break;
                        case SDL_TEXTINPUT:
                            auto text = event.text.text[0..event.text.text.indexOf('\0')].to!wstring;
                            keybuffermutex.lock();
                            foreach(wchar key; text)
                            {
                                sendKey(key);
                            }
                            keybuffermutex.unlock();
                            break;
                        default:
                            break;
                    }
                }
                long delay = (1000/60) - cast(long)(SDL_GetTicks() - profile);
                if(delay > 0)
                    SDL_Delay(cast(uint)delay);
            }
        }
        catch(Throwable t)
        {
            writeln(t);
        }
    }
    SDL_Window* window;
    void run()
    {
        init();
        SDL_Init(SDL_INIT_VIDEO);
        /+for(int i = 0; i < GRPFColor.length; i++)
        {
            for(int j = 0; j < GRPFColor.length; j++)
            {
                GRPFColorFore[i][j].createTexture(renderer);
            }
        }+/
        //とりあえず
        auto parser = new Parser(//readText("./SYS/EX1TEXT.TXT").to!wstring
                                 //readText("FIZZBUZZ.TXT").to!wstring
                                 readText("TEST.TXT").to!wstring
/*"?ABS(-1)
LOCATE 0,10
COLOR 5
FOR I=0 TO 10
 ?I;\"!\",\"=\",FACT(I)
NEXT
DEF FACT(N)
 IF N<=1 THEN RETURN 1
 RETURN N*FACT(N-1)
END"*/
/*
`CLS : CL=0 : Z=0
WHILE 1
  INC Z : IF Z>200 THEN Z=0
  FOR I=0 TO 15
    LOCATE 9,4+I,Z : COLOR (CL+I) MOD 16
    PRINT "★ 梅雨で雨が多い季節ですね ★"
  NEXT
  CL=(CL+1) MOD 16 
WEND`*/
/*
`CLS : CL=0
WHILE 1
FOR I=0 TO 15
  LOCATE 9,4+I : COLOR (CL+I) MOD 16
  PRINT "Ё プチコン3ゴウ Ж"
NEXT
CL=(CL+1) MOD 16 : VSYNC 1
WEND`
/*
`CLS : CL=0
@LOOP
FOR I=0 TO 15
  LOCATE 9,4+I : COLOR (CL+I) MOD 16
  PRINT "Ё プチコン3ゴウ Ж"
NEXT
CL=(CL+1) MOD 16 : VSYNC 1
GOTO @LOOP`*/
);
        auto vm = parser.compile();
        bool running = true;
        vm.init(this);
        consolem = new Mutex();
        keybuffermutex = new Mutex();
        core.thread.Thread thread = new core.thread.Thread(&render);
        thread.start();
        auto startTicks = SDL_GetTicks();
        while (true)
        {
            uint elapse;
            startTicks = SDL_GetTicks();
            do
            {
                try
                {
                    if(!vsyncFrame && running) running = vm.runStep();
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
            vsyncCount++;
            if(vsyncFrame <= vsyncCount) vsyncFrame = 0;
        }
        SDL_DestroyWindow(window);
        SDL_Quit();
    }
    void clearKeyBuffer()
    {
        keybuffermutex.lock();
        scope(exit) keybuffermutex.unlock();
        keybufferpos = 0;
        keybufferlen = 0;
    }
    wstring input(wstring prompt, bool useClipBoard)
    {
        printConsole(prompt);
        clearKeyBuffer();
        wstring buffer;
        showCursor = true;
        while(true)
        {
            auto oldpos = keybufferpos;
            while(oldpos == keybufferpos)
            {
                SDL_Delay(4);//適当 ストレスを感じないくらい
            }
            auto kbp = keybufferpos;
            auto len = kbp - oldpos;
            if(len < 0)
            {
                //arienai
                kbp = oldpos;
            }
            wchar k;
            //文字入力中はカーソルを表示する
            animationCursor = true;
            foreach(key; keybuffer[oldpos..kbp])
            {
                printConsole(key);
                if(key == '\r')
                {
                    k = key;
                    break;
                }
                buffer ~= key;
            }
            clearKeyBuffer();
            if(k == '\r')
            {
                break;
            }
        }
        showCursor = false;
        return buffer;
    }
    int CSRX;
    int CSRY;
    int CSRZ;
    int consoleForeColor, consoleBackColor;
    bool showCursor;
    bool animationCursor;
    Mutex consolem;

    void renderConsoleGL()
    {
        consolem.lock();
        scope(exit) consolem.unlock();
        glBindTexture(GL_TEXTURE_2D, GRPF.glTexture);
        glDisable(GL_TEXTURE_2D);
        glBegin(GL_QUADS);
        for(int y = 0; y < consoleHeight; y++)
            for(int x = 0; x < consoleWidth; x++)
            {
                auto back = consoleColorGL[console[y][x].backColor];
                glColor4ubv(cast(ubyte*)&back);
                glVertex3f((x * 8) / 200f - 1, 1 - (y * 8 + 8) / 120f, 0.9f);
                glVertex3f((x * 8) / 200f - 1, 1 - (y * 8) / 120f, 0.9f);
                glVertex3f((x * 8 + 8) / 200f - 1, 1 - (y * 8) / 120f, 0.9f);
                glVertex3f((x * 8 + 8) / 200f - 1, 1 - (y * 8 + 8) / 120f, 0.9f);
            }
        if(showCursor && animationCursor)
        {
            glColor4ubv(cast(ubyte*)&consoleColorGL[15]);
            glVertex3f((CSRX * 8) / 200f - 1, 1 - (CSRY * 8 + 8) / 120f, -0.9f);
            glVertex3f((CSRX * 8) / 200f - 1, 1 - (CSRY * 8) / 120f, -0.9f);
            glVertex3f((CSRX * 8 + 2) / 200f - 1, 1 - (CSRY * 8) / 120f, -0.9f);
            glVertex3f((CSRX * 8 + 2) / 200f - 1, 1 - (CSRY * 8 + 8) / 120f, -0.9f);
        }
        glEnd();
        glEnable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

        //glAlphaFunc(GL_GEQUAL, 0.5);
        //glEnable(GL_ALPHA_TEST);
        glBegin(GL_QUADS);
        glColor3f(1.0, 1.0, 1.0);
        for(int y = 0; y < consoleHeight; y++)
            for(int x = 0; x < consoleWidth; x++)
            {
                auto fore = consoleColorGL[console[y][x].foreColor];
                auto rect = &fontTable[console[y][x].charater];
                glColor4ubv(cast(ubyte*)&fore);
                glTexCoord2f((rect.x) / 512f - 1 , (rect.y + 8) / 512f - 1);
                glVertex3f((x * 8) / 200f - 1, 1 - (y * 8 + 8) / 120f, 0);
                glTexCoord2f((rect.x) / 512f - 1, (rect.y) / 512f - 1);
                glVertex3f((x * 8) / 200f - 1, 1 - (y * 8) / 120f, 0);
                glTexCoord2f((rect.x + 8) / 512f - 1, (rect.y) / 512f - 1);
                glVertex3f((x * 8 + 8) / 200f - 1, 1 - (y * 8) / 120f, 0);
                glTexCoord2f((rect.x + 8) / 512f - 1, (rect.y +8) / 512f - 1);
                glVertex3f((x * 8 + 8) / 200f - 1, 1 - (y * 8 + 8) / 120f, 0);
            }
        glEnd();
        glFlush();
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
        consolem.lock();
        scope(exit) consolem.unlock();
        //write(text);
        foreach(wchar c; text)
        {
            if(CSRY >= consoleHeight)
            {
                CSRY = consoleHeight - 1;
            }
            if(c != '\r' && c != '\n')
            {
                console[CSRY][CSRX].charater = c;
                console[CSRY][CSRX].foreColor = consoleForeColor;
                console[CSRY][CSRX].backColor = consoleBackColor;
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
                tmp[] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
                //assert(console[0] != console[2]);
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
