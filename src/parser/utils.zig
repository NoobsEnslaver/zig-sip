const std = @import("std");
const headers = @import("./headers.zig");
const RURI = @import("./ruri.zig").RURI;

// --------------- Types -------------------
pub const Method = enum {
    INVITE,
    ACK,
    OPTIONS,
    BYE,
    CANCEL,
    REGISTER,
    INFO,

    UNEXPECTED,
    USER1,
    USER2,
    USER3,
    USER4,

    pub fn parseFromSlice(s: []const u8, opts: ParseMethodErrBehavior) !Method {
        if (std.mem.eql(u8, s, "INVITE")) return Method.INVITE;
        if (std.mem.eql(u8, s, "ACK")) return Method.ACK;
        if (std.mem.eql(u8, s, "OPTIONS")) return Method.OPTIONS;
        if (std.mem.eql(u8, s, "INFO")) return Method.INFO;
        if (std.mem.eql(u8, s, "BYE")) return Method.BYE;
        if (std.mem.eql(u8, s, "CANCEL")) return Method.CANCEL;
        if (std.mem.eql(u8, s, "REGISTER")) return Method.REGISTER;

        switch (opts) {
            ParseMethodErrBehaviorTag.err => return error.BadMethod,
            ParseMethodErrBehaviorTag.replace => |res| {
                return res;
            },
            ParseMethodErrBehaviorTag.callback => |f| {
                return f(s);
            },
        }

        return error.BadMethod;
    }
};

pub const Req = struct {
    ruri: RURI = undefined,
    headers: std.ArrayList(headers.RawHeader) = undefined,
    method: Method = undefined,
    body: ?[]const u8 = null,
};

pub const Resp = struct {
    code: u10 = undefined,
    reason: []const u8 = undefined,
    headers: std.ArrayList(headers.RawHeader) = undefined,
    method: Method = undefined,
    body: ?[]const u8 = null,
};

pub const MessageType = enum { req, resp };
pub const Msg = union(MessageType) {
    req: Req,
    resp: Resp,
};

pub const UnknownHeaderBehaviorTag = enum { err, remove, skip_parsing, callback };
pub const UnknownHeaderBehavior = union(UnknownHeaderBehaviorTag) {
    err,
    remove,
    skip_parsing,
    callback: fn (*headers.RawHeader) anyerror!void,
};

pub const ParseMethodErrBehaviorTag = enum { err, replace, callback };
pub const ParseMethodErrBehavior = union(ParseMethodErrBehaviorTag) {
    err,
    replace: Method,
    callback: fn ([]const u8) anyerror!Method,
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
    lazy_parsing: bool = false,

    share_memory: bool = false,
    allow_multiline: bool = true,
    ignore_sip_version: bool = true,
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
