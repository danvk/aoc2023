const std = @import("std");
const bufIter = @import("./buf-iter.zig");

const assert = std.debug.assert;

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var totalSum: u32 = 0;
    while (try iter.next()) |line| {
        var firstInt: ?u8 = null;
        var lastInt: ?u8 = null;
        for (line) |c| {
            if (c < '0' or c > '9') {
                continue;
            }
            var digit = c - '0';
            if (firstInt == null) {
                firstInt = digit;
            }
            lastInt = digit;
        }
        std.debug.print("{s} -> {d} / {d}\n", .{ line, firstInt.?, lastInt.? });
        totalSum += 10 * firstInt.? + lastInt.?;
    }

    std.debug.print("part 1: {d}\n", .{totalSum});
    // std.debug.print("part 2: {any}\n", .{part1(&components.items)});
}
