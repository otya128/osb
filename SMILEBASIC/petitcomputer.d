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
import otya.smilebasic.sprite;
import otya.smilebasic.error;
enum Button
{
    NONE = 0,
    UP = 1,
    DOWN = 2,
    LEFT = 4,
    RIGHT = 8,
    A = 16,
    B = 32,
    X = 64,
    Y = 128,
    L = 256,
    R = 512,
    UNUSED = 1024,
    ZR = 2048,
    ZL = 4096,
    START = 8192,
}
class GraphicPage
{
    static GLenum textureScaleMode = GL_NEAREST;
    SDL_Surface* surface;
    this(SDL_Surface* s)
    {
        surface = s;
    }
    GLuint glTexture;
    GLenum textureFormat;
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
        textureFormat = texture_format;
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
        //new Test();
    }
    static const string resourceDirName = "resources";
    static const string resourcePath = "./resources";
    static const string fontFile = resourcePath ~ "/font.png";
    static const string spriteFile = resourcePath ~ "/defsp.png";
    static const string BGFile = resourcePath ~ "/defbg.png";
    static const string fontTableFile = resourcePath ~ "/fonttable.txt";
    int screenWidth;
    int screenHeight;
    int screenWidthDisplay1;
    int screenHeightDisplay1;
    int fontWidth;
    int fontHeight;
    int consoleWidth;
    int consoleHeight;
    int consoleWidthDisplay1;
    int consoleHeightDisplay1;
    int consoleHeightC, consoleWidthC;
    ConsoleCharacter[][] consoleC;
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
        wchar character;
        int foreColor;
        int backColor;
        byte attr;
    }
    SDL_Color PetitColor(byte r, byte g, byte b, byte a)
    {
        return SDL_Color(r >> 5 << 5, g >> 5 << 5, b >> 5 << 5, a == 255 ? 255 : 0);
    }
    Button button;
    ConsoleCharacter[][] console;
    ConsoleCharacter[][] consoleDisplay1;
    bool visibleGRP = true;
    int showGRP;
    int useGRP;
    uint gcolor;
    GraphicPage[] GRP;
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
        SDL_Surface* surface = SDL_CreateRGBSurface(0, src.w, src.h, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);//0xff000000, 0x00ff0000, 0x0000ff00,  0xFF);
        SDL_Rect rect;
        rect.x = 0;
        rect.y = 0;
        rect.w = src.w;
        rect.h = src.h;
