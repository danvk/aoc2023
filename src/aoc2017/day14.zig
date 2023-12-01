const std = @import("std");
const util = @import("./util.zig");
const hashString = @import("./day10.zig").hashString;
const Dir = @import("./dir.zig").Dir;
const DIRS = @import("./dir.zig").DIRS;
const Coord = @import("./dir.zig").Coord;

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

// Caller is responsible for freeing the returned Arraylist.
pub fn findCluster(allocator: std.mem.Allocator, grid: std.AutoHashMap(Coord, void), seed: Coord) !std.ArrayList(Coord) {
    var seen = std.AutoHashMap(Coord, void).init(allocator);
    defer seen.deinit();

    var fringe = std.ArrayList(Coord).init(allocator);

    try fringe.append(seed);
    while (fringe.popOrNull()) |coord| {
        if (seen.contains(coord)) {
            continue;
        }
        try seen.put(coord, undefined);
        for (DIRS) |dir| {
            const n = coord.move(dir);
            if (grid.contains(n) and !seen.contains(n)) {
                try fringe.append(n);
            }
        }
    }

    var it = seen.keyIterator();
    while (it.next()) |id| {
        try fringe.append(id.*);
    }

    return fringe;
}

fn numClusters(allocator: std.mem.Allocator, grid: std.AutoHashMap(Coord, void)) !u32 {
    var seen = std.AutoHashMap(Coord, void).init(allocator);
    defer seen.deinit();

    var num: u32 = 0;
    var it = grid.keyIterator();
    while (it.next()) |id| {
        if (seen.contains(id.*)) {
            continue;
        }
        num += 1;

        var cluster = try findCluster(allocator, grid, id.*);
        defer cluster.deinit();
        // std.debug.print("Cluster: {any}\n", .{cluster.items});
        for (cluster.items) |cluster_id| {
            try seen.put(cluster_id, undefined);
        }
    }
    return num;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const key = args[0];

    std.debug.print("part 1: {d}\n", .{try part1(allocator, key)});
    var grid = try makeGrid(allocator, key);
    defer grid.deinit();
    std.debug.print("part 2: {d}\n", .{try numClusters(allocator, grid)});
}

const expectEqual = std.testing.expectEqual;

test "numBitsSets" {
    try expectEqual(@as(u32, 0), numBitsSet(u32, 0));
    try expectEqual(@as(u32, 1), numBitsSet(u32, 1));
    try expectEqual(@as(u32, 1), numBitsSet(u32, 2));
    try expectEqual(@as(u32, 2), numBitsSet(u32, 3));
}
