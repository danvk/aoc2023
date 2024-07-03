const std = @import("std");
const util = @import("../util.zig");
const bufIter = @import("../buf-iter.zig");

fn is_valid(line: []const u8, allocator: std.mem.Allocator) !bool {
    var values = std.StringHashMap(void).init(allocator);
    defer values.deinit();

    var it = std.mem.splitAny(u8, line, " \t");
    while (it.next()) |word| {
        const prev = values.get(word);
        if (prev) |_| {
            return false;
        }
        try values.put(word, undefined);
    }
    return true;
}

fn is_valid2(line: []const u8, parent_allocator: std.mem.Allocator) !bool {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    var values = std.StringHashMap(void).init(allocator);
    // defer values.deinit();

    var it = std.mem.splitAny(u8, line, " \t");
    while (it.next()) |word| {
        const my_word = try allocator.dupe(u8, word);
        std.mem.sort(u8, my_word, {}, comptime std.sort.asc(u8));
        if (values.contains(my_word)) {
            return false;
        }
        try values.put(my_word, undefined);
    }
    return true;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var line_it = try bufIter.iterLines(filename);
    defer line_it.deinit();

    var sum: u32 = 0;
    var sum2: u32 = 0;
    while (try line_it.next()) |line| {
        if (try is_valid(line, allocator)) {
            sum += 1;
        }
        if (try is_valid2(line, allocator)) {
            sum2 += 1;
        }
    }
    std.debug.print("Part 1: {d}\n", .{sum});
    std.debug.print("Part 2: {d}\n", .{sum2});
}

const expectEqual = std.testing.expectEqual;

test "is_valid" {
    try expectEqual(true, try is_valid("aa bb cc dd ee", std.testing.allocator));
    try expectEqual(false, try is_valid("aa bb cc dd aa", std.testing.allocator));
    try expectEqual(true, try is_valid("aa bb cc dd aaa", std.testing.allocator));
}

test "is_valid_part2" {
    try expectEqual(true, try is_valid2("abcde fghij", std.testing.allocator));
    try expectEqual(false, try is_valid2("abcde xyz ecdab", std.testing.allocator));
    try expectEqual(true, try is_valid2("a ab abc abd abf abj", std.testing.allocator));
    try expectEqual(true, try is_valid2("iiii oiii ooii oooi oooo", std.testing.allocator));
    try expectEqual(false, try is_valid2("oiii ioii iioi iiio", std.testing.allocator));
}
