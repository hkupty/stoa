const std = @import("std");

const Writer = std.Io.Writer;

pub fn write_color(writer: *Writer, color: u8) void {
    var buf: [256]u8 = undefined;
    const out = std.fmt.bufPrint(&buf, "%{{\x1B[38;5;{d}m%}}", .{color}) catch unreachable;
    _ = writer.write(out) catch unreachable;
}

pub fn clear_format(writer: *Writer) void {
    _ = writer.write("%{\x1B[0m%}") catch unreachable;
}
