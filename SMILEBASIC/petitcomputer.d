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
import std.range;
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
        createTexture(renderer, GraphicPage.textureScaleMode);
    }
    void createTexture(SDL_Renderer* renderer, GLenum textureScaleMode)
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
        //glRenderbufferStorageEXT(GL_RENDERBUFFER_EXT, GL_DEPTH_COMPONENT24, surface.w, surface.h);
        glGenFramebuffersEXT(1, &buffer);
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, buffer);
        glFramebufferTexture2DEXT(GL_FRAMEBUFFER_EXT, GL_COLOR_ATTACHMENT0_EXT, GL_TEXTURE_2D, glTexture, 0);
        //glFramebufferRenderbufferEXT(GL_FRAMEBUFFER_EXT, GL_DEPTH_ATTACHMENT_EXT, GL_RENDERBUFFER_EXT, render);
        glBindFramebufferEXT(GL_FRAMEBUFFER_EXT, 0);
        if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        {
            writeln("!?");
        }
        glBindFramebufferEXT(GL_FRAMEBUFFER, old);
    }
    void deleteGL()
    {
        glDeleteFramebuffersEXT(1, &buffer);
        glDeleteRenderbuffersEXT(1, &render);
        glDeleteTextures(1, &glTexture);
        buffer = render = glTexture = 0;
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
struct Size
{
    int width, height;
}
struct Display
{
    SDL_Rect[] rect;
    Size windowSize;
    int yoffset;
    int count()
    {
        return cast(int)rect.length;
    }
}
class RingBuffer(T)
{
    T[] buffer;
    this(size_t size)
    {
        start = -1;
        end = -1;
        buffer = new T[size];
    }
    sizediff_t end;
    sizediff_t start;
    void put(T val)
    {
        if (end < start)
        {
            start++;
            if (start == buffer.length)
            {
                start = 0;
            }
        }
        end++;
        if (end == buffer.length)
        {
            end = 0;
            start = 1;
        }
        buffer[end] = val;
        return;
    }
    size_t length()
    {
        return start == -1 ? end - start : buffer.length;
    }
    T opIndex(size_t index)
    {
        return buffer[(start != -1 ? start + index : index) % buffer.length];
    }
}
enum Hardware
{
    threeDS = 0,
    new3DS = 1,
    wiiU = 2,
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
    struct Point
    {
        int x, y;
        this(int x, int y)
        {
            this.x = x;
            this.y = y;
        }
    }
    int[2] bgpage;
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
        currentDisplay = Display([SDL_Rect(0, 0, screenWidth, screenHeight)]);
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
        writeln("OK");
    }
    int currentScreenWidth;
    int currentScreenHeight;
    void display(int number)
    {
        import std.exception : enforce;
        enforce(number >= 0);
        currentScreenHeight = currentDisplay.rect[number].h;
        currentScreenWidth = currentDisplay.rect[number].w;
        displaynum = number;

        console.display(number);
        graphic.display(number);
    }
    SDL_Renderer* renderer;
    int vsyncFrame;
    int vsyncCount;
    int prevVSyncCount;
    bool isVSync;
    bool waitFlag;
    void vsync(int f)
    {
        waitFlag = true;
        isVSync = true;
        vsyncFrame = f;
    }
    void wait(int f)
    {
        waitFlag = true;
        isVSync = false;
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
    //フォントの都合で縮小するとまともに見られないので非推奨
    float scaleX = 1;
    float scaleY = 1;
    void glViewport2(int x, int y, int w, int h)
    {
        glViewport(cast(int)(x * scaleX), cast(int)(y * scaleY), cast(int)(w * scaleX), cast(int)(h * scaleY));
    }
    void chScreen2(int x, int y, int w, int h)
    {
        glViewport2(x, currentDisplay.yoffset - h - y, w, h);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, w, h, 0, 1024, -2048);
    }
    void chRenderingDisplay(int i)
    {
        chScreen2(currentDisplay.rect[i].x, currentDisplay.rect[i].y, currentDisplay.rect[i].w, currentDisplay.rect[i].h);
    }
    void chRenderingDisplay(int i, int x, int y, int w, int h)
    {
        glViewport2(x + currentDisplay.rect[i].x, currentDisplay.yoffset - h - y - currentDisplay.rect[i].y, w, h);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(x, x + w - 1, y + h - 1, y, 1024, -2048);
    }
    Button[] buttonTable;
    Sprite sprite;
    Size[7] resolutionTable = [Size(256, 192), Size(320, 200), Size(320, 240), Size(400, 240), Size(640, 400), Size(640, 480), Size(854, 480)];
    int xscreenmode = 0;
    int bgmax;
    void xscreen(int mode, int tv, int sprite, int bg)
    {
        xscreen(mode, tv, -1, sprite, bg);
    }
    void xscreen(int mode, int sprite, int bg)
    {
        xscreen(mode, -1, -1, sprite, bg);
    }
    Display currentDisplay;
    void xscreen(int mode, int tv, int gamepad, int sprite, int bg)
    {
        int mode2 = mode / 2;
        synchronized(renderSync)
        {
            this.sprite.spclr();
            this.sprite.spmax = sprite;
            this.bgmax = bg;
            //BG
            xscreenmode = mode2;
            if(mode2 == 0)
            {
                currentDisplay = Display([SDL_Rect(0, 0, screenWidth, screenHeight)], Size(400, 240));
            }
            if(mode2 == 1)
            {
                currentDisplay = Display([SDL_Rect(0, 0, screenWidth, screenHeight), SDL_Rect((screenWidth - screenWidthDisplay1) / 2, screenHeight, screenWidthDisplay1, screenHeightDisplay1)], Size(400, 480));
            }
            if(mode == 4)
            {
                currentDisplay = Display([SDL_Rect(0, 0, screenWidthDisplay1, screenHeight + screenHeightDisplay1)], Size(320, 480));
            }
            if (mode == 5)
            {
                currentDisplay = Display([SDL_Rect(0, 0, resolutionTable[tv].width, resolutionTable[tv].height)], Size(resolutionTable[tv].width, resolutionTable[tv].height));
                xscreenmode = 3;
            }
            if (mode == 6)
            {
                auto display0 = SDL_Rect(0, 0, resolutionTable[tv].width, resolutionTable[tv].height);
                auto display1 = SDL_Rect(0, resolutionTable[tv].height, resolutionTable[gamepad].width, resolutionTable[gamepad].height);
                if (resolutionTable[tv].width > resolutionTable[gamepad].width)
                {
                    display1.x = (resolutionTable[tv].width - resolutionTable[gamepad].width) / 2;
                }
                else
                {
                    display0.x = (resolutionTable[gamepad].width - resolutionTable[tv].width) / 2;
                }
                currentDisplay = Display([display0, display1], Size(std.algorithm.max(resolutionTable[gamepad].width, resolutionTable[tv].width), resolutionTable[gamepad].height + resolutionTable[tv].height));
                xscreenmode = 4;
            }
            currentDisplay.yoffset = currentDisplay.windowSize.height;
            int grpw, grph;
            graphic.getSize(grpw, grph);
            //1024*1024?
            if (mode == 5 || mode == 6)
            {
                if (grpw != 1024 || grph != 1024)
                {
                    graphic.setSize(1024, 1024);
                    graphic.initGraphicPages();
                }
            }
            else if (grpw != 512 || grph != 512)
            {
                graphic.setSize(512, 512);
                graphic.initGraphicPages();
            }
            displaynum = 0;
            console.changeDisplay(currentDisplay);
            for(int i = 0; i < bgmax; i++)
            {
                this.bg[i].display = 0;
                this.bg[i].clip;
            }
            if (currentDisplay.rect.length > 1)
            {
                for(int i = bgmax; i < this.bg.length; i++)
                {
                    this.bg[i].display = 1;
                    this.bg[i].clip;
                }
            }
            for (int i = cast(int)currentDisplay.rect.length - 1; i >= 0; i--)
            {
                display(i);
                graphic.clip(false);
                graphic.clip(true);
                this.sprite.spclip;
            }
        }

        SDL_SetWindowSize(window, cast(int)(currentDisplay.windowSize.width * scaleX), cast(int)(currentDisplay.windowSize.height * scaleY));
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
    //TODO:extract class
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
    struct Touch
    {
        int tm;
        int x;
        int y;
        //WiiU
        int gamepadX;
        int gamepadY;
        int display1X;
        int display1Y;
    };
    Object touchSync = new Object();
    Touch m_touch;
    Touch touchPosition()
    {
        synchronized(touchSync)
        {
            return m_touch;
        }
    }
    void touchPosition(Touch to)
    {
        synchronized(touchSync)
        {
            m_touch = to;
        }
    }
    int petitcomBackcolor;
    void backcolor(int color)
    {
        petitcomBackcolor = color;
    }
    int backcolor()
    {
        return petitcomBackcolor;
    }
    void updateTouch(int mousex, int mousey)
    {
        int ww, wh;
        SDL_GetWindowSize(window, &ww, &wh);
        mousex = cast(int)(mousex / scaleX);
        mousey = cast(int)(mousey / scaleY) - (wh - currentDisplay.yoffset);
        import std.algorithm.comparison : clamp;
        auto old = touchPosition;
        if (x.mode != XMode.WIIU)
        {
            if (mousey >= screenHeight)
            {
                mousey -= screenHeight;
                mousex -= (screenWidth - screenWidthDisplay1) / 2;
            }
            mousex = mousex.clamp(5, 314);
            mousey = mousey.clamp(5, 234);
            touchPosition = Touch(old.tm + 1, mousex, mousey);
        }
        else
        {
            //!!WiiU
            if (xscreenmode == 2 || xscreenmode == 0 || xscreenmode == 3)//XSCREEN 5
            {
                auto w = currentDisplay.rect[0].w;
                auto h = currentDisplay.rect[0].h;
                auto x3DS = cast(int)(mousex * (screenWidthDisplay1 / cast(float)w));
                auto y3DS = cast(int)(mousey * (screenHeightDisplay1 / cast(float)h));
                auto gamepadx = cast(int)(mousex * (854 / cast(float)w));
                auto gamepady = cast(int)(mousey * (480 / cast(float)h));
                touchPosition = Touch(old.tm + 1,
                                      x3DS.clamp(5, 314), y3DS.clamp(5, 234),
                                      gamepadx.clamp(8, 854 - 9), gamepady.clamp(8, 480 - 9),
                                      mousex.clamp(8, w - 13), mousey.clamp(8, h - 9));
            }
            else
            {
                auto w = currentDisplay.rect[1].w;
                auto h = currentDisplay.rect[1].h;
                mousex -= currentDisplay.rect[1].x;
                mousey -= currentDisplay.rect[1].y;
                if (mousex >= 0 && mousey >= 0)
                {
                    auto x3DS = cast(int)(mousex * (screenWidthDisplay1 / cast(float)w));
                    auto y3DS = cast(int)(mousey * (screenHeightDisplay1 / cast(float)h));
                    auto gamepadx = cast(int)(mousex * (854 / cast(float)w));
                    auto gamepady = cast(int)(mousey * (480 / cast(float)h));
                    touchPosition = Touch(old.tm + 1,
                                          x3DS.clamp(5, 314), y3DS.clamp(5, 234),
                                          gamepadx.clamp(8, 854 - 9), gamepady.clamp(8, 480 - 9),
                                          mousex.clamp(12, w - 13), mousey.clamp(8, h - 9));
                }
            }
        }
    }
    SDL_GLContext context;
    SDL_GLContext contextVM;
    Object renderSync = new Object();
    Button[int] controllerTable;
    void render()
    {
        try
        {
            DerelictSDL2.load();
            DerelictSDL2Image.load();
            sprite.sppage[] = 4;
            bgpage[] = 5;
            SDL_Init(SDL_INIT_VIDEO);
            SDL_Init(SDL_INIT_GAMECONTROLLER);

            DerelictGL.load();
            DerelictGL3.load();
        }
        catch(Throwable t)
        {
            writeln(t);
        }
        bool renderprofile = false;
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
            buttonTable[SDL_SCANCODE_RETURN] = Button.A;
            buttonTable[SDL_SCANCODE_X] = Button.A;
            buttonTable[SDL_SCANCODE_ESCAPE] = Button.B;
            buttonTable[SDL_SCANCODE_B] = Button.B;
            buttonTable[SDL_SCANCODE_A] = Button.X;
            buttonTable[SDL_SCANCODE_S] = Button.Y;

            controllerTable[SDL_CONTROLLER_BUTTON_DPAD_UP] = Button.UP;
            controllerTable[SDL_CONTROLLER_BUTTON_DPAD_DOWN] = Button.DOWN;
            controllerTable[SDL_CONTROLLER_BUTTON_DPAD_LEFT] = Button.LEFT;
            controllerTable[SDL_CONTROLLER_BUTTON_DPAD_RIGHT] = Button.RIGHT;
            controllerTable[SDL_CONTROLLER_BUTTON_A] = Button.A;
            controllerTable[SDL_CONTROLLER_BUTTON_B] = Button.B;
            controllerTable[SDL_CONTROLLER_BUTTON_X] = Button.X;
            controllerTable[SDL_CONTROLLER_BUTTON_Y] = Button.Y;
            controllerTable[SDL_CONTROLLER_BUTTON_LEFTSHOULDER] = Button.L;
            controllerTable[SDL_CONTROLLER_BUTTON_RIGHTSHOULDER] = Button.R;
            if(!window)
            {
                write("can't create window: ");
                writeln(SDL_GetError.to!string);
                return;
            }
            bool fullscreen = false;
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
            SDL_GL_SetAttribute(SDL_GL_SHARE_WITH_CURRENT_CONTEXT, 1);
            contextVM = SDL_GL_CreateContext(window);
            context = SDL_GL_CreateContext(window);
            if(!context || !contextVM)
            {
                write("can't create OpenGL context: ");
                writeln(SDL_GetError.to!string);
                return;
            }
            SDL_GL_MakeCurrent(window, context);
            console.GRPF = graphic.createGRPF(fontFile);
            graphic.GRPFWidth = console.GRPF.surface.w;
            graphic.GRPFHeight = console.GRPF.surface.h;
            console.GRPF.createTexture(renderer, textureScaleMode);
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
            console.GRPF.createBuffer();
            graphic.initGraphicPages();
            //3graphic.initGLGraphicPages();
            //glEnable(GL_BLEND);
            //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            //glAlphaFunc(GL_GEQUAL, 0.5);
            //glEnable(GL_ALPHA_TEST);
            glAlphaFunc(GL_GEQUAL, 0.1f);
            glEnable(GL_ALPHA_TEST);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
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
                synchronized(renderSync)
                {
                    glLoadIdentity();
                    {
                        ubyte r, g, b, a;
                        RGBRead(petitcomBackcolor, r, g, b, a);
                        glClearColor(r / 255f, g / 255f, b / 255f, 1);
                    }
                    //描画の順位
                    //sprite>GRP>console>BG
                    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
                    version(test) glLoadIdentity();
                    version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);
                    console.render();

                    graphic.render();
                    version(test) glLoadIdentity();
                    version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);

                    if (BGvisibles[0])
                    {
                        chRenderingDisplay(0);
                        glBindTexture(GL_TEXTURE_2D, graphic.GRP[bgpage[0]].glTexture);
                        for(int i = 0; i < bgmax; i++)
                        {
                            bg[i].render(0, currentDisplay.rect[0].w, currentDisplay.rect[0].h);
                        }
                    }
                    if(currentDisplay.rect.length > 1 && BGvisibles[1])
                    {
                        chRenderingDisplay(1);
                        glBindTexture(GL_TEXTURE_2D, graphic.GRP[bgpage[1]].glTexture);
                        for(int i = bgmax; i < bg.length; i++)
                        {
                            bg[i].render(1, currentDisplay.rect[1].w, currentDisplay.rect[1].h);
                        }
                    }
                    glMatrixMode(GL_MODELVIEW);
                    version(test) glLoadIdentity();
                    version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);

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
                    int mousex, mousey;
                    if (SDL_GetMouseState(&mousex, &mousey) & SDL_BUTTON_LMASK)
                    {
                        updateTouch(mousex, mousey);
                    }
                    else
                    {
                        if (touchPosition.tm)
                        {
                            auto old = touchPosition;
                            old.tm = 0;
                            touchPosition = old;
                        }
                    }
                }
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
                                if (event.key.keysym.mod & KMOD_ALT)
                                {
                                    if (key == SDLK_RETURN)
                                    {
                                        fullscreen = !fullscreen;
                                        if (fullscreen)
                                            SDL_SetWindowFullscreen(window, SDL_WINDOW_FULLSCREEN);
                                        else
                                            SDL_SetWindowFullscreen(window, 0);
                                        break;
                                    }
                                }
                                button |= buttonTable[event.key.keysym.scancode];
                                if(key == SDLK_v)
                                {
                                    auto mod = event.key.keysym.mod;
                                    if((mod & 0xC0))
                                    {
                                        sendKey(Key(KeyOp.PASTE));
                                    }
                                }
                                //TODO:mod key support
                                if(event.key.keysym.scancode == SDL_SCANCODE_C && (event.key.keysym.mod & 0xC0) || Button.START & buttonTable[event.key.keysym.scancode])
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
                        case SDL_MOUSEWHEEL:
                            synchronized (renderSync)
                            {
                                currentDisplay.yoffset -= event.wheel.y * 8;
                            }
                            break;
                        case SDL_CONTROLLERDEVICEADDED:
                            {
                                AddController(event.cdevice.which);
                            }
                            break;
                        case SDL_CONTROLLERDEVICEREMOVED:
                            {
                                RemoveController(event.cdevice.which);
                            }
                            break;
                        case SDL_CONTROLLERBUTTONDOWN:
                            {
                                auto jbtn = event.jbutton.button;
                                if (jbtn in controllerTable)
                                {
                                    button |= controllerTable[event.jbutton.button];
                                }
                            }
                            break;
                        case SDL_CONTROLLERBUTTONUP:
                            {
                                auto jbtn = event.jbutton.button;
                                if (jbtn in controllerTable)
                                {
                                    button &= ~controllerTable[event.jbutton.button];
                                }
                            }
                            break;
                        case SDL_FINGERDOWN:
                            {
                                auto f = event.tfinger;
                                auto x = f.x * this.currentDisplay.windowSize.width;
                                auto y = f.y * this.currentDisplay.windowSize.height;
                                updateTouch(cast(int)x, cast(int)y);
                            }
                            break;
                        default:
                            break;
                    }
                }
                long delay = (1000/60) - (cast(long)SDL_GetTicks() - profile);
                if(delay > 0)
                    SDL_Delay(cast(uint)delay);
                maincntRender++;
            }
        }
        catch(Throwable t)
        {
            writeln(t);
            readln();
        }
    }
    SDL_GameController*[int] controllers;
    void AddController(int id)
    {
        if(SDL_IsGameController(id))
        {
            SDL_GameController* pad = SDL_GameControllerOpen(id);
            if (pad)
            {
                controllers[id] = pad;
            }
        }
    }
    void RemoveController(int id)
    {
        if(SDL_IsGameController(id))
        {
            SDL_GameControllerClose(controllers.get(id, null));
        }
    }
    SDL_Window* window;
    otya.smilebasic.vm.VM vm;
    int maincntRender;
    bool running;
    bool stopflg;
    void stop()
    {
        running = false;
        stopflg = true;
    }
    void printInformation()
    {
        console.print("otyaSMILEBASIC ver ", versionString, "\n");
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
    GLenum textureScaleMode;
    int maincnt;
    void run(bool nodirectmode = false, string inputfile = "", bool antialiasing = false)
    {
        if (antialiasing)
        {
            textureScaleMode = GL_LINEAR;
        }
        else
        {
            textureScaleMode = GL_NEAREST;
        }
        buttonLock = new Object();
        slot = new Slot[5];
        keybuffer = new Key[128];
        init();
        graphic = new Graphic2(this);
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
        graphic.initVM();
        xscreen(0, 512, 4);
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
                if (!prg.empty && (inputHistory.length == 0 || inputHistory[inputHistory.length - 1] != prg))
                {
                    inputHistory.put(prg);
                }
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
            version (dumpVM)
                vm.dump;
            this.vm = vm;
            int startcnt = SDL_GetTicks();
            float frame = 1000f / 60f;
            typeof(vm.currentLocation()) loc;
            debug bool trace = false;
            while (true)
            {
                uint elapse;
                startTicks = SDL_GetTicks();
                int oldmaincnt = maincntRender;
                //do
                {
                    try
                    {
                        for(int i = 0; !quit && maincntRender == oldmaincnt && !waitFlag && running; i++)
                        {
                            version (traceVM)
                                std.stdio.stderr.writefln("%04X:%s", vm.pc, vm.getCurrent.toString(vm));
                            version (dumpStackVM)
                                vm.dumpStack();
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
                if (maincntRender != oldmaincnt)
                {
                    maincnt++;
                    vsyncCount++;
                }
                if(waitFlag)
                {
                    graphic.updateVM();
                    if (isVSync && prevVSyncCount)
                    {
                        vsyncFrame -= vsyncCount - prevVSyncCount;
                    }
                    auto endmaincnt = maincnt + vsyncFrame;
                    oldmaincnt = maincntRender;
                    while (maincnt < endmaincnt && !quit)
                    {
                        SDL_Delay(1);
                        if (maincntRender != oldmaincnt)
                        {
                            maincnt++;
                            oldmaincnt = maincntRender;
                        }
                    }
                    vsyncFrame = 0;
                    waitFlag = false;
                    isVSync = false;
                    prevVSyncCount = vsyncCount;
                }
                //maincnt = cast(int)((SDL_GetTicks() - startcnt) / frame);
                graphic.updateVM();
                if(quit)
                {
                    break;
                }
            }
            graphic.updateVM();
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
    RingBuffer!wstring inputHistory = new RingBuffer!wstring(32/*ダイレクトモードでの履歴の数は32*/);
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
        int historyIndex = cast(int)inputHistory.length;
        int oldmaincnt = maincntRender;
        scope (exit)
        {
            maincnt += maincntRender - oldmaincnt;
            vsyncCount += maincntRender - oldmaincnt;
        }
        void setText(wstring text)
        {
            console.CSRX = oldCSRX;
            console.CSRY = oldCSRY;
            for (int i = 0; i < buffer.length; i++)
            {
                console.print(" ");
            }
            buffer = text;
            pos = cast(int)text.length;
            console.CSRX = oldCSRX;
            console.CSRY = oldCSRY;
            console.print(text);
        }
        void left()
        {
            if (pos == 0)
            {
                return;
            }
            pos--;
            if (console.CSRX == 0)
            {
                console.CSRY--;
                console.CSRX = console.consoleWidthC - 1;
                return;
            }
            console.CSRX--;
        }
        void right()
        {
            if (pos >= buffer.length)
            {
                return;
            }
            pos++;
            console.CSRX++;
            if (console.CSRX == console.consoleWidthC)
            {
                console.CSRY++;
                console.CSRX = 0;
            }
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
                if (button & Button.UP)
                {
                    if (historyIndex - 1 >= 0)
                    {
                        historyIndex--;
                        setText(inputHistory[historyIndex]);
                    }
                }
                if (button & Button.DOWN)
                {
                    if (historyIndex + 1 < inputHistory.length)
                    {
                        historyIndex++;
                        setText(inputHistory[historyIndex]);
                    }
                    else
                    {
                        historyIndex++;
                        setText("");
                    }
                }
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
    public bool isValidGraphicPage(int page)
    {
        return page >= 0 && page < 6;
    }
    enum XMode
    {
        _3DS,
        COMPAT,
        WIIU,
    }
    struct X
    {
        bool motion;
        bool expad;
        bool mic;
        XMode mode;
    }
    X x;
    public void xoff(wstring func)
    {
        if (func == "MIC")
        {
            x.mic = false;
        }
        else if (func == "EXPAD")
        {
            x.expad = false;
        }
        else if (func == "MOTION")
        {
            x.motion = false;
        }
        else
        {
            std.stdio.stderr.writefln("Unknown XOFF %s", func);
        }
    }
    public void xon(wstring func)
    {
        if (func == "WIIU")
        {
            x.mode = XMode.WIIU;
        }
        else if (func == "3DS")
        {
            x.mode = XMode._3DS;
        }
        else if (func == "COMPAT")
        {
            x.mode = XMode.COMPAT;
        }
        else if (func == "MIC")
        {
            x.mic = true;
        }
        else if (func == "EXPAD")
        {
            x.expad = true;
        }
        else if (func == "MOTION")
        {
            x.motion = true;
        }
        else
        {
            std.stdio.stderr.writefln("Unknown XON %s", func);
        }
    }
    Hardware hardware = Hardware.wiiU;
    wstring versionString = "3.5.0";
    int version_ = 0x3050000;
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
