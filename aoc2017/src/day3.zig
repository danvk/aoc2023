const std = @import("std");

// R1
// U1
// L2
// D2
// R3
// U3
// L4
// D4
// R5

const Dir = enum(u2) { right, up, left, down };

// TODO: make these methods
fn dirDx(d: Dir) i32 {
    return switch (d) {
        Dir.left => -1,
        Dir.right => 1,
        Dir.up => 0,
        Dir.down => 0,
    };
}
fn dirDy(d: Dir) i32 {
    return switch (d) {
        Dir.left => 0,
        Dir.right => 0,
        Dir.up => -1,
        Dir.down => 1,
    };
}
fn next(d: Dir) Dir {
    const n: u32 = @intFromEnum(d);
    return @as(Dir, @enumFromInt((n + 1) % 4));
}

fn part1(n: u32) u32 {
    var d = Dir.right;
    var amount: u32 = 1;
    var x: i32 = 0;
    var y: i32 = 0;
    var i: u32 = 1;

    outer: while (i < n) {
        for (1..(1 + amount)) |_| {
            if (i == n) {
                break :outer;
            }
            i += 1;
            x += dirDx(d);
            y += dirDy(d);
        }
        d = next(d);
        if (d == Dir.left or d == Dir.right) {
            amount += 1;
        }
    }
    std.debug.print("{d} is at {d}, {d}\n", .{ i, x, y });
    return std.math.absCast(x) + std.math.absCast(y);
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) !void {
    _ = allocator;
    const arg = args[0];
    std.debug.print("arg: {s}\n", .{arg});

    const num = try std.fmt.parseInt(u32, arg, 10);

    std.debug.print("Part 1: {d}\n", .{part1(num)});
    // std.debug.print("Part 2: {d}\n", .{sum2});
}

test "next dir" {
    try std.testing.expectEqual(next(Dir.left), Dir.down);
}
