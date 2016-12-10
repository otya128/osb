module otya.smilebasic.console;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl;
import derelict.opengl3.gl3;
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

class Console
{

    int fontWidth;
    int fontHeight;
    int consoleWidth;
    int consoleHeight;
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
    int consoleForeColor, consoleBackColor;
    bool showCursor;
    bool animationCursor;
    SDL_Rect[] fontTable = new SDL_Rect[65536];
    GraphicPage GRPF;
    PetitComputer petitcom;
    bool[2] visibles = [true, true];
    Object consoleSync = new Object();

    int width()
    {
        return fontWidth;
    }
    void width(int w)
    {
        synchronized(this)
        {
            fontWidth = fontHeight = w;
            consoleWidth = petitcom.screenWidth / fontWidth;
            consoleHeight = petitcom.screenHeight / fontHeight;
            console = new ConsoleCharacter[][][petitcom.currentDisplay.rect.length];
            consoleForeColor = 15;//#T_WHITE
            for(int i = 0; i < console.length; i++)
            {
                console[i] = new ConsoleCharacter[][petitcom.currentDisplay.rect[i].h / fontHeight];
                for(int j = 0; j < console[i].length; j++)
                {
                    console[i][j] = new ConsoleCharacter[petitcom.currentDisplay.rect[i].w / fontWidth];
                    console[i][j][] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
                }
            }
            CSRXs[] = 0;
            CSRYs[] = 0;
            CSRZs[] = 0;
            display(petitcom.displaynum);
        }
    }
    //FIXME:画面サイズが変わらないと画面はクリアされないのにクリアされる
    void changeDisplay(ref Display display)
    {
        width(fontWidth);
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
        width = 8;

        for(int i = 0; i < consoleColor.length; i++)
            consoleColorGL[i] = petitcom.toGLColor(consoleColor[i]);

    }
    void createFontTable()
    {
        auto file = File(petitcom.fontTableFile, "w");
        std.algorithm.fill(fontTable, SDL_Rect(488,120, 8, 8));//TODO:480,120とどっちが使われているかは要調査
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
            }
        }
    }
    void loadFontTable()
    {
        import std.csv;
        import std.typecons;
        std.algorithm.fill(fontTable, SDL_Rect(488,120, 8, 8));//TODO:480,120とどっちが使われているかは要調査
        auto csv = csvReader!(Tuple!(int,int,int))(readText(petitcom.fontTableFile));
        foreach(record; csv)
        {
            fontTable[record[0]].x = record[1];
            fontTable[record[0]].y = record[2];
            fontTable[record[0]].w = 8;
            fontTable[record[0]].h = 8;
        }
    }
    void cls()
    {
        for(int i = 0; i < consoleC.length; i++)
        {
            consoleC[i][] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
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
    void adjustScreen()
    {
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();
        glScalef(fontWidth / 8f, fontHeight / 8f, 1);
    }
    void render()
    {
        adjustScreen();
        scope (exit)
        {
            glLoadIdentity();
            petitcom.chScreen(0, 0, 400, 240);
        }
        synchronized(this)
        {
            glBindTexture(GL_TEXTURE_2D, GRPF.glTexture);
            for (int i = 0; i < petitcom.currentDisplay.rect.length; i++)
            {
                if (!visibles[i] && !showCursor)
                    continue;
                petitcom.chRenderingDisplay(i);
                int consoleWidth = petitcom.currentDisplay.rect[i].w / fontWidth;
                int consoleHeight = petitcom.currentDisplay.rect[i].h / fontHeight;
                glDisable(GL_TEXTURE_2D);
                glBegin(GL_QUADS);
                for(int y = 0; y < consoleHeight; y++)
                    for(int x = 0; x < consoleWidth; x++)
                    {
                        auto back = consoleColorGL[console[i][y][x].backColor];
                        if(back)
                        {
                            glColor4ubv(cast(ubyte*)&back);
                            glVertex3f(x * 8, y * 8 + 8, 1024);
                            glVertex3f(x * 8, y * 8, 1024);
                            glVertex3f(x * 8 + 8, y * 8, 1024);
                            glVertex3f(x * 8 + 8, y * 8 + 8, 1024);
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
                glEnable(GL_TEXTURE_2D);

                glBegin(GL_QUADS);
                for(int y = 0; y < consoleHeight; y++)
                    for(int x = 0; x < consoleWidth; x++)
                    {
                        drawCharacter(x, y, console[i][y][x]);
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
    ConsoleAttribute attr;
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
                    consoleC[CSRY][CSRX..t] = ConsoleCharacter(0, consoleForeColor, consoleBackColor, attr, CSRZ);
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
                consoleC[CSRY][CSRX] = ConsoleCharacter(c, consoleForeColor, consoleBackColor, attr, CSRZ);
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
                auto tmp = consoleC[0];
                for(int i = 0; i < consoleHeightC - 1; i++)
                {
                    consoleC[i] = consoleC[i + 1];
                }
                consoleC[consoleHeightC - 1] = tmp;
                tmp[] = ConsoleCharacter(0, consoleForeColor, consoleBackColor, attr, CSRZ);
                CSRY = consoleHeightC - 1;
            }
        }
    }
}