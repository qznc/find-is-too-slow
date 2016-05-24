import std.stdio;
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

string generateHaystack(long n)
{
    string res;
    foreach(d; 0..n) {
        res ~= "ab";
    }
    return res;
}

void main(string[] args)
{
    long haystack_length = 200;
    uint iterations = 100_000;
    string needle = "aaa";
    if (args.length > 1)
        haystack_length = to!long(args[1]);
    if (args.length > 2)
        iterations = to!uint(args[2]);
    if (args.length > 3)
        needle = "bbb";
    string haystack = generateHaystack(haystack_length);
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
    { // Correctness check
        import std.algorithm : find;
        size_t correct_i = haystack.length - find(haystack, needle).length;
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
