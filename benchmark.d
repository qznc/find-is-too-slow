import std.stdio;
import std.random;
import std.getopt;
import std.datetime : benchmark, Duration;
import std.conv : to;
import std.algorithm : sum, min;
import std.math : abs;
import std.array;
import core.cpuid;

bool halt_on_error = false;
bool verbose_errors = false;

string[] names = ["std", "manual", "qznc", "Chris", "Andrei", "Andrei2"];

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
    for (auto i = 0; i < haystack.length-(needle.length-1); i++)
    {
        if (haystack[i] != needle[0])
            continue;
        for (size_t j = i+1, k = 1; k < needle.length; ++j, ++k)
            if (haystack[j] != needle[k])
                continue outer;
        return haystack[i..$];
    }
    return haystack[$ .. $];
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

T[] andrei_find2(T)(T[] haystack, T[] needle)
{
    static size_t computeSkip(T[] needle)
    {
        size_t result = 1;
        while (result < needle.length && needle[$ - 1 - result] != needle[$ - 1])
        {
            ++result;
        }
        return result;
    }

    if (needle.length == 0) return haystack;
    immutable lastIndex = needle.length - 1;
    auto last = needle[lastIndex];
    size_t j = lastIndex, skip = 0;
    for (; j < haystack.length;)
    {
        if (haystack[j] != last)
        {
            ++j;
            continue;
        }
        immutable k = j - lastIndex;
        // last elements match
        for (size_t i = 0; ; ++i)
        {
            if (i == lastIndex) return haystack[k .. $];
            if (needle[i] != haystack[k + i]) break;
        }
        if (skip == 0) skip = computeSkip(needle);
        j += skip;
    }
    return haystack[$ .. $];
}


immutable LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

string generate(long n, string alphabet, uint seed)
{
    auto rnd = Random(seed);
    string res;
    foreach(d; 0..n) {
        res ~= alphabet[uniform(0,$,rnd)];
    }
    return res;
}

auto runRandom(int seed)
{
    auto rnd = Random(seed);
    auto haystack_length = uniform(10,10000,rnd);
    auto needle_length = uniform(2,30,rnd);
    auto haystack_alphabet_length = uniform(1, LETTERS.length, rnd);
    auto needle_alphabet_length = uniform(1, LETTERS.length, rnd);
    auto alphabet = LETTERS[0 .. haystack_alphabet_length];
    auto needle_alphabet = LETTERS[0 .. needle_alphabet_length];
    string haystack = generate(haystack_length, alphabet, rnd.front);
    rnd.popFront();
    string needle   = generate(needle_length, needle_alphabet, rnd.front);

    return doBenchmark(haystack, needle);
}

auto runAlice(int seed)
{
    import std.file : read;
    string haystack = cast(string) read("alice.txt");
    string needle   = "find a pleasure in all their simple joys";

    return doBenchmark(haystack, needle);
}

auto doBenchmark(string haystack, string needle)
{
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
    },{
        results ~= andrei_find2(haystack, needle);
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
    long m = min(res[0].length, res[1].length, res[2].length, res[3].length, res[4].length, res[5].length);
    return [
        100 * res[0].length / m,
        100 * res[1].length / m,
        100 * res[2].length / m,
        100 * res[3].length / m,
        100 * res[4].length / m,
        100 * res[5].length / m];
}

void manyRuns(long n, long[] function(int) gen)
{
    // measure
    auto rnd = Random();
    long[][] results;
    foreach(i; 0..n) {
        auto res = gen(rnd.front);
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
        assert (results[i].length);
        averages ~= results[i].sum / results[i].length;
    }

    // MADs
    long[] mads;
    long[] plus_dev, sub_dev, plus_c, sub_c;
    foreach(i; 0..results.length) {
        long mad;
        long avg = averages[i];
        long plus_sum, plus_count, sub_sum, sub_count;
        foreach(x; results[i]) {
            auto diff = x - avg;
            if (diff > 0) {
                plus_sum += diff;
                plus_count += 1;
            } else if (diff < 0) {
                sub_sum += diff;
                sub_count += 1;
            }
            mad += abs(x - avg);
        }
        if (results[i].length == 0)
            mad = -1;
        else
            mad /= results[i].length;
        mads ~= mad;
        if (plus_count == 0)
            plus_dev ~= -1;
        else
            plus_dev ~= plus_sum / plus_count;
        plus_c ~= plus_count;
        if (sub_count == 0)
            sub_dev ~= -1;
        else
            sub_dev ~= sub_sum / sub_count;
        sub_c ~= sub_count;
    }

    // print
    foreach(i; 0 .. averages.length) {
        writefln("%10s: %3d ±%-3d  %+4d (%4d) %4d (%4d)", names[i], averages[i], mads[i],
            plus_dev[i], plus_c[i], sub_dev[i], sub_c[i]);
    }
}

void main(string[] args)
{
    uint iterations = 1000;
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

    writeln("Search in Alice in Wonderland");
    manyRuns(iterations, &runAlice);
    writeln("Search random haystack with random needle");
    manyRuns(iterations, &runRandom);
    writeln(" (avg slowdown vs fastest; absolute deviation)");
    writeln("CPU ID: ", vendor(), " ", processor());
}
