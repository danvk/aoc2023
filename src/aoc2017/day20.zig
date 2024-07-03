const std = @import("std");
const util = @import("../util.zig");
const bufIter = @import("../buf-iter.zig");

const assert = std.debug.assert;

const Vec3 = struct {
    x: i64,
    y: i64,
    z: i64,
    fn l1norm(self: @This()) u64 {
        return std.math.absCast(self.x) + std.math.absCast(self.y) + std.math.absCast(self.z);
    }
    fn add(self: @This(), other: Vec3) Vec3 {
        return Vec3{
            .x = self.x + other.x,
            .y = self.y + other.y,
            .z = self.z + other.z,
        };
    }
    fn addTo(self: *@This(), other: Vec3) void {
        self.x += other.x;
        self.y += other.y;
        self.z += other.z;
    }
};
const Particle = struct {
    id: usize,
    p: Vec3,
    v: Vec3,
    a: Vec3,
    fn tick(self: *@This()) void {
        self.v.addTo(self.a);
        self.p.addTo(self.v);
    }
};

fn parseVec3(buf: []const u8) !Vec3 {
    var intBuf: [3]i64 = undefined;
    const ints = try util.extractIntsIntoBuf(i64, buf, &intBuf);
    assert(ints.len == 3);

    return Vec3{ .x = ints[0], .y = ints[1], .z = ints[2] };
}

fn parseLine(id: usize, line: []const u8) !Particle {
    var left = std.mem.indexOfScalar(u8, line, '<').?;
    var right = std.mem.indexOfScalar(u8, line, '>').?;
    const p = try parseVec3(line[left + 1 .. right]);

    var buf = line[right + 1 ..];
    // std.debug.print("remaining: {s}\n", .{buf});
    left = std.mem.indexOfScalar(u8, buf, '<').?;
    right = std.mem.indexOfScalar(u8, buf, '>').?;
    const v = try parseVec3(buf[left + 1 .. right]);

    buf = buf[right + 1 ..];
    // std.debug.print("remaining: {s}\n", .{buf});
    left = std.mem.indexOfScalar(u8, buf, '<').?;
    right = std.mem.indexOfScalar(u8, buf, '>').?;
    const a = try parseVec3(buf[left + 1 .. right]);

    return Particle{ .id = id, .p = p, .v = v, .a = a };
}

fn tick(allocator: std.mem.Allocator, particlesList: *std.ArrayList(Particle)) !void {
    var coords = std.AutoHashMap(Vec3, i32).init(allocator);
    defer coords.deinit();
    var toRemove = std.ArrayList(usize).init(allocator);
    defer toRemove.deinit();
    const particles = particlesList.items;
    for (particles) |*particle| {
        particle.tick();
    }

    for (particles, 0..) |*particle, i| {
        if (coords.get(particle.p)) |other_i| {
            if (other_i != -1) {
                try toRemove.append(@intCast(other_i));
                try coords.put(particle.p, -1);
            }
            try toRemove.append(i);
        } else {
            try coords.putNoClobber(particle.p, @intCast(i));
        }
    }

    // Remove items from the back.
    // This won't invalidate earlier indices and is O(len(toRemove)).
    std.mem.sort(usize, toRemove.items, {}, std.sort.desc(usize));
    for (toRemove.items) |i| {
        const p = particlesList.swapRemove(i);
        std.debug.print("Particle {d} is annihilated\n", .{p.id});
    }
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var lines_it = try bufIter.iterLines(filename);
    defer lines_it.deinit();

    var particles = std.ArrayList(Particle).init(allocator);
    defer particles.deinit();

    var n: usize = 0;
    while (try lines_it.next()) |line| {
        const particle = try parseLine(n, line);
        try particles.append(particle);

        // std.debug.print("{d}\t{d}\t{any}\n", .{ particle.a.l1norm(), n, particle });
        n += 1;
    }

    for (0..1000) |i| {
        std.debug.print("Tick {d} starts with {d} particles.\n", .{ i, particles.items.len });
        try tick(allocator, &particles);
        if (particles.items.len <= 1) {
            break;
        }
    }

    // Checked via command line that all initial positions are unique.

    // std.debug.print("part 1: {d}\n", .{part1(instructions.items)});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, instructions.items)});
}

test "parseLine" {
    const p = try parseLine(0, "p=< 3,0,0>, v=< 2,0,0>, a=<-1,0,0>");
    try std.testing.expectEqualDeep(Vec3{ .x = 3, .y = 0, .z = 0 }, p.p);
    try std.testing.expectEqualDeep(Particle{
        .id = 0,
        .p = Vec3{ .x = 3, .y = 0, .z = 0 },
        .v = Vec3{ .x = 2, .y = 0, .z = 0 },
        .a = Vec3{ .x = -1, .y = 0, .z = 0 },
    }, p);
}
