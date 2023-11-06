const std = @import("std");
const util = @import("./util.zig");

fn part2(nums: []u32) u32 {
    for (nums, 0..) |a, i| {
        for (nums, 0..) |b, j| {
            if (j == i) {
                continue;
            }
            if (a % b == 0) {
                // std.debug.print("Found it! {d} / {d}\n", .{ a, b });
                return a / b;
            }
        }
    }
    return 0;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];
    std.debug.print("Filename: {s}\n", .{filename});

    // var file = try std.fs.cwd().openFile(filename, .{});
    // defer file.close();
    // var buf_reader = std.io.bufferedReader(file.reader());

    // var line_it = util.readByLine(allocator, &buf_reader);
    var line_it = try util.iterLines2(filename, allocator);
    defer line_it.deinit();

    var sum: u32 = 0;
    var sum2: u32 = 0;
    while (try line_it.next()) |line| {
        var nums = std.ArrayList(u32).init(allocator);
        defer nums.deinit();
        try util.readInts(line, &nums);

        const min_max = std.mem.minMax(u32, nums.items);
        const min = min_max.min;
        const max = min_max.max;
        const diff = max - min;
        // std.debug.print("{d} - {d} = {d}\n", .{ min, max, diff });
        sum += diff;

        sum2 += part2(nums.items);
    }
    std.debug.print("Part 1: {d}\n", .{sum});
    std.debug.print("Part 2: {d}\n", .{sum2});
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
