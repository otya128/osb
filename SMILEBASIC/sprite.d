module otya.smilebasic.sprite;
import otya.smilebasic.petitcomputer;
import otya.smilebasic.error;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;
enum SpriteAttr
{
    none = 0,
    show =      0b00001,
    rotate90 =  0b00010,
    rotate180 = 0b00100,
    rotate270 = 0b00110,
    hflip =     0b01000,//yoko
    vflip =     0b10000,//tate
}
enum SpriteAnimTarget
{
    XY = 0,
    Z,
    UV,
    I,
    R,
    S,
    C,
    V,
    relative = 8,
}
struct SpriteAnimState
{
    union
    {
        struct
        {
            double x, y;
        }
        struct
        {
            double z;
        }
        struct
        {
            int u, v;
        }
        struct
        {
            int i;
        }
        struct
        {
            double r;
        }
        struct
        {
            double scalex, scaley;
        }
        struct
        {
            uint c;
        }
        struct
        {
            double var;
        }
    }
}

struct SpriteAnimData
{
    bool relative;//相対座標として扱うか
    int frame;//何フレームごとに動かすか
    int elapse;//何フレーム目か
    //int repeatcount;//何回目のループか
    //int loop;//何回ループするか(0で無限ループ)
    bool interpolation;//線形補完するかどうか
    SpriteAnimState data;
    SpriteAnimState old;
    int load(int i, ref SpriteData sprite, SpriteAnimTarget target, double[] data, SpriteAnimData* old)
    {
        this.frame = cast(int)data[i];
        if(this.frame < 0)
        {
            this.frame = -this.frame;
            interpolation = true;
        }
        if(this.frame == 0)
        {
            throw new IllegalFunctionCall("SPANIM");
        }
        i++;
        switch(target)
        {
            case SpriteAnimTarget.XY:
                this.data.x = cast(int)data[i++];
                this.data.y = cast(int)data[i++];
                this.old.x = old ? old.data.x : sprite.x;
                this.old.y = old ? old.data.y : sprite.y;
                break;
            case SpriteAnimTarget.Z:
                this.data.z = cast(int)data[i++];
                this.old.z = old ? old.data.z : sprite.z;
                break;
            case SpriteAnimTarget.UV:
                this.data.u = cast(int)data[i++];
                this.data.v = cast(int)data[i++];
                this.old.u = old ? old.data.u : sprite.u;
                this.old.v = old ? old.data.v : sprite.v;
                break;
            case SpriteAnimTarget.I:
                this.data.i = cast(int)data[i++];
                this.old.i = old ? old.data.i : sprite.defno;
                break;
            case SpriteAnimTarget.R:
                this.data.r = data[i++];
                this.old.r = old ? old.data.r : sprite.r;
                break;
            case SpriteAnimTarget.S:
                this.data.scalex = data[i++];
                this.data.scaley = data[i++];
                this.old.scalex = old ? old.data.scalex : sprite.scalex;
                this.old.scaley = old ? old.data.scaley : sprite.scaley;
                break;
            case SpriteAnimTarget.C:
                this.data.c = cast(uint)data[i++];
                break;
            case SpriteAnimTarget.V:
                this.data.var = data[i++];
                break;
            default:
                throw new IllegalFunctionCall("SPANIM");
        }
        return i;
    }
}
struct SpriteDef
{
    int u, v, w, h, hx, hy;
    SpriteAttr a;
}
struct SpriteData
{
    bool isAnim;
    int id;
    int defno;
    double x, y;
    int homex, homey;
    double z;/*!*/
    int u, v, w, h;//個々で保持してるみたい,SPSETをして後でSPDEFをしても変化しない
    uint color;
    double[8] var;
    SpriteAttr attr;
    bool define;//定義されてればtrue
    double scalex;
    double scaley;
    double r;
    this(bool flag)
    {
        define = false;
    }
    this(int id, int defno)
    {
        x = 0;
        y = 0;
        z = 0;
        r = 0;
        this.id = id;
        this.defno = defno;
        this.color = -1;
        this.attr = SpriteAttr.show;
        this.define = true;
        scalex = 1;
        scaley = 1;
    }
    this(int id, int u, int v, int w, int h)
    {
        x = 0;
        y = 0;
        z = 0;
        r = 0;
        this.id = id;
        this.u = u;
        this.v = v;
        this.w = w;
        this.h = h;
        this.color = -1;
        this.attr = SpriteAttr.show;
        this.define = true;
        scalex = 1;
        scaley = 1;
    }
    this(int id, ref SpriteDef spdef, int defno)
    {
        x = 0;
        y = 0;
        z = 0;
        r = 0;
        this.id = id;
        this.u = spdef.u;
        this.v = spdef.v;
        this.w = spdef.w;
        this.h = spdef.h;
        this.color = -1;
        this.attr = spdef.a;
        this.homex = spdef.hx;
        this.homey = spdef.hy;
        this.define = true;
        scalex = 1;
        scaley = 1;
        this.defno = defno;
    }
    SpriteAnimData[][SpriteAnimTarget.V] anim;
    int[SpriteAnimTarget.V] animindex;
    int[SpriteAnimTarget.V] animloop;
    int[SpriteAnimTarget.V] animloopcnt;
    void setAnimation(SpriteAnimData[] anim, SpriteAnimTarget sat, int loop)
    {
        this.anim[sat] = anim;
        if(loop < 0)
        {
            throw new IllegalFunctionCall("SPANIM");
        }
        animloop[sat] = loop;
        animloopcnt[sat] = 0;
        isAnim = true;
    }
    void clear()
    {
        this.define = false;
        this.attr = SpriteAttr.none;
    }
    void change(SpriteDef s)
    {
        this.u = s.u;
        this.v = s.v;
        this.w = s.w;
        this.h = s.h;
        this.homex = s.hx;
        this.homey = s.hy;
        this.attr = s.a;
    }
}
class Sprite
{
    SpriteDef[] SPDEFTable;
    SpriteData[] sprites;
    PetitComputer petitcom;
    string spdefTableFile = "spdef.csv";
    int spmax = 512;
    void initUVTable()
    {
        SPDEFTable = new SpriteDef[4096];
        //UVTable[] = SDL_Rect(0, 0, 16, 16);//Ichigo
        for(int i = 0; i < 4096; i++)
        {
            SPDEFTable[i] = SpriteDef(0, 0, 16, 16, 0, 0, SpriteAttr.show);
        }
        SPDEFTable[4095] = SpriteDef(192, 480, 96, 32, 48, 16, SpriteAttr.show);
        //UVTable[] = SDL_Rect(192, 480, 96, 32);
        import std.csv;
        import std.typecons;//I	X	Y	W	H	HX	HY	ATTR
        import std.file;
        import std.stdio;
        import std.algorithm;
        auto file = File(spdefTableFile, "r");
        file.readln();//一行読み飛ばす
        auto csv = file.byLine.joiner("\n").csvReader!(Tuple!(int, "I", int, "X" ,int, "Y", int, "W", int, "H", int, "HX", int, "HY", int, "ATTR"));
        foreach(record; csv)
        {
            SPDEFTable[record.I] = SpriteDef(record.X, record.Y, record.W, record.H, record.HX, record.HY, cast(SpriteAttr)record.ATTR);
        }
    }
    void spchr(int i, int d)
    {
        i = spid(i);
        sprites[i].change(SPDEFTable[d]);
    }
    void spchr(int id, int u, int v, int w, int h, SpriteAttr attr)
    {
        id = spid(id);
        auto spdef = SpriteDef(u, v, w, h, sprites[id].homex, sprites[id].homey, attr);
        sprites[id].change(spdef);
    }
    this(PetitComputer petitcom)
    {
        sprites = new SpriteData[512];
        sprites[] = SpriteData(false);
        initUVTable;
        this.petitcom = petitcom;
    }
    void animation(ref SpriteData sprite)
    {
        foreach(i, ref d; sprite.anim)
        {
            if(!d) continue;//未定義
            SpriteAnimTarget target = cast(SpriteAnimTarget)i;
            int index = sprite.animindex[i];
            SpriteAnimData* data = &d[index];
            data.elapse = data.elapse + 1;
            auto frame = data.elapse;
            if(frame == 1)
            {
                if(!data.interpolation)
                {
                    switch(target)
                    {
                        case SpriteAnimTarget.XY:
                            sprite.x = data.data.x;
                            sprite.y = data.data.y;
                            break;
                        case SpriteAnimTarget.Z:
                            sprite.z = data.data.z;
                            break;
                        case SpriteAnimTarget.UV:
                            sprite.u = data.data.u;
                            sprite.v = data.data.v;
                            break;
                        case SpriteAnimTarget.I:
                            sprite.defno = data.data.i;
                            spchr(sprite.id, sprite.defno);
                            break;
                        case SpriteAnimTarget.R:
                            sprite.r = data.data.r;
                            break;
                        case SpriteAnimTarget.S:
                            sprite.scalex = data.data.scalex;
                            sprite.scaley = data.data.scaley;
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
                        sprite.x = data.old.x + ((data.data.x - data.old.x) / data.frame) * frame;
                        sprite.y = data.old.y + ((data.data.y - data.old.y) / data.frame) * frame;
                        break;
                    case SpriteAnimTarget.Z:
                        sprite.z = data.old.z + ((data.data.z - data.old.z) / data.frame) * frame;
                        break;
                    case SpriteAnimTarget.UV:
                        sprite.u = data.old.u + ((data.data.u - data.old.u) / data.frame) * frame;
                        sprite.v = data.old.v + ((data.data.v - data.old.v) / data.frame) * frame;
                        break;
                    case SpriteAnimTarget.I:
                        sprite.defno = data.old.i + ((data.data.i - data.old.i) / data.frame) * frame;
                        spchr(sprite.id, sprite.defno);
                        break;
                    case SpriteAnimTarget.R:
                        sprite.r = data.old.r + ((data.data.r - data.old.r) / data.frame) * frame;
                        break;
                    case SpriteAnimTarget.S:
                        sprite.scalex = data.old.scalex + ((data.data.scalex - data.old.scalex) / data.frame) * frame;
                        sprite.scaley = data.old.scaley + ((data.data.scaley - data.old.scaley) / data.frame) * frame;
                        break;
                    case SpriteAnimTarget.C:
                        break;
                    case SpriteAnimTarget.V:
                        break;
                    default:
                        break;
                }
            }
            if(frame >= data.frame)
            {
                sprite.animindex[i] = (sprite.animindex[i] + 1) % d.length;
                data.elapse = 0;
                if(sprite.animloop[i] == 0)
                {
                    continue;
                }
                sprite.animloop[i]++;
                if(sprite.animloop[i] >= sprite.animloopcnt[i])
                {
                    sprite.anim[i] = null;
                    continue;
                }
                continue;
            }
        }
    }
    bool lll;
    import std.algorithm;
    void render()
    {
        float disw = 200f, dish = 120f, disw2 = 400f, dish2 = 240f;
        auto texture = petitcom.GRP[petitcom.sppage].glTexture;
        float aspect = disw2 / dish2;
        float z = -0.01f;
        int spmax = petitcom.xscreenmode == 1 ? this.spmax : -1;//XSCREENが2,3じゃないと下画面は描画しない
        glBindTexture(GL_TEXTURE_2D, texture);
        glEnable(GL_TEXTURE_2D);
        // glDisable(GL_TEXTURE_2D);
        version(test) glLoadIdentity();
        glLoadIdentity();
        foreach(i,ref sprite; sprites)
        {
            if(i == spmax)
            {
                disw = 160f;
                disw2 = 320f;
                glViewport(40, 0, 320, 240);
                aspect = disw2 / dish2;
            }
            //定義されてたら動かす
            if(sprite.define)
            {
                animation(sprite);
            }
            if(sprite.attr & SpriteAttr.show)
            {
                int x = cast(int)sprite.x;// - cast(int)(sprite.homex * sprite.scalex);
                int y = cast(int)sprite.y;// - cast(int)(sprite.homey * sprite.scaley);
                auto homex2 = ((sprite.w / 2 ) - sprite.homex) / dish;
                auto homey2 = ((sprite.h / 2 ) - sprite.homey) / dish;
                int w = sprite.w;
                int h = sprite.h;
                
                if((sprite.attr & SpriteAttr.rotate90) == SpriteAttr.rotate90)
                {
                    swap(w, h);
                }
                int x2 = cast(int)x + w;//-1
                int y2 = cast(int)y + h;
                int u = cast(int)sprite.u;
                int v = cast(int)sprite.v;
                int u2 = cast(int)sprite.u + sprite.w;//-1
                int v2 = cast(int)sprite.v + sprite.h;
                z = sprite.z / 1025f;
                float flipx = cast(float)sprite.scalex, flipy = cast(float)sprite.scaley, flipx2 = x, flipy2 = y;
                if(sprite.attr & SpriteAttr.hflip)
                {
                    flipx = -flipx;
                    flipx2 = x2 - cast(int)(sprite.homex * sprite.scalex);//sprite.homex * sprite.scalex);
                }
                if(sprite.attr & SpriteAttr.vflip)
                {
                    flipy = -flipy;
                    flipy2 = y2 - cast(int)(sprite.homey * sprite.scaley);
                }
                version(test) glRotatef(45f, 1f, 0f, 0.5f);

                glTranslatef((flipx2) / disw - 1,
                             1 - ((flipy2) / dish), 0);
                //glTranslatef((flipx2) / dish - 1,1 - ((flipy2) / dish), 0);
                //glScalef(flipx, flipy, 1f); 
                //アスペクト比を調節しないといけないらしい
                //https://groups.google.com/forum/#!topic/android-group-japan/45mjecPSY4s
                //http://www.tnksoft.com/blog/?p=2889
                glScalef(1.0f / aspect, 1.0f, 1.0f);
                glRotatef(360 - sprite.r, 0.0f, 0.0f, 1.0f );
                glScalef(flipx * aspect, flipy, 1f);
                glBegin(GL_QUADS);
                glColor3f(1.0, 1.0, 1.0);
                if((sprite.attr& 0b111) == SpriteAttr.show)
                {
                    //d+=0.01;
                    /*glTexCoord2f(u / 512f - 1, v / 512f - 1);
                    glVertex3f(0, 0, z);//1
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);
                    glVertex3f(0, -(sprite.h / dish), z);//2
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);
                    glVertex3f(sprite.w / dish, -(sprite.h / dish), z);//3
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);
                    glVertex3f(sprite.w / dish, 0, z);//4*/
                    
                    //glColor3f(0,1,0);
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);
                    glVertex3f(-((sprite.w) / disw2 - homex2) , ((sprite.h) / dish2 - homey2), z);//1
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);
                    glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);
                    glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3//y+--+x--++
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);
                    glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                    glEnd();
                    /*
                    glDisable(GL_TEXTURE_2D);
                    glColor3f(1,0,0);
                    glBegin(GL_POINTS);
                    glVertex3f(0,0,-0.9);
                    glColor3f(0,1,0);
                    glVertex3f(-((sprite.w) / dish2),((sprite.h) / dish2),-0.9);
                    glEnd();
                    glEnable(GL_TEXTURE_2D);*/
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate270) == SpriteAttr.rotate270)
                {
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);//3
                    glVertex3f(-((sprite.w) / disw2 - homex2), ((sprite.h) / dish2 - homey2), z);//1
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);//1
                    glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);//2
                    glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);//4
                    glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate90) == SpriteAttr.rotate90)
                {
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);//2
                    glVertex3f(-((sprite.w) / disw2 - homex2), ((sprite.h) / dish2 - homey2), z);//1
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);//3
                    glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);//4
                    glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);//1
                    glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate180) == SpriteAttr.rotate180)
                {
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);//4
                    glVertex3f(-((sprite.w) / disw2 - homex2), ((sprite.h) / dish2 - homey2), z);//1
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);//3
                    glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);//1
                    glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);//2
                    glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                glTexCoord2f(u / 512f - 1, v / 512f - 1);
                glVertex3f(-((sprite.w) / disw2 - homex2), ((sprite.h) / dish2 - homey2), z);//1
                glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);
                glVertex3f(-((sprite.w) / disw2 - homex2), -((sprite.h) / dish2 + homey2), z);//2
                glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);
                glVertex3f((sprite.w) / disw2 + homex2, -((sprite.h) / dish2 + homey2), z);//3
                glTexCoord2f(u2 / 512f - 1, v / 512f - 1);
                glVertex3f((sprite.w) / disw2 + homex2, ((sprite.h) / dish2 - homey2), z);//4
                glEnd();
                glLoadIdentity();
                continue;
            }
        }
    }
    int spid(int id)
    {
        if(petitcom.displaynum == 1)
        {
            return id + this.spmax;
        }
        return id;
    }
    void spset(int id, int defno)
    {
        id = spid(id);
        sprites[id] = SpriteData(id, SPDEFTable[defno], defno);
    }
    void spset(int id, int u, int v, int w, int h, SpriteAttr attr)
    {
        id = spid(id);
        auto spdef = SpriteDef(u, v, w, h, 0, 0, attr);
        sprites[id] = SpriteData(id, spdef, 0/*要調査*/);
    }
    void spofs(int id, int x, int y)
    {
        id = spid(id);
        sprites[id].x = x;
        sprites[id].y = y;
    }
    void spofs(int id, int x, int y, int z)
    {
        id = spid(id);
        sprites[id].x = x;
        sprites[id].y = y;
        sprites[id].z = z;
    }
    void sphide(int id)
    {
        id = spid(id);
        sprites[id].attr ^= SpriteAttr.show;
    }
    void spshow(int id)
    {
        id = spid(id);
        sprites[id].attr |= SpriteAttr.show;
    }
    void spanim(int id, wstring target, double[] data)
    {
        bool relative = false;
        if(target[$ - 1..$] == "+")
        {
            target = target[0..$-1];
            relative = true;
        }
        spanim(id, spriteAnimTarget[target] | (relative ? SpriteAnimTarget.relative : cast(SpriteAnimTarget)0), data);
        
    }
    static SpriteAnimTarget[wstring] spriteAnimTarget;
    static this()
    {
        spriteAnimTarget = [
            "XY": SpriteAnimTarget.XY,
            "Z": SpriteAnimTarget.Z,
            "UV": SpriteAnimTarget.UV,
            "I": SpriteAnimTarget.I,
            "R": SpriteAnimTarget.R,
            "S": SpriteAnimTarget.S,
            "C": SpriteAnimTarget.C,
            "V": SpriteAnimTarget.V,
        ];
    }
    void spanim(int id, SpriteAnimTarget target, double[] data)
    {
        id = spid(id);
        bool relative;
        if(SpriteAnimTarget.relative & target)
        {
            relative = true;
            target ^= SpriteAnimTarget.relative;
        }
        int animcount = data.length / ((target == SpriteAnimTarget.XY || target == SpriteAnimTarget.UV) ? 3 : 2);
        SpriteAnimData[] animdata = new SpriteAnimData[animcount];
        int j;
        int loop = 1;
        SpriteAnimData* old;
        for(int i = 0; i < data.length;)
        {
            i = animdata[j].load(i, sprites[id], target, data, old);
            old = &animdata[j++];
            if(data.length - i == 1)
            {
                //loop
                loop = cast(int)data[i];
                break;
            }
        }
        sprites[id].setAnimation(animdata, target, loop);
    }
    void spclr(int id)
    {
        id = spid(id);
        sprites[id].clear;
    }
    void spclr()
    {
        for(int i = 0; i < sprites.length; i++)
        {
            sprites[i].clear;
        }
    }
    void sphome(int i, int hx, int hy)
    {
        i = spid(i);
        sprites[i].homex = hx;
        sprites[i].homey = hy;
    }
    void spscale(int i, double x, double y)
    {
        i = spid(i);
        sprites[i].scalex = x;
        sprites[i].scaley = y;
    }
    void sprot(int i, double rot)
    {
        i = spid(i);
        sprites[i].r = rot;
    }
}
