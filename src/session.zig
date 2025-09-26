const std = @import("std");
const stoa = @import("stoa");

const b32 = "0123456789ABCDEFGHJKMNPQRSTVWXYZ";

fn create() ![5]u8 {
    var random_read: [3]u8 = undefined;
    var session: [5]u8 = undefined;
    const out = try std.fs.openFileAbsolute("/dev/urandom", .{ .mode = .read_only });
    defer out.close();
    _ = try out.read(&random_read);

    var random: u24 = random_read[0] + (@as(u24, random_read[1]) << 8) + (@as(u24, random_read[2]) << 16);

    for (0..session.len) |offset| {
        const ix = session.len - offset - 1;
        const char = @as(usize, random & 0x1F);
        std.debug.assert(char < 32);
        session[ix] = b32[char];
        random >>= 5;
    }
    return session;
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    const fp = try create();
    const path = try std.mem.join(alloc, "-", &.{ "stoa", &fp });
    const abs_path = try std.fs.path.join(alloc, &.{ "/run/user/1000/", path });
    var file = try std.fs.createFileAbsolute(abs_path, .{});
    defer file.close();
    try stoa.touch(file);
    _ = try std.fs.File.stdout().write(abs_path);
}
