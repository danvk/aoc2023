const std = @import("std");
const dir = @import("../dir.zig");
const Dir = dir.Dir;

// R1
// U1
// L2
// D2
// R3
// U3
// L4
// D4
// R5

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
            x += d.dx();
            y += d.dy();
        }
        d = d.ccw();
        if (d == Dir.left or d == Dir.right) {
            amount += 1;
        }
    }
    std.debug.print("{d} is at {d}, {d}\n", .{ i, x, y });
    // Will become @abs in Zig 0.12: https://github.com/ziglang/zig/issues/16026
    return @abs(x) + @abs(y);
}

const Point = struct { x: i32, y: i32 };

fn part2(n: u32, allocator: std.mem.Allocator) !u32 {
    var d = Dir.right;
    var amount: u32 = 1;
    var x: i32 = 0;
    var y: i32 = 0;
    var i: u32 = 1;

    var values = std.AutoHashMap(Point, u32).init(allocator);
    defer values.deinit();
    try values.put(Point{ .x = 0, .y = 0 }, 1);

    const ds = [_]i32{ -1, 0, 1 };

    while (true) {
        for (1..(1 + amount)) |_| {
            var sum: u32 = 0;
            for (ds) |dx| {
                for (ds) |dy| {
                    const pt = Point{ .x = (x + dx), .y = (y + dy) };
                    const val = values.get(pt);
                    sum += val orelse 0;
                }
            }
            std.debug.print("{d},{d} {d} -> sum={d}\n", .{ x, y, i, sum });
            if (sum > n) {
                return sum;
            }
            const pt = Point{ .x = x, .y = y };
            try values.put(pt, sum);
            i += 1;
            x += d.dx();
            y += d.dy();
        }
        d = d.ccw();
        if (d == Dir.left or d == Dir.right) {
            amount += 1;
        }
    }
    return 0;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const arg = args[0];
    std.debug.print("arg: {s}\n", .{arg});

    const num = try std.fmt.parseInt(u32, arg, 10);

    std.debug.print("Part 1: {d}\n", .{part1(num)});
    std.debug.print("Part 2: {d}\n", .{try part2(num, allocator)});
}

test "next dir" {
    try std.testing.expectEqual(Dir.left.next(), Dir.down);
}

test "point as hash key" {
    var values = std.AutoHashMap(Point, u32).init(std.testing.allocator);
    defer values.deinit();
    try values.put(Point{ .x = 2, .y = 3 }, 123);
    try std.testing.expectEqual(values.get(Point{ .x = 2, .y = 3 }), 123);
}
