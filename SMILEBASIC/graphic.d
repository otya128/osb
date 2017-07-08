module otya.smilebasic.graphic;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl;
import otya.smilebasic.petitcomputer;
import std.string;

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
    int GRPFWidth, GRPFHeight;
    void setSize(int w, int h)
    {
        width = w;
        height = h;
    }
    void getSize(out int w, out int h)
    {
        w = width;
        h = height;
    }
    void initGraphicPages()
    {
        if (GRP.length == 0)
        {
            GRP = new GraphicPage[6];
        }
        for(int i = 0; i < 4; i++)
        {
            GRP[i] = createEmptyPage();
        }
        GRP[4] = createGRPF(petitcom.spriteFile);
        GRP[5] = createGRPF(petitcom.BGFile);
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
    int[2] showPage = [0, 1];
    int[2] usePage = [0, 1];
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
    abstract void initVM();
    abstract void display(int display);
    abstract void updateVM();
    abstract void gpset(int page, int x, int y, uint color);
    abstract void gline(int page, int x, int y, int x2, int y2, uint color);
    abstract void gbox(int page, int x, int y, int x2, int y2, uint color);
    abstract void gfill(int page, int x, int y, int x2, int y2, uint color);
    abstract void gcls(int page, uint color);
    abstract void gpaint(int page, int x, int y, uint color);
    abstract void gcircle(int page, int x, int y, int r, uint color);
    abstract void gcircle(int page, int x, int y, int r, int startr, int endr, int flag, uint color);
    abstract void gputchr(int page, int x, int y, int text, int scalex, int scaley, uint color);
    abstract void gputchr(int page, int x, int y, wstring text, int scalex, int scaley, uint color);
    abstract int gspoit(int page, int x, int y);
    abstract void gsave(int savepage, int x, int y, int w, int h, double[] array, int flag);
    abstract void gsave(int savepage, int x, int y, int w, int h, int[] array, int flag);
    abstract void gload(int x, int y, int w, int h, int[] array, int flag, int copymode);
    abstract void gload(int x, int y, int w, int h, double[] array, int flag, int copymode);
    void gloadPalette(T, T2)(int x, int y, int w, int h, T[] array, T2[] palette, int copymode)
    if ((is(T == int) || is(T == double)) && (is(T2 == int) || is(T2 == double)))
    {
        if (cast(GraphicFBO)this)
        {
            GraphicFBO gfbo = (cast(GraphicFBO)this);
            gfbo.gloadPalette(x, y, w, h, array, palette, copymode);
        }
        if (cast(Graphic2)this)
        {
            Graphic2 g = (cast(Graphic2)this);
            g.gloadPalette(x, y, w, h, array, palette, copymode);
        }
    }
    abstract void gcopy(int srcpage, int x, int y, int x2, int y2, int x3, int y3, int cpmode);
    abstract void gtri(int x1, int y1, int x2, int y2, int x3, int y3, int color);
    int[2] gprios = [512, 512];

    @property ref gprio()
    {
        return gprios[petitcom.displaynum];
    }
    @property void gprio(int value)
    {
        gprios[petitcom.displaynum] = value;
    }

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
        float z = gprios[display];
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
    static int ARGB32ToRGBA16Color(int argb32)
    {
        auto a = (argb32 & 0xFF000000) >> 24;
        auto r = (argb32 & 0x00FF0000) >> 16;
        auto g = (argb32 & 0x0000FF00) >> 8;
        auto b = (argb32 & 0x000000FF);
        return (a == 255) | r >> 3 << 11 | g >> 3 << 6 | b >> 3 << 1;
    }
    static int RGBA16ToARGB32Color(int rgba16)
    {
        auto a = (rgba16 & 0b0000000000000001) == 1 ? 0xFF000000 : 0;
        auto r = (rgba16 & 0b1111100000000000) >> 11;
        auto g = (rgba16 & 0b0000011111000000) >> 6;
        auto b = (rgba16 & 0b0000000000111110) >> 1;
        return a | r << 19 | g << 11 | b << 3;
    }
}

