# Advent of Code 2017

## Questions

- Is `GeneralPurposeAllocator` a singleton? Should I care about reusing my instance?

## Day 1

- Had to Google how to read a file line-by-line in Zig.
- I'm not getting autocomplete or quickinfo in VS Code. Is this expected or broken?
  - Opening VS Code in the root directory for the day made it work as expected.
  - There's syntax highlighting but no language service from the root aoc directory
- I was surprised that `std.debug.print` takes a tuple as its second arg. Are there no varargs in Zig?
- I had a bug where I was adding the `u8` ASCII values of the digits, not the numeric values.
- You can do `zig run src/main.zig -- input.txt` to pass args to the program, but it doesn't cache between builds.
- Second star was very speedy after all the setup for the first!

## Day 2

I'm not sure what the best way to set up the Zig build system for multi-day AoC is. I made `src/day1.zig` and `src/day2.zig` and updated `build.zig` to use a for loop. This produces two output binaries. I think this works, but maybe I should have a single binary that takes "day" as an argument? Do I have to change `build.zig` every time I add a source file? This is a part of C that I don't love.

Concatenating strings was kinda painful! You need an allocator to do it, which I guess makes sense. I'm not sure why my first attempt with `std.fmt.bufPrint` failed.

I had a `null` vs. `undefined` bug! You have to initialize optionals to `null` rather than `undefined`.

For part 2 I'm implementing `readInts` using an `ArrayList`. Zig found a memory leak (I forgot to deallocate the ArrayList). Pretty cool!

Zig error handling is interesting. If your function returns `!void`, then you can just stick `try` in front of any statement that could error and its error returns will be added to your error returns.

I'm thinking I should at least try the mono-binary approach. It's supposed to be a build _graph_, right? Hopefully the days I'm not working on will be cached.

The Zig Build System / module documentation is pretty poor: https://ziglearn.org/chapter-3/
There's no explanation of what `zig.mod` is, for example.

Setting each day up as a module works fine. It's a little verbose (for each day I have to add a line to `build.zig` and an `if` statement to `main.zig`) but not so terrible. See 3dc252e for my failed attempt to rework this using a hash map of function pointers.

Reworking `build.zig` to use a for loop is a real pain! I banged my head for a while thinking that my call to `std.fmt.bufPrint` was actually running out of space, when it was just trying to return that error from a function (`build`) that can't return an error. Now I'm running into an issue where (I think) the buffer I'm allocating gets reused across loops. So maybe an allocator really is the way to go.

## Day 3

Zig uses `or` instead of `||`. This is confusing because `||` does mean something in Zig, just not what I expected.

My bug with enum math was really just a bug (I did `(n+4)%4` instead of `(n+1)%4`). A unit test made it easy to track down.

For part 2 I had to roll out the hash map. My first mistake was forgetting to call `init` on the hash map, which resulted in some deeply confusing errors about not passing enough parameters to `get`.

Then I got some errors about "cast discards const qualifier". It seems there is a big difference between:

    - const values = std.AutoHashMap(Point, u32).init(allocator);
    + var values = std.AutoHashMap(Point, u32).init(allocator);

This difference doesn't seem like it's the same as it is in JS.

## Day 4

I'm getting errors like this when I try to write a test with a string literal:

    src/day4.zig:48:48: error: expected type '[]u8', found '*const [14:0]u8'

How do I read `*const [14:0]u8`? And how do I pass a string literal to a function?
It's a `const` issue: https://zig.news/kristoff/what-s-a-string-literal-in-zig-31e9

Since any function that allocates memory can fail, it seems like you wind up having to put `try` in front of almost every function call.

I've turned off inlay hints, which I find quite distracting and "jumpy" as I type. The "offUnlessPressed" setting means that they appear when I hit option+ctrl. This still doesn't eliminate the inlays when I hit `(` to call a function.

On part 2 I had some fun figuring out how to properly free memory I allocated to sort the words. I wound up putting them all on an ArrayList and freeing that in a `defer` block, but maybe there's a more idiomatic way.

I asked for feedback on r/zig:
https://www.reddit.com/r/Zig/comments/17mwi96/feedback_on_a_zig_advent_of_code_solution/

Arena allocators seem very useful!

You can `@import("./path/to/file.zig");`. Interestingly there are zero examples of this on ziglearn.org!

> How do I read `*const [14:0]u8`?

