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

immutable LETTERS = "abcd"; // Current goal is highlighted be few letters
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
    string needle   = generate(needle_length, NEEDLE_LETTERS, 42);

    // actual benchmarking
    string r1, r2, r3;
    auto res = benchmark!({
        import std.algorithm : find;
        r1 = find(haystack, needle);
    },{
        r2 = manual_find(haystack, needle);
    },{
        import my_searching : find;
        r3 = find(haystack, needle);
    })(iterations);

    if (show) {
        writeln("Haystack: ", haystack);
        writeln("Needle: ", needle);
    }

    { // Correctness check
        import std.algorithm : find;
        auto correct_r = find(haystack, needle);
        writefln("Found at %d", haystack.length - correct_r.length);
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
    }
    writefln("std find    took %12d", res[0].length);
    writefln("manual find took %12d", res[1].length);
    writefln("my std find took %12d", res[2].length);
}
