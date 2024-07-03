const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

fn pointsForMatches(matches: u32) u32 {
    if (matches == 0) {
        return 0;
    }
    return @as(u32, 1) << @intCast(matches - 1);
}

// "Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53"
fn pointsForLine(line: []const u8) !u32 {
    var buf: [3][]const u8 = undefined;
    const parts = util.splitAnyIntoBuf(line, ":|", &buf);
    assert(parts.len == 3);

    var intBuf: [50]u8 = undefined;
    var intBuf2: [50]u8 = undefined;
    const winners = try util.extractIntsIntoBuf(u8, parts[1], &intBuf);
    const nums = try util.extractIntsIntoBuf(u8, parts[2], &intBuf2);

    var matches: u32 = 0;
    for (nums) |num| {
        if (std.mem.indexOfScalar(u8, winners, num) != null) {
            matches += 1;
        }
    }
    return matches;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const filename = args[0];

    // const copies = std.AutoHashMap(u32, u32).init(allocator);
    // defer copies.deinit();

    var copiesBuf: [300]u32 = undefined;
    @memset(copiesBuf[0..], 1);
    var copies: []u32 = copiesBuf[0..];

    var iter = try bufIter.iterLines(filename);
    var part1: u32 = 0;
    var part2: u32 = 0;
    while (try iter.next()) |line| {
        const matches = try pointsForLine(line);
        const points = pointsForMatches(matches);
        part1 += points;
        const numTimes = copies[0];
        // std.debug.print("{d} matches -> {d} points, running {d} times\n", .{ matches, points, numTimes });
        copies = copies[1..];
        part2 += numTimes;

        var i: u32 = 0;
        while (i < matches) : (i += 1) {
            copies[i] += numTimes;
        }
    }

    std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
