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

fn rhsForMove(tile: Tile) ?struct { Dir, Dir } {
    return switch (tile) {
        // if you have moved into this square from the down direction, then
        // the RHS is right, otherwise it's left.
        // .@"|" => .{ .up, .down },
        .@"|" => .{ .left, .right },
        // .@"-" => .{ .left, .right },
        .@"-" => .{ .down, .up },
        .L => null,
        .J => null,
        .@"7" => null,
        .F => null,
        else => unreachable,
    };
}

fn rhsForDiag(tile: Tile, idx: usize) ?struct { Dir, Dir } {
    return switch (tile) {
        // if you have moved into this square from the down direction, then
        // the RHS is right, otherwise it's left.
        .@"|" => null,
        .@"-" => null,
        // .L => .{ .up, .right },
        .L => if (idx == 0) .{ .left, .down } else null,
        // .J => .{ .up, .left },
        .J => if (idx == 0) null else .{ .down, .right },
        // .@"7" => .{ .left, .down },
        .@"7" => if (idx == 0) null else .{ .right, .up },
        // .F => .{ .down, .right },
        .F => if (idx == 0) null else .{ .up, .left },
        else => unreachable,
    };
}

fn part2(allocator: std.mem.Allocator, start: Coord, step1: Coord, grid: std.AutoHashMap(Coord, Tile), ds: std.AutoHashMap(Coord, usize)) !usize {

    // Find some interior cells. Assume the first direction from start is clockwise.
    // So the interior is on your right.
    var fringe = std.AutoHashMap(Coord, void).init(allocator);
    defer fringe.deinit();

    var lastNode = start;
    var pos = step1;
    while (true) {
        var tile = grid.get(pos).?;
        if (tile == Tile.S) {
            break; // completed the loop
        }

        var moves = neighborsForTile(tile);
        var a = moves[0];
        var b = moves[1];
        var interiorDirs = rhsForMove(tile);
        var interiorDir: ?Dir = null;
        var diagIntDirs: ?struct { Dir, Dir } = null;
        if (std.meta.eql(pos.move(a), lastNode)) {
            if (interiorDirs) |id| {
                interiorDir = id[0];
            } else {
                diagIntDirs = rhsForDiag(tile, 0);
            }
            lastNode = pos;
            pos = pos.move(b);
        } else if (std.meta.eql(pos.move(b), lastNode)) {
            if (interiorDirs) |id| {
                interiorDir = id[1];
            } else {
                diagIntDirs = rhsForDiag(tile, 1);
            }
            lastNode = pos;
            pos = pos.move(a);
        } else {
            unreachable;
        }
        var candidates = std.ArrayList(Dir).init(allocator);
        defer candidates.deinit();
        if (interiorDir) |id| {
            try candidates.append(id);
        }
        if (diagIntDirs) |diags| {
            try candidates.append(diags[0]);
            try candidates.append(diags[1]);
            std.debug.print("{any} diagonal candidates: {any}\n", .{ lastNode, diags });
        }
        for (candidates.items) |id| {
            var p = lastNode.move(id);
            if (!ds.contains(p)) {
                try fringe.put(p, undefined);
                std.debug.print("{any} added to fringe: {any}\n", .{ lastNode, p });
            }
        }
    }

    std.debug.print("fringe:\n", .{});
    var it = fringe.keyIterator();
    while (it.next()) |int| {
        std.debug.print("  {any}\n", .{int});
    }

    return fringe.count();
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
            // std.debug.print("{any} {any}\n", .{ coord, tile });
            try grid.putNoClobber(coord, tile);
        }
        y += 1;
    }
    const h: usize = @intCast(y);
    _ = h;

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

    var ds = std.AutoHashMap(Coord, usize).init(allocator);
    defer ds.deinit();
    try ds.put(start, 0);

    var maxSteps: usize = 0;
    _ = maxSteps;
    for (starts.items) |step1| {
        var numSteps: usize = 0;
        var lastNode = start;
        var pos = step1;
        while (true) {
            numSteps += 1;
            var tile = grid.get(pos).?;

            // std.debug.print("{any} {any}\n", .{ pos, tile });
            var prev = ds.get(pos) orelse 1_000_000;
            if (numSteps < prev) {
                try ds.put(pos, numSteps);
            }
            if (tile == Tile.S) {
                break; // completed the loop
            }

            var moves = neighborsForTile(tile);
            var a = moves[0];
            var b = moves[1];
            if (std.meta.eql(pos.move(a), lastNode)) {
                lastNode = pos;
                pos = pos.move(b);
            } else if (std.meta.eql(pos.move(b), lastNode)) {
                lastNode = pos;
                pos = pos.move(a);
            } else {
                unreachable;
            }
        }
        std.debug.print("part 1: {d}\n", .{util.hashMaxValue(Coord, usize, ds).?});
    }

    // std.debug.print("part 1: {d}\n", .{sum1});
    std.debug.print("part 2: {d}\n", .{try part2(allocator, start, starts.items[0], grid, ds)});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
