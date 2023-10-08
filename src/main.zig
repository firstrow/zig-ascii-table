const std = @import("std");
const Allocator = std.mem.Allocator;
const testing = std.testing;
const utflen = std.unicode.calcUtf16LeLen;

pub const AsciiWriter = struct {
    allocator: Allocator,
    arena: Allocator,

    pub fn render(self: *AsciiWriter, data: [][]const []const u8) ![]const u8 {
        var arena = std.heap.ArenaAllocator.init(self.allocator);
        defer arena.deinit();
        self.arena = arena.allocator();

        var widths = try self.make_columns_widths(data);
        var result = std.ArrayList(u8).init(self.allocator);
        var w = result.writer();

        const table_width = widths.total_width + (3 * data[0].len) + 1;
        const sep_line = try self.str_repeat('-', table_width);

        // pre-render sep-line
        var pos: usize = 0;
        for (data[0][0..1], 0..) |_, i| {
            var sep_len: u8 = 0;
            if (i == 0) sep_len = 2 else sep_len = 3;
            pos += widths.map[i] + sep_len;
            if (pos < sep_line.len) {
                sep_line[pos + 1] = '+';
            }
        }

        for (data) |row| {
            try w.print("{s}\n", .{sep_line});
            for (row, 0..) |col, i| {
                var v = try self.right_pad(col, widths.map[i]);
                var sep = if (i == 0) "| " else " | ";
                try w.print("{s}", .{sep});
                try w.print("{s}", .{v});
            }
            try w.print(" |\n", .{});
        }
        try w.print("{s}\n", .{sep_line});

        return result.toOwnedSlice();
    }

    /// TODO: use fixed width array
    fn make_columns_widths(self: *AsciiWriter, data: [][]const []const u8) !struct { total_width: usize, map: []usize } {
        var cols_widths = try self.arena.alloc(usize, data[0].len);
        @memset(cols_widths, 0);
        var total_width: usize = 0;

        for (data) |row| {
            for (row, 0..) |col, i| {
                var len = try utflen(col);
                if (len > cols_widths[i]) {
                    cols_widths[i] = len;
                }
            }
        }

        var i: usize = 0;
        while (i <= data[0].len - 1) : (i += 1) {
            total_width += cols_widths[i];
        }

        return .{
            .total_width = total_width,
            .map = cols_widths,
        };
    }

    fn right_pad(self: *AsciiWriter, str: []const u8, width: usize) ![]u8 {
        const numChars = try utflen(str);

        if (numChars >= width) {
            return self.arena.dupe(u8, str);
        }

        var remainder: i32 = @intCast(width - numChars);

        const buf = try self.arena.alloc(u8, str.len + @as(usize, @intCast(remainder)));
        std.mem.copy(u8, buf, str);

        var i: usize = 0;
        while (i < remainder) : (i += 1) {
            buf[str.len + i] = ' ';
        }

        return buf;
    }

    fn str_repeat(self: *AsciiWriter, char: u8, len: usize) ![]u8 {
        var str = try self.arena.alloc(u8, len);
        var i: usize = 0;
        while (i <= len - 1) : (i += 1) {
            str[i] = char;
        }

        str[0] = '+';
        str[len - 1] = '+';

        return str;
    }
};

pub fn init(allocator: Allocator) AsciiWriter {
    return .{
        .allocator = allocator,
        .arena = undefined,
    };
}

///////////////////////////////////////////////////////////////////////////

test "render" {
    var app = init(std.testing.allocator);

    var rows = try std.ArrayList([]const []const u8).initCapacity(std.testing.allocator, 4);
    defer rows.deinit();
    try rows.append(&[_][]const u8{ "Hello", "World" });
    try rows.append(&[_][]const u8{ "Привіт", "Світ" });
    try rows.append(&[_][]const u8{ "Hello", "Zig" });
    try rows.append(&[_][]const u8{ "Hello", "äåóö" });

    const result = try app.render(rows.items);
    defer app.allocator.free(result);

    const expected =
        \\+--------+-------+
        \\| Hello  | World |
        \\+--------+-------+
        \\| Привіт | Світ  |
        \\+--------+-------+
        \\| Hello  | Zig   |
        \\+--------+-------+
        \\| Hello  | äåóö  |
        \\+--------+-------+
        \\
    ;

    try testing.expectEqualStrings(expected, result);
}

// test "right pad" {
//     var app = try init(std.testing.allocator);
//     defer app.deinit();

//     var msg = "hello";
//     var r = try app.right_pad(msg, 8);
//     try testing.expectEqualStrings("hello   ", r);
//     app.allocator.free(r);

//     msg = "hello";
//     r = try app.right_pad(msg, 4);
//     try testing.expectEqualStrings("hello", r);
//     app.allocator.free(r);
// }

// test "str_repeat" {
//     var app = try init(std.testing.allocator);
//     defer app.deinit();

//     var r = try app.str_repeat('-', 5);
//     defer app.allocator.free(r);

//     try testing.expectEqualStrings("+---+", r);
// }
