const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const zui_mod = b.addModule("zui", .{
        .root_source_file = b.path("src/zui.zig"),
        .target = target,
        .optimize = optimize,
    });
    addPlatformLinks(zui_mod, target);

    const hello = b.addExecutable(.{
        .name = "zui-hello",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/hello.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
            },
        }),
    });
    addPlatformLinks(hello.root_module, target);
    b.installArtifact(hello);

    const run_hello = b.addRunArtifact(hello);
    run_hello.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_hello.addArgs(args);
    }

    const run_step = b.step("run", "Run the hello example");
    run_step.dependOn(&run_hello.step);

    const test_mod = b.createModule(.{
        .root_source_file = b.path("src/zui.zig"),
        .target = target,
        .optimize = optimize,
    });
    addPlatformLinks(test_mod, target);

    const zui_tests = b.addTest(.{ .root_module = test_mod });
    const run_zui_tests = b.addRunArtifact(zui_tests);

    const test_step = b.step("test", "Run ZUI tests");
    test_step.dependOn(&run_zui_tests.step);
}

fn addPlatformLinks(module: *std.Build.Module, target: std.Build.ResolvedTarget) void {
    switch (target.result.os.tag) {
        .windows => {
            module.linkSystemLibrary("user32", .{});
            module.linkSystemLibrary("kernel32", .{});
        },
        else => {},
    }
}
