const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const Coord = @import("./dir.zig").Coord;

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
