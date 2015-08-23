module otya.smilebasic.systemvariable;
import otya.smilebasic.type;
import otya.smilebasic.error;
import otya.smilebasic.vm;
class SystemVariable
{
    @property
        abstract Value value(VM vm);
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
    override Value value(VM vm)
    {
        auto currentTime = Clock.currTime();
        wstring timeString = format("%04d/%02d/%02d", currentTime.year, currentTime.month, currentTime.day).to!wstring;
        return Value(timeString);
    }
}
class Time : SystemVariable
{
    @property
    override Value value(VM vm)
    {
        auto currentTime = Clock.currTime();
        wstring timeString = format("%02d:%02d:%02d", currentTime.hour, currentTime.minute, currentTime.second).to!wstring;
        return Value(timeString);
    }
}
class Maincnt : SystemVariable
{
    @property
        override Value value(VM vm)
        {
            return Value(vm.petitcomputer.maincnt);
        }
}
class CSRX : SystemVariable
{
    @property
        override Value value(VM vm)
        {
            return Value(vm.petitcomputer.CSRX);
        }
}
class CSRY : SystemVariable
{
    @property
        override Value value(VM vm)
        {
            return Value(vm.petitcomputer.CSRY);
        }
}
class CSRZ : SystemVariable
{
    @property
        override Value value(VM vm)
        {
            return Value(vm.petitcomputer.CSRZ);
        }
}

