module otya.smilebasic.bg;
import otya.smilebasic.petitcomputer;
import otya.smilebasic.error;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;

struct BGChip
{
    int i;
    int screenData()
    {
        return i;
    }
    void screenData(int a)
    {
        i = a;
    }
}
//912枚まで描画されるみたい
//->899枚まで描画してその後は一番下のみ描画の様子
//縦から描画していそう
class BG
{
    BGChip[16384] chip;
    int offsetx, offsety, offsetz;
    int clipx, clipy, clipx2, clipy2;
    double scalex, scaley;
    double r;
    int homex, homey;
    int width, height;
    int rendermax = 899;
    PetitComputer petitcom;
    bool show;
    int chipWidth = 16;
    int chipHeight = 16;
    int display;
    this(PetitComputer pc)
    {
        chip[] = BGChip(0);
        width = 25;
        height = 35;
        petitcom = pc;
        scalex = 1;
        scaley = 1;
        r = 0;
        show = true;
    }
    void render(int display, float disw, float dish)
    {
        if (!show)
            return;
        float aspect = disw / dish;
        disw /= 2;
        dish /= 2;
        float z = offsetz;
        glColor3f(1.0, 1.0, 1.0);
        petitcom.chRenderingDisplay(display, clipx, clipx, clipx2 - clipx + 1, clipy2 - clipy + 1);
        glMatrixMode(GL_MODELVIEW);
        glLoadIdentity();

        glTranslatef(homex, homey, 0);
        glScalef(scalex, scaley, 1f);
        glRotatef( r, 0.0f, 0.0f, 1.0f );
        glTranslatef(-offsetx, -offsety, z);
        version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);
        //viewport
        //clipx,clipy
        int bgchipwidth = 512 / chipWidth;
        int bgchipheight = 512 / chipHeight;
        int bgchipwidth2 = petitcom.graphic.width / chipWidth;
        int bgchipheight2 = petitcom.graphic.height / chipHeight;
        int chipNumberMax = bgchipwidth * bgchipheight;
        int chipNumberMax2 = bgchipwidth2 * bgchipheight2;
        bool isHR = (petitcom.graphic.width > 512) || (petitcom.graphic.height > 512);
        glBegin(GL_QUADS);
        int rendercount = 0;
        for(int x = 0; x < width; x++)
        {
            version(none)
            {
                for(int y = 0; y < height; y++){}
            }
            for(int y = height - 1; y >= 0; y--)//下から描画してるのか?
            {
                BGChip bgc = chip[x + y * width];
                if(!bgc.i) continue;
                int u = (bgc.i % bgchipwidth) * chipWidth;
                int v = (bgc.i / bgchipheight) * chipHeight;
                if (bgc.i >= chipNumberMax)
                {
                    if (isHR)
                    {
                        if (bgc.i >= bgchipheight2 * bgchipwidth)
                        {
                            u += 512;
                            v %= petitcom.graphic.height;
                        }
                    }
                    else
                    {
                        u = ((bgc.i % chipNumberMax) % bgchipwidth) * chipWidth;
                        v = ((bgc.i % chipNumberMax) / bgchipheight) * chipHeight;
                    }
                }
                int u2 = u + chipWidth;
                int v2 = v + chipHeight;
                int w = chipWidth;
                int h = chipHeight;
                glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1 , v2 / (cast(float)petitcom.graphic.height) - 1);
                glVertex3f((x * w), (y * h + h), 0);
                glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);
                glVertex3f((x * w), (y * h), 0);
                glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);
                glVertex3f((x * w + w), (y * h), 0);
                glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v2 / (cast(float)petitcom.graphic.height) - 1);
                glVertex3f((x * w + w), (y * h + h), 0);
                rendercount++;
                /*if(rendercount >= 899)
                {
                    break;
                }*/
            }
        }
        glEnd();
        glLoadIdentity();
    }
    void put(int x, int y, int screendata)
    {
        int i = screendata & 4095;
        chip[x + y * width].i = i;
    }
    void clear()
    {
        chip[0 .. width * height] = BGChip(0);
    }
    void screen(int w, int h)
    {
        rot = 0;
        scalex = 0;
        scaley = 0;
        homex = 0;
        homey = 0;
        chipWidth = 16;
        chipHeight = 16;
        offsetx = offsety = offsetz = 0;
        //BGCLIP is not initialized
        this.width = w;
        this.height = h;
        this.clear();
    }
    void ofs(int x, int y, int z)
    {
        this.offsetx = x;
        this.offsety = y;
        this.offsetz = z;
    }
    void clip(int x, int y, int x2, int y2)
    {
        import std.algorithm : swap;
        if (x > x2)
        {
            swap(x, x2);
        }
        if (y > y2)
        {
            swap(y, y2);
        }
        this.clipx = x;
        this.clipy = y;
        this.clipx2 = x2;
        this.clipy2 = y2;
    }
    void clip()
    {
        this.clipx = 0;
        this.clipy = 0;
        this.clipx2 = petitcom.currentDisplay.rect[display].w - 1;
        this.clipy2 = petitcom.currentDisplay.rect[display].h - 1;
    }
    void home(int x, int y)
    {
        homex = x;
        homey = y;
    }
    void scale(double x, double y)
    {
        this.scalex = x;
        this.scaley = y;
    }
    void rot(double rot)
    {
        this.r = rot;
    }
    void fill(int x, int y, int x2, int y2, int screendata)
    {
        import std.algorithm;
        int id = screendata & 4095;
        if(x > x2) swap(x, x2);
        if(y > y2) swap(y, y2);
        for(; y <= y2; y++)
            chip[x + y * width .. x2 + y * width] = BGChip(id);
            /*for(int i = x; i <= x2; i++)
            {
                chip[i + y * width].i = id;
            }*/
    }
    int get(int x, int y, int flag)
    {
        if (flag)
        {
            return chip[x / chipWidth + y / chipHeight * width].screenData;
        }
        else
        {
            return chip[x + y * width].screenData;
        }
    }
    void save(T)(int x, int y, int w, int h, T[] array)
        if (is(T == int) || is(T == double))
        {
            int desti;
            for (int i = x; i < x + w; i++)
            {
                for (int j = y; j < y + h; j++)
                {
                    desti++;
                    int index = i + j * width;
                    if (index < 0)
                        continue;
                    array[desti - 1] = cast(int)chip[index].screenData;
                }
            }
        }
    void load(T)(int x, int y, int w, int h, T[] array, int charoff)
        if (is(T == int) || is(T == double))
        {
            int srci;
            for (int i = x; i < x + w; i++)
            {
                for (int j = y; j < y + h; j++)
                {
                    srci++;
                    int index = i + j * width;
                    if (index < 0)
                        continue;
                    auto scr = cast(int)array[srci - 1];
                    auto chr = ((scr & 0xFFF) + charoff) & /*mask?*/0xFFF;
                    chip[index].screenData = (scr & 0xF000) | chr;
                }
            }
        }
}
