const std = @import("std");
const util = @import("./util.zig");
const Queue = @import("./queue.zig").Queue;
const bufIter = @import("./buf-iter.zig");

const assert = std.debug.assert;

const RV = enum { Reg, Value };
const RegOrValue = union(RV) { Reg: u8, Value: i128 };

const Code = enum { snd, set, add, mul, mod, rcv, jgz };

const RegAndValue = struct {
    a: u8,
    b: RegOrValue,
};
const TwoRegValue = struct {
    a: RegOrValue,
    b: RegOrValue,
};

const Instruction = union(Code) {
    snd: RegOrValue,
    set: RegAndValue,
    add: RegAndValue,
    mul: RegAndValue,
    mod: RegAndValue,
    rcv: u8,
    jgz: TwoRegValue,
};

fn valueOf(regs: []const i128, rv: RegOrValue) i128 {
    return switch (rv) {
        .Reg => |reg| regs[reg],
        .Value => |v| v,
    };
}

// snd X plays a sound with a frequency equal to the value of X.
// set X Y sets register X to the value of Y.
// add X Y increases register X by the value of Y.
// mul X Y sets register X to the result of multiplying the value contained in register X by the value of Y.
// mod X Y sets register X to the remainder of dividing the value contained in register X by the value of Y (that is, it sets X to the result of X modulo Y).
// rcv X recovers the frequency of the last sound played, but only when the value of X is not zero. (If it is zero, the command does nothing.)
// jgz X Y jumps with an offset of the value of Y, but only if the value of X is greater than zero. (An offset of 2 skips the next instruction, an offset of -1 jumps to the previous instruction, and so on.)

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
    const parts = util.splitIntoBuf(line, " ", &buf);
    const instr: Code = std.meta.stringToEnum(Code, parts[0]).?;
    const args = parts[1..];
    return switch (instr) {
        .snd => Instruction{ .snd = try parseRegOrValue(args[0]) },
        .rcv => switch (try parseRegOrValue(args[0])) {
            .Reg => |r| Instruction{ .rcv = r },
            .Value => unreachable,
        },
        .jgz => {
            return Instruction{
                .jgz = .{
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
                .add => Instruction{ .add = .{ .a = r, .b = b } },
                .mul => Instruction{ .mul = .{ .a = r, .b = b } },
                .mod => Instruction{ .mod = .{ .a = r, .b = b } },
                else => unreachable,
            };
        },
    };
}

const State1 = struct {
    pos: usize,
    regs: [26]i128,
    sound: i128,
    recovered: ?i128,
};

fn execute1(instr: Instruction, state: *State1) void {
    switch (instr) {
        .snd => |freq| {
            state.sound = valueOf(&state.regs, freq);
            state.pos += 1;
        },
        .set => |rv| {
            state.regs[rv.a] = valueOf(&state.regs, rv.b);
            state.pos += 1;
        },
        .add => |rv| {
            state.regs[rv.a] += valueOf(&state.regs, rv.b);
            state.pos += 1;
        },
        .mul => |rv| {
            state.regs[rv.a] *= valueOf(&state.regs, rv.b);
            state.pos += 1;
        },
        .mod => |rv| {
            // XXX check that this does the right modulus
            const v = state.regs[rv.a];
            const m = valueOf(&state.regs, rv.b);
            assert(v >= 0);
            assert(m >= 0);
            state.regs[rv.a] = @mod(v, m);
            state.pos += 1;
        },
        .rcv => |rv| {
            const v = state.regs[rv];
            if (v != 0) {
                std.debug.print("Recovered sound {d}!\n", .{state.sound});
                state.recovered = state.sound;
            } else {
                std.debug.print("Did not recover sound\n", .{});
            }
            state.pos += 1;
        },
        .jgz => |vv| {
            const v = valueOf(&state.regs, vv.a);
            if (v > 0) {
                const offset = valueOf(&state.regs, vv.b);
                // This is a doozy!
                state.pos = @intCast(@as(i128, @intCast(state.pos)) + offset);
            } else {
                state.pos += 1;
            }
        },
    }
}

fn part1(instructions: []Instruction) i128 {
    var regs = std.mem.zeroes([26]i128);
    var state = State1{
        .pos = 0,
        .regs = regs,
        .sound = 0,
        .recovered = null,
    };

    while (state.pos >= 0 and state.pos < instructions.len) {
        const instr = instructions[state.pos];
        execute1(instr, &state);
        if (state.recovered) |value| {
            return value;
        }
        // std.debug.print("execute {any} -> {any}\n", .{ instr, state });
    }
    unreachable;
}

