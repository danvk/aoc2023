const std = @import("std");

// Half-open interval
pub fn Interval(comptime IntType: type) type {
    return struct {
        low: IntType,
        high: IntType,

        pub fn intersects(self: @This(), other: @This()) bool {
            return !(self.low >= other.high or self.high <= other.low);
        }

        pub fn intersection(self: @This(), other: @This()) ?@This() {
            var low = @max(self.low, other.low);
            var high = @min(self.high, other.high);
            return if (low < high) @This(){ .low = low, .high = high } else null;
        }

        pub fn includes(self: @This(), val: IntType) bool {
            return val >= self.low and val < self.high;
        }

        // Does self fully contain other?
        pub fn contains(self: @This(), other: @This()) bool {
            return (self.low <= other.low and self.high >= other.high);
        }

        const Self = @This();

        // Split self into intersecting and non-intersecting bits according to other
        pub fn split(self: Self, other: Self) struct { int: ?Self, pre: ?Self, post: ?Self } {
            // does not intersect
            if (self.high <= other.low) {
                return .{ .pre = self, .int = null, .post = null };
            } else if (self.low >= other.high) {
                return .{ .pre = null, .int = null, .post = self };
            }
            // complete containment
            if (other.contains(self)) {
                return .{ .int = self, .pre = null, .post = null };
            } else if (self.contains(other)) {
                return .{
                    .int = other,
                    .pre = if (self.low == other.low) null else Self{ .low = self.low, .high = other.low },
                    .post = if (other.high == self.high) null else Self{ .low = other.high, .high = self.high },
                };
            }
            // overlap
            if (self.low < other.low) {
                assert(other.low > self.low);
                return .{
                    .int = self.intersection(other),
                    .pre = Self{ .low = self.low, .high = other.low },
                    .post = null,
                };
            } else if (self.low > other.low) {
                assert(other.high < self.high);
                return .{
                    .int = self.intersection(other),
                    .pre = null,
                    .post = Self{ .low = other.high, .high = self.high },
                };
            }
            unreachable;
        }

        pub fn len(self: @This()) IntType {
            return self.high - self.low;
        }
    };
}

const assert = std.debug.assert;
const expectEqual = std.testing.expectEqual;
const expectDeepEqual = std.testing.expectEqualDeep;

const Iv32 = Interval(u32);

test "interval intersects" {
    const a = Iv32{ .low = 10, .high = 20 };
    const b = Iv32{ .low = 15, .high = 25 };
    const c = Iv32{ .low = 20, .high = 30 };
    assert(a.intersects(b));
    assert(!a.intersects(c));
    assert(b.intersects(c));
    assert(!c.intersects(a));
    assert(b.intersects(a));
    assert(a.intersects(a));
}

test "interval intersection" {
    const a = Iv32{ .low = 10, .high = 20 };
    const b = Iv32{ .low = 15, .high = 25 };
    const c = Iv32{ .low = 20, .high = 30 };

    try expectDeepEqual(a.intersection(b), Iv32{ .low = 15, .high = 20 });
    try expectDeepEqual(b.intersection(a), Iv32{ .low = 15, .high = 20 });
    try expectDeepEqual(a.intersection(c), null);
}

test "interval contains and length" {
    const a = Iv32{ .low = 10, .high = 20 };
    assert(a.includes(10));
    assert(a.includes(15));
    assert(!a.includes(20));
    assert(!a.includes(0));
    try expectEqual(a.len(), 10);
}

test "interval three-way split" {
    const a = Iv32{ .low = 10, .high = 20 };
    const b = Iv32{ .low = 15, .high = 25 };

    try expectDeepEqual(a.split(b), .{ .int = Iv32{ .low = 15, .high = 20 }, .pre = Iv32{ .low = 10, .high = 15 }, .post = null });
    try expectDeepEqual(b.split(a), .{ .int = Iv32{ .low = 15, .high = 20 }, .post = Iv32{ .low = 20, .high = 25 }, .pre = null });

    const big = Iv32{ .low = 5, .high = 25 };
    try expectDeepEqual(b.split(big), .{ .int = b, .pre = null, .post = null });
    try expectDeepEqual(a.split(big), .{ .int = a, .pre = null, .post = null });
    try expectDeepEqual(big.split(a), .{ .int = a, .pre = Iv32{ .low = 5, .high = 10 }, .post = Iv32{ .low = 20, .high = 25 } });
    try expectDeepEqual(big.split(b), .{ .int = b, .pre = Iv32{ .low = 5, .high = 15 }, .post = null });

    const c = Iv32{ .low = 20, .high = 30 };
    try expectDeepEqual(a.split(c), .{ .int = null, .pre = a, .post = null });
    try expectDeepEqual(c.split(a), .{ .int = null, .pre = null, .post = c });
}
