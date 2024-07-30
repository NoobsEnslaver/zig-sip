const std = @import("std");
const utils = @import("../utils.zig");
const parser = @import("name_addr_parser.zig");

pub const H = struct { display_name: ?[]const u8 = null, addr: []const u8, tags: std.StringHashMap([]const u8) };
pub const key_lower = "from";
pub const key_short = 'f';
pub const key = "From";

pub fn parse(str: []const u8, allocator: std.mem.Allocator, opts: *const utils.ParseOptions) !H {
    return try parser.parse(H, str, allocator, opts);
}

// -------------- Tests --------------------
const t = std.testing;
test "parsing 'From' header" {
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    const a = arena.allocator();
    defer arena.deinit();

    const h1 = try parse("\"J Rosenberg \\\"\" <sip:jdrosen@lucent.com>;tag = 98asjd8", a, &.{});
    try t.expectEqualStrings("J Rosenberg \\\"", h1.display_name.?);
    try t.expectEqualStrings("sip:jdrosen@lucent.com", h1.addr);
    try t.expectEqual(1, h1.tags.count());
    try t.expectEqualStrings("98asjd8", h1.tags.get("tag").?);

    const h2 = try parse("J Rosenberg    <sip:jdrosen@lucent.com;tag=zzz>;tag =98asjd8;q=1;w", a, &.{});
    try t.expectEqualStrings("J Rosenberg", h2.display_name.?);
    try t.expectEqualStrings("sip:jdrosen@lucent.com;tag=zzz", h2.addr);
    try t.expectEqual(3, h2.tags.count());
    try t.expectEqualStrings("98asjd8", h2.tags.get("tag").?);
    try t.expectEqualStrings("1", h2.tags.get("q").?);
    try t.expectEqualStrings("", h2.tags.get("w").?);

    const h3 = try parse("<sips:lucent.com:8090>;tag= 98asjd8", a, &.{});
    try t.expectEqual(null, h3.display_name);
    try t.expectEqualStrings("sips:lucent.com:8090", h3.addr);
    try t.expectEqual(1, h3.tags.count());
    try t.expectEqualStrings("98asjd8", h1.tags.get("tag").?);

    const h4 = try parse("http://lucent.com:8090?qwe&tag=98asjd8;asd=1", a, &.{});
    try t.expectEqual(null, h4.display_name);
    try t.expectEqualStrings("http://lucent.com:8090?qwe&tag=98asjd8;asd=1", h4.addr);
    try t.expectEqual(0, h4.tags.count());
}
