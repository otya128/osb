module otya.smilebasic.fade;
import otya.smilebasic.petitcomputer;
import derelict.opengl3.gl;

class Fade
{
    PetitComputer petitcom;
    int display;
    public this(PetitComputer p, int display)
    {
        petitcom = p;
        this.display = display;
        fade(0);
    }
    int color;
    int start;
    int startColor;
    int end;
    int endColor;
    public void fade(int color)
    {
        this.color = color;
        end = -1;
        start = -1;
    }
    public void fade(int color, int time)
    {
        this.startColor = this.color;
        this.endColor = color;
        this.start = petitcom.maincntRender;
        this.end = this.start + time;
    }
    public int fade()
    {
        return color;
    }
    Tt linear(Tx, Tt)(Tx x1, Tx x2, Tt t)
    {
        return (x2 - x1) / t;
    }
    void render()
    {
        auto m = petitcom.maincntRender;
        ubyte a, r, g, b;
        petitcom.RGBRead(color, r, g, b, a);
        if (m <= end)
        {           
            int a1, r1, g1, b1, a2, r2, g2, b2;
            petitcom.RGBRead(startColor, r1, g1, b1, a1);
            petitcom.RGBRead(endColor, r2, g2, b2, a2);
            auto t1 = m - start;
            auto t2 = end - start;
            a = cast(ubyte)(a1 + (linear(a1, a2, cast(double)t2) * t1));
            r = cast(ubyte)(r1 + (linear(r1, r2, cast(double)t2) * t1));
            g = cast(ubyte)(g1 + (linear(g1, g2, cast(double)t2) * t1));
            b = cast(ubyte)(b1 + (linear(b1, b2, cast(double)t2) * t1));
            color = petitcom.RGB(a, r, g, b);
        }
        if (!a)
            return;
        petitcom.chRenderingDisplay(display);
        glEnable(GL_BLEND);
        glDisable(GL_DEPTH_TEST);
        glDepthMask(GL_FALSE);
        glColor4ub(r, g, b, a);
        glDisable(GL_TEXTURE_2D);
        glBegin(GL_QUADS);
        glVertex2i(0, 0);
        glVertex2i(petitcom.currentDisplay.rect[display].w, 0);
        glVertex2i(petitcom.currentDisplay.rect[display].w, petitcom.currentDisplay.rect[display].h);
        glVertex2i(0, petitcom.currentDisplay.rect[display].h);
        glEnd();
        glDepthMask(GL_TRUE);
        glEnable(GL_DEPTH_TEST);
        glDisable(GL_BLEND);
    }
}