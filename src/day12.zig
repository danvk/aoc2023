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
    const n = std.mem.count(u8, pat, "?");
    var count: u32 = 0;
    var buf: [100]u8 = undefined;

    std.debug.print("{s} {any}\n", .{ pat, nums });
    const num: u32 = @as(u32, 1) << @intCast(n);
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

var memo: std.StringHashMap(u64) = undefined;

fn lookupMemo(pat: []const u8, nums: []u8) ?u64 {
    var buf: [1000]u8 = undefined;
    @memcpy(buf[0..], pat);
    @memcpy(buf[pat.len], nums);
    const key = buf[0..(pat.len + nums.len)];
    return memo.get(key);
}

fn setMemo(pat: []const u8, nums: []u8, count: u64) !void {
    var buf: [1000]u8 = undefined;
    @memcpy(buf[0..], pat);
    @memcpy(buf[pat.len], nums);
    const key = buf[0..(pat.len + nums.len)];
    try memo.put(key, count); // <-- this won't work since buf is freed.
}

fn clearMemo() void {
    memo.clearAndFree();
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
        const ok = true;
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

fn minLenForNums(nums: []u8) u8 {
    var sum: u8 = 0;
    for (nums) |num| {
        sum += num;
    }
    return @intCast(sum + nums.len - 1);
}

fn numMatchSplit(pat: []const u8, nums: []u8) u64 {
    if (nums.len < 2) {
        return numMatchRec(pat, nums);
    }

    const splitI = nums.len / 2;
    const nums1 = nums[0..splitI];
    const nums2 = nums[splitI..];
    assert(nums1.len > 0);
    assert(nums2.len > 0);
    // std.debug.print("split {any} -> {any} / {any}\n", .{ nums, nums1, nums2 });

    const minLen1 = minLenForNums(nums1);
    const minLen2 = minLenForNums(nums2);
    if (minLen1 + minLen2 + 1 > pat.len) {
        return 0;
    }

    // 012345678
    // #.#.#.#.#
    // minLen1 = 2
    // minLen2 = 2
    // pat.len = 8
    // 2..6
    var count: u64 = 0;
    var rightBuf: [1000]u8 = undefined;
    for (minLen1..(pat.len - minLen2 + 1)) |i| {
        const c = pat[i];
        if (c == '#') {
            // must be a '.' or '?' in between the splits.
            continue;
        }

        var splitCount: u64 = 0;
        const pat1 = pat[0..i];
        const pat2raw = pat[(i + 1)..];
        if (pat1.len == 0 or pat2raw.len == 0) {
            continue; // TODO: eliminate by updating for loop bounds
        }
        // std.debug.print("{s} -> '{s}' / '{s}'\n", .{ pat, pat1, pat2raw });
        if (pat2raw[0] == '.') {
            continue; // invalid, we'll count this a different way.
        }
        const count1 = numMatchSplit(pat1, nums1);
        // std.debug.print("{d}:{s} / {any} -> {d}\n", .{ i, pat1, nums1, count1 });
        if (count1 > 0) {
            @memcpy(rightBuf[0..pat2raw.len], pat2raw);
            var pat2 = rightBuf[0..pat2raw.len];
            pat2[0] = '#';
            const count2 = numMatchSplit(pat2, nums2);
            splitCount = count1 * count2;
            // if (splitCount > 0) {
            //     std.debug.print("{d}:{s} / {any} -> {d}\n", .{ i, pat2, nums2, count2 });
            // }
        }
        count += splitCount;
    }

    // var checkCount = numMatchRec(pat, nums);
    // if (count != checkCount) {
    //     std.debug.print("mismatch: {s} {any} {d} != {d}\n", .{ pat, nums, count, checkCount });
    //     assert(false);
    // }

    return count;
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
        const n = std.mem.count(u8, line, "?");
        maxQ = @max(maxQ, n);

        const parts = util.splitOne(line, " ").?;
        var nums = try util.extractIntsIntoBuf(u8, parts.rest, &intBuf);
        const pat = parts.head;
        std.debug.print("{d} {s} {d} {d}\n", .{ numLines, pat, n, nums.len });
        // const count = numMatching(pat, nums);
        // sum += count;
        // std.debug.print(" -> {d}\n", .{count});
        const count = numMatchRec(pat, nums);
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
        const unfolded = unfold(pat, &unfoldBuf);
        std.debug.print(" -> {s} {any}\n", .{ unfolded, nums });
        const count2 = numMatchRec(unfolded, nums);
        // var count3 = numMatchSplit(unfolded, nums);
        sum2 += count2;
        numLines += 1;
        const elapsed = timer.read() / 1_000_000_000;
        std.debug.print(" -> {d} {d}s\n", .{ count2, elapsed });
        // assert(count2 == count3);
    }

    std.debug.print("part 1: {d}\n", .{sum});
    std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "match" {
    var counts = [_]u8{ 1, 1, 3 };
    try expect(matches("#.#.###", &counts));
}

test "split" {
    var pat = "###???";
    var nums = [_]u8{ 3, 1 };
    // The two are:
    // ###.#.
    // ###..#

    try expectEqual(numMatchSplit(pat[0..], &nums), 2);
}
