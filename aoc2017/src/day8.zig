const std = @import("std");
const util = @import("./util.zig");

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

fn splitIntoArrayList(input: []const u8, delim: []const u8, array_list: *std.ArrayList([]const u8)) !void {
    array_list.clearAndFree();
    var it = std.mem.splitSequence(u8, input, delim);
    while (it.next()) |part| {
        try array_list.append(part);
    }
}

// Returned instruction is valid so long as line is.
fn parseInstruction(allocator: std.mem.Allocator, line: []const u8) !Instruction {
    // aj dec -520 if icd < 9
    var parts = std.ArrayList([]const u8).init(allocator);
    defer parts.deinit();

    try splitIntoArrayList(line, " ", &parts);
    assert(parts.items.len == 7);
    const reg = parts.items[0];
    var op = std.meta.stringToEnum(Op, parts.items[1]) orelse unreachable;
    const amount = try std.fmt.parseInt(i32, parts.items[2], 10);

    assert(std.mem.eql(u8, parts.items[3], "if"));
    const cond_reg = parts.items[4];
    // See https://www.reddit.com/r/Zig/comments/13buv9l/extended_switch_semantics_on_stringsarrays/jje4st0/
    const cond_op = std.meta.stringToEnum(Relation, parts.items[5]) orelse unreachable;
    const comp_val = try std.fmt.parseInt(i32, parts.items[6], 10);
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

pub fn hashMinMaxValue(comptime V: type, hash_map: std.StringHashMap(V)) struct { min: V, max: V } {
    var min: V = undefined;
    var max: V = undefined;
    var it = hash_map.valueIterator();
    if (it.next()) |val| {
        min = val.*;
        max = val.*;
    } else {
        unreachable;
    }
    while (it.next()) |val| {
        min = @min(min, val.*);
        max = @max(max, val.*);
    }
    return .{ .min = min, .max = max };
}

pub fn main(parent_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();

    var line_it = try util.iterLines(filename, allocator);
    defer line_it.deinit();

    var reg = std.StringHashMap(i32).init(allocator);
    var max_ever: i32 = 0;

    while (try line_it.next()) |line_in| {
        const line = try allocator.dupe(u8, line_in);
        std.debug.print("line: '{s}'\n", .{line});
        const instr = try parseInstruction(allocator, line);
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
            try reg.put(instr.reg, target_val);
        }
        printHashMap(i32, reg);
        max_ever = @max(max_ever, hashMinMaxValue(i32, reg).max);
    }

    std.debug.print("part 1: {d}\n", .{hashMinMaxValue(i32, reg).max});
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
