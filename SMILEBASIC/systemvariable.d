module otya.smilebasic.systemvariable;
import otya.smilebasic.type;
import otya.smilebasic.error;
class SystemVariable
{
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

