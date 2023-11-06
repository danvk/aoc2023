const std = @import("std");
const util = @import("./util.zig");

const U32SliceContext = struct {
    pub fn hash(self: @This(), s: []const u32) u64 {
        _ = self;
        return hash_u32_slice(s);
    }
    pub fn eql(self: @This(), a: []const u32, b: []const u32) bool {
        _ = self;
        return std.mem.eql(u32, a, b);
    }
};

fn hash_u32_slice(s: []const u32) u64 {
    var hasher = std.hash.Wyhash.init(0);
    std.hash.autoHashStrat(&hasher, s, .Deep);
    return hasher.final();
}

fn part1_2(in_nums: []const u32, parent_allocator: std.mem.Allocator) ![2]u32 {
    var nums = try parent_allocator.dupe(u32, in_nums);
    defer parent_allocator.free(nums);
    var num_rounds: u32 = 0;

    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var states = std.HashMap([]const u32, u32, U32SliceContext, std.hash_map.default_max_load_percentage).init(allocator);

    std.debug.print("0: {any}\n", .{nums});
    // XXX initial state doesn't get hashed

    while (true) {
        // indexOfMax doesn't say it'll return the first occurence of the max, but it does.
        const bank_num = std.mem.indexOfMax(u32, nums);
        const bank_count = nums[bank_num];
        nums[bank_num] = 0;
        for (0..bank_count) |i| {
            nums[(bank_num + 1 + i) % nums.len] += 1;
        }
        num_rounds += 1;
        std.debug.print("{d}: {any}\n", .{ num_rounds, nums });
        const copy = try allocator.dupe(u32, nums);
        if (states.get(copy)) |prev_round| {
            return .{ num_rounds, num_rounds - prev_round };
        }
        try states.put(copy, num_rounds);
    }
    return .{ 0, 0 };
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var line_it = try util.iterLines(filename, allocator);
    defer line_it.deinit();

    while (line_it.next()) |line| {
        var nums = std.ArrayList(u32).init(allocator);
        defer nums.deinit();
        try util.readInts(line, &nums);

        std.debug.print("Part 1: {any}\n", .{try part1_2(nums.items, allocator)});
    }
}

test "hash map of []u32" {
    var array1 = [_]u32{ 1, 2, 3, 4, 5, 6 };
    var array2 = [_]u32{ 1, 2, 3, 4, 5, 6 };

    try std.testing.expectEqual(hash_u32_slice(&array1), hash_u32_slice(&array2));
    array1[0] = 2;
    try std.testing.expect(hash_u32_slice(&array1) != hash_u32_slice(&array2));
}

test "part 1 example" {
    const init = [_]u32{ 0, 2, 7, 0 };
    try std.testing.expectEqual(@as([2]u32, .{ 5, 4 }), try part1_2(&init, std.testing.allocator));
}
