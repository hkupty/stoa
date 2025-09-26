const std = @import("std");

const outstr =
    "\x1B7\x1B[3A\x1B[2M\x1B8\x1B[1A";

const out = std.fs.File.stdout();

pub fn main() !void {
    _ = try out.write(outstr);
}
