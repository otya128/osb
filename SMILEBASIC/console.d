module otya.smilebasic.console;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl;
import otya.smilebasic.petitcomputer;
import std.string;
import std.stdio;
import std.file;
import std.conv;
import std.csv;
import std.net.curl;

struct ConsoleCharacter
{
    wchar character;
    int foreColor;
    int backColor;
    ConsoleAttribute attr;
    int z;
}

enum ConsoleAttribute
{
    TROT0 = 0,
    TROT90 = 1,
    TROT180= 2,
    TROT270 = 3,
    TREVH = 4,
    TREVV = 8,
}

struct FontRect
{
    int x, y, w, h;
    bool define = true;
}

class Console
{

    //width 16,16 => return 16
    int fontDefWidth()
    {
        return 8;
    }
    int fontDefHeight()
    {
        return 8;
    }
    int[2] fontWidths;
    int[2] fontHeights;
    int consoleWidthDisplay1;
    int consoleHeightDisplay1;
    int consoleWidth4;
    int consoleHeight4;
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
    ConsoleCharacter[][][] console;
    int[2] CSRXs;
    int[2] CSRYs;
    int[2] CSRZs;
    @property ref fontWidth()
    {
        return fontWidths[petitcom.displaynum];
    }
    @property int fontWidth(int value)
    {
        return fontWidths[petitcom.displaynum] = value;
    }
    @property ref fontHeight()
    {
        return fontHeights[petitcom.displaynum];
    }
    @property int fontHeight(int value)
    {
        return fontHeights[petitcom.displaynum] = value;
    }
    @property ref CSRX()
    {
        return CSRXs[petitcom.displaynum];
    }
    @property void CSRX(int value)
    {
        CSRXs[petitcom.displaynum] = value;
    }
    @property ref CSRY()
    {
        return CSRYs[petitcom.displaynum];
    }
    @property void CSRY(int value)
    {
        CSRYs[petitcom.displaynum] = value;
    }
    @property ref CSRZ()
    {
        return CSRZs[petitcom.displaynum];
    }
    @property void CSRZ(int value)
    {
        CSRZs[petitcom.displaynum] = value;
    }
    int[2] foreColors, backColors;
    @property ref foreColor()
    {
        return foreColors[petitcom.displaynum];
    }
    @property void foreColor(int value)
    {
        foreColors[petitcom.displaynum] = value;
    }
    @property ref backColor()
    {
        return backColors[petitcom.displaynum];
    }
    @property void backColor(int value)
    {
        backColors[petitcom.displaynum] = value;
    }

    struct IMEditInfo
    {
        wstring editingText;
        int start;
        int length;
    }
    IMEditInfo imEditInfo;
    void setIMEditInfo(wstring e, int s, int l)
    {
        imEditInfo.editingText = e;
        imEditInfo.start = s;
        imEditInfo.length = l;
    }

    bool showCursor;
    bool animationCursor;
    FontRect[] fontTable = new FontRect[65536];
    GraphicPage GRPF;
    PetitComputer petitcom;
    bool[2] visibles = [true, true];
    Object consoleSync = new Object();

