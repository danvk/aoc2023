const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const dirMod = @import("./dir.zig");
const Dir = dirMod.Dir;
const Coord = dirMod.Coord;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

// | is a vertical pipe connecting north and south.
// - is a horizontal pipe connecting east and west.
// L is a 90-degree bend connecting north and east.
// J is a 90-degree bend connecting north and west.
// 7 is a 90-degree bend connecting south and west.
// F is a 90-degree bend connecting south and east.
// . is ground; there is no pipe in this tile.
// S is the starting position of the animal; there is a pipe on this tile, but your sketch doesn't show what shape the pipe has.

const Tile = enum(u8) { @"|", @"-", L, J, @"7", F, @".", S };

fn neighborsForTile(tile: Tile) struct { Dir, Dir } {
    return switch (tile) {
        .@"|" => .{ .up, .down },
        .@"-" => .{ .left, .right },
        .L => .{ .up, .right },
        .J => .{ .up, .left },
        .@"7" => .{ .left, .down },
        .F => .{ .down, .right },
        else => unreachable,
    };
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var grid = std.AutoHashMap(Coord, Tile).init(allocator);
    defer grid.deinit();

    var y: i32 = 0;
    var w: usize = 0;
    var start: Coord = undefined;
    while (try iter.next()) |line| {
        w = line.len;
        for (line, 0..) |c, i| {
            var tile = std.meta.stringToEnum(Tile, &[_]u8{c}).?;
            var coord = Coord{ .x = @intCast(i), .y = y };

            if (tile == Tile.@".") {
                continue;
            } else if (tile == Tile.S) {
                start = coord;
            }
            std.debug.print("{any} {any}\n", .{ coord, tile });
            try grid.putNoClobber(coord, tile);
        }
        y += 1;
    }
    const h: usize = @intCast(y);
    assert(w == h);

    var starts = std.ArrayList(Coord).init(allocator);
    defer starts.deinit();
    for (dirMod.DIRS) |dir| {
        var c = start.move(dir);
        var maybeTile = grid.get(c);
        if (maybeTile) |tile| {
            var moves = neighborsForTile(tile);
            if (std.meta.eql(c.move(moves[0]), start) or std.meta.eql(c.move(moves[1]), start)) {
                try starts.append(c);
            }
        }
    }

    std.debug.print("start: {any}\n", .{start});
    std.debug.print("starts: {any}\n", .{starts.items});

    // std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
