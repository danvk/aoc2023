const std = @import("std");

pub fn main() !void {
    // https://stackoverflow.com/a/68879352/388951
    var file = try std.fs.cwd().openFile("input.txt", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var sum: u32 = 0;
        for (line, 0..) |a, i| {
            var b = if (i == line.len - 1) line[0] else line[i + 1];
            if (a == b) {
                std.debug.print("{d} sum += {d}\n", .{ i, a });
                sum += (a - '0');
            }
        }
        std.debug.print("Part 1: {d}\n", .{sum});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
