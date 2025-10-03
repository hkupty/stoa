const std = @import("std");

const Writer = std.Io.Writer;

var buf: [3]u8 = undefined;
fn to_ascii(number: u8) usize {
    var num = number;
    var index: usize = 3;
    while (num > 0) {
        index -= 1;
        const digit = num % 10;
        buf[index] = digit + '0';
        num /= 10;
    }
    return index;
}

pub fn write_color(writer: *Writer, color: u8) void {
    _ = writer.write("%{\x1B[38;5;") catch unreachable;
    const sz = to_ascii(color);
    _ = writer.write(buf[sz..]) catch unreachable;
    _ = writer.write("m%}") catch unreachable;
}

pub fn clear_format(writer: *Writer) void {
    _ = writer.write("%{\x1B[0m%}") catch unreachable;
}
