const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const dirMod = @import("./dir.zig");
const gridMod = @import("./grid.zig");
const Coord = dirMod.Coord;

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

const Plan = struct {
    dir: dirMod.Dir,
    len: usize,
    color: u24,
};

// R 6 (#70c710)
fn parsePlan(line: []const u8) !Plan {
    var partsBuf: [3][]const u8 = undefined;
    var parts = util.splitAnyIntoBuf(line, " ()", &partsBuf);
    assert(parts.len == 3);
    var dir = parts[0];
    assert(dir.len == 1);
    var len = try std.fmt.parseInt(usize, parts[1], 10);
    var colorStr = parts[2];
    assert(colorStr[0] == '#');
    assert(colorStr.len == 7);
    var color = try std.fmt.parseInt(u24, colorStr[1..], 16);
    var plan = Plan{
        .dir = switch (dir[0]) {
            'L' => .left,
            'R' => .right,
            'U' => .up,
            'D' => .down,
            else => unreachable,
        },
        .len = len,
        .color = color,
    };
    return plan;
}

fn fmtColor(color: ?u24) u8 {
    return if (color == null) '.' else '#';
}

fn fill(grid: *std.AutoHashMap(Coord, u24), seed: Coord) !void {
    var fringe = std.ArrayList(Coord).init(grid.allocator);
    defer fringe.deinit();

    try fringe.append(seed);
    while (fringe.popOrNull()) |pos| {
        if (grid.contains(pos)) {
            continue;
        }

        try grid.put(pos, 0);
        for (dirMod.DIRS) |d| {
            const np = pos.move(d);
            if (!grid.contains(np)) {
                try fringe.append(np);
            }
        }
    }
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var grid = std.AutoHashMap(Coord, u24).init(allocator);
    defer grid.deinit();
    var pos = Coord{ .x = 0, .y = 0 };

    try grid.put(pos, 0);

    var iter = try bufIter.iterLines(filename);
    var minX: i32 = 0;
    var minY: i32 = 0;
    var maxX: i32 = 0;
    var maxY: i32 = 0;
    while (try iter.next()) |line| {
        const plan = try parsePlan(line);
        std.debug.print("{any}\n", .{plan});

        for (0..plan.len) |_| {
            pos = pos.move(plan.dir);
            try grid.put(pos, plan.color);
            maxX = @max(pos.x, maxX);
            maxY = @max(pos.y, maxY);
            minX = @min(pos.x, minX);
            minY = @min(pos.y, minY);
        }
    }
    std.debug.print("{d}-{d}, {d}-{d} {any}\n", .{ minX, maxX, minY, maxY, pos });
    std.debug.print("count: {d}\n", .{grid.count()});

    gridMod.printGridFmt(u24, grid, Coord{ .x = minX, .y = minY }, Coord{ .x = maxX, .y = maxY }, fmtColor);

    try fill(&grid, Coord{ .x = 1, .y = 1 });
    const sum1 = grid.count();

    std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
