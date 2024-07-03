const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");
const interval = @import("./interval.zig");

const assert = std.debug.assert;

// alternative with arena allocator:

const Rel = enum { @"<", @">" };
const Rule = struct {
    part: u8,
    rel: Rel,
    num: u32,
    workflow: []const u8,
};
const Workflow = struct {
    name: []const u8,
    rules: []Rule,
    fallback: []const u8,
};

fn parseWorkflow(allocator: std.mem.Allocator, line: []const u8) !Workflow {
    var partsBuf: [2][]const u8 = undefined;
    const parts = util.splitAnyIntoBuf(line, "{}", &partsBuf);
    assert(parts.len == 2);

    const name = parts[0];
    var rules = std.ArrayList(Rule).init(allocator);
    var it = std.mem.tokenizeScalar(u8, parts[1], ',');
    var fallback: ?[]const u8 = null;
    while (it.next()) |ruleStr| {
        if (ruleStr.len < 2 or (ruleStr[1] != '<' and ruleStr[1] != '>')) {
            std.debug.print("fallback: {s}\n", .{ruleStr});
            assert(fallback == null);
            fallback = ruleStr;
            continue;
        }
        var ruleBuf: [3][]const u8 = undefined;
        const ruleParts = util.splitAnyIntoBuf(ruleStr, "<>:", &ruleBuf);
        assert(ruleParts.len == 3);
        const part = ruleParts[0];
        assert(part.len == 1);
        const rel = std.meta.stringToEnum(Rel, ruleStr[1..2]).?;
        const num = try std.fmt.parseInt(u32, ruleParts[1], 10);
        const workflow = ruleParts[2];
        try rules.append(Rule{
            .num = num,
            .part = part[0],
            .rel = rel,
            .workflow = workflow,
        });
    }
    return Workflow{
        .name = name,
        .rules = rules.items,
        .fallback = fallback.?,
    };
}

// {x=787,m=2655,a=1222,s=2876}
fn parseCounts(line: []const u8, counts: []u32) !void {
    var it = std.mem.tokenizeAny(u8, line, "{},");
    while (it.next()) |part| {
        assert(part[1] == '=');
        const num = try std.fmt.parseInt(u32, part[2..], 10);
        const p = part[0];
        assert(counts[p] == 0);
        counts[p] = num;
    }
}

fn matchesRule(rule: Rule, counts: []u32) bool {
    const pn = counts[rule.part];
    return switch (rule.rel) {
        .@"<" => pn < rule.num,
        .@">" => pn > rule.num,
    };
}

fn applyWorkflow(wf: Workflow, counts: []u32) []const u8 {
    for (wf.rules) |rule| {
        if (matchesRule(rule, counts)) {
            return rule.workflow;
        }
    }
    return wf.fallback;
}

fn accepts(workflows: std.StringHashMap(Workflow), counts: []u32) bool {
    var name: []const u8 = "in";

    while (true) {
        // std.debug.print("  {s}\n", .{name});
        const wf = workflows.get(name).?;
        const next = applyWorkflow(wf, counts);
        if (std.mem.eql(u8, next, "A")) {
            return true;
        } else if (std.mem.eql(u8, next, "R")) {
            return false;
        }
        name = next;
    }
    unreachable;
}

fn dropLast(comptime T: type, slice: []T) []T {
    assert(slice.len > 0);
    return slice[0 .. slice.len - 1];
}

fn xmasToRange(c: u8) u2 {
    return switch (c) {
        'x' => 0,
        'm' => 1,
        'a' => 2,
        's' => 3,
        else => unreachable,
    };
}

const Range = interval.Interval(u32);
const XmasRange = [4]Range;

const WorkflowRange = struct {
    name: []const u8,
    range: XmasRange,
};

fn xmasRangeVolume(r: XmasRange) u64 {
    return @as(u64, r[0].len()) * r[1].len() * r[2].len() * r[3].len();
}

