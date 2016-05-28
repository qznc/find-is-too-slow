import std.stdio;
import std.random;
import std.getopt;
import std.datetime : benchmark, Duration;
import std.conv : to;
import std.algorithm : sum, min;
import std.math : abs;
import std.array;

bool halt_on_error = false;
bool verbose_errors = false;

string[] names = ["std find", "manual find", "qznc find", "Chris find", "Andrei find"];

string manual_find(string haystack, string needle) {
    size_t i=0;
    if (needle.length > haystack.length)
        return haystack[$ .. $];
    size_t end = haystack.length - needle.length + 1;
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

T[] andrei_find(T)(T[] haystack, T[] needle)
{
    if (needle.length == 0) return haystack;
    immutable lastIndex = needle.length - 1;
    auto last = needle[lastIndex];
    size_t j = lastIndex;
    for (; j < haystack.length; ++j)
    {
        if (haystack[j] != last) continue;
        immutable k = j - lastIndex;
        // last elements match
        for (size_t i = 0; ; ++i)
        {
            if (i == lastIndex) return haystack[k .. $];
            if (needle[i] != haystack[k + i]) break;
        }
    }
    return haystack[$ .. $];
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
    string[] results;
    auto res = benchmark!({
        import std.algorithm : find;
        results ~= find(haystack, needle);
    },{
        results ~= manual_find(haystack, needle);
    },{
        import my_searching : find;
        results ~= find(haystack, needle);
    },{
        results ~= findStringS_Manual(haystack, needle);
    },{
        results ~= andrei_find(haystack, needle);
    })(1);

    { // Correctness check
        import std.algorithm : find;
        auto correct_r = find(haystack, needle);
        //writefln("Found at %d", haystack.length - correct_r.length);
        foreach(i, r; results) {
            if (r == correct_r)
                continue;
            writeln("E: wrong result with ", names[i]);
            if (verbose_errors) {
                writeln("Correct: ", correct_r);
                writeln("Wrong: ", r);
                writeln("Haystack: ", haystack);
                writeln("Needle: ", needle);
            }
            if (halt_on_error)
                assert (false);
        }
    }

    // normalize
    auto m = min(res[0].length, res[1].length, res[2].length, res[3].length);
    return [
        100 * res[0].length / m,
        100 * res[1].length / m,
        100 * res[2].length / m,
        100 * res[3].length / m,
        100 * res[4].length / m];
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
    foreach(i; 0 .. averages.length) {
        writefln("%12s:\t%3d ±%d", names[i], averages[i], mads[i]);
    }
    writeln(" (avg slowdown vs fastest; absolute deviation)");
}

void main(string[] args)
{
    uint iterations = 10000;
    auto helpInformation = getopt(args,
        "iterations|i"  ,"number of iterations per run" ,&iterations,
        "halt-on-error" ,"stop benchmarking if any result is wrong" ,&halt_on_error,
        "verbose-errors","show some debugging output if any result is wrong" ,&verbose_errors,
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
