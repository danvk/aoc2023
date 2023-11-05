const std = @import("std");

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
        var my_word = try allocator.dupe(u8, word);
        std.mem.sort(u8, my_word, {}, comptime std.sort.asc(u8));
        if (values.contains(my_word)) {
            return false;
        }
        try values.put(my_word, undefined);
    }
    return true;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) !void {
    const filename = args[0];
    std.debug.print("Filename: {s}\n", .{filename});

    // https://stackoverflow.com/a/68879352/388951
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [4096]u8 = undefined;
    var sum: u32 = 0;
    var sum2: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
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
