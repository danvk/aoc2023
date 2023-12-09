const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

fn extrapolateNext(allocator: std.mem.Allocator, nums: []i32) !i32 {
    var allZero = true;
    var diffs = std.ArrayList(i32).init(allocator);
    defer diffs.deinit();

    for (nums[1..], 1..) |next, i| {
        var diff = next - nums[i - 1];
        allZero = allZero and (diff == 0);
        try diffs.append(diff);
    }

    if (allZero) {
        // all nums are the same; just return the first one.
        return nums[0];
    }
    // nums are not all the same; infer the next difference.
    var diff = try extrapolateNext(allocator, diffs.items);
    return nums[nums.len - 1] + diff;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var part1: i32 = 0;
    var nums = std.ArrayList(i32).init(allocator);
    defer nums.deinit();
    while (try iter.next()) |line| {
        nums.clearAndFree();
        try util.readInts(i32, line, &nums);
        var next = try extrapolateNext(allocator, nums.items);
        std.debug.print("{s} -> {d}\n", .{ line, next });
        part1 += next;
    }

    std.debug.print("part 1: {d}\n", .{part1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
