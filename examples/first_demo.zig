const std = @import("std");
const ui = @import("zui");

const c = ui.colors;

var focus = ui.state(i32, 72);
var shipped = ui.state(i32, 3);

fn focusLabel(value: i32, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "Focus score: {d}%", .{value}) catch @panic("out of memory");
}

fn shippedLabel(value: i32, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "Shipped demos: {d}", .{value}) catch @panic("out of memory");
}

fn addFocus() void {
    focus.set(@min(100, focus.get() + 6));
}

fn shipDemo() void {
    shipped.set(shipped.get() + 1);
    focus.set(@max(0, focus.get() - 8));
}

fn resetDemo() void {
    focus.set(72);
    shipped.set(3);
}

fn hero() ui.Element {
    return ui.column(.{ .p = 22, .gap = 10, .bg = c.slate_50 }, .{
        ui.t("ZUI Studio", .{ .fg = c.slate_900, .size = 30, .weight = .bold }),
        ui.t("A tiny native app shell built with clean Zig UI code.", .{ .fg = c.slate_700, .size = 16 }),
        ui.row(.{ .gap = 10 }, .{
            ui.t("Native", .{ .fg = c.white, .bg = c.emerald_600, .size = 15, .weight = .semibold }),
            ui.t("Small", .{ .fg = c.white, .bg = c.blue_600, .size = 15, .weight = .semibold }),
            ui.t("Reactive", .{ .fg = c.white, .bg = c.rose_600, .size = 15, .weight = .semibold }),
        }),
    });
}

fn metrics() ui.Element {
    return ui.column(.{ .p = 18, .gap = 10, .bg = c.slate_100 }, .{
        ui.t("Live project pulse", .{ .fg = c.slate_900, .size = 20, .weight = .semibold }),
        ui.styledStateText(i32, &focus, focusLabel, .{ .fg = c.blue_600, .size = 18, .weight = .bold }),
        ui.styledStateText(i32, &shipped, shippedLabel, .{ .fg = c.emerald_600, .size = 18, .weight = .bold }),
        ui.t("Buttons below update these native text controls in place.", .{ .fg = c.slate_700, .size = 14 }),
    });
}

fn toolkit() ui.Element {
    return ui.column(.{ .p = 18, .m = 4, .gap = 10, .bg = c.slate_50 }, .{
        ui.t("Toolkit snapshot", .{ .fg = c.slate_900, .size = 20, .weight = .semibold }),
        ui.row(.{ .gap = 10 }, .{
            ui.t("Layout", .{ .fg = c.white, .bg = c.blue_600, .size = 15 }),
            ui.t("Style", .{ .fg = c.white, .bg = c.emerald_600, .size = 15 }),
            ui.t("State", .{ .fg = c.white, .bg = c.amber_500, .size = 15 }),
        }),
        ui.t("Column, row, styled text, buttons, colors, and reactive labels are all native.", .{ .fg = c.slate_700, .size = 15 }),
    });
}

fn nextSteps() ui.Element {
    return ui.column(.{ .p = 18, .gap = 8, .bg = c.slate_50 }, .{
        ui.t("Next polish targets", .{ .fg = c.slate_900, .size = 20, .weight = .semibold }),
        ui.t("Text input, alignment, per-side spacing, and custom button drawing.", .{ .fg = c.slate_700, .size = 15 }),
    });
}

fn actions() ui.Element {
    return ui.row(.{ .m = 4, .gap = 12 }, .{
        ui.button(.{ .title = "Add focus", .on_click = addFocus, .size = 16, .weight = .semibold }),
        ui.button(.{ .title = "Ship demo", .on_click = shipDemo, .size = 16, .weight = .semibold }),
        ui.button(.{ .title = "Reset", .on_click = resetDemo, .size = 16 }),
    });
}

fn App() ui.Element {
    return ui.column(.{ .p = 24, .gap = 14, .bg = c.slate_900 }, .{
        hero(),
        ui.row(.{ .gap = 14 }, .{
            metrics(),
            toolkit(),
        }),
        nextSteps(),
        actions(),
    });
}

pub fn main() !void {
    try ui.run(.{
        .app_name = "ZUI Studio Demo",
        .root = App,
    });
}
