const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

const String = []const u8;

pub const AsciiWriter = struct {
    allocator: Allocator,

    pub fn one(self: *AsciiWriter) u8 {
        _ = self;
        return 1;
    }

    pub fn render(self: *AsciiWriter, data: [][]const []const u8) []const u8 {
        _ = self;
        for (data) |row| {
            for (row) |col| {
                std.debug.print("{s}\n", .{col});
            }
        }
        return "ok";
    }

    pub fn deinit(self: *AsciiWriter) void {
        self.allocator.destroy(self);
    }
};

pub fn init(allocator: Allocator) !*AsciiWriter {
    var self = try allocator.create(AsciiWriter);
    self.* = AsciiWriter{
        .allocator = allocator,
    };
    return self;
}

test "init works" {
    var app = try init(std.testing.allocator);
    defer app.deinit();
    try testing.expect(app.one() == 1);
}

test "render" {
    var app = try init(std.testing.allocator);
    defer app.deinit();

    var rows = std.ArrayList([]const []const u8).init(app.allocator);
    defer rows.deinit();

    var v = [_][]const u8{ "Hello", "World" };
    try rows.append(&v);
    v = [_][]const u8{ "Hello", "World2" };
    try rows.append(&v);

    try testing.expectEqualStrings(app.render(rows.items), "ok");
}
