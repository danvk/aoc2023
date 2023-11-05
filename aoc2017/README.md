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