const std = @import("std");
const util = @import("./util.zig");

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
    rcv: RegOrValue,
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

fn splitOne(line: []const u8, delim: []const u8) ?struct { head: []const u8, rest: []const u8 } {
    const maybeIdx = std.mem.indexOf(u8, line, delim);
    // XXX is there a more idiomatic way to write this pattern?
    if (maybeIdx) |idx| {
        return .{ .head = line[0..idx], .rest = line[(idx + 1)..] };
    } else {
        return null;
    }
}

fn parseRegOrValue(arg: []const u8) !RegOrValue {
    const r = arg[0];
    if (r >= 'a' and r <= 'z') {
        return RegOrValue{ .Reg = r - 'a' };
    }
    const v = try std.fmt.parseInt(i128, arg, 10);
    return RegOrValue{ .Value = v };
}

fn parseLine(line: []const u8) !Instruction {
    const instrRest = splitOne(line, " ").?;
    const instr: Code = std.meta.stringToEnum(Code, instrRest.head).?;
    const args = instrRest.rest;
    return switch (instr) {
        .snd => Instruction{ .snd = try parseRegOrValue(args) },
        .rcv => Instruction{ .rcv = try parseRegOrValue(args) },
        .jgz => {
            const two = splitOne(args, " ").?;
            return Instruction{
                .jgz = .{
                    .a = try parseRegOrValue(two.head),
                    .b = try parseRegOrValue(two.rest),
                },
            };
        },
        else => {
            const two = splitOne(args, " ").?;
            const a = two.head;
            assert(a.len == 1);
            var r = a[0];
            assert(r >= 'a');
            assert(r <= 'z');
            r -= 'a';
            const b = try parseRegOrValue(two.rest);
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

const State = struct {
    pos: usize,
    regs: [26]i128,
    sound: i128,
};

fn execute(instr: Instruction, state: *State) void {
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
            const v = valueOf(&state.regs, rv);
            if (v != 0) {
                std.debug.print("Recovered sound {d}!\n", .{state.sound});
                std.process.exit(0);
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
        std.debug.print("{d:>3} {any}\n", .{ instructions.items.len, instruction });
        try instructions.append(instruction);
    }

    var regs = std.mem.zeroes([26]i128);
    var state = State{
        .pos = 0,
        .regs = regs,
        .sound = 0,
    };

    while (state.pos >= 0 and state.pos < instructions.items.len) {
        const instr = instructions.items[state.pos];
        execute(instr, &state);
        std.debug.print("execute {any} -> {any}\n", .{ instr, state });
    }

    // std.debug.print("part 1: {d}\n", .{try part1(allocator, step)});
    // std.debug.print("part 2: {d}\n", .{try part2(allocator, step)});
}