This is [Sentinel Termination](https://ziglearn.org/chapter-1/#sentinel-termination):

> The types of string literals is *const [N:0]u8, where N is the length of the string.

So the `:0` means it's null-terminated. Sentinel-termination seems like kind of a funny generalization of null-termination. Are there any use cases other than C strings? A `[]u8` is kind of like a Pascal string, just without storing the length in a specific place.

## Day 5

So much `try`! I'm getting flashbacks to doing the Advent of Code in Rust three years ago, and how fussy it was about adding signed and unsigned ints:

    const idx = @as(usize, @intCast(i));
    var offset = nums[idx];
    nums[idx] += 1;

Short integer loops are certainly fast! 0.25s for both parts.

## Day 6

Perhaps the values in each bank will always be below 256, but I wasn't sure about part 2 so I chose to represent them as a `[]u32`. This mean that I couldn't use `StringHashMap`. Slices can't go through an `AutoHashMap` (it's ambiguous what you want) so I had to roll my own hashing function. Fortunately there was a unit test in `auto_hash.zig` that showed me how to do what I wanted. My first try failed until I looked at the unit test more closely. "Shallow" is really, truly shallow (just comparing pointers). What I wanted was "deep" but not deep recursive.

... and of course part 2 didn't need `u32` :/ I'm sure this will come in handy again sometime.

Instead of `std.hash.Strategy.Deep`, you can just write `.Deep`. Though `zls` doesn't seem to understand this.

Implementing a line-by-line iterator seems ridiculously hard (this was also true in Rust). I tried, failed, and ran across a few interesting links:

- https://web.archive.org/web/20210413234716/https://zigforum.org/t/read-file-or-buffer-by-line/317/2; this does exactly what I want, but the `ReturnTypeOf` function doesn't seem to work for a `File` (maybe it does for stdin).
- This article explains `@This`: https://www.openmymind.net/Zig-Quirks/
- This page has some advice for using Zig for Advent of Code! https://www.huy.rocks/everyday/12-11-2022-zig-using-zig-for-advent-of-code

Zig explicitly does not have closures:
https://github.com/ziglang/zig/issues/229

Reading the Zig AoC page introduced me to `std.mem.tokenize`. It has a return type of `TokenIterator`, which is considerably easier to write out than the return type of `buffered_reader.reader()`. So I _can_ write my `iter_lines` function, just not with a buffered reader.