    int width()
    {
        return fontWidth;
    }
    void resizeConsole()
    {
        console.length = petitcom.currentDisplay.rect.length;
        for(int i = 0; i < petitcom.currentDisplay.rect.length; i++)
        {
            auto h = petitcom.currentDisplay.rect[i].h / fontHeights[i];
            auto w = petitcom.currentDisplay.rect[i].w / fontWidths[i];
            if (!console[i] || console[i].length != h || console[i][0].length != w)
            {
                console[i] = new ConsoleCharacter[][h];
                for(int j = 0; j < console[i].length; j++)
                {
                    console[i][j] = new ConsoleCharacter[w];
                    console[i][j][] = ConsoleCharacter(0, foreColor, backColor);
                }
                CSRXs[i] = 0;
                CSRYs[i] = 0;
                CSRZs[i] = 0;
            }
        }
    }
    void initConsole()
    {
        fontWidths = 8;
        fontHeights = 8;
        CSRXs = 0;
        CSRYs = 0;
        CSRZs = 0;
        foreColors = 15;//#T_WHITE
        backColors = 0;
        attrs = ConsoleAttribute.TROT0;
        resizeConsole();
    }
    void width(int w)
    {
        synchronized(this)
        {
            cls();
            fontWidth = fontHeight = w;
            resizeConsole();
            display(petitcom.displaynum);
        }
    }
    void changeDisplay(ref Display display)
    {
        resizeConsole();
    }
    bool visible()
    {
        return visibles[petitcom.displaynum];
    }
    void visible(bool value)
    {
        visibles[petitcom.displaynum] = value;
    }
    this(PetitComputer p)
    {
        petitcom = p;
        initConsole();

        for(int i = 0; i < consoleColor.length; i++)
            consoleColorGL[i] = petitcom.toGLColor(consoleColor[i]);

    }
    void createFontTable()
    {
        auto file = File(petitcom.fontTableFile, "w");
        std.algorithm.fill(fontTable, FontRect(488,120, 8, 8, false));//TODO:480,120とどっちが使われているかは要調査
        for (int i = 1; i <= 16; i++)
        {
            string html = cast(string)get("http://smilebasic.com/supplements/unicode" ~ format("%02d",i));
            std.stdio.writeln("http://smilebasic.com/supplements/unicode" ~ format("%02d",i));
            int pos = 0, index;
            while(true)
            {
                pos = cast(int)html.indexOf("<tr>\r\n<th>U+");
                if(pos == -1) break;
                pos += "<tr>\r\n<th>U+".length;
                html = html[pos..$];
                writeln(index = html.parse!int(16));
                file.write(index, ',');
                pos = cast(int)html.indexOf("</td>\r\n<td>(");
                if(pos == -1) break;
                pos += "</td>\r\n<td>(".length;
                html = html[pos..$];
                writeln(fontTable[index].x = html.parse!int);
                file.write(fontTable[index].x, ',');
                pos = cast(int)html.indexOf(',');
                html = html[pos + 1..$];
                munch(html, " ");
                writeln(fontTable[index].y = html.parse!int);
                file.write(fontTable[index].y, '\n');
                fontTable[index].w = 8;
                fontTable[index].h = 8;
                fontTable[index].define = true;
            }
        }
    }
    void loadFontTable()
    {
        import std.csv;
        import std.typecons;
        std.algorithm.fill(fontTable, FontRect(488,120, 8, 8, false));//TODO:480,120とどっちが使われているかは要調査
        auto csv = csvReader!(Tuple!(int,int,int))(readText(petitcom.fontTableFile));
        foreach(record; csv)
        {
            fontTable[record[0]].x = record[1];
            fontTable[record[0]].y = record[2];
            fontTable[record[0]].w = 8;
            fontTable[record[0]].h = 8;
            fontTable[record[0]].define = true;
        }
    }
    void cls()
    {
        for(int i = 0; i < consoleC.length; i++)
        {
            consoleC[i][] = ConsoleCharacter(0, foreColor, backColor);
        }
        CSRX = 0;
        CSRY = 0;
        CSRZ = 0;
    }
    void display(int number)
    {
        synchronized(this)
        {
            consoleHeightC = petitcom.currentDisplay.rect[number].h / fontHeight;
            consoleWidthC = petitcom.currentDisplay.rect[number].w / fontWidth;
            consoleC = console[number];
        }
    }
    void drawCharacter(int x, int y, ConsoleCharacter ch)
    {
        import std.algorithm.mutation : swap;
        auto fore = consoleColorGL[ch.foreColor];
        auto rect = &fontTable[ch.character];
        ConsoleAttribute rot = ch.attr & ConsoleAttribute.TROT270;
        int z = ch.z;
        glColor4ubv(cast(ubyte*)&fore);
        float tx1 = (rect.x) / (cast(float)petitcom.graphic.GRPFWidth) - 1;
        float ty1 = (rect.y + 8) / (cast(float)petitcom.graphic.GRPFHeight) - 1;
        float tx2 = (rect.x + 8) / (cast(float)petitcom.graphic.GRPFWidth) - 1;
        float ty2 = (rect.y) / (cast(float)petitcom.graphic.GRPFHeight) - 1;
        int x1 = x * 8;
        int x2 = x * 8 + 8;
        int y1 = y * 8;
        int y2 = y * 8 + 8;
        if (ch.attr & ConsoleAttribute.TREVH)
            swap(x1, x2);
        if (ch.attr & ConsoleAttribute.TREVV)
            swap(y1, y2);
        if (rot == ConsoleAttribute.TROT0)
        {
            glTexCoord2f(tx1 , ty1);
            glVertex3i(x1, y2, z);
            glTexCoord2f(tx1, ty2);
            glVertex3i(x1, y1, z);
            glTexCoord2f(tx2, ty2);
            glVertex3i(x2, y1, z);
            glTexCoord2f(tx2, ty1);
            glVertex3i(x2, y2, z);
        }
        if (rot == ConsoleAttribute.TROT90)
        {
            glTexCoord2f(tx2, ty1);
            glVertex3i(x1, y2, z);
            glTexCoord2f(tx1 , ty1);
            glVertex3i(x1, y1, z);
            glTexCoord2f(tx1, ty2);
            glVertex3i(x2, y1, z);
            glTexCoord2f(tx2, ty2);
            glVertex3i(x2, y2, z);
        }
        if (rot == ConsoleAttribute.TROT180)
        {
            glTexCoord2f(tx2, ty2);
            glVertex3i(x1, y2, z);
            glTexCoord2f(tx2, ty1);
            glVertex3i(x1, y1, z);
            glTexCoord2f(tx1 , ty1);
            glVertex3i(x2, y1, z);
            glTexCoord2f(tx1, ty2);
            glVertex3i(x2, y2, z);
        }
        if (rot == ConsoleAttribute.TROT270)
        {
            glTexCoord2f(tx1, ty2);
            glVertex3i(x1, y2, z);
            glTexCoord2f(tx2, ty2);
            glVertex3i(x1, y1, z);
            glTexCoord2f(tx2, ty1);
            glVertex3i(x2, y1, z);
            glTexCoord2f(tx1 , ty1);
            glVertex3i(x2, y2, z);
        }
    }
    void adjustScreen(int disp)
    {
        glMatrixMode(GL_MODELVIEW);
        glPopMatrix();
        glPushMatrix();
        glScalef(fontWidths[disp] / 8f, fontHeights[disp] / 8f, 1);
    }
    void render()
    {
        glMatrixMode(GL_MODELVIEW);
        glPushMatrix();
        scope (exit)
        {
            glMatrixMode(GL_MODELVIEW);
            glPopMatrix();
        }
        synchronized(this)
        {
            glBindTexture(GL_TEXTURE_2D, GRPF.glTexture);
            for (int i = 0; i < petitcom.currentDisplay.rect.length; i++)
            {
                if (!visibles[i] && !showCursor)
                    continue;
                petitcom.chRenderingDisplay(i);
                adjustScreen(i);
                int consoleWidth = petitcom.currentDisplay.rect[i].w / fontWidths[i];
                int consoleHeight = petitcom.currentDisplay.rect[i].h / fontHeights[i];
                glEnable(GL_TEXTURE_2D);

                glBegin(GL_QUADS);
                if (i == 0 && !imEditInfo.editingText.empty)
                {
                    foreach (j, c; imEditInfo.editingText)
                    {
                        ConsoleCharacter cc;
                        cc.character = c;
                        cc.z = -256;
                        if (imEditInfo.start <= j && (imEditInfo.start + imEditInfo.length > j || imEditInfo.length == 0))
                        {
                            cc.foreColor = 10;
                        }
                        else
                        {
                            cc.foreColor = 1;
                        }
                        drawCharacter(cast(int)j, CSRYs[0], cc);
                    }
                }
                for(int y = 0; y < consoleHeight; y++)
                    for(int x = 0; x < consoleWidth; x++)
                    {
                        drawCharacter(x, y, console[i][y][x]);
                    }
                glEnd();
                glDisable(GL_TEXTURE_2D);
                glBegin(GL_QUADS);

                if (i == 0 && !imEditInfo.editingText.empty)
                {
                    foreach (j, c; imEditInfo.editingText)
                    {
                        auto x = j, y = CSRYs[0];
                        auto back = consoleColorGL[15];
                        if (imEditInfo.start <= j && (imEditInfo.start + imEditInfo.length > j || imEditInfo.length == 0))
                        {
                            back = consoleColorGL[1];
                        }
                        if(back)
                        {
                            glColor4ubv(cast(ubyte*)&back);
                            glVertex3f(x * 8, y * 8 + 8, -256);
                            glVertex3f(x * 8, y * 8, -256);
                            glVertex3f(x * 8 + 8, y * 8, -256);
                            glVertex3f(x * 8 + 8, y * 8 + 8, -256);
                        }
                    }
                }
                for(int y = 0; y < consoleHeight; y++)
                    for(int x = 0; x < consoleWidth; x++)
                    {
                        auto back = consoleColorGL[console[i][y][x].backColor];
                        if(back)
                        {
                            glColor4ubv(cast(ubyte*)&back);
                            glVertex3f(x * 8, y * 8 + 8, console[i][y][x].z);
                            glVertex3f(x * 8, y * 8, console[i][y][x].z);
                            glVertex3f(x * 8 + 8, y * 8, console[i][y][x].z);
                            glVertex3f(x * 8 + 8, y * 8 + 8, console[i][y][x].z);
                        }
                    }
                if(petitcom.displaynum == i && showCursor && animationCursor)
                {
                    glColor4ubv(cast(ubyte*)&consoleColorGL[15]);
                    glVertex3f((CSRX * 8), (CSRY * 8 + 8), -256);
                    glVertex3f((CSRX * 8), (CSRY * 8), -256);
                    glVertex3f((CSRX * 8 + 2), (CSRY * 8), -256);
                    glVertex3f((CSRX * 8 + 2), (CSRY * 8 + 8), -256);
                }
                glEnd();
            }
        }
    }
    void print(T...)(T args)
    {
        foreach(i; args)
        {
            printString(i.to!wstring);
        }
    }
    //0<=TABSTEP<=16
    int TABSTEP = 4;
    ConsoleAttribute[2] attrs;
    ConsoleAttribute attr()
    {
        return attrs[petitcom.displaynum];
    }
    void attr(ConsoleAttribute ca)
    {
        attrs[petitcom.displaynum] = ca;
    }
    int tab;
    void printString(wstring text)
    {
        //consolem.lock();
        //scope(exit) consolem.unlock();
        //write(text);
        foreach(wchar c; text)
        {
            if(CSRX == consoleWidthC)
            {
                CSRX = 0;
                CSRY++;
                if(CSRY >= consoleHeightC)
                {
                    scrollY1;
                    CSRY = consoleHeightC - 1;
                }
            }
            if(CSRY >= consoleHeightC)
            {
                CSRY = consoleHeightC - 1;
            }
            if(c == '\t')
            {
                import std.algorithm : min;
                if(tab == 2 && CSRX == 0)
                {
                    CSRX--;
                }
                else
                {
                    auto t = min(CSRX + TABSTEP - CSRX % TABSTEP, consoleWidthC - 1);
                    consoleC[CSRY][CSRX..t] = ConsoleCharacter(0, foreColor, backColor, attr, CSRZ);
                    CSRX += TABSTEP - (CSRX % TABSTEP) - 1;
                    if(CSRX + 1 >= consoleWidthC)
                    {
                        CSRX = consoleWidthC - 2;
                    }
                    tab = true;
                }
            }
            else if(c != '\n')
            {
                consoleC[CSRY][CSRX] = ConsoleCharacter(c, foreColor, backColor, attr, CSRZ);
                tab = tab ? 2 : 0;
            }
            CSRX++;
            if(CSRX > consoleWidthC || c == '\n')
            {
                CSRX = 0;
                CSRY++;
            }
            if(CSRY >= consoleHeightC)
            {
                scrollY1;
                CSRY = consoleHeightC - 1;
            }
        }
    }
    void scrollY1()
    {
        auto tmp = consoleC[0];
        for(int i = 0; i < consoleHeightC - 1; i++)
        {
            consoleC[i] = consoleC[i + 1];
        }
        consoleC[consoleHeightC - 1] = tmp;
        tmp[] = ConsoleCharacter(0, foreColor, backColor, attr, CSRZ);
    }
    import std.range;
    void tonikakusugokutesutekinasaikyounaFill(T, T2)(T input, T2 v)
    {
        foreach (ref e; input)
        {
            e[] = v;
        }
    }
    void scroll(int x, int y)
    {
        import std.math;
        if (abs(x) >= consoleWidthC)
        {
            auto oldCSRX = CSRX;
            auto oldCSRY = CSRY;
            auto oldCSRZ = CSRZ;
            cls();
            CSRX = oldCSRX;
            CSRY = oldCSRY;
            CSRZ = oldCSRZ;
            return;
        }
        if (abs(y) >= consoleHeightC)
        {
            cls();
            return;
        }
        for (int i = 0; i < consoleHeightC; i++)
        {
            if (x > 0)
            {
                for (int j = x; j < consoleWidthC; j++)
                {
                    consoleC[i][j - x] = consoleC[i][j];
                }
                consoleC[i][$ - x..$] = ConsoleCharacter(0, foreColor, backColor);
            }
            else if (x < 0)
            {
                for (int j = consoleWidthC - 1; j >= -x; j--)
                {
                    consoleC[i][j] = consoleC[i][j + x];
                }
                consoleC[i][0..-x] = ConsoleCharacter(0, foreColor, backColor);
            }
        }
        if (y > 0)
        {
            for (int i = y; i < consoleHeightC; i++)
            {
                consoleC[i - y][] = consoleC[i][];
            }
            tonikakusugokutesutekinasaikyounaFill(consoleC[$ - y..$], ConsoleCharacter(0, foreColor, backColor));
        }
        else if (y < 0)
        {
            for (int i = consoleHeightC - 1; i >= -y; i--)
            {
                consoleC[i][] = consoleC[i + y][];
            }
            tonikakusugokutesutekinasaikyounaFill(consoleC[0..-y], ConsoleCharacter(0, foreColor, backColor));
        }
    }
    bool canDefine(ushort a)
    {
        return fontTable[a].define;
    }
    void define(T)(ushort code, T[] array)
    {
        import otya.smilebasic.graphic;
        if (!canDefine(code))
        {
            return;
        }
        auto buffer = cast(int*)GRPF.surface.pixels;
        auto w = GRPF.surface.w;
        auto h = GRPF.surface.h;
        auto font = fontTable[code];
        for (int y = 0; y < font.h; y++)
        {
            for (int x = 0; x < font.w; x++)
            {
                buffer[x + font.x + (font.y + y) * w] = Graphic.RGBA16ToARGB32Color(cast(int)array[x + y * font.w]);
            }
        }
        //update texture
        glBindTexture(GL_TEXTURE_2D, GRPF.glTexture);
        glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, w, h, GL_BGRA, GL_UNSIGNED_BYTE, buffer);
        glFlush();
    }
    void initGRPF()
    {
        if (GRPF)
        {
            GRPF.deleteGL();
            GRPF.deleteSDL();
        }
        GRPF = petitcom.graphic.createGRPF(petitcom.fontFile);
        petitcom.graphic.GRPFWidth = GRPF.surface.w;
        petitcom.graphic.GRPFHeight = GRPF.surface.h;
        GRPF.createTexture(petitcom.renderer, petitcom.textureScaleMode);
    }
}