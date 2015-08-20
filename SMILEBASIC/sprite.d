module otya.smilebasic.sprite;
import otya.smilebasic.petitcomputer;
import derelict.sdl2.sdl;
import derelict.opengl3.gl;
enum SpriteAttr
{
    show = 1,
    rotate90 = 2,
    rotate180 = 4,
    rotate270 = 8,
}
struct SpriteData
{
    int id;
    int defno;
    double x, y;
    double z;/*!*/
    int u, v, w, h;//個々で保持してるみたい,SPSETをして後でSPDEFをしても変化しない
    uint color;
    double[8] var;
    SpriteAttr attr;
    bool define;//定義されてればtrue
    this(int id, int defno)
    {
        x = 0;
        y = 0;
        this.id = id;
        this.defno = defno;
        this.color = -1;
        this.attr = SpriteAttr.show;
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
    }
}
class Sprite
{
    SDL_Rect[2048] UVTable;
    SpriteData[512] sprites;
    PetitComputer petitcom;
    void initUVTable()
    {
        UVTable[] = SDL_Rect(0, 0, 16, 16);//Ichigo
    }
    this(PetitComputer petitcom)
    {
        initUVTable;
        this.petitcom = petitcom;
    }
    void animation()
    {
    }
    void render()
    {
        auto texture = petitcom.GRP[petitcom.sppage].glTexture;
        float z = -0.01f;
        glBindTexture(GL_TEXTURE_2D, texture);
        glEnable(GL_TEXTURE_2D);
        glBegin(GL_QUADS);
        foreach(sprite; sprites)
        {
            if(sprite.attr & SpriteAttr.show)
            {
                glColor3f(1.0, 1.0, 1.0);
                int x2 = cast(int)sprite.x + sprite.w;//-1
                int y2 = cast(int)sprite.y + sprite.h;
                int u2 = cast(int)sprite.u + sprite.w;//-1
                int v2 = cast(int)sprite.v + sprite.h;
                glTexCoord2f(sprite.u / 512f - 1 , v2 / 512f - 1);
                glVertex3f(sprite.x / 200f - 1, 1 - y2 / 120f, z);
                glTexCoord2f(sprite.u / 512f - 1, sprite.v / 512f - 1);
                glVertex3f(sprite.x / 200f - 1, 1 - sprite.y / 120f, z);
                glTexCoord2f(u2 / 512f - 1, sprite.v / 512f - 1);
                glVertex3f(x2 / 200f - 1, 1 - sprite.y / 120f, z);
                glTexCoord2f(u2 / 512f - 1, v2 / 512f - 1);
                glVertex3f(x2 / 200f - 1, 1 - y2 / 120f, z);
            }
        }
        glEnd();
    }
    void spset(int id, int defno)
    {
        if(defno >= 2048 && defno < 4096)
        {
            defno -= 2048;
        }
        sprites[id] = SpriteData(id, UVTable[defno].x, UVTable[defno].y, UVTable[defno].w, UVTable[defno].h);
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
}
