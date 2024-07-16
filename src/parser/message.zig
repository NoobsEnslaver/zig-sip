const std = @import("std");
const utils = @import("./utils.zig");
const headers = @import("./headers.zig");
const ruri = @import("./ruri.zig");

const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

// ------------- Declarations -------------

// -------------- Functions ---------------
// TODO: возвращать union или принимать тип в качестве аргумента?

pub fn parseFromSlice(allocator: Allocator, s: []const u8, options: utils.ParseOptions) !utils.Msg {
    var stream = std.io.fixedBufferStream(s);
    const r = stream.reader();
    return parseFromReader(allocator, r, options);
}

pub fn parseFromReader(allocator: Allocator, r: anytype, options: utils.ParseOptions) !utils.Msg {
    // parse first line
    //   if request_line -> create Req
    //   if status_line -> create Resp
    // parse headers
    // if content_len > 0 -> parse sdp

    // FIXME: use unils.readUntilDelimiterAlloc for split by "\r\n"?
    var first_line: []const u8 = try r.readUntilDelimiterAlloc(allocator, '\n', options.max_line_len);
    first_line = std.mem.trim(u8, first_line, &std.ascii.whitespace);
    if (first_line.len < 12) {
        return error.TooShort;
    }

    if (std.mem.startsWith(u8, first_line, "SIP/")) { // RESP
        var resp = utils.Resp{};
        try parseStatusLine(first_line, &resp, options);
        resp.headers = try headers.parse(allocator, r, options);
        // TODO: add body
        return utils.Msg{ .resp = resp };
    } else { // REQ
        var req = utils.Req{};
        try parseRequestLine(first_line, &req, options);
        req.headers = try headers.parse(allocator, r, options);
        return utils.Msg{ .req = req };
    }
}

// -------------- Tests --------------------
const t = std.testing;
test {
    _ = @import("./ruri.zig");
    _ = @import("./headers.zig");
}

// Request-Line = Method SP Request-URI SP SIP-Version CRLF
fn parseRequestLine(first_line: []const u8, req: *utils.Req, options: utils.ParseOptions) !void {
    var it = std.mem.tokenizeScalar(u8, first_line, ' ');
    var pos: u8 = 0;
    while (it.next()) |token| : (pos += 1) {
        switch (pos) {
            0 => req.method = try utils.Method.parseFromSlice(token, options.on_parse_method_error),
            1 => req.ruri = try ruri.parse(token),
            2 => if (!std.mem.eql(u8, token, "SIP/2.0")) {
                return error.UnexpectedSIPVer;
            },
            else => return error.UnexpectedToken,
        }
    }
    if (pos != 3) return error.UnexpectedToken;
}

// Status-Line = SIP-Version SP Status-Code SP Reason-Phrase CRLF
fn parseStatusLine(first_line: []const u8, resp: *utils.Resp, options: utils.ParseOptions) !void {
    _ = options;
    var it = std.mem.tokenizeScalar(u8, first_line, ' ');
    var pos: u8 = 0;
    while (it.next()) |token| : (pos += 1) {
        switch (pos) {
            0 => if (!std.mem.eql(u8, token, "SIP/2.0")) return error.UnexpectedSIPVer,
            1 => {
                resp.code = try std.fmt.parseUnsigned(u10, token, 10);
                resp.reason = it.rest();
                break; // stop tokenization there to don't tokenize Reason-Phrase
            },
            else => unreachable,
        }
    }
    if (pos != 1) return error.UnexpectedToken;
}
