module otya.smilebasic.bg;
import otya.smilebasic.petitcomputer;
import otya.smilebasic.error;
import otya.smilebasic.sprite;
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
    int bgcolor;
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
        bgcolor = 0xffffffff;
        initBGAnimationTable();
    }
    void render(int display, float disw, float dish)
    {
        animation();
        if (!show)
            return;
        float aspect = disw / dish;
        disw /= 2;
        dish /= 2;
        float z = offsetz;
        {
            ubyte r, g, b, a;
            petitcom.RGBRead(bgcolor, r, g, b, a);
            glColor4ub(r, g, b, 255);
        }
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
        scalex = 1;
        scaley = 1;
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
    void getScale(out double x, out double y)
    {
        x = this.scalex;
        y = this.scaley;
    }
    void rot(int rot)
    {
        this.r = rot;
    }
    int rot()
    {
        return cast(int)r;
    }
    void fill(int x, int y, int x2, int y2, int screendata)
    {
        import std.algorithm;
        int id = screendata & 4095;
        if(x > x2) swap(x, x2);
        if(y > y2) swap(y, y2);
        for(; y <= y2; y++)
            chip[x + y * width .. x2 + y * width + 1] = BGChip(id);
            /*for(int i = x; i <= x2; i++)
            {
                chip[i + y * width].i = id;
            }*/
    }
    void fill(int x, int y, int x2, int y2, ushort[] screendata)
    {
        import std.algorithm;
        if(x > x2) swap(x, x2);
        if(y > y2) swap(y, y2);
        int index = 0;
        if (screendata.length == 0)
        {
            fill(x, y, x2, y2, 0);
            return;
        }
        for(; y <= y2; y++)
            for(int i = x; i <= x2; i++)
            {
                chip[i + y * width] = BGChip(screendata[index] & 4095);
                index = (index + 1) % screendata.length;
            }
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
    import otya.smilebasic.vm;
    Callback callback;
    public void color(int color)
    {
        this.bgcolor = color;
    }
    public int color()
    {
        return this.bgcolor;
    }
    bool isAnim;
    SpriteAnimData[][SpriteAnimTarget.V + 1] anim;
    int[SpriteAnimTarget.V + 1] animindex;
    int[SpriteAnimTarget.V + 1] animloop;
    int[SpriteAnimTarget.V + 1] animloopcnt;
    void setAnimation(SpriteAnimData[] anim, SpriteAnimTarget sat, int loop)
    {
        this.anim[sat] = null;
        if(loop < 0)
        {
            throw new IllegalFunctionCall("BGANIM");
        }
        animloop[sat] = loop;
        animloopcnt[sat] = 0;
        animindex[sat] = 0;
        this.anim[sat] = anim;
        isAnim = true;
    }



    void bganim(wstring target, double[] data)
    {
        static import std.uni;
        bool relative = false;
        if(target[$ - 1..$] == "+")
        {
            target = target[0..$-1];
            relative = true;
        }
        target = std.uni.toUpper(target);
        if (!(target in bgAnimTarget))
            throw new IllegalFunctionCall("BGANIM");
        auto tgete = bgAnimTarget[target];
        bganim(tgete | (relative ? SpriteAnimTarget.relative : cast(SpriteAnimTarget)0), data);

    }
    SpriteAnimTarget[wstring] bgAnimTarget;
    void initBGAnimationTable()
    {
        bgAnimTarget = [
            "XY": SpriteAnimTarget.XY,
            "Z": SpriteAnimTarget.Z,
            "R": SpriteAnimTarget.R,
            "S": SpriteAnimTarget.S,
            "C": SpriteAnimTarget.C,
            "V": SpriteAnimTarget.V,
        ];
    }
    SpriteAnimTarget getBGAnimTarget(wstring target)
    {
        bool relative = false;
        if(target[$ - 1..$] == "+")
        {
            target = target[0..$-1];
            relative = true;
        }
        return bgAnimTarget[target] | (relative ? SpriteAnimTarget.relative : cast(SpriteAnimTarget)0);
    }
    void animation(SpriteAnimData* data, SpriteAnimTarget target)
    {
        if (!animationEnabled)
            return;
        auto frame = data.elapse;
        if(frame == 1)
        {
            if(!data.interpolation)
            {
                switch(target)
                {
                    case SpriteAnimTarget.XY:
                        offsetx = cast(int)data.data.x;
                        offsety = cast(int)data.data.y;
                        break;
                    case SpriteAnimTarget.Z:
                        offsetz = cast(int)data.data.z;
                        break;
                    case SpriteAnimTarget.R:
                        r = data.data.r;
                        break;
                    case SpriteAnimTarget.S:
                        scalex = data.data.scalex;
                        scaley = data.data.scaley;
                        break;
                    case SpriteAnimTarget.C:
                        break;
                    case SpriteAnimTarget.V:
                        break;
                    default:
                        break;
                }
            }
        }
        if(data.interpolation)
        {
            //線形補完する奴
            switch(target)
            {
                case SpriteAnimTarget.XY:
                    offsetx = cast(int)(data.old.x + ((data.data.x - data.old.x) / data.frame) * frame);
                    offsety = cast(int)(data.old.y + ((data.data.y - data.old.y) / data.frame) * frame);
                    break;
                case SpriteAnimTarget.Z:
                    offsetz = cast(int)(data.old.z + ((data.data.z - data.old.z) / data.frame) * frame);
                    break;
                case SpriteAnimTarget.R:
                    r = data.old.r + ((data.data.r - data.old.r) / data.frame) * frame;
                    break;
                case SpriteAnimTarget.S:
                    scalex = data.old.scalex + ((data.data.scalex - data.old.scalex) / data.frame) * frame;
                    scaley = data.old.scaley + ((data.data.scaley - data.old.scaley) / data.frame) * frame;
                    break;
                case SpriteAnimTarget.C:
                    break;
                case SpriteAnimTarget.V:
                    break;
                default:
                    break;
            }
        }
    }

    void animation()
    {
        if (!animationEnabled)
            return;
        foreach(i, ref d; anim)
        {
            if(!d) continue;//未定義
            SpriteAnimTarget target = cast(SpriteAnimTarget)i;
            int index = animindex[i];
            SpriteAnimData* data = &d[index];
            data.elapse = data.elapse + 1;
            auto frame = data.elapse;
            animation(data, target);
            if(frame >= data.frame)
            {
                animindex[i] = (animindex[i] + 1) % cast(int)d.length;
                data.elapse = 0;
                if(animloop[i] == 0)
                {
                    continue;
                }
                if(!animindex[i])
                {
                    animloop[i]++;
                    if(animloop[i] >= animloopcnt[i])
                    {
                        anim[i] = null;
                        continue;
                    }
                }
                continue;
            }
        }
    }
    bool animationEnabled = true;
    void bganim(SpriteAnimTarget target, double[] data)
    {
        synchronized (this)
        {
            bool relative;
            if(SpriteAnimTarget.relative & target)
            {
                relative = true;
                target ^= SpriteAnimTarget.relative;
            }
            int animcount = cast(int)data.length / ((target == SpriteAnimTarget.XY || target == SpriteAnimTarget.UV) ? 3 : 2);
            SpriteAnimData[] animdata = new SpriteAnimData[animcount];
            int j;
            int loop = 1;
            SpriteAnimData* old;
            for(int i = 0; i < data.length;)
            {
                i = animdata[j].load(i, this, target, data, old, relative);
                old = &animdata[j++];
                if(data.length - i == 1)
                {
                    //loop
                    loop = cast(int)data[i];
                    break;
                }
            }
            setAnimation(animdata, target, loop);
            if(animdata[0].frame == 1)
            {
                animindex[target]++;
                animation(&animdata[0], target);
                if(animcount == 1)
                {
                    if(loop > 1 || loop == 0)
                    {
                        animindex[target] = 0;
                        animloopcnt[target]++;
                    }
                    else
                    {
                        anim[target] = null;
                    }
                }
            }
        }
    }
}