I have a [Stack Overflow question](https://stackoverflow.com/q/77427514/388951) up about this. If I get an answer then I can hopefully swap out the implementation without changing the API.

## Day 7

Zig is also [opposed to scanf](https://github.com/ziglang/zig/issues/12161). Maybe this is most useful for Aoc? When I searched "zig scanf", a [post about AoC not being a good way to learn Zig](https://cohost.org/strangebroadcasts/post/542139-also-failing-to-lear) popped up!

Regular expressions also seem hard in Zig:
https://www.openmymind.net/Regular-Expressions-in-Zig/

So maybe just split, split, split?

I continue to be surprised by the differences between `const` and `var`. You need to make your iterators `var`. Also the error you get if you forget the `init()` on a hash map is very cryptic!

Thanks to my Stack Overflow question I'm very, very close to having the line iterator function I want. Writing the type signature of these functions is quite difficult, but `@TypeOf` is pretty powerful. The final (hopefully?) issue I'm running into is that you need two statements to get rid of this `const` error: https://ziggit.dev/t/what-does-error-expected-type-t-found-const-t-mean-where-t-is-some-type/1320. But how do you do that in a comptime expression?

Some background on why Zig wants you to factor out a local variable here: https://github.com/ziglang/zig/issues/12414 (it prevents use-after-free bugs).

You can use a labelled block as an expression, but not a bare block. To "return" from a labelled loop, you use a `break` statement.

Is there anything like C++'s pass by value copying? I guess not if Zig is all about "no secret copying".

zls is surprisingly bad at reporting errors. For example calling `std.debug.print` with the wrong number of parameters is not reported as an error.

I'm just going to get a final answer for part two by hand:

tylelk:
  1614 (58) drfzng
  1614 (579) yhonqw
  1614 (504) wsyiyen
  1623 (1215) dqwocyn
  1614 (666) qqnroz

The 1623 should be a 1614. So the 1215 needs to be a 1206.

I've at least learned something because it was clearer to me how to clean up some repeated code in `main.zig` (d7aff8d). I'm a bit confused about `anyerror`. Putting all the `main` functions for each day in a struct requires me to declare their error sets. I can declare them as `anyerror`, but then Zig is unwilling to infer the error set on each of them. Declaring each `main` to return `anyerror` makes the problem go away. But what issue am I addressing here, exactly? Is there a downside to using `anyerror`?

## Day 8

- Is there a `toString()` convention for Zig structs?
- Is it a convention that `allocator` is always passed first?
- The `std.meta.stringToEnum` trick is handy.
- I wrote a `printHashMap` function but I'm surprised that I had to.
- I continue to find postfix dereferencing (`x.*`) weird, but I guess this does make more sense than C (`*x`).
- Why doesn't `std.testing.expectEqual` work with my `struct Instruction`?

With my fancy new buffered reader iterator, I'm getting crashes. I don't think these are because of my iterator, though, I think they're because of the way I'm setting up the hash map.

## Day 9

Iterating strings character-by-character: Zig's got this!

## Day 10

I generalized `readInts` to work with any integer type. Interesting that you can overflow by multiplying to `u8`s! I'm happy with my `reverse` implementation for circular lists.

`23234babdc6afa036749cfa9e097de1b` is wrong.

My answers are very close to the correct ones but not quite right!
It turned out to be:

    - 0..255
    + 0..256

In my initialization. I guess this didn't trip me up in part 1 because the answer only looked at the first two entries. Never will I ever assume closed intervals!

## Day 11

Putting coordinates on hex grids is pretty confusing! I was tempted to implement Dijkstra for distance-to-origin but I knew it was overkill. I tried to write a direct formula but failed. I eventually wrote something that was recursive but only in the y-dimension.

This may have been the first day where the problem itself was more challenging for me than Zig.

## Day 12

First day where BFS is in play. It's going to be interesting to write a general Dijkstra in Zig.

I find the two forms of iteration in Zig to be a bit confusing. You iterate over a slice with a `for` loop, which yields values, but you iterate over a HashMap with an iterator, which yields pointers.

This is useful! I've been writing `orelse unreachable` a lot.

> `.?` is a shorthand for `orelse unreachable`

## Day 13

Some off-by-ones, but otherwise no problems. Having to cast between `u32` and `usize` is a bit annoying. I wonder why this isn't modeled in the same way as other errors, i.e. why don't you need to wrap integer casts with `try`?

Part 2: first time I've had a performance issue! Building with `-O ReleaseFast` does result in a significantly faster program. But fast enough?

Nope! My answer was 3,907,994. I killed my direct solution after delay=110,000 after 5 minutes, and presumably it was progressing quadratically. So… math for the win!

## Day 14

I'm surprised that `u128` is a thing!

Another off-by-one, this one entirely idiotic and my own fault:

    - var numSet: u32 = 1;
    + var numSet: u32 = 0;

Somehow I lost my part 2 solution for Day 12 which would have been helpful! (It was in my undo buffer, fortunately. I lost it when I changed to `.?`.)

Inching towards a general BFS. Today's is distinct from day 12's because I'm using coordinates as hash keys, not values.

I asked about the memory corruption issue with my line-by-line iterator on the Zig forum: https://ziggit.dev/t/help-debugging-memory-corruption-while-reading-a-file-with-a-buffered-reader-and-iterator/2203

## Day 15

This is an annoyance that I've run into a few times:

```
install transitive failure
└─ install main transitive failure
   └─ zig build-exe main Debug native 1 errors
/opt/homebrew/Cellar/zig/0.11.0/lib/zig/std/fmt.zig:182:13: error: too few arguments
            @compileError("too few arguments");
            ^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
```

Which call has too few arguments? Would be nice to have a stack trace!

Part 2 took a little care to get the synchronization right. The trick was to factor out a `getNext` helper and not try to do the synchronization at too low a level.

## Day 16

First day using a tagged union. It's a bit tedious. One realization was that using named structs works a lot better than anonymous ones since they're not compared structurally.

Part 2 is going to be fun! You can't just look at how the dance permutes the indices since the "partner" move looks at the values, not the positions.

Unoptimized build: 100,000 dances in ~1min.
Optimized build: 300,000 dances in ~20s
=> 1M dances in 67s
=> 1B dances in 67,000s = 18.7h

so doable! but surely there's a better way.
16! = 20,922,789,888,000
so memoizing all the permutations probably won't help unless there's some surprise structure to it.

Fortunately there's a cycle after only 30 dances.

## Day 17

Circular linked lists, always annoying!

{
    day17.Value{ .num = 0, .next = 5 },
    day17.Value{ .num = 1, .next = 0 },
    day17.Value{ .num = 2, .next = 4 },
    day17.Value{ .num = 3, .next = 6 },  // <-
    day17.Value{ .num = 4, .next = 3 },
    day17.Value{ .num = 5, .next = 7 },
    day17.Value{ .num = 6, .next = 1 },
    day17.Value{ .num = 7, .next = 2 }
}

inserting 8 after 3: day17.Value{ .num = 3, .next = 6 }

{
    day17.Value{ .num = 0, .next = 5 },
    day17.Value{ .num = 1, .next = 0 },
    day17.Value{ .num = 2, .next = 4 },
    day17.Value{ .num = 3, .next = 6 },
    day17.Value{ .num = 4, .next = 3 },
    day17.Value{ .num = 5, .next = 7 },
    day17.Value{ .num = 6, .next = 1 },
    day17.Value{ .num = 7, .next = 2 },
    day17.Value{ .num = 8, .next = 6 }
}

This makes a big difference:

    - const v = &vals.items[i];
    - v.next = vals.items.len - 1;
    + vals.items[i].next = vals.items.len - 1;

The former makes a change to a temporary I guess?

My code Just Worked for part 2, 2 minutes in a debug build (1m40s opt). I guess the 50M is big enough to weed out vector shifting implementations?
