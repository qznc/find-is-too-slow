import std.stdio;
import std.datetime : benchmark, Duration;
import std.conv : to;

enum iterations = 2_000_000;

string haystack = "bababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
ababababababababababababababababababab
aaabababababababababababababababababab";
string needle = "aaa";

string manual_find(string haystack, string needle) {
    size_t i=0;
    size_t end = haystack.length - needle.length;
outer:
    for(; i < end; i++)
    {
        if (haystack[i] != needle[0])
            continue;
        for(size_t j = i+1, k=1; k < needle.length; ++j, ++k)
            if (haystack[j] != needle[k])
                continue outer;
        break;
    }
    return haystack[i .. $];
}

void main()
{
    size_t i;
    auto res = benchmark!({
        import std.algorithm : find;
        auto f = find(haystack, needle);
        i = haystack.length - f.length;
    },{
        import std.algorithm : find, boyerMooreFinder;
        auto f = find(haystack, boyerMooreFinder(needle));
        i = haystack.length - f.length;
    },{
        auto f = manual_find(haystack, needle);
        i = haystack.length - f.length;
    })(iterations);
    writefln("std find    took %12d", res[0].length);
    writefln("boyer find  took %12d", res[1].length);
    writefln("manual find took %12d", res[2].length);
}
