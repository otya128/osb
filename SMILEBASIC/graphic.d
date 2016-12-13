module otya.smilebasic.graphic;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl;
import derelict.opengl3.gl3;
import otya.smilebasic.petitcomputer;
import std.string;

enum DrawType
{
    CLEAR,
    PSET,
    LINE,
    FILL,
    BOX,
    CIRCLE1,
    CIRCLE2,//startangle, endangle
    TRI,
    PAINT,
    CLIPWRITE,
    PUTCHR,
    INIT,
}
struct Circle
{
    short r, startr, endr;
    short flag;
}
struct Character
{
    int scalex;
    int scaley;
    wstring text;
}
struct DrawMessage
{
    DrawType type;
    byte page;
    byte display;
    uint color;
    short x;
    short y;
    union
    {
        struct
        {
            union
            {
                short x2;
                short w;
            }
            union
            {
                short y2;
                short h;
            }
            Circle circle;
        }
        Character character;
    }
    //
}
class Graphic
{
    PetitComputer petitcom;
    int width;
    int height;
    this(PetitComputer p)
    {
        petitcom = p;
        paint = new Paint();
        width = 512;
        height = 512;
        //nnnue
        paint.buffer = new uint[width * height];
    }
    void setSize(int w, int h)
    {
        width = w;
        height = h;
        initGraphicPages();
    }
    void getSize(out int w, out int h)
    {
        w = width;
        h = height;
    }
    void initGraphicPages()
    {
        if (GRP.length != 0 && GRP[0].glTexture/*TODO:gl texture 0?*/)
        {
            foreach(g; GRP)
            {
                g.deleteGL();
            }
        }
        else
        {
            GRP = new GraphicPage[6];
        }
        for(int i = 0; i < 4; i++)
        {
            GRP[i] = createEmptyPage();
        }
        GRP[4] = createGRPF(petitcom.spriteFile);
        GRP[5] = createGRPF(petitcom.BGFile);
        foreach(g; GRP)
        {
            g.createTexture(petitcom.renderer, petitcom.textureScaleMode);
            g.createBuffer();
        }
    }
    GraphicPage createGRPF(string file)
    {
        SDL_RWops* stream = SDL_RWFromFile(toStringz(file), toStringz("rb"));
        auto src = IMG_Load_RW(stream, 0);
        SDL_Surface* surface = SDL_CreateRGBSurface(0, width, height, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);//0xff000000, 0x00ff0000, 0x0000ff00,  0xFF);
        SDL_Rect rect;
        rect.x = 0;
        rect.y = 0;
        rect.w = surface.w;
        rect.h = surface.h;
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
        for(int x = 0; x < surface.w; x++)
        {
            for(int y = 0; y < surface.h; y++)
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
        auto surface = SDL_CreateRGBSurface(0, width, height, 32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
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

    bool[2] visibles = [true, true];
    private int[2] showPage = [0, 1];
    private int[2] usePage = [0, 1];
    bool visible()
    {
        return visibles[petitcom.displaynum];
    }
    void visible(bool value)
    {
        visibles[petitcom.displaynum] = value;
    }
    @property int useGRP()
    {
        return usePage[petitcom.displaynum];
    }
    @property int showGRP()
    {
        return showPage[petitcom.displaynum];
    }
    @property void useGRP(int page)
    {
        glBindFramebufferEXT(GL_FRAMEBUFFER, this.GRP[page].buffer);
        usePage[petitcom.displaynum] = page;
    }
    @property void showGRP(int page)
    {
        showPage[petitcom.displaynum] = page;
    }
    uint gcolor = -1;
    GraphicPage[] GRP;
    GraphicPage[] oldGRP;
    class Paint
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
        BufStr[MAXSIZE] buff; /* シード登録用バッファ */
        BufStr* sIdx, eIdx;  /* buffの先頭・末尾ポインタ */
        uint point(int x, int y)
        {
            return buffer.ptr[x + y * width];
        }
        void pset(int x, int y, uint col)
        {
            buffer.ptr[x + y * width] = col;
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
            //glTexSubImage2D(GL_TEXTURE_2D , 0, 0, dy, width, h, tf, GL_UNSIGNED_BYTE, pixels + (dy * width));
            glDrawPixels(512, dy2, tf, GL_UNSIGNED_BYTE, buffer.ptr);
        }
    }
    Paint paint;
    //(x+r,y):0°
    //(x,y+r):90°
    void drawCircle(int x, int y, int r, int startr, int endr, int flag)
    {
        import std.math : sin, cos, PI;
        import std.algorithm.comparison : min;
        int count = min(r, 1000);
        if (flag)
        {
            glBegin(GL_LINE_LOOP);
            glVertex2i(x, y);
        }
        else
        {
            glBegin(GL_LINE_STRIP);
        }
        startr = startr % 360;
        endr = endr % 360;
        if (startr > endr)
        {
            endr += 360;
        }
        for (int i = 0; i <= r; i++)
        {
            //float a = i * (360f / count);
            float angle = (cast(float)i / count) * ((endr - startr) / 180f) * PI + (startr / 180f * PI);
            glVertex2f(cos(angle) * r + x, sin(angle) * r + y);
        }
        glEnd();
    }
    void drawCircle(int x, int y, int r)
    {
        import std.math : sin, cos, PI;
        import std.algorithm.comparison : min;
        int count = min(r, 1000);
        glBegin(GL_LINE_STRIP);
        for (int i = 0; i <= r; i++)
        {
            //float a = i * (360f / r);
            float angle = cast(float)i / count * 2f * PI;
            glVertex2f(cos(angle) * r + x, sin(angle) * r + y);
        }
        glEnd();
    }
    void drawText(wstring text)
    {
        int x;
        foreach (c; text)
        {
            drawCharacter(x, 0, c);
            x += 8;
        }
    }
    int GRPFWidth, GRPFHeight;
    void drawCharacter(int x, int y, wchar character)
    {
        auto rect = petitcom.console.fontTable[character];
        float tx1 = (rect.x) / (cast(float)GRPFWidth) - 1;
        float ty1 = (rect.y + 8) / (cast(float)GRPFHeight) - 1;
        float tx2 = (rect.x + 8) / (cast(float)GRPFWidth) - 1;
        float ty2 = (rect.y) / (cast(float)GRPFHeight) - 1;
        glTexCoord2f(tx1 , ty1);
        glVertex3i(x, y + 8, 0);
        glTexCoord2f(tx1, ty2);
        glVertex3i(x, y, 0);
        glTexCoord2f(tx2, ty2);
        glVertex3i(x + 8, y, 0);
        glTexCoord2f(tx2, ty1);
        glVertex3i(x + 8, y + 8, 0);
    }
    void initVM()
    {
        SDL_GL_MakeCurrent(petitcom.window, petitcom.contextVM);
        glAlphaFunc(GL_GEQUAL, 0.1f);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_ALPHA_TEST);
        glDisable(GL_DEPTH_TEST);
    }
    int drc = 0;
    void display(int display)
    {
        void chScreen(int x, int y, int w, int h)
        {
            glViewport(x, y, w, h);
            glMatrixMode(GL_PROJECTION);
            glLoadIdentity();
            glOrtho(x, x + w - 1, y, y + h - 1, -256, 1024);//wakaranai
        }
        chScreen(writeArea[display].x, writeArea[display].y, writeArea[display].w, writeArea[display].h);
        glBindFramebufferEXT(GL_FRAMEBUFFER, this.GRP[usePage[display]].buffer);
    }
    bool flushRequired;
    void updateVM()
    {
        if (drc)
            glFlush();
        drc = 0;
    }
    uint convertColor(uint color)
    {
        return petitcom.toGLColor(this.GRP[0].textureFormat, color & 0xFFF8F8F8);
    }
    void gpset(int page, int x, int y, uint color)
    {
        color = convertColor(color);
        glBegin(GL_POINTS);
        glColor4ubv(cast(ubyte*)&color);
        glVertex2f(x, y);
        glEnd();
        drc++;
    }
    void gline(int page, int x, int y, int x2, int y2, uint color)
    {
        color = convertColor(color);
        glBegin(GL_LINES);
        glColor4ubv(cast(ubyte*)&color);
        glVertex2f(x, y);
        glVertex2f(x2, y2);
        glEnd();
        drc++;
    }
    void gbox(int page, int x, int y, int x2, int y2, uint color)
    {
        color = convertColor(color);
        glBegin(GL_LINE_LOOP);
        glColor4ubv(cast(ubyte*)&color);
        glVertex2f(x, y);
        glVertex2f(x, y2);
        glVertex2f(x2, y2);
        glVertex2f(x2, y);
        glEnd();
        drc++;
    }
    void gfill(int page, int x, int y, int x2, int y2, uint color)
    {
        color = convertColor(color);
        glBegin(GL_QUADS);
        glColor4ubv(cast(ubyte*)&color);
        glVertex2f(x, y);
        glVertex2f(x, y2);
        glVertex2f(x2, y2);
        glVertex2f(x2, y);
        glEnd();
        drc++;
    }
    void gcls(int page, uint color)
    {
        gfill(page, 0, 0, width - 1, height - 1, color);
    }
    void gpaint(int page, int x, int y, uint color)
    {
        color = convertColor(color);
        updateVM();
        //glGetTexImage(GL_TEXTURE_2D,0,GRP[oldpage].textureFormat,GL_UNSIGNED_BYTE,buffer.ptr);
        glReadPixels(0, 0, width, height, GRP[useGRP].textureFormat, GL_UNSIGNED_BYTE, paint.buffer.ptr);
        paint.gpaintBuffer(paint.buffer.ptr, x, y, color, GRP[useGRP].textureFormat);
    }
    void gcircle(int page, int x, int y, int r, uint color)
    {
        color = convertColor(color);
        glColor4ubv(cast(ubyte*)&color);
        drawCircle(x, y, r);
        drc++;
    }
    void gcircle(int page, int x, int y, int r, int startr, int endr, int flag, uint color)
    {
        color = convertColor(color);
        glColor4ubv(cast(ubyte*)&color);
        drawCircle(x, y, r, startr, endr, flag);
        drc++;
    }
    void gputchr(int page, int x, int y, int text, int scalex, int scaley, uint color)
    {
        import std.conv : to;
        gputchr(page, x, y, (cast(wchar)text).to!wstring, scalex, scaley, color);
    }
    void gputchr(int page, int x, int y, wstring text, int scalex, int scaley, uint color)
    {
        color = convertColor(color);
        glColor4ubv(cast(ubyte*)&color);
        glEnable(GL_TEXTURE_2D);
        glEnable(GL_ALPHA_TEST);
        glBindTexture(GL_TEXTURE_2D, petitcom.console.GRPF.glTexture);
        glMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        glTranslatef(x, y, 0);
        glScalef(scalex, scaley, 1);
        glBegin(GL_QUADS);
        drawText(text);
        glEnd();
        glPopMatrix();
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_ALPHA_TEST);
        drc++;
    }
    int gspoit(int page, int x, int y)
    {
        int ui;
        //flush
        //if (drc)
        //    glFinish();
        //drc = 0;
        glReadPixels(x, y, 1, 1, GRP[page].textureFormat, GL_UNSIGNED_BYTE, &ui);
        return ui;
    }
    void gsave(int savepage, int x, int y, int w, int h, double[] array, int flag)
    {
        if (w * h > array.length)
            return;
        gsave(savepage, x, y, w, h, cast(int[])paint.buffer, flag);
        for (int i = 0; i < array.length; i++)
        {
            array[i] = cast(double)cast(int)paint.buffer[i];
        }
    }
    void gsave(int savepage, int x, int y, int w, int h, int[] array, int flag)
    {
        if (w * h > array.length)
            return;
        //endian?
        if (false && flag)//0=32bit
        {
            glReadPixels(x, y, w, h, GL_RGBA, GL_UNSIGNED_SHORT_5_5_5_1, array.ptr);
        }
        else
        {
            glReadPixels(x, y, w, h, GL_BGRA, GL_UNSIGNED_BYTE, array.ptr);
        }
        if (flag)
        {
            //ARRRRRGGGGGBBBBB
            for (int i = 0; i < array.length; i++)
            {
                auto a = (array[i] & 0xFF000000) >> 24;
                auto r = (array[i] & 0x00FF0000) >> 16;
                auto g = (array[i] & 0x0000FF00) >> 8;
                auto b = (array[i] & 0x000000FF);
                array[i] = (a == 255) | r >> 3 << 11 | g >> 3 << 6 | b >> 3 << 1;
            }
        }
    }
    int gprio;
    void render()
    {
        for (int i = 0; i < petitcom.currentDisplay.rect.length; i++)
        {
            render(i, petitcom.currentDisplay.rect[i].w, petitcom.currentDisplay.rect[i].h);
        }
    }
    void render(int display, int w, int h)
    {
        if (!visibles[display])
            return;
        petitcom.chRenderingDisplay(display);
        float z = gprio;
        glColor3f(1.0, 1.0, 1.0);
        glBindTexture(GL_TEXTURE_2D, GRP[showPage[display]].glTexture);
        glEnable(GL_TEXTURE_2D);
        glBegin(GL_QUADS);
        int x1 = displayArea[display].x;
        int y1 = displayArea[display].y;
        int x2 = x1 + displayArea[display].w;
        int y2 = y1 + displayArea[display].h;
        glTexCoord2f(x1 / (cast(float)width) - 1 , y2 / (cast(float)height) - 1);
        glVertex3f(x1, y2, z);
        glTexCoord2f(x1 / (cast(float)width) - 1, y1 / (cast(float)height) - 1);
        glVertex3f(x1, y1, z);
        glTexCoord2f(x2 / (cast(float)width) - 1, y1 / (cast(float)height) - 1);
        glVertex3f(x2, y1, z);
        glTexCoord2f(x2 / (cast(float)width) - 1, y2 / (cast(float)height) - 1);
        glVertex3f(x2, y2, z);
        glEnd();
        //glFlush();
    }
    SDL_Rect[2] writeArea;
    SDL_Rect[2] displayArea;
    void clip(bool clipmode)
    {
        if (clipmode)
        {
            clip(clipmode, 0, 0, width, height);
        }
        else
        {
            clip(clipmode, 0, 0, petitcom.currentScreenWidth, petitcom.currentScreenHeight);
        }
    }
    void clip(bool clipmode, int x, int y, int w, int h)
    {
        if (clipmode)
        {
            writeArea[petitcom.displaynum].x = x;
            writeArea[petitcom.displaynum].y = y;
            writeArea[petitcom.displaynum].w = w;
            writeArea[petitcom.displaynum].h = h;
            this.display(petitcom.displaynum);
        }
        else
        {
            displayArea[petitcom.displaynum] = SDL_Rect(x, y, w, h);
        }
    }
}
