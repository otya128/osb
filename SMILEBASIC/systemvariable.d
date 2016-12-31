module otya.smilebasic.systemvariable;
import otya.smilebasic.type;
import otya.smilebasic.error;
import otya.smilebasic.vm;
class SystemVariable
{
    VM vm;
    @property
        abstract Value value();
    @property
        void value(Value value)
        {
            //v3.3.2
            //TIME$=1,TIME$="1"=>Type mismatch(runtime)
            //MAINCNT=1,MAINCNT="1"=>Syntax error(runtime)
            throw new TypeMismatch();
        }
}
import std.datetime;
import std.string;
import std.conv;
class Date : SystemVariable
{
    @property
    override Value value()
    {
        auto currentTime = Clock.currTime();
        wstring timeString = format("%04d/%02d/%02d", currentTime.year, currentTime.month, currentTime.day).to!wstring;
        return Value(timeString);
    }
}
class Time : SystemVariable
{
    @property
    override Value value()
    {
        auto currentTime = Clock.currTime();
        wstring timeString = format("%02d:%02d:%02d", currentTime.hour, currentTime.minute, currentTime.second).to!wstring;
        return Value(timeString);
    }
}
class Maincnt : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.maincnt);
        }
}
class CSRX : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.console.CSRX);
        }
}
class CSRY : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.console.CSRY);
        }
}
class CSRZ : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.console.CSRZ);
        }
}
class TabStep : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.console.TABSTEP);
        }
    @property
        override void value(Value value)
        {
            if(!value.isNumber)
            {
                throw new TypeMismatch();
            }
            int i = value.castInteger;
            if(i < 0 || i > 16)
            {
                throw new OutOfRange();
            }
            vm.petitcomputer.console.TABSTEP = i;
        }
}
class Version : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.version_);
        }
}
class FreeMem : SystemVariable
{
    @property
        override Value value()
        {
            return Value(8327164);
        }
}
class Result : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.project.result);
        }
}
class Hardware : SystemVariable
{
    @property
        override Value value()
        {
            return Value(cast(int)vm.petitcomputer.hardware);
        }
}
class MilliSecond : SystemVariable
{
    @property
        override Value value()
        {
            import derelict.sdl2.sdl;
            return Value(cast(int)SDL_GetTicks());
        }
}
class ProgramSlot : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.program.currentSlot);
        }
}
class CallIndex : SystemVariable
{
    @property override Value value()
    {
        return Value(vm.petitcomputer.callidx);
    }
}
