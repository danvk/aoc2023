const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

const Game = struct {
    r: u32,
    g: u32,
    b: u32,
};

// 8 green, 6 blue, 20 red
fn parseGame(txt: []const u8) !Game {
    var g = Game{ .r = 0, .g = 0, .b = 0 };
    var buf: [3][]const u8 = undefined;
    var parts = util.splitIntoBuf(txt, ", ", &buf);
    var intBuf: [1]u32 = undefined;
    for (parts) |part| {
        var nums = try util.extractIntsIntoBuf(u32, part, &intBuf);
        assert(nums.len == 1);
        const num = nums[0];
        if (std.mem.endsWith(u8, part, "green")) {
            g.g = num;
        } else if (std.mem.endsWith(u8, part, "blue")) {
            g.b = num;
        } else if (std.mem.endsWith(u8, part, "red")) {
            g.r = num;
        } else {
            unreachable;
        }
    }
    return g;
}

// 12 red cubes, 13 green cubes, and 14 blue
const MAX_GAME = Game{ .r = 12, .g = 13, .b = 14 };

fn isLineValid(line: []const u8) !?u32 {
    var buf: [10][]const u8 = undefined;
    var parts = util.splitIntoBuf(line, ": ", &buf);
    assert(parts.len == 2);

    var intBuf: [1]u32 = undefined;
    var ids = try util.extractIntsIntoBuf(u32, parts[0], &intBuf);
    assert(ids.len == 1);
    const id = ids[0];

    var games = util.splitIntoBuf(parts[1], "; ", &buf);
    for (games) |gameStr| {
        std.debug.print("parsing {s}\n", .{gameStr});
        const game = try parseGame(gameStr);
        if (game.r <= MAX_GAME.r and game.g <= MAX_GAME.g and game.b <= MAX_GAME.b) {
            // ok
        } else {
            return null;
        }
    }
    return id;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var sum1: u32 = 0;
    while (try iter.next()) |line| {
        if (try isLineValid(line)) |id| {
            sum1 += id;
        }
    }

    std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "parse game" {
    var g = try parseGame("8 green, 6 blue, 20 red");
    try expectEqualDeep(Game{ .g = 8, .b = 6, .r = 20 }, g);
}
