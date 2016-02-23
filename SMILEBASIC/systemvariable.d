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
            return Value(vm.petitcomputer.CSRX);
        }
}
class CSRY : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.CSRY);
        }
}
class CSRZ : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.CSRZ);
        }
}
class TabStep : SystemVariable
{
    @property
        override Value value()
        {
            return Value(vm.petitcomputer.TABSTEP);
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
            vm.petitcomputer.TABSTEP = i;
        }
}
class Version : SystemVariable
{
    static VERSIONSTRING = "3.1.0";
    static VERSION = 0x3010000;
    @property
        override Value value()
        {
            return Value(VERSION);
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
