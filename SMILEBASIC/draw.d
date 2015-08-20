module otya.smilebasic.draw;
import otya.smilebasic.petitcomputer;
import derelict.opengl3.gl;
class Draw
{
    PetitComputer petitcom;
    this(PetitComputer petitcom)
    {
        this.petitcom = petitcom;
    }

    void gpset(int page, int x, int y, uint color)
    {
        color = PetitComputer.toGLColor(petitcom.GRP[page].textureFormat, color);
        glBindTexture(GL_TEXTURE_2D, petitcom.GRP[page].glTexture);
        glTexSubImage2D(GL_TEXTURE_2D , 0, x, y, 1, 1, petitcom.GRP[page].textureFormat, GL_UNSIGNED_BYTE, &color);
    }
    void gline(int page, int x, int y, int x2, int y2, uint color)
    {
        import std.math;
        int dx = abs(x2 - x);
        int dy = abs(y2 - y);
        int sx, sy;
        if(x < x2) sx = 1; else sx = -1;
        if(y < y2) sy = 1; else sy = -1;
        int err = dx - dy;
        while(true)
        {
            if(x < 0 || y < 0 || x >= 512 || y >= 512) break;
            gpset(page, x, y, color);
            if(x == x2 && y == y2) break;
            int e2 = 2*err;
            if(e2 > -dy)
            {
                err = err - dy;
                x = x + sx;
            }
            if(e2 <  dx)
            {
                err = err + dx;
                y = y + sy ;
            }
        }
    }
    uint[] graphicBuffer = new uint[512 * 512];
    void gfill(int page, int x, int y, int x2, int y2, uint color)
    {
        import std.algorithm;
        import std.math;
        if(x < 0 && x2 < 0 || y < 0 && y2 < 0) return;
        if(x > 511 && x2 > 511 || y > 511 && y2 > 511) return;
        //0<=x<512
        x = min(max(x, 0), 511);
        y = min(max(y, 0), 511);
        x2 = min(max(x2, 0), 511);
        y2 = min(max(y2, 0), 511);
        if(x2 < x) swap(x, x2);
        if(y2 < y) swap(y, y2);
        auto w = abs(x2 - x) + 1;//abs
        auto h = abs(y2 - y) + 1;
        auto size = w * h;
        uint* pixels = graphicBuffer.ptr;
        color = PetitComputer.toGLColor(petitcom.GRP[page].textureFormat, color);
        for(int i = 0; i < size; i++)
        {
            pixels[i] = color;
        }
        glBindTexture(GL_TEXTURE_2D, petitcom.GRP[page].glTexture);
        glTexSubImage2D(GL_TEXTURE_2D , 0, x, y, w, h, petitcom.GRP[page].textureFormat, GL_UNSIGNED_BYTE, pixels);
    }

    void gbox(int page, int x, int y, int x2, int y2, uint color)
    {
        import std.algorithm;
        import std.math;
        if(x < 0 && x2 < 0 || y < 0 && y2 < 0) return;
        if(x > 511 && x2 > 511 || y > 511 && y2 > 511) return;
        //0<=x<512
        x = min(max(x, 0), 511);
        y = min(max(y, 0), 511);
        x2 = min(max(x2, 0), 511);
        y2 = min(max(y2, 0), 511);
        if(x2 < x) swap(x, x2);
        if(y2 < y) swap(y, y2);
        auto w = abs(x2 - x) + 1;//abs
        auto h = abs(y2 - y) + 1;
        auto size = max(w, h);
        uint* pixels = graphicBuffer.ptr;
        color = PetitComputer.toGLColor(petitcom.GRP[page].textureFormat, color);
        for(int i = 0; i < size; i++)
        {
            pixels[i] = color;
        }
        glBindTexture(GL_TEXTURE_2D, petitcom.GRP[page].glTexture);
        glTexSubImage2D(GL_TEXTURE_2D , 0, x, y, w, 1, petitcom.GRP[page].textureFormat, GL_UNSIGNED_BYTE, pixels);
        glTexSubImage2D(GL_TEXTURE_2D , 0, x, y2, w, 1, petitcom.GRP[page].textureFormat, GL_UNSIGNED_BYTE, pixels);
        glTexSubImage2D(GL_TEXTURE_2D , 0, x, y, 1, h, petitcom.GRP[page].textureFormat, GL_UNSIGNED_BYTE, pixels);
        glTexSubImage2D(GL_TEXTURE_2D , 0, x2, y, 1, h, petitcom.GRP[page].textureFormat, GL_UNSIGNED_BYTE, pixels);
    }
}
