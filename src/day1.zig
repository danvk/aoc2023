const std = @import("std");
const bufIter = @import("./buf-iter.zig");

const assert = std.debug.assert;

fn calibration1(line: []const u8) u8 {
    var firstInt: ?u8 = null;
    var lastInt: ?u8 = null;
    for (line) |c| {
        if (c < '0' or c > '9') {
            continue;
        }
        const digit = c - '0';
        if (firstInt == null) {
            firstInt = digit;
        }
        lastInt = digit;
    }
    return 10 * firstInt.? + lastInt.?;
}

const NUMS = [_][]const u8{ "one", "two", "three", "four", "five", "six", "seven", "eight", "nine" };

fn calibration2(line: []const u8) u8 {
    var firstInt: ?u8 = null;
    var lastInt: ?u8 = null;
    for (line, 0..) |c, i| {
        var digit: ?u8 = null;
        if (c >= '0' and c <= '9') {
            digit = c - '0';
        } else {
            for (NUMS, 1..) |numStr, d| {
                if (std.mem.startsWith(u8, line[i..], numStr)) {
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
    return 10 * firstInt.? + lastInt.?;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var sum1: u32 = 0;
    var sum2: u32 = 0;
    while (try iter.next()) |line| {
        sum1 += calibration1(line);
        sum2 += calibration2(line);
    }

    std.debug.print("part 1: {d}\n", .{sum1});
    std.debug.print("part 2: {d}\n", .{sum2});
}
