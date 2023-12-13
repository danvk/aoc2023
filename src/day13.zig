const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const Coord = @import("./dir.zig").Coord;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

fn findMirrorY(grid: std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize) ?i32 {
    for (0..maxY) |myu| {
        const mirrorY: i32 = @intCast(myu);
        var isMatch = true;
        for (0..maxY + 1) |y| {
            for (0..maxX + 1) |x| {
                var c = grid.get(Coord{ .x = @intCast(x), .y = @intCast(y) }).?;
                var my: i32 = mirrorY + 1 + (mirrorY - @as(i32, @intCast(y)));

                var other = grid.get(Coord{ .x = @intCast(x), .y = my }) orelse c;
                if (other != c) {
                    isMatch = false;
                }
            }
        }
        if (isMatch) {
            return 1 + mirrorY;
        }
    }
    return null;
}

fn findMirrorX(grid: std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize) ?i32 {
    for (0..maxX) |mxu| {
        const mirrorX: i32 = @intCast(mxu);
        var isMatch = true;
        for (0..maxY + 1) |y| {
            for (0..maxX + 1) |x| {
                var c = grid.get(Coord{ .x = @intCast(x), .y = @intCast(y) }).?;
                var mx: i32 = mirrorX + 1 + (mirrorX - @as(i32, @intCast(x)));

                var other = grid.get(Coord{ .x = mx, .y = @intCast(y) }) orelse c;
                if (other != c) {
                    isMatch = false;
                }
            }
        }
        if (isMatch) {
            return 1 + mirrorX;
        }
    }
    return null;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var sum: i32 = 0;
    var isLast = false;
    while (!isLast) {
        var y: usize = 0;
        var grid = std.AutoHashMap(Coord, u8).init(allocator);
        defer grid.deinit();
        var maxY: usize = 0;
        var maxX: usize = 0;
        isLast = true;
        while (try iter.next()) |line| {
            if (line.len == 0) {
                isLast = false;
                break;
            }
            for (line, 0..) |c, x| {
                try grid.putNoClobber(Coord{ .x = @intCast(x), .y = @intCast(y) }, c);
                maxX = @intCast(x);
            }
            maxY = y;
            y += 1;
            std.debug.print("{s}\n", .{line});
        }

        var mirrorX = findMirrorX(grid, maxX, maxY);
        var mirrorY = findMirrorY(grid, maxX, maxY);
        std.debug.print("mirrorX: {?d} / y: {?d}\n", .{ mirrorX, mirrorY });
        assert((mirrorX == null) != (mirrorY == null));
        sum += 100 * (mirrorY orelse 0) + (mirrorX orelse 0);
    }

    std.debug.print("part 1: {d}\n", .{sum});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
