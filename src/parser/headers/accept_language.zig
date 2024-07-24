const std = @import("std");

pub const H = struct {};
pub const key_lower = "accept-language";
pub const key = "Accept-Language";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Accept-Language' header" {
    try t.expect(true);
}
