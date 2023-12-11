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

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var galaxies = std.ArrayList(Coord).init(allocator);
    defer galaxies.deinit();

    var iter = try bufIter.iterLines(filename);
    var y: i32 = 0;
    var maxY: i32 = 0;
    var maxX: i32 = 0;
    while (try iter.next()) |line| {
        for (line, 0..) |c, x| {
            if (c == '#') {
                try galaxies.append(Coord{ .x = @intCast(x), .y = y });
            }
            maxX = @intCast(x);
        }
        maxY = y;
        y += 1;
    }
    const extent = Coord{ .x = maxX, .y = maxY };
    _ = extent;

    var freeX = std.ArrayList(usize).init(allocator);
    defer freeX.deinit();

    for (0..@intCast(maxX)) |x| {
        for (galaxies.items) |c| {
            if (c.x == x) {
                break;
            }
        } else {
            try freeX.append(x);
        }
    }

    var freeY = std.ArrayList(usize).init(allocator);
    defer freeY.deinit();

    for (0..@intCast(maxY)) |yi| {
        for (galaxies.items) |c| {
            if (c.y == yi) {
                break;
            }
        } else {
            try freeY.append(yi);
        }
    }

    std.debug.print("{any}\n", .{freeX.items});
    std.debug.print("{any}\n", .{freeY.items});

    for (galaxies.items, 0..) |c, i| {
        var bumpX: i32 = 0;
        for (freeX.items) |fx| {
            if (fx < c.x) {
                bumpX += 1;
            }
        }

        var bumpY: i32 = 0;
        for (freeY.items) |fy| {
            if (fy < c.y) {
                bumpY += 1;
            }
        }
        galaxies.items[i] = Coord{ .x = c.x + bumpX, .y = c.y + bumpY };
    }

    var part1: u32 = 0;
    for (galaxies.items, 0..) |g1, i| {
        for (galaxies.items[(i + 1)..], (i + 1)..) |g2, j| {
            var d = std.math.absCast(g1.x - g2.x) + std.math.absCast(g1.y - g2.y);
            std.debug.print("{d} -> {d}: {d}\n", .{ i + 1, j + 1, d });
            part1 += d;
        }
    }
    // std.debug.print("{any}\n", .{galaxies.items});

    std.debug.print("part 1: {d}\n", .{part1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
