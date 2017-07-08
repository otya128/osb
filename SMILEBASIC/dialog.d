module otya.smilebasic.dialog;
import otya.smilebasic.petitcomputer;
import otya.smilebasic.project;
import otya.smilebasic.error;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.ttf;
import derelict.opengl3.gl;

class DialogBase
{
    abstract void render();
}

enum ButtonType
{
    abxyButton = 1,
    dpad = 2,
    lrButton = 4,
    touchPanel = 8,
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
    SDL_Rect foregroundRect;
    GraphicPage background;
    GraphicPage foreground;
    DialogResult result;
    bool isPressed;
    this(GraphicPage background, GraphicPage foreground, int x, int y, DialogResult result, int fx, int fy)
    {
        this.background = background;
        this.foreground = foreground;
        this.x = x;
        this.y = y;
        this.width = background.surface.w;
        this.height = background.surface.h;
        this.result = result;
        foregroundRect.x = fx;
        foregroundRect.y = fy;
        foregroundRect.w = foreground.surface.w;
        foregroundRect.h = foreground.surface.h;
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
    public TTF_Font* font;
    wstring[][] buttonCaptions;
    public this(SDL_Renderer* renderer, GLenum textureScaleMode)
    {
        button1 = new GraphicPage("dialogresource/yes.png");
        button1.createTexture(renderer, textureScaleMode);
        button2 = new GraphicPage("dialogresource/no.png");
        button2.createTexture(renderer, textureScaleMode);
        font = TTF_OpenFont("dialogresource/mplus-1c-regular.ttf", 14);
        buttonCaptions = [["了解"], ["はい", "いいえ"], ["次へ", "戻る"], ["決定", "中止"], ["実行", "中止"], ["次へ"]];
    }
}

struct Text
{
    GraphicPage texture;
    this(PetitComputer petitcom, wstring text, SDL_Color color)
    {
        text ~= '\0';
        auto surface = petitcom.dialogResource.font.TTF_RenderUNICODE_Blended((cast(ushort[])text).ptr, color);
        texture = new GraphicPage(surface);
        texture.createTexture(petitcom.renderer, petitcom.textureScaleMode);
    }
    this(PetitComputer petitcom, wchar* text, SDL_Color color, uint width)
    {
        auto surface = petitcom.dialogResource.font.TTF_RenderUNICODE_Blended_Wrapped((cast(ushort*)text), color, width);
        if (surface)
        {
            texture = new GraphicPage(surface);
            texture.createTexture(petitcom.renderer, petitcom.textureScaleMode);
        }
    }
    ~this()
    {
        if (texture)
        {
            texture.deleteGL();
            texture.deleteSDL();
        }
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
    void renderQuad(SDL_Rect rect)
    {
        glBegin(GL_QUADS);
        glTexCoord2i(0, 0);
        glVertex2i(rect.x, rect.y);
        glTexCoord2i(1, 0);
        glVertex2i(rect.x + rect.w, rect.y);
        glTexCoord2i(1, 1);
        glVertex2i(rect.x + rect.w, rect.y + rect.h);
        glTexCoord2i(0, 1);
        glVertex2i(rect.x, rect.y + rect.h);
        glEnd();
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
        glEnable(GL_BLEND);
        glColor3ub(255, 255, 255);
        glBindTexture(GL_TEXTURE_2D, button.background.glTexture);
        renderQuad(SDL_Rect(button.x + mx, button.y + my, button.width, button.height));
        if (button.foreground)
        {
            glBindTexture(GL_TEXTURE_2D, button.foreground.glTexture);
            renderQuad(SDL_Rect(button.x + button.foregroundRect.x + mx, button.y + button.foregroundRect.y + my, button.foregroundRect.w, button.foregroundRect.h));
        }
        glDisable(GL_BLEND);
        glDisable(GL_TEXTURE_2D);
        glDepthMask(GL_TRUE);
    }
    void renderContent()
    {
        if (!message)
            return;
        glDepthMask(GL_FALSE);
        glEnable(GL_TEXTURE_2D);
        glEnable(GL_BLEND);
        glColor3ub(255, 255, 255);
        glBindTexture(GL_TEXTURE_2D, message.glTexture);
        renderQuad(SDL_Rect(12, 24, message.surface.w, message.surface.h));
        glDisable(GL_BLEND);
        glDisable(GL_TEXTURE_2D);
        glDepthMask(GL_TRUE);
    }
    override void render()
    {
        petitcom.chScreen2(area.x, area.y, area.w, area.h);
        glDisable(GL_DEPTH_TEST);
        renderBackground();
        foreach (b; buttons)
        {
            renderButton(b);
        }
        renderContent();
        glEnable(GL_DEPTH_TEST);
    }

    GraphicPage message;

    int show(wstring text, SelectionType selType = SelectionType.ok, wstring caption = "■DIALOG", int timeout = 0)
    {
        if (selType >= cast(ptrdiff_t)petitcom.dialogResource.buttonCaptions.length || -selType >= 15)
        {
            throw new OutOfRange("DIALOG", 2);
        }
        area = petitcom.showTouchScreen();
        scope (exit)
            petitcom.hideTouchScreen();
        wchar[257] buffer;
        if (text.length > 256)
        {
            buffer[0..256] = text[0..256];
            buffer[256] = '\0';
        }
        else
        {
            buffer[0..text.length] = text[];
            buffer[text.length] = '\0';
        }
        Text messageText =  Text(petitcom, buffer.ptr, SDL_Color(0, 0, 0, 255), area.w - 24);
        message = messageText.texture;
        int buttonMarginWidth = 12;
        int buttonMarginHeight = 12;

        Text button1text;
        DialogButton button1;
        Text button2text;
        DialogButton button2;
        if (selType >= 0)
        {
            auto cs = petitcom.dialogResource.buttonCaptions[cast(size_t)selType];

            button1text = Text(petitcom, cs[0], SDL_Color(0, 0, 0, 255));
            button1 = 
                new DialogButton(
                                 petitcom.dialogResource.button1,
                                 button1text.texture,
                                 area.w - buttonMarginWidth - petitcom.dialogResource.button1.surface.w,
                                 area.h - buttonMarginHeight - petitcom.dialogResource.button1.surface.h,
                                 DialogResult.SUCCESS,
                                 22,
                                 1
                                 );
            if (cs.length > 1)
            {
                ubyte sr, sg, sb, sa;
                SDL_GetRGBA((cast(uint*)petitcom.dialogResource.button2.surface.pixels)[0], petitcom.dialogResource.button2.surface.format, &sr, &sg, &sb, &sa);
                button2text = Text(petitcom, cs[1], SDL_Color(sr, sg, sb, 255));
                button2 = 
                    new DialogButton(
                                     petitcom.dialogResource.button2,
                                     button2text.texture,
                                     buttonMarginWidth,
                                     area.h - buttonMarginHeight - petitcom.dialogResource.button1.surface.h,
                                     DialogResult.CANCEL,
                                     22,
                                     1
                                     );
                buttons = [button1, button2];
            }
            else
            {
                buttons = [button1];
            }
        }
        petitcom.dialog = this;
        scope (exit)
            petitcom.dialog = null;
        bool isPressed;
        int timeoutframe;
        if (timeout > 0)
        {
            timeoutframe = timeout * 60;
        }
        else if (timeout < 0)
        {
            timeoutframe = -timeout;
        }
        auto startmaincnt = petitcom.maincnt;
        auto oldbutton = petitcom.button;
        while (!isPressed && petitcom.running && !petitcom.quit)
        {
            auto pbutton = petitcom.button;
            auto button = pbutton ^ oldbutton & pbutton;
            oldbutton = pbutton;
            petitcom.maincnt++;
            if (petitcom.maincnt - startmaincnt == timeoutframe)
            {
                break;
            }
            auto to = petitcom.touchPosition();
            auto x = to.display1X;
            auto y = to.display1Y;
            if (selType >= 0)
            {
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
            }
            else
            {
                auto buttonType = -selType;
                if (buttonType & ButtonType.abxyButton)
                {
                    if (button & Button.A)
                    {
                        result = ButtonResult.a;
                        break;
                    }
                    if (button & Button.B)
                    {
                        result = ButtonResult.b;
                        break;
                    }
                    if (button & Button.X)
                    {
                        result = ButtonResult.x;
                        break;
                    }
                    if (button & Button.Y)
                    {
                        result = ButtonResult.y;
                        break;
                    }
                }
                if (buttonType & ButtonType.dpad)
                {
                    if (button & Button.UP)
                    {
                        result = ButtonResult.up;
                        break;
                    }
                    if (button & Button.DOWN)
                    {
                        result = ButtonResult.down;
                        break;
                    }
                    if (button & Button.LEFT)
                    {
                        result = ButtonResult.left;
                        break;
                    }
                    if (button & Button.RIGHT)
                    {
                        result = ButtonResult.right;
                        break;
                    }
                }
                if (buttonType & ButtonType.lrButton)
                {
                    if (button & Button.L)
                    {
                        result = ButtonResult.l;
                        break;
                    }
                    if (button & Button.R)
                    {
                        result = ButtonResult.r;
                        break;
                    }
                }
                if (buttonType & ButtonType.touchPanel)
                {
                    if (to.tm == 1)
                    {
                        result = ButtonResult.touch;
                        break;
                    }
                }
            }
            SDL_Delay(16);
        }
        return result;
    }
}

