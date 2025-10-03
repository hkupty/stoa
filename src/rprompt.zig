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

pub fn write_prefix(logo: []const u8, color: u8, index: usize) !void {
    if (index > 0) {
        _ = try out.write(" | ");
    }
    stoa.color.write_color(out, color);
    _ = try out.write(logo);
}

pub fn write(logo: []const u8, content: []const u8, color: u8, index: usize) !void {
    try write_prefix(logo, color, index);
    _ = try out.write(content);
    stoa.color.clear_format(out);
}

pub fn main() void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    if (stoa.atomic_read(alloc)) |runtimeData| {
        if (runtimeData.in_git) {
            for (shell.rprompt, 0..) |piece, ix| {
                switch (piece) {
                    .aws => {
                        const env = std.process.getEnvVarOwned(alloc, "AWS_PROFILE") catch {
                            continue;
                        };
                        write(" ", env, 220, ix) catch unreachable;
                    },
                    .kubernetes => {
                        write_prefix(" ", 68, ix) catch unreachable;
                        k8s.parse_current_context(out);
                        stoa.color.clear_format(out);
                    },
                }
            }
        }
    }

    out.flush() catch unreachable;
}
