const std = @import("std");
const hs = @import("./headers.zig");
const RURI = @import("./ruri.zig").RURI;

// --------------- Types -------------------
pub const Method = enum(usize) {
    INVITE = 1 << 0,
    ACK = 1 << 1,
    OPTIONS = 1 << 2,
    BYE = 1 << 3,
    CANCEL = 1 << 4,
    REGISTER = 1 << 5,
    INFO = 1 << 6,
    SUBSCRIBE = 1 << 7,
    REFER = 1 << 8,
    NOTIFY = 1 << 9,
    MESSAGE = 1 << 10,
    UPDATE = 1 << 11,
    PRACK = 1 << 12,

    UNEXPECTED = 1 << 13,
    USER1 = 1 << 14,
    USER2 = 1 << 15,
    USER3 = 1 << 16,

    pub fn parseFromSlice(s: []const u8, opts: ParseMethodErrBehavior) !Method {
        if (std.mem.eql(u8, s, "INVITE")) return Method.INVITE;
        if (std.mem.eql(u8, s, "ACK")) return Method.ACK;
        if (std.mem.eql(u8, s, "OPTIONS")) return Method.OPTIONS;
        if (std.mem.eql(u8, s, "BYE")) return Method.BYE;
        if (std.mem.eql(u8, s, "CANCEL")) return Method.CANCEL;
        if (std.mem.eql(u8, s, "REGISTER")) return Method.REGISTER;
        if (std.mem.eql(u8, s, "INFO")) return Method.INFO;
        if (std.mem.eql(u8, s, "SUBSCRIBE")) return Method.SUBSCRIBE;
        if (std.mem.eql(u8, s, "REFER")) return Method.REFER;
        if (std.mem.eql(u8, s, "NOTIFY")) return Method.NOTIFY;
        if (std.mem.eql(u8, s, "MESSAGE")) return Method.MESSAGE;
        if (std.mem.eql(u8, s, "UPDATE")) return Method.UPDATE;
        if (std.mem.eql(u8, s, "PRACK")) return Method.PRACK;

        switch (opts) {
            ParseMethodErrBehaviorTag.err => return error.BadMethod,
            ParseMethodErrBehaviorTag.replace => |res| return res,
            ParseMethodErrBehaviorTag.callback => |f| return f(s),
        }

        return error.BadMethod;
    }
};

pub const TransportProtocol = enum {
    TCP,
    UDP,
    TLS,
    SCTP,

    pub fn parse(str: []const u8) !TransportProtocol {
        if (std.ascii.eqlIgnoreCase(str, "TCP")) return TransportProtocol.TCP;
        if (std.ascii.eqlIgnoreCase(str, "UDP")) return TransportProtocol.UDP;
        if (std.ascii.eqlIgnoreCase(str, "TLS")) return TransportProtocol.TLS;
        if (std.ascii.eqlIgnoreCase(str, "SCTP")) return TransportProtocol.SCTP;

        // std.debug.print("++++++++++++++++ UnexpectedTransportProtocol: {s}\n", .{str});
        return error.UnexpectedTransportProtocol;
    }
};

pub const UnknownHeaderBehaviorTag = enum { err, remove, skip_parsing, callback };
pub const UnknownHeaderBehavior = union(UnknownHeaderBehaviorTag) {
    err,
    remove,
    skip_parsing,
    callback: *const fn (*hs.RawHeader) anyerror!void,
};

pub const ParseMethodErrBehaviorTag = enum { err, replace, callback };
pub const ParseMethodErrBehavior = union(ParseMethodErrBehaviorTag) {
    err,
    replace: Method,
    callback: *const fn ([]const u8) anyerror!Method,
};
pub const ParseOptions = struct {
    duplicate_field_behavior: enum {
        use_first,
        @"error",
        use_last,
    } = .@"error",

    // if true - remove an unknown header from parsing result (no error)
    // If false - finding an unknown header returns `error.UnknownHeader`.
    on_unknown_header: UnknownHeaderBehavior = .skip_parsing,
    on_parse_method_error: ParseMethodErrBehavior = .err,

    // limits
    max_message_size: usize = 8192,
    max_line_len: usize = 256,
    max_headers: u8 = 50,

    // Headers wil be complitely parsed, or just to form "key":"value" and then when required
    lazy_parsing: bool = true,

    share_memory: bool = false,
    allow_multiline: bool = true,
    ignore_sip_version: bool = true,
    compress_headers: bool = false,
};

pub const Pair = struct {
    key: []const u8,
    value: []const u8,
};

