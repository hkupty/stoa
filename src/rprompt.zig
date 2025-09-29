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
    repo_color: []const u8,
    worktree_color: []const u8,
    git_color: []const u8,
};

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
            for (shell.rprompt, 0..) |piece, ix| {
                switch (piece) {
                    .aws => {
                        const env = std.process.getEnvVarOwned(alloc, "AWS_PROFILE") catch {
                            continue;
                        };
                        if (ix > 0) {
                            _ = out.write(" | ") catch unreachable;
                        }

                        _ = out.write("%{\x1B[38;5;220m%} ") catch unreachable;
                        _ = out.write(env) catch unreachable;
                        _ = out.write("%{\x1B[0m%}") catch unreachable;
                    },
                    .kubernetes => {
                        if (ix > 0) {
                            _ = out.write(" | ") catch unreachable;
                        }
                        _ = out.write("%{\x1B[38;5;68m%} ") catch unreachable;
                        k8s.parse_current_context(out);
                        _ = out.write("%{\x1B[0m%}") catch unreachable;
                    },
                }
            }
        }
    }

    out.flush() catch unreachable;
}
