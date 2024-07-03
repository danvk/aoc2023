const std = @import("std");
const util = @import("../util.zig");

const assert = std.debug.assert;

const Instruction = struct {
    write: u8,
    move: i8,
    nextState: u8,
};

const State = struct {
    state: u8,
    instr: [2]Instruction,
};

const TuringMachine = struct {
    startState: u8,
    diagnosticSteps: usize,
    states: []State,
};

fn parseInstruction(lines: [][]const u8) !Instruction {
    const line = lines[0];
    assert(std.mem.startsWith(u8, line, "    - Write the value "));
    const writeChar = line[line.len - 2];
    assert(writeChar == '0' or writeChar == '1');
    const write = try std.fmt.charToDigit(writeChar, 10);

    const moveLine = lines[1];
    var move: i8 = 1;
    if (std.mem.endsWith(u8, moveLine, "to the left.")) {
        move = -1;
    } else if (std.mem.endsWith(u8, moveLine, "to the right.")) {
        move = 1;
    } else {
        unreachable;
    }

    const stateLine = lines[2];
    assert(std.mem.startsWith(u8, stateLine, "    - Continue with state"));
    const state = stateLine[stateLine.len - 2];
    assert(state >= 'A');
    assert(state <= 'Z');

    return Instruction{ .write = write, .move = move, .nextState = state };
}

fn parseState(lines: [][]const u8) !struct { State, [][]const u8 } {
    const first = lines[0];
    var rest = lines[1..];
    assert(std.mem.startsWith(u8, first, "In state "));
    const state = first[9];
    assert(state >= 'A');
    assert(state <= 'Z');

    var line = rest[0];
    assert(std.mem.endsWith(u8, line, "0:"));
    rest = rest[1..];
    const instr0 = try parseInstruction(rest);
    rest = rest[3..];

    line = rest[0];
    assert(std.mem.endsWith(u8, line, "1:"));
    rest = rest[1..];
    const instr1 = try parseInstruction(rest);
    rest = rest[3..];

    return .{ State{ .state = state, .instr = .{ instr0, instr1 } }, rest };
}

fn parseInput(allocator: std.mem.Allocator, lines: [][]const u8) !TuringMachine {
    const beginLine = lines[0];
    assert(std.mem.startsWith(u8, beginLine, "Begin in state A."));

    const diagnosticLine = lines[1];
    assert(std.mem.startsWith(u8, diagnosticLine, "Perform a diagnostic checksum after "));
    var diagBuf: [1]usize = undefined;
    const diag = try util.extractIntsIntoBuf(usize, diagnosticLine, &diagBuf);
    assert(diag.len == 1);
    const diagnosticSteps = diag[0];

    var states = std.ArrayList(State).init(allocator);

    var rest = lines[2..];
    while (rest.len > 0) {
        assert(rest[0].len == 0);
        rest = rest[1..];
        const pair = try parseState(rest);
        try states.append(pair[0]);
        std.debug.print("state: {any}\n", .{pair[0]});
        rest = pair[1];
    }

    return TuringMachine{
        .startState = 'A',
        .diagnosticSteps = diagnosticSteps,
        .states = states.items,
    };
}

fn execute(allocator: std.mem.Allocator, machine: TuringMachine) !usize {
    var regs = std.AutoHashMap(i128, u8).init(allocator);

    var pos: i128 = 0;
    var state = machine.startState;
    for (0..machine.diagnosticSteps) |_| {
        const val = regs.get(pos) orelse 0;
        const instr = machine.states[state - 'A'].instr[val];
        try regs.put(pos, instr.write);
        pos += instr.move;
        state = instr.nextState;
    }

    var it = regs.valueIterator();
    var count: usize = 0;
    while (it.next()) |v| {
        if (v.* == 1) {
            count += 1;
        }
    }
    return count;
}

pub fn main(parent_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const filename = args[0];

    const contents = try util.readInputFile(allocator, filename);
    var lines = std.ArrayList([]const u8).init(allocator);
    try util.splitIntoArrayList(contents, "\n", &lines);

    const machine = try parseInput(allocator, lines.items);
    std.debug.print("machine: {any}\n", .{machine});

    std.debug.print("part 1: {d}\n", .{try execute(allocator, machine)});
    // std.debug.print("part 2: {any}\n", .{part1(&components.items)});
}
