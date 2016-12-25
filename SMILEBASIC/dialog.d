module otya.smilebasic.dialog;
import otya.smilebasic.petitcomputer;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.opengl3.gl;
import derelict.opengl3.gl3;

class DialogBase
{
    abstract void render();
}

enum SelectionType
{
    ok,
    noYes,
    backNext,
    cancelConfirm,
    cancelExecute,
    next,
}

enum ButtonResult
{
    a = 128,
    b = 129,
    x = 130,
    y = 131,
    up = 132,
    down = 133,
    left = 134,
    right = 135,
    l = 136,
    r = 137,
    touch = 140,
}


class Dialog : DialogBase
{
    private PetitComputer petitcom;
    this(PetitComputer petitcom)
    {
        this.petitcom = petitcom;
    }
    private int result;
    private SDL_Rect area;

    void renderBackground()
    {
        int w = 16, h = 16;
        glDepthMask(GL_FALSE);
        glDisable(GL_TEXTURE_2D);
        glColor3ub(248, 248, 248);
        glBegin(GL_QUADS);
        glVertex2i(0, 0);
        glVertex2i(area.w, 0);
        glVertex2i(area.w, area.h);
        glVertex2i(0, area.h);
        glEnd();
        glColor3ub(192, 192, 192);
        glBegin(GL_LINES);
        for (int y = 0; y < area.h; y += h)
        {
            glVertex2i(0, y);
            glVertex2i(area.w, y);
        }
        for (int x = 0; x < area.w; x += w)
        {
            glVertex2i(x, 0);
            glVertex2i(x, area.h);
        }
        glEnd();
        glDepthMask(GL_TRUE);
    }
    override void render()
    {
        petitcom.chScreen2(area.x, area.y, area.w, area.h);
        renderBackground();
    }

    int show(wstring text)
    {
        petitcom.dialog = this;
        area = petitcom.showTouchScreen();
        while (true)
        {
            auto to = petitcom.touchPosition();
            SDL_Delay(16);
        }
        petitcom.hideTouchScreen();
        return result;
    }
}

