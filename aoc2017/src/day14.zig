const std = @import("std");
const util = @import("./util.zig");
const hashString = @import("./day10.zig").hashString;

const assert = std.debug.assert;

fn numBitsSet(comptime T: type, val: T) u32 {
    var num: u32 = 0;
    var v: T = val;
    while (v != 0) {
        if (v & 1 == 1) {
            num += 1;
        }
        v >>= 1;
    }
    return num;
}

pub fn part1(allocator: std.mem.Allocator, key: []const u8) !u32 {
    var numSet: u32 = 0;
    var buf: [100]u8 = undefined;
    for (0..128) |row| {
        const rowKey = try std.fmt.bufPrint(&buf, "{s}-{d}", .{ key, row });
        const hash = try hashString(allocator, rowKey);
        std.debug.print("{d:>3} {b:0>128}\n", .{ row, hash });
        numSet += numBitsSet(u128, hash);
    }
    return numSet;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const key = args[0];

    std.debug.print("part 1: {d}\n", .{try part1(allocator, key)});
    // std.debug.print("part 2: {d}\n", .{part2(layers, maxLayer)});
}

const expectEqual = std.testing.expectEqual;

test "numBitsSets" {
    try expectEqual(@as(u32, 0), numBitsSet(u32, 0));
    try expectEqual(@as(u32, 1), numBitsSet(u32, 1));
    try expectEqual(@as(u32, 1), numBitsSet(u32, 2));
    try expectEqual(@as(u32, 2), numBitsSet(u32, 3));
}
