const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

fn matches(pat: []const u8, expected: []u8) bool {
    var ns = expected;
    var len: u8 = 0;
    for (pat) |p| {
        if (p == '#') {
            len += 1;
        } else if (p == '.') {
            if (len > 0) {
                if (ns.len == 0 or ns[0] != len) {
                    return false;
                }
                ns = ns[1..];
                len = 0;
            }
        }
    }
    if (len > 0) {
        if (ns.len == 0 or ns[0] != len) {
            return false;
        }
        ns = ns[1..];
    }
    return ns.len == 0;
}

fn numMatching(pat: []const u8, nums: []u8) u32 {
    var n = std.mem.count(u8, pat, "?");
    var count: u32 = 0;
    var buf: [100]u8 = undefined;

    std.debug.print("{s} {any}\n", .{ pat, nums });
    var num: u32 = @as(u32, 1) << @intCast(n);
    for (0..num) |x| {
        var y = x;
        @memcpy(buf[0..pat.len], pat);
        for (0..buf.len) |i| {
            if (buf[i] == '?') {
                if (y % 2 == 1) {
                    buf[i] = '#';
                } else {
                    buf[i] = '.';
                }
                y = y >> 1;
            }
        }
        assert(y == 0);
        std.debug.print(" {s}\n", .{buf[0..pat.len]});
        if (matches(buf[0..pat.len], nums)) {
            count += 1;
        }
    }
    return count;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const filename = args[0];

    var maxQ: usize = 0;
    var iter = try bufIter.iterLines(filename);
    var intBuf: [30]u8 = undefined;
    var count: u32 = 0;
    while (try iter.next()) |line| {
        var n = std.mem.count(u8, line, "?");
        maxQ = @max(maxQ, n);

        var parts = util.splitOne(line, " ").?;
        var nums = try util.extractIntsIntoBuf(u8, parts.rest, &intBuf);
        std.debug.print("{d} {d}\n", .{ n, nums.len });
        var pat = parts.head;
        count += numMatching(pat, nums);
    }

    std.debug.print("part 1: {d}\n", .{count});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expect = std.testing.expect;

test "match" {
    var counts = [_]u8{ 1, 1, 3 };
    try expect(matches("#.#.###", &counts));
}
