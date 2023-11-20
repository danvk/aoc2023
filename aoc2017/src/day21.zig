const std = @import("std");
const util = @import("./util.zig");

const assert = std.debug.assert;

// .#.
// ..#
// ###

const Coord = struct {
    x: usize,
    y: usize,
};

const Pattern = struct {
    buf: []u8,
    rows: usize,
    cols: usize,

    fn get(self: @This(), p: Coord) u8 {
        return self.buf[self.cols * p.y + p.x];
    }

    fn set(self: *@This(), p: Coord, val: u8) void {
        self.buf[self.cols * p.y + p.x] = val;
    }

    fn flipX(self: @This(), dest: *@This()) void {
        const w = self.cols;
        for (0..self.rows) |y| {
            for (0..w) |x| {
                dest.set(Coord{ .x = x, .y = y }, self.get(Coord{ .x = w - 1 - x, .y = y }));
            }
        }
    }

    fn flipY(self: @This(), dest: *@This()) void {
        const h = self.rows;
        for (0..h) |y| {
            for (0..self.cols) |x| {
                dest.set(Coord{ .x = x, .y = y }, self.get(Coord{ .x = x, .y = h - 1 - y }));
            }
        }
    }

    // ABC    GDA
    // DEF -> HEB
    // GHI    IFC

    fn rotCw(self: @This(), dest: *@This()) void {
        const w = self.cols;
        const h = self.rows;
        for (0..h) |y| {
            for (0..w) |x| {
                dest.set(Coord{ .x = h - 1 - y, .y = x }, self.get(Coord{ .x = x, .y = y }));
            }
        }
    }

    fn print(self: @This()) void {
        for (0..self.rows) |y| {
            if (y > 0) {
                std.debug.print("/", .{});
            }
            for (0..self.cols) |x| {
                std.debug.print("{c}", .{self.get(Coord{ .x = x, .y = y })});
            }
        }
    }
};

fn allTransforms(allocator: std.mem.Allocator, pat: Pattern, out: *std.ArrayList(Pattern)) !void {
    out.clearAndFree();
    var lastPat = pat;
    for (0..3) |_| {
        var rot = try createPattern(allocator, pat.rows, pat.cols);
        lastPat.rotCw(&rot);
        try out.append(rot);
        lastPat = rot;
    }

    var flipX = try createPattern(allocator, pat.rows, pat.cols);
    pat.flipX(&flipX);
    var flipY = try createPattern(allocator, pat.rows, pat.cols);
    pat.flipY(&flipY);
    var flipXY = try createPattern(allocator, pat.rows, pat.cols);
    flipY.flipX(&flipXY);
    try out.append(flipX);
    try out.append(flipY);
    try out.append(flipXY);
}

// caller is responsible for freeing returned buffer
fn createPattern(allocator: std.mem.Allocator, rows: usize, cols: usize) !Pattern {
    var buf = try allocator.alloc(u8, rows * cols);
    var pat = Pattern{
        .buf = buf,
        .rows = rows,
        .cols = cols,
    };
    @memset(buf, '.');
    return pat;
}

// caller owns returned buffer
// XXX this would be a good use for a Rust lifetime annotation! Pattern could share buf.
fn parsePattern(allocator: std.mem.Allocator, buf: []const u8) !Pattern {
    var rows = 1 + std.mem.count(u8, buf, "/");
    var pat = try createPattern(allocator, rows, rows);
    for (0..rows) |y| {
        for (0..rows) |x| {
            pat.set(Coord{ .x = x, .y = y }, buf[(rows + 1) * y + x]);
        }
    }
    return pat;
}

const Rule = struct {
    left: Pattern,
    right: Pattern,
};

fn parseRule(allocator: std.mem.Allocator, line: []const u8) !Rule {
    var parts = util.splitOne(line, " => ").?;
    var left = try parsePattern(allocator, parts.head);
    var right = try parsePattern(allocator, parts.rest);

    return Rule{ .left = left, .right = right };
}

pub fn main(parent_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    // XXX why is ArenaAllocator in std.heap rather than std.mem?
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    const filename = args[0];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var rules = std.StringHashMap(Pattern).init(allocator);
    defer rules.deinit();

    var scratch = std.ArrayList(Pattern).init(allocator);

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        var rule = try parseRule(allocator, line);
        std.debug.print("{s} -> {any}\n", .{ line, rule });

        try allTransforms(allocator, rule.left, &scratch);
        for (scratch.items) |left| {
            // std.debug.print("  ", .{});
            // left.print();
            // std.debug.print("\n", .{});
            try rules.put(left.buf, rule.right);
        }
    }

    // try part1(allocator, maze, x0);

    // std.debug.print("part 1: {d}\n", .{part1(instructions.items)});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, instructions.items)});
}
