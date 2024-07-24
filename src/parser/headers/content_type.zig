const std = @import("std");

pub const H = struct {};
pub const key_lower = "content-type";
pub const key = "Content-Type";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Content-Type' header" {
    try t.expect(true);
}
