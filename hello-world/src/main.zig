const std = @import("std");

fn fibonacci(n: u32) u32 {
    if (n == 0 or n == 1) return n;
    return fibonacci(n - 1) + fibonacci(n - 2);
}

const Box = struct {
    val: u32,
};

pub fn main() !void {
    // var a: u8 = 255;
    // a += 1;
    // std.debug.print("255 + 1 = {d}!\n", .{a});

    var a: Box = .{ .val = 1 };
    var b = a;
    b.val = 2;
    std.debug.print("a: {} b: {}\n", .{ a, b });
    a.val = 2;

    // std.debug.print("All your {s} are belong to us.\n", .{}); // <-- missing argument

    const comp = comptime fibonacci(40);
    std.debug.print("comptime: {d}\n", .{comp});
    const run = fibonacci(40);
    std.debug.print("runtime: {d}\n", .{run});

    // Prints to stderr (it's a shortcut based on `std.io.getStdErr()`)
    std.debug.print("All your {s} are belong to us.\n", .{"codebase"});

    // stdout is for the actual output of your application, for example if you
    // are implementing gzip, then only the compressed bytes should be sent to
    // stdout, not any debugging messages.
    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    try stdout.print("Run `zig build test` to run the tests.\n", .{});

    try bw.flush(); // don't forget to flush!
}

test "simple test" {
    var list = std.ArrayList(i32); // .init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}

test "test with overflow" {
    var a: u8 = 255;
    a += 1;
    std.debug.print("255 + 1 = {d}!\n", .{a});
}
