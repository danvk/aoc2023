const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

fn pointsForLine(line: []const u8) !u32 {
    var cardSplit = util.splitOne(line, ": ").?;
    var parts = util.splitOne(cardSplit.rest, " | ").?;

    var intBuf: [50]u8 = undefined;
    var winners = try util.extractIntsIntoBuf(u8, parts.head, &intBuf);
    var intBuf2: [50]u8 = undefined;
    var nums = try util.extractIntsIntoBuf(u8, parts.rest, &intBuf2);

    var score: u32 = 0;
    for (nums) |num| {
        if (std.mem.indexOfScalar(u8, winners, num) != null) {
            score = if (score == 0) 1 else 2 * score;
        }
    }
    return score;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var part1: u32 = 0;
    while (try iter.next()) |line| {
        part1 += try pointsForLine(line);
    }

    std.debug.print("part 1: {d}\n", .{part1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
