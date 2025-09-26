const std = @import("std");

const File = std.fs.File;
const Allocator = std.mem.Allocator;
const Writer = std.Io.Writer;

// This is more than enough, as maximum size is 255
var in: [4 * 1024]u8 = undefined;

const prefix = "current-context:";

pub fn parse_current_context(writer: *Writer) void {
    const file = std.fs.openFileAbsolute("/home/hkupty/.kube/config", .{}) catch return;
    defer file.close();
    var file_reader = file.reader(&in);
    var reader = &file_reader.interface;

    while (true) {
        const peek = reader.peekDelimiterExclusive('\n') catch return;
        if (!std.mem.startsWith(u8, peek, prefix)) {
            reader.toss(peek.len + 1);
            continue;
        }

        reader.toss(prefix.len);
        _ = reader.streamDelimiterEnding(writer, '\n') catch return;
        break;
    }
}
