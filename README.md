# Advent of Code 2023

This time in Zig?

I know about Zig because of Bun. Zig seems fast, I think it's a C (rather than C++) replacement.

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
