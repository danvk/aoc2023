const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const Coord = @import("./dir.zig").Coord;

const assert = std.debug.assert;

pub const GridResult = struct {
    grid: std.AutoHashMap(Coord, u8),
    maxX: usize,
    maxY: usize,
    extent: Coord,
};

// Read input a file into a Coord -> u8 hash map.
// Caller is responsible for freeing the hash map.
pub fn readGrid(allocator: std.mem.Allocator, filename: []const u8, blankChar: ?u8) !GridResult {
    var grid = std.AutoHashMap(Coord, u8).init(allocator);

    var iter = try bufIter.iterLines(filename);
    var y: usize = 0;
    var maxY: usize = 0;
    var maxX: usize = 0;
    while (try iter.next()) |line| {
        for (line, 0..) |c, x| {
            if (blankChar == null or c != blankChar) {
                try grid.putNoClobber(Coord{ .x = @intCast(x), .y = @intCast(y) }, c);
            }
            maxX = @intCast(x);
        }
        maxY = y;
        y += 1;
    }

    return GridResult{
        .grid = grid,
        .maxX = maxX,
        .maxY = maxY,
        .extent = Coord{ .x = @intCast(maxX), .y = @intCast(maxY) },
    };
}

pub fn printGrid(grid: std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize, blankChar: ?u8) void {
    for (0..maxY + 1) |y| {
        for (0..maxX + 1) |x| {
            var c = grid.get(Coord{ .x = @intCast(x), .y = @intCast(y) }) orelse blankChar orelse ' ';
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}

// ABCD
// FGHI
// KLMN
// PQRS

// PKFA
// QLGB
// RMHC
// SNID

// (0, 1) -> (4, 3)

pub fn rotCW(grid: *std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize) !void {
    assert(maxX == maxY);
    assert(maxX % 2 == 1);

    const mx: i32 = @intCast(maxX);
    const my: i32 = @intCast(maxY);

    const midX = 1 + (maxX >> 1);
    const midY = 1 + (maxY >> 1);
    std.debug.print("midX: {d}, midY: {d}\n", .{ midX, midY });

    for (0..(midX)) |xu| {
        const x: i32 = @intCast(xu);
        for (0..(midY)) |yu| {
            const y: i32 = @intCast(yu);
            const c1 = Coord{ .x = x, .y = y };
            const c2 = Coord{ .x = mx - y, .y = x };
            const c3 = Coord{ .x = mx - x, .y = my - y };
            const c4 = Coord{ .x = y, .y = my - x };
            const v1 = grid.get(c1).?;
            const v2 = grid.get(c2).?;
            const v3 = grid.get(c3).?;
            const v4 = grid.get(c4).?;

            try grid.put(c2, v1);
            try grid.put(c3, v2);
            try grid.put(c4, v3);
            try grid.put(c1, v4);
        }
    }
}

test "rotate grid" {
    var gr = try readGrid(std.testing.allocator, "day14/grid-test.txt", '.');
    var grid = gr.grid;
    defer grid.deinit();
    std.debug.print("maxX: {d}, maxY: {d}\n", .{ gr.maxX, gr.maxY });
    try rotCW(&grid, gr.maxX, gr.maxY);
    printGrid(grid, gr.maxX, gr.maxY, '.');
}
