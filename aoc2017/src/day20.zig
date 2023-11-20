const std = @import("std");
const util = @import("./util.zig");

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
    p: Vec3,
    v: Vec3,
    a: Vec3,
};

fn parseVec3(buf: []const u8) !Vec3 {
    // std.debug.print("parse vec3: '{s}'\n", .{buf});
    const part1 = util.splitOne(buf, ",").?;
    const xStr = std.mem.trim(u8, part1.head, " ");
    const part2 = util.splitOne(part1.rest, ",").?;
    const yStr = std.mem.trim(u8, part2.head, " ");
    const zStr = std.mem.trim(u8, part2.rest, " ");
    // std.debug.print("x/y/z: '{s}'/'{s}'/'{s}'\n", .{ xStr, yStr, zStr });
    const x = try std.fmt.parseInt(i64, xStr, 10);
    const y = try std.fmt.parseInt(i64, yStr, 10);
    const z = try std.fmt.parseInt(i64, zStr, 10);
    return Vec3{ .x = x, .y = y, .z = z };
}

fn parseLine(line: []const u8) !Particle {
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

    return Particle{ .p = p, .v = v, .a = a };
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var particles = std.ArrayList(Particle).init(allocator);
    defer particles.deinit();

    var n: usize = 0;
    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        const particle = try parseLine(line);
        try particles.append(particle);

        std.debug.print("{d}\t{d}\t{any}\n", .{ particle.a.l1norm(), n, particle });
        n += 1;
    }

    // std.debug.print("part 1: {d}\n", .{part1(instructions.items)});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, instructions.items)});
}

test "parseLine" {
    const p = try parseLine("p=< 3,0,0>, v=< 2,0,0>, a=<-1,0,0>");
    try std.testing.expectEqualDeep(Vec3{ .x = 3, .y = 0, .z = 0 }, p.p);
    try std.testing.expectEqualDeep(Particle{
        .p = Vec3{ .x = 3, .y = 0, .z = 0 },
        .v = Vec3{ .x = 2, .y = 0, .z = 0 },
        .a = Vec3{ .x = -1, .y = 0, .z = 0 },
    }, p);
}
