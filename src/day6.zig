const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

fn distForWait(waitMs: u64, time: u64) u64 {
    return (time - waitMs) * waitMs;
}

fn numWinners(time: u64, distance: u64) u64 {
    var n: u64 = 0;
    for (0..time) |wait| {
        if (distForWait(@intCast(wait), time) > distance) {
            n += 1;
        }
    }
    return n;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var contents = try util.readInputFile(allocator, filename);
    defer allocator.free(contents);

    var lines = util.splitOne(contents, "\n").?;

    var numsBuf1: [20]u64 = undefined;
    var numsBuf2: [20]u64 = undefined;
    var times = try util.extractIntsIntoBuf(u64, lines.head, &numsBuf1);
    var distances = try util.extractIntsIntoBuf(u64, lines.rest, &numsBuf2);

    var prod: u64 = 1;
    for (times, distances) |time, distance| {
        const n = numWinners(time, distance);
        std.debug.print("{d} / {d} -> {d}\n", .{ time, distance, n });
        prod *= n;
    }
    std.debug.print("part 1: {d}\n", .{prod});

    var buf: [100]u8 = undefined;
    assert(std.mem.replace(u8, lines.head, " ", "", &buf) > 0);
    const times2a = try util.extractIntsIntoBuf(u64, &buf, &numsBuf1);
    assert(times2a.len == 1);
    const times2 = times2a[0];

    assert(std.mem.replace(u8, lines.rest, " ", "", &buf) > 0);
    const dist2a = try util.extractIntsIntoBuf(u64, &buf, &numsBuf1);
    assert(dist2a.len == 1);
    const dist2 = dist2a[0];
    std.debug.print("{d} / {d}\n", .{ times2, dist2 });

    std.debug.print("part 2: {d}\n", .{numWinners(times2, dist2)});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
