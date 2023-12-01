const std = @import("std");
const util = @import("../util.zig");

const assert = std.debug.assert;

const Exchange = struct {
    posA: u32,
    posB: u32,
};
const Partner = struct {
    a: u8,
    b: u8,
};

const MoveType = enum { Spin, Exchange, Partner };
const Move = union(MoveType) { Spin: u32, Exchange: Exchange, Partner: Partner };

fn parseMove(move: []const u8) !Move {
    const t = move[0];
    const nums = move[1..];
    if (t == 's') {
        return Move{
            .Spin = try std.fmt.parseInt(u32, nums, 10),
        };
    }
    const slash = std.mem.indexOf(u8, nums, "/").?;
    const a = nums[0..slash];
    const b = nums[(1 + slash)..];
    return switch (t) {
        'x' => Move{
            .Exchange = .{ .posA = try std.fmt.parseInt(u32, a, 10), .posB = try std.fmt.parseInt(u32, b, 10) },
        },
        'p' => Move{
            .Partner = .{ .a = a[0], .b = b[0] },
        },
        else => unreachable,
    };
}

fn spin(buf: []u8, amount: u32) void {
    var tmp: [26]u8 = undefined;
    const n = buf.len;
    @memcpy(tmp[0..buf.len], buf);
    for (buf, 0..) |_, i| {
        if (i < amount) {
            buf[i] = tmp[i + n - amount];
            // std.debug.print("s buf[{d}] = tmp[{d}]\n", .{ i, i + n - amount });
        } else {
            buf[i] = tmp[i - amount];
            // std.debug.print("c buf[{d}] = tmp[{d}]\n", .{ i, i - amount });
        }
    }
}

fn exchange(buf: []u8, x: Exchange) void {
    const tmp = buf[x.posA];
    buf[x.posA] = buf[x.posB];
    buf[x.posB] = tmp;
}

fn partner(buf: []u8, p: Partner) void {
    const posA = std.mem.indexOfScalar(u8, buf, p.a).?;
    const posB = std.mem.indexOfScalar(u8, buf, p.b).?;
    exchange(buf, .{ .posA = @intCast(posA), .posB = @intCast(posB) });
}

fn doMove(buf: []u8, move: Move) void {
    switch (move) {
        .Exchange => |x| exchange(buf, x),
        .Partner => |p| partner(buf, p),
        .Spin => |s| spin(buf, s),
    }
}

fn hashBuffer(buf: []u8) u128 {
    var out: u128 = 0;
    for (buf) |c| {
        out <<= 8;
        out += c;
    }
    return out;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    const contents = try util.readInputFile(filename, allocator);
    defer allocator.free(contents);

    var parts = std.ArrayList([]const u8).init(allocator);
    defer parts.deinit();

    var buf: [16]u8 = undefined;
    for (buf, 0..) |_, i| {
        buf[i] = 'a' + @as(u8, @intCast(i));
    }
    assert(buf[15] == 'p');

    try util.splitIntoArrayList(contents, ",", &parts);
    var moves = std.ArrayList(Move).init(allocator);
    defer moves.deinit();
    for (parts.items) |part| {
        const move = try parseMove(part);
        try moves.append(move);
    }

    var seen = std.AutoHashMap(u128, usize).init(allocator);
    defer seen.deinit();

    var c: usize = 0;

    for (1..100) |i| {
        for (moves.items) |move| {
            // std.debug.print("{s} => {any}\n", .{ part, move });
            doMove(&buf, move);
        }
        const hash = hashBuffer(&buf);
        std.debug.print("{d:>3} hash: {d} {s}\n", .{ i, hash, buf });
        if (c == 0) {
            if (seen.get(hash)) |prev| {
                std.debug.print("found a cycle! {d} = {d}\n", .{ i, prev });
                c = i;

                // this means that the value after c cycles is the same as after prev cycles
            } else {
                try seen.putNoClobber(hash, i);
            }
        }

        if (i == 0) {
            std.debug.print("part 1: {s}\n", .{buf});
        }
    }

    const n = 1_000_000_000;
    const prev = 1 + ((n - 1) % 30);
    std.debug.print("{d} is same as {d}\n", .{ n, prev });

    std.debug.print("part 2: {s}\n", .{buf});
}

const expectEqual = std.testing.expectEqual;

test "sample moves" {
    var buf = [_]u8{ 'a', 'b', 'c', 'd', 'e' };
    spin(&buf, 1);
    try expectEqual([_]u8{ 'e', 'a', 'b', 'c', 'd' }, buf);

    exchange(&buf, .{ .posA = 3, .posB = 4 });
    try expectEqual([_]u8{ 'e', 'a', 'b', 'd', 'c' }, buf);

    partner(&buf, .{ .a = 'e', .b = 'b' });
    try expectEqual([_]u8{ 'b', 'a', 'e', 'd', 'c' }, buf);
}