class GraphicFBO : Graphic
{
    this(PetitComputer p)
    {
        super(p);
    }
    override void initGraphicPages()
    {
        foreach(g; GRP)
        {
            if (g.glTexture)
                g.deleteGL();
        }
        super.initGraphicPages();
        foreach(g; GRP)
        {
            g.createTexture(petitcom.renderer, petitcom.textureScaleMode);
            g.createBuffer();
        }
    }
    override @property void useGRP(int page)
    {
        super.useGRP = page;
        glBindFramebufferEXT(GL_FRAMEBUFFER, this.GRP[page].buffer);
    }
    override @property int useGRP()
    {
        return super.useGRP;
    }
    
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
    override void initVM()
    {
        SDL_GL_MakeCurrent(petitcom.window, petitcom.contextVM);
        glAlphaFunc(GL_GEQUAL, 0.1f);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_ALPHA_TEST);
        glDisable(GL_DEPTH_TEST);
    }
    int drc = 0;
    override void display(int display)
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
    override void updateVM()
    {
        if (drc)
            glFlush();
        drc = 0;
    }
    uint convertColor(uint color)
    {
        return petitcom.toGLColor(this.GRP[0].textureFormat, color & 0xFFF8F8F8);
    }
    override void gpset(int page, int x, int y, uint color)
    {
        color = convertColor(color);
        glBegin(GL_POINTS);
        glColor4ubv(cast(ubyte*)&color);
        glVertex2f(x, y);
        glEnd();
        drc++;
    }
    override void gline(int page, int x, int y, int x2, int y2, uint color)
    {
        color = convertColor(color);
        glBegin(GL_LINES);
        glColor4ubv(cast(ubyte*)&color);
        glVertex2f(x, y);
        glVertex2f(x2, y2);
        glEnd();
        drc++;
    }
    override void gbox(int page, int x, int y, int x2, int y2, uint color)
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
    override void gfill(int page, int x, int y, int x2, int y2, uint color)
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
    override void gcls(int page, uint color)
    {
        gfill(page, 0, 0, width - 1, height - 1, color);
    }
    override void gpaint(int page, int x, int y, uint color)
    {
        color = convertColor(color);
        updateVM();
        //glGetTexImage(GL_TEXTURE_2D,0,GRP[oldpage].textureFormat,GL_UNSIGNED_BYTE,buffer.ptr);
        glReadPixels(0, 0, width, height, GRP[useGRP].textureFormat, GL_UNSIGNED_BYTE, paint.buffer.ptr);
        paint.gpaintBuffer(paint.buffer.ptr, x, y, color, GRP[useGRP].textureFormat);
    }
    override void gcircle(int page, int x, int y, int r, uint color)
    {
        color = convertColor(color);
        glColor4ubv(cast(ubyte*)&color);
        drawCircle(x, y, r);
        drc++;
    }
    override void gcircle(int page, int x, int y, int r, int startr, int endr, int flag, uint color)
    {
        color = convertColor(color);
        glColor4ubv(cast(ubyte*)&color);
        drawCircle(x, y, r, startr, endr, flag);
        drc++;
    }
    override void gputchr(int page, int x, int y, int text, int scalex, int scaley, uint color)
    {
        import std.conv : to;
        gputchr(page, x, y, (cast(wchar)text).to!wstring, scalex, scaley, color);
    }
    override void gputchr(int page, int x, int y, wstring text, int scalex, int scaley, uint color)
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
    override int gspoit(int page, int x, int y)
    {
        int ui;
        //flush
        //if (drc)
        //    glFinish();
        //drc = 0;
        glReadPixels(x, y, 1, 1, GRP[page].textureFormat, GL_UNSIGNED_BYTE, &ui);
        return ui;
    }
    override void gsave(int savepage, int x, int y, int w, int h, double[] array, int flag)
    {
        if (w * h > array.length)
            return;
        gsave(savepage, x, y, w, h, cast(int[])paint.buffer, flag);
        for (int i = 0; i < array.length; i++)
        {
            array[i] = cast(double)cast(int)paint.buffer[i];
        }
    }
    override void gsave(int savepage, int x, int y, int w, int h, int[] array, int flag)
    {
        if (w * h > array.length)
            return;
        auto oldPage = useGRP;
        if (savepage == -1)
        {
            glBindFramebufferEXT(GL_FRAMEBUFFER, petitcom.console.GRPF.buffer);
        }
        else
        {
            useGRP = savepage;
        }
        scope (exit)
        {
            useGRP = oldPage;
        }
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
                array[i] = ARGB32ToRGBA16Color(array[i]);
            }
        }
    }
    override void gload(int x, int y, int w, int h, int[] array, int flag, int copymode)
    {
        if (w * h > array.length)
            return;
        if (!copymode)
        {
            glEnable(GL_ALPHA_TEST);
        }
        glRasterPos2i(x, y);
        //convertColor
        if (flag)
        {
            //ARRRRRGGGGGBBBBB
            for (int i = 0; i < array.length; i++)
            {
                paint.buffer[i] = RGBA16ToARGB32Color(array[i]);
            }
            glDrawPixels(w , h , GL_BGRA , GL_UNSIGNED_BYTE , paint.buffer.ptr);
        }
        else
        {
            glDrawPixels(w , h , GL_BGRA , GL_UNSIGNED_BYTE , array.ptr);
        }
        if (!copymode)
        {
            glDisable(GL_ALPHA_TEST);
        }
    }
    override void gload(int x, int y, int w, int h, double[] array, int flag, int copymode)
    {
        for (int i = 0; i < array.length; i++)
        {
            paint.buffer[i] = cast(int)array[i];
        }
        gload(x, y, w, h, cast(int[])paint.buffer, flag, copymode);
    }
    void gloadPalette(T, T2)(int x, int y, int w, int h, T[] array, T2[] palette, int copymode)
        if ((is(T == int) || is(T == double)) && (is(T2 == int) || is(T2 == double)))
        {
            for (int i = 0; i < array.length; i++)
            {
                paint.buffer[i] = cast(int)palette[cast(int)array[i]];
            }
            gload(x, y, w, h, cast(int[])paint.buffer, 0, copymode);
        }
}

