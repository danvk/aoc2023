const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const Interval = @import("./interval.zig").Interval;

const assert = std.debug.assert;

const Iv64 = Interval(u64);

const Range = struct {
    dest: u64,
    source: Iv64,
};

fn mapThroughRanges(num: u64, ranges: []Range) u64 {
    for (ranges) |range| {
        if (range.source.includes(num)) {
            return range.dest + (num - range.source.low);
        }
    }
    return num;
}

fn mapRangeThroughRange(r: Iv64, range: Range) struct { mapped: ?Iv64, pre: ?Iv64, post: ?Iv64 } {
    const src = range.source;
    const split = r.split(src);

    return .{
        .pre = split.pre,
        .post = split.post,
        .mapped = if (split.int) |int| Iv64{
            .low = range.dest + (int.low - src.low),
            .high = range.dest + (int.high - src.low),
        } else null,
    };
}

fn mapRangeThroughRanges(r: Iv64, ranges: []Range, out: *std.ArrayList(Iv64)) !void {
    if (ranges.len == 0) {
        try out.append(r);
        return;
    }

    var range = ranges[0];
    var split = mapRangeThroughRange(r, range);
    if (split.mapped) |mapped| {
        try out.append(mapped);
    }
    if (split.pre) |pre| {
        try mapRangeThroughRanges(pre, ranges[1..], out);
    }
    if (split.post) |post| {
        try mapRangeThroughRanges(post, ranges[1..], out);
    }
}

fn readRanges(alloc: std.mem.Allocator, iter: *bufIter.ReadByLineIterator) !std.ArrayList(Range) {
    var out = std.ArrayList(Range).init(alloc);
    var intBuf: [3]u64 = undefined;
    while (try iter.next()) |line| {
        if (line.len == 0) {
            break;
        }
        var ints = try util.extractIntsIntoBuf(u64, line, &intBuf);
        assert(ints.len == 3);
        try out.append(Range{
            .dest = ints[0],
            .source = Iv64{ .low = ints[1], .high = ints[1] + ints[2] },
        });
    }
    return out;
}

// alternative with arena allocator:
pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    // XXX probably don't need arena allocator here
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var seedsBuf: [100]u64 = undefined;
    var line1 = (try iter.next()).?;
    var seeds = try util.extractIntsIntoBuf(u64, line1, &seedsBuf);
    std.debug.print("seeds: {any}\n", .{seeds});
    assert(seeds.len > 2);
    _ = try iter.next();

    var part2Seeds = std.ArrayList(Iv64).init(allocator);
    // defer part2Seeds.deinit();
    var i: usize = 0;
    while (i < seeds.len) : (i += 2) {
        var start = seeds[i];
        var num = seeds[i + 1];
        try part2Seeds.append(Iv64{ .low = start, .high = start + num });
    }
    var seeds2 = part2Seeds.items;

    while (try iter.next()) |line| {
        assert(std.mem.endsWith(u8, line, "map:"));
        var ranges = try readRanges(allocator, &iter);
        defer ranges.deinit();

        // map all the seeds through.
        var j: usize = 0;
        while (j < seeds.len) : (j += 1) {
            seeds[j] = mapThroughRanges(seeds[j], ranges.items);
        }

        var newRanges = std.ArrayList(Iv64).init(allocator);
        _ = newRanges;
        for (seeds2) |seedRange| {
            _ = seedRange;
        }
        // j = 0;
        // while (j < seeds2.len) : (j += 1) {
        //     seeds2[j] = mapThroughRanges(seeds2[j], ranges.items);
        // }
        std.debug.print("seeds: {any}\n", .{seeds});
    }

    std.debug.print("part 1: {d}\n", .{std.mem.min(u64, seeds)});
    // std.debug.print("part 2: {d}\n", .{std.mem.min(u64, seeds2)});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
