const std = @import("std");
const parser = @import("./parser/message.zig");
const utils = @import("./parser/utils.zig");
// const sdp = @import("./sdp/sdp.zig");

// ---------------- Interfaces --------------------
pub const MessageType = utils.MessageType;
pub const Req = utils.Req;
pub const Resp = utils.Resp;
pub const Msg = utils.Msg;

// ---------------- Testing -----------------------
const t = std.testing;
test {
    _ = @import("./parser/message.zig");
}

test {
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();

    //These are messages that the parser should pass
    const good = [_][]const u8{
        "test1.txt",  "test2.txt",  "test3.txt",  "test4.txt",
        "test1.txt",  "test2.txt",  "test3.txt",  "test4.txt",
        "test5.txt",  "test6.txt",  "test9.txt",  "test14.txt",
        "test20.txt", "test23.txt", "test24.txt", "test31.txt",
        "own1.txt",   "own2.txt",   "own3.txt",   "own4.txt",
        "own5.txt",   "own6.txt",

        // These are ugly messages that parser should pass
          "test25.txt", "test27.txt",
        "test28.txt", "test30.txt", "test32.txt", "test34.txt",
        "test36.txt", "test37.txt", "test38.txt",
        "test39.txt",
        // "test41.txt", "test42.txt",
    };

    // These are messages that the parser should fail
    const bad = [_][]const u8{
        "test7.txt", "test8.txt", // "test10.txt", "test11.txt",
        // "test12.txt",
        // "test13.txt",
        // "test15.txt",
        // "test16.txt",
        // "test17.txt",
        // "test18.txt",
        // "test19.txt",
        // "test21.txt",
        "test22.txt", // "test26.txt",
        // "test29.txt",
        // "test33.txt",
        // "test35.txt",
        // "test40.txt",
    };

    var tests_dir = try std.fs.cwd().openDir("tests", .{});
    defer tests_dir.close();
    for (good) |file| {
        const fd = try tests_dir.openFile(file, .{});
        defer fd.close();
        _ = parser.parseFromReader(arena.allocator(), fd.reader(), .{}) catch |err| {
            std.debug.print("{s}: unexpected parsing error: {any}\n", .{ file, err });
            try t.expect(false);
            continue;
        };
        try t.expect(true);
    }

    for (bad) |file| {
        const fd = try tests_dir.openFile(file, .{});
        defer fd.close();
        _ = parser.parseFromReader(arena.allocator(), fd.reader(), .{}) catch {
            try t.expect(true);
            continue;
        };
        std.debug.print("{s}: unexpected parsing success (should fail)\n", .{file});
        try t.expect(false);
    }
}

test "test2.txt" {
    const raw_msg = @embedFile("./tests/test2.txt");
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();
    const msg = try parser.parseFromSlice(arena.allocator(), raw_msg, .{});
    try t.expectEqual(utils.MessageType.req, @as(utils.MessageType, msg));

    const req = msg.req;
    try t.expectEqual(utils.Method.INVITE, req.method);
    try t.expectEqualStrings("sip:user@company.com", req.ruri);
    try t.expectEqual(null, req.body);
}

test "test7.txt" {
    const raw_msg = @embedFile("./tests/test7.txt");
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();
    const parse_opts = .{ .on_parse_method_error = utils.ParseMethodErrBehavior{ .replace = utils.Method.UNEXPECTED } };
    const msg = try parser.parseFromSlice(arena.allocator(), raw_msg, parse_opts);
    try t.expectEqual(utils.MessageType.req, @as(utils.MessageType, msg));

    const req = msg.req;
    try t.expectEqual(utils.Method.UNEXPECTED, req.method);
    try t.expectEqualStrings("sip:user@comapny.com", req.ruri);
    // try t.expectEqual(null, req.body);
}

fn test8FixMethodCallback(s: []const u8) anyerror!utils.Method {
    try t.expectEqualStrings("NEWMETHOD", s);
    return utils.Method.USER1;
}

test "test8.txt" {
    const raw_msg = @embedFile("./tests/test8.txt");
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();

    const parse_opts = .{ .on_parse_method_error = utils.ParseMethodErrBehavior{ .callback = test8FixMethodCallback } };
    const msg = try parser.parseFromSlice(arena.allocator(), raw_msg, parse_opts);
    try t.expectEqual(utils.MessageType.req, @as(utils.MessageType, msg));

    const req = msg.req;
    try t.expectEqual(utils.Method.USER1, req.method);
    try t.expectEqualStrings("sip:user@comapny.com", req.ruri);
    // try t.expectEqual(null, req.body);
}

test "own2.txt" {
    const raw_msg = @embedFile("./tests/own2.txt");
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();
    const msg = try parser.parseFromSlice(arena.allocator(), raw_msg, .{});
    try t.expectEqual(utils.MessageType.resp, @as(utils.MessageType, msg));

    const resp = msg.resp;
    try t.expectEqual(401, resp.code);
    try t.expectEqualStrings("Unauthorized", resp.reason);
    try t.expectEqual(null, resp.body);
}

test "test41.txt" {
    const raw_msg = @embedFile("./tests/test41.txt");
    var arena = std.heap.ArenaAllocator.init(t.allocator);
    defer arena.deinit();

    try t.expectEqual(error.UnexpectedSIPVer, parser.parseFromSlice(arena.allocator(), raw_msg, .{}));
}
