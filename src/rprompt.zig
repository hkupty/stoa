const std = @import("std");
const shell = @import("./shell.zon");
const stoa = @import("stoa");

var rprompt: [2 * 1024]u8 = undefined;
var cursor: usize = 0;

fn data(alloc: std.mem.Allocator) ?stoa.RuntimeData {
    const key = std.process.getEnvVarOwned(alloc, "STOA_SESION") catch {
        // TODO: Must not spill errors
        return null;
    };
    var file = std.fs.openFileAbsolute(key, .{ .mode = .read_only }) catch {
        return null;
    };
    defer file.close();

    return stoa.getdata(file) catch null;
}

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    if (data(alloc)) |runtimeData| {
        if (runtimeData.in_git) {
            @memcpy(rprompt[0..3], "git");
            cursor += 3;
        }
    }

    _ = std.fs.File.stdout().write(rprompt[0..cursor]) catch unreachable;
}
