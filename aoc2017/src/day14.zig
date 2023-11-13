const std = @import("std");
const util = @import("./util.zig");
const hashString = @import("./day10.zig").hashString;
const Dir = @import("./day3.zig").Dir;

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

const Coord = struct {
    x: i32,
    y: i32,

    pub fn n4(self: @This(), dir: Dir) Coord {
        return Coord{
            .x = self.x + dir.dx(),
            .y = self.y + dir.dy(),
        };
    }
};

// caller is responsible for freeing hash map
pub fn makeGrid(allocator: std.mem.Allocator, key: []const u8) !std.AutoHashMap(Coord, void) {
    var grid = std.AutoHashMap(Coord, void).init(allocator);

    var buf: [100]u8 = undefined;
    var numSet: u32 = 0;
    for (0..128) |row| {
        const rowKey = try std.fmt.bufPrint(&buf, "{s}-{d}", .{ key, row });
        const hash = try hashString(allocator, rowKey);
        const y: i32 = @intCast(row);
        // std.debug.print("{d:>3} {b:0>128}\n", .{ y, hash });
        for (0..128) |col| {
            if (hash & (@as(u128, 1) << @as(u7, @intCast(127 - col))) != 0) {
                const x: i32 = @intCast(col);
                try grid.putNoClobber(Coord{ .y = y, .x = x }, undefined);
                // std.debug.print("{d}, {d}\n", .{ x, y });
                numSet += 1;
            }
        }
    }

    std.debug.print("Num set: {d}\n", .{numSet});
    return grid;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const key = args[0];

    std.debug.print("part 1: {d}\n", .{try part1(allocator, key)});
    var grid = try makeGrid(allocator, key);
    defer grid.deinit();
    // std.debug.print("part 2: {d}\n", .{part2(layers, maxLayer)});
}

const expectEqual = std.testing.expectEqual;

test "numBitsSets" {
    try expectEqual(@as(u32, 0), numBitsSet(u32, 0));
    try expectEqual(@as(u32, 1), numBitsSet(u32, 1));
    try expectEqual(@as(u32, 1), numBitsSet(u32, 2));
    try expectEqual(@as(u32, 2), numBitsSet(u32, 3));
}
