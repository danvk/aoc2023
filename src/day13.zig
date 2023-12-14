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

fn findMirrorY(grid: std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize, exclude: ?i32) ?i32 {
    for (0..maxY) |myu| {
        const mirrorY: i32 = @intCast(myu);
        if (1 + mirrorY == exclude) {
            continue;
        }
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

fn findMirrorX(grid: std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize, exclude: ?i32) ?i32 {
    for (0..maxX) |mxu| {
        const mirrorX: i32 = @intCast(mxu);
        if (1 + mirrorX == exclude) {
            continue;
        }
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

// TODO: implement transpose

fn printGrid(grid: std.AutoHashMap(Coord, u8), maxX: usize, maxY: usize) void {
    for (0..maxY + 1) |y| {
        for (0..maxX + 1) |x| {
            var c = grid.get(Coord{ .x = @intCast(x), .y = @intCast(y) }) orelse ' ';
            std.debug.print("{c}", .{c});
        }
        std.debug.print("\n", .{});
    }
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var sum1: i32 = 0;
    var sum2: i32 = 0;
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
            // std.debug.print("{s}\n", .{line});
        }

        var rawMirrorX = findMirrorX(grid, maxX, maxY, null);
        var rawMirrorY = findMirrorY(grid, maxX, maxY, null);
        assert((rawMirrorX == null) != (rawMirrorY == null));
        const count1: i32 = 100 * (rawMirrorY orelse 0) + (rawMirrorX orelse 0);
        assert(count1 != 0);
        sum1 += count1;

        printGrid(grid, maxX, maxY);
        std.debug.print("raw: {?d}/{?d} -> {d}\n", .{ rawMirrorX, rawMirrorY, count1 });

        var thisSum: i32 = 0;
        for (0..maxX + 1) |xi| {
            for (0..maxY + 1) |yi| {
                const k = Coord{ .x = @intCast(xi), .y = @intCast(yi) };
                const c = grid.get(k).?;
                try grid.put(k, if (c == '#') '.' else '#');
                var mirrorX = findMirrorX(grid, maxX, maxY, rawMirrorX);
                var mirrorY = findMirrorY(grid, maxX, maxY, rawMirrorY);
                var count2: i32 = 100 * (mirrorY orelse 0) + (mirrorX orelse 0);
                std.debug.print("set {any} was {c} -> {?d}/{?d} {d}\n", .{ k, c, mirrorX, mirrorY, count2 });
                // printGrid(grid, maxX, maxY);
                try grid.put(k, c);

                if (mirrorX == null and mirrorY == null) {
                    continue;
                }
                if (count1 != count2) {
                    if (mirrorX != null and mirrorY != null) {
                        count2 -= count1;
                    }
                    //std.debug.print("{any} mirrorX: {?d} / y: {?d}\n", .{ k, mirrorX, mirrorY });
                    // assert((mirrorX == rawMirrorX) != (mirrorY == rawMirrorY));
                    // var countX = if (mirrorX == null or mirrorX == rawMirrorX) 0 else (mirrorX orelse 0);
                    // var countY = if (mirrorY == null or mirrorY == rawMirrorY) 0 else (mirrorY orelse 0);
                    // if (countX != 0) {
                    //     std.debug.print("match! {any} mirrorX: {?d}\n", .{ k, countX });
                    // }
                    // if (countY != 0) {
                    //     std.debug.print("match! {any} mirrorY: {?d}\n", .{ k, countY });
                    // }
                    // if (countX == 0 and countY == 0) {
                    //     std.debug.print("should not happen; x:{?d}/{?d}, y:{?d}/{?d}\n", .{ rawMirrorX, mirrorX, rawMirrorY, mirrorY });
                    // }
                    // assert(countX == 0 or countY == 0);
                    // const newSum: i32 = 100 * (countY) + (countX);
                    if (thisSum != 0) {
                        assert(thisSum == count2); // should be unique
                    }
                    std.debug.print("{any}: {?d} / {?d} +{d}\n", .{ k, mirrorX, mirrorY, count2 });
                    thisSum = count2;
                    // break :outer;
                }
            }
        }
        assert(thisSum != 0);
        sum2 += thisSum;
        std.debug.print("---\n", .{});
    }

    std.debug.print("part 1: {d}\n", .{sum1});
    std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
