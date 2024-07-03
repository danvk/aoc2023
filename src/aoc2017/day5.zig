const std = @import("std");
const util = @import("../util.zig");
const bufIter = @import("../buf-iter.zig");

fn part1(in_nums: []const i32, allocator: std.mem.Allocator) !u32 {
    var nums = try allocator.dupe(i32, in_nums);
    defer allocator.free(nums);
    var i: i32 = 0;
    var num_steps: u32 = 0;
    while (i >= 0 and i < nums.len) {
        const idx = @as(usize, @intCast(i));
        const offset = nums[idx];
        nums[idx] += 1;
        i += offset;
        num_steps += 1;
    }
    return num_steps;
}

fn part2(in_nums: []const i32, allocator: std.mem.Allocator) !u32 {
    var nums = try allocator.dupe(i32, in_nums);
    defer allocator.free(nums);
    var i: i32 = 0;
    var num_steps: u32 = 0;
    while (i >= 0 and i < nums.len) {
        const idx = @as(usize, @intCast(i));
        const offset = nums[idx];
        var new_val = offset;
        if (new_val >= 3) {
            new_val -= 1;
        } else {
            new_val += 1;
        }
        nums[idx] = new_val;
        i += offset;
        num_steps += 1;
    }
    return num_steps;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var line_it = try bufIter.iterLines(filename);
    defer line_it.deinit();

    var nums = std.ArrayList(i32).init(allocator);
    defer nums.deinit();

    while (try line_it.next()) |line| {
        const num = try std.fmt.parseInt(i32, line, 10);
        try nums.append(num);
    }

    std.debug.print("Part 1: {d}\n", .{try part1(nums.items, allocator)});
    std.debug.print("Part 2: {d}\n", .{try part2(nums.items, allocator)});
}

test "part 1 sample" {
    var nums = [_]i32{ 0, 3, 0, 1, -3 };
    const actual: u32 = try part1(&nums, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 5), actual);
}

test "part 2 sample" {
    var nums = [_]i32{ 0, 3, 0, 1, -3 };
    const actual: u32 = try part2(&nums, std.testing.allocator);
    try std.testing.expectEqual(@as(u32, 10), actual);
}
