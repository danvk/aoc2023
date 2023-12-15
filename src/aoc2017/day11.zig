const std = @import("std");
const util = @import("../util.zig");

const assert = std.debug.assert;

const Dir = enum { nw, n, ne, se, s, sw };
const DIRS = [_]Dir{ .nw, .n, .ne, .se, .s, .sw };

const Cell = struct {
    x: i32,
    y: i32,

    fn dyForX(self: Cell) i32 {
        return switch (@mod(self.x, 2)) {
            0 => -1,
            1 => 0,
            else => unreachable,
        };
    }

    // pub fn neighbors(self: Cell, out: *std.ArrayList(Cell)) !void {
    //     const x = self.x;
    //     const y = self.y;
    //     const dx = self.dxForY();
    //     out.clearAndFree();
    //     out.append(Cell{ .x = x, .y = y - 1 });
    //     out.append(Cell{ .x = x + dx, .y = y - 1 });
    //     out.append(Cell{ .x = x + dx + 1, .y = y - 1 });
    //     out.append(Cell{ .x = x + dx, .y = y + 1 });
    //     out.append(Cell{ .x = x + dx + 1, .y = y + 1 });
    //     out.append(Cell{ .x = x, .y = y + 1 });
    // }

    pub fn move(self: Cell, dir: Dir) Cell {
        const x = self.x;
        const y = self.y;
        const dy = self.dyForX();
        return switch (dir) {
            .n => Cell{ .x = x, .y = y - 1 },
            .nw => Cell{ .x = x - 1, .y = y + dy },
            .ne => Cell{ .x = x + 1, .y = y + dy },
            .sw => Cell{ .x = x - 1, .y = y + dy + 1 },
            .se => Cell{ .x = x + 1, .y = y + dy + 1 },
            .s => Cell{ .x = x, .y = y + 1 },
        };
    }

    pub fn distFromOrigin(self: Cell) u32 {
        const dy = std.math.absCast(self.y);
        const dx = std.math.absCast(self.x);
        if (self.x == 0) {
            // std.debug.print(".x=0 -> {d}\n", .{dy});
            return dy;
        } else if (self.y == 0) {
            // std.debug.print(".y=0 -> {d}\n", .{dx});
            return dx;
        } else if (self.x < 0) {
            const flipCell = Cell{ .x = @as(i32, @intCast(dx)), .y = self.y };
            // std.debug.pring("flipping {any} -> {any}\n", .{ self, flipCell });
            return flipCell.distFromOrigin();
        } else if (self.y < 0) {
            return 1 + self.move(.sw).distFromOrigin();
        } else {
            return 1 + self.move(.nw).distFromOrigin();
        }
        // assume: x > 0

        // return @max(dx, dy);
        // if (dx == 0 or dy == 0) {
        //     return dx + dy;
        // }
        // const myD = dx + dy + @as(u32, @intCast(self.dyForX() + 1));
        // var minD = myD + 1;
        // var minDir = Dir.n;
        // for (DIRS) |dir| {
        //     var cell = self.move(dir);
        //     var ndApprox = std.math.absCast(cell.x) + std.math.absCast(cell.y) + @as(u32, @intCast(1 + self.dyForX()));
        //     if (ndApprox < myD) {
        //         std.debug.print("{any} ({d}) {any} -> {any} ({d})\n", .{ self, dx + dy, dir, cell, ndApprox });
        //         const nd = 1 + cell.distFromOrigin();
        //         if (nd <= minD) {
        //             minD = nd;
        //             minDir = dir;
        //         }
        //     }
        // }
        // return minD;
    }
};

pub fn part1(str: []const u8) !u32 {
    var cell = Cell{ .x = 0, .y = 0 };
    var it = std.mem.splitAny(u8, str, ",");
    std.debug.print("  -> {any}\n", .{cell});
    while (it.next()) |move| {
        const d = std.meta.stringToEnum(Dir, move) orelse unreachable;
        cell = cell.move(d);
        std.debug.print("{any} -> {any}\n", .{ d, cell });
    }
    return cell.distFromOrigin();
}

pub fn part2(str: []const u8) !u32 {
    var maxD: u32 = 0;
    var cell = Cell{ .x = 0, .y = 0 };
    var it = std.mem.splitAny(u8, str, ",");
    std.debug.print("  -> {any}\n", .{cell});
    while (it.next()) |move| {
        const dir = std.meta.stringToEnum(Dir, move) orelse unreachable;
        cell = cell.move(dir);
        const dist = cell.distFromOrigin();
        maxD = @max(maxD, dist);
    }
    return maxD;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];
    const contents = try util.readInputFile(allocator, filename);
    defer allocator.free(contents);
    std.debug.print("part1: {d}\n", .{try part1(contents)});
    std.debug.print("part2: {d}\n", .{try part2(contents)});
}

const expectEqual = std.testing.expectEqual;

test "mod" {}

test "samples part1" {
    // ne,ne,ne is 3 steps away.
    try expectEqual(@as(u32, 3), try part1("ne,ne,ne"));
    // ne,ne,sw,sw is 0 steps away (back where you started).
    try expectEqual(@as(u32, 0), try part1("ne,ne,sw,sw"));
    // ne,ne,s,s is 2 steps away (se,se).
    try expectEqual(@as(u32, 2), try part1("ne,ne,s,s"));
    // se,sw,se,sw,sw is 3 steps away (s,s,sw).
    try expectEqual(@as(u32, 3), try part1("se,sw,se,sw,sw"));
}
