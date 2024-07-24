const std = @import("std");

pub const H = struct {};
pub const key_lower = "from";
pub const key = "From";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'From' header" {
    try t.expect(true);
}
