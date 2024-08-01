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

// ------------------ Tests -----------------
const t = std.testing;
test indexOfUnquoted {
    const str = "\"J Rosenberg \\\"\" <sip:jdrosen@lucent.com>;tag = 98asjd8";
    try t.expectEqual(0, indexOfUnquoted(str, '"').?);
    try t.expectEqual(14, indexOfUnquoted(str[1..], '"').?);
}
