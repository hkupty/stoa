const std = @import("std");
const shell: Shell = @import("./shell.zon");
const k8s = @import("./extras/kubernetes.zig");
const stoa = @import("stoa");

const stdout = std.fs.File.stdout();
var rprompt: [1 * 1024]u8 = undefined;
var fwriter = stdout.writer(&rprompt);
var out = &fwriter.interface;
var cursor: usize = 0;

const parts = enum {
    aws,
    kubernetes,
};

const Shell = struct {
    rprompt: []const parts,
    prompt: []const u8,
    repo_color: u8,
    worktree_color: u8,
    git_color: u8,
};

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    if (stoa.atomic_read(alloc)) |runtimeData| {
        if (runtimeData.in_git) {
            for (shell.rprompt, 0..) |piece, ix| {
                if (ix > 0) {
                    _ = out.write(" | ") catch unreachable;
                }

                switch (piece) {
                    .aws => {
                        const env = std.process.getEnvVarOwned(alloc, "AWS_PROFILE") catch {
                            continue;
                        };
                        stoa.color.write_color(out, 220);
                        _ = out.write(" ") catch unreachable;
                        _ = out.write(env) catch unreachable;
                        stoa.color.clear_format(out);
                    },
                    .kubernetes => {
                        stoa.color.write_color(out, 68);
                        _ = out.write(" ") catch unreachable;
                        k8s.parse_current_context(out);
                        stoa.color.clear_format(out);
                    },
                }
            }
        }
    }

    out.flush() catch unreachable;
}
