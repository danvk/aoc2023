const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const interval = @import("./interval.zig");

const IvI32 = interval.Interval(i32);

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
        var me = IvI32{ .low = self.a.x, .high = self.b.x + 1 };
        var them = IvI32{ .low = other.a.x, .high = other.b.x + 1 };
        if (!me.intersects(them)) {
            return false;
        }

        me = IvI32{ .low = self.a.y, .high = self.b.y + 1 };
        them = IvI32{ .low = other.a.y, .high = other.b.y + 1 };
        if (!me.intersects(them)) {
            return false;
        }

        me = IvI32{ .low = self.a.z, .high = self.b.z + 1 };
        them = IvI32{ .low = other.a.z, .high = other.b.z + 1 };
        return me.intersects(them);
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
    std.debug.print("part 1: {d}\n", .{num});

    var num2: usize = 0;
    for (bricks.items, 0..) |brick, i| {
        const n = try chainReaction(allocator, bricks.items, i);
        std.debug.print("{any} drops {d}\n", .{ brick, n });
        num2 += n;
    }
    return num2;
}

// How many other bricks would disintegrating i drop?
fn chainReaction(allocator: std.mem.Allocator, bricks: []Brick, i: usize) !usize {
    var copyBuf = try allocator.dupe(Brick, bricks);
    defer allocator.free(copyBuf);

    for (i..(bricks.len - 1)) |j| {
        copyBuf[j] = copyBuf[j + 1];
    }
    var copy = copyBuf[0..(bricks.len - 1)];
    return fall1(copy);
}

fn fall1(bricks: []Brick) usize {
    var numMoved: usize = 0;
    std.mem.sort(Brick, bricks, {}, sortByBottom);
    for (bricks, 0..) |*brick, i| {
        var z = brick.bottom();
        if (z == 1) {
            // std.debug.print("Brick {c} is on the ground\n", .{brick.name});
            continue; // already resting on the ground
        }
        // Check if another brick is supporting us.
        // Since we've already moved all the bricks under us, it won't budge.
        const drop1 = Brick{ .a = brick.a.down1(), .b = brick.b.down1(), .name = brick.name };
        var isSupported = false;
        for (bricks[0..i]) |other| {
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
        numMoved += 1;
    }
    return numMoved;
}

fn fall(bricks: *std.ArrayList(Brick)) void {
    var n: usize = 0;
    while (fall1(bricks.items) > 0) {
        std.debug.print("{d} ---\n", .{n});
        n += 1;
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

    std.debug.print("part 2: {d}\n", .{sum1});
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
