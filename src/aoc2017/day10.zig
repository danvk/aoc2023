const std = @import("std");
const util = @import("../util.zig");

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
    _ = hashWithState(nums, lengths, state);
}

pub fn hashWithState(nums: []u8, lengths: []const u8, init_state: State) State {
    var state = State{
        .pos = init_state.pos,
        .skip = init_state.skip,
    };
    for (lengths, 0..) |len, i| {
        _ = i;
        state = hashOnce(nums, len, state);
        // std.debug.print("{d}: {any}\n", .{ i, nums });
    }
    return state;
}

pub fn hashString(allocator: std.mem.Allocator, str: []const u8) !u128 {
    const n = str.len;
    var lens = try std.fmt.allocPrint(allocator, "{s}.....", .{str});
    defer allocator.free(lens);
    lens[n] = 17;
    lens[n + 1] = 31;
    lens[n + 2] = 73;
    lens[n + 3] = 47;
    lens[n + 4] = 23;
    var els: [256]u8 = undefined;
    for (0..256) |i| {
        els[i] = @as(u8, @intCast(i));
    }
    var state = State{ .pos = 0, .skip = 0 };
    for (0..64) |_| {
        state = hashWithState(&els, lens, state);
    }
    // els is now the "sparse hash"
    return densifyHash(&els);
}

fn densifyHash(els: []const u8) u128 {
    var i: usize = 0;
    var out: u128 = 0;
    while (i < els.len) : (i += 16) {
        var n = els[i];
        for (1..16) |d| {
            n = n ^ els[i + d];
            // std.debug.print("{d}: {d}\n", .{ d, els[i + d] });
        }
        out <<= 8;
        out += n;
        // std.debug.print("dense: {d}\n", .{n});
        // std.debug.print("{x:0>2}\n", .{n});
        // std.debug.print("{x:0>32}\n", .{out});
    }
    // std.debug.print("\n", .{});
    // std.debug.print("{x:0>32}\n", .{out});
    return out;
}

fn printDenseHash(els: []const u8) void {
    const dense = densifyHash(els);
    std.debug.print("{x:0>32}\n", .{dense});
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

    assert(contents[contents.len - 1] != '\n');
    std.debug.print("contents: '{s}'\n", .{contents});
    std.debug.print("{x:0>32}\n", .{try hashString(allocator, contents)});
}

const expectEqual = std.testing.expectEqual;

test "samples part1" {
    var els = [_]u8{ 0, 1, 2, 3, 4 };
    const lens = [_]u8{ 3, 4, 1, 5 };
    hash(&els, &lens);
    std.debug.print("els: {any}\n", .{els});
    try expectEqual(@as(u32, 12), els[0] * els[1]);
}

test "print dense hash" {
    printDenseHash(&[_]u8{ 65, 27, 9, 1, 4, 3, 40, 50, 91, 7, 6, 0, 2, 5, 68, 22 });
    try expectEqual(@as(u128, 64), densifyHash(&[_]u8{ 65, 27, 9, 1, 4, 3, 40, 50, 91, 7, 6, 0, 2, 5, 68, 22 }));
}

test "samples part 2" {
    _ = try hashString(std.testing.allocator, "");
    try expectEqual(@as(u128, 0xa2582a3a0e66e6e86e3812dcb672a272), try hashString(std.testing.allocator, ""));
    try expectEqual(@as(u128, 0x33efeb34ea91902bb2f59c9920caa6cd), try hashString(std.testing.allocator, "AoC 2017"));
    try expectEqual(@as(u128, 0x3efbe78a8d82f29979031a4aa0b16a9d), try hashString(std.testing.allocator, "1,2,3"));
    try expectEqual(@as(u128, 0x63960835bcdc130f0b66d7ff4f6a5a8e), try hashString(std.testing.allocator, "1,2,4"));
}
