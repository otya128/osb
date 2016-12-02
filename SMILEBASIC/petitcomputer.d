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
    bool visibleGRP = true;
    private int[2] showPage = [0, 1];
    private int[2] usePage = [0, 1];
    @property int useGRP()
    {
        return usePage[displaynum];
    }
    @property int showGRP()
    {
        return showPage[displaynum];
    }
    @property void useGRP(int page)
    {
        usePage[displaynum] = page;
    }
    @property void showGRP(int page)
    {
        showPage[displaynum] = page;
    }
    uint gcolor = -1;
    GraphicPage[] GRP;
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
    void display(int number)
    {
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
    struct Paint
    {
        uint[] buffer;
        static const MAXSIZE = 1024; /* バッファサイズ */

        /* 画面サイズは 1024 X 1024 とする */
        static const MINX = 0;
        static const MINY = 0;
        static const MAXX = 511;
        static const MAXY = 511;

        struct BufStr {
            int lx; /* 領域右端のX座標 */
            int rx; /* 領域右端のX座標 */
            int y;  /* 領域のY座標 */
            int oy; /* 親ラインのY座標 */
        };
        BufStr buff[MAXSIZE]; /* シード登録用バッファ */
        BufStr* sIdx, eIdx;  /* buffの先頭・末尾ポインタ */
        uint point(int x, int y)
        {
            return buffer.ptr[x + y * 512];
        }
        void pset(int x, int y, uint col)
        {
            buffer.ptr[x + y * 512] = col;
        }
        /*
        scanLine : 線分からシードを探索してバッファに登録する

        int lx, rx : 線分のX座標の範囲
        int y : 線分のY座標
        int oy : 親ラインのY座標
        unsigned int col : 領域色
        */
        void scanLine( int lx, int rx, int y, int oy, uint col )
        {
            while ( lx <= rx ) {

                /* 非領域色を飛ばす */
                for ( ; lx < rx ; lx++ )
                    if ( point( lx, y ) == col ) break;
                if ( point( lx, y ) != col ) break;

                eIdx.lx = lx;

                /* 領域色を飛ばす */
                for ( ; lx <= rx ; lx++ )
                    if ( point( lx, y ) != col ) break;

                eIdx.rx = lx - 1;
                eIdx.y = y;
                eIdx.oy = oy;

                if ( ++eIdx == &buff.ptr[MAXSIZE] )
                    eIdx = buff.ptr;
            }
        }

        /*
        paint : 塗り潰し処理(高速版)

        int x, y : 開始座標
        unsigned int paintCol : 塗り潰す時の色(描画色)
        */
        void paint( int x, int y, uint paintCol , out int dx, out int dy, out int dx2, out int dy2)
        {
            int lx, rx; /* 塗り潰す線分の両端のX座標 */
            int ly;     /* 塗り潰す線分のY座標 */
            int oy;     /* 親ラインのY座標 */
            int i;
            uint col = point( x, y ); /* 閉領域の色(領域色) */
            dx = int.max, dy = int.max, dx2 = int.min, dy2 = int.min;
            if ( col == paintCol ) return;    /* 領域色と描画色が等しければ処理不要 */
            sIdx = buff.ptr;
            eIdx = buff.ptr + 1;
            sIdx.lx = sIdx.rx = x;
            sIdx.y = sIdx.oy = y;

            do {
                lx = sIdx.lx;
                rx = sIdx.rx;
                ly = sIdx.y;
                oy = sIdx.oy;

                int lxsav = lx - 1;
                int rxsav = rx + 1;

                if ( ++sIdx == &buff.ptr[MAXSIZE] ) sIdx = buff.ptr;

                /* 処理済のシードなら無視 */
                if ( point( lx, ly ) != col )
                    continue;

                /* 右方向の境界を探す */
                while ( rx < MAXX ) {
                    if ( point( rx + 1, ly ) != col ) break;
                    rx++;
                }
                /* 左方向の境界を探す */
                while ( lx > MINX ) {
                    if ( point( lx - 1, ly ) != col ) break;
                    lx--;
                }
                import std.algorithm;
                dy = min(dy, ly);
                dy2 = max(dy2, ly);
                dx = min(dx, lx);
                dx2 = max(dx2, rx);
                //
                /* lx-rxの線分を描画 */
                for ( i = lx; i <= rx; i++ ) pset( i, ly, paintCol );

                /* 真上のスキャンラインを走査する */
                if ( ly - 1 >= MINY ) {
                    if ( ly - 1 == oy ) {
                        scanLine( lx, lxsav, ly - 1, ly, col );
                        scanLine( rxsav, rx, ly - 1, ly, col );
                    } else {
                        scanLine( lx, rx, ly - 1, ly, col );
                    }
                }

                /* 真下のスキャンラインを走査する */
                if ( ly + 1 <= MAXY ) {
                    if ( ly + 1 == oy ) {
                        scanLine( lx, lxsav, ly + 1, ly, col );
                        scanLine( rxsav, rx, ly + 1, ly, col );
                    } else {
                        scanLine( lx, rx, ly + 1, ly, col );
                    }
                }

            } while ( sIdx != eIdx );
        }
        void gpaintBuffer(uint* pixels, int x, int y, uint color, GLenum tf)
        {
            int dx, dy, dx2, dy2;
            paint(x, y, color, dx, dy, dx2, dy2);
            if(dx == int.max) return;
            int h = dy2 - dy;
            glTexSubImage2D(GL_TEXTURE_2D , 0, 0, dy, 512, h, tf, GL_UNSIGNED_BYTE, pixels + (dy * 512));
            //        glDrawPixels(512, dy2, tf, GL_UNSIGNED_BYTE, buffer.ptr);
        }
    }
    Paint paint;
    int renderstartpos;
    void chScreen(int x, int y, int w, int h)
    {
        glViewport(x, y, w, h);
        glMatrixMode(GL_PROJECTION);
        glLoadIdentity();
        glOrtho(0, w, h, 0, 1024, -2048);
    }
    void drawCircle(int x, int y, int r, int startr, int endr, int flag)
    {
        import std.math : sin, cos, PI;
        int count = r;
        glBegin(GL_LINE_LOOP);
        for (int i = 0; i <= r; i++)
        {
            //float a = i * (360f / r);
            glVertex2f(sin(cast(float)i / count * 2f * PI) * r + x, cos(cast(float)i / count * 2f * PI) * r + y);
        }
        glEnd();
    }
    void renderGraphic()
    {
        if(!drawMessageLength) return;
        drawflag = true;
        //betuni kouzoutai demo sonnnani sokudo kawaranasasou
        auto len = drawMessageLength;
        int s = renderstartpos;
        GLint old;
        auto a = & glBindFramebuffer;
        glGetIntegerv(GL_FRAMEBUFFER_BINDING, &old);
        int oldpage = drawMessageQueue[0].page;
        glBindFramebufferEXT(GL_FRAMEBUFFER, this.GRP[oldpage].buffer);
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_ALPHA_TEST);
        glDisable(GL_DEPTH_TEST);

        //glAlphaFunc(GL_GEQUAL, 0.0);
        void chScreen(int x, int y, int w, int h)
        {
            glViewport(x, y, w, h);
            glMatrixMode(GL_PROJECTION);
            glLoadIdentity();
            glOrtho(0, w, 0, h, -256, 1024);//wakaranai
        }
        chScreen(0, 0, 511, 511);
        DrawType dt;
        auto start = SDL_GetTicks();
        int i = s;
        static const size = 255.5f;
        for(; i < len; i++)
        {
            DrawMessage dm = drawMessageQueue[i];
            if(oldpage != dm.page)
            {
                oldpage = dm.page;
                glBindFramebufferEXT(GL_FRAMEBUFFER, this.GRP[oldpage].buffer);
            }
            switch(dm.type)
            {
                case DrawType.PSET:
                    glBegin(GL_POINTS);
                    glColor4ubv(cast(ubyte*)&dm.color);
                    glVertex2f(dm.x, dm.y);
                    glEnd();
                    //draw.gpset(dm.page, dm.x, dm.y ,dm.color);
                    break;
                case DrawType.LINE:
                    {
                        glBegin(GL_LINES);
                        glColor4ubv(cast(ubyte*)&dm.color);
                        glVertex2f(dm.x, dm.y);
                        glVertex2f(dm.x2, dm.y2);
                        //glFlush();
                        glEnd();
                    }
                    //draw.gline(dm.page, dm.x, dm.y ,dm.x2, dm.y2, dm.color);
                    break;
                case DrawType.FILL:
                    {
                        glBegin(GL_QUADS);
                        glColor4ubv(cast(ubyte*)&dm.color);
                        glVertex2f(dm.x, dm.y);
                        glVertex2f(dm.x, dm.y2);
                        glVertex2f(dm.x2, dm.y2);
                        glVertex2f(dm.x2, dm.y);
                        glEnd();
                    }
                    //draw.gfill(dm.page, dm.x, dm.y ,dm.x2, dm.y2, dm.color);
                    break;
                case DrawType.BOX:
                    {
                        glBegin(GL_LINE_LOOP);
                        glColor4ubv(cast(ubyte*)&dm.color);
                        glVertex2f(dm.x, dm.y);
                        glVertex2f(dm.x, dm.y2);
                        glVertex2f(dm.x2, dm.y2);
                        glVertex2f(dm.x2, dm.y);
                        glEnd();
                    }
                    //draw.gbox(dm.page, dm.x, dm.y ,dm.x2, dm.y2, dm.color);
                    break;
                case DrawType.PAINT:
                    {
                        glBindTexture(GL_TEXTURE_2D, GRP[oldpage].glTexture);
                        if(dt != DrawType.PAINT)
                        {
                            glFinish();
                            //glGetTexImage(GL_TEXTURE_2D,0,GRP[oldpage].textureFormat,GL_UNSIGNED_BYTE,buffer.ptr);
                            glReadPixels(0, 0, 512, 512, GRP[oldpage].textureFormat, GL_UNSIGNED_BYTE, paint.buffer.ptr);
                        }
                        paint.gpaintBuffer(paint.buffer.ptr, dm.x, dm.y, dm.color, GRP[oldpage].textureFormat);
                        //gpaintBufferExW(oldpage, dm.x, dm.y, dm.color);
                        if(SDL_GetTicks() - start >= 16 && i != len - 1)
                        {
                            s = i + 1;
                            goto brk;
                        }
                    }
                    break;
                case DrawType.CIRCLE:
                    {
                        glColor4ubv(cast(ubyte*)&dm.color);
                        drawCircle(dm.x, dm.y, dm.circle.r, dm.circle.startr, dm.circle.endr, dm.circle.flag);
                    }
                    break;
                default:
            }
            dt = dm.type;
        }
    brk:
        if(i == len)
        {
            renderstartpos = 0;
            drawMessageLength = 0;
        }
        else
        {
            renderstartpos = s;
        }
        glBindFramebufferEXT(GL_FRAMEBUFFER, old);
        glEnable(GL_DEPTH_TEST);
        drawflag = false;
        glEnable(GL_ALPHA_TEST);
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
        }
        if(mode == 4)
        {
            SDL_SetWindowSize(window, 320, 240 * 2);
            display(0);
        }
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
    protected BG[4] bg;
    bool quit;
    Condition renderCondition;
    void render()
    {
        try
        {
            paint.buffer = new uint[512 * 512];
            DerelictSDL2.load();
            DerelictSDL2Image.load();
            console.GRPF = createGRPF(fontFile);
            GRP = new GraphicPage[6];
            for(int i = 0; i < 4; i++)
            {
                GRP[i] = createEmptyPage();
            }
            sppage = 4;
            GRP[4] = createGRPF(spriteFile);
            bgpage = 5;
            GRP[5] = createGRPF(BGFile);
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
            foreach(g; GRP)
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
                renderGraphic();
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
                    renderGraphicPage(0, 320, 480);
                }
                else
                {
                    renderGraphicPage(0, 400, 240);
                }
                if(xscreenmode == 1)
                {
                    chScreen(40, 0, 320, 240);
                    renderGraphicPage(1, 320, 240);
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
                glBindTexture(GL_TEXTURE_2D, GRP[bgpage].glTexture);
                if(xscreenmode == 2)
                {
                    for(int i = 0; i < bgmax; i++)
                    {
                        bg[i].render(320f, 480f);
                    }
                }
                else
                {
                    for(int i = 0; i < bgmax; i++)
                    {
                        bg[i].render(400f, 240f);
                    }
                    if(xscreenmode == 1)
                    {
                        chScreen(40, 0, 320, 240);
                        for(int i = bgmax; i < bg.length; i++)
                        {
                            bg[i].render(320f, 240f);
                        }
                        chScreen(0, 240, 400, 240);
                    }
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
            parser = new Parser(std.algorithm.reduce!("a ~ b")(slot[lot].program.opSlice));
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
            /*vm.code.append(parser.compiler.compileProgram());*/
            version(none)
                do
                {
                    auto file = input("LOAD PROGRAM:", true).to!string;
                    try
                    {
                        parser = new Parser(readText(file).to!wstring);
                    }
                    catch(Throwable t)
                    {
                        writeln(t);
                        print("can't open program \"", file, "\".\n");
                        continue;
                    }
                    try
                    {
                        vm = parser.compile();
                        vm.init(this);
                        running = true;
                    }
                    catch(SmileBasicError sbe)
                    {
                        print(sbe.getErrorMessage, "\n");
                        print(sbe.getErrorMessage2, "\n");
                        //print(sbe.to!string);
                        writeln(sbe.to!string);
                        writeln(sbe.getErrorMessage2);
                        continue;
                    }
                    catch(Throwable t)
                    {
                        writeln(t);
                        continue;
                    }
                    break;
                } while(!quit);
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
            //bg[0].put(0,0,1);
            //gpset(0, 10, 10, 0xFF00FF00);
            //gline(0, 0, 0, 399, 239, RGB(0, 255, 0));
            //gfill(0, 78, 78, 40, 40, RGB(0, 255, 255));
            //gbox(0, 78, 78, 40, 40, RGB(255, 255, 0));
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
    enum DrawType
    {
        CLEAR,
        PSET,
        LINE,
        FILL,
        BOX,
        CIRCLE,
        TRI,
        PAINT,
    }
    struct Circle
    {
        short r, startr, endr;
        short flag;
    } 
    struct DrawMessage
    {
        DrawType type;
        byte page;
        short x;
        short y;
        uint color;
        short x2;
        short y2;
        Circle circle;
        //
    }
    static const int dmqqueuelen = 8192;
    DrawMessage[] drawMessageQueue = new DrawMessage[dmqqueuelen];
    int drawMessageLength;
    bool drawflag;
    void sendDrawMessage(DrawMessage dm)
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
        dm.color = toGLColor(this.GRP[0].textureFormat, dm.color & 0xFFF8F8F8);
        drawMessageQueue[drawMessageLength] = dm;
        drawMessageLength++;
    }
    void sendDrawMessage(DrawType type, byte page, short x, short y, uint color)
    {
        DrawMessage dm;
        dm.type = type;
        dm.page = page;
        dm.x = x;
        dm.y = y;
        dm.color = color;
        sendDrawMessage(dm);
    }
    void sendDrawMessage(DrawType type, byte page, short x, short y, short x2, short y2, uint color)
    {
        DrawMessage dm;
        dm.type = type;
        dm.page = page;
        dm.x = x;
        dm.y = y;
        dm.x2 = x2;
        dm.y2 = y2;
        dm.color = color;
        sendDrawMessage(dm);
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
    void gpaint(int page, int x, int y, uint color)
    {
        sendDrawMessage(DrawType.PAINT, cast(byte)page, cast(short)x, cast(short)y, color);
    }
    void gcircle(int page, int x, int y, int r, int startr, int endr, int flag, uint color)
    {
        DrawMessage dm;
        dm.page = cast(byte)page;
        dm.x = cast(short)x;
        dm.y = cast(short)y;
        dm.circle.r = cast(short)r;
        dm.circle.startr = cast(short)startr;
        dm.circle.endr = cast(short)endr;
        dm.circle.flag = cast(short)flag;
        dm.color = color;
        dm.type = DrawType.CIRCLE;
        sendDrawMessage(dm);
    }
    int gprio;
    void renderGraphicPage(int display, float w, float h)
    {
        float z = gprio;
        glColor3f(1.0, 1.0, 1.0);
        glBindTexture(GL_TEXTURE_2D, GRP[showPage[display]].glTexture);
        glEnable(GL_TEXTURE_2D);
        glBegin(GL_QUADS);
        glTexCoord2f(0 / 512f - 1 , h / 512f - 1);
        glVertex3f(0, h, z);
        glTexCoord2f(0 / 512f - 1, 0 / 512f - 1);
        glVertex3f(0, 0, z);
        glTexCoord2f(w / 512f - 1, 0 / 512f - 1);
        glVertex3f(w, 0, z);
        glTexCoord2f(w / 512f - 1, h / 512f - 1);
        glVertex3f(w, h, z);
        glEnd();
        //glFlush();
    }
}