//        SDL_SetSurfaceBlendMode(surface, SDL_BLENDMODE_BLEND);
//        SDL_SetSurfaceBlendMode(src, SDL_BLENDMODE_BLEND);

        ubyte sr, sg, sb, sa;
        SDL_GetRGBA((cast(uint*)src.pixels)[0], src.format, &sr, &sg, &sb, &sa);
        auto color = SDL_MapRGBA(surface.format, sr, sg, sb, sa);
        SDL_SetColorKey(src, SDL_TRUE, (cast(uint*)src.pixels)[0]);
        //SDL_SetColorKey(surface, SDL_TRUE, color);
        int i = SDL_BlitSurface(src, &rect, surface, &rect);
        auto srcpixels = (cast(uint*)src.pixels);
        auto pixels = (cast(uint*)surface.pixels);
        auto aaa = surface.format.Amask;
        //surface.format.Amask = 0xFF;
        for(int x = 0; x < src.w; x++)
        {
            for(int y = 0; y < src.h; y++)
            {
                ubyte r, g, b, a;
                SDL_GetRGBA(*pixels, surface.format, &r, &g, &b, &a);
                if(r == sr && g == sg && b == sb)
                {
                    r = 0;
                    g = 0;
                    b = 0;
                    a = 0;
                    *pixels = 0;
                    *pixels = SDL_MapRGBA(surface.format, r, g, b, a);
                }
                pixels++;
            }
        }
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
    GraphicPage createEmptyPage()
    {
        auto surface = SDL_CreateRGBSurface(0, 512, 512, 32, 0xff000000, 0x00ff0000, 0x0000ff00,  0xff);
        auto pixels = (cast(uint*)surface.pixels);
        for(int x = 0; x < surface.w; x++)
        {
            for(int y = 0; y < surface.h; y++)
            {
                *pixels++ = 0;
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
    int sppage, bgpage;
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
        //s8x8 = SDL_CreateRGBSurface(0, 8, 8, 32, 0, 0, 0, 0);
        /*auto pixels = (cast(uint*)s8x8.pixels);
        for(int x = 0; x < 8; x++)
        {
            for(int y = 0; y < 8; y++)
            {
                *pixels = SDL_MapRGBA(s8x8.format, 255, 255, 255, 255);
                pixels++;
            }
        }*/
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
        GRP = new GraphicPage[6];
        for(int i = 0; i < 4; i++)
        {
            GRP[i] = createEmptyPage();
        }
        sppage = 4;
        GRP[4] = createGRPF(spriteFile);
        bgpage = 5;
        GRP[5] = createGRPF(BGFile);
        writeln("OK");
        screenWidth = 400;
        screenHeight = 240;
        screenWidthDisplay1 = 320;
        screenHeightDisplay1 = 240;
        fontWidth = 8;
        fontHeight = 8;
        consoleWidth = screenWidth / fontWidth;
        consoleHeight = screenHeight / fontHeight;
        consoleWidthDisplay1 = screenWidthDisplay1 / fontWidth;
        consoleHeightDisplay1 = screenHeightDisplay1 / fontHeight;
        console = new ConsoleCharacter[][consoleHeight];
        consoleDisplay1 = new ConsoleCharacter[][consoleHeightDisplay1];
        consoleForeColor = 15;//#T_WHITE
        for(int i = 0; i < console.length; i++)
        {
            console[i] = new ConsoleCharacter[consoleWidth];
            console[i][] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
        }
        for(int i = 0; i < consoleDisplay1.length; i++)
        {
            consoleDisplay1[i] = new ConsoleCharacter[consoleWidthDisplay1];
            consoleDisplay1[i][] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
        }
        display(0);
    }
    void display(int number)
    {
        if(number)
        {
            consoleHeightC = consoleHeightDisplay1;
            consoleWidthC = consoleWidthDisplay1;
            consoleC = consoleDisplay1;
            return;
        }
        consoleHeightC = consoleHeight;
        consoleWidthC = consoleWidth;
        consoleC = console;
    }
    void cls()
    {
        for(int i = 0; i < console.length; i++)
        {
            console[i][] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
        }
        CSRX = 0;
        CSRY = 0;
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
    Mutex grpmutex;
    otya.smilebasic.draw.Draw draw;
    bool displaynum;
    void renderGraphic()
    {
        //grpmutex.lock();
        //scope(exit)
        //    grpmutex.unlock();
        drawflag = true;
        //betuni kouzoutai demo sonnnani sokudo kawaranasasou
        auto len = drawMessageLength;
        drawMessageLength = 0;
        for(int i = 0; i < len; i++)
        {
            DrawMessage dm = drawMessageQueue[i];
            switch(dm.type)
            {
                case DrawType.PSET:
                    draw.gpset(dm.page, dm.x, dm.y ,dm.color);
                    break;
                case DrawType.LINE:
                    draw.gline(dm.page, dm.x, dm.y ,dm.x2, dm.y2, dm.color);
                    break;
                case DrawType.FILL:
                    draw.gfill(dm.page, dm.x, dm.y ,dm.x2, dm.y2, dm.color);
                    break;
                case DrawType.BOX:
                    draw.gbox(dm.page, dm.x, dm.y ,dm.x2, dm.y2, dm.color);
                    break;
                default:
            }
        }
        drawflag = false;

    }
    Button[] buttonTable;
    Sprite sprite;
    int xscreenmode = 0;
    void xscreen(int mode, int sprite, int bg)
    {
        int mode2 = mode / 2;
        if(mode2 == 0)
        {
            SDL_SetWindowSize(window, 400, 240);
        }
        if(mode2 == 1)
        {
            SDL_SetWindowSize(window, 400, 480);
        }
        if(mode == 4)
        {
            SDL_SetWindowSize(window, 320, 240);
        }
        xscreenmode = mode2;
    }
    void render()
    {
        buttonTable = new Button[SDL_SCANCODE_SLEEP + 1];
        buttonTable[SDL_SCANCODE_UP] = Button.UP;
        buttonTable[SDL_SCANCODE_DOWN] = Button.DOWN;
        buttonTable[SDL_SCANCODE_LEFT] = Button.LEFT;
        buttonTable[SDL_SCANCODE_RIGHT] = Button.RIGHT;
        buttonTable[SDL_SCANCODE_SPACE] = Button.A;
        bool renderprofile;// = true;
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
            foreach(g; GRP)
            {
                g.createTexture(renderer);
            }
            //GRP[0] = GRPF;
            //glEnable(GL_BLEND);
            //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glAlphaFunc(GL_GEQUAL, 0.5);
            glEnable(GL_ALPHA_TEST);
            draw = new otya.smilebasic.draw.Draw(this);
           // sprite.spset(0, 0);
            // sprite.spofs(0, 9, 8);
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
                if(xscreenmode == 1)
                {
                    glViewport(0, 240, 400, 240);
                }
                renderGraphic();
                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
                renderGraphicPage();
                renderConsoleGL();
                if(xscreenmode == 1)
                {
                    glViewport(0, 240, 400, 240);
                }
                sprite.render();
/*                if(this.sprite.sprites[0].define)
                    if(this.sprite.sprites[0].u == 0)
                    {
                        writeln("WHATW");
                    }
                    else
                    {
                        writeln(this.sprite.sprites[0].u);
                    }*/

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
                        case SDL_KEYUP:
                            {
                                auto key = event.key.keysym.sym;
                                button &= ~buttonTable[event.key.keysym.scancode];
                            }
                            break;
                        case SDL_KEYDOWN:
                            {
                                auto key = event.key.keysym.sym;
                                button |= buttonTable[event.key.keysym.scancode];
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
                while(true)
                {
                    long delay = (1000/60) - (cast(long)SDL_GetTicks() - profile);
                    if(delay > 0)
                            SDL_Delay(cast(uint)delay);
                    break;
                    if(delay < 0) break;
                    renderGraphic();
                    SDL_Delay(1);
                    //if(delay > 0)
                //    SDL_Delay(cast(uint)delay);
                }
            }
        }
        catch(Throwable t)
        {
            writeln(t);
        }
    }
    SDL_Window* window;
    otya.smilebasic.vm.VM vm;
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

        consolem = new Mutex();
        keybuffermutex = new Mutex();
        grpmutex = new Mutex();
        core.thread.Thread thread = new core.thread.Thread(&render);
        thread.start();
        sprite = new Sprite(this);
        auto startTicks = SDL_GetTicks();
        //とりあえず
        auto parser = new Parser(
                                 //readText("./SYS/GAME6TALK.TXT").to!wstring
                                 readText("./SYS/GAME2RPG.TXT").to!wstring
                                 //readText("./SYS/GAME1DOTRC.TXT").to!wstring
                                 //readText(input("LOAD PROGRAM:", true).to!string).to!wstring
                                 //readText("./SYS/EX1TEXT.TXT").to!wstring
                                 //readText("FIZZBUZZ.TXT").to!wstring
                                 //readText("TEST.TXT").to!wstring
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
        vm.dump;
        this.vm = vm;
        //gpset(0, 10, 10, 0xFF00FF00);
        //gline(0, 0, 0, 399, 239, RGB(0, 255, 0));
        //gfill(0, 78, 78, 40, 40, RGB(0, 255, 255));
        //gbox(0, 78, 78, 40, 40, RGB(255, 255, 0));
        while (true)
        {
            uint elapse;
            startTicks = SDL_GetTicks();
            do
            {
                try
                {
                    if(!vsyncFrame && running)
                    {
                        //writefln("%04X:%s", vm.pc, vm.getCurrent);
                        running = vm.runStep();
                    }
                }
                catch(SmileBasicError sbe)
                {
                    running = false;
                    try
                    {
                        printConsole(sbe.to!string);
                        writeln(sbe.to!string);
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
                        writeln(t);
                    }
                    catch
                    {
                    }
                }
                elapse = SDL_GetTicks() - startTicks;
                /*if(this.sprite.sprites[0].define)
                    if(this.sprite.sprites[0].u == 0)
                {
                    writeln("WHATW");
                }
                else
                {
                    writeln(this.sprite.sprites[0].u);
                }*/
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
        auto olddisplay = displaynum;
        displaynum = 0;
        printConsole(prompt);
        clearKeyBuffer();
        wstring buffer;
        showCursor = true;
        int oldCSRX = this.CSRX;
        int oldCSRY = this.CSRY;
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
                if(key == 8)
                {
                    k = key;
                    if(!buffer.length) continue;
                    buffer = buffer[0..$ - 1];
                    CSRX--;
                    printConsoleString(" ");
                    CSRX--;
                    continue;
                }
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
        display = olddisplay;
        return buffer;
    }
    int CSRX;
    int CSRY;
    int CSRZ;
    int consoleForeColor, consoleBackColor;
    bool showCursor;
    bool animationCursor;
    Mutex consolem;
    //プチコン内部表現はRGB5_A1
    static uint toGLColor(GLenum format, ubyte r, ubyte g, ubyte b, ubyte a)
    {
        if(format == GL_BGRA)
        {
            return a << 24 | r << 16 | g << 8 | b;
        }
        if(format == GL_RGBA)
        {
            return a << 24 | b << 16 | g << 8 | r;
        }
        throw new Exception("unsuport enviroment");
    }
    static uint toGLColor(GLenum format, uint petitcolor)
    {
        if(format == GL_BGRA)
        {
            return petitcolor;
        }
        if(format == GL_RGBA)
        {
            //return a << 24 | b << 16 | g << 8 | r;
        }
        throw new Exception("unsuport enviroment");
    }
    //プチコンと違って[A,]R,G,Bじゃない
    static void RGBRead(uint color, out ubyte r, out ubyte g, out ubyte b, out ubyte a)
    {
        //エンディアン関係ない
        a = color >> 24;
        r = color >> 16 & 0xFF;
        g = color >> 8 & 0xFF;
        b = color& 0xFF;
    }
    static uint RGB(ubyte r, ubyte g, ubyte b)
    {
        return 0xFF000000 | r << 16 | g << 8 | b; 
    }
    static uint RGB(ubyte a, ubyte r, ubyte g, ubyte b)
    {
        return a << 24 | r << 16 | g << 8 | b; 
    }
    enum DrawType
    {
        CLEAR,
        PSET,
        LINE,
        FILL,
        BOX,
        CIRCLE,
        TRI,
    }
    struct DrawMessage
    {
        DrawType type;
        byte page;
        short x;
        short y;
        short x2;
        short y2;
        uint color;
        //
    }
    static const int dmqqueuelen = 8192;
    DrawMessage[] drawMessageQueue = new DrawMessage[dmqqueuelen];
    int drawMessageLength;
    bool drawflag;
    void sendDrawMessage(DrawType type, byte page, short x, short y, uint color)
    {
        //grpmutex.lock();
        //scope(exit)
        //    grpmutex.unlock();
        if(drawMessageLength >= dmqqueuelen)
        {
            while(drawMessageLength)
            {
                SDL_Delay(1);
            }
        }
        while(drawflag){}
        drawMessageQueue[drawMessageLength].type = type;
        drawMessageQueue[drawMessageLength].page = page;
        drawMessageQueue[drawMessageLength].x = x;
        drawMessageQueue[drawMessageLength].y = y;
        drawMessageQueue[drawMessageLength].color = color;
        drawMessageLength++;
    }
    void sendDrawMessage(DrawType type, byte page, short x, short y, short x2, short y2, uint color)
    {
        grpmutex.lock();
        scope(exit)
            grpmutex.unlock();
        drawMessageQueue[drawMessageLength].type = type;
        drawMessageQueue[drawMessageLength].page = page;
        drawMessageQueue[drawMessageLength].x = x;
        drawMessageQueue[drawMessageLength].y = y;
        drawMessageQueue[drawMessageLength].x2 = x2;
        drawMessageQueue[drawMessageLength].y2 = y2;
        drawMessageQueue[drawMessageLength].color = color;
        drawMessageLength++;
    }
    //TODO:範囲チェック
    void gpset(int page, int x, int y, uint color)
    {
        sendDrawMessage(DrawType.PSET, cast(byte)page, cast(short)x, cast(short)y, color);
    }
    void gline(int page, int x, int y, int x2, int y2, uint color)
    {
        sendDrawMessage(DrawType.LINE, cast(byte)page, cast(short)x, cast(short)y, cast(short)x2, cast(short)y2, color);
    }
    void gbox(int page, int x, int y, int x2, int y2, uint color)
    {
        sendDrawMessage(DrawType.BOX, cast(byte)page, cast(short)x, cast(short)y, cast(short)x2, cast(short)y2, color);
    }
    void gfill(int page, int x, int y, int x2, int y2, uint color)
    {
        sendDrawMessage(DrawType.FILL, cast(byte)page, cast(short)x, cast(short)y, cast(short)x2, cast(short)y2, color);
    }
    void renderGraphicPage()
    {
        float z = 0.01f;
        glColor3f(1.0, 1.0, 1.0);
        glBindTexture(GL_TEXTURE_2D, GRP[showGRP].glTexture);
        glEnable(GL_TEXTURE_2D);
        glBegin(GL_QUADS);
        glTexCoord2f(0 / 512f - 1 , 240 / 512f - 1);
        glVertex3f(0 / 200f - 1, 1 - 240 / 120f, z);
        glTexCoord2f(0 / 512f - 1, 0 / 512f - 1);
        glVertex3f(0 / 200f - 1, 1 - 0 / 120f, z);
        glTexCoord2f(400 / 512f - 1, 0 / 512f - 1);
        glVertex3f(400 / 200f - 1, 1 - 0 / 120f, z);
        glTexCoord2f(400 / 512f - 1, 240 / 512f - 1);
        glVertex3f(400 / 200f - 1, 1 - 240 / 120f, z);
        glEnd();
        //glFlush();
    }
    void renderConsoleGL()
    {
        //consolem.lock();
        //scope(exit) consolem.unlock();
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

        //glAlphaFunc(GL_GEQUAL, 0.5);
        //glEnable(GL_ALPHA_TEST);
        glBegin(GL_QUADS);
        for(int y = 0; y < consoleHeight; y++)
            for(int x = 0; x < consoleWidth; x++)
            {
                auto fore = consoleColorGL[console[y][x].foreColor];
                auto rect = &fontTable[console[y][x].character];
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
        if(xscreenmode != 1)
        {
            return;
        }
        //下画面
        glViewport(40, 0, 400, 240);
        glBindTexture(GL_TEXTURE_2D, GRPF.glTexture);
        glDisable(GL_TEXTURE_2D);
        glBegin(GL_QUADS);
        for(int y = 0; y < consoleHeightDisplay1; y++)
            for(int x = 0; x < consoleWidthDisplay1; x++)
            {
                auto back = consoleColorGL[consoleDisplay1[y][x].backColor];
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

        //glAlphaFunc(GL_GEQUAL, 0.5);
        //glEnable(GL_ALPHA_TEST);
        glBegin(GL_QUADS);
        for(int y = 0; y < consoleHeightDisplay1; y++)
            for(int x = 0; x < consoleWidthDisplay1; x++)
            {
                auto fore = consoleColorGL[consoleDisplay1[y][x].foreColor];
                auto rect = &fontTable[consoleDisplay1[y][x].character];
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
       // glFlush();
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
        //consolem.lock();
        //scope(exit) consolem.unlock();
        //write(text);
        foreach(wchar c; text)
        {
            if(CSRY >= consoleHeightC)
            {
                CSRY = consoleHeightC - 1;
            }
            if(c != '\r' && c != '\n')
            {
                consoleC[CSRY][CSRX].character = c;
                consoleC[CSRY][CSRX].foreColor = consoleForeColor;
                consoleC[CSRY][CSRX].backColor = consoleBackColor;
            }
            CSRX++;
            if(CSRX >= consoleWidthC || c == '\n' || c == '\r')
            {
                CSRX = 0;
                CSRY++;
            }
            if(CSRY >= consoleHeightC)
            {
                auto tmp = consoleC[0];
                for(int i = 0; i < consoleHeightC - 1; i++)
                {
                    consoleC[i] = consoleC[i + 1];
                }
                consoleC[consoleHeightC - 1] = tmp;
                tmp[] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
                //assert(console[0] != console[2]);
                CSRY = consoleHeightC - 1;
            }
        }
    }
}
