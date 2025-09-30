const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const mod = b.addModule("stoa", .{
        .root_source_file = b.path("lib/root.zig"),
        .target = target,
    });

    const transient = b.addExecutable(.{
        .name = "stoa-transient",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/transient.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "stoa", .module = mod },
            },
        }),
    });

    b.installArtifact(transient);

    const status = b.addExecutable(.{
        .name = "stoa-status",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/status.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "stoa", .module = mod },
            },
        }),
    });

    b.installArtifact(status);

    const session = b.addExecutable(.{
        .name = "stoa-session",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/session.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "stoa", .module = mod },
            },
        }),
    });

    b.installArtifact(session);

    const prompt = b.addExecutable(.{
        .name = "stoa-prompt",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/prompt.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "stoa", .module = mod },
            },
        }),
    });

    b.installArtifact(prompt);

    const rprompt = b.addExecutable(.{
        .name = "stoa-rprompt",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/rprompt.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "stoa", .module = mod },
            },
        }),
    });

    b.installArtifact(rprompt);

    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = transient.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
