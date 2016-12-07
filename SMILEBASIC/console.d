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
    ConsoleCharacter[][] console;
    ConsoleCharacter[][] consoleDisplay1;
    ConsoleCharacter[][] console4;
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

    int width()
    {
        return fontWidth;
    }
    void width(int w)
    {
        fontWidth = fontHeight = w;
        consoleWidth = petitcom.screenWidth / fontWidth;
        consoleHeight = petitcom.screenHeight / fontHeight;
        consoleWidthDisplay1 = petitcom.screenWidthDisplay1 / fontWidth;
        consoleHeightDisplay1 = petitcom.screenHeightDisplay1 / fontHeight;
        consoleWidth4 = 320 / fontWidth;
        consoleHeight4 = 480 / fontHeight;
        console = new ConsoleCharacter[][consoleHeight];
        consoleDisplay1 = new ConsoleCharacter[][consoleHeightDisplay1];
        console4 = new ConsoleCharacter[][consoleHeight4];
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
        for(int i = 0; i < console4.length; i++)
        {
            console4[i] = new ConsoleCharacter[consoleWidth4];
            console4[i][] = ConsoleCharacter(0, consoleForeColor, consoleBackColor);
        }
        CSRXs[] = 0;
        CSRYs[] = 0;
        CSRZs[] = 0;
        display(petitcom.displaynum);
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
        if(petitcom.xscreenmode == 2)
        {
            consoleHeightC = consoleHeight4;
            consoleWidthC = consoleWidth4;
            consoleC = console4;
            return;
        }
        if(number == 1)
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
    void drawCharacter(int x, int y, ConsoleCharacter ch)
    {
        import std.algorithm.mutation : swap;
        auto fore = consoleColorGL[ch.foreColor];
        auto rect = &fontTable[ch.character];
        ConsoleAttribute rot = ch.attr & ConsoleAttribute.TROT270;
        int z = ch.z;
        glColor4ubv(cast(ubyte*)&fore);
        float tx1 = (rect.x) / 512f - 1;
        float ty1 = (rect.y + 8) / 512f - 1;
        float tx2 = (rect.x + 8) / 512f - 1;
        float ty2 = (rect.y) / 512f - 1;
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
        }
        if(petitcom.xscreenmode == 2 && (visibles[0] || showCursor)/*XSCREEN4*/)
        {
            glBindTexture(GL_TEXTURE_2D, GRPF.glTexture);
            glDisable(GL_TEXTURE_2D);
            glBegin(GL_QUADS);
            for(int y = 0; y < consoleHeight4; y++)
                for(int x = 0; x < consoleWidth4; x++)
                {
                    auto back = consoleColorGL[console4[y][x].backColor];
                    if(back)
                    {
                        glColor4ubv(cast(ubyte*)&back);
                        glVertex3f(x * 8, y * 8 + 8, 1024);
                        glVertex3f(x * 8, y * 8, 1024);
                        glVertex3f(x * 8 + 8, y * 8, 1024);
                        glVertex3f(x * 8 + 8, y * 8 + 8, 1024);
                    }
                }
            if(showCursor && animationCursor)
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
            for(int y = 0; y < consoleHeight4; y++)
                for(int x = 0; x < consoleWidth4; x++)
                {
                    drawCharacter(x, y, console4[y][x]);
                }
            glEnd();
            return;
        }
        if (showCursor || visibles[0])
        {
            glBindTexture(GL_TEXTURE_2D, GRPF.glTexture);
            glDisable(GL_TEXTURE_2D);
            glBegin(GL_QUADS);
            for(int y = 0; y < consoleHeight; y++)
                for(int x = 0; x < consoleWidth; x++)
                {
                    auto back = consoleColorGL[console[y][x].backColor];
                    if(back)
                    {
                        glColor4ubv(cast(ubyte*)&back);
                        glVertex3f(x * 8, y * 8 + 8, 1024);
                        glVertex3f(x * 8, y * 8, 1024);
                        glVertex3f(x * 8 + 8, y * 8, 1024);
                        glVertex3f(x * 8 + 8, y * 8 + 8, 1024);
                    }
                }
            if(petitcom.displaynum == 0 && showCursor && animationCursor)
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
                    drawCharacter(x, y, console[y][x]);
                }
            glEnd();
            if(petitcom.xscreenmode != 1)
            {
                return;
            }
        }
        if (visibles[1] || showCursor)
        {
            //下画面
            petitcom.chScreen(40, 0, 400, 240);
            adjustScreen();
            glBindTexture(GL_TEXTURE_2D, GRPF.glTexture);
            glDisable(GL_TEXTURE_2D);
            glBegin(GL_QUADS);
            for(int y = 0; y < consoleHeightDisplay1; y++)
                for(int x = 0; x < consoleWidthDisplay1; x++)
                {
                    auto back = consoleColorGL[consoleDisplay1[y][x].backColor];
                    if(back)
                    {
                        glColor4ubv(cast(ubyte*)&back);
                        glVertex3f(x * 8, y * 8 + 8, 1024);
                        glVertex3f(x * 8, y * 8, 1024);
                        glVertex3f(x * 8 + 8, y * 8, 1024);
                        glVertex3f(x * 8 + 8, y * 8 + 8, 1024);
                    }
                }
            if(petitcom.displaynum == 1 && showCursor && animationCursor)
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
            for(int y = 0; y < consoleHeightDisplay1; y++)
                for(int x = 0; x < consoleWidthDisplay1; x++)
                {
                    drawCharacter(x, y, consoleDisplay1[y][x]);
                }
            glEnd();
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
            if(CSRX >= consoleWidthC || c == '\n')
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