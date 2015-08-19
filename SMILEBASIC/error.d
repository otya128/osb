module otya.smilebasic.error;
import std.exception;
import std.string;
class SmileBasicError : Exception
{
    int errnum;
    int errline;
    int errprg;
    this(int slot, int line, string message)
    {
        super(format("%s in %d:%d", message, slot, line));
    }
    this(int line, string message)
    {
        super(format("%s in %d", message, line));
    }
    this(string message)
    {
        super(message);
    }
}
class SyntaxError : SmileBasicError
{
    this()
    {
        this.errnum = 3;
        super("Syntax error");
    }
}
class IllegalFunctionCall : SmileBasicError
{
    this()
    {
        this.errnum = 4;
        super("Illegal function call");
    }
}
class TypeMismatch : SmileBasicError
{
    this()
    {
        this.errnum = 8;
        super("Type mismatch");
    }
}
class OutOfDATA : SmileBasicError
{
    this()
    {
        this.errnum = 13;
        super("Out of DATA");
    }
}
class DuplicateVariable : SmileBasicError
{
    this()
    {
        this.errnum = 18;
        super("Duplicate variable");
    }
}
class ReturnWithoutGosub : SmileBasicError
{
    this()
    {
        this.errnum = 30;
        super("RETURN without GOSUB");
    }
}
class SubscriptOutOfRange : SmileBasicError
{
    this()
    {
        this.errnum = 31;
        super("Subscript out of range");
    }
}

