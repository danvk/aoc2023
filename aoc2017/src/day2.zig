const std = @import("std");

fn readInts(line: []u8, nums: *std.ArrayList(u32)) !void {
    var it = std.mem.splitAny(u8, line, " \t");
    while (it.next()) |split| {
        if (split.len == 0) {
            continue;
        }
        const num = try std.fmt.parseInt(u32, split, 10);
        try nums.append(num);
    }
}

fn extent(nums: []u32) [2]u32 {
    var min: ?u32 = null;
    var max: ?u32 = null;

    for (nums) |num| {
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

fn part2(nums: []u32) u32 {
    for (nums, 0..) |a, i| {
        for (nums, 0..) |b, j| {
            if (j == i) {
                continue;
            }
            if (a % b == 0) {
                std.debug.print("Found it! {d} / {d}\n", .{ a, b });
                return a / b;
            }
        }
    }
    return 0;
}

pub fn main(args: []const [:0]u8) !void {
    // See https://zigbyexample.github.io/command_line_arguments
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

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
    var sum2: u32 = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var nums = std.ArrayList(u32).init(allocator);
        defer nums.deinit();
        try readInts(line, &nums);

        const min_max = extent(nums.items);
        const min = min_max[0];
        const max = min_max[1];
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
