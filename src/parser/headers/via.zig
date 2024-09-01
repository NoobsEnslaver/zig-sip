const std = @import("std");
const utils = @import("../utils.zig");

pub const H = struct {
    protocol: utils.TransportProtocol,
    host: []const u8,
    port: ?u16,
    params: std.StringHashMap([]const u8),
};

pub const key_lower = "via";
pub const key_short = 'v';
pub const key = "Via";

pub fn parse(str: []const u8, allocator: std.mem.Allocator, opts: *const utils.ParseOptions) !H {
    var it = std.mem.tokenizeScalar(u8, str, ' ');
    const proto = it.next() orelse return error.UnexpectedTokenNoProto;
    const rest = it.next() orelse return error.UnexpectedTokenNoHostParam;

    if (proto.len < 9) return error.ProtocolTokenTooShort;
    if (!opts.ignore_sip_version and !std.mem.startsWith(u8, proto, "SIP/2.0")) {
        return error.UnexpectedSIPVer;
    }

    it = std.mem.tokenizeScalar(u8, rest, ';');
    const addr = it.next() orelse return error.UnexpectedTokenNoHost;
    var params = std.StringHashMap([]const u8).init(allocator);
    while (it.next()) |token| {
        if (std.mem.indexOfScalar(u8, token, '=')) |idx| {
            try params.put(token[0..idx], token[idx + 1 ..]);
        } else {
            try params.put(token, "");
        }
    }

    const hp = try utils.splitHostPort(addr);
    return H{
        .protocol = try utils.TransportProtocol.parse(proto[8..]),
        .host = hp.host,
        .port = hp.port,
        .params = params,
    };
}
// -------------- Tests --------------------
const t = std.testing;
test "parsing 'Via' header" {
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    const a = arena.allocator();
    defer arena.deinit();

    var h = try parse("SIP/2.0/UDP srlab.sr.ntc.nokia.com:5060;maddr=192.168.102.5", a, &.{});
    try t.expectEqual(utils.TransportProtocol.UDP, h.protocol);
    try t.expectEqualStrings("srlab.sr.ntc.nokia.com", h.host);
    try t.expectEqual(5060, h.port);
    try t.expectEqualStrings("192.168.102.5", h.params.get("maddr").?);

    h = try parse("SIP/2.0/TCP [aa:bb::1]:5061;rport", a, &.{});
    try t.expectEqual(utils.TransportProtocol.TCP, h.protocol);
    try t.expectEqualStrings("[aa:bb::1]", h.host);
    try t.expectEqual(5061, h.port);
    try t.expectEqualStrings("", h.params.get("rport").?);
}
