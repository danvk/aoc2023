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
    var parallel: struct { usize, usize } = undefined;
    for (stones.items, 0..) |a, i| {
        for (stones.items[(i + 1)..], (i + 1)..) |b, j| {
            // std.debug.print("A: {any}\n", .{a});
            // std.debug.print("B: {any}\n", .{b});
            const int = intersection(a, b);
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

    if (false) {
        parallel = .{ 28, 274 };
        std.debug.print("parallel: {any}\n", .{parallel});

        const pa = stones.items[parallel[0]];
        const pb = stones.items[parallel[1]];
        const p1 = whereAt(pa, 0);
        const p2 = whereAt(pa, 1000);
        const p3 = whereAt(pb, 0);
        std.debug.print("p1: {any}\n", .{p1});
        std.debug.print("p2: {any}\n", .{p2});
        std.debug.print("p3: {any}\n", .{p3});
        const points = [_]Coord3{ p1, p2, p3 };

        for (&points) |p| {
            std.debug.print("{d} = {d}a + {d}b + c\n", .{ p.z, p.x, p.y });
        }

        // const p = Plane{ .a = 0, .b = 2, .c = -16 };
        // const p = Plane{ .a = -154366485978260 / 34705859347523, .b = 119660626630737 / 34705859347523, .c = 19580930587073342134275113886 / 34705859347523 };
        const p = Plane{
            .a = -3775750953325940 / 234223023870859,
            .b = 2544191182650133 / 234223023870859,
            .c = 465380250490660088107002948066 / 234223023870859,
        };
        assert(parallel[0] != stones.items.len - 1);
        assert(parallel[0] != stones.items.len - 2);
        assert(parallel[1] != stones.items.len - 1);
        assert(parallel[1] != stones.items.len - 2);
        const s1 = stones.items[stones.items.len - 1];
        const s2 = stones.items[stones.items.len - 2];

        const t1 = timeForStone(p, s1);
        const pt1 = whereAt(s1, t1);
        const t2 = timeForStone(p, s2);
        const pt2 = whereAt(s2, t2);

        std.debug.print("two points:\n", .{});
        std.debug.print("{d} @ {any}\n", .{ t1, pt1 });
        std.debug.print("{d} @ {any}\n", .{ t2, pt2 });

        // std.debug.print("{d} = {d}a + {d}b + c\n", .{ pt1.z, pt1.x, pt1.y });
        // std.debug.print("{d} = {d}a + {d}b + c\n", .{ pt2.z, pt2.x, pt2.y });

        const ray = findOrigin(t1, pt1, t2, pt2);
        std.debug.print("stone: {any}\n", .{ray});
        std.debug.print("part2: {d}\n", .{ray.p.x + ray.p.y + ray.p.z});
    }

    for (stones.items, 0..) |a, i| {
        for (stones.items, 0..) |b, j| {
            if (i == j) {
                continue;
            }
            const h = findOrigin(1, whereAt(a, 1), 3, whereAt(b, 3));
            const h3 = whereAt(h, 4);
            std.debug.print("implied: {any}\n", .{h});
            for (stones.items, 0..) |c, k| {
                if (i == k or j == k) {
                    continue;
                }
                const c3 = whereAt(c, 4);
                if (@fabs(c3.x - h3.x) + @fabs(c3.y - h3.y) + @fabs(c3.z - h3.z) < 0.01) {
                    std.debug.print("candidate! {any}\n", .{h});
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

    const int = intersection(a, b);
    _ = int;
    // try expectEqual(int, Coord3{ .x = 14.333, .y = 15.333, .z = 0 });
}
