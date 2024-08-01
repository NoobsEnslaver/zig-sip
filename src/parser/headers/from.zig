const std = @import("std");
const utils = @import("../utils.zig");

pub const H = struct { display_name: ?[]const u8 = null, addr: []const u8, tags: std.StringHashMap([]const u8) };
pub const key_lower = "from";
pub const key_short = 'f';
pub const key = "From";

pub fn parse(str: []const u8, allocator: std.mem.Allocator, opts: *const utils.ParseOptions) !H {
    if (str.len == 0) return error.EmptyString;
    var display_name: ?[]const u8 = null;
    var addr: []const u8 = undefined;
    var raw_tags: ?[]const u8 = null;
    _ = opts; // TODO
    switch (str[0]) {
        '"' => {
            if (utils.indexOfUnquoted(str[1..], '"')) |sndQuoteIdx| {
                display_name = str[1 .. sndQuoteIdx + 1];
                const addr_spec_str = std.mem.trimLeft(u8, str[sndQuoteIdx + 2 ..], &std.ascii.whitespace);
                if (addr_spec_str.len == 0) return error.NoAddr;
                if (addr_spec_str[0] != '<') return error.UnexpectedToken;
                if (std.mem.indexOfScalar(u8, addr_spec_str, '>')) |sndBracketIdx| {
                    addr = addr_spec_str[1..sndBracketIdx];
                    raw_tags = addr_spec_str[sndBracketIdx + 1 ..];
                } else {
                    return error.UnbalancedBrackets;
                }
            } else {
                return error.UnbalancedQuotes;
            }
        },
        '<' => {
            if (utils.indexOfUnquoted(str[1..], '>')) |sndBracketIdx| {
                addr = str[1 .. sndBracketIdx + 1];
                raw_tags = str[sndBracketIdx + 2 ..];
            } else {
                return error.UnbalancedBrackets;
            }
        },
        else => {
            if (std.mem.indexOfScalar(u8, str, '<')) |idx| {
                display_name = std.mem.trim(u8, str[0..idx], &std.ascii.whitespace);
                if (utils.indexOfUnquoted(str[idx + 1 ..], '>')) |sndBracketIdx| {
                    addr = str[idx + 1 .. idx + sndBracketIdx + 1];
                    raw_tags = str[idx + sndBracketIdx + 2 ..];
                } else {
                    return error.UnbalancedBrackets;
                }
            } else {
                addr = str;
            }
        },
    }

    var tags = std.StringHashMap([]const u8).init(allocator);
    if (raw_tags) |s| {
        var it = std.mem.tokenizeScalar(u8, s, ';');
        while (it.next()) |token| {
            if (std.mem.indexOfScalar(u8, token, '=')) |idx| {
                const k = std.mem.trim(u8, token[0..idx], &std.ascii.whitespace);
                const v = std.mem.trim(u8, token[idx + 1 ..], &std.ascii.whitespace);
                try tags.put(k, v);
            } else {
                const k = std.mem.trim(u8, token, &std.ascii.whitespace);
                try tags.put(k, "");
            }
        }
    }

    return H{ .addr = addr, .tags = tags, .display_name = display_name };
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
