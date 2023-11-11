const std = @import("std");
const util = @import("./util.zig");

const assert = std.debug.assert;

// 0    X   X   X   X
// 1  X   X   X   X   X
// 2    X   X   X   X

// (0, 0) -> (0, 1), (1, 1)
// (0, 1) -> (0, 0), (-1, 0)
// (0, 2) -> (0, 1), (1, 1)

// 0  X   X   X
// 1    X   X   X
// 2  X   o   X
// 3    X   o   X
// 4  X   X   X
// 5    X   X   X

// (1, 2) -> (1, 0), (0, 1), (1, 1), (0, 3), (1, 3), (1, 4)
// (1, 3) -> (1, 1), (1, 2), (2, 2), (1, 4), (2, 4), (1, 5)
// y even: x never increases
// y odd: x never decreases

const Dir = enum { nw, n, ne, se, s, sw };

const Cell = struct {
    x: i32,
    y: i32,

    fn dxForY(self: Cell) i32 {
        return switch (@mod(self.y, 2)) {
            0 => -1,
            1 => 0,
            else => unreachable,
        };
    }

    pub fn neighbors(self: Cell, out: *std.ArrayList(Cell)) !void {
        const x = self.x;
        const y = self.y;
        const dx = self.dxForY();
        out.clearAndFree();
        // TODO: rewrite using self.move()
        out.append(Cell{ .x = x, .y = y - 2 });
        out.append(Cell{ .x = x + dx, .y = y - 1 });
        out.append(Cell{ .x = x + dx + 1, .y = y - 1 });
        out.append(Cell{ .x = x + dx, .y = y + 1 });
        out.append(Cell{ .x = x + dx + 1, .y = y + 1 });
        out.append(Cell{ .x = x, .y = y + 2 });
    }

    pub fn move(self: Cell, dir: Dir) Cell {
        const x = self.x;
        const y = self.y;
        const dx = self.dxForY();
        return switch (dir) {
            .n => Cell{ .x = x, .y = y - 2 },
            .nw => Cell{ .x = x + dx, .y = y - 1 },
            .ne => Cell{ .x = x + dx + 1, .y = y - 1 },
            .sw => Cell{ .x = x + dx, .y = y + 1 },
            .se => Cell{ .x = x + dx + 1, .y = y + 1 },
            .s => Cell{ .x = x, .y = y + 2 },
        };
    }

    pub fn distFromOrigin(self: Cell) u32 {
        const dx = 2 * std.math.absCast(self.x);
        const dy = std.math.absCast(self.y);
        if (dx >= dy) {
            return dx;
        }
        const yDist = std.math.divCeil(u32, dy - dx, 2) catch {
            return 0;
        };
        return dx + yDist;
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

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];
    const contents = try util.readInputFile(filename, allocator);
    defer allocator.free(contents);
    std.debug.print("part1: {d}\n", .{try part1(contents)});
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
