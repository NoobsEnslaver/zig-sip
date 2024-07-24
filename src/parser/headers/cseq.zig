const std = @import("std");
const utils = @import("../utils.zig");

pub const H = struct { seq: u32, method: utils.Method };
pub const key_lower = "cseq";
pub const key = "CSeq";

pub fn parse(str: []const u8) !H {
    var it = std.mem.tokenizeScalar(u8, str, ' ');
    const token1 = it.next() orelse return error.UnexpectedToken;
    const token2 = it.next() orelse return error.UnexpectedToken;
    return H{
        .seq = try std.fmt.parseInt(u32, token1, 10),
        .method = try utils.Method.parseFromSlice(token2, .err), // FIXME: parse opts
    };
}

// -------------- Tests --------------------
const t = std.testing;
test "parsing 'CSeq' header" {
    try t.expect(true);
}