class Graphic2 : Graphic
{
    this(PetitComputer p)
    {
        super(p);
    }
    override void initGraphicPages()
    {
        foreach(g; GRP)
        {
            if (g.glTexture)
                g.deleteGL();
        }
        super.initGraphicPages();
        foreach(g; GRP)
        {
            g.createTexture(petitcom.renderer, petitcom.textureScaleMode);
        }
    }
    override void initVM()
    {
        SDL_GL_MakeCurrent(petitcom.window, petitcom.contextVM);
        glAlphaFunc(GL_GEQUAL, 0.1f);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glDisable(GL_TEXTURE_2D);
        glDisable(GL_ALPHA_TEST);
        glDisable(GL_DEPTH_TEST);
    }

    int olddisplay;
    override void display(int display)
    {
        if (df)
        {
            glBindTexture(GL_TEXTURE_2D, this.GRP[usePage[olddisplay]].glTexture);
            glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_BGRA, GL_UNSIGNED_BYTE, buffer);
            glFlush();
            df = false;
        }
        olddisplay = display;
        buffer = cast(int*)this.GRP[usePage[display]].surface.pixels;
    }

    bool df;
    void updateTexture()
    {
        glBindTexture(GL_TEXTURE_2D, this.GRP[useGRP].glTexture);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, width, height, GL_BGRA, GL_UNSIGNED_BYTE, buffer);
        glFlush();
    }
    override void updateVM()
    {
        if (df)
        {
            updateTexture;
            df = false;
        }
    }

    int convertColor(int color)
    {
        return color & 0xFFF8F8F8;
    }
    int* buffer;
    override @property void useGRP(int page)
    {
        updateVM;
        super.useGRP(page);
        buffer = cast(int*)this.GRP[useGRP].surface.pixels;
    }
    override @property int useGRP()
    {
        return super.useGRP;
    }

    override void gpset(int page, int x, int y, uint color)
    {
        color = convertColor(color);
        auto wa = writeArea[petitcom.displaynum];
        int cx2 = wa.x + wa.w;
        int cy2 = wa.y + wa.h;
        if (x >= wa.x && y >= wa.y && x < cx2 && y < cy2)
        {
            buffer[y * width + x] = color;
        }
        df = true;
    }

    import std.math;
    override void gline(int page, int x, int y, int x2, int y2, uint color)
    {
        color = convertColor(color);
        int dx = abs(x2 - x);
        int dy = abs(y2 - y);
        int sx, sy;
        if (x < x2)
            sx = 1;
        else
            sx = -1;
        if (y < y2)
            sy = 1;
        else
            sy = -1;
        int err = dx - dy;

        auto wa = writeArea[petitcom.displaynum];
        int cx2 = wa.x + wa.w;
        int cy2 = wa.y + wa.h;
        while (true)
        {
            if (x >= wa.x && y >= wa.y && x < cx2 && y < cy2)
                buffer[y * width + x] = color;
            if (x == x2 && y == y2) break;
            int e2 = 2 * err;
            if (e2 > -dy)
            {
                err = err - dy;
                x = x + sx;
            }
            if (e2 <  dx)
            {
                err = err + dx;
                y = y + sy;
            }
        }
        df = true;
    }

    override void gbox(int page, int x, int y, int x2, int y2, uint color)
    {
        color = convertColor(color);
        int sx, sy, ex, ey;
        if (x > x2)
        {
            sx = x2;
            ex = x;
        }
        else
        {
            sx = x;
            ex = x2;
        }
        if (y > y2)
        {
            sy = y2;
            ey = y;
        }
        else
        {
            sy = y;
            ey = y2;
        }
        auto wa = writeArea[petitcom.displaynum];
        int cx2 = wa.x + wa.w - 1;
        int cy2 = wa.y + wa.h - 1;
        void drawLine1(int y)
        {
            for (int x = sx; x <= ex; x++)
            {
                if (x >= wa.x && y >= wa.y && x <= cx2 && y <= cy2)
                    buffer[y * height + x] = color;
            }
        }
        drawLine1(sy);
        drawLine1(ey);
        void drawLine2(int x)
        {
            for (int y = sy; y <= ey; y++)
            {
                if (x >= wa.x && y >= wa.y && x <= cx2 && y <= cy2)
                    buffer[y * width + x] = color;
            }
        }
        drawLine2(ex);
        drawLine2(sx);
        df = true;
    }

    override void gfill(int page, int x, int y, int x2, int y2, uint color)
    {
        color = convertColor(color);
        int sx, sy, ex, ey;
        if (x > x2)
        {
            sx = x2;
            ex = x;
        }
        else
        {
            sx = x;
            ex = x2;
        }
        if (y > y2)
        {
            sy = y2;
            ey = y;
        }
        else
        {
            sy = y;
            ey = y2;
        }
        auto wa = writeArea[petitcom.displaynum];
        int cx2 = wa.x + wa.w - 1;
        int cy2 = wa.y + wa.h - 1;
        //clipping
        if (wa.x > sx)
        {
            if (wa.x > ex)
            {
                return;
            }
            sx = wa.x;
        }
        if (cx2 < ex)
        {
            if (cx2 < sx)
            {
                return;
            }
            ex = cx2;
        }
        if (wa.y > sy)
        {
            if (wa.y > ey)
            {
                return;
            }
            sy = wa.y;
        }
        if (cy2 < ey)
        {
            if (cy2 < sy)
            {
                return;
            }
            ey = cy2;
        }
        for (y = sy; y <= ey; y++)
        {
            (buffer + y * width + sx)[0..(ex - sx + 1)] = color;
        }
        df = true;
    }

    override void gcls(int page, uint color)
    {
        color = convertColor(color);
        gfill(page, 0, 0, width - 1, height - 1, color);
    }

    override void gpaint(int page, int x, int y, uint color)
    {
        color = convertColor(color);
    }

    override void gcircle(int page, int x0, int y0, int r, uint color)
    {
        color = convertColor(color);
        /*== http://fussy.web.fc2.com/algo/algo2-1.htm ==*/
        int x = r;
        int y = 0;
        int F = -2 * r + 3;

        void pset(int x, int y, int color)
        {
            auto wa = writeArea[petitcom.displaynum];
            int cx2 = wa.x + wa.w;
            int cy2 = wa.y + wa.h;
            if (x >= wa.x && y >= wa.y && x < cx2 && y < cy2)
            {
                buffer[y * width + x] = color;
            }
        }
        while (x >= y)
        {
            pset(x0 + x, y0 + y, color);
            pset(x0 - x, y0 + y, color);
            pset(x0 + x, y0 - y, color);
            pset(x0 - x, y0 - y, color);
            pset(x0 + y, y0 + x, color);
            pset(x0 - y, y0 + x, color);
            pset(x0 + y, y0 - x, color);
            pset(x0 - y, y0 - x, color);
            if (F >= 0)
            {
                x--;
                F -= 4 * x;
            }
            y++;
            F += 4 * y + 2;
        }
        /*== http://fussy.web.fc2.com/algo/algo2-1.htm ==*/
        df = true; 
    }

    override void gcircle(int page, int x, int y, int r, int startr, int endr, int flag, uint color)
    {
        color = convertColor(color);
    }

    override void gputchr(int page, int x, int y, int text, int scalex, int scaley, uint color)
    {
        color = convertColor(color);
        drawCharacter(x, y, scalex, scaley, color, cast(wchar)text);
        df = true;
    }

    int mulColor(int color, int color2)
    {
        ubyte r1, g1, b1, a1;
        ubyte r2, g2, b2, a2;
        PetitComputer.RGBRead(color, r1, g1, b1, a1);
        PetitComputer.RGBRead(color2, r2, g2, b2, a2);
        r1 = cast(ubyte)((r1 * r2) / 255);
        g1 = cast(ubyte)((g1 * g2) / 255);
        b1 = cast(ubyte)((b1 * b2) / 255);
        if (a2 && a1)
            a1 = 255;
        else
            a1 = 0;
        return PetitComputer.RGB(a1, r1, g1, b1);
    }
    bool clipXYWH(SDL_Rect wa, int x, int y, int w, int h, out int sx, out int sy, out int w2, out int h2)
    {
        int cx2 = wa.x + wa.w;
        int cy2 = wa.y + wa.h;
        w2 = w;
        h2 = h;
        //clipping
        if (wa.x > x)
        {
            sx = wa.x - x;
            w2 -= sx;
            if (sx >= w)
            {
                return true;
            }
        }
        if (wa.w + wa.x < x + sx + w2)
        {
            w2 = w2 - ((x + sx + w2) - (wa.w + wa.x));
            if (w < 1)
            {
                return true;
            }
        }
        if (wa.y > y)
        {
            sy = wa.y - y;
            h2 -= sy;
            if (sy >=  h)
            {
                return true;
            }
        }
        if (wa.h + wa.y < y + sy + h2)
        {
            h2 = h2 - ((y + sy + h2) - (wa.h + wa.y));
            if (h < 1)
            {
                return true;
            }
        }
        return false;
    }
    void drawCharacter(int x, int y, int scalex, int scaley, uint color, immutable wchar c)
    {
        auto rect = petitcom.console.fontTable[c];
        int[8 * 8] font;
        auto wa = writeArea[petitcom.displaynum];
        int cx2 = wa.x + wa.w;
        int cy2 = wa.y + wa.h;
        int sx, sy, w = rect.w * scalex, h = rect.h * scaley;
        //clipping
        if (wa.x > x)
        {
            sx = wa.x - x;
            w -= sx;
            if (sx >=  rect.w)
            {
                return;
            }
        }
        if (wa.w + wa.x < x + sx + w)
        {
            w = w - ((x + sx + w) - (wa.w + wa.x));
            if (w < 1)
            {
                return;
            }
        }
        if (wa.y > y)
        {
            sy = wa.y - y;
            h -= sy;
            if (sy >=  rect.h)
            {
                return;
            }
        }
        if (wa.h < h)
        {
            h = h - ((y + sy + h) - (wa.h + wa.y));
            if (h < 1)
            {
                return;
            }
        }
        int* grpfbuffer = cast(int*)petitcom.console.GRPF.surface.pixels;
        if (scalex == 1 && scaley == 1)
        {
            for (int i = sy; i < sy + h; i ++)
            {
                for (int j = sx; j < sx + w; j++)
                {
                    font[i * 8 + j] = mulColor(grpfbuffer[rect.x + j + (rect.y + i) * GRPFWidth], color);
                }
            }
            for (int iy = sy; iy < sy + h; iy++)
            {
                for (int ix = sx; ix < sx + w; ix++)
                {
                    if (font[iy * 8 + ix] >> 24/*is trans*/)
                    {
                        (buffer + (y + iy) * width + x + ix)[0] = font[iy * 8 + ix];
                    }
                }
            }
            return;
        }
        for (int i = sy / scaley; i < (sy + h) / scaley; i ++)
        {
            for (int j = sx / scalex; j < (sx + w) / scalex; j++)
            {
                font[i * 8 + j] = mulColor(grpfbuffer[rect.x + j + (rect.y + i) * GRPFWidth], color);
            }
        }
        for (int iy = sy; iy < sy + h; iy++)
        {
            for (int ix = sx; ix < sx + w; ix++)
            {
                if (font[iy / scaley * 8 + ix / scalex] >> 24/*is trans*/)
                {
                    (buffer + (y + iy) * width + x + ix)[0] = font[iy / scaley * 8 + ix / scalex];
                }
            }
        }
    }
    override void gputchr(int page, int x, int y, wstring text, int scalex, int scaley, uint color)
    {
        color = convertColor(color);
        foreach (i, c; text)
        {
            drawCharacter(x + scalex * cast(int)i * 8, y, scalex, scaley, color, c);
        }
        df = true;
    }

    override int gspoit(int page, int x, int y)
    {
        return buffer[y * height + x];
    }

    void gsaveTempl(T)(int savepage, int x, int y, int w, int h, T array, int flag)
    {
        int arrayH = h, arrayW = w;
        int sx, sy;
        int* buffer = cast(int*)GRP[savepage].surface.pixels;
        for (int iy = sy; iy < h; iy++)
        {
            for (int ix = sx; ix < w; ix++)
            {
                if (x >= 0 && y >= 0 && x < width && y < height)
                {
                    auto c = *(buffer + (iy + y) * width + (x + ix));
                    array[iy * arrayW + ix] = flag ? ARGB32ToRGBA16Color(c) : c;
                }
                else
                    array[iy * arrayW + ix] = 0;
            }
        }
    }

    override void gsave(int savepage, int x, int y, int w, int h, double[] array, int flag)
    {
        gsaveTempl(savepage, x, y, w, h, array, flag);
    }

    override void gsave(int savepage, int x, int y, int w, int h, int[] array, int flag)
    {
        gsaveTempl(savepage, x, y, w, h, array, flag);
    }

    void gloadTempl(T)(int x, int y, int w, int h, T array, int flag, int copymode)
    {
        int arrayH = h, arrayW = w;
        int sx, sy;
        if (clipXYWH(writeArea[petitcom.displaynum], x, y, w, h, sx, sy, w, h))
            return;
        for (int iy = sy; iy < sy + h; iy++)
        {
            for (int ix = sx; ix < sx + w; ix++)
            {
                auto c = cast(int)array[iy * arrayW + ix];
                if (flag)
                    c = RGBA16ToARGB32Color(c);
                c = convertColor(c);
                if (copymode || c >> 24)
                    *(buffer + (iy + y) * width + (x + ix)) = c;
            }
        }
        df = true;
    }

    override void gload(int x, int y, int w, int h, int[] array, int flag, int copymode)
    {
        gloadTempl(x, y, w, h, array, flag, copymode);
    }

    override void gload(int x, int y, int w, int h, double[] array, int flag, int copymode)
    {
        gloadTempl(x, y, w, h, array, flag, copymode);
    }

    void gloadPalette(T, T2)(int x, int y, int w, int h, T[] array, T2[] palette, int copymode)
    if ((is(T == int) || is(T == double)) && (is(T2 == int) || is(T2 == double)))
    {
        int arrayH = h, arrayW = w;
        int sx, sy;
        if (clipXYWH(writeArea[petitcom.displaynum], x, y, w, h, sx, sy, w, h))
            return;
        for (int iy = sy; iy < sy + h; iy++)
        {
            for (int ix = sx; ix < sx + w; ix++)
            {
                auto c = cast(int)palette[cast(int)array[iy * arrayW + ix]];
                c = convertColor(c);
                if (copymode || c >> 24)
                    *(buffer + (iy + y) * width + (x + ix)) = c;
            }
        }
        df = true;
    }
    //incomplete
    override void gcopy(int srcpage, int x1, int y1, int x2, int y2, int x3, int y3, int cpmode)
    {
        import std.algorithm;
        auto tempbuffer = paint.buffer;//aa
        if (x1 > x2)
            swap(x1, x2);
        if (y1 > y2)
            swap(y1, y2);
        int w = x2 - x1 + 1, h = y2 - y1 + 1;
        gsaveTempl(srcpage, x1, y1, w, h, tempbuffer, 0);
        gloadTempl(x3, y3, w, h, tempbuffer, 0, cpmode);
    }
    override void gtri(int x1, int y1, int x2, int y2, int x3, int y3, int color)
    {
        import std.algorithm, std.typecons, std.math;
        df = true;
        Tuple!(int, "x", int, "y") drawSize = tuple(511, 511);
        void pset(int x, int y)
        {
            auto wa = writeArea[petitcom.displaynum];
            int cx2 = wa.x + wa.w;
            int cy2 = wa.y + wa.h;
            if (x >= wa.x && y >= wa.y && x < cx2 && y < cy2)
            {
                buffer[y * width + x] = color;
            }
        }
        //====http://fussy.web.fc2.com/algo/polygon3_misc.htm====
        /*
        TriFill_XDraw : 三角形描画スキャンライン描画

        DrawingArea_IF& draw : 描画領域
        GPixelOp& pset : 点描画に使う関数オブジェクト
        pair<double, double> &l, &r : スキャンラインの両端座標の X 成分と増分の pair
        int& sy : 描画開始 Y 座標(描画終了時に次の Y 座標を返す)
        int ey : 描画終了 Y 座標
        */
        void TriFill_XDraw(ref Tuple!(double, double) l, ref Tuple!(double, double) r, ref int sy, int ey )
        {
            for ( ; sy < ey ; ++sy ) {
                int sx = cast(int)round( l[0]); // 描画開始 X 座標
                int ex = cast(int)round( r[0]); // 描画終了 X 座標

                // X 座標のクリッピング
                if ( sx < 0 ) sx = 0;
                if ( ex >= drawSize.x ) ex = drawSize.x - 1;

                // スキャンライン描画
                for ( ; sx <= ex ; ++sx )
                    pset(sx, sy);

                // X 座標の更新
                l[0] += l[1];
                r[0] += r[1];
            }
        }

        /*
        TriFill_Main : 三角形描画用 メイン・ルーチン

        DrawingArea_IF& draw : 描画領域
        GPixelOp& pset : 点描画に使う関数オブジェクト
        Coord<int> &top, &middle, &bottom : 三角形の頂角の座標(上側・中央・下側の順)
        */
        void TriFill_Main(const ref Tuple!(int, "x", int, "y") top, const ref Tuple!(int, "x", int, "y") middle, const ref Tuple!(int, "x", int, "y") bottom )
        {
            // 上側の頂点からの描画開始 X 座標(頂角が描画領域外の場合、異なる座標になる)
            double top_mid_x = top.x; // top - middle
            double top_btm_x = top.x; // top - bottom

            // 上側に水平な辺がある場合は中央の頂点で初期化する
            if ( top.y == middle.y )
                top_mid_x = middle.x;

            int sy = top.y;    // 描画開始 Y 座標
            int my = middle.y; // 中央の頂点の Y 座標
            int ey = bottom.y; // 描画終了 Y 座標

            // クリッピング

            // 上側の頂点が領域外の場合
            if ( top.y < 0 ) {
                sy = 0;
                // 上側から中央への辺をクリッピング
                if ( middle.y >= 0 ) {
                    if ( top.y != middle.y )
                        top_mid_x = cast(double)( middle.x - top.x ) * cast(double)middle.y / cast(double)( top.y - middle.y ) + cast(double)middle.x;
                } else {
                    if ( middle.y != bottom.y )
                        top_mid_x = cast(double)( bottom.x - middle.x ) * cast(double)bottom.y / cast(double)( middle.y - bottom.y ) + cast(double)bottom.x;
                }
                // 上側から下側への辺をクリッピング
                if ( top.y != bottom.y )
                    top_btm_x = cast(double)( bottom.x - top.x ) * cast(double)bottom.y / cast(double)( top.y - bottom.y ) + cast(double)bottom.x;
            }

            // 下側の頂点が領域外の場合は描画終了 Y 座標を描画領域内にする
            if ( bottom.y >= drawSize.y )
                ey = drawSize.y - 1;

            // X 座標に対する増分
            double top_mid_a = ( middle.y != top.y ) ?
                cast(double)( middle.x - top.x ) / cast(double)( middle.y - top.y ) : 0;       // top - middle
            double mid_btm_a = ( middle.y != bottom.y ) ?
                cast(double)( middle.x - bottom.x ) / cast(double)( middle.y - bottom.y ) : 0; // middle - bottom
            double top_btm_a = ( top.y != bottom.y ) ?
                cast(double)( top.x - bottom.x ) / cast(double)( top.y - bottom.y ) : 0;       // top - bottom

            // 描画開始 X 座標とその増分の pair
            Tuple!(double, double) top_mid = tuple( top_mid_x, top_mid_a ); // top - middle
            Tuple!(double, double) top_btm = tuple( top_btm_x, top_btm_a ); // top - bottom

            // 中央の頂点が右向きか左向きかを判定して、各辺が左側・右側ののいずれかを決定する
            // 中央の頂点を通る水平線が、上側・下側を通る直線と交わる点の X 座標
            int splitLine_x = ( top.y != bottom.y ) ?
                ( top.x - bottom.x ) * ( middle.y - top.y ) / ( top.y - bottom.y ) + top.x :
            bottom.x; // 中央・下側の Y 座標が等しい場合、下側の X 座標
            Tuple!(double, double)* l = ( middle.x < splitLine_x ) ? &top_mid : &top_btm; // 左側
            Tuple!(double, double)* r = ( middle.x < splitLine_x ) ? &top_btm : &top_mid; // 右側

            // 描画開始
            TriFill_XDraw(*l, *r, sy, my );
            top_mid[1] = mid_btm_a;
            TriFill_XDraw(*l, *r, sy, ey + 1 );
        }

        /*
        TriFill : 三角形描画用ルーチン 前処理

        DrawingArea_IF& draw : 描画領域
        GPixelOp& pset : 点描画に使う関数オブジェクト
        Coord<int> c1, c2, c3 : 三角形の頂点
        */
        void TriFill(Tuple!(int, "x", int, "y") c1, Tuple!(int, "x", int, "y") c2, Tuple!(int, "x", int, "y") c3 )
        {
            // Y 座標で昇順にソート
            if ( c1.y > c2.y ) swap( c1, c2 );
            if ( c1.y > c3.y ) swap( c1, c3 );
            if ( c2.y > c3.y ) swap( c2, c3 );

            // ポリゴンが描画領域外なら処理しない
            if ( c1.y >= drawSize.y ) return;
            if ( c3.y < 0 ) return;

            // 描画ルーチン メインへ
            TriFill_Main(c1, c2, c3 );
        }
        //====http://fussy.web.fc2.com/algo/polygon3_misc.htm====
        TriFill(Tuple!(int, "x", int, "y")(x1, y1), Tuple!(int, "x", int, "y")(x2, y2), Tuple!(int, "x", int, "y")(x3, y3));
    }
}
