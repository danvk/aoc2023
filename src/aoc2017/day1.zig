const std = @import("std");

fn part1(line: []u8) u32 {
    var sum: u32 = 0;
    for (line, 0..) |a, i| {
        const b = if (i == line.len - 1) line[0] else line[i + 1];
        if (a == b) {
            // std.debug.print("{d} sum += {d}\n", .{ i, a });
            sum += (a - '0');
        }
    }
    return sum;
}

fn part2(line: []u8) u32 {
    var sum: u32 = 0;
    for (line, 0..) |a, i| {
        const j = (i + (line.len >> 1)) % line.len;
        const b = line[j];
        if (a == b) {
            // std.debug.print("{d} sum += {d}\n", .{ i, a });
            sum += (a - '0');
        }
    }
    return sum;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    _ = allocator;
    const filename = args[0];
    std.debug.print("Filename: {s}\n", .{filename});

    // https://stackoverflow.com/a/68879352/388951
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const reader = file.reader();
    var buf_reader = std.io.bufferedReader(reader);
    var in_stream = buf_reader.reader();
    var buf: [4096]u8 = undefined;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        std.debug.print("Part 1: {d}\n", .{part1(line)});
        std.debug.print("Part 2: {d}\n", .{part2(line)});
    }
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