const State2 = struct {
    pos: usize,
    regs: [26]i128,
    produced: Queue(i128),
    numSent: usize,
};

const StallState = enum { Stalled, NotStalled };

fn execute2(instr: Instruction, state: *State2, other: *State2) !StallState {
    switch (instr) {
        .snd => |val| {
            const v = valueOf(&state.regs, val);
            try state.produced.enqueue(v);
            state.pos += 1;
            state.numSent += 1;
        },
        .rcv => |r| {
            if (other.produced.dequeue()) |val| {
                state.regs[r] = val;
                state.pos += 1;
            } else {
                // stall! don't advance position so that we come back here.
                return .Stalled;
            }
        },
        .set => |rv| {
            state.regs[rv.a] = valueOf(&state.regs, rv.b);
            state.pos += 1;
        },
        .add => |rv| {
            state.regs[rv.a] += valueOf(&state.regs, rv.b);
            state.pos += 1;
        },
        .mul => |rv| {
            state.regs[rv.a] *= valueOf(&state.regs, rv.b);
            state.pos += 1;
        },
        .mod => |rv| {
            // XXX check that this does the right modulus
            const v = state.regs[rv.a];
            const m = valueOf(&state.regs, rv.b);
            assert(v >= 0);
            assert(m >= 0);
            state.regs[rv.a] = @mod(v, m);
            state.pos += 1;
        },
        .jgz => |vv| {
            const v = valueOf(&state.regs, vv.a);
            if (v > 0) {
                const offset = valueOf(&state.regs, vv.b);
                // This is a doozy!
                state.pos = @intCast(@as(i128, @intCast(state.pos)) + offset);
            } else {
                state.pos += 1;
            }
        },
    }
    return .NotStalled;
}

fn isDone(state: State2, numInstruction: usize) bool {
    return (state.pos < 0 or state.pos >= numInstruction);
}

fn executeUntilStallOrDone(state: *State2, instructions: []Instruction, otherState: *State2) !void {
    while (true) {
        const instr = instructions[state.pos];
        const stallState = try execute2(instr, state, otherState);
        if (stallState == .Stalled) {
            return;
        }
        if (isDone(state.*, instructions.len)) {
            return;
        }
    }
    unreachable;
}

fn part2(allocator: std.mem.Allocator, instructions: []Instruction) !usize {
    const n = instructions.len;
    var regs0 = std.mem.zeroes([26]i128);
    var regs1 = std.mem.zeroes([26]i128);
    var state0 = State2{
        .pos = 0,
        .regs = regs0,
        .produced = Queue(i128).init(allocator),
        .numSent = 0,
    };
    var state1 = State2{
        .pos = 0,
        .regs = regs1,
        .produced = Queue(i128).init(allocator),
        .numSent = 0,
    };
    state1.regs['p' - 'a'] = 1;

    while (true) {
        try executeUntilStallOrDone(&state0, instructions, &state1);
        if (isDone(state0, n)) {
            std.debug.print("program 0 terminated\n", .{});
            return state1.numSent;
        }
        try executeUntilStallOrDone(&state1, instructions, &state0);
        if (isDone(state1, n)) {
            std.debug.print("program 1 terminated\n", .{});
            return state1.numSent;
        }
        if (state0.produced.isEmpty() and state1.produced.isEmpty()) {
            std.debug.print("deadlock! 0: {d} / 1: {d}\n", .{ state0.numSent, state1.numSent });
            return state1.numSent;
        }
    }
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var lines_it = try bufIter.iterLines(filename);

    var instructions = std.ArrayList(Instruction).init(allocator);
    defer instructions.deinit();

    while (try lines_it.next()) |line| {
        // std.debug.print("line: {s}\n", .{line});
        // Comment this out and the lines all look great:
        const instruction = try parseLine(line);
        // std.debug.print("{d:>3} {any}\n", .{ instructions.items.len, instruction });
        try instructions.append(instruction);
    }

    // std.debug.print("part 1: {d}\n", .{part1(instructions.items)});
    std.debug.print("part 2: {d}\n", .{try part2(allocator, instructions.items)});
}
