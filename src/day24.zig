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

fn intersectionXY(a: Hailstone, b: Hailstone) ?CoordTimes {
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
        const flip = intersectionXY(b, a);
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

fn whereAt(h: Hailstone, t: f64) Coord3 {
    return Coord3{
        .x = h.p.x + t * h.v.x,
        .y = h.p.y + t * h.v.y,
        .z = h.p.z + t * h.v.z,
    };
}

// if a hailstone hit a at t=0 and b at t=1, what would it be?
fn impliedHailstone(a: Hailstone, b: Hailstone) Hailstone {
    const p1 = whereAt(a, 0);
    const p2 = whereAt(b, 1);

    const vx = p2.x - p1.x;
    const vy = p2.y - p1.y;
    _ = vy;
    const vz = p2.z - p1.z;

    return Hailstone{
        .p = p1,
        .v = Coord3{ .x = vx, .y = vx, .z = vz },
    };
}

const Plane = struct {
    a: f128,
    b: f128,
    c: f128,
};

fn timeForStone(p: Plane, s: Hailstone) f64 {
    const a = p.a;
    const b = p.b;
    const c = p.c;
    const px: f128 = s.p.x;
    const py: f128 = s.p.y;
    const pz: f128 = s.p.z;
    const vx: f128 = s.v.x;
    const vy: f128 = s.v.y;
    const vz: f128 = s.v.z;

    const num = pz - a * px - b * py - c;
    const den = a * vx + b * vy - vz;
    const result = num / den;
    return @floatCast(result);
}

fn findOrigin(t1: f64, pt1: Coord3, t2: f64, pt2: Coord3) Hailstone {
    const dt = t2 - t1;
    const dx = (pt2.x - pt1.x) / dt;
    const dy = (pt2.y - pt1.y) / dt;
    const dz = (pt2.z - pt1.z) / dt;

    const x0 = pt1.x - dx * t1;
    const y0 = pt1.y - dy * t1;
    const z0 = pt1.z - dz * t1;

    return Hailstone{
        .p = Coord3{ .x = x0, .y = y0, .z = z0 },
        .v = Coord3{ .x = dx, .y = dy, .z = dz },
    };
}

fn isInt(v: f64) bool {
    return areClose(v, std.math.round(v));
}

fn areClose(a: f64, b: f64) bool {
    return @fabs(a - b) < 0.01;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var stones = std.ArrayList(Hailstone).init(allocator);
    defer stones.deinit();
    var iter = try bufIter.iterLines(filename);
    while (try iter.next()) |line| {
        var stone = try parseHailstone(line);
        // std.debug.print("{any}\n", .{stone});
        try stones.append(stone);
    }

    var part1: usize = 0;
    var parallel: struct { usize, usize } = undefined;
    for (stones.items, 0..) |a, i| {
        for (stones.items[(i + 1)..], (i + 1)..) |b, j| {
            // std.debug.print("A: {any}\n", .{a});
            // std.debug.print("B: {any}\n", .{b});
            const int = intersectionXY(a, b);
            // std.debug.print("-> {?any}\n", .{int});
            if (int) |hit| {
                if (isValid(hit)) {
                    part1 += 1;
                }
            } else {
                std.debug.print("parallel hailstones:\n", .{});
                std.debug.print("A {d}: {any}\n", .{ i, a });
                std.debug.print("B {d}: {any}\n", .{ j, b });
                parallel = .{ i, j };

                std.debug.print("{d} = {d} = {d}?\n", .{ a.v.x / b.v.x, a.v.y / b.v.y, a.v.z / b.v.z });
            }
        }
    }
    std.debug.print("part 1: {d}\n", .{part1});

    const s0 = stones.items[1];
    const s1 = stones.items[2];
    const s2 = stones.items[3];
    const p1 = s0.p;
    const p2 = s1.p;
    const v1 = s0.v;
    const v2 = s1.v;

    for (0..2001) |avx| {
        const vx: f64 = @as(f64, @floatFromInt(avx)) - 1000;
        for (0..2001) |avy| {
            const vy: f64 = @as(f64, @floatFromInt(avy)) - 1000;
            const num = (p2.y - p1.y) * (vx - v1.x) - (p2.x - p1.x) * (vy - v1.y);
            const den = (vy - v2.y) * (vx - v1.x) - (vx - v2.x) * (vy - v1.y);
            const t2 = num / den;
            const t1 = ((vy - v2.y) * t2 - (p2.y - p1.y)) / (vy - v1.y);

            const px = p1.x + (v1.x - vx) * t1;
            const py = p1.y + (v1.y - vy) * t1;

            const z1 = p1.z + t1 * v1.z;
            const z2 = p2.z + t2 * v2.z;
            const vz = (z2 - z1) / (t2 - t1);
            const pz = p1.z + (v1.z - vz) * t1;

            if (isInt(t1) and isInt(t2) and isInt(vz)) {
                const s = Hailstone{ .p = Coord3{ .x = px, .y = py, .z = pz }, .v = Coord3{ .x = vx, .y = vy, .z = vz } };
                if (intersectionXY(s, s2)) |hit2| {
                    if (areClose(hit2.t1, hit2.t2)) {
                        const t3 = hit2.t1;
                        const z3 = s2.p.z + t3 * s2.v.z;
                        const sz3 = s.p.z + t3 * s.v.z;
                        if (areClose(z3, sz3)) {
                            // std.debug.print("vx={d}, vy={d}: t1={d}/t2={d}: {any} {any}, p=({d},{d},{d})\n", .{ vx, vy, t1, t2, whereAt(s0, t1), whereAt(s1, t2), px, py, pz });
                            std.debug.print("part 2: {d}\n", .{px + py + pz});
                        }
                    }
                }
            }
        }
    }

    // std.debug.print("part 2: {d}\n", .{sum2});
}

// 697869420003814.2
// 642678186425533.1

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "intersect" {
    const a = try parseHailstone("19, 13, 30 @ -2, 1, -2");
    const b = try parseHailstone("18, 19, 22 @ -1, -1, -2");

    const int = intersectionXY(a, b);
    _ = int;
    // try expectEqual(int, Coord3{ .x = 14.333, .y = 15.333, .z = 0 });
}
