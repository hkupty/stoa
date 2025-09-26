const std = @import("std");

const File = std.fs.File;
const Allocator = std.mem.Allocator;

// This is more than enough, as maximum size is 255
var in: [512]u8 = undefined;

pub fn parseHead(alloc: Allocator, git_dir_path: []const u8) []const u8 {
    const head = std.fs.path.join(alloc, &.{ git_dir_path, "HEAD" }) catch return "";
    const head_file = std.fs.openFileAbsolute(head, .{ .mode = .read_only }) catch return "";
    defer head_file.close();
    var file_reader = head_file.reader(&in);
    var reader = &file_reader.interface;

    const header = reader.peek(4) catch unreachable;
    if (std.mem.eql(u8, "ref:", header)) {
        _ = reader.discardDelimiterInclusive('/') catch return "";
        _ = reader.discardDelimiterInclusive('/') catch return "";
    }
    const out = reader.takeDelimiterExclusive('\n') catch return "";
    return alloc.dupe(u8, out) catch return "";
}
