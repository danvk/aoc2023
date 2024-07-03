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

    const range = ranges[0];
    const split = mapRangeThroughRange(r, range);
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
        const ints = try util.extractIntsIntoBuf(u64, line, &intBuf);
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
    const allocator = arena.allocator();

    const filename = args[0];

    var iter = try bufIter.iterLines(filename);
    var seedsBuf: [100]u64 = undefined;
    const line1 = (try iter.next()).?;
    var seeds = try util.extractIntsIntoBuf(u64, line1, &seedsBuf);
    std.debug.print("seeds: {any}\n", .{seeds});
    assert(seeds.len > 2);
    _ = try iter.next();

    var part2Seeds = std.ArrayList(Iv64).init(allocator);
    // defer part2Seeds.deinit();
    var i: usize = 0;
    while (i < seeds.len) : (i += 2) {
        const start = seeds[i];
        const num = seeds[i + 1];
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
        for (seeds2) |seedRange| {
            try mapRangeThroughRanges(seedRange, ranges.items, &newRanges);
        }
        seeds2 = newRanges.items;
        // j = 0;
        // while (j < seeds2.len) : (j += 1) {
        //     seeds2[j] = mapThroughRanges(seeds2[j], ranges.items);
        // }
        std.debug.print("seeds: {any}\n", .{seeds});
    }

    var min = seeds2[0].low;
    for (seeds2) |r| {
        min = @min(min, r.low);
    }

    std.debug.print("part 1: {d}\n", .{std.mem.min(u64, seeds)});
    std.debug.print("part 2: {d}\n", .{min});
}

const expectEqualSlices = std.testing.expectEqualSlices;
const expectEqualDeep = std.testing.expectEqualDeep;

test "mapRangeThroughRanges" {
    var out = std.ArrayList(Iv64).init(std.testing.allocator);
    defer out.deinit();

    // 50 98 2
    // 52 50 48
    var ranges = [_]Range{ //
        .{ .dest = 50, .source = Iv64{ .low = 98, .high = 100 } }, //
        .{ .dest = 52, .source = Iv64{ .low = 50, .high = 98 } }, //
    };

    try mapRangeThroughRanges( //
        Iv64{ .low = 79, .high = 79 + 14 }, //
        @as([]Range, &ranges), &out);
    var expected = [_]Iv64{.{ .low = 81, .high = 95 }};
    try expectEqualDeep(out.items, &expected);

    out.clearAndFree();
    try mapRangeThroughRanges( //
        Iv64{ .low = 95, .high = 101 }, //
        @as([]Range, &ranges), &out);
    // std.debug.print("out: {any}\n", .{out.items});
    var expected2 = [_]Iv64{
        .{ .low = 50, .high = 52 }, // 98-100
        .{ .low = 97, .high = 100 }, // 95-98
        .{ .low = 100, .high = 101 }, // 100-101
    };
    try expectEqualDeep(out.items, &expected2);
}
