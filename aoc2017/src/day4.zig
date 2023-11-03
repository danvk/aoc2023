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
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        if (try is_valid(line, allocator)) {
            sum += 1;
        }
    }
    std.debug.print("Part 1: {d}\n", .{sum});
    // std.debug.print("Part 2: {d}\n", .{sum2});
}

test "is_valid" {
    try std.testing.expectEqual(true, try is_valid("aa bb cc dd ee", std.testing.allocator));
    try std.testing.expectEqual(false, try is_valid("aa bb cc dd aa", std.testing.allocator));
    try std.testing.expectEqual(true, try is_valid("aa bb cc dd aaa", std.testing.allocator));
}
