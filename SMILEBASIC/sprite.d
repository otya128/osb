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
            double s;
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
    int load(int i, ref SpriteData sprite, SpriteAnimTarget target, double[] data)
    {
        this.frame = -cast(int)data[i];
        i++;
        switch(target)
        {
            case SpriteAnimTarget.XY:
                this.data.x = cast(int)data[i++];
                this.data.y = cast(int)data[i++];
                this.old.x = sprite.x;
                this.old.y = sprite.y;
                break;
            case SpriteAnimTarget.Z:
                this.data.z = cast(int)data[i++];
                this.old.z = sprite.z;
                break;
            case SpriteAnimTarget.UV:
                this.data.u = cast(int)data[i++];
                this.data.v = cast(int)data[i++];
                this.old.u = sprite.u;
                this.old.v = sprite.v;
                break;
            case SpriteAnimTarget.I:
                this.data.i = cast(int)data[i++];
                this.old.i = sprite.defno;
                break;
            case SpriteAnimTarget.R:
                this.data.r = data[i++];
                break;
            case SpriteAnimTarget.S:
                this.data.s = data[i++];
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
    this(bool flag)
    {
        define = false;
    }
    this(int id, int defno)
    {
        x = 0;
        y = 0;
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
    this(int id, ref SpriteDef spdef)
    {
        x = 0;
        y = 0;
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
    }
    SpriteAnimData[][SpriteAnimTarget.V] anim;
    void setAnimation(SpriteAnimData[] anim, SpriteAnimTarget sat)
    {
        this.anim[sat] = anim;
        isAnim = true;
    }
    void clear()
    {
        this.define = false;
        this.attr = SpriteAttr.none;
    }
}
struct SpriteDef
{
    int u, v, w, h, hx, hy;
    SpriteAttr a;
}
class Sprite
{
    SpriteDef[] SPDEFTable;
    SpriteData[] sprites;
    PetitComputer petitcom;
    string spdefTableFile = "spdef.csv";
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
            int index = 0;
            SpriteAnimData* data = &d[index];
            data.elapse = data.elapse + 1;
            auto frame = data.elapse;
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
                    sprite.id = data.old.i + ((data.data.i - data.old.i) / data.frame) * frame;
                    break;
                case SpriteAnimTarget.R:
                    break;
                case SpriteAnimTarget.S:
                    break;
                case SpriteAnimTarget.C:
                    break;
                case SpriteAnimTarget.V:
                    break;
                default:
                    break;
            }
            if(frame >= data.frame)
            {
                sprite.anim[i] = null;
                continue;
            }
        }
    }
    bool lll;
    double d = 0;
    import std.algorithm;
    void render()
    {
        auto texture = petitcom.GRP[petitcom.sppage].glTexture;
        float z = -0.01f;
        glBindTexture(GL_TEXTURE_2D, texture);
        glEnable(GL_TEXTURE_2D);
       // glDisable(GL_TEXTURE_2D);
        foreach(i,ref sprite; sprites)
        {
            //定義されてたら動かす
            if(sprite.define)
            {
                animation(sprite);
            }
            if(sprite.attr & SpriteAttr.show)
            {
                int x = cast(int)sprite.x - cast(int)(sprite.homex * sprite.scalex);
                int y = cast(int)sprite.y - cast(int)(sprite.homey * sprite.scaley);
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
                float flipx = cast(float)sprite.scalex, flipy = cast(float)sprite.scaley, flipx2 = x, flipy2 = y;
                if(sprite.attr & SpriteAttr.hflip)
                {
                    flipx = -flipx;
                    flipx2 = x2;
                }
                if(sprite.attr & SpriteAttr.hflip)
                {
                    flipy = -flipy;
                    flipy2 = y2;
                }
                glTranslatef((flipx2) / 200f - 1,1 - ((flipy2) / 120f), z);
                glScalef(flipx, flipy, 1f);
                glRotatef(d, 0.0f, 0.0f, 1.0f );
                glBegin(GL_QUADS);
                glColor3f(1.0, 1.0, 1.0);
                if(sprite.attr == SpriteAttr.show)
                {
                    //d+=0.01;
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);
                    glVertex3f(0, 0, z);//1
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);
                    glVertex3f(0, -(sprite.h / 120f), z);//2
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);
                    glVertex3f(sprite.w / 200f, -(sprite.h / 120f), z);//3
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);
                    glVertex3f(sprite.w / 200f, 0, z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate270) == SpriteAttr.rotate270)
                {
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);//3
                    glVertex3f(0, 0, z);//1
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);//1
                    glVertex3f(0, -(h / 120f), z);//
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);//2
                    glVertex3f(w / 200f, -(h / 120f), z);//3
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);//4
                    glVertex3f(w / 200f, 0, z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate90) == SpriteAttr.rotate90)
                {
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);//2
                    glVertex3f(0, 0, z);//1
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);//3
                    glVertex3f(0, -(h / 120f), z);//2
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);//4
                    glVertex3f(w / 200f, -(h / 120f), z);//3
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);//1
                    glVertex3f(w / 200f, 0, z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate180) == SpriteAttr.rotate180)
                {
                    glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);//4
                    glVertex3f(0, 0, z);//1
                    glTexCoord2f(u2 / 512f - 1, v / 512f - 1);//3
                    glVertex3f(0, -(h / 120f), z);//2
                    glTexCoord2f(u / 512f - 1, v / 512f - 1);//1
                    glVertex3f(w / 200f, -(h / 120f), z);//3
                    glTexCoord2f(u / 512f - 1 , v2 / 512f - 1);//2
                    glVertex3f(w / 200f, 0, z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                glEnd();
                glLoadIdentity();
                continue;
            }
        }
    }
    void spset(int id, int defno)
    {
        sprites[id] = SpriteData(id, SPDEFTable[defno]);
    }
    void spofs(int id, int x, int y)
    {
        sprites[id].x = x;
        sprites[id].y = y;
    }
    void sphide(int id)
    {
        sprites[id].attr ^= SpriteAttr.show;
    }
    void spshow(int id)
    {
        sprites[id].attr |= SpriteAttr.show;
    }
    void spanim(int id, wstring target, double[] data)
    {
        bool relative = false;
        if(target[$..$] == "+")
        {
            target = target[0..$-1];
            relative = true;
        }
        spanim(id, spriteAnimTarget[target] | SpriteAnimTarget.relative, data);
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
        bool relative;
        if(SpriteAnimTarget.relative & target)
        {
            relative = true;
            target ^= SpriteAnimTarget.relative;
        }
        int animcount = data.length / ((target == SpriteAnimTarget.XY || target == SpriteAnimTarget.UV) ? 3 : 2);
        SpriteAnimData[] animdata = new SpriteAnimData[animcount];
        int j;
        for(int i = 0; i < data.length;)
        {
            i = animdata[j++].load(i, sprites[id], target, data);
            if(data.length - i == 1)
            {
                //loop
                break;
            }
        }
        sprites[id].setAnimation(animdata, target);
    }
    void spclr(int id)
    {
        sprites[id].clear;
    }
    void spclr()
    {
        for(int i = 0; i < sprites.length; i++)
        {
            spclr(i);
        }
    }
    void sphome(int i, int hx, int hy)
    {
        sprites[i].homex = hx;
        sprites[i].homey = hy;
    }
    void spscale(int i, int x, int y)
    {
        sprites[i].scalex = x;
        sprites[i].scaley = y;
    }
}
