const std = @import("std");
const ui = @import("zui");

const c = ui.colors;

fn primaryClicked() void {
    std.debug.print("Styled primary button clicked.\n", .{});
}

fn StyleScreen() ui.Element {
    return ui.column(.{
        .p = 24,
        .gap = 14,
        .bg = c.slate_900,
    }, .{
        ui.t("Phase 007: Clean Native Styling", .{ .fg = c.white, .size = 26, .weight = .bold }),
        ui.t("Short code, inherited backgrounds, safer layout, native controls.", .{ .fg = c.slate_100, .size = 16 }),
        ui.column(.{
            .p = 18,
            .m = 8,
            .gap = 10,
            .bg = c.slate_50,
        }, .{
            ui.t("Styled card area", .{ .fg = c.slate_900, .size = 20, .weight = .semibold }),
            ui.t("Text now inherits the card background instead of turning into white bars.", .{ .fg = c.slate_700, .size = 15 }),
            ui.t("Blue text background", .{ .fg = c.white, .bg = c.blue_600, .size = 16, .weight = .medium }),
        }),
        ui.row(.{
            .m = 8,
            .gap = 12,
        }, .{
            ui.button(.{
                .title = "Primary",
                .on_click = primaryClicked,
                .size = 16,
                .weight = .semibold,
            }),
            ui.button(.{
                .title = "Secondary",
                .size = 16,
            }),
        }),
    });
}

pub fn main() !void {
    try ui.run(.{
        .app_name = "ZUI Essential Styling",
        .root = StyleScreen,
    });
}
