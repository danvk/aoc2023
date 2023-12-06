const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

fn distForWait(waitMs: u32, time: u32) u32 {
    return (time - waitMs) * waitMs;
}

fn numWinners(time: u32, distance: u32) u32 {
    var n: u32 = 0;
    for (0..time) |wait| {
        if (distForWait(@intCast(wait), time) > distance) {
            n += 1;
        }
    }
    return n;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var contents = try util.readInputFile(filename, allocator);
    defer allocator.free(contents);

    var lines = util.splitOne(contents, "\n").?;

    var numsBuf1: [20]u32 = undefined;
    var numsBuf2: [20]u32 = undefined;
    var times = try util.extractIntsIntoBuf(u32, lines.head, &numsBuf1);
    var distances = try util.extractIntsIntoBuf(u32, lines.rest, &numsBuf2);

    var prod: u32 = 1;
    for (times, distances) |time, distance| {
        const n = numWinners(time, distance);
        std.debug.print("{d} / {d} -> {d}\n", .{ time, distance, n });
        prod *= n;
    }

    std.debug.print("part 1: {d}\n", .{prod});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