fn rangeForRule(rule: Rule) struct { pass: Range, fail: Range } {
    if (rule.rel == .@"<") {
        return .{
            .pass = Range{ .low = 1, .high = rule.num },
            .fail = Range{ .low = rule.num, .high = 4001 },
        };
    }
    return .{
        .pass = Range{ .low = rule.num + 1, .high = 4001 },
        .fail = Range{ .low = 1, .high = rule.num + 1 },
    };
}

fn isReject(c: []const u8) bool {
    return c.len == 1 and c[0] == 'R';
}

fn isAccept(c: []const u8) bool {
    return c.len == 1 and c[0] == 'A';
}

const XMAS = [_]u8{ 'x', 'm', 'a', 's' };

fn printWFRange(wfr: WorkflowRange) void {
    std.debug.print("  {s}:", .{wfr.name});
    const r = wfr.range;
    for (XMAS[0..], 0..) |c, i| {
        std.debug.print(" {c}=[{d},{d})", .{ c, r[i].low, r[i].high });
    }
    std.debug.print("\n", .{});
}

// pass the range through the workflow.
fn throughWorkflow(range: XmasRange, wf: Workflow, out: *std.ArrayList(WorkflowRange)) !u64 {
    var remaining = range;
    var volume: u64 = 0;
    for (wf.rules) |rule| {
        // Part matches this rule, part does not.
        const ruleRs = rangeForRule(rule);
        const i = xmasToRange(rule.part);
        const curR = remaining[i];
        if (ruleRs.pass.intersection(curR)) |matchR| {
            var matchXR = remaining;
            matchXR[i] = matchR;
            if (isAccept(rule.workflow)) {
                volume += xmasRangeVolume(matchXR);
            } else if (!isReject(rule.workflow)) {
                if (xmasRangeVolume(matchXR) > 0) {
                    try out.append(WorkflowRange{
                        .name = rule.workflow,
                        .range = matchXR,
                    });
                }
            }
        }
        if (ruleRs.fail.intersection(curR)) |matchR| {
            remaining[i] = matchR;
        } else {
            return volume;
        }

        if (xmasRangeVolume(remaining) == 0) {
            return volume;
        }
    }

    if (isAccept(wf.fallback)) {
        volume += xmasRangeVolume(remaining);
        return volume;
    } else if (isReject(wf.fallback)) {
        return volume;
    }
    try out.append(WorkflowRange{
        .name = wf.fallback,
        .range = remaining,
    });
    return volume;
}

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    const filename = args[0];
    const contents = try util.readInputFile(allocator, filename);
    defer allocator.free(contents);

    var partsBuf: [2][]const u8 = undefined;
    const parts = util.splitIntoBuf(contents, "\n\n", &partsBuf);
    assert(parts.len == 2);

    var workflows = std.StringHashMap(Workflow).init(allocator);
    defer workflows.deinit();
    var it = std.mem.tokenize(u8, parts[0], "\n");
    while (it.next()) |line| {
        const workflow = try parseWorkflow(allocator, line);
        std.debug.print("{s} -> {any}\n", .{ workflow.name, workflow });
        try workflows.put(workflow.name, workflow);
    }

    it = std.mem.tokenize(u8, parts[1], "\n");
    var sum1: u32 = 0;
    while (it.next()) |line| {
        var counts = [_]u32{0} ** 256;
        try parseCounts(line, &counts);
        if (accepts(workflows, &counts)) {
            for (counts[0..]) |c| {
                sum1 += c;
            }
        }
    }
    std.debug.print("part 1: {d}\n", .{sum1});

    // XXX this was surprisingly hard! Discovered hash.getPtr.
    var seenNums = std.AutoHashMap(u8, std.AutoHashMap(u32, void)).init(allocator);
    defer seenNums.deinit();
    var wfit = workflows.valueIterator();
    while (wfit.next()) |wf| {
        for (wf.rules) |rule| {
            if (!seenNums.contains(rule.part)) {
                try seenNums.put(rule.part, std.AutoHashMap(u32, void).init(allocator));
                // std.debug.print("creating {c}\n", .{rule.part});
            }
            var h = seenNums.getPtr(rule.part).?;
            // std.debug.print("put {c} {d}\n", .{ rule.part, rule.num });
            const n: u32 = if (rule.rel == .@"<") rule.num else rule.num + 1;
            try h.put(n, undefined);
            // std.debug.print("  {d}\n", .{h.count()});
            // std.debug.print("  {d}\n", .{seenNums.get(rule.part).?.count()});
        }
    }
    std.debug.print("{any}\n", .{seenNums});
    // sample: nums seen: 14
    // input: nums seen: 891 -> 630B, still too much.
    std.debug.print("nums seen: {d}, {d}, {d}, {d}\n", .{ seenNums.get('x').?.count(), seenNums.get('m').?.count(), seenNums.get('a').?.count(), seenNums.get('s').?.count() });

    const keys = [_]u8{ 'x', 'm', 'a', 's' };
    var nums: [4]std.ArrayList(u32) = undefined;
    for (keys, 0..) |key, i| {
        var vit = seenNums.get(key).?.keyIterator();
        nums[i] = std.ArrayList(u32).init(allocator);
        try nums[i].append(1);
        while (vit.next()) |v| {
            try nums[i].append(v.*);
        }
        try nums[i].append(4001);
        std.mem.sort(u32, nums[i].items, {}, std.sort.asc(u32));
        std.debug.print("{c}: {any}\n", .{ key, nums[i].items });
    }

    var sum2: u64 = 0;
    // var counts = [_]u32{0} ** 256;
    // var timer = try std.time.Timer.start();
    // for (dropLast(u32, nums[0].items), 0..) |x, xi| {
    //     const elapsed = timer.read() / 1_000_000_000;
    //     std.debug.print(" -> x={d}, {d}/{d} {d}s\n", .{ x, xi, nums[0].items.len, elapsed });
    //
    //     counts['x'] = x;
    //     const numX: u64 = nums[0].items[xi + 1] - x;
    //     for (dropLast(u32, nums[1].items), 0..) |m, mi| {
    //         counts['m'] = m;
    //         const numM: u64 = nums[1].items[mi + 1] - m;
    //         for (dropLast(u32, nums[2].items), 0..) |a, ai| {
    //             counts['a'] = a;
    //             const numA: u64 = nums[2].items[ai + 1] - a;
    //             for (dropLast(u32, nums[3].items), 0..) |s, si| {
    //                 counts['s'] = s;
    //                 const numS: u64 = nums[3].items[si + 1] - s;
    //                 if (accepts(workflows, &counts)) {
    //                     sum2 += numX * numM * numA * numS;
    //                 }
    //             }
    //         }
    //     }
    // }

    const fullRange = Range{ .low = 1, .high = 4001 };
    const initRange = XmasRange{ fullRange, fullRange, fullRange, fullRange };
    var cubes = std.ArrayList(WorkflowRange).init(allocator);
    try cubes.append(WorkflowRange{ .name = "in", .range = initRange });
    std.debug.print("{d} cubes, volume={d}\n", .{ cubes.items.len, xmasRangeVolume(cubes.items[0].range) });
    while (cubes.items.len > 0) {
        var nexts = std.ArrayList(WorkflowRange).init(allocator);

        for (cubes.items) |cube| {
            std.debug.print("cube.name={s}\n", .{cube.name});
            const wf = workflows.get(cube.name).?;
            sum2 += try throughWorkflow(cube.range, wf, &nexts);
        }

        var volumeRemaining: u64 = 0;
        for (nexts.items) |next| {
            // std.debug.print("  {any}\n", .{next});
            printWFRange(next);
            volumeRemaining += xmasRangeVolume(next.range);
        }
        std.debug.print("{d} cubes, volume={d}\n", .{ cubes.items.len, volumeRemaining });

        cubes.deinit();
        cubes = nexts;
    }
    cubes.deinit();

    std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
