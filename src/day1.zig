const std = @import("std");
const bufIter = @import("./buf-iter.zig");

const assert = std.debug.assert;

const NUMS = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var totalSum: u32 = 0;
    while (try iter.next()) |line| {
        var firstInt: ?u8 = null;
        var lastInt: ?u8 = null;
        for (line, 0..) |c, i| {
            var digit: ?u8 = null;
            if (c >= '0' and c <= '9') {
                digit = c - '0';
            } else {
                for (NUMS, 1..) |numStr, d| {
                    const lineSlice = line[i..@min(i + numStr.len, line.len)];
                    if (std.mem.eql(u8, numStr, lineSlice)) {
                        digit = @intCast(d);
                    }
                }
            }

            if (digit) |d| {
                _ = d;
                if (firstInt == null) {
                    firstInt = digit;
                }
                lastInt = digit;
            }
        }
        std.debug.print("{s} -> {d} / {d}\n", .{ line, firstInt.?, lastInt.? });
        totalSum += 10 * firstInt.? + lastInt.?;
    }

    std.debug.print("part 1: {d}\n", .{totalSum});
    // std.debug.print("part 2: {any}\n", .{part1(&components.items)});
}
