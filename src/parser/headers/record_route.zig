const std = @import("std");

pub const H = struct {};
pub const key_lower = "record-route";
pub const key = "Record-Route";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Record-Route' header" {
    try t.expect(true);
}
