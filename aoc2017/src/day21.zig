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

const Size = struct {
    width: usize,
    height: usize,
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

    fn printDelim(self: @This(), delim: []const u8) void {
        for (0..self.rows) |y| {
            if (y > 0) {
                std.debug.print("{s}", .{delim});
            }
            for (0..self.cols) |x| {
                std.debug.print("{c}", .{self.get(Coord{ .x = x, .y = y })});
            }
        }
    }

    fn print(self: @This()) void {
        self.printDelim("/");
    }

    fn printSquare(self: @This()) void {
        self.printDelim("\n");
    }

    fn sliceIntoAt(self: @This(), pos: Coord, size: Size, dest: *@This(), destPos: Coord) void {
        const x0 = destPos.x;
        const y0 = destPos.y;
        for (0..size.width) |x| {
            for (0..size.height) |y| {
                dest.set(Coord{ .x = x0 + x, .y = y0 + y }, self.get(Coord{ .x = x + pos.x, .y = y + pos.y }));
            }
        }
    }

    fn sliceInto(self: @This(), pos: Coord, size: Size, dest: *@This()) void {
        self.sliceIntoAt(pos, size, dest, Coord{ .x = 0, .y = 0 });
    }

    fn numSet(self: @This()) usize {
        var n: usize = 0;
        for (0..self.rows) |y| {
            for (0..self.cols) |x| {
                if (self.get(Coord{ .x = x, .y = y }) == '#') {
                    n += 1;
                }
            }
        }
        return n;
    }
};

fn allTransforms(allocator: std.mem.Allocator, pat: Pattern, out: *std.ArrayList(Pattern)) !void {
    // XXX this definitely isn't the minimal set of rotations + flips.
    out.clearAndFree();
    try out.append(pat);

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
    // var flipXY = try createPattern(allocator, pat.rows, pat.cols);
    // flipY.flipX(&flipXY);
    try out.append(flipX);
    try out.append(flipY);
    // try out.append(flipXY);

    lastPat = flipX;
    for (0..3) |_| {
        var rot = try createPattern(allocator, pat.rows, pat.cols);
        lastPat.rotCw(&rot);
        try out.append(rot);
        lastPat = rot;
    }
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

// .#.
// ..#
// ###

fn part1(allocator: std.mem.Allocator, rules: std.StringHashMap(Pattern)) !void {
    var pat = try parsePattern(allocator, ".#./..#/###");

    for (0..5) |iter| {
        var n: usize = 0;
        var m: usize = 0;
        if (pat.rows % 2 == 0) {
            // break the pixels up into 2x2 squares, and convert each 2x2 square into a 3x3 square by following the corresponding enhancement rule.
            n = 2;
            m = 3;
        } else if (pat.rows % 3 == 0) {
            // break the pixels up into 3x3 squares, and convert each 3x3 square into a 4x4 square by following the corresponding enhancement rule.
            n = 3;
            m = 4;
        } else {
            unreachable;
        }

        const numCells = pat.rows / n;
        var slice = try createPattern(allocator, n, n);
        var out = try createPattern(allocator, numCells * m, numCells * m);
        const dims = Size{ .width = n, .height = n };
        const outDims = Size{ .width = m, .height = m };
        for (0..numCells) |yi| {
            var y0 = n * yi;
            for (0..numCells) |xi| {
                const x0 = n * xi;
                pat.sliceInto(Coord{ .x = x0, .y = y0 }, dims, &slice);
                std.debug.print("Looking up:", .{});
                slice.print();
                std.debug.print("\n", .{});
                var rep = rules.get(slice.buf).?;
                rep.sliceIntoAt(Coord{ .x = 0, .y = 0 }, outDims, &out, Coord{ .x = m * xi, .y = m * yi });
            }
        }
        pat = out;
        std.debug.print("After {d} iters:\n", .{iter + 1});
        pat.printSquare();
        std.debug.print("\n{d} set\n", .{pat.numSet()});
    }
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

    var it = rules.iterator();
    while (it.next()) |entry| {
        std.debug.print("{s} -> ", .{entry.key_ptr.*});
        entry.value_ptr.print();
        std.debug.print("\n", .{});
    }

    try part1(allocator, rules);

    // try part1(allocator, maze, x0);

    // std.debug.print("part 1: {d}\n", .{part1(instructions.items)});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, instructions.items)});
}
