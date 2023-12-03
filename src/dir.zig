pub const Dir = enum(u2) {
    right,
    up,
    left,
    down,
    pub fn ccw(self: Dir) Dir {
        const n: u32 = @intFromEnum(self);
        return @as(Dir, @enumFromInt((n + 1) % 4));
    }
    pub fn cw(self: Dir) Dir {
        const n: u32 = @intFromEnum(self);
        return @as(Dir, @enumFromInt((n + 3) % 4));
    }
    pub fn dx(this: Dir) i32 {
        return switch (this) {
            Dir.left => -1,
            Dir.right => 1,
            Dir.up => 0,
            Dir.down => 0,
        };
    }
    pub fn dy(this: Dir) i32 {
        return switch (this) {
            Dir.left => 0,
            Dir.right => 0,
            Dir.up => -1,
            Dir.down => 1,
        };
    }
};

pub const DIRS = [_]Dir{ .right, .up, .left, .down };

pub const Coord = struct {
    x: i32,
    y: i32,

    pub fn move(self: @This(), dir: Dir) Coord {
        return Coord{
            .x = self.x + dir.dx(),
            .y = self.y + dir.dy(),
        };
    }

    pub fn move8(self: @This(), dir: Dir8) Coord {
        return Coord{
            .x = self.x + dir.dx(),
            .y = self.y + dir.dy(),
        };
    }
};

pub const Dir8 = enum(u3) {
    nw,
    n,
    ne,
    w,
    e,
    sw,
    s,
    se,
    pub fn dx(this: @This()) i32 {
        return switch (this) {
            .nw => -1,
            .w => -1,
            .sw => -1,
            .n => 0,
            .s => 0,
            .ne => 1,
            .e => 1,
            .se => 1,
        };
    }
    pub fn dy(this: @This()) i32 {
        return switch (this) {
            .nw => -1,
            .n => -1,
            .ne => -1,
            .w => 0,
            .e => 0,
            .sw => 1,
            .s => 1,
            .se => 1,
        };
    }
};

pub const DIR8S = [_]Dir8{ .nw, .n, .ne, .w, .e, .sw, .s, .se };
