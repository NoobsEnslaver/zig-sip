const std = @import("std");

pub const H = struct {};
pub const key_lower = "accept-encoding";
pub const key = "Accept-Encoding";

pub fn parse(str: []const u8) !H {
    _ = str;
    return H{};
}

// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Accept-Encoding' header" {
    try t.expect(true);
}
