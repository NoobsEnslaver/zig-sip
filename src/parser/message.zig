const std = @import("std");
const utils = @import("./utils.zig");
const headers = @import("./headers.zig");
const ruri = @import("./ruri.zig");
const Allocator = std.mem.Allocator;

// -------------- Functions ---------------
pub fn parseFromSlice(allocator: Allocator, s: []const u8, options: *const utils.ParseOptions) !utils.Msg {
    var stream = std.io.fixedBufferStream(s);
    const r = stream.reader();
    return parseFromReader(allocator, r, options);
}

pub fn parseFromReader(allocator: Allocator, reader: anytype, options: *const utils.ParseOptions) !utils.Msg {
    // parse first line
    //   if request_line -> create Req
    //   if status_line -> create Resp
    // parse headers
    // if content_len > 0 -> parse sdp
    var early_stream = std.io.LimitedReader(@TypeOf(reader)){ .bytes_left = options.max_message_size, .inner_reader = reader };
    const lim_reader = early_stream.reader();

    var buf: [options.max_line_len]u8 = undefined;
    var first_line: []const u8 = try reader.readUntilDelimiter(&buf, '\n');
    first_line = std.mem.trim(u8, first_line, &std.ascii.whitespace);
    if (first_line.len < 12) {
        return error.TooShort;
    }

    if (std.mem.startsWith(u8, first_line, "SIP/")) { // RESP
        var resp = utils.Resp{};
        try parseStatusLine(allocator, first_line, &resp, options);
        resp.headers = try headers.parse(allocator, lim_reader, options);
        // TODO: add body
        return utils.Msg{ .resp = resp };
    } else { // REQ
        var req = utils.Req{};
        try parseRequestLine(allocator, first_line, &req, options);
        req.headers = try headers.parse(allocator, lim_reader, options);
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
fn parseRequestLine(allocator: Allocator, first_line: []const u8, req: *utils.Req, options: *const utils.ParseOptions) !void {
    var it = std.mem.tokenizeScalar(u8, first_line, ' ');
    var pos: u8 = 0;
    while (it.next()) |token| : (pos += 1) {
        switch (pos) {
            0 => req.method = try utils.Method.parseFromSlice(token, options.on_parse_method_error),
            1 => req.ruri = try ruri.create(allocator, token, options),
            2 => if (!options.ignore_sip_version and !std.mem.eql(u8, token, "SIP/2.0"))
                return error.UnexpectedSIPVer,
            else => return error.UnexpectedToken,
        }
    }
    if (pos != 3) return error.UnexpectedToken;
}

// Status-Line = SIP-Version SP Status-Code SP Reason-Phrase CRLF
fn parseStatusLine(allocator: Allocator, first_line: []const u8, resp: *utils.Resp, options: *const utils.ParseOptions) !void {
    var it = std.mem.tokenizeScalar(u8, first_line, ' ');
    var pos: u8 = 0;
    while (it.next()) |token| : (pos += 1) {
        switch (pos) {
            0 => if (!options.ignore_sip_version and !std.mem.eql(u8, token, "SIP/2.0"))
                return error.UnexpectedSIPVer,
            1 => {
                resp.code = try std.fmt.parseUnsigned(u10, token, 10);
                const buf = try allocator.alloc(u8, it.rest().len);
                @memcpy(buf, it.rest());
                resp.reason = buf;
                break; // stop tokenization there to don't tokenize Reason-Phrase
            },
            else => unreachable,
        }
    }
    if (pos != 1) return error.UnexpectedToken;
}
