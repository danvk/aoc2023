const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const readGrid = @import("./grid.zig").readGrid;
const printGrid = @import("./grid.zig").printGrid;
const Coord = @import("./dir.zig").Coord;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var gridResult = try readGrid(allocator, filename, '.');
    var grid = gridResult.grid;
    defer grid.deinit();
    const maxX = gridResult.maxX;
    const maxY = gridResult.maxY;

    printGrid(grid, maxX, maxY, '.');
    std.debug.print("---\n", .{});

    var sum1: i32 = 0;
    for (0..(1 + maxX)) |xu| {
        const x: i32 = @intCast(xu);
        for (0..(1 + maxY)) |yu| {
            // If relevant, roll this rock as far up as it will go.
            // Important to start from the top and work down.
            var y: i32 = @intCast(yu);
            const init = Coord{ .x = x, .y = y };
            if (grid.get(init) orelse '.' != 'O') {
                continue;
            }

            var last = init;
            for (1..(yu + 1)) |dy| {
                const up = Coord{ .x = x, .y = (y - @as(i32, @intCast(dy))) };
                if (grid.get(up) orelse '.' == '.') {
                    _ = grid.remove(last);
                    try grid.put(up, 'O');
                    last = up;
                } else {
                    break;
                }
            }
            const count = @as(i32, @intCast(maxY)) + 1 - last.y;
            sum1 += count;
        }
    }

    printGrid(grid, maxX, maxY, '.');
    std.debug.print("---\n", .{});

    std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
