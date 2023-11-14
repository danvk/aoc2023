const std = @import("std");
const util = @import("./util.zig");

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
    for (parts.items) |part| {
        const move = try parseMove(part);
        std.debug.print("{s} => {any}\n", .{ part, move });
        doMove(&buf, move);
    }
    std.debug.print("part 1: {s}\n", .{buf});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, programs)});
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
