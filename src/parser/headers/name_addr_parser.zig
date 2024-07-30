const std = @import("std");
const utils = @import("../utils.zig");

// From: "J Rosenberg \\\"" <sip:jdrosen@lucent.com>;tag = 98asjd8
pub fn parse(t: type, str: []const u8, allocator: std.mem.Allocator, opts: *const utils.ParseOptions) !t {
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

    return t{ .addr = addr, .tags = tags, .display_name = display_name };
}
