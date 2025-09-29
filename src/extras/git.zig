const std = @import("std");

const path = std.fs.path;
const File = std.fs.File;
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;

// This is more than enough, as maximum size is 255
var in: [512]u8 = undefined;

const PathIterator = path.NativeComponentIterator;

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

pub fn is_in_git(alloc: Allocator, iter: *PathIterator) ?[]const u8 {
    // Skip /home
    _ = iter.next() orelse return null;

    // Skip /home/hkupty
    _ = iter.next() orelse return null;

    while (iter.next()) |component| {
        const target = path.join(alloc, &.{ component.path, ".git" }) catch return null;
        std.fs.accessAbsolute(target, .{}) catch continue;
        return target;
    }
    return null;
}


