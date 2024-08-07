const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const readGrid = @import("./grid.zig").readGrid;
const printGrid = @import("./grid.zig").printGrid;
const rotCW = @import("./grid.zig").rotCW;
const Coord = @import("./dir.zig").Coord;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

pub fn shiftUp(grid: *std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize) !void {
    for (0..(1 + maxX)) |xu| {
        const x: i32 = @intCast(xu);
        for (0..(1 + maxY)) |yu| {
            // If relevant, roll this rock as far up as it will go.
            // Important to start from the top and work down.
            const y: i32 = @intCast(yu);
            const init = Coord{ .x = x, .y = y };
            if (grid.get(init) orelse '.' != 'O') {
                continue;
            }

            var last = init;
            for (1..(yu + 1)) |dy| {
                const up = Coord{ .x = x, .y = (y - @as(i32, @intCast(dy))) };
                if (grid.get(up) orelse '.' == '.') {
                    try grid.put(last, '.');
                    try grid.put(up, 'O');
                    last = up;
                } else {
                    break;
                }
            }
        }
    }
}

pub fn weight(grid: std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize) i32 {
    var sum: i32 = 0;
    for (0..(1 + maxX)) |xu| {
        const x: i32 = @intCast(xu);
        for (0..(1 + maxY)) |yu| {
            // If relevant, roll this rock as far up as it will go.
            // Important to start from the top and work down.
            const y: i32 = @intCast(yu);
            const k = Coord{ .x = x, .y = y };
            if (grid.get(k) == 'O') {
                const count = @as(i32, @intCast(maxY)) + 1 - y;
                sum += count;
            }
        }
    }
    return sum;
}

fn spin(grid: *std.AutoHashMap(Coord, u8), dim: usize) !void {
    try shiftUp(grid, dim, dim); // shift north
    try rotCW(grid, dim, dim);
    try shiftUp(grid, dim, dim); // shift west
    try rotCW(grid, dim, dim);
    try shiftUp(grid, dim, dim); // shift south
    try rotCW(grid, dim, dim);
    try shiftUp(grid, dim, dim); // shift east
    try rotCW(grid, dim, dim);
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    const gridResult = try readGrid(allocator, filename, 'x');
    var grid = gridResult.grid;
    defer grid.deinit();
    const maxX = gridResult.maxX;
    const maxY = gridResult.maxY;

    printGrid(grid, maxX, maxY, '.');
    std.debug.print("---\n", .{});

    assert(maxX == maxY);
    assert(maxX % 2 == 1);

    // try shiftUp(&grid, maxX, maxY);
    // const sum1 = weight(grid, maxX, maxY);
    var timer = try std.time.Timer.start();
    for (0..1000000000) |n| {
        try spin(&grid, maxX);
        if (n % 10_000 == 0) {
            const elapsed = timer.read() / 1_000_000_000;
            const w = weight(grid, maxX, maxY);
            std.debug.print("{d}: {d}s, weight={d}\n", .{ n, elapsed, w });
        }
        if ((n < 100) or (n > 100_000 and n < 100_999)) {
            const w = weight(grid, maxX, maxY);
            std.debug.print("{d} {d}\n", .{ n + 1, w });
        }
        if (n == 101_000) {
            break;
        }
    }

    const sum2 = weight(grid, maxX, maxY);

    printGrid(grid, maxX, maxY, '.');
    std.debug.print("---\n", .{});

    // std.debug.print("part 1: {d}\n", .{sum1});
    std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
