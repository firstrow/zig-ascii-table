const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;

pub const AsciiWriter = struct {
    allocator: Allocator,

    pub fn render(self: *AsciiWriter, data: [][]const []const u8) ![]const u8 {
        var widths = try self.make_columns_widths(data);
        defer widths.map.deinit();

        var buf = std.ArrayList(u8).init(self.allocator);
        var w = buf.writer();

        const table_width = widths.total_width + (3 * data[0].len) + 1;
        const sep_line = try self.str_repeat('-', table_width);
        for (data) |row| {
            var pos: usize = 0;
            try w.print("{s}\n", .{sep_line});
            for (row, 0..) |col, i| {
                var col_max_width = widths.map.get(i) orelse col.len;
                var v = try self.right_pad(col, col_max_width);

                var sep = if (i == 0) "| " else " | ";

                pos += col_max_width + sep.len;
                if (pos < sep_line.len) {
                    sep_line[pos + 1] = '+';
                }

                try w.print("{s}", .{sep});
                try w.print("{s}", .{v});

                self.allocator.free(v);
            }
            try w.print(" |\n", .{});
        }
        try w.print("{s}\n", .{sep_line});
        self.allocator.free(sep_line);

        return buf.toOwnedSlice();
    }

    /// TODO: use fixed width array
    fn make_columns_widths(self: *AsciiWriter, data: [][]const []const u8) !struct { total_width: usize, map: std.AutoHashMap(usize, usize) } {
        var cols_widths = std.AutoHashMap(usize, usize).init(self.allocator);
        var total_width: usize = 0;

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

        var it = cols_widths.iterator();
        while (it.next()) |kv| {
            total_width += kv.value_ptr.*;
        }

        return .{
            .total_width = total_width,
            .map = cols_widths,
        };
    }

    fn right_pad(self: *AsciiWriter, str: []const u8, width: usize) ![]u8 {
        if (str.len >= width) {
            return self.allocator.dupe(u8, str);
        }

        const buf = try self.allocator.alloc(u8, width);
        std.mem.copy(u8, buf, str);

        var i: usize = width;
        while (i > str.len) : (i -= 1) {
            buf[i - 1] = ' ';
        }

        return buf;
    }

    fn str_repeat(self: *AsciiWriter, char: u8, len: usize) ![]u8 {
        var str = try self.allocator.alloc(u8, len);
        var i: usize = 0;
        while (i <= len - 1) : (i += 1) {
            str[i] = char;
        }

        str[0] = '+';
        str[len - 1] = '+';

        return str;
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

///////////////////////////////////////////////////////////////////////////

test "render" {
    var app = try init(std.testing.allocator);
    defer app.deinit();

    var rows = std.ArrayList([]const []const u8).init(app.allocator);
    defer rows.deinit();

    try rows.append(&[_][]const u8{ "Hello", "World" });
    try rows.append(&[_][]const u8{ "Hello", "Zig" });

    const result = try app.render(rows.items);
    defer app.allocator.free(result);

    const expected =
        \\+-------+-------+
        \\| Hello | World |
        \\+-------+-------+
        \\| Hello | Zig   |
        \\+-------+-------+
        \\
    ;

    try testing.expectEqualStrings(expected, result);
}

test "right pad" {
    var app = try init(std.testing.allocator);
    defer app.deinit();

    var msg = "hello";
    var r = try app.right_pad(msg, 8);
    try testing.expectEqualStrings("hello   ", r);
    app.allocator.free(r);

    msg = "hello";
    r = try app.right_pad(msg, 4);
    try testing.expectEqualStrings("hello", r);
    app.allocator.free(r);
}

test "str_repeat" {
    var app = try init(std.testing.allocator);
    defer app.deinit();

    var r = try app.str_repeat('-', 5);
    defer app.allocator.free(r);

    try testing.expectEqualStrings("+---+", r);
}
