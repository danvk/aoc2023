const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const queue = @import("./queue.zig");

const assert = std.debug.assert;

// alternative with arena allocator:

const PulseType = enum { low, high };
const ModuleType = enum { broadcast, flipFlop, conjunction };

const Module = struct {
    name: []const u8,
    typ: ModuleType,
    nextStrs: [][]const u8,
    nexts: []?*Module,
    values: std.StringHashMap(PulseType),
    flipFlopOn: bool,
};

const Pulse = struct {
    from: []const u8,
    to: []const u8,
    val: PulseType,
};

fn parseModule(allocator: std.mem.Allocator, line: []const u8) !Module {
    var sides = util.splitOne(line, " -> ").?;
    const nameType = sides.head;
    var mod: Module = undefined;
    if (nameType[0] == '%') {
        // flip-flop
        mod.name = nameType[1..];
        mod.typ = .flipFlop;
        mod.flipFlopOn = false;
    } else if (nameType[0] == '&') {
        mod.name = nameType[1..];
        mod.typ = .conjunction;
    } else if (std.mem.eql(u8, nameType, "broadcaster")) {
        mod.name = nameType;
        mod.typ = .broadcast;
    } else {
        unreachable;
    }
    var nextStrs = std.ArrayList([]const u8).init(allocator);
    try util.splitIntoArrayList(sides.rest, ", ", &nextStrs);
    mod.nextStrs = nextStrs.items;
    mod.values = std.StringHashMap(PulseType).init(allocator);
    mod.nexts = try allocator.alloc(?*Module, mod.nextStrs.len);
    @memset(mod.nexts, null);
    return mod;
}

fn setNexts(modules: *std.StringHashMap(Module)) !void {
    var it = modules.valueIterator();
    while (it.next()) |module| {
        for (module.nextStrs, 0..) |nextStr, i| {
            if (modules.getPtr(nextStr)) |next| {
                module.nexts[i] = next;
                assert(module.nexts[i] == next);
                try next.values.put(module.name, .low);
                assert(next.values.contains(module.name));
                assert(next.values.get(module.name).? == .low);
            } else {
                std.debug.print("untyped module: {s}\n", .{nextStr});
                module.nexts[i] = null;
            }
        }
    }
}

fn indexOfStr(haystack: [][]const u8, needle: []const u8) ?usize {
    for (haystack, 0..) |str, i| {
        if (std.mem.eql(u8, str, needle)) {
            return i;
        }
    }
    return null;
}

fn printPulse(pulse: Pulse) void {
    std.debug.print("{s} -{s}-> {s}\n", .{ pulse.from, if (pulse.val == .low) "low" else "high", pulse.to });
}

fn allHashValuesEql(comptime T: type, map: std.StringHashMap(T), val: T) bool {
    var it = map.valueIterator();
    while (it.next()) |v| {
        if (v.* != val) {
            return false;
        }
    }
    return true;
}

fn pressButton(modules: *std.StringHashMap(Module)) !bool {
    var pulses = queue.Queue(Pulse).init(modules.allocator);
    var broadcast = modules.get("broadcaster").?;
    var low: u64 = 1;
    var high: u64 = 0;
    for (broadcast.nextStrs) |nextStr| {
        try pulses.enqueue(Pulse{ .from = "broadcaster", .to = nextStr, .val = PulseType.low });
    }

    while (pulses.dequeue()) |pulse| {
        if (pulse.val == .high) {
            high += 1;
        } else {
            low += 1;
        }
        // printPulse(pulse);
        if (std.mem.eql(u8, pulse.to, "rx") and pulse.val == .low) {
            return true;
        }
        const maybeModule = modules.getPtr(pulse.to);
        if (maybeModule == null) {
            continue; // untyped module
        }
        const module = maybeModule.?;

        switch (module.typ) {
            .flipFlop => {
                // if a flip-flop module receives a low pulse, it flips between
                // on and off. If it was off, it turns on and sends a high pulse.
                // If it was on, it turns off and sends a low pulse.
                if (pulse.val == .low) {
                    module.flipFlopOn = !module.flipFlopOn;
                    const sendType = if (module.flipFlopOn) PulseType.high else PulseType.low;
                    for (module.nextStrs) |nextStr| {
                        try pulses.enqueue(Pulse{ .from = module.name, .to = nextStr, .val = sendType });
                    }
                }
            },
            .conjunction => {
                // Conjunction modules (prefix &) remember the type of the most recent pulse
                // received from each of their connected input modules; they initially default
                // to remembering a low pulse for each input. When a pulse is received, the
                // conjunction module first updates its memory for that input. Then, if it
                // remembers high pulses for all inputs, it sends a low pulse; otherwise, it
                // sends a high pulse.
                try module.values.put(pulse.from, pulse.val);
                const allHigh = allHashValuesEql(PulseType, module.values, .high);
                const sendType = if (allHigh) PulseType.low else PulseType.high;
                for (module.nextStrs) |nextStr| {
                    try pulses.enqueue(Pulse{ .from = module.name, .to = nextStr, .val = sendType });
                }
            },
            else => unreachable,
        }
    }
    return false;
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    const filename = args[0];

    const contents = try util.readInputFile(allocator, filename);
    defer allocator.free(contents);

    var modules = std.StringHashMap(Module).init(allocator);
    defer modules.deinit();
    var it = std.mem.tokenize(u8, contents, "\n");
    while (it.next()) |line| {
        var module = try parseModule(allocator, line);
        try modules.put(module.name, module);
    }

    try setNexts(&modules);

    var timer = try std.time.Timer.start();
    var numPresses: u64 = 0;
    while (true) {
        numPresses += 1;
        var sent = try pressButton(&modules);
        if (sent) {
            break;
        }
        if (numPresses % 100_000 == 0) {
            const elapsed = timer.read() / 1_000_000_000;
            std.debug.print("{d} {d}s\n", .{ numPresses, elapsed });
        }
    }
    std.debug.print("part 2: {d}\n", .{numPresses});

    // var sumLow: u64 = 0;
    // var sumHigh: u64 = 0;
    // for (0..1000) |_| {
    //     var sum = try pressButton(&modules);
    //     sumLow += sum.low;
    //     sumHigh += sum.high;
    // }
    // std.debug.print("part 1: {d} = {d} * {d}\n", .{ sumLow * sumHigh, sumLow, sumHigh });

}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