// --------------- Functions -------------------

pub fn readLine(allocator: std.mem.Allocator, reader: anytype, max_size: usize) ![]const u8 {
    const buf: []u8 = try allocator.alloc(u8, max_size);
    var stream = std.io.fixedBufferStream(buf);
    const w = stream.writer();
    try reader.streamUntilDelimiter(w, '\n', max_size);
    while (buf[w.context.pos - 1] != '\r') {
        try reader.streamUntilDelimiter(w, '\n', max_size - w.context.pos);
    }

    return std.mem.trimRight(u8, buf[0..w.context.pos], &std.ascii.whitespace);
}

pub fn isValidHeaderName(name: []const u8) bool {
    for (name) |c| {
        if (!std.ascii.isAlphabetic(c) and c != '-') {
            return false;
        }
    }
    return true;
}

pub fn foldl(T: type, f: fn (T, T) T, init: T, list: []const T) T {
    var acc: T = init;
    for (list) |x| {
        acc = f(acc, x);
    }
    return acc;
}

pub fn reduce(T: type, f: fn (T, T) T, list: []const T) T {
    return foldl(T, f, list[0], list[1..]);
}

pub fn max(xs: []const usize) usize {
    var res = 0;
    for (xs) |x| {
        res = @max(res, x);
    }
    return res;
}

pub fn indexOfUnquoted(str: []const u8, c: u8) ?usize {
    if (str.len == 0) return null;
    if (str[0] == c) return 0;

    var it = std.mem.window(u8, str, 2, 1);
    var idx: usize = 1;
    while (it.next()) |s| : (idx += 1) {
        if (s[1] == c and s[0] != '\\') {
            return idx;
        }
    }
    return null;
}

pub fn splitHostPort(addr: []const u8) !struct { host: []const u8, port: ?u16 } {
    var host: []const u8 = undefined;
    var port: ?u16 = null;
    if (std.mem.lastIndexOfScalar(u8, addr, ']')) |idx| { // ipv6 test
        host = addr[0 .. idx + 1];
        if (idx < addr.len) {
            if (addr[idx + 1] != ':') {
                return error.TrashOnHostEnd;
            }
            port = try std.fmt.parseInt(u16, addr[idx + 2 ..], 10);
        }
    } else {
        if (std.mem.lastIndexOfScalar(u8, addr, ':')) |idx| {
            host = addr[0..idx];
            port = try std.fmt.parseInt(u16, addr[idx + 1 ..], 10);
        } else {
            host = addr;
        }
    }

    return .{ .host = host, .port = port };
}

// ------------------ Tests -----------------
const t = std.testing;
test indexOfUnquoted {
    const str = "\"J Rosenberg \\\"\" <sip:jdrosen@lucent.com>;tag = 98asjd8";
    try t.expectEqual(0, indexOfUnquoted(str, '"').?);
    try t.expectEqual(14, indexOfUnquoted(str[1..], '"').?);
}

test splitHostPort {
    const str1 = "google.com:8080";
    const str2 = "192.168.1.1:5090";
    const str3 = "[aa:bb::1]:5061";
    const str4 = "https://ya.ru:80";

    var hp = try splitHostPort(str1);
    try t.expectEqualStrings("google.com", hp.host);
    try t.expectEqual(8080, hp.port);

    hp = try splitHostPort(str2);
    try t.expectEqualStrings("192.168.1.1", hp.host);
    try t.expectEqual(5090, hp.port);

    hp = try splitHostPort(str3);
    try t.expectEqualStrings("[aa:bb::1]", hp.host);
    try t.expectEqual(5061, hp.port);

    hp = try splitHostPort(str4);
    try t.expectEqualStrings("https://ya.ru", hp.host);
    try t.expectEqual(80, hp.port);

    // bad cases
    const bad1 = "google.com:";
    const bad2 = "https://ya.ru";
    const bad4 = "ya.ru:8888888";
    const bad5 = ":ya.ru";
    const bad6 = "[aa:bb::1]123";
    const bad7 = "https://ya.ru:8080/qwe";
    try t.expectError(error.InvalidCharacter, splitHostPort(bad1));
    try t.expectError(error.InvalidCharacter, splitHostPort(bad2));
    try t.expectError(error.Overflow, splitHostPort(bad4));
    try t.expectError(error.InvalidCharacter, splitHostPort(bad5));
    try t.expectError(error.TrashOnHostEnd, splitHostPort(bad6));
    try t.expectError(error.InvalidCharacter, splitHostPort(bad7));
}
