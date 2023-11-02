const std = @import("std");

fn extent(line: []u8) [2]u32 {
    var sum: u32 = 0;
    _ = sum;

    var it = std.mem.splitAny(u8, line, " \t");

    var min: ?u32 = null;
    var max: ?u32 = null;

    while (it.next()) |split| {
        std.debug.print("split: {s}\n", .{split});
        if (split.len == 0) {
            continue;
        }
        // XXX what's the right way to handle errors here?
        const num = std.fmt.parseInt(u32, split, 10) catch {
            return .{ 0, 0 };
        };
        std.debug.print("num: {d}, {any} / {any}\n", .{ num, min orelse num, max orelse num });
        if (min orelse num >= num) {
            min = num;
        }
        if (max orelse num <= num) {
            max = num;
        }
    }
    std.debug.print("{any} / {any}\n", .{ min, max });
    return .{ min orelse 0, max orelse 0 };
}

fn part2(line: []u8) u32 {
    _ = line;
    return 0;
}

pub fn main() !void {
    // See https://zigbyexample.github.io/command_line_arguments
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    // args[0] is the executable
    const filename = args[1];
    std.debug.print("Filename: {s}\n", .{filename});

    // https://stackoverflow.com/a/68879352/388951
    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();
    var buf: [4096]u8 = undefined;
    var sum: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const min_max = extent(line);
        const min = min_max[0];
        const max = min_max[1];
        const diff = max - min;
        std.debug.print("{d} - {d} = {d}\n", .{ min, max, diff });
        sum += diff;
    }
    std.debug.print("Part 1: {d}\n", .{sum});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
