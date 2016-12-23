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
struct SpriteCollision
{
    SpriteData* data;
    bool scale = true;//scale対応
    int mask = -1;
    short sx;
    short sy;
    ushort w;
    ushort h;
    bool detection(ref SpriteData sp)
    {
        if(sp.define && sp.col.mask & mask)
        {
            int x = (sp.linkx + sp.homex + sp.col.sx);
            int y = (sp.linky + sp.homey + sp.col.sy);
            return detection(x, y, cast(int)(sp.w * sp.scalex), cast(int)(sp.h * sp.scaley));
        }
        return false;
    }

    //(x,y,z,w)
    //(x,y,w,h)と判定
    bool detection(int x, int y, int w, int h)
    {
        int x2 = (data.linkx + data.homex + sx);
        int y2 = (data.linky + data.homey + sy);
        if(x <= x2 && y <= y2 && x + w >= x2 && y + h >= y2)
            return true;
        int w2 = cast(int)(data.w * data.scalex);
        int h2 = cast(int)(data.h * data.scaley);
        if(x <= x2 + w2 && y <= y2 + h2 && x + w >= x2 + w2 && y + h >= y2 + h2)
            return true;
        if(x <= x2 + w2 && y <= y2 && x + w >= x2  + w2 && y + h >= y2)
            return true;
        if(x <= x2 && y <= y2 + h2 && x + w >= x2 && y + h >= y2 + h2)
            return true;
        return false;
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
    double[8] var = 0;
    SpriteAttr attr;
    bool define;//定義されてればtrue
    double scalex;
    double scaley;
    double r;
    this(int id)
    {
        this.id = id;
        z = 0;
        define = false;
        col = SpriteCollision(&this);
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
        col = SpriteCollision(&this);
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
        col = SpriteCollision(&this);
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
        col = SpriteCollision(&this);
    }
    SpriteAnimData[][SpriteAnimTarget.V + 1] anim;
    int[SpriteAnimTarget.V + 1] animindex;
    int[SpriteAnimTarget.V + 1] animloop;
    int[SpriteAnimTarget.V + 1] animloopcnt;
    void setAnimation(SpriteAnimData[] anim, SpriteAnimTarget sat, int loop)
    {
        this.anim[sat] = null;
        if(loop < 0)
        {
            throw new IllegalFunctionCall("SPANIM");
        }
        animloop[sat] = loop;
        animloopcnt[sat] = 0;
        animindex[sat] = 0;
        this.anim[sat] = anim;
        isAnim = true;
    }
    void clear()
    {
        this.define = false;
        this.attr = SpriteAttr.none;
    }
    void change(ref SpriteDef s)
    {
        this.u = s.u;
        this.v = s.v;
        this.w = s.w;
        this.h = s.h;
        this.homex = s.hx;
        this.homey = s.hy;
        this.attr = s.a;
    }
    //SPLINK用
    SpriteData* parent;
    //SPLINKの親は子より小さい管理番号でしかなれないのでsprite->child->nextのX座標を加算すればなんとかなる
    //->挙動的に違う
    int linkx, linky;

    //SPCOL
    SpriteCollision col;
    bool enableCol;
}
class Sprite
{
    SpriteDef[] defSPDEFTable;
    SpriteDef[] SPDEFTable;
    SpriteData[] sprites;
    PetitComputer petitcom;
    string spdefTableFile = "spdef.csv";
    int spmax = 512;
    bool[2] visibles = [true, true];
    bool visible()
    {
        return visibles[petitcom.displaynum];
    }
    void visible(bool value)
    {
        visibles[petitcom.displaynum] = value;
    }
    void initUVTable()
    {
        SPDEFTable = new SpriteDef[4096];
        defSPDEFTable = new SpriteDef[4096];
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
            defSPDEFTable[record.I] = SpriteDef(record.X, record.Y, record.W, record.H, record.HX, record.HY, cast(SpriteAttr)record.ATTR);
        }
        //defSPDEFTable[1208].u = 176;
        //defSPDEFTable[1208 + 2048].u = 176;
        spdef;
    }
    void spdef()
    {
        this.SPDEFTable[] = (this.defSPDEFTable)[];
    }
    void getspdef(int id, out int U, out int V, out int W, out int H, out int HX, out int HY, out int A)
    {
        U = SPDEFTable[id].u;
        V = SPDEFTable[id].v;
        W = SPDEFTable[id].w;
        H = SPDEFTable[id].h;
        HX= SPDEFTable[id].hx;
        HY= SPDEFTable[id].hy;
        A = SPDEFTable[id].a;
    }
    bool isSpriteDefined(int i)
    {
        i = spid(i);
        return sprites[i].define;
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
    void getSpchr(int i, out int d)
    {
        i = spid(i);
        d = sprites[i].defno;
    }
    void getSpchr(int id, out int u, out int v, out int w, out int h, out SpriteAttr attr)
    {
        id = spid(id);
        u = sprites[id].u;
        v = sprites[id].v;
        w = sprites[id].w;
        h = sprites[id].h;
        attr = sprites[id].attr;
    }
    this(PetitComputer petitcom)
    {
        initSpriteAnimationTable();
        sprites = new SpriteData[512];
        zsortedSprites = new SpriteData*[512];
        for(int i = 0; i < sprites.length; i++)
        {
            zsortedSprites[i] = &sprites[i];
            sprites[i] = SpriteData(i);
        }
        initUVTable;
        this.petitcom = petitcom;
        list = new SpriteBucket[512];
        for(int i = 0; i < 512; i++)
        {
            list[i] = new SpriteBucket();
        }
        buckets = new SpriteBucket[1024 + 256];
        listptr = list.ptr;
        bucketsptr = buckets.ptr;
    }
    void animation(SpriteData* sprite, SpriteAnimData* data, SpriteAnimTarget target)
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
                    sprite.z = cast(int)data.data.z;
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
        else
        {
            auto frame = data.elapse;
            //線形補完する奴
            switch(target)
            {
                case SpriteAnimTarget.XY:
                    sprite.x = data.old.x + ((data.data.x - data.old.x) / data.frame) * frame;
                    sprite.y = data.old.y + ((data.data.y - data.old.y) / data.frame) * frame;
                    break;
                case SpriteAnimTarget.Z:
                    sprite.z = cast(int)(data.old.z + ((data.data.z - data.old.z) / data.frame) * frame);
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
    }
    void animation(SpriteData* sprite)
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
                            sprite.z = cast(int)data.data.z;
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
                        sprite.z = cast(int)(data.old.z + ((data.data.z - data.old.z) / data.frame) * frame);
                        break;
                    case SpriteAnimTarget.UV:
                        sprite.u = data.old.u + cast(int)(((data.data.u - data.old.u) / cast(double)data.frame) * frame);
                        sprite.v = data.old.v + cast(int)(((data.data.v - data.old.v) / cast(double)data.frame) * frame);
                        break;
                    case SpriteAnimTarget.I:
                        sprite.defno = data.old.i + cast(int)(((data.data.i - data.old.i) / cast(double)data.frame) * frame);
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
                sprite.animindex[i] = (sprite.animindex[i] + 1) % cast(int)d.length;
                data.elapse = 0;
                if(sprite.animloop[i] == 0)
                {
                    continue;
                }
                if(!sprite.animindex[i])
                {
                    sprite.animloop[i]++;
                    if(sprite.animloop[i] >= sprite.animloopcnt[i])
                    {
                        sprite.anim[i] = null;
                        continue;
                    }
                }
                continue;
            }
        }
    }
    bool lll;
    import std.algorithm;
    SpriteData*[] zsortedSprites;
    bool zChange;
    class SpriteBucket
    {
        SpriteData* sprite;
        SpriteBucket next;
        SpriteBucket last;
    }
    SpriteBucket[] list;
    SpriteBucket[] buckets;
    SpriteBucket* listptr;
    SpriteBucket* bucketsptr;
    int[2] sppage;
    void render()
    {
        if ((!visibles[0] && !visibles[1]) || (petitcom.xscreenmode == 2 && !visibles[0]))
        {
            synchronized (this) foreach(ref sprite; sprites)
            {
                if(sprite.define)
                {
                    animation(&sprite);
                }
            }
            return;
        }
        //とりあえずZ更新されたら描画時にまとめてソート
        //thread safe.....
        if(zChange)
        {
            
            import std.range;
            import std.algorithm;
            zChange = false;
            /*//TimSortImpl!(binaryFun!("a.z < b.z"), Range).sort(zsortedSprites, null);
            try
            {
                sort!("a.z > b.z", SwapStrategy.stable)(zsortedSprites);
            }
            catch(Throwable t)
            {
            }//*/
            //バケットソートっぽい奴
            //基本的にほぼソートされてるので挿入ソートのほうが早そう
            //std.algorithmソートだと例外出る
            //m = 256+1024
            //n = 512
            import std.stdio;
            //writeln("=============START==========");
            //writeln("sort");
            foreach(i, ref s; sprites)
            {
                //if(!s.define) continue;
                auto zet = cast(int)s.z + 256;
                listptr[i].sprite = &s;
                if(bucketsptr[zet])
                {
                    //listptr[i].next = bucketsptr[zet].last;
                    bucketsptr[zet].last.next = listptr[i];
                    bucketsptr[zet].last = listptr[i];
                    listptr[i].next = null;
                }
                else
                {
                    bucketsptr[zet] = listptr[i].last = listptr[i];
                    listptr[i].next = null;
                }
            }
            int j;
            foreach_reverse(i, b; buckets)
            {
                if(b)
                {
                    while(b)
                    {
                        //writefln("z:%d, id:%d", b.sprite.z, b.sprite.id);
                        zsortedSprites[j] = b.sprite;
                        j++;
                        b = b.next;
                    }
                    bucketsptr[i] = null;
                }
            }
        }
        float disw, dish, disw2, dish2;
        disw = petitcom.currentDisplay.rect[0].w / 2;
        disw2 = petitcom.currentDisplay.rect[0].w;
        dish = petitcom.currentDisplay.rect[0].h / 2;
        dish2 = petitcom.currentDisplay.rect[0].h;
        petitcom.chRenderingDisplay(0, clipRect[0].x, clipRect[0].y, clipRect[0].w, clipRect[0].h);
        glMatrixMode(GL_MODELVIEW);
        int dis;
        if(petitcom.xscreenmode == 2)
        {
            disw = 160f;
            disw2 = 320f;
            dish = 240f;
            dish2 = 480f;
            dis = -1;
        }
        auto texture = petitcom.graphic.GRP[sppage[0]].glTexture;
        float aspect = disw2 / dish2;
        float z = -0.01f;
        glBindTexture(GL_TEXTURE_2D, texture);
        glEnable(GL_TEXTURE_2D);
        // glDisable(GL_TEXTURE_2D);
        version(test) glLoadIdentity();
        glLoadIdentity();
        synchronized (this) foreach(i, sprite; zsortedSprites)
        {
            //定義されてたら動かす
            if(sprite.define)
            {
                animation(sprite);
            }
            if(sprite.attr & SpriteAttr.show)
            {
                if(dis != -1)
                {
                    if(!dis && sprite.id >= spmax)
                    {
                        dis = true;
                        if (!visibles[1])
                            continue;
                        //display:1
                        disw = petitcom.currentDisplay.rect[1].w / 2;
                        disw2 = petitcom.currentDisplay.rect[1].w;
                        petitcom.chRenderingDisplay(1, clipRect[1].x, clipRect[1].y, clipRect[1].w, clipRect[1].h);
                        glMatrixMode(GL_MODELVIEW);
                        aspect = disw2 / dish2;
                        texture = petitcom.graphic.GRP[sppage[1]].glTexture;
                        glBindTexture(GL_TEXTURE_2D, texture);
                    }
                    else
                    {
                        if(sprite.id < spmax && dis)
                        {
                            dis = false;
                            if (!visibles[0])
                                continue;
                            disw = petitcom.currentDisplay.rect[0].w / 2;
                            disw2 = petitcom.currentDisplay.rect[0].w;
                            petitcom.chRenderingDisplay(0, clipRect[0].x, clipRect[0].y, clipRect[0].w, clipRect[0].h);
                            glMatrixMode(GL_MODELVIEW);
                            aspect = disw2 / dish2;
                            texture = petitcom.graphic.GRP[sppage[0]].glTexture;
                            glBindTexture(GL_TEXTURE_2D, texture);
                        }
                    }
                    if (!visibles[dis])
                        continue;
                }
                int x, y;
                if(sprite.parent)
                {
                    x += cast(int)(sprite.x + sprite.parent.linkx);
                    y += cast(int)(sprite.y + sprite.parent.linky);
                }
                else
                {
                    x = cast(int)sprite.x;// - cast(int)(sprite.homex * sprite.scalex);
                    y = cast(int)sprite.y;// - cast(int)(sprite.homey * sprite.scaley);
                }
                sprite.linkx = x;
                sprite.linky = y;
                auto homex2 = ((sprite.w / 2f ) - sprite.homex);
                auto homey2 = ((sprite.h / 2f ) - sprite.homey);
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
                z = (sprite.z - 1);//スプライトの描画順が一番上だけどスプライトは最後に描画しないといけないのでZ - 1で一番上にする
                float flipx = cast(float)sprite.scalex, flipy = cast(float)sprite.scaley, flipx2 = x, flipy2 = y;
                if(sprite.attr & SpriteAttr.hflip)
                {
                    swap(u, u2);
                }
                if(sprite.attr & SpriteAttr.vflip)
                {
                    swap(v, v2);
                }
                version(test) glRotatef(rot_test_deg, rot_test_x, rot_test_y, rot_test_z);

                glTranslatef((flipx2),
                             ((flipy2)), 0);
                //glTranslatef((flipx2) / dish - 1,1 - ((flipy2) / dish), 0);
                //アスペクト比を調節しないといけないらしい
                //https://groups.google.com/forum/#!topic/android-group-japan/45mjecPSY4s
                //http://www.tnksoft.com/blog/?p=2889
                //glScalef(1.0f / aspect, 1.0f, 1.0f);
                glRotatef(sprite.r, 0.0f, 0.0f, 1.0f );
                //glScalef(flipx * aspect, flipy, 1f);
                glScalef(flipx, flipy, 1f); 
                glBegin(GL_QUADS);
                glColor4ubv(cast(ubyte*)&sprite.color);
                if((sprite.attr& 0b111) == SpriteAttr.show)
                {
                    glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);
                    auto kbc= (-((sprite.w / 2f) - homex2));
                    glVertex3f(-((sprite.w / 2f) - homex2) , -((sprite.h / 2f) - homey2), z);//1
                    glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1 , v2 / (cast(float)petitcom.graphic.height) - 1);
                    glVertex3f(-((sprite.w / 2f) - homex2), ((sprite.h / 2f) + homey2), z);//2
                    glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v2 / (cast(float)petitcom.graphic.height) - 1);
                    glVertex3f((sprite.w / 2f) + homex2, ((sprite.h / 2f) + homey2), z);//3//y+--+x--++
                    glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);
                    glVertex3f((sprite.w / 2f) + homex2, -((sprite.h / 2f) - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate270) == SpriteAttr.rotate270)
                {
                    glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);//3
                    glVertex3f(-((sprite.w) / 2 - homex2), -((sprite.h) / 2 - homey2), z);//1
                    glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);//1
                    glVertex3f(-((sprite.w) / 2 - homex2), ((sprite.h) / 2 + homey2), z);//2
                    glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1 , v2 / (cast(float)petitcom.graphic.height) - 1);//2
                    glVertex3f((sprite.w) / 2 + homex2, ((sprite.h) / 2 + homey2), z);//3
                    glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v2 / (cast(float)petitcom.graphic.height) - 1);//4
                    glVertex3f((sprite.w) / 2 + homex2, -((sprite.h) / 2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate90) == SpriteAttr.rotate90)
                {
                    glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1 , v2 / (cast(float)petitcom.graphic.height) - 1);//2
                    glVertex3f(-((sprite.w) / 2 - homex2), -((sprite.h) / 2 - homey2), z);//1
                    glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v2 / (cast(float)petitcom.graphic.height) - 1);//3
                    glVertex3f(-((sprite.w) / 2 - homex2), ((sprite.h) / 2 + homey2), z);//2
                    glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);//4
                    glVertex3f((sprite.w) / 2 + homex2, ((sprite.h) / 2 + homey2), z);//3
                    glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);//1
                    glVertex3f((sprite.w) / 2 + homex2, -((sprite.h) / 2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                if((sprite.attr & SpriteAttr.rotate180) == SpriteAttr.rotate180)
                {
                    glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v2 / (cast(float)petitcom.graphic.height) - 1);//4
                    glVertex3f(-((sprite.w) / 2 - homex2), -((sprite.h) / 2 - homey2), z);//1
                    glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);//3
                    glVertex3f(-((sprite.w) / 2 - homex2), ((sprite.h) / 2 + homey2), z);//2
                    glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);//1
                    glVertex3f((sprite.w) / 2 + homex2, ((sprite.h) / 2 + homey2), z);//3
                    glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1 , v2 / (cast(float)petitcom.graphic.height) - 1);//2
                    glVertex3f((sprite.w) / 2 + homex2, -((sprite.h) / 2 - homey2), z);//4
                    glEnd();
                    glLoadIdentity();
                    continue;
                }
                glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);
                glVertex3f(-((sprite.w) / 2 - homex2), -((sprite.h) / 2 - homey2), z);//1
                glTexCoord2f(u / (cast(float)petitcom.graphic.width) - 1 , v2 / (cast(float)petitcom.graphic.height) - 1);
                glVertex3f(-((sprite.w) / 2 - homex2), ((sprite.h) / 2 + homey2), z);//2
                glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v2 / (cast(float)petitcom.graphic.height) - 1);
                glVertex3f((sprite.w) / 2 + homex2, ((sprite.h) / 2 + homey2), z);//3
                glTexCoord2f(u2 / (cast(float)petitcom.graphic.width) - 1, v / (cast(float)petitcom.graphic.height) - 1);
                glVertex3f((sprite.w) / 2 + homex2, -((sprite.h) / 2 - homey2), z);//4
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
        synchronized (this)
            sprites[id] = SpriteData(id, SPDEFTable[defno], defno);
    }
    void spset(int id, int u, int v, int w, int h, SpriteAttr attr)
    {
        id = spid(id);
        auto spdef = SpriteDef(u, v, w, h, 0, 0, attr);
        synchronized (this)
            sprites[id] = SpriteData(id, spdef, 0/*要調査*/);
    }
    int spchk(int id)
    {
        id = spid(id);
        int state;
        for(int i = 0; i <= SpriteAnimTarget.V; i++)
        {
            if(sprites[id].anim[i])
            {
                state |= 1 << i;
            }
        }
        return state;
    }
    void spofs(int id, double x, double y)
    {
        //animeとめる
        id = spid(id);
        synchronized (this)
        {
            sprites[id].anim[SpriteAnimTarget.XY] = null;
            sprites[id].x = x;
            sprites[id].y = y;
            sprites[id].linkx = cast(int)(x + (sprites[id].parent ? sprites[id].parent.linkx : 0));
            sprites[id].linky = cast(int)(y + (sprites[id].parent ? sprites[id].parent.linky : 0));
        }
    }
    void spofs(int id, double x, double y, double z)
    {
        id = spid(id);
        synchronized (this)
        {
            sprites[id].anim[SpriteAnimTarget.XY] = null;
            sprites[id].x = x;
            sprites[id].y = y;
            sprites[id].z = z;
            sprites[id].linkx = cast(int)(x + (sprites[id].parent ? sprites[id].parent.linkx : 0));
            sprites[id].linky = cast(int)(y + (sprites[id].parent ? sprites[id].parent.linky : 0));
        }
        zChange = true;
    }
    void getspofs(int id, out  double x, out double y, out double z)
    {
        id = spid(id);
        x = sprites[id].x;
        y = sprites[id].y;
        z = sprites[id].z;
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
        target = std.uni.toUpper(target);
        if (!(target in spriteAnimTarget))
            throw new IllegalFunctionCall("SPANIM");
        auto tgete = spriteAnimTarget[target];
        spanim(id, tgete | (relative ? SpriteAnimTarget.relative : cast(SpriteAnimTarget)0), data);
        
    }
    SpriteAnimTarget[wstring] spriteAnimTarget;
    void initSpriteAnimationTable()
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
    SpriteAnimTarget getSpriteAnimTarget(wstring target)
    {
        bool relative = false;
        if(target[$ - 1..$] == "+")
        {
            target = target[0..$-1];
            relative = true;
        }
        return spriteAnimTarget[target] | (relative ? SpriteAnimTarget.relative : cast(SpriteAnimTarget)0);
    }
    void spanim(int id, SpriteAnimTarget target, double[] data)
    {
        synchronized (this)
        {
            id = spid(id);
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
            if(animdata[0].frame == 1)
            {
                sprites[id].animindex[target]++;
                animation(&sprites[id], &animdata[0], target);
                if(animcount == 1)
                {
                    if(loop > 1 || loop == 0)
                    {
                        sprites[id].animindex[target] = 0;
                        sprites[id].animloopcnt[target]++;
                    }
                    else
                    {
                        sprites[id].anim[target] = null;
                    }
                }
            }
        }
    }
    void spclr(int id)
    {
        id = spid(id);
        synchronized (this)
            sprites[id].clear;
    }
    void spclr()
    {
        synchronized (this) for(int i = 0; i < sprites.length; i++)
        {
            sprites[i].clear;
        }
    }
    void sphome(int i, int hx, int hy)
    {
        i = spid(i);
        synchronized (this)
        {
            sprites[i].homex = hx;
            sprites[i].homey = hy;
        }
    }
    void spscale(int i, double x, double y)
    {
        i = spid(i);
        synchronized (this)
        {
            sprites[i].scalex = x;
            sprites[i].scaley = y;
        }
    }
    void sprot(int i, double rot)
    {
        i = spid(i);
        sprites[i].r = rot;
    }
    void spcolor(int id, uint color)
    {
        id = spid(id);
        sprites[id].color = petitcom.toGLColor(color);
    }
    void splink(int child, int parent)
    {
        if(parent >= child)
        {
            throw new IllegalFunctionCall("SPLINK");
        }
        parent = spid(parent);
        child = spid(child);
        //SPLINK 2,0
        //SPLINK 2,1した時の挙動謎
        //最後にSPSETした親が優先される->子が親を保持？
        sprites[child].parent = &sprites[parent];
    }
    //再帰的にUNLINKされるのか？
    void spunlink(int id)
    {
        id = spid(id);
        //parent==nullでもエラーでない
        sprites[id].parent = null;
    }
    void spcol(int id)
    {
        id = spid(id);
        spcol(id, 0, 0, cast(ushort)sprites[id].w, cast(ushort)sprites[id].h, true, -1);
    }
    void spcol(int id, bool scale)
    {
        id = spid(id);
        spcol(id, 0, 0, cast(ushort)sprites[id].w, cast(ushort)sprites[id].h, scale, -1);
    }
    void spcol(int id, bool scale, int mask)
    {
        id = spid(id);
        synchronized (this) spcol(id, 0, 0, cast(ushort)sprites[id].w, cast(ushort)sprites[id].h, scale, mask);
    }
    void spcol(int id, short sx, short sy, ushort w, ushort h, bool scale, int mask)
    {
        id = spid(id);
        sprites[id].enableCol = true;
        sprites[id].col.data = &sprites[id];
        sprites[id].col.sx = sx;
        sprites[id].col.sy = sy;
        sprites[id].col.w = w;
        sprites[id].col.h = h;
        sprites[id].col.scale = scale;
        sprites[id].col.mask = mask;
    }
    void getspcol(int id, out bool scale)
    {
        id = spid(id);
    }
    void getspcol(int id, out bool scale, out int mask)
    {
        id = spid(id);
    }
    void getspcol(int id, out int sx, out int sy, out int w, out int h)
    {
        id = spid(id);
    }
    void getspcol(int id, out int sx, out int sy, out int w, out int h, out bool scale)
    {
        id = spid(id);
    }
    void getspcol(int id, out int sx, out int sy, out int w, out int h, out bool scale, out int mask)
    {
        id = spid(id);
    }
    int sphitsp(int id)
    {
        id = spid(id);
        if(spmax > id)
        {
            return sphitsp2(id, 0, spmax - 1);
        }
        return sphitsp2(id, spmax, 511);
    }
    int sphitsp(int id, int start, int end)
    {
        id = spid(id);
        start = spid(start);
        end = spid(end);
        return sphitsp2(id, start, end);
    }
    int sphitsp2(int id, int start, int end)
    {
        if (!sprites[id].enableCol)
        {
            return -1;
        }
        synchronized (this) for(; start <= end; start++)
        {
            if(id == start) continue;
            if(sprites[start].enableCol && sprites[id].col.detection(sprites[start]))
                return start;
        }
        return -1;
    }
    void spvar(int id, int var, double val)
    {
        id = spid(id);
        sprites[id].var[var] = val;
    }
    double spvar(int id, int var)
    {
        id = spid(id);
        return sprites[id].var[var];
    }
    SDL_Rect[2] clipRect;
    void spclip()
    {
        spclip(0, 0, petitcom.currentScreenWidth, petitcom.currentScreenHeight);
    }
    void spclip(int x1, int y1, int x2, int y2)
    {
        import std.algorithm : swap;
        if (x1 > x2)
        {
            swap(x1, x2);
        }
        if (y1 > y2)
        {
            swap(y1, y2);
        }
        clipRect[petitcom.displaynum] = SDL_Rect(x1, y1, x2 - x1 + 1, y2 - y1 + 1);
    }
}
