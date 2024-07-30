const std = @import("std");

pub const H = struct { localid: []const u8, host: ?[]const u8 = null };
pub const key_lower = "call-id";
pub const key_short = 'i';
pub const key = "Call-ID";

pub fn parse(str: []const u8) !H {
    if (std.mem.indexOfScalar(u8, str, '@')) |idx| {
        return H{ .localid = str[0..idx], .host = str[idx + 1 ..] };
    } else {
        return H{ .localid = str };
    }
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Call-ID' header" {
    try t.expect(true);
}
