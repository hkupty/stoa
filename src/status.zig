const std = @import("std");
const stoa = @import("stoa");

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var iter = std.process.args();
    defer iter.deinit();
    _ = iter.next();

    const last_status = iter.next() orelse return;
    const success = std.fmt.parseInt(i32, last_status, 10) catch return;

    if (stoa.get_session_file(alloc, .read_write)) |session_file| {
        defer session_file.close();
        var session = stoa.getdata(session_file) catch return;
        session.success = success == 0;

        stoa.stamp(session_file, &session) catch return;
    }
}
