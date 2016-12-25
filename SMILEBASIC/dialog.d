module otya.smilebasic.dialog;
import otya.smilebasic.petitcomputer;
import otya.smilebasic.project;
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

class DialogButton
{
    int x, y, width, height;
    GraphicPage background;
    DialogResult result;
    bool isPressed;
    this(GraphicPage background, int x, int y, DialogResult result)
    {
        this.background = background;
        this.x = x;
        this.y = y;
        this.width = background.surface.w;
        this.height = background.surface.h;
        this.result = result;
    }
    bool colDetect(int x, int y)
    {
        return x >= this.x && y >= this.y && this.x + this.width > x && this.y + this.height > y;
    }
}

class DialogResources
{
    public GraphicPage button1;
    public GraphicPage button2;
    public this(SDL_Renderer* renderer, GLenum textureScaleMode)
    {
        button1 = new GraphicPage("dialogresource/yes.png");
        button1.createTexture(renderer, textureScaleMode);
        button2 = new GraphicPage("dialogresource/no.png");
        button2.createTexture(renderer, textureScaleMode);
    }
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
    DialogButton[] buttons;

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
    void renderButton(DialogButton button)
    {
        int mx, my;
        if (button.isPressed)
        {
            mx += 2;
            my += 2;
        }
        glDepthMask(GL_FALSE);
        glEnable(GL_TEXTURE_2D);
        glColor3ub(255, 255, 255);
        glBindTexture(GL_TEXTURE_2D, button.background.glTexture);
        glBegin(GL_QUADS);
        glTexCoord2i(0, 0);
        glVertex2i(button.x + mx, button.y + my);
        glTexCoord2i(1, 0);
        glVertex2i(button.x + button.width + mx, button.y + my);
        glTexCoord2i(1, 1);
        glVertex2i(button.x + button.width + mx, button.y + button.height + my);
        glTexCoord2i(0, 1);
        glVertex2i(button.x + mx, button.y + button.height + my);
        glEnd();
        glDisable(GL_TEXTURE_2D);
        glDepthMask(GL_TRUE);
    }
    override void render()
    {
        petitcom.chScreen2(area.x, area.y, area.w, area.h);
        renderBackground();
        foreach (b; buttons)
        {
            renderButton(b);
        }
    }


    int show(wstring text)
    {
        petitcom.dialog = this;
        area = petitcom.showTouchScreen();
        int buttonMarginWidth = 12;
        int buttonMarginHeight = 12;
        buttons = [
            new DialogButton(
                             petitcom.dialogResource.button1,
                             area.w - buttonMarginWidth - petitcom.dialogResource.button1.surface.w,
                             area.h - buttonMarginHeight - petitcom.dialogResource.button1.surface.h,
                             DialogResult.SUCCESS
                             ),
            new DialogButton(
                             petitcom.dialogResource.button2,
                             buttonMarginWidth,
                             area.h - buttonMarginHeight - petitcom.dialogResource.button1.surface.h,
                             DialogResult.CANCEL
                             )
        ];
        bool isPressed;
        while (!isPressed)
        {
            auto to = petitcom.touchPosition();
            auto x = to.display1X;
            auto y = to.display1Y;
            foreach (b; buttons)
            {
                if (to.tm == 1 && b.colDetect(x, y))
                {
                    b.isPressed = true;
                }
                else if (b.isPressed && to.tm < 1)
                {
                    result = b.result;
                    isPressed = true;
                }
            }
            SDL_Delay(16);
        }
        petitcom.hideTouchScreen();
        return result;
    }
}

