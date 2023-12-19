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

fn fmtChar(c: ?u8) u8 {
    return c orelse '.';
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

// var area2: i32 = 0;
// const xys = coords.items;
// for (xys[0 .. xys.len - 1], xys[1..]) |a, b| {
//     std.debug.print("{d},{d}\n", .{ a.x, a.y });
//     area2 += a.x * b.y - b.x * a.y;
// }
// var area = @divFloor(area2, 2);
// std.debug.print("area: {d}\n", .{area});

fn area(grid: std.AutoHashMap(Coord, u8), topLeft: Coord, bottomRight: Coord) usize {
    const minX = topLeft.x;
    const minY = topLeft.y;
    const maxX = bottomRight.x;
    const maxY = bottomRight.y;
    var part2alt: usize = 0;
    var y = minY;
    while (y <= maxY) : (y += 1) {
        var numBars: usize = 0;
        var prevCorner: ?u8 = null;

        var x = minX;
        while (x <= maxX) : (x += 1) {
            var c = Coord{ .x = x, .y = y };
            if (!grid.contains(c)) {
                if (numBars % 2 == 1) {
                    part2alt += 1;
                }
            } else {
                var tile = grid.get(c).?;
                if (tile == '|') {
                    numBars += 1;
                } else if (tile == 'J' and prevCorner == 'F') {
                    numBars += 1;
                } else if (tile == '7' and prevCorner == 'L') {
                    numBars += 1;
                }
                if (tile != '-') {
                    prevCorner = tile;
                }
            }
        }
    }
    return part2alt;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var grid = std.AutoHashMap(Coord, u8).init(allocator);
    defer grid.deinit();
    var pos = Coord{ .x = 0, .y = 0 };

    try grid.put(pos, '?');

    var iter = try bufIter.iterLines(filename);
    var minX: i32 = 0;
    var minY: i32 = 0;
    var maxX: i32 = 0;
    var maxY: i32 = 0;
    var coords = std.ArrayList(Coord).init(allocator);
    defer coords.deinit();
    try coords.append(pos);
    var firstD: ?dirMod.Dir = null;
    var lastD = dirMod.Dir.up;
    while (try iter.next()) |line| {
        const plan = try parsePlan(line);
        std.debug.print("{any}\n", .{plan});

        const d = plan.dir;
        if (firstD == null) {
            firstD = d;
        }
        for (0..plan.len) |i| {
            if (i == 0) {
                try grid.put(pos, if (d == .up and lastD == .left) 'L' else if (d == .up and lastD == .right) 'J' else if (d == .down and lastD == .left) 'F' else if (d == .down and lastD == .right) '7' else if (d == .left and lastD == .up) '7' else if (d == .left and lastD == .down) 'J' else if (d == .right and lastD == .up) 'F' else if (d == .right and lastD == .down) 'L' else unreachable);
            }
            pos = pos.move(d);
            try grid.put(pos, if (d == .up or d == .down) '|' else '-');
            maxX = @max(pos.x, maxX);
            maxY = @max(pos.y, maxY);
            minX = @min(pos.x, minX);
            minY = @min(pos.y, minY);
        }
        lastD = d;
        try coords.append(pos);
    }
    const d = firstD.?;
    try grid.put(pos, if (d == .up and lastD == .left) 'L' else if (d == .up and lastD == .right) 'J' else if (d == .down and lastD == .left) 'F' else if (d == .down and lastD == .right) '7' else if (d == .left and lastD == .up) '7' else if (d == .left and lastD == .down) 'J' else if (d == .right and lastD == .up) 'F' else if (d == .right and lastD == .down) 'L' else unreachable);
    std.debug.print("{d}-{d}, {d}-{d} {any}\n", .{ minX, maxX, minY, maxY, pos });
    std.debug.print("count: {d}\n", .{grid.count()});

    const tl = Coord{ .x = minX, .y = minY };
    const br = Coord{ .x = maxX, .y = maxY };
    gridMod.printGridFmt(u8, grid, tl, br, fmtChar);

    // try fill(&grid, Coord{ .x = 1, .y = 1 });
    const count = grid.count();
    const intArea = area(grid, tl, br);

    std.debug.print("part 1: {d} + {d} = {d}\n", .{ count, intArea, count + intArea });

    // std.debug.print("part 2: {d}\n", .{});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
