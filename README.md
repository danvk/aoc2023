# Advent of Code 2023

This time in Zig?

I know about Zig because of Bun. Zig seems fast, I think it's a C (rather than C++) replacement.

## Day by day

### Day 8

Using a hash map was a real mistake for part 2 -- I assumed there would be some fanout of ghosts, but really you'll always have a fixed number of ghosts and using hash maps in Zig complicates absolutely everything.

Killed after 110,440,000 steps.

### Day 7

- How do I write a literal `[5]u8`?

### Day 6 (61931 / 60637)

Very easy compared to yesterday. I guess if you don't write the closed-form solution for part 1 then part 2 might be slow / intractable. Once again, I had to `s/u32/u64/g` for part 2. Nice that this just works!

We did a birding trip in Miami today starting at 6 AM so I wasn't able to do Advent of Code until after we got back home.

- Start: 5:41 PM
- ⭐️: 5:51 PM
- ⭐️⭐️: 5:56 PM

### Day 5 (33605 / 15495)

1.8B seeds for part 2… maybe that's doable? Yes! Took ~2.5 minutes to run with `-Doptimize=ReleaseFast`. Thanks, Zig!

I reworked my solution to use an Interval class. It's kinda hairy but does at least run really fast: 79ms vs. 2.5 minutes.

In retrospect it might have been easier to split the number line into disjoint intervals. You only have to care about numbers that actually appear somewhere in the input, and there are only at most a thousand or so of those. But hopefully my `Interval` type will be useful on some future day.

TODO: look at r/adventofcode, is there a more clever, simple solution?

- Start: 7:28 AM
- ⭐️: 7:43 AM
- ⭐️⭐️: 7:52 AM

### Day 4 (48615 / 38383)

No point in using a hash map for such a small number of winning numbers on each card. Part 2 was more interesting, I like the pattern of using a slice view of a fixed-length buffer as a poor man's queue.

I factored out a `splitAnyIntoBuf` helper that can split strings along multiple delimiters. I feel like that's come up a few times already.

- Start: 7:28 AM
- ⭐️: 7:35 AM
- ⭐️⭐️: 7:47 AM

### Day 3 (45310 / 36647)

These continue to be more involved than I'd expect from the first week. In part 2 I looked in each of the eight directions from each `*`. A possible issue I had to avoid was double-counting, i.e. if the same number were both north and northwest of a `*`. I was worried about boundary conditions until I realized I could completely avoid them by padding the input.

The lack of closures and the attention you have to pay to allocation and errors definitely rule out certain ways of separating concerns that I'd otherwise reach for. For example fetching all the neighbors for a cell, or mapping over them.

- Start: 9:35 AM
- ⭐️: 9:59 AM
- ⭐️⭐️: 10:14 AM

### Day 2 (49232 / 45787)

My `splitIntoBuf` and `extractIntsIntoBuf` helpers continue to be very efficient at parsing AoC input. I'm intrigued by the suggestion (on r/adventofcode) that the inputs and problem phrasing will be more convoluted this year in an attempt to throw off AI solvers.

### Day 1 (64698 / 40279)

I forgot it was December! I reused my 2017 setup (pretended that today was a 26th day of 2017) to get an answer, then cleaned up after. Part 2 was definitely a curveball. I checked for each of the nine digit strings at each position with `std.mem.eql`.

Actually taking time to read through the prompt, I realized that I hadn't considered the case that there was only one digit in an input line. But my code just happened to do the right thing (that one digit is both first and last). Ryan pointed out that he got tripped up by "twone", which wasn't even something I'd considered.

Also `std.mem.startsWith` is slightly simpler than `std.mem.eql` here.

## Other Ziggers

- https://github.com/LukeMinnich/advent-of-code-2023
- https://github.com/ManDeJan/advent-of-code/tree/master/src/2023
- https://github.com/iskyd/aoc-zig
- https://github.com/LeperGnome/AoC2023

## Questions I still have about Zig

- Is there anything like upper bounds on `anytype`? Is this C++-style "substitution failure is not an error"?
- Is `zls` just known to be really bad?
- You need an `Allocator` to allocate memory. But what's the underlying mechanism here? Is `Allocator` special? How is `GeneralPurposeAllocator` implemented?
- Zig has lots of numeric types that don't correspond to anything in hardware, e.g. `u5`. How do these work?
- Why are they so opposed to destructuring assignment? It seems like it would really encourage consistent naming, especially with imports.

Nitty gritty questions:

- Why is it `expectEqual(expected, actual)` when the other way around works so much better from a type inference perspective?

## Observations

- An Arena allocator has some similarities to Rust-style lifetime annotations.
- The pattern of passing allocators (which usually implies `try`) pushes you towards allocator-free patterns, e.g. for parsing.
- `comptime` makes a lot of sense. Why have a separate language for metaprogramming?
- Inferred error return types mostly let you not think about errors. But this doesn't really feel that different than exceptions.
- "Detectable undefined behavior" or whatever seems like a useful concept.
- Slices are nice. Especially in the context of strings, they feel like a revival of the "Pascal string" as opposed to the null-terminated C string.

## References

- https://avestura.dev/blog/problems-of-c-and-how-zig-addresses-them
- https://www.huy.rocks/everyday/12-11-2022-zig-using-zig-for-advent-of-code#splitting-a-string
- https://www.forrestthewoods.com/blog/failing-to-learn-zig-via-advent-of-code/
- https://cohost.org/strangebroadcasts/post/542139-also-failing-to-lear

## Warmup

Following:
https://ziglang.org/learn/getting-started/

