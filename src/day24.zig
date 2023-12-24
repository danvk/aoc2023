const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

const Coord3 = struct {
    x: f64,
    y: f64,
    z: f64,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.fs.File.Writer) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{d},{d},{d}", .{ self.x, self.y, self.z });
    }
};

const Hailstone = struct {
    p: Coord3,
    v: Coord3,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.fs.File.Writer) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{any} @ {any}", .{ self.p, self.v });
    }
};

fn parseHailstone(line: []const u8) !Hailstone {
    var intBuf: [6]i64 = undefined;
    var xs = try util.extractIntsIntoBuf(i64, line, &intBuf);
    assert(intBuf.len == 6);

    return Hailstone{
        .p = Coord3{
            .x = @floatFromInt(xs[0]),
            .y = @floatFromInt(xs[1]),
            .z = @floatFromInt(xs[2]),
        },
        .v = Coord3{
            .x = @floatFromInt(xs[3]),
            .y = @floatFromInt(xs[4]),
            .z = @floatFromInt(xs[5]),
        },
    };
}

// x1 = px1 + vx1 * t1
// y1 = py1 + vy1 * t1
// x2 = px2 + vx2 * t2
// y2 = py2 + vy2 * t2

// px1 + vx1 * t1 = px2 + vx2 * t2
// py1 + vy1 * t1 = py2 + vy2 * t2

// (px1 - px2) = vx2 * t2 - vx1 * t1
// (py1 - py2) = vy2 * t2 - vy1 * t1

// ((px1 - px2) + vx1 * t1)/vx2 = t2

// vy2(px1 - px2) = vy2(vx2 * t2 - vx1 * t1)
// vx2(py1 - py2) = vx2(vy2 * t2 - vy1 * t1)

// vy2(px1 - px2) - vx2(py1 - py2) = (vx2*vy1-vy2*vx1)*t1
// t1 = (vy2(px1 - px2) - vx2(py1 - py2)) / (vx2*vy1-vy2*vx1)

const CoordTimes = struct {
    x: f64,
    y: f64,
    z: f64,
    t1: f64,
    t2: f64,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.fs.File.Writer) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{d},{d},{d} @ {d}/{d}", .{ self.x, self.y, self.z, self.t1, self.t2 });
    }
};

fn intersection(a: Hailstone, b: Hailstone) ?CoordTimes {
    const px1: f64 = a.p.x;
    const vx1: f64 = a.v.x;
    const py1: f64 = a.p.y;
    const vy1: f64 = a.v.y;
    const px2: f64 = b.p.x;
    const vx2: f64 = b.v.x;
    const py2: f64 = b.p.y;
    const vy2: f64 = b.v.y;

    const den: f64 = vx2 * vy1 - vy2 * vx1;
    if (den == 0) {
        return null;
    }
    const num: f64 = vy2 * (px1 - px2) - vx2 * (py1 - py2);
    const t1: f64 = num / den;
    const t2 = ((px1 - px2) + vx1 * t1) / vx2;

    if (vx2 == 0) {
        assert(vx1 != 0);
        const flip = intersection(b, a);
        if (flip) |h| {
            return CoordTimes{ .x = h.x, .y = h.y, .z = h.z, .t1 = h.t2, .t2 = h.t1 };
        }
        return null;
    }

    const x = a.p.x + a.v.x * t1;
    const y = a.p.y + a.v.y * t1;
    const z = a.p.z + a.v.z * t1;
    return CoordTimes{ .x = x, .y = y, .z = z, .t1 = t1, .t2 = t2 };
}

// const min = 7;
// const max = 27;
const min = 200000000000000;
const max = 400000000000000;
fn isValid(hit: CoordTimes) bool {
    return (hit.x >= min and hit.y >= min and hit.x <= max and hit.y <= max and hit.t1 > 0 and hit.t2 > 0);
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var stones = std.ArrayList(Hailstone).init(allocator);
    defer stones.deinit();
    var iter = try bufIter.iterLines(filename);
    while (try iter.next()) |line| {
        var stone = try parseHailstone(line);
        std.debug.print("{any}\n", .{stone});
        try stones.append(stone);
    }

    var part1: usize = 0;
    for (stones.items, 0..) |a, i| {
        for (stones.items[(i + 1)..]) |b| {
            // std.debug.print("A: {any}\n", .{a});
            // std.debug.print("B: {any}\n", .{b});
            const int = intersection(a, b);
            // std.debug.print("-> {?any}\n", .{int});
            if (int) |hit| {
                if (isValid(hit)) {
                    part1 += 1;
                }
            }
        }
    }

    std.debug.print("part 1: {d}\n", .{part1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "intersect" {
    const a = try parseHailstone("19, 13, 30 @ -2, 1, -2");
    const b = try parseHailstone("18, 19, 22 @ -1, -1, -2");

    const int = intersection(a, b);
    _ = int;
    // try expectEqual(int, Coord3{ .x = 14.333, .y = 15.333, .z = 0 });
}
