const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

pub const AsciiWriter = struct {
    allocator: Allocator,

    pub fn one(self: *AsciiWriter) u8 {
        _ = self;
        return 1;
    }

    pub fn render(self: *AsciiWriter, data: [][]const []const u8) ![]const u8 {
        // find max_width per_column
        var cols_widths = std.AutoHashMap(usize, usize).init(self.allocator);
        defer cols_widths.deinit();

        for (data) |row| {
            for (row, 0..) |col, i| {
                var max_width = try cols_widths.getOrPut(i);
                if (!max_width.found_existing) {
                    max_width.value_ptr.* = 0;
                }
                if (col.len > max_width.value_ptr.*) {
                    max_width.value_ptr.* = col.len;
                }
            }
        }

        for (data) |row| {
            std.debug.print("------------------\n", .{});
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
    v = [_][]const u8{ "Hello", "Worldddddddd" };
    try rows.append(&v);

    const result = try app.render(rows.items);
    try testing.expectEqualStrings(result, "ok");
}
