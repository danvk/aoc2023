const std = @import("std");
const util = @import("./util.zig");
const bufIter = @import("./buf-iter.zig");

const assert = std.debug.assert;

const Relation = enum { @">", @"<", @">=", @"<=", @"==", @"!=" };
const Op = enum { inc, dec };

const Condition = struct {
    reg: []const u8,
    op: Relation,
    val: i32,
};

const Instruction = struct {
    reg: []const u8,
    op: Op,
    amount: i32,
    cond: Condition,
};

// Returned instruction is valid so long as line is.
fn parseInstruction(line: []const u8) !Instruction {
    // aj dec -520 if icd < 9
    var buf: [7][]const u8 = undefined;
    var parts = util.splitIntoBuf(line, " ", &buf);
    assert(parts.len == 7);
    const reg = parts[0];
    var op = std.meta.stringToEnum(Op, parts[1]) orelse unreachable;
    const amount = try std.fmt.parseInt(i32, parts[2], 10);

    assert(std.mem.eql(u8, parts[3], "if"));
    const cond_reg = parts[4];
    // See https://www.reddit.com/r/Zig/comments/13buv9l/extended_switch_semantics_on_stringsarrays/jje4st0/
    const cond_op = std.meta.stringToEnum(Relation, parts[5]) orelse unreachable;
    const comp_val = try std.fmt.parseInt(i32, parts[6], 10);
    return Instruction{ .reg = reg, .op = op, .amount = amount, .cond = Condition{
        .reg = cond_reg,
        .op = cond_op,
        .val = comp_val,
    } };
}

fn printHashMap(comptime V: type, hash_map: std.StringHashMap(V)) void {
    var is_first = true;
    var it = hash_map.iterator();
    std.debug.print("{{ ", .{});
    while (it.next()) |entry| {
        if (!is_first) {
            std.debug.print(", ", .{});
        } else {
            is_first = false;
        }
        std.debug.print("{s}: {any}", .{ entry.key_ptr.*, entry.value_ptr.* });
    }
    std.debug.print(" }}\n", .{});
}

pub fn hashMinMaxValue(comptime V: type, hash_map: std.StringHashMap(V)) ?struct { min: V, max: V } {
    var min: V = undefined;
    var max: V = undefined;
    var it = hash_map.valueIterator();
    if (it.next()) |val| {
        min = val.*;
        max = val.*;
    } else {
        return null;
    }
    while (it.next()) |val| {
        min = @min(min, val.*);
        max = @max(max, val.*);
    }
    return .{ .min = min, .max = max };
}

pub fn hashMaxValue(comptime V: type, hash_map: std.StringHashMap(V)) ?V {
    const minMax = hashMinMaxValue(V, hash_map);
    if (minMax) |v| {
        return v.max;
    }
    return null;
}

pub fn main(parent_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];
    return runOnFile(parent_allocator, filename);
}

pub fn runOnFile(parent_allocator: std.mem.Allocator, filename: [:0]const u8) !void {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var line_it = try bufIter.iterLines(filename);
    defer line_it.deinit();

    var reg = std.StringHashMap(i32).init(allocator);
    var max_ever: i32 = 0;

    while (try line_it.next()) |line_in| {
        const line = try allocator.dupe(u8, line_in);
        std.debug.print("line: '{s}'\n", .{line});
        const instr = try parseInstruction(line);
        const cond = instr.cond;
        const reg_val = reg.get(cond.reg) orelse 0;
        const cond_true = switch (cond.op) {
            .@"<" => reg_val < cond.val,
            .@"<=" => reg_val <= cond.val,
            .@">" => reg_val > cond.val,
            .@">=" => reg_val >= cond.val,
            .@"!=" => reg_val != cond.val,
            .@"==" => reg_val == cond.val,
        };
        if (cond_true) {
            var target_val = reg.get(instr.reg) orelse 0;
            switch (instr.op) {
                .dec => {
                    target_val -= instr.amount;
                },
                .inc => {
                    target_val += instr.amount;
                },
            }
            const my_reg = try allocator.dupe(u8, instr.reg);
            std.debug.print("reg: {s} @ {any}\n", .{ my_reg, my_reg.ptr });

            // uncommenting this causes a crash:
            try reg.put(my_reg, target_val);
        }
        // printHashMap(i32, reg);
        max_ever = @max(max_ever, hashMaxValue(i32, reg) orelse 0);
    }

    std.debug.print("part 1: {d}\n", .{hashMaxValue(i32, reg) orelse 0});
    std.debug.print("part 2: {d}\n", .{max_ever});
}

const expectEqual = std.testing.expectEqual;

test "parse instruction" {
    const actual = try parseInstruction(std.testing.allocator, "aj dec -520 if icd < 9");
    std.debug.print("actual: {any}\n", .{actual});
    try expectEqual(Instruction{ .reg = "aj", .op = .dec, .amount = -520, .cond = Condition{
        .reg = "icd",
        .op = .@"<",
        .val = 9,
    } }, actual);
}

test "sample input" {
    const filename: [:0]const u8 = "day8/sample.txt";
    try runOnFile(std.testing.allocator, filename);
}

test "real input" {
    const filename: [:0]const u8 = "day8/input.txt";
    try runOnFile(std.testing.allocator, filename);
}
