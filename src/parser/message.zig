const std = @import("std");
const utils = @import("./utils.zig");
const headers = @import("./headers.zig");
const ruri = @import("./ruri.zig");
const Allocator = std.mem.Allocator;
const Arena = std.heap.ArenaAllocator;

// -------------- Functions ---------------
pub fn parseFromSlice(allocator: Allocator, s: []const u8, options: *const utils.ParseOptions) !utils.Msg {
    var stream = std.io.fixedBufferStream(s);
    const r = stream.reader();
    return parseFromReader(allocator, r, options);
}

pub fn parseFromReader(allocator: Allocator, reader: anytype, options: *const utils.ParseOptions) !utils.Msg {
    var arena = std.heap.ArenaAllocator.init(allocator);
    const arena_alloc = arena.allocator();
    errdefer arena.deinit();

    var early_stream = std.io.LimitedReader(@TypeOf(reader)){
        .bytes_left = options.max_message_size,
        .inner_reader = reader,
    };
    const lim_reader = early_stream.reader();

    const buf = try arena_alloc.alloc(u8, options.max_line_len);
    defer arena_alloc.free(buf);

    var first_line: []const u8 = try reader.readUntilDelimiter(buf, '\n');
    first_line = std.mem.trim(u8, first_line, &std.ascii.whitespace);
    if (first_line.len < 12) {
        return error.TooShort;
    }

    if (std.mem.startsWith(u8, first_line, "SIP/")) { // RESP
        var resp = try parseStatusLine(&arena, first_line, options);
        resp.headers = try headers.parse(&resp, lim_reader);
        // TODO: set method from CSeq or error
        // TODO: add body
        return resp;
    } else { // REQ
        var req = try parseRequestLine(&arena, first_line, options);
        req.headers = try headers.parse(&req, lim_reader);
        // TODO: body
        return req;
    }
}

// -------------- Tests --------------------
const t = std.testing;
test {
    _ = @import("./ruri.zig");
    _ = @import("./headers.zig");
}

// Request-Line = Method SP Request-URI SP SIP-Version CRLF
fn parseRequestLine(arena: *Arena, first_line: []const u8, options: *const utils.ParseOptions) !utils.Msg {
    var it = std.mem.tokenizeScalar(u8, first_line, ' ');
    var pos: u8 = 0;
    var m: utils.Method = undefined;
    var r: ruri.RURI = undefined;
    while (it.next()) |token| : (pos += 1) {
        switch (pos) {
            0 => m = try utils.Method.parseFromSlice(token, options.on_parse_method_error),
            1 => r = try ruri.create(arena.allocator(), token, options),
            2 => if (!options.ignore_sip_version and !std.mem.eql(u8, token, "SIP/2.0"))
                return error.UnexpectedSIPVer,
            else => return error.UnexpectedToken,
        }
    }
    if (pos != 3) return error.UnexpectedToken;

    return utils.Msg{
        .arena = arena,
        .parse_opts = options,
        .tag = .req,
        .method = m,
        .ruri = r,
    };
}

// Status-Line = SIP-Version SP Status-Code SP Reason-Phrase CRLF
fn parseStatusLine(arena: *Arena, first_line: []const u8, options: *const utils.ParseOptions) !utils.Msg {
    var it = std.mem.tokenizeScalar(u8, first_line, ' ');
    var pos: u8 = 0;
    var code: u10 = undefined;
    var reason: []const u8 = undefined;
    while (it.next()) |token| : (pos += 1) {
        switch (pos) {
            0 => if (!options.ignore_sip_version and !std.mem.eql(u8, token, "SIP/2.0"))
                return error.UnexpectedSIPVer,
            1 => {
                code = try std.fmt.parseUnsigned(u10, token, 10);
                const buf = try arena.allocator().alloc(u8, it.rest().len);
                @memcpy(buf, it.rest());
                reason = buf;
                break; // stop tokenization there to don't tokenize Reason-Phrase
            },
            else => unreachable,
        }
    }
    if (pos != 1) return error.UnexpectedToken;

    return utils.Msg{
        .arena = arena,
        .tag = .resp,
        .parse_opts = options,
        .code = code,
        .reason = reason,
    };
}
