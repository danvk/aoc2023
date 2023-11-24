const std = @import("std");
const util = @import("./util.zig");

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
    var line = lines[0];
    assert(std.mem.startsWith(u8, line, "    - Write the value "));
    var writeChar = line[line.len - 2];
    assert(writeChar == '0' or writeChar == '1');
    var write = try std.fmt.charToDigit(writeChar, 10);

    var moveLine = lines[1];
    var move: i8 = 1;
    if (std.mem.endsWith(u8, moveLine, "to the left.")) {
        move = -1;
    } else if (std.mem.endsWith(u8, moveLine, "to the right.")) {
        move = 1;
    } else {
        unreachable;
    }

    var stateLine = lines[2];
    assert(std.mem.startsWith(u8, stateLine, "    - Continue with state"));
    var state = stateLine[stateLine.len - 2];
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
    var instr0 = try parseInstruction(rest);
    rest = rest[3..];

    line = rest[0];
    assert(std.mem.endsWith(u8, line, "1:"));
    rest = rest[1..];
    var instr1 = try parseInstruction(rest);
    rest = rest[3..];

    return .{ State{ .state = state, .instr = .{ instr0, instr1 } }, rest };
}

fn parseInput(allocator: std.mem.Allocator, lines: [][]const u8) !TuringMachine {
    var beginLine = lines[0];
    assert(std.mem.startsWith(u8, beginLine, "Begin in state A."));

    var diagnosticLine = lines[1];
    assert(std.mem.startsWith(u8, diagnosticLine, "Perform a diagnostic checksum after "));
    var diagBuf: [1]usize = undefined;
    var diag = try util.extractIntsIntoBuf(usize, diagnosticLine, &diagBuf);
    assert(diag.len == 1);
    var diagnosticSteps = diag[0];

    var states = std.ArrayList(State).init(allocator);

    var rest = lines[2..];
    while (rest.len > 0) {
        assert(rest[0].len == 0);
        rest = rest[1..];
        var pair = try parseState(rest);
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

pub fn main(parent_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(parent_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    const filename = args[0];

    var contents = try util.readInputFile(filename, allocator);
    var lines = std.ArrayList([]const u8).init(allocator);
    try util.splitIntoArrayList(contents, "\n", &lines);

    var machine = try parseInput(allocator, lines.items);
    std.debug.print("machine: {any}\n", .{machine});

    // std.debug.print("part 1: {d}\n", .{part1(&components.items)});
    // std.debug.print("part 2: {any}\n", .{part1(&components.items)});
}
