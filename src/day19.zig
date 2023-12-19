const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

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
    var parts = util.splitAnyIntoBuf(line, "{}", &partsBuf);
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
        var ruleParts = util.splitAnyIntoBuf(ruleStr, "<>:", &ruleBuf);
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
        std.debug.print("  {s}\n", .{name});
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

pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    var arena = std.heap.ArenaAllocator.init(in_allocator);
    defer arena.deinit();
    var allocator = arena.allocator();
    const filename = args[0];
    var contents = try util.readInputFile(allocator, filename);
    defer allocator.free(contents);

    var partsBuf: [2][]const u8 = undefined;
    var parts = util.splitIntoBuf(contents, "\n\n", &partsBuf);
    assert(parts.len == 2);

    var workflows = std.StringHashMap(Workflow).init(allocator);
    defer workflows.deinit();
    var it = std.mem.tokenize(u8, parts[0], "\n");
    while (it.next()) |line| {
        var workflow = try parseWorkflow(allocator, line);
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
    // std.debug.print("part 2: {d}\n", .{sum2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "sample test" {
    try expectEqualDeep(true, true);
}
