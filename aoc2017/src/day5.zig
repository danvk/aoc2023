const std = @import("std");

fn part1(in_nums: []const i32, allocator: std.mem.Allocator) !u32 {
    var nums = try allocator.dupe(i32, in_nums);
    defer allocator.free(nums);
    var i: i32 = 0;
    var num_steps: u32 = 0;
    while (i >= 0 and i < nums.len) {
        const idx = @as(usize, @intCast(i));
        var offset = nums[idx];
        nums[idx] += 1;
        i += offset;
        num_steps += 1;
    }
    return num_steps;
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
    _ = sum;
    var sum2: u32 = 0;
    var nums = std.ArrayList(i32).init(allocator);
    defer nums.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const num = try std.fmt.parseInt(i32, line, 10);
        try nums.append(num);
    }

    std.debug.print("Part 1: {d}\n", .{try part1(nums.items, allocator)});
    std.debug.print("Part 2: {d}\n", .{sum2});
}

test "part 1 sample" {
    var nums = [_]i32{ 0, 3, 0, 1, -3 };
    var actual: u32 = try part1(&nums, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 5), actual);
}
