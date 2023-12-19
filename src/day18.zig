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

// R 6 (#70c710)
fn parsePlan2(line: []const u8) !Plan {
    var partsBuf: [3][]const u8 = undefined;
    var parts = util.splitAnyIntoBuf(line, " ()", &partsBuf);
    assert(parts.len == 3);
    // var dir = parts[0];
    // assert(dir.len == 1);
    // var len = try std.fmt.parseInt(usize, parts[1], 10);
    var colorStr = parts[2];
    assert(colorStr[0] == '#');
    assert(colorStr.len == 7);
    var len = try std.fmt.parseInt(u24, colorStr[1..6], 16);
    const dir = colorStr[6];
    var plan = Plan{
        // 0 means R, 1 means D, 2 means L, and 3 means U.
        .dir = switch (dir) {
            '2' => .left,
            '0' => .right,
            '3' => .up,
            '1' => .down,
            else => unreachable,
        },
        .len = len,
        .color = len,
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

fn area(grid: std.AutoHashMap(Coord, u8), topLeft: Coord, bottomRight: Coord, ys: std.AutoHashMap(i32, void)) !usize {
    const minX = topLeft.x;
    const minY = topLeft.y;
    const maxX = bottomRight.x;
    const maxY = bottomRight.y;
    var part2alt: usize = 0;
    var y = minY;
    var timer = try std.time.Timer.start();
    var lastRowArea: usize = 0;
    var ysUsed: usize = 0;
    while (y <= maxY) : (y += 1) {
        if (!ys.contains(y)) {
            part2alt += lastRowArea;
            continue;
        }
        ysUsed += 1;
        const elapsed = timer.read() / 1_000_000_000;
        std.debug.print(" -> y={d}, {d}/{d} {d}s\n", .{ y, ysUsed, ys.count(), elapsed });
        var numBars: usize = 0;
        var prevCorner: ?u8 = null;
        lastRowArea = 0;

        var x = minX;
        while (x <= maxX) : (x += 1) {
            var c = Coord{ .x = x, .y = y };
            if (grid.get(c)) |tile| {
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
            } else {
                if (numBars % 2 == 1) {
                    lastRowArea += 1;
                }
            }
        }
        part2alt += lastRowArea;
    }
    return part2alt;
}

fn shoelaceArea(xys: []Coord) u64 {
    var area2: i64 = 0;
    for (xys[0 .. xys.len - 1], xys[1..]) |a, b| {
        std.debug.print("{d},{d}\n", .{ a.x, a.y });
        area2 += @as(i64, a.x) * b.y - @as(i64, b.x) * a.y;
    }
    assert(area2 > 0);
    return @divFloor(@as(u64, @intCast(area2)), 2);
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
    var countDirect: usize = 0;
    defer coords.deinit();
    // try coords.append(pos);
    var firstD: ?dirMod.Dir = null;
    var lastD = dirMod.Dir.up;
    while (try iter.next()) |line| {
        const plan = try parsePlan2(line);
        // std.debug.print("{any}\n", .{plan});

        const d = plan.dir;
        if (firstD == null) {
            firstD = d;
        }
        // for (0..plan.len) |i| {
        //     if (i == 0) {
        //         try grid.put(pos, if (d == .up and lastD == .left) 'L' else if (d == .up and lastD == .right) 'J' else if (d == .down and lastD == .left) 'F' else if (d == .down and lastD == .right) '7' else if (d == .left and lastD == .up) '7' else if (d == .left and lastD == .down) 'J' else if (d == .right and lastD == .up) 'F' else if (d == .right and lastD == .down) 'L' else unreachable);
        //     }
        //     pos = pos.move(d);
        //     try grid.put(pos, if (d == .up or d == .down) '|' else '-');
        //     maxX = @max(pos.x, maxX);
        //     maxY = @max(pos.y, maxY);
        //     minX = @min(pos.x, minX);
        //     minY = @min(pos.y, minY);
        // }
        const lenI32: i32 = @intCast(plan.len);
        pos = Coord{ .x = pos.x + lenI32 * d.dx(), .y = pos.y + lenI32 * d.dy() };
        lastD = d;
        try coords.append(pos);
        countDirect += plan.len;
    }
    const d = firstD.?;
    try grid.put(pos, if (d == .up and lastD == .left) 'L' else if (d == .up and lastD == .right) 'J' else if (d == .down and lastD == .left) 'F' else if (d == .down and lastD == .right) '7' else if (d == .left and lastD == .up) '7' else if (d == .left and lastD == .down) 'J' else if (d == .right and lastD == .up) 'F' else if (d == .right and lastD == .down) 'L' else unreachable);
    std.debug.print("{d}-{d}, {d}-{d} {any}\n", .{ minX, maxX, minY, maxY, pos });
    std.debug.print("count: {d} =? {d}\n", .{ grid.count(), countDirect });

    var xs = std.AutoHashMap(i32, void).init(allocator);
    defer xs.deinit();
    var ys = std.AutoHashMap(i32, void).init(allocator);
    defer ys.deinit();
    for (coords.items) |c| {
        try xs.put(c.x, undefined);
        try ys.put(@max(c.y - 1, minY), undefined);
        try ys.put(c.y, undefined);
        try ys.put(@min(c.y + 1, maxY), undefined);
    }

    const tl = Coord{ .x = minX, .y = minY };
    _ = tl;
    const br = Coord{ .x = maxX, .y = maxY };
    _ = br;
    // gridMod.printGridFmt(u8, grid, tl, br, fmtChar);

    // try fill(&grid, Coord{ .x = 1, .y = 1 });
    const count = grid.count();
    std.debug.print("#ys of note: {d}\n", .{ys.count()});
    // const intArea = try area(grid, tl, br, ys);
    std.debug.print("count: {d}\n", .{count});

    // std.debug.print("part 1: {d} + {d} = {d}\n", .{ count, intArea, count + intArea });

    var slArea = shoelaceArea(coords.items);
    std.debug.print("shoelace area: {d}\n", .{slArea});

    // A = i + b/2 - 1
    // i = A - b/2 + 1

    var totalArea = slArea + (countDirect >> 1) + 1;
    std.debug.print("part 2: {d}\n", .{totalArea});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
