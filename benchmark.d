import std.stdio;
import std.random;
import std.getopt;
import std.datetime : benchmark, Duration;
import std.conv : to;
import std.algorithm : sum, min;
import std.math : abs;

string manual_find(string haystack, string needle) {
    size_t i=0;
    if (needle.length > haystack.length)
        return haystack[$ .. $];
    size_t end = haystack.length - needle.length;
outer:
    for(; i < end; i++)
    {
        if (haystack[i] != needle[0])
            continue;
        for(size_t j = i+1, k=1; k < needle.length; ++j, ++k)
            if (haystack[j] != needle[k])
                continue outer;
        return haystack[i .. $];
    }
    return haystack[$ .. $];
}

string findStringS_Manual(string haystack, string needle)
{
    if (needle.length > haystack.length)
        return haystack[$..$];
outer:
    for (auto i = 0; i < haystack.length; i++)
    {
        if (haystack[i] != needle[0])
            continue;
        for (size_t j = (i+1 < haystack.length) ? i+1 : i, k = 1; k < needle.length; ++j, ++k)
            if (haystack[j] != needle[k])
                continue outer;
        return haystack[i..$];
    }
    return haystack[$..$];
}

immutable LETTERS = "abcdefghijklmnopqrstuvwxyz";
immutable NEEDLE_LETTERS = "abc";

string generate(long n, string alphabet, uint seed)
{
    auto rnd = Xorshift(seed);
    string res;
    foreach(d; 0..n) {
        res ~= alphabet[uniform(0,$,rnd)];
    }
    return res;
}

auto singleRun(int seed)
{
    auto rnd = Random(seed);
    auto haystack_length = uniform(10,10000,rnd);
    auto needle_length = uniform(2,20,rnd);
    auto alphabet_length = uniform(1, LETTERS.length, rnd);
    auto alphabet = LETTERS[0 .. alphabet_length];
    string haystack = generate(haystack_length, alphabet, rnd.front);
    rnd.popFront();
    string needle   = generate(needle_length, NEEDLE_LETTERS, rnd.front);
    //writefln("RUN h=%d n=%d a=%d", haystack_length, needle_length, alphabet_length);

    // actual benchmarking
    string r1, r2, r3, r4;
    auto res = benchmark!({
        import std.algorithm : find;
        r1 = find(haystack, needle);
    },{
        r2 = manual_find(haystack, needle);
    },{
        import my_searching : find;
        r3 = find(haystack, needle);
    },{
        r4 = findStringS_Manual(haystack, needle);
    })(1);

    { // Correctness check
        import std.algorithm : find;
        auto correct_r = find(haystack, needle);
        //writefln("Found at %d", haystack.length - correct_r.length);
        if (r1 != correct_r) {
            writeln("E: std find wrong");
            writeln("Correct: ", correct_r);
            writeln("Wrong: ", r1);
        }
        if (r2 != correct_r) {
            writeln("E: manual find wrong");
            writeln("Correct: ", correct_r);
            writeln("Wrong: ", r2);
        }
        if (r3 != correct_r) {
            writeln("E: my std find wrong");
            writeln("Correct: ", correct_r);
            writeln("Wrong: ", r3);
        }
        if (r4 != correct_r) {
            writeln("E: manual2 find wrong");
            writeln("Correct: ", correct_r);
            writeln("Wrong: ", r3);
        }
    }
    //writeln(res);

    // normalize
    auto m = min(res[0].length, res[1].length, res[2].length, res[3].length);
    return [
        100 * res[0].length / m,
        100 * res[1].length / m,
        100 * res[2].length / m,
        100 * res[3].length / m];
}

void manyRuns(long n)
{
    // measure
    auto rnd = Random();
    long[][] results;
    foreach(i; 0..n) {
        auto res = singleRun(rnd.front);
        //writeln(res);
        rnd.popFront();
        results.length = res.length;
        foreach (j; 0 .. res.length) {
            results[j] ~= res[j];
        }
    }

    // averages
    long[] averages;
    foreach(i; 0..results.length) {
        averages ~= results[i].sum / results[i].length;
    }

    // MADs
    long[] mads;
    foreach(i; 0..results.length) {
        long mad;
        long avg = averages[i];
        foreach(x; results[i]) {
            mad += abs(x - avg);
        }
        mad /= results[i].length;
        mads ~= mad;
    }

    // print
    writefln("std find:    %3d ±%d", averages[0], mads[0]);
    writefln("manual find: %3d ±%d", averages[1], mads[1]);
    writefln("qznc find:   %3d ±%d", averages[2], mads[2]);
    writefln("Chris find:  %3d ±%d", averages[3], mads[3]);
    writeln(" (avg slowdown vs fastest; absolute deviation)");
}

void main(string[] args)
{
    uint iterations = 10000;
    auto helpInformation = getopt(args,
        "iterations|i"     ,"number of iterations per run" ,&iterations,
    );
    if (helpInformation.helpWanted)
    {
        writef("Benchmark usage: %s { -switch }", args[0]);
        defaultGetoptPrinter("",
                helpInformation.options);
        return;
    }

    manyRuns(iterations);
}
