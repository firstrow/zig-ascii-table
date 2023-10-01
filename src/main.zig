const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

pub const AsciiWriter = struct {
    allocator: Allocator,

    pub fn render(self: *AsciiWriter, data: [][]const []const u8) ![]const u8 {
        // find max_width per_column
        var widths = try self.make_columns_widths(data);
        defer widths.deinit();

        for (data) |row| {
            for (row) |col| {
                std.debug.print("{s} |", .{col});
            }
            std.debug.print("\n", .{});
        }
        return "ok";
    }

    /// find max width per column
    /// TODO: use fixed width array
    fn make_columns_widths(self: *AsciiWriter, data: [][]const []const u8) !std.AutoHashMap(usize, usize) {
        var cols_widths = std.AutoHashMap(usize, usize).init(self.allocator);

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

        return cols_widths;
    }

    pub fn right_pad(self: *AsciiWriter, str: []const u8, width: usize) ![]u8 {
        if (str.len >= width) {
            return self.allocator.dupe(u8, str);
        }

        const buf = try self.allocator.alloc(u8, width);
        std.mem.copy(u8, buf, str);

        var i: usize = width;
        while (i > str.len) : (i -= 1) {
            buf[i - 1] = '_';
        }

        return buf;
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

test "right pad" {
    var app = try init(std.testing.allocator);
    defer app.deinit();

    var msg = "hello";
    var r = try app.right_pad(msg, 8);
    try testing.expectEqualStrings("hello___", r);
    app.allocator.free(r);

    msg = "hello";
    r = try app.right_pad(msg, 4);
    try testing.expectEqualStrings("hello", r);
    app.allocator.free(r);
}
