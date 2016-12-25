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

    override void render()
    {
        
    }

    int show(wstring text)
    {
        petitcom.dialog = this;
        auto area = petitcom.showTouchScreen();
        while (true)
        {
            auto to = petitcom.touchPosition();
            
        }
        petitcom.hideTouchScreen();
        return result;
    }
}

