import std.stdio;
import std.random;
import std.getopt;
import std.datetime : benchmark, Duration;
import std.conv : to;

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

immutable LETTERS = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ";

string generate(long n, string alphabet, uint seed)
{
    auto rnd = Xorshift(seed);
    string res;
    foreach(d; 0..n) {
        res ~= alphabet[uniform(0,$,rnd)];
    }
    return res;
}

void main(string[] args)
{
    long haystack_length = 200;
    long needle_length = 3;
    uint iterations = 100_000;
    bool show = false;
    string alphabet = LETTERS;
    auto helpInformation = getopt(args,
        "haystack-length|l","length of the random haystack",&haystack_length,
        "needle-length|n"  ,"length of the random needle"  ,&needle_length,
        "iterations|i"     ,"number of iterations per run" ,&iterations,
        "alphabet"         ,"characters for the haystack" ,&alphabet,
        "show"             ,"show needle and haystack", &show,
    );
    if (helpInformation.helpWanted)
    {
        writef("Benchmark usage: %s { -switch }", args[0]);
        defaultGetoptPrinter("",
                helpInformation.options);
        return;
    }
    string haystack = generate(haystack_length, alphabet, 11);
    string needle   = generate(needle_length, "abc", 42);

    // actual benchmarking
    size_t i1, i2, i3;
    auto res = benchmark!({
        import std.algorithm : find;
        auto f = find(haystack, needle);
        i1 = haystack.length - f.length;
    },{
        auto f = manual_find(haystack, needle);
        i2 = haystack.length - f.length;
    },{
        import my_searching : find;
        auto f = find(haystack, needle);
        i3 = haystack.length - f.length;
    })(iterations);

    if (show) {
        writeln("Haystack: ", haystack);
        writeln("Needle: ", needle);
    }

    { // Correctness check
        import std.algorithm : find;
        size_t correct_i = haystack.length - find(haystack, needle).length;
        writefln("Found at %d", correct_i);
        if (i1 != correct_i) {
            writefln("E: std find wrong");
        }
        if (i2 != correct_i) {
            writefln("E: manual find wrong");
        }
        if (i3 != correct_i) {
            writefln("E: my std find wrong");
        }
    }
    writefln("std find    took %12d", res[0].length);
    writefln("manual find took %12d", res[1].length);
    writefln("my std find took %12d", res[2].length);
}
