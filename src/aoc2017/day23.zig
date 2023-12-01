const std = @import("std");
const util = @import("../util.zig");
const Queue = @import("../queue.zig").Queue;

const assert = std.debug.assert;

const RV = enum { Reg, Value };
const RegOrValue = union(RV) { Reg: u8, Value: i128 };

const Code = enum { set, sub, mul, jnz };

const RegAndValue = struct {
    a: u8,
    b: RegOrValue,
};
const TwoRegValue = struct {
    a: RegOrValue,
    b: RegOrValue,
};

const Instruction = union(Code) {
    set: RegAndValue,
    sub: RegAndValue,
    mul: RegAndValue,
    jnz: TwoRegValue,
};

fn valueOf(regs: []const i128, rv: RegOrValue) i128 {
    return switch (rv) {
        .Reg => |reg| regs[reg],
        .Value => |v| v,
    };
}

// set X Y sets register X to the value of Y.
// sub X Y decreases register X by the value of Y.
// mul X Y sets register X to the result of multiplying the value contained in register X by the value of Y.
// jnz X Y jumps with an offset of the value of Y, but only if the value of X is not zero. (An offset of 2 skips the next instruction, an offset of -1 jumps to the previous instruction, and so on.)

fn parseRegOrValue(arg: []const u8) !RegOrValue {
    const r = arg[0];
    if (r >= 'a' and r <= 'z') {
        return RegOrValue{ .Reg = r - 'a' };
    }
    const v = try std.fmt.parseInt(i128, arg, 10);
    return RegOrValue{ .Value = v };
}

fn parseLine(line: []const u8) !Instruction {
    var buf: [3][]const u8 = undefined;
    var parts = util.splitIntoBuf(line, " ", &buf);
    assert(parts.len >= 2);
    const op = parts[0];
    const instr: Code = std.meta.stringToEnum(Code, op).?;
    const args = parts[1..];
    return switch (instr) {
        .jnz => {
            assert(args.len == 2);
            return Instruction{
                .jnz = .{
                    .a = try parseRegOrValue(args[0]),
                    .b = try parseRegOrValue(args[1]),
                },
            };
        },
        else => {
            assert(args.len == 2);
            const a = args[0];
            assert(a.len == 1);
            var r = a[0];
            assert(r >= 'a');
            assert(r <= 'z');
            r -= 'a';
            const b = try parseRegOrValue(args[1]);
            // XXX surely there is a better way?
            return switch (instr) {
                .set => Instruction{ .set = .{ .a = r, .b = b } },
                .sub => Instruction{ .sub = .{ .a = r, .b = b } },
                .mul => Instruction{ .mul = .{ .a = r, .b = b } },
                else => unreachable,
            };
        },
    };
}

const State = struct {
    pos: usize,
    regs: [26]i128,
    numMuls: usize,
};

fn execute(instr: Instruction, state: *State) void {
    switch (instr) {
        .set => |rv| {
            state.regs[rv.a] = valueOf(&state.regs, rv.b);
            state.pos += 1;
        },
        .sub => |rv| {
            state.regs[rv.a] -= valueOf(&state.regs, rv.b);
            state.pos += 1;
        },
        .mul => |rv| {
            state.regs[rv.a] *= valueOf(&state.regs, rv.b);
            state.pos += 1;
            state.numMuls += 1;
        },
        .jnz => |vv| {
            const v = valueOf(&state.regs, vv.a);
            if (v != 0) {
                const offset = valueOf(&state.regs, vv.b);
                // This is a doozy!
                state.pos = @intCast(@as(i128, @intCast(state.pos)) + offset);
            } else {
                state.pos += 1;
            }
        },
    }
}

fn part1(instructions: []Instruction) usize {
    var regs = std.mem.zeroes([26]i128);
    var state = State{
        .pos = 0,
        .regs = regs,
        .numMuls = 0,
    };

    while (state.pos >= 0 and state.pos < instructions.len) {
        const instr = instructions[state.pos];
        execute(instr, &state);
        // std.debug.print("execute {any} -> {any}\n", .{ instr, state });
    }
    return state.numMuls;
}

fn part2(instructions: []Instruction) i128 {
    var regs = std.mem.zeroes([26]i128);
    var state = State{
        .pos = 0,
        .regs = regs,
        .numMuls = 0,
    };
    state.regs[0] = 1;

    while (state.pos >= 0 and state.pos < instructions.len) {
        const instr = instructions[state.pos];
        execute(instr, &state);
        std.debug.print("{any}\n", .{state});
    }
    return state.regs[7];
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var file = try std.fs.cwd().openFile(filename, .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var in_stream = buf_reader.reader();

    var buf: [1024]u8 = undefined;

    var instructions = std.ArrayList(Instruction).init(allocator);
    defer instructions.deinit();

    while (try in_stream.readUntilDelimiterOrEof(&buf, '\n')) |line| {
        // std.debug.print("line: {s}\n", .{line});
        // Comment this out and the lines all look great:
        const instruction = try parseLine(line);
        // std.debug.print("{d:>3} {any}\n", .{ instructions.items.len, instruction });
        try instructions.append(instruction);
    }

    std.debug.print("part 1: {d}\n", .{part1(instructions.items)});
    std.debug.print("part 2: {d}\n", .{part2(instructions.items)});
}
