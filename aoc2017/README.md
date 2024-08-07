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

Perhaps the values in each bank will always be below 256, but I wasn't sure about part 2 so I chose to represent them as a `[]u32`. This meant that I couldn't use `StringHashMap`. Slices can't go through an `AutoHashMap` (it's ambiguous what you want) so I had to roll my own hashing function. Fortunately there was a unit test in `auto_hash.zig` that showed me how to do what I wanted. My first try failed until I looked at the unit test more closely. "Shallow" is really, truly shallow (just comparing pointers). What I wanted was "deep" but not deep recursive.

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

I generalized `readInts` to work with any integer type. Interesting that you can overflow by multiplying two `u8`s! I'm happy with my `reverse` implementation for circular lists.

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

```
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
```

inserting 8 after 3: day17.Value{ .num = 3, .next = 6 }

```
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
```

This makes a big difference:

    - const v = &vals.items[i];
    - v.next = vals.items.len - 1;
    + vals.items[i].next = vals.items.len - 1;

The former makes a change to a temporary I guess?

My code Just Worked for part 2, 2 minutes in a debug build (1m40s opt). I guess the 50M is big enough to weed out vector shifting implementations?

## Day 18

Interesting how having to pass in an allocator pushes you towards writing (more efficient) code that doesn't need to allocate memory.

On destructuring assignment (or lack thereof):
https://github.com/ziglang/zig/issues/3897#issuecomment-738984680
https://github.com/ziglang/zig/pull/17156

I had to switch from i32 -> i128 to avoid an overflow. But nice that Zig crashed on this rather than giving me the wrong answer. Zig also made it clear that the problem underspecifies the `mod` behavior (what does it do with negatives?).

I'm surprised there's no Queue built-in. There is a PriorityQueue.
I found some code online for a queue and plugged it in. Part 2 went pretty well! I'm glad there were no errors.

A `usize` is an unsigned integer with the same width as a pointer.

## Day 19

No major trouble on part 1. What's the most idiomatic way to return a string from a function in Zig?

I'm having trouble imagining the approach where part 2 is difficult given a solution to part 1.

## Day 20

This one feels slightly math-y. In the long run, shouldn't the particle that stays the closest be the one with the lowest acceleration (L1 norm)? It seems like the initial position and velocity should only matter as tie-breakers.

No tie-breakers needed, as it turns out!

There must be some more helpful primitives I can factor out for parsing, that wound up being the biggest PITA.

For part 2, the interesting part is "after all collisions are resolved". One idea for determining this is to look at the pairwise distances. If no two particles get closer to each other after a tick, then we're done. There are 1000 particles, so 1M pairwise distances. But maybe lots of them annihilate in the first few ticks?

I'm extremely surprised this isn't a compiler error:

    var coords = std.AutoHashMap(Vec3, i32).init(allocator);
    try coords.putNoClobber(particle.p, undefined);

So `undefined` is assignable to `i32`?

I ran the simulation for 100 ticks and then 1000 and got no new collisions, so I plugged in the answer. It was right! No math needed.

## Day 21

Definitely thought we were going to be implementing the game of life! There's always a problem involving rotations and I always find it annoying.

Arenas and Rust-style Lifetime annotations solve related problems. If I allocate all the scratch stuff in an arena, I can freely share references to it from anything else allocated in that same arena.

Part 2: 18 iterations is nowhere near enough to cause problems.

I'm thinking that a `splitIntoBuf` and `extractIntsIntoBuf` helper would be very useful for parsing.

How do I fix this?

    src/util.zig:109:33: error: expected type '*const [3:0]u8', found '[]const u8'
        try expectEqual("abc", parts[0]);

You use `@as`:

  try expectEqualDeep(@as([]const u8, "abc"), parts[0]);

The "Deep" makes it not compare pointers. I still have no idea how to use `expectEqualDeep` to check the entire slice in one statement.
(It looks like `std.mem.eql` is an easier way to compare slices.)

## Day 22

5328 = too low

Some wrong answers due to off-by-one errors in part 1. I think I found a compiler bug: there _was_ an error, but it was reported in a completely unrelated place.

## Day 23

Very curious what part 2 will be because part 1 is just a minor tweak of day 18.

OK, I need to figure out what the program is doing. There have been a few others like this, too.

Well that was fun. No real programming for part 2, just carefully rewriting `jnz` instructions to if statements and loops, then simplifying until it became clear what was going on. I wound up rewriting the program as JavaScript. Probably the most interesting problem so far!

## Day 24

This one is interesting! You can represent the components as a bidirectional graph, where each pin is a node and a component is a link between the two pins. Then each pin has a link to the other pins with the same number. Then I think the problem is just max flow.

I'd like to think about how to implement max flow! I think it's some sort of dynamic programming algorithm. The obvious thing to me is to have a grid of start/end nodes and the max flow path between them. But that doesn't have an optimal substructure: it's not clear how to add the next node to the graph given the existing paths.

Or maybe I don't need to solve that problem? There are a few interesting patterns in my data:

- There are 5 pins that only occur once. These would have to be terminal pins.
- There are 16 pins that only occur twice. So these can all be pre-linked together.

Maybe doing that will reveal more structure? It will at least reduce the number of nodes.

I guess the input isn't long enough to require anything fancy :(. I just brute forced my way through part 1 and I think the same will work for part 2.

Yep!

After looking up Max Flow on Wikipedia, it's not at all analogous to this problem. This would be more like shortest path with negative edge weights. Max flow is the maximum flow across all paths with limited capacity on each node, not just a single path.

## Day 25

