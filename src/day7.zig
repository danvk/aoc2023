const std = @import("std");
const bufIter = @import("./buf-iter.zig");
const util = @import("./util.zig");

const assert = std.debug.assert;

// alternative with arena allocator:
// pub fn main(in_allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
//     var arena = std.heap.ArenaAllocator.init(in_allocator);
//     defer arena.deinit();
//     var allocator = arena.allocator();

const Hand = [5]u8;

const HandType = enum(u8) {
    FIVE = 7,
    FOUR = 6,
    FULL = 5,
    THREE = 4,
    TWO_PAIR = 3,
    PAIR = 2,
    HIGH = 1,
};

fn cardNum(card: u8) u8 {
    return if (card == 'A') 14 else if (card == 'K') 13 else if (card == 'Q') 12 else if (card == 'J') 11 else if (card == 'T') 10 else if (card >= '1' and card <= '9') card - '0' else unreachable;
}

fn cardNum2(card: u8) u8 {
    return if (card == 'A') 14 else if (card == 'K') 13 else if (card == 'Q') 12 else if (card == 'J') 0 else if (card == 'T') 10 else if (card >= '1' and card <= '9') card - '0' else unreachable;
}

fn evaluateHand(hand: Hand) HandType {
    var counts: [15]u8 = undefined;
    @memset(&counts, 0);
    for (hand) |card| {
        counts[cardNum(card)] += 1;
    }
    std.mem.sort(u8, &counts, {}, comptime std.sort.desc(u8));

    return switch (counts[0]) {
        5 => .FIVE,
        4 => .FOUR,
        3 => if (counts[1] == 2) .FULL else .THREE,
        2 => if (counts[1] == 2) .TWO_PAIR else .PAIR,
        1 => .HIGH,
        else => unreachable,
    };
}

fn evaluateHand2(hand: Hand) HandType {
    var counts: [15]u8 = undefined;
    @memset(&counts, 0);
    var numJokers: u8 = 0;
    for (hand) |card| {
        if (card == 'J') {
            numJokers += 1;
        } else {
            counts[cardNum(card)] += 1;
        }
    }
    std.mem.sort(u8, &counts, {}, comptime std.sort.desc(u8));
    counts[0] += numJokers;

    return switch (counts[0]) {
        5 => .FIVE,
        4 => .FOUR,
        3 => if (counts[1] == 2) .FULL else .THREE,
        2 => if (counts[1] == 2) .TWO_PAIR else .PAIR,
        1 => .HIGH,
        else => unreachable,
    };
}

fn handLessThan(a: Hand, b: Hand) bool {
    const typeA = @intFromEnum(evaluateHand2(a));
    const typeB = @intFromEnum(evaluateHand2(b));
    if (typeA < typeB) {
        return true;
    } else if (typeA > typeB) {
        return false;
    }
    for (a, b) |charA, charB| {
        const cardA = cardNum2(charA);
        const cardB = cardNum2(charB);
        if (cardA < cardB) {
            return true;
        } else if (cardA > cardB) {
            return false;
        }
    }
    return false;
}

const HandBid = struct {
    hand: Hand,
    bid: u32,
};

fn handBidLessThan(ctx: void, a: HandBid, b: HandBid) bool {
    _ = ctx;
    return handLessThan(a.hand, b.hand);
}

pub fn main(allocator: std.mem.Allocator, args: []const [:0]u8) anyerror!void {
    const filename = args[0];

    var hands = std.ArrayList(HandBid).init(allocator);
    defer hands.deinit();

    var iter = try bufIter.iterLines(filename);
    while (try iter.next()) |line| {
        var parts = util.splitOne(line, " ").?;
        var hand: Hand = undefined;
        @memcpy(&hand, parts.head);
        const bid = try std.fmt.parseInt(u32, parts.rest, 10);

        try hands.append(HandBid{ .hand = hand, .bid = bid });
    }

    std.mem.sort(HandBid, hands.items, {}, handBidLessThan);
    var part2: u64 = 0;
    for (hands.items, 1..) |hand, rank| {
        std.debug.print("{d} {s} {d}\n", .{ rank, hand.hand, hand.bid });
        part2 += rank * hand.bid;
    }

    // std.debug.print("part 1: {d}\n", .{part1});
    std.debug.print("part 2: {d}\n", .{part2});
}

const expectEqualDeep = std.testing.expectEqualDeep;
const expectEqual = std.testing.expectEqual;
const expect = std.testing.expect;

test "hand rank" {
    try expectEqual(evaluateHand([_]u8{ '3', '2', 'T', '3', 'K' }), .PAIR);
    try expectEqual(evaluateHand([_]u8{ 'K', 'K', '6', '7', '7' }), .TWO_PAIR);
    try expectEqual(evaluateHand([_]u8{ 'K', 'T', 'J', 'J', 'T' }), .TWO_PAIR);
    try expectEqual(evaluateHand([_]u8{ 'Q', 'Q', 'Q', 'J', 'A' }), .THREE);
    try expectEqual(evaluateHand([_]u8{ 'T', '5', '5', 'J', '5' }), .THREE);
}

test "ordering" {
    var a = [_]u8{ 'K', 'K', '6', '7', '7' };
    var b = [_]u8{ 'K', 'T', 'J', 'J', 'T' };
    try expect(handLessThan(b, a));
    try expect(!handLessThan(a, b));
}
