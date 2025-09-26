const std = @import("std");

const outstr =
    "\x1B7\x1B[2A\x1B[2K\x1B8";

const out = std.fs.File.stdout();

pub fn main() !void {
    _ = try out.write(outstr);
}
