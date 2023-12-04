const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

fn pointsForMatches(matches: u32) u32 {
    if (matches == 0) {
        return 0;
    }
    return @as(u32, 1) << @intCast(matches - 1);
}

fn pointsForLine(line: []const u8) !u32 {
    var cardSplit = util.splitOne(line, ": ").?;
    var parts = util.splitOne(cardSplit.rest, " | ").?;

    var intBuf: [50]u8 = undefined;
    var winners = try util.extractIntsIntoBuf(u8, parts.head, &intBuf);
    var intBuf2: [50]u8 = undefined;
    var nums = try util.extractIntsIntoBuf(u8, parts.rest, &intBuf2);

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
        std.debug.print("{d} matches -> {d} points, running {d} times\n", .{ matches, points, numTimes });
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
