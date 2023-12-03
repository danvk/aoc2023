const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const dir = @import("./dir.zig");
const util = @import("./util.zig");

const Coord = dir.Coord;

const assert = std.debug.assert;

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}

fn findPartNums(grid: std.AutoHashMap(Coord, u8), extent: Coord) u32 {
    var total: u32 = 0;
    var inNum = false;
    var isPart = false;
    var curNum: u32 = 0;
    var y: i32 = -1;

    while (y < extent.y + 1) : (y += 1) {
        var x: i32 = 0;
        while (x < extent.x + 2) : (x += 1) {
            const pos = Coord{ .x = x, .y = y };
            const c = grid.get(pos) orelse '.';

            if (isDigit(c)) {
                if (!inNum) {
                    inNum = true;
                    curNum = 0;
                }
                curNum *= 10;
                curNum += (c - '0');

                var hasSymNeighbor = false;
                for (dir.DIR8S) |d| {
                    if (grid.get(pos.move8(d))) |nv| {
                        if (!isDigit(nv)) {
                            hasSymNeighbor = true;
                            std.debug.print("{any} {c} is sym\n", .{ pos.move8(d), nv });
                        }
                    }
                }
                isPart = isPart or hasSymNeighbor;
            } else {
                if (inNum) {
                    inNum = false;
                    if (isPart) {
                        std.debug.print("Adding part num: {d}\n", .{curNum});
                        total += curNum;
                    }
                    isPart = false;
                }
            }
        }
        assert(inNum == false);
    }
    return total;
}

fn findNumStart(grid: std.AutoHashMap(Coord, u8), pos: Coord) Coord {
    var x = pos.x;
    const y = pos.y;
    while (true) {
        const c = grid.get(Coord{ .x = x, .y = y }) orelse '.';
        if (!isDigit(c)) {
            return Coord{ .x = x + 1, .y = y };
        }
        x -= 1;
    }
    unreachable;
}

fn extractNum(grid: std.AutoHashMap(Coord, u8), pos: Coord) u32 {
    var num: u32 = 0;
    var x = pos.x;
    const y = pos.y;
    while (true) {
        const c = grid.get(Coord{ .x = x, .y = y }) orelse '.';
        if (!isDigit(c)) {
            return num;
        } else {
            num *= 10;
            num += (c - '0');
        }
        x += 1;
    }
    unreachable;
}

fn addGearRatios(allocator: std.mem.Allocator, grid: std.AutoHashMap(Coord, u8)) !u32 {
    var it = grid.iterator();
    var sum: u32 = 0;
    while (it.next()) |entry| {
        if (entry.value_ptr.* != '*') {
            continue;
        }
        const pos = entry.key_ptr.*;
        std.debug.print("{any} {c}\n", .{ pos, entry.value_ptr });

        var numStarts = std.AutoHashMap(Coord, void).init(allocator);
        defer numStarts.deinit();
        var gearRatio: u32 = 1;
        var numNeighbors: usize = 0;
        for (dir.DIR8S) |d| {
            const n = pos.move8(d);
            if (grid.get(n)) |nv| {
                if (isDigit(nv)) {
                    const numStart = findNumStart(grid, n);
                    if (!numStarts.contains(numStart)) {
                        const num = extractNum(grid, numStart);
                        try numStarts.put(numStart, undefined);
                        gearRatio *= num;
                        numNeighbors += 1;
                    }
                }
            }
        }
        if (numNeighbors == 2) {
            sum += gearRatio;
        }
    }
    return sum;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var grid = std.AutoHashMap(Coord, u8).init(allocator);
    defer grid.deinit();

    var iter = try bufIter.iterLines(filename);
    var y: i32 = 0;
    var maxY: i32 = 0;
    var maxX: i32 = 0;
    while (try iter.next()) |line| {
        for (line, 0..) |c, x| {
            if (c != '.') {
                try grid.putNoClobber(Coord{ .x = @intCast(x), .y = y }, c);
            }
            maxX = @intCast(x);
        }
        maxY = y;
        y += 1;
    }

    const extent = Coord{ .x = maxX, .y = maxY };
    std.debug.print("part 1: {d}\n", .{findPartNums(grid, extent)});
    std.debug.print("part 2: {d}\n", .{try addGearRatios(allocator, grid)});
}

const expectEqualDeep = std.testing.expectEqualDeep;
