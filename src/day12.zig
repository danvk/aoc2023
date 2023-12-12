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
        // std.debug.print(" {s}\n", .{buf[0..pat.len]});
        if (matches(buf[0..pat.len], nums)) {
            // std.debug.print("  match!\n", .{});
            count += 1;
        }
    }
    return count;
}

fn numMatchRec(pat: []const u8, nums: []u8) u64 {
    // Assumptions:
    // - pat is potentially at the start of a pattern.
    //
    // If nums.len == 0 then:
    // - scan pat for any #. If there are any, then return 0.
    // - if it's all `?` and `.` then return 1.
    // If pat[0] is '.' then shift it off and continue recursively.
    // If pat[0] is '#' then we have to match nums[0] here.
    // - if there are too few characters left then return 0.
    // - if there are exactly nums[0] characters left, return 1 or 0.
    // - if there are more:
    //   - the first nums[0] must be `#` or `?`
    //   - the next after that must be `.` or `?`
    //   - if not, return 0. Otherwise shift and continue.
    // If pat[0] is '?' then either pretend it's '.' or '#' and add the results.

    // Other possible filters:
    // - If at any point sum(nums) + len(nums) - 1 > len(pat), return 0.
    // - If at any point there are too few `?` and `#` left, return 0.

    // Since I'm adding by at most 1s, I worry this is going to be too slow.

    if (pat.len == 0) {
        return if (nums.len > 0) 0 else 1;
    }
    if (nums.len == 0) {
        for (pat) |p| {
            if (p == '#') {
                return 0;
            }
        }
        return 1;
    }

    // Check if no matches are possible.
    var sum: u8 = 0;
    for (nums) |num| {
        sum += num;
    }
    if (sum + nums.len - 1 > pat.len) {
        return 0;
    }
    var numPound: u8 = 0;
    var numDot: u8 = 0;
    for (pat) |p| {
        if (p == '.' or p == '?') {
            numDot += 1;
        }
        if (p == '#' or p == '?') {
            numPound += 1;
        }
    }
    if (numPound < sum or numDot < nums.len - 1) {
        return 0;
    }

    const c = pat[0];
    var count: u64 = 0;

    if (c == '.' or c == '?') {
        count += numMatchRec(pat[1..], nums);
    }
    if (c == '#' or c == '?') {
        // match nums[0] #s here.
        const n = nums[0];
        var ok = true;
        _ = ok;
        if (pat.len < n) {
            return count;
        }
        for (pat[0..n]) |p| {
            if (p == '.') {
                return count;
            }
        }
        if (pat.len == n) {
            count += numMatchRec(pat[n..], nums[1..]);
        } else {
            if (pat[n] == '.' or pat[n] == '?') {
                count += numMatchRec(pat[(n + 1)..], nums[1..]);
            }
        }
    }
    return count;
}

fn unfold(inBuf: []const u8, outBuf: []u8) []u8 {
    var i: usize = 0;
    for (0..5) |n| {
        if (n > 0) {
            outBuf[i] = '?';
            i += 1;
        }
        for (inBuf) |c| {
            outBuf[i] = c;
            i += 1;
        }
    }
    return outBuf[0..i];
}

fn numMatchSplit(pat: []const u8, nums: []u8) u64 {
    if (nums.len <= 2) {
        return numMatchRec(pat, nums);
    }
    return 0;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const filename = args[0];

    var maxQ: usize = 0;
    var iter = try bufIter.iterLines(filename);
    var intBuf: [30]u8 = undefined;
    var sum: u64 = 0;
    var sum2: u64 = 0;
    var numLines: usize = 0;

    var timer = try std.time.Timer.start();

    while (try iter.next()) |line| {
        var n = std.mem.count(u8, line, "?");
        maxQ = @max(maxQ, n);

        var parts = util.splitOne(line, " ").?;
        var nums = try util.extractIntsIntoBuf(u8, parts.rest, &intBuf);
        var pat = parts.head;
        std.debug.print("{d} {s} {d} {d}\n", .{ numLines, pat, n, nums.len });
        // const count = numMatching(pat, nums);
        // sum += count;
        // std.debug.print(" -> {d}\n", .{count});
        var count = numMatchRec(pat, nums);
        std.debug.print(" -> {d}\n", .{count});
        // assert(count == count2);
        sum += count;

        var numNums = nums.len;
        for (0..4) |_| {
            for (nums) |num| {
                intBuf[numNums] = num;
                numNums += 1;
            }
        }
        nums = intBuf[0..numNums];

        var unfoldBuf: [1000]u8 = undefined;
        var unfolded = unfold(pat, &unfoldBuf);
        std.debug.print(" -> {s} {any}\n", .{ unfolded, nums });
        var count2 = numMatchRec(unfolded, nums);
        sum2 += count2;
        numLines += 1;
        const elapsed = timer.read() / 1_000_000_000;
        std.debug.print(" -> {d} {d}s\n", .{ count2, elapsed });
    }

    std.debug.print("part 1: {d}\n", .{sum});
    std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expect = std.testing.expect;

test "match" {
    var counts = [_]u8{ 1, 1, 3 };
    try expect(matches("#.#.###", &counts));
}
