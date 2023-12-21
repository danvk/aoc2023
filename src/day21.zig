const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const dirMod = @import("./dir.zig");
const gridMod = @import("./grid.zig");

const Coord = dirMod.Coord;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

fn findStart(grid: std.AutoHashMap(Coord, u8)) Coord {
    var it = grid.iterator();
    while (it.next()) |entry| {
        if (entry.value_ptr.* == 'S') {
            return entry.key_ptr.*;
        }
    }
    unreachable;
}

fn step(gr: *gridMod.GridResult, spots: std.AutoHashMap(Coord, void), nexts: *std.AutoHashMap(Coord, void)) !void {
    nexts.clearAndFree();
    var it = spots.keyIterator();
    var grid = gr.grid;
    while (it.next()) |pos| {
        for (dirMod.DIRS) |d| {
            var p = pos.move(d);
            if ((grid.get(p) orelse '.') == '.') {
                try nexts.put(p, undefined);
            }
        }
    }
}

fn printKeys(grid: std.AutoHashMap(Coord, void)) void {
    var it = grid.keyIterator();
    while (it.next()) |pos| {
        std.debug.print("{any} ", .{pos});
    }
    std.debug.print("\n", .{});
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var gr = try gridMod.readGrid(allocator, filename, null);
    var grid = gr.grid;
    defer grid.deinit();

    const start = findStart(grid);
    try grid.put(start, '.');

    std.debug.print("start: {any}\n", .{start});

    var spots = std.AutoHashMap(Coord, void).init(allocator);
    try spots.put(start, undefined);
    for (0..64) |i| {
        var nextSpots = std.AutoHashMap(Coord, void).init(allocator);

        try step(&gr, spots, &nextSpots);
        std.debug.print("{d}: {d}\n", .{ i, nextSpots.count() });
        // printKeys(nextSpots);

        spots.deinit();
        spots = nextSpots;
    }

    spots.deinit();

    // std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
