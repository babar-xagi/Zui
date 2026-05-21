const std = @import("std");
const zui = @import("zui");

fn onPrimaryClick() void {
    std.debug.print("Primary button clicked from native Win32.\n", .{});
}

fn onSecondaryClick() void {
    std.debug.print("Secondary button clicked from native Win32.\n", .{});
}

fn ButtonScreen() zui.Node {
    return zui.column(.{ .padding = 24, .gap = 12 }, .{
        zui.text("Phase 004: Interactive Button"),
        zui.text("Click a button and watch the terminal output."),
        zui.row(.{ .padding = 0, .gap = 12 }, .{
            zui.button(.{
                .label = "Primary Action",
                .on_click = onPrimaryClick,
            }),
            zui.button(.{
                .label = "Secondary Action",
                .on_click = onSecondaryClick,
            }),
        }),
        zui.button(.{
            .label = "Button without callback",
        }),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "ZUI Button Example",
        .root = ButtonScreen,
    });
}
