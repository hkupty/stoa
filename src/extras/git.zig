const std = @import("std");

const File = std.fs.File;
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;

// This is more than enough, as maximum size is 255
var in: [512]u8 = undefined;

pub fn parseHeadInto(alloc: Allocator, git_dir_path: []const u8, writer: *Writer) void {
    const head = std.fs.path.join(alloc, &.{ git_dir_path, "HEAD" }) catch return;
    const head_file = std.fs.openFileAbsolute(head, .{ .mode = .read_only }) catch return;
    defer head_file.close();
    var file_reader = head_file.reader(&in);
    var reader = &file_reader.interface;

    const header = reader.peek(4) catch unreachable;
    if (std.mem.eql(u8, "ref:", header)) {
        _ = reader.discardDelimiterInclusive('/') catch return;
        _ = reader.discardDelimiterInclusive('/') catch return;
    }
    _ = reader.streamDelimiter(writer, '\n') catch return;
}
