const std = @import("std");
const util = @import("./util.zig");

const assert = std.debug.assert;

const State = struct {
    pos: usize,
    skip: u32,
};

pub fn reverse(nums: []u8, pos: usize, len: usize) void {
    var a = pos;
    var b = pos + len - 1;
    while (a < b) {
        const ai = a % nums.len;
        const bi = b % nums.len;
        var t = nums[ai];
        nums[ai] = nums[bi];
        nums[bi] = t;
        a += 1;
        b -= 1;
    }
}

pub fn hashOnce(nums: []u8, len: usize, state: State) State {
    // Reverse the order of that length of elements in the list,
    // starting with the element at the current position.
    reverse(nums, state.pos, len);
    // Move the current position forward by that length plus the skip size.
    const new_pos = (state.pos + len + state.skip) % nums.len;
    // Increase the skip size by one.
    const new_skip = state.skip + 1;
    return State{
        .pos = new_pos,
        .skip = new_skip,
    };
}

pub fn hash(nums: []u8, lengths: []const u8) void {
    var state = State{ .pos = 0, .skip = 0 };
    for (lengths, 0..) |len, i| {
        state = hashOnce(nums, len, state);
        std.debug.print("{d}: {any}\n", .{ i, nums });
    }
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];
    const contents = try util.readInputFile(filename, allocator);
    defer allocator.free(contents);
    var lengths = std.ArrayList(u8).init(allocator);
    defer lengths.deinit();
    try util.readInts(u8, contents, &lengths);
    var els: [256]u8 = undefined;
    for (0..255) |i| {
        els[i] = @as(u8, @intCast(i));
    }
    std.debug.print("els: {any}\n", .{els});
    std.debug.print("lens: {any}\n", .{lengths});
    hash(&els, lengths.items);
    const el0 = @as(u32, els[0]);
    const el1 = @as(u32, els[1]);
    std.debug.print("part1: {d} x {d} = {d}\n", .{ el0, el1, el0 * el1 });
}

const expectEqual = std.testing.expectEqual;

test "samples part1" {
    var els = [_]u8{ 0, 1, 2, 3, 4 };
    const lens = [_]u8{ 3, 4, 1, 5 };
    hash(&els, &lens);
    std.debug.print("els: {any}\n", .{els});
    try expectEqual(@as(u32, 12), els[0] * els[1]);
}
