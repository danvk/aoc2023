const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

const Coord3 = struct {
    x: i32,
    y: i32,
    z: i32,

    pub fn down1(self: @This()) Coord3 {
        return Coord3{ .x = self.x, .y = self.y, .z = self.z - 1 };
    }

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.fs.File.Writer) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{d},{d},{d}", .{ self.x, self.y, self.z });
    }
};

const Orientation = enum { X, Y, Z };

const Brick = struct {
    name: u8,
    a: Coord3,
    b: Coord3,

    pub fn format(self: @This(), comptime fmt: []const u8, options: std.fmt.FormatOptions, writer: std.fs.File.Writer) !void {
        _ = fmt;
        _ = options;
        try std.fmt.format(writer, "{c}: {any}~{any}", .{ self.name, self.a, self.b });
    }

    pub fn contains(self: @This(), pt: Coord3) bool {
        var dx: i32 = if (self.lenX() != 0) 1 else 0;
        var dy: i32 = if (self.lenY() != 0) 1 else 0;
        var dz: i32 = if (self.lenZ() != 0) 1 else 0;
        var x = self.a.x;
        var y = self.a.y;
        var z = self.a.z;
        var n = self.len();
        var i: i32 = 0;
        while (i <= n) : (i += 1) {
            if (x == pt.x and y == pt.y and z == pt.z) {
                return true;
            }
            x += dx;
            y += dy;
            z += dz;
        }
        return false;
    }

    pub fn lenX(self: @This()) i32 {
        return self.b.x - self.a.x;
    }
    pub fn lenY(self: @This()) i32 {
        return self.b.y - self.a.y;
    }
    pub fn lenZ(self: @This()) i32 {
        return self.b.z - self.a.z;
    }
    pub fn len(self: @This()) i32 {
        return self.lenX() + self.lenY() + self.lenZ();
    }
    pub fn bottom(self: @This()) i32 {
        return self.a.z;
    }
    pub fn getOrientation(self: @This()) Orientation {
        if (self.lenX() > 1) {
            return .X;
        } else if (self.lenY() > 1) {
            return .Y;
        }
        return .Z;
    }
    pub fn intersects(self: @This(), other: Brick) bool {
        // TODO: optimize
        var dx: i32 = if (self.lenX() != 0) 1 else 0;
        var dy: i32 = if (self.lenY() != 0) 1 else 0;
        var dz: i32 = if (self.lenZ() != 0) 1 else 0;
        var x = self.a.x;
        var y = self.a.y;
        var z = self.a.z;
        var n = self.len();
        var i: i32 = 0;
        while (i <= n) : (i += 1) {
            const pt = Coord3{ .x = x, .y = y, .z = z };
            if (other.contains(pt)) {
                return true;
            }
            x += dx;
            y += dy;
            z += dz;
        }
        return false;
    }
};

fn sortByBottom(_: void, a: Brick, b: Brick) bool {
    return a.bottom() < b.bottom();
}
fn sortByName(_: void, a: Brick, b: Brick) bool {
    return a.name < b.name;
}

const Support = struct {
    bottom: usize,
    top: usize,
};

fn findSupports(bricks: std.ArrayList(Brick)) !usize {
    var allocator = bricks.allocator;
    std.mem.sort(Brick, bricks.items, {}, sortByBottom);

    // var supports = std.AutoHashMap(usize, usize).init(allocator);
    // defer supports.deinit();

    var supports = std.ArrayList(Support).init(allocator);
    defer supports.deinit();

    for (bricks.items, 0..) |*brick, i| {
        var z = brick.bottom();
        if (z == 1) {
            std.debug.print("Brick {c} is on the ground\n", .{brick.name});
            continue; // already resting on the ground
        }

        // Check if another brick is supporting us.
        // Since we've already moved all the bricks under us, it won't budge.
        const drop1 = Brick{ .a = brick.a.down1(), .b = brick.b.down1(), .name = brick.name };
        for (bricks.items[0..i], 0..) |other, j| {
            if (drop1.intersects(other)) {
                std.debug.print("Brick {c} is supporting {c}\n", .{ other.name, brick.name });
                // try supports.put(j, 1 + (supports.get(j) orelse 0));
                try supports.append(Support{ .bottom = j, .top = i });
            }
        }
    }

    var canDisintegrate = try allocator.alloc(bool, bricks.items.len);
    @memset(canDisintegrate, true);
    defer allocator.free(canDisintegrate);

    for (bricks.items, 0..) |brick, i| {
        var numSupports: usize = 0;
        var support: ?usize = null;
        for (supports.items) |sup| {
            if (sup.top == i) {
                support = sup.bottom;
                numSupports += 1;
            }
        }
        if (numSupports == 1) {
            const j = support.?;
            std.debug.print("{c} is sole support for {c}\n", .{ bricks.items[j].name, brick.name });
            canDisintegrate[j] = false;
        }
    }

    var num: usize = 0;
    for (canDisintegrate) |c| {
        if (c) {
            num += 1;
        }
    }
    return num;
}

