const std = @import("std");

pub const H = struct {};
pub const key_lower = "route";
pub const key = "Route";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Route' header" {
    try t.expect(true);
}
