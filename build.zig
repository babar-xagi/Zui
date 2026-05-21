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

    const interactive_button = b.addExecutable(.{
        .name = "zui-004-interactive-button",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/004_interactive_button.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
            },
        }),
    });
    addPlatformLinks(interactive_button.root_module, target);
    b.installArtifact(interactive_button);

    const run_interactive_button = b.addRunArtifact(interactive_button);
    run_interactive_button.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_interactive_button.addArgs(args);
    }

    const run_button_step = b.step("run-button", "Run the phase 004 interactive button example");
    run_button_step.dependOn(&run_interactive_button.step);

    const state_counter = b.addExecutable(.{
        .name = "zui-005-state-counter",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/005_state_counter.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
            },
        }),
    });
    addPlatformLinks(state_counter.root_module, target);
    b.installArtifact(state_counter);

    const run_state_counter = b.addRunArtifact(state_counter);
    run_state_counter.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_state_counter.addArgs(args);
    }

    const run_counter_step = b.step("run-counter", "Run the phase 005 state counter example");
    run_counter_step.dependOn(&run_state_counter.step);

    const declarative_api = b.addExecutable(.{
        .name = "zui-006-declarative-api",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/006_declarative_api.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
            },
        }),
    });
    addPlatformLinks(declarative_api.root_module, target);
    b.installArtifact(declarative_api);

    const run_declarative_api = b.addRunArtifact(declarative_api);
    run_declarative_api.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_declarative_api.addArgs(args);
    }

    const run_declarative_step = b.step("run-declarative", "Run the phase 006 declarative API example");
    run_declarative_step.dependOn(&run_declarative_api.step);

    const essential_styling = b.addExecutable(.{
        .name = "zui-007-essential-styling",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/007_essential_styling.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
            },
        }),
    });
    addPlatformLinks(essential_styling.root_module, target);
    b.installArtifact(essential_styling);

    const run_essential_styling = b.addRunArtifact(essential_styling);
    run_essential_styling.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_essential_styling.addArgs(args);
    }

    const run_styling_step = b.step("run-styling", "Run the phase 007 essential styling example");
    run_styling_step.dependOn(&run_essential_styling.step);

    const first_demo = b.addExecutable(.{
        .name = "zui-first-demo",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/first_demo.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
            },
        }),
    });
    addPlatformLinks(first_demo.root_module, target);
    b.installArtifact(first_demo);

    const run_first_demo = b.addRunArtifact(first_demo);
    run_first_demo.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_first_demo.addArgs(args);
    }

    const run_first_demo_step = b.step("run-first-demo", "Run the first polished ZUI demo app");
    run_first_demo_step.dependOn(&run_first_demo.step);

    // Todo App - Example 010
    const todo_app = b.addExecutable(.{
        .name = "zui-010-todo-app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/010_todo_app.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
            },
        }),
    });
    addPlatformLinks(todo_app.root_module, target);
    b.installArtifact(todo_app);

    const run_todo_app = b.addRunArtifact(todo_app);
    run_todo_app.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_todo_app.addArgs(args);
    }

    const run_todo_step = b.step("run-todo", "Run the todo app example");
    run_todo_step.dependOn(&run_todo_app.step);

    // Profile App - Example 011
    const profile_app = b.addExecutable(.{
        .name = "zui-011-profile-app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/011_profile_app.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
            },
        }),
    });
    addPlatformLinks(profile_app.root_module, target);
    b.installArtifact(profile_app);

    const run_profile_app = b.addRunArtifact(profile_app);
    run_profile_app.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_profile_app.addArgs(args);
    }

    const run_profile_step = b.step("run-profile", "Run the profile app example");
    run_profile_step.dependOn(&run_profile_app.step);

    // Advanced Counter - Example 012
    const advanced_counter = b.addExecutable(.{
        .name = "zui-012-advanced-counter",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/012_advanced_counter.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zui", .module = zui_mod },
            },
        }),
    });
    addPlatformLinks(advanced_counter.root_module, target);
    b.installArtifact(advanced_counter);

    const run_advanced_counter = b.addRunArtifact(advanced_counter);
    run_advanced_counter.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_advanced_counter.addArgs(args);
    }

    const run_advanced_counter_step = b.step("run-advanced-counter", "Run the advanced counter example");
    run_advanced_counter_step.dependOn(&run_advanced_counter.step);

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
            module.linkSystemLibrary("gdi32", .{});
        },
        else => {},
    }
}