fn fall1(bricks: *std.ArrayList(Brick)) bool {
    var anyMoved = false;
    std.mem.sort(Brick, bricks.items, {}, sortByBottom);
    for (bricks.items, 0..) |*brick, i| {
        var z = brick.bottom();
        if (z == 1) {
            // std.debug.print("Brick {c} is on the ground\n", .{brick.name});
            continue; // already resting on the ground
        }
        // Check if another brick is supporting us.
        // Since we've already moved all the bricks under us, it won't budge.
        const drop1 = Brick{ .a = brick.a.down1(), .b = brick.b.down1(), .name = brick.name };
        var isSupported = false;
        for (bricks.items[0..i]) |other| {
            if (drop1.intersects(other)) {
                // std.debug.print("Brick {c} is supported by {c}\n", .{ brick.name, other.name });
                isSupported = true;
                break;
            }
        }
        if (isSupported) {
            continue;
        }
        // no support: drop it!
        // std.debug.print("Dropping {any}\n", .{brick.*});
        brick.* = drop1;
        assert(brick.bottom() == z - 1);
        anyMoved = true;
    }
    return anyMoved;
}

fn fall(bricks: *std.ArrayList(Brick)) void {
    while (fall1(bricks)) {
        std.debug.print("---\n", .{});
    }
}

fn parseBrick(line: []const u8, i: usize) !Brick {
    var name: u8 = if (i >= 26) 'Z' else 'A' + @as(u8, @intCast(i));
    var intBuf: [6]i32 = undefined;
    var ints = try util.extractIntsIntoBuf(i32, line, &intBuf);
    var a = Coord3{ .x = ints[0], .y = ints[1], .z = ints[2] };
    var b = Coord3{ .x = ints[3], .y = ints[4], .z = ints[5] };
    var brick = Brick{ .a = a, .b = b, .name = name };

    assert(brick.a.x <= brick.b.x);
    assert(brick.a.y <= brick.b.y);
    assert(brick.a.z <= brick.b.z);
    return brick;
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var bricks = std.ArrayList(Brick).init(allocator);
    defer bricks.deinit();
    var iter = try bufIter.iterLines(filename);
    var i: usize = 0;
    while (try iter.next()) |line| {
        const brick = try parseBrick(line, i);
        try bricks.append(brick);
        i += 1;
    }

    fall(&bricks);
    std.mem.sort(Brick, bricks.items, {}, sortByName);
    std.debug.print("---\nResting state:\n", .{});
    for (bricks.items) |brick| {
        std.debug.print("{any}\n", .{brick});
    }
    std.debug.print("---\n", .{});
    var sum1 = try findSupports(bricks);

    std.debug.print("part 1: {d}\n", .{sum1});
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "intersects" {
    const A = try parseBrick("1,0,1~1,2,1", 0); //   <- A
    // const B = try parseBrick("0,0,2~2,0,2"); //   <- B
    const C = try parseBrick("0,2,2~2,2,2", 2); //   <- C

    // dropc1: C: 0,2,1~2,2,1 : 0,2,1 1,2,1 2,2,1
    //      A: A: 1,0,1~1,2,1 : 1,0,1 1,1,1 1,2,1
    const dropC1 = Brick{ .a = C.a.down1(), .b = C.b.down1(), .name = C.name };
    std.debug.print("dropc1: {any}\n", .{dropC1});
    std.debug.print("A: {any}\n", .{A});
    try expect(dropC1.intersects(A));
}
