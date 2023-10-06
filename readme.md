# zig-ascii-table

Generate ASCII table on the fly with Zig.

## Usage

``` zig
test "render" {
    var app = try init(std.testing.allocator);
    defer app.deinit();

    var rows = try std.ArrayList([]const []const u8).initCapacity(app.allocator, 2);
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
```

## TODO
- [x] Render array of strings.
- [x] UTF support.
- [ ] Render array of structs.
- [ ] Limit table max. width.
- [ ] Headers.
- [ ] Configure width-per-column.
