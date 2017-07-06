module otya.smilebasic.random;
import std.random;
import tinymt32;

struct TinyMT(uint mat1 = 0x8f7011ee, uint mat2 = 0xfc78ff1f, uint tmat = 0x3793fdff)
{
    tinymt32_t tinymt = tinymt32_t([0, 0, 0, 0], mat1, mat2, tmat);
    this(uint x)
    {
        seed(x);
    }
    void seed(uint seed)
    {
        tinymt32_init(&tinymt, seed);
        popFront;
    }
    private uint f;
    void popFront()
    {
        f = tinymt32_generate_uint32(&tinymt);
    }
    typeof(this) save() @safe pure nothrow @nogc
    {
        return this;
    }
    uint front() @safe pure nothrow @nogc const
    {
        return f;
    }
    enum isUniformRandom = true;
    enum empty = false;
    enum min = uint.min;
    enum max = uint.max;
}

class Random
{
    alias RandomType = TinyMT!();
    RandomType[8] engine;
    public this()
    {
        foreach (ref e; engine)
        {
            e.seed(unpredictableSeed);
        }
    }
    public T random(T)(int seedid, T min, T max)
    {
        return uniform(min, max, engine[seedid]);
    }
    public double RNDF(int seedid)
    {
        auto d = uniform(0.0, 1.0, engine[seedid]);
        uniform(0.0, 1.0, engine[seedid]);//why??????????????
        return d;
    }
    public void randomize(int seedid)
    {
        engine[seedid].seed(unpredictableSeed);
    }
    public void randomize(int seedid, int seed)
    {
        engine[seedid].seed(seed);
    }
}
