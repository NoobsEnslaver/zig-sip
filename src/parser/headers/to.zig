const std = @import("std");
const parser = @import("name_addr_parser.zig");

pub const H = struct { display_name: ?[]const u8 = null, addr: []const u8, tags: std.StringHashMap([]const u8) };
pub const key_lower = "to";
pub const key_short = 't';
pub const key = "To";

pub fn parse(str: []const u8, allocator: std.mem.Allocator, opts: anytype) !H {
    return try parser.parse(H, str, allocator, opts);
}
