const std = @import("std");
const util = @import("./util.zig");
const Dir = @import("./dir.zig").Dir;
const Coord = @import("./dir.zig").Coord;

const assert = std.debug.assert;

const Carrier = struct {
    pos: Coord,
    dir: Dir,
};

fn advance(grid: *std.AutoHashMap(Coord, bool), carrier: Carrier) !struct { Carrier, bool } {
    const c = grid.get(carrier.pos) orelse false;
    var dir = carrier.dir;
    if (c) {
        // If the current node is infected, it turns to its right.
        dir = dir.cw();
    } else {
        // Otherwise, it turns to its left.
        dir = dir.ccw();
    }

    // If the current node is clean, it becomes infected.
    // Otherwise, it becomes cleaned.
    const infected = !c;
    try grid.put(carrier.pos, infected);

    // The virus carrier moves forward one node in the direction it is facing.
    const next = carrier.pos.move(dir);
    return .{ Carrier{
        .pos = next,
        .dir = dir,
    }, infected };
}

fn part1(allocator: std.mem.Allocator, grid: *std.AutoHashMap(Coord, bool), w: usize, numRounds: usize) !usize {
    _ = allocator;
    assert(w % 2 == 1);
    const mid: i32 = @intCast((w - 1) / 2);
    var curNode = Coord{ .x = mid, .y = mid };
    var curDir = Dir.up;
    var carrier = Carrier{ .pos = curNode, .dir = curDir };
    std.debug.print("start state: {any}\n", .{carrier});

    var numInfects: usize = 0;

    for (0..numRounds) |i| {
        var pair = try advance(grid, carrier);
        carrier = pair[0];
        const causedInfection = pair[1];
        std.debug.print("{d} infect? {any}\n", .{ i, causedInfection });
        if (causedInfection) {
            numInfects += 1;
        }

        // try printGrid(allocator, grid.*);
    }
    return numInfects;
}

fn printGrid(allocator: std.mem.Allocator, grid: std.AutoHashMap(Coord, bool)) !void {
    var minX: i32 = 0;
    var minY: i32 = 0;
    var maxX: i32 = 0;
    var maxY: i32 = 0;

    var it = grid.keyIterator();
    while (it.next()) |coord| {
        const x = coord.x;
        const y = coord.y;
        minX = @min(minX, x);
        maxX = @max(maxX, x);
        minY = @min(minY, y);
        maxY = @max(maxY, y);
    }

    const w: usize = @intCast(maxX - minX + 1);
    const h: usize = @intCast(maxY - minY + 1);
    var buf = try allocator.alloc(u8, w);
    defer allocator.free(buf);
    for (0..h) |y| {
        for (0..w) |x| {
            const v = grid.get(Coord{ .x = @intCast(x), .y = @intCast(y) }) orelse false;
            if (v) {
                buf[x] = '#';
            } else {
                buf[x] = '.';
            }
        }
        std.debug.print("{s}\n", .{buf});
    }
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var grid = std.AutoHashMap(Coord, bool).init(allocator);
    defer grid.deinit();

    var y: i32 = 0;
    var w: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        w = line.len;
        for (line, 0..) |c, i| {
            var v = false;
            if (c == '.') {
                v = false;
            } else if (c == '#') {
                v = true;
            } else {
                unreachable;
            }
            try grid.putNoClobber(Coord{ .x = @intCast(i), .y = y }, v);
        }
        y += 1;
    }
    const h: usize = @intCast(y);
    assert(w == h);

    try printGrid(allocator, grid);
    std.debug.print("part 1: {d}\n", .{try part1(allocator, &grid, w, 10_000)});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, instructions.items)});
}
