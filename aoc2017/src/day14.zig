const std = @import("std");
const util = @import("./util.zig");
const hashString = @import("./day10.zig").hashString;

const assert = std.debug.assert;

pub fn part1(allocator: std.mem.Allocator, key: []const u8) !u32 {
    _ = key;
    _ = allocator;
    var i: u128 = 1;
    _ = i;
    return 12;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const key = args[0];

    std.debug.print("part 1: {d}\n", .{try part1(allocator, key)});
    // std.debug.print("part 2: {d}\n", .{part2(layers, maxLayer)});
}