Parsing this is going to be fun.
Actually not too bad -- I guess I've gotten better at Zig!
I'm the 6,675th person to complete the 2017 Advent of Code.

General impressions:

- The 2017 Advent of Code was really, really easy. Day 23 was the only one that required much thought. There were a few problems (day 16, day 24) where it could have been interesting with a larger input but wasn't.
- I definitely "got the hang of" Zig after ~15 days. I was particularly happy with how few iterations my parser on day 25 took.
- JavaScript/TypeScript's choice to just have a single `number` type is a massive simplification. There's so much ceremony around numeric type conversions in Zig (and Rust).
- The "error union" pattern is neat because you almost never wind up having to explicitly write the error types. But it's also interesting what's considered an "error union" type error vs. what's not. Memory allocation failure is something you need to think about. But numeric overflow or failed `@intCast` is not.
- It's annoying how any function that takes an allocator needs a `try`. But it's not annoying how this pushes you to write allocation-free versions of your code, e.g. using a buffer.
- `zls` is shockingly bad. It will point out syntax errors and undeclared variables, but that's about it. Calling non-existent methods of functions in a module is OK. Calling a function with the wrong number of arguments is also OK. And it's not able to follow along with the types when you iterate over a hash map, say.
- I was much happier with my VS Code Zig experience when I turned off inlays and stopped expecting `zls` to be helpful.
- Good in-editor error checking for `std.debug.print` would have saved me at least half my round trips to build from the CLI.
- The `comptime` idea is pretty neat. Rather than having a different type-level language, it's all just Zig. I came to appreciate this when I realized that you could put literally any code in a `@TypeOf` expression.
- I'm most baffled by "types that dare not speak their name." There are a lot of these in Zig, e.g. a buffered reader. This is a barrier to abstraction since you have to annotate all parameter and return types. I was shocked how difficult (maybe impossible) it is to encapsulate reading the lines of a file via a buffered reader.
- I'd known about "arenas" since college but had never used one. They're quite convenient! They basically let you pretend you're working in a garbage-collected environment for a limited time. Allocating lots of values in an arena is kind of like having them all share a lifetime annotation in Rust.
- Zig advertises "no hidden memory allocations" which I guess is technically true. I misinterpreted this as "no hidden copies" which most definitely isn't. It took me a while to realize that `struct`s and many other types are copied when you assign them, which leads to aliasing problems.
- I still find the type syntax hard to parse. There's a lot of information being conveyed through punctuation in slice types.
- Some errors that are confusing:
  - Forgetting to put `try` in front of a function call.
  - Forgetting to put `.init(allocator)` at the end of the line when you initialize a hash map.
  - A `const` in the middle of a type.
  - Type errors involving `std.testing.expectEqual` and strings.
  - When you specify the wrong number of elements to `std.debug.print`, it doesn't always tell you _where_ the erroneous print statement is.
  - A surprising non-error: you can put `undefined` in a hashmap with `u32` values. I guess it just inserts garbage?
- I like that unit testing is built-in. It feels weird to me that this is standardized (`zig test`) while building is not.
- Functional programming constructs aren't especially useful without closures.
- No regex or scanf in Zig, so parsing is just split, split, split.
- I've heard Zig described as a C replacement, rather than a C++ replacement. But that doesn't feel entirely fair: it let's you define methods on `struct`s, which feels very object-y. I guess the thing it _doesn't_ have is inheritance, but is that really what defines C++? I don't think so. You can definitely replace C++ with Zig.
- I was surprised there wasn't any sort of `toString()` convention for handling `{s}` or `{any}` in format strings.
- I was confused that `for` lets you iterate some things (slices) but for others you have to use an iterator and `while`.
- I wish Zig had destructuring assignment. It sounds like it will get it for tuples.
- The difference between `var` and `const` in Zig is quite different than it is in JS.
- Making function parameters immutable is an interesting (and different) design choice than JS. The "pass a pointer if you want to mutate it" convention felt very familiar to me from Google-style C++.
- Some Zig conventions:
  - allocator first
  - passing types as the first parameter to functions
- It seems like there's nothing between `anytype` and a concrete type? Are there type bounds in Zig? This feels like C++'s SFINAE.
- Capture is pretty intuitive, I just wish it worked better with zls.

I should play around with building Bun.

This is interesting!

    $ zig zen

    * Communicate intent precisely.
    * Edge cases matter.
    * Favor reading code over writing code.
    * Only one obvious way to do things.
    * Runtime crashes are better than bugs.
    * Compile errors are better than runtime crashes.
    * Incremental improvements.
    * Avoid local maximums.
    * Reduce the amount one must remember.
    * Focus on code rather than style.
    * Resource allocation may fail; resource deallocation must succeed.
    * Memory is a resource.
    * Together we serve the users.

I took another crack at `ReadByLineIterator` having completed the whole AoC. I got it working with only a little fuss. The "types that dare not speak their name" aren't actually a big deal. You can name them just fine. The problem was exactly what was pointed out on the Zig forum:

> std.io.BufferedReader.reader() returns a Reader with a context of *Self (meaning a pointer to the std.io.BufferedReader). In your case, this is a pointer to the stack-allocated buf_reader which gets invalidated after getBufferedReader returns.

So while I can stack-allocate the file, reader and buffered reader in the `iterLines` function, I need to lazily initialize the `stream` (`Reader`) in a method once the `buf_reader` has its final memory address. Once I do this it works pretty nicely.

This makes me think two things:

1. This went a lot better than it did a week or two ago, so I've clearly learned something about Zig.
2. Building a mental model for the implicit copying that goes on is the key breakthrough that made this click.
