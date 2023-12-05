const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

const Range = struct {
    dest: u64,
    start: u64,
    length: u64,
};

fn mapThroughRanges(num: u64, ranges: []Range) u64 {
    for (ranges) |range| {
        if (num >= range.start and num < range.start + range.length) {
            return range.dest + (num - range.start);
        }
    }
    return num;
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
            .start = ints[1],
            .length = ints[2],
        });
    }
    return out;
}

// alternative with arena allocator:
pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
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

    var numSeeds: u64 = 0;
    _ = numSeeds;
    var i: usize = 0;
    var part2Seeds = std.ArrayList(u64).init(allocator);
    defer part2Seeds.deinit();
    while (i < seeds.len) : (i += 2) {
        var start = seeds[i];
        var num = seeds[i + 1];
        for (start..(start + num)) |s| {
            try part2Seeds.append(s);
        }
    }
    var seeds2 = part2Seeds.items;
    std.debug.print("part 2: {d} seeds\n", .{seeds2.len});

    while (try iter.next()) |line| {
        assert(std.mem.endsWith(u8, line, "map:"));
        var ranges = try readRanges(allocator, &iter);
        defer ranges.deinit();

        // map all the seeds through.
        var j: usize = 0;
        while (j < seeds.len) : (j += 1) {
            seeds[j] = mapThroughRanges(seeds[j], ranges.items);
        }

        j = 0;
        while (j < seeds2.len) : (j += 1) {
            seeds2[j] = mapThroughRanges(seeds2[j], ranges.items);
        }
        std.debug.print("seeds: {any}\n", .{seeds});
    }

    std.debug.print("part 1: {d}\n", .{std.mem.min(u64, seeds)});
    std.debug.print("part 2: {d}\n", .{std.mem.min(u64, seeds2)});
}

const expectEqualDeep = std.testing.expectEqualDeep;

test "sample test" {
    try expectEqualDeep(true, true);
}