Install with homebrew:

    brew install zig

This puts me on Zig 0.11.

VS Code integration requires an extension. I got errors about not being able to find zig or zls in my PATH. I wound up installing it via the VS Code extension.

The thing about types being values looks interesting and kinda crazy.

## Tutorial

https://ziglearn.org/

### Chapter 1

- Uses `const` and `var`. That makes a lot more sense than `let` if `var` isn't already taken.
- Types may be omitted if they can be inferred from values.
- `undefined` may be assigned to any value. How does this work?
- There is no concept of truthy or falsy values.
- There's a built-in test runner.
- You can use `if` statements as expressions.
- while loops have a "continue" clause that lets them act like C-style `for(;;)` loops.
- `for` loops are specifically for iterating over containers. You iterate over value, index.
- Values must be used, you can assign to `_` to ignore them explicitly.
- `defer` can be used to execute a statement when you exit a block.
- Errors are defined via `error{}`, which creates an enum of errors. There are no exceptions.
- You can return a value or error with something like `AllocationError!u16`.
- You can add a `catch` clause after a function call that returns an error union.
- `switch` is an expression and must be exhaustive.
- Some types of illegal behavior (e.g. out-of-bounds array access) are caught when you enable "runtime safety" (at a performance cost)
- You can use `unreachable` in places that shouldn't be reached (e.g. in a `switch`)
- Zig has pointers (`*T`) but no null pointers. It also has const pointers (`*const T`)
- Zig has slices (`[]T`). Conceptually they are a pair `([*]T, usize)`.
  - String literals coerce to `[]const u8`
  - `x[n..m]` creates a slice from an array. The interval is half-open.
- Zig has enums. enums can have methods attached to them.
- You define structs with `struct` and initialize them with `T{.k=v}`.
  - struct fields may have default values.
  - structs may have methods
  - You can access a field on a pointer to a struct without `*`.
- Zig has unions. They always have a tag.
- `@setFloatMode(.Optimized)` is equivalent to `-ffast-math`.
- You can return a value from a block and use a block as an expression.
- You can also use loops as expressions (it seems that everything is an expression!)
- `?T` is an optional.
  - You can assign `null` to it.
  - You can use `x orelse 0` to "unwrap" the optional
  - You can use `x orelse unreachable` as a non-null assertion
  - You can write `if (b) |value|` to extract the value via "payload capturing"
- You can execute blocks at compile time using `comptime`.
  - Numeric constants have a distinct comptime type
  - You can declare that a function parameter is `comptime`. This is useful for type generators.
  - I don't follow what `@This()` is doing.
- Captures and function parameters are immutable. You can capture a pointer for mutability.
- An anonymous struct without field names is a tuple! You can iterate over these.
- There is a special syntax for "sentinel-terminated" containers: `[N:t]T`, `[:t]T`, and `[*:t]T`
- There's a special `@Vector` syntax for SIMD vectors

### Chapter 2

- Memory allocators seem to be more of a thing in Zig than I'm used to.
- There is a `GeneralPurposeAllocator` that's a reasonable default.
- You often use `defer allocator.free(bytes)` to free memory.
- `std.ArrayList(T)` is similar to a C++ `std::vector<T>`. It can be used as a stack.
- You use `{d} {s}` for string formatting, or `{}` or `{any}` (`std.fmt`)
- There's built-in JSON parsing (`std.json`) and stringifying. You need to supply a parse type.
- `std.AutoHashMap` is the built-in hash map. There's also `std.StringHashMap`.

Questions:

- Who makes Zig? Where did it come from? Why?
  - It's been around since 2016. I'm surprised no one did AoC in it last year!
  - This is the mission statement: https://andrewkelley.me/post/intro-to-zig.html
  - I see a lot of signal processing work
  - Andrew Kelley used to work at OkC and has some JS background: https://andrewkelley.me/post/do-not-use-bodyparser-with-express-js.html
- Is it annoying to use in practice? (I found Rust quite annoying!)
- Is Zig a good language for targeting WASM?

## Advent of Code 2017

### Day 1

- Had to Google how to read a file line-by-line in Zig.
- I'm not getting autocomplete or quickinfo in VS Code. Is this expected or broken?
  - Opening VS Code in the root directory for the day made it work as expected.
  - There's syntax highlighting but no language service from the root aoc directory
- I was surprised that `std.debug.print` takes a tuple as its second arg. Are there no varargs in Zig?
- I had a bug where I was adding the `u8` ASCII values of the digits, not the numeric values.
- You can do `zig run src/main.zig -- input.txt` to pass args to the program, but it doesn't cache between builds.
- Second star was very speedy after all the setup for the first!

### Day 2

I'm not sure what the best way to set up the Zig build system for multi-day AoC is. I made `src/day1.zig` and `src/day2.zig` and updated `build.zig` to use a for loop. This produces two output binaries. I think this works, but maybe I should have a single binary that takes "day" as an argument? Do I have to change `build.zig` every time I add a source file? This is a part of C that I don't love.

Concatenating strings was kinda painful! You need an allocator to do it, which I guess makes sense. I'm not sure why my first attempt with `std.fmt.bufPrint` failed.

I had a `null` vs. `undefined` bug! You have to initialize optionals to `null` rather than `undefined`.

For part 2 I'm implementing `readInts` using an `ArrayList`. Zig found a memory leak (I forgot to deallocate the ArrayList). Pretty cool!

Zig error handling is interesting. If your function returns `!void`, then you can just stick `try` in front of any statement that could error and its error returns will be added to your error returns.

... continues in [2017/README.md](/aoc2017/README.md).
