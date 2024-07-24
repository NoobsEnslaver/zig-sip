const std = @import("std");

pub const H = struct {};
pub const key_lower = "contact";
pub const key = "Contact";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Contact' header" {
    try t.expect(true);
}
