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
}

const expectEqualDeep = std.testing.expectEqualDeep;
