module otya.smilebasic.petitcomputer;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl;
import derelict.opengl3.gl3;
import std.net.curl;
import std.file;
import std.stdio;
import std.conv;
import std.string;
import core.stdc.stdio;
import core.sync.mutex;
import core.sync.condition;
import otya.smilebasic.sprite;
import otya.smilebasic.error;
import otya.smilebasic.bg;
import otya.smilebasic.parser;
import otya.smilebasic.project;
import otya.smilebasic.console;
import otya.smilebasic.graphic;
const static rot_test_deg = 45f;
const static rot_test_x = 0f;
const static rot_test_y = 1f;
const static rot_test_z = 1f;
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
        textureFormat = texture_format;
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
    GLuint render;
    GLuint buffer;
    void createBuffer()
    {
        GLint old;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &old);
        glBindTexture(GL_TEXTURE_2D, glTexture);
        glGenRenderbuffersEXT(1, &render);
        glBindRenderbufferEXT(GL_RENDERBUFFER_EXT, render);
        glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, 512, 512);
        glGenFramebuffersEXT(1, &buffer);
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, buffer);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, glTexture, 0);
        glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, render);
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
        if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            writeln("!?");
        }
        glBindFramebufferEXT(GL_FRAMEBUFFER, old);
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
        int z;
    }
    SDL_Color PetitColor(ubyte r, ubyte g, ubyte b, ubyte a)
    {
        return SDL_Color(r >> 5 << 5, g >> 5 << 5, b >> 5 << 5, a == 255 ? 255 : 0);
    }
    Button button;
    GraphicPage createGRPF(string file)
    {
        SDL_RWops* stream = SDL_RWFromFile(toStringz(file), toStringz("rb"));
        auto src = IMG_Load_RW(stream, 0);
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
    GraphicPage createEmptyPage()
    {
        auto surface = SDL_CreateRGBSurface(0, 512, 512, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
        auto pixels = (cast(uint*)surface.pixels);
        for(int x = 0; x < surface.w; x++)
        {
            for(int y = 0; y < surface.h; y++)
            {
                ubyte r, g, b, a;
                SDL_GetRGBA(*pixels, surface.format, &r, &g, &b, &a);
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
    int sppage, bgpage;
    Projects project;
    wstring currentProject;
    void init()
    {
        currentProject = "";
        project = new Projects(".");
        //   DerelictGL.load();
        if(!exists(resourcePath))
        {
            writeln("create ./resources");
            mkdir(resourceDirName);
        }
        if(!exists(fontFile))
        {
            writeln("download font");
            download("http://smilebasic.com/wordpress/wp-content/themes/smilebasic/publishimage/appendix/res_font_table-320.png",
                     fontFile);
        }
        if(!exists(spriteFile))
        {
            writeln("download sprite");
            download("http://dengekionline.com/elem/000/000/927/927124/petitcom_16_cs1w1_512x512.jpg",
                     spriteFile);
        }
        if(!exists(BGFile))
        {
            writeln("download BG");
            download("http://dengekionline.com/elem/000/000/927/927125/petitcom_17_cs1w1_512x512.jpg",
                     BGFile);
        }
        screenWidth = 400;
        screenHeight = 240;
        screenWidthDisplay1 = 320;
        screenHeightDisplay1 = 240;
        console = new Console(this);
        if(!exists(fontTableFile))
        {
            writeln("create font table");
            //HTMLなんて解析したくないから適当
            console.createFontTable();
        }
        else
        {
            console.loadFontTable();
        }
        display(0);
        writeln("OK");
    }
    int currentScreenWidth;
    int currentScreenHeight;
    void display(int number)
    {
        import std.exception : enforce;
        enforce(number >= 0);
        if(xscreenmode == 0)
        {
            enforce(number == 0);
            currentScreenWidth = screenWidth;
            currentScreenHeight = screenHeight;
        }
        else if(xscreenmode == 1)
        {
            enforce(number == 0 || number == 1);
            currentScreenWidth = screenWidthDisplay1;
            currentScreenHeight = screenHeightDisplay1;
        }
        else
        {
            enforce(number == 0);
            currentScreenWidth = screenWidthDisplay1;
            currentScreenHeight = screenHeightDisplay1 * 2;
        }
        displaynum = number;

        console.display(number);
    }
    SDL_Renderer* renderer;
    int vsyncFrame;
    int vsyncCount;
    void vsync(int f)
    {
        vsyncCount = 0;
        vsyncFrame = f;
    }
    Graphic graphic;
    Mutex keybuffermutex;
    int keybufferpos;
    int keybufferlen;
    enum KeyOp
    {
        KEY,
        COPY,
        PASTE,
        UNDO,
        REDO,
    }
    struct Key
    {
        wchar key;
        KeyOp op;
        this(wchar k)
        {
            key = k;
            op = KeyOp.KEY;
        }
        this(KeyOp o)
        {
            op = o;
        }
    }
    //解析した結果キー入力のバッファは127くらい
    Key[] keybuffer;// = new wchar[128];//Linuxだとこうやって確保した場合書き込むとSEGV
    void sendKey(wchar key)
    {
        sendKey(Key(key));
    }
    void sendKey(Key key)
    {
        keybuffer[keybufferpos] = key;
        keybufferlen++;
        if(keybufferlen > keybuffer.length)
            keybufferlen = cast(int)keybuffer.length;
        keybufferpos = (keybufferpos + 1) % cast(int)keybuffer.length;
    }
    Mutex grpmutex;
    int displaynum;
    int renderstartpos;
    void chScreen(int x, int y, int w, int h)
    {
        glViewport(x, y, w, h);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, w, h, 0, 1024, -2048);
    }
    Button[] buttonTable;
    Sprite sprite;
    int xscreenmode = 0;
    int bgmax;
    void xscreen(int mode, int sprite, int bg)
    {
        this.sprite.spclr();
        this.sprite.spmax = sprite;
        this.bgmax = bg;
        //BG
        int mode2 = mode / 2;
        xscreenmode = mode2;
        if(mode2 == 0)
        {
            SDL_SetWindowSize(window, 400, 240);
        }
        if(mode2 == 1)
        {
            SDL_SetWindowSize(window, 400, 480);
            display(1);
            graphic.clip(false);
            graphic.clip(true);
        }
        if(mode == 4)
        {
            SDL_SetWindowSize(window, 320, 240 * 2);
        }
        display(0);
        graphic.clip(false);
        graphic.clip(true);
    }
    BG getBG(int layer)
    {
        if(displaynum)
        {
            return bg[layer + bgmax];
        }
        return bg[layer];
    }
    BG[] allBG()
    {
        return bg;
    }
    bool[2] BGvisibles = [true, true];
    bool BGvisible()
    {
        return BGvisibles[displaynum];
    }
    void BGvisible(bool value)
    {
        BGvisibles[displaynum] = value;
    }
    protected BG[4] bg;
    bool quit;
    Condition renderCondition;
    void render()
    {
        try
        {
            DerelictSDL2.load();
            DerelictSDL2Image.load();
            console.GRPF = createGRPF(fontFile);
            graphic.GRP = new GraphicPage[6];
            for(int i = 0; i < 4; i++)
            {
                graphic.GRP[i] = createEmptyPage();
            }
            sppage = 4;
            graphic.GRP[4] = createGRPF(spriteFile);
            bgpage = 5;
            graphic.GRP[5] = createGRPF(BGFile);
            SDL_Init(SDL_INIT_VIDEO);

            DerelictGL.load();
            DerelictGL3.load();
        }
        catch(Throwable t)
        {
            writeln(t);
        }
        bool renderprofile;// = true;
        try
        {
            version(Windows)
            {
                auto imm32 = LoadLibraryA("imm32.dll".toStringz);
                ImmDisableIME ImmDisableIME = cast(ImmDisableIME)GetProcAddress(imm32, "ImmDisableIME".toStringz);
                if(ImmDisableIME) ImmDisableIME(0);
            }
            SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
            window = SDL_CreateWindow("SMILEBASIC", SDL_WINDOWPOS_UNDEFINED,
                                      SDL_WINDOWPOS_UNDEFINED, 400, 240,
                                      SDL_WINDOW_SHOWN | SDL_WINDOW_OPENGL);
            buttonTable = new Button[SDL_SCANCODE_SLEEP + 1];
            buttonTable[SDL_SCANCODE_UP] = Button.UP;
            buttonTable[SDL_SCANCODE_DOWN] = Button.DOWN;
            buttonTable[SDL_SCANCODE_LEFT] = Button.LEFT;
            buttonTable[SDL_SCANCODE_RIGHT] = Button.RIGHT;
            buttonTable[SDL_SCANCODE_SPACE] = Button.A;
            buttonTable[SDL_SCANCODE_ESCAPE] = Button.START;
            if(!window)
            {
                write("can't create window: ");
                writeln(SDL_GetError.to!string);
                return;
            }
            scope(exit)
            {
                quit = true;
                SDL_DestroyWindow(window);
                SDL_Quit();
            }
            renderer = SDL_CreateRenderer(window, -1, 0);
            if(!renderer)
            {
                write("can't create renderer: ");
                writeln(SDL_GetError.to!string);
                return;
            }
            SDL_Event event;
            SDL_GLContext context;
            context = SDL_GL_CreateContext(window);
            if(!context)
            {
                write("can't create OpenGL context: ");
                writeln(SDL_GetError.to!string);
                return;
            }
            console.GRPF.createTexture(renderer);
            chScreen(0, 0, 400, 240);
            glClearColor(0.0f, 0.0f, 0.0f, 0.0f);
            glEnable(GL_DEPTH_TEST);
            version(Windows)
            {
                SDL_SysWMinfo wm;
                if(SDL_GetWindowWMInfo(window, &wm))
                {
                    ImmAssociateContext ImmAssociateContext = cast(ImmAssociateContext)GetProcAddress(imm32, "ImmAssociateContext".toStringz);
                    if(ImmAssociateContext)
                    {
                        auto c = ImmAssociateContext(wm.info.win.window, null);
                    }
                }
            }
            int loopcnt;
            DerelictGL3.reload();
            foreach(g; graphic.GRP)
            {
                g.createTexture(renderer);
                g.createBuffer();
            }
            //glEnable(GL_BLEND);
            //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            //glAlphaFunc(GL_GEQUAL, 0.5);
            //glEnable(GL_ALPHA_TEST);
            glAlphaFunc(GL_GEQUAL, 0.1f);
            glEnable(GL_ALPHA_TEST);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            xscreen(0, 512, 4);
            {
                renderCondition.mutex.lock;
                scope (exit)
                    renderCondition.mutex.unlock;
                renderCondition.notify();
            }
            while(true)
            {
                auto profile = SDL_GetTicks();
                if(console.showCursor)
                {
                    loopcnt++;
                    //30フレームに一回
                    if(loopcnt >= 30)
                    {
                        console.animationCursor = !console.animationCursor;
                        loopcnt = 0;
                    }
                }
                glLoadIdentity();
                graphic.draw();
                chScreen(0, 0, 400, 240);
                if(xscreenmode == 1)
                {
                    chScreen(0, 240, 400, 240);
                }
                if(xscreenmode == 2)
                {
                    chScreen(0, 0, 320, 480);
                }
                //描画の順位
                //sprite>GRP>console>BG
                glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
                version(test) glLoadIdentity();
                version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);
                console.render();

                if(xscreenmode == 1)
                {
                    chScreen(0, 240, 400, 240);
                }
                if(xscreenmode == 2)
                {
                    graphic.render(0, 320, 480);
                }
                else
                {
                    graphic.render(0, 400, 240);
                }
                if(xscreenmode == 1)
                {
                    chScreen(40, 0, 320, 240);
                    graphic.render(1, 320, 240);
                    chScreen(0, 240, 400, 240);
                }
                if(xscreenmode == 2)
                {
                    chScreen(0, 0, 320, 480);
                }
                if(xscreenmode == 1)
                {
                    chScreen(0, 240, 400, 240);
                }
                version(test) glLoadIdentity();
                version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);
                glBindTexture(GL_TEXTURE_2D, graphic.GRP[bgpage].glTexture);
                if(xscreenmode == 2 && BGvisibles[0])
                {
                    for(int i = 0; i < bgmax; i++)
                    {
                        bg[i].render(320f, 480f);
                    }
                }
                else
                {
                    if (BGvisibles[0])
                    {
                        for(int i = 0; i < bgmax; i++)
                        {
                            bg[i].render(400f, 240f);
                        }
                    }
                    if(xscreenmode == 1 && BGvisibles[1])
                    {
                        chScreen(40, 0, 320, 240);
                        for(int i = bgmax; i < bg.length; i++)
                        {
                            bg[i].render(320f, 240f);
                        }
                        chScreen(0, 240, 400, 240);
                    }
                    glMatrixMode(GL_MODELVIEW);
                }
                version(test) glLoadIdentity();
                version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);

                if(xscreenmode == 1)
                {
                    chScreen(0, 240, 400, 240);
                }
                //http://marina.sys.wakayama-u.ac.jp/~tokoi/?date=20081122 みたいな方法もあるけどとりあえず
                //とりあえず一番楽な方法
                //これだと同一Zでスプライトが一番下に来てしまうのでZ値を補正する必要がある->やった
                glEnable(GL_BLEND);
                glDepthMask(GL_FALSE);//スプライト同士でのZバッファは半透明だと邪魔なので無効
                sprite.render();//Zソートすべき->やった->プチコンの挙動的に安定ソートか非安定ソートか
                glDepthMask(GL_TRUE);
                glDisable(GL_BLEND);
                SDL_GL_SwapWindow(window);
                auto renderticks = (SDL_GetTicks() - profile);
                if(renderprofile) writeln(renderticks);
                while (SDL_PollEvent(&event))
                {
                    switch (event.type)
                    {
                        case SDL_QUIT:
                            return;
                        case SDL_KEYUP:
                            synchronized (buttonLock)
                            {
                                auto key = event.key.keysym.sym;
                                button &= ~buttonTable[event.key.keysym.scancode];
                            }
                            break;
                        case SDL_KEYDOWN:
                            synchronized (buttonLock)
                            {
                                auto key = event.key.keysym.sym;
                                button |= buttonTable[event.key.keysym.scancode];
                                if(key == SDLK_v)
                                {
                                    auto mod = event.key.keysym.mod;
                                    if((mod & 0xC0))
                                    {
                                        sendKey(Key(KeyOp.PASTE));
                                    }
                                }
                                if(Button.START & buttonTable[event.key.keysym.scancode])
                                {
                                    stop();
                                }
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
                long delay = (1000/60) - (cast(long)SDL_GetTicks() - profile);
                if(delay > 0)
                    SDL_Delay(cast(uint)delay);
            }
        }
        catch(Throwable t)
        {
            writeln(t);
            readln();
        }
    }
    SDL_Window* window;
    otya.smilebasic.vm.VM vm;
    int maincnt;
    bool running;
    bool stopflg;
    void stop()
    {
        running = false;
        stopflg = true;
    }
    void printInformation()
    {
        console.print("otyaSMILEBASIC ver ", otya.smilebasic.systemvariable.Version.VERSIONSTRING, "\n");
        console.print("(C)2015-2016 otya\n");
        console.print("8327164 bytes free\n");
        console.print("\n");
        printPrompt();
    }
    void printPrompt()
    {
        if(currentProject.length) console.print("[", currentProject, "]");
        console.print("OK\n");
    }
    Console console;
    Object buttonLock;
    Slot[] slot;
    bool isRunningDirectMode = false;
    void run(bool nodirectmode = false, string inputfile = "")
    {
        buttonLock = new Object();
        slot = new Slot[5];
        keybuffer = new Key[128];
        init();
        graphic = new Graphic(this);
        consolem = new Mutex();
        keybuffermutex = new Mutex();
        grpmutex = new Mutex();
        sprite = new Sprite(this);
        for(int i = 0; i < bg.length; i++)
            bg[i] = new BG(this);
        core.thread.Thread thread = new core.thread.Thread(&render);
        renderCondition = new Condition(new Mutex());
        thread.start();
        {
            renderCondition.mutex.lock;
            scope (exit)
                renderCondition.mutex.unlock;
            renderCondition.wait();
        }
        auto startTicks = SDL_GetTicks();
        Parser parser;
        otya.smilebasic.vm.VM vm;
        bool directMode = false;
        int oldpc;
        void runSlot(int lot)
        {
            import std.algorithm.iteration, std.outbuffer;
            auto buffer = new OutBuffer();
            buffer.reserve(slot[lot].program.opSlice.map!"(a.length + 1) * 2".sum);

            foreach(line; slot[lot].program)
            {
                buffer.write(line);
            }
            ubyte[] progbuff = buffer.toBytes;
            wchar[] progbuff2 = (cast(wchar*)progbuff.ptr)[0..progbuff.length / 2];
            parser = new Parser(cast(wstring)progbuff2);
            try
            {
                vm = parser.compile();
                vm.init(this);
                running = true;
            }
            catch(SmileBasicError sbe)
            {
                console.print(sbe.getErrorMessage, "\n");
                if(sbe.getErrorMessage2.length) console.print(sbe.getErrorMessage2, "\n");
                writeln(sbe.to!string);
                writeln(sbe.getErrorMessage2);
            }
            catch(Throwable t)
            {
                writeln(t);
            }
        }
        //デバッグ用
        version(NDirectMode)
            nodirectmode = true;
        if (nodirectmode)
        {
            slot[0].load(readText(inputfile).to!wstring);
            runSlot(0);
        }
        else
        {
            printInformation();
            directMode = true;
        }
        do
        {
			if(quit) return;
            if(directMode)
            {
                if(!vm)
                {
                    import otya.smilebasic.vm;
                    vm = (new Parser("")).compile;
                    vm.init(this);
                }
                else
                {
                    printPrompt();
                }
                auto prg = input("", true);
                auto lex = new Lexical(prg);
                lex.popFront();
                auto token = lex.front();
                if(token.type == otya.smilebasic.token.TokenType.Iden && token.value.stringValue == "RUN")
                {
                    bool empty = lex.empty();
                    int slot;
                    if(!empty)
                    {
                        lex.popFront();
                        token = lex.front();
                        if(token.type != otya.smilebasic.token.TokenType.Integer)
                        {
                            console.print("Illegal function call", "\n");
                            continue;
                        }
                        else
                        {
                            slot = token.value.castInteger;
                        }
                    }
                    isRunningDirectMode = false;
                    runSlot(slot);
                }
                else if(token.type == otya.smilebasic.token.TokenType.Iden && token.value.stringValue == "CONT")
                {
                    vm.pc = oldpc;
                    isRunningDirectMode = false;
                    directMode = false;
                }
                else
                {
                    isRunningDirectMode = true;
                    parser = new Parser(prg);
                    try
                    {
                        auto cc = parser.compiler;
                        cc.compileDirectMode(vm);
                    }
                    catch(SmileBasicError sbe)
                    {
                        try
                        {
                            console.print(sbe.getErrorMessage, "\n");
                            if(sbe.getErrorMessage2.length) console.print(sbe.getErrorMessage2, "\n");
                            writeln(sbe.to!string);
                            writeln(sbe.getErrorMessage2);
                            auto loc = vm.currentLocation;
                            console.print(loc.line, ":", loc.pos, ":", parser.getLine(loc));
                        }
                        catch(Throwable t)
                        {
                            writeln(t);
                        }
                        continue;
                    }
                    catch(Throwable t)
                    {
                        try
                        {
                            console.print(t.to!string);
                            writeln(t);
                            console.print(parser.getLine(vm.currentLocation));
                        }
                        catch(Throwable t)
                        {
                            writeln(t);
                        }
                        continue;
                    }
                }
                running = true;
            }
            //vm.dump;
            this.vm = vm;
            int startcnt = SDL_GetTicks();
            float frame = 1000f / 60f;
            typeof(vm.currentLocation()) loc;
            debug bool trace = false;
            while (true)
            {
                uint elapse;
                startTicks = SDL_GetTicks();
                //do
                {
                    try
                    {
                        for(int i = 0; i < 128 && !vsyncFrame && running; i++)
                        {
                            //writefln("%04X:%s", vm.pc, vm.getCurrent);
                            running = vm.runStep();
                            debug if(trace && loc.line != vm.currentLocation.line)
                            {
                                loc = vm.currentLocation;
                                console.print(loc.line, ":", loc.pos, ":", parser.getLine(loc));
                            }
                        }
                    }
                    catch(SmileBasicError sbe)
                    {
                        running = false;
                        try
                        {
                            console.print(sbe.getErrorMessage, "\n");
                            if(sbe.getErrorMessage2.length) console.print(sbe.getErrorMessage2, "\n");
                            //print(sbe.to!string);
                            writeln(sbe.to!string);
                            writeln(sbe.getErrorMessage2);
                            loc = vm.currentLocation;
                            console.print(loc.line, ":", loc.pos, ":", parser.getLine(loc));
                        }
                        catch(Throwable t)
                        {
                            writeln(t);
                        }
                    }
                    catch(Throwable t)
                    {
                        running = false;
                        try
                        {
                            console.print(t.to!string);
                            writeln(t);
                            console.print(parser.getLine(vm.currentLocation));
                        }
                        catch(Throwable t)
                        {
                            writeln(t);
                        }
                    }
                    if(!running || stopflg)
                    {
                        if(stopflg)
                        {
                            loc = vm.currentLocation;
                            console.print("Break on ", vm.currentSlotNumber, ":", loc.line, "\n");
                            stopflg = false;
                            directMode = true;
                            if(!isRunningDirectMode)
                                oldpc = vm.pc;
                        }
                        if(directMode) break;
                    }
                    //elapse = SDL_GetTicks() - startTicks;
                } //while(elapse <= 1000 / 60);
                if(vsyncFrame)
                {
                    SDL_Delay(cast(uint)(vsyncFrame * frame));
                    vsyncFrame = 0;
                }
                maincnt = cast(int)((SDL_GetTicks() - startcnt) / frame);
                if(quit)
                {
                    quit = false;
                    break;
                }
            }
        } while(directMode);
        scope(exit)
        {
            writeln("quit");
        }
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
        //displaynum = 0;
        console.print(prompt);
        clearKeyBuffer();
        wstring buffer;
        console.showCursor = true;
        int oldCSRX = this.console.CSRX;
        int oldCSRY = this.console.CSRY;
        int pos;
        void left()
        {
            pos--;
            console.CSRX--;
        }
        void right()
        {
            console.CSRX++;
        }
        while(!quit)
        {
            auto oldpos = keybufferpos;
            while(oldpos == keybufferpos && !quit)
            {
                Button old;
                synchronized(buttonLock)
                {
                    old = button;
                }
                SDL_Delay(16);//適当 ストレスを感じないくらい
                Button button;
                synchronized(buttonLock)
                {
                    button = this.button;
                }
                button = button ^ old & button;
                if (button & Button.LEFT)
                {
                    left();
                }
                if (button & Button.RIGHT)
                {
                    right();
                }
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
            console.animationCursor = true;
            foreach(key1; keybuffer[oldpos..kbp])
            {
                wchar key = key1.key;
                wstring ks;
                wstring obf = buffer;
                if(key1.op == KeyOp.KEY)
                {
                    if(key == 8)
                    {
                        k = key;
                        if(!buffer.length) continue;
                        left();
                        auto odcsrx = console.CSRX;
                        auto odcsry = console.CSRY;
                        buffer = (pos ? buffer[0..pos] : "");
                        auto ocsrx = console.CSRX;
                        auto ocsry = console.CSRY;
                        if (obf.length > pos + 1)
                        {
                            buffer ~= obf[pos + 1..$];
                            console.print(obf[pos + 1..$]);
                        }
                        console.print(" ");
                        console.CSRX = odcsrx;
                        console.CSRY = odcsry;
                        continue;
                    }
                    if(key == '\r')
                    {
                        k = key;
                        console.print("\n");
                        break;
                    }
                    immutable(wchar[1]) a = key;
                    ks = a[];
                }
                else if(key1.op == KeyOp.PASTE)
                {
                    if(SDL_HasClipboardText())
                    {
                        char* cl = SDL_GetClipboardText();
                        string an = cast(string)(cl[0..core.stdc.string.strlen(cl)]);
                        ks = an.to!wstring;
                    }
                }
                console.print(ks);
                buffer = (pos ? buffer[0..pos] : "") ~ ks;
                auto ocsrx = console.CSRX;
                auto ocsry = console.CSRY;
                if (obf.length > pos)
                {
                    buffer ~= obf[pos..$];
                    console.print(obf[pos..$]);
                }
                console.CSRX = ocsrx;
                console.CSRY = ocsry;
                pos += ks.length;
            }
            clearKeyBuffer();
            if(k == '\r')
            {
                break;
            }
        }
        console.showCursor = false;
        //display = olddisplay;
        return buffer;
    }
    wstring inkey()
    {
        if (!keybufferlen)
        {
            return "";
        }
        auto result = keybuffer[(keybufferpos - keybufferlen)];
        keybufferlen--;
        return result.key.to!wstring;
    }
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
            //ARGB->BGRA
            return (petitcolor & 0xFF00FF00) | (petitcolor & 0xFF) << 16 | petitcolor >> 16 & 0xFF;
        }
        if(format == GL_RGBA)
        {
            //return a << 24 | b << 16 | g << 8 | r;
        }
        throw new Exception("unsuport enviroment");
    }
    //プチコンと違って[A,]R,G,Bじゃない
    static pure nothrow void RGBRead(uint color, out ubyte r, out ubyte g, out ubyte b, out ubyte a)
    {
        //エンディアン関係ない
        a = color >> 24;
        r = color >> 16 & 0xFF;
        g = color >> 8 & 0xFF;
        b = color& 0xFF;
    }
    static pure nothrow uint RGB(ubyte r, ubyte g, ubyte b)
    {
        return 0xFF000000 | r << 16 | g << 8 | b; 
    }
    static pure nothrow uint RGB(ubyte a, ubyte r, ubyte g, ubyte b)
    {
        return a << 24 | r << 16 | g << 8 | b; 
    }
}
