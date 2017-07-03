module otya.smilebasic.random;
import std.random;

class Random
{
    LinearCongruentialEngine!(uint, 16_807, 0, 2_147_483_647)[8] engine;
    public this()
    {
        foreach (e; engine)
        {
            e.seed(unpredictableSeed);
        }
    }
    public T random(T)(int seedid, T min, T max)
    {
        return uniform(min, max, engine[seedid]);
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
