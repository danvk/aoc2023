const std = @import("std");
const util = @import("./util.zig");
const hashString = @import("./day10.zig").hashString;
const Dir = @import("./day3.zig").Dir;
const DIRS = @import("./day3.zig").DIRS;

const assert = std.debug.assert;

const A_FACTOR = 16807;
const B_FACTOR = 48271;
const MOD = 2147483647;
const MASK = 0xffff;

pub fn part1(a0: u32, b0: u32, n: usize) u32 {
    var a: u64 = a0;
    var b: u64 = b0;
    var numMatches: u32 = 0;
    for (0..n) |i| {
        a = (a * A_FACTOR) % MOD;
        b = (b * B_FACTOR) % MOD;
        if (i < 4) {
            std.debug.print("{d} A: {d:>10}  B: {d:>10}\n", .{ i, a, b });
        }
        if (a & MASK == b & MASK) {
            numMatches += 1;
            // std.debug.print("{d} match!\n", .{i});
        }
    }
    return numMatches;
}

fn getNext(seed: u64, factor: u32, mult: u32) u64 {
    var x = seed;
    while (true) {
        x = (x * factor) % MOD;
        if (x % mult == 0) {
            return x;
        }
    }
}

pub fn part2(a0: u32, b0: u32, n: usize) u32 {
    var a: u64 = a0;
    var b: u64 = b0;
    var numMatches: u32 = 0;
    for (0..n) |i| {
        a = getNext(a, A_FACTOR, 4);
        b = getNext(b, B_FACTOR, 8);

        if (i < 4) {
            std.debug.print("{d} A: {d:>10}  B: {d:>10}\n", .{ i, a, b });
        }
        if (a & MASK == b & MASK) {
            numMatches += 1;
            // std.debug.print("{d} match!\n", .{i});
        }
    }
    return numMatches;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const a0_str = args[0];
    const b0_str = args[1];

    const a0 = try std.fmt.parseInt(u32, a0_str, 10);
    const b0 = try std.fmt.parseInt(u32, b0_str, 10);

    std.debug.print("part 1: {d}\n", .{part1(a0, b0, 40_000_000)});
    std.debug.print("part 2: {d}\n", .{part2(a0, b0, 5_000_000)});
}

const expectEqual = std.testing.expectEqual;
