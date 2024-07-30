const std = @import("std");
const utils = @import("../utils.zig");
const Method = utils.Method;

pub const H = struct {
    map: usize = 0,

    pub fn get(self: @This(), m: Method) bool {
        return (self.map & @intFromEnum(m)) != 0;
    }

    pub fn set(self: *@This(), m: Method) void {
        self.map |= @intFromEnum(m);
    }

    pub fn unset(self: *@This(), m: Method) void {
        self.map &= ~@intFromEnum(m);
    }
};

pub const key_lower = "allow";
pub const key = "Allow";

pub fn parse(str: []const u8, opts: *const utils.ParseOptions) !H {
    var res: usize = 0;
    var it = std.mem.tokenizeScalar(u8, str, ',');
    while (it.next()) |token| {
        const m = try Method.parseFromSlice(
            std.mem.trim(u8, token, &std.ascii.whitespace),
            opts.on_parse_method_error,
        );
        res |= @intFromEnum(m);
    }
    return H{ .map = res };
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Allow' header" {
    const h1 = try parse("INVITE, ACK, CANCEL, OPTIONS, BYE, REFER, NOTIFY, MESSAGE, SUBSCRIBE, INFO, PRACK, UPDATE", &.{});
    try t.expect(h1.get(Method.INVITE));
    try t.expect(h1.get(Method.ACK));
    try t.expect(h1.get(Method.CANCEL));
    try t.expect(h1.get(Method.OPTIONS));
    try t.expect(h1.get(Method.BYE));
    try t.expect(h1.get(Method.REFER));
    try t.expect(h1.get(Method.NOTIFY));
    try t.expect(h1.get(Method.MESSAGE));
    try t.expect(h1.get(Method.SUBSCRIBE));
    try t.expect(h1.get(Method.INFO));
    try t.expect(h1.get(Method.PRACK));
    try t.expect(h1.get(Method.UPDATE));

    try t.expect(!h1.get(Method.UNEXPECTED));
    try t.expect(!h1.get(Method.USER1));
    try t.expect(!h1.get(Method.USER2));
    try t.expect(!h1.get(Method.USER3));

    const h2 = try parse("INVITE", &.{});
    try t.expect(h2.get(Method.INVITE));
    try t.expect(!h2.get(Method.ACK));

    var h3 = try parse("BYE, REFER", &.{});
    try t.expect(h3.get(Method.BYE));
    try t.expect(h3.get(Method.REFER));

    try t.expect(!h3.get(Method.INVITE));
    h3.set(Method.INVITE);
    try t.expect(h3.get(Method.INVITE));
    h3.unset(Method.INVITE);
    try t.expect(!h3.get(Method.INVITE));
}
