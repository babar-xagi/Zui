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
        ui.t("ZUI First Demo", .{ .fg = c.slate_900, .size = 28, .weight = .bold }),
        ui.t("Tiny Zig code. Native controls. Reactive state.", .{ .fg = c.slate_700, .size = 16 }),
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
        ui.stateText(i32, &focus, focusLabel),
        ui.stateText(i32, &shipped, shippedLabel),
        ui.t("Buttons below update these native text controls.", .{ .fg = c.slate_700, .size = 14 }),
    });
}

fn roadmap() ui.Element {
    return ui.column(.{ .p = 18, .m = 4, .gap = 10, .bg = c.slate_50 }, .{
        ui.t("What this demo uses", .{ .fg = c.slate_900, .size = 20, .weight = .semibold }),
        ui.row(.{ .gap = 10 }, .{
            ui.t("Layout", .{ .fg = c.white, .bg = c.blue_600, .size = 15 }),
            ui.t("Style", .{ .fg = c.white, .bg = c.emerald_600, .size = 15 }),
            ui.t("State", .{ .fg = c.white, .bg = c.amber_500, .size = 15 }),
        }),
        ui.t("The screen is built from column, row, text, button, colors, and state.", .{ .fg = c.slate_700, .size = 15 }),
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
            roadmap(),
        }),
        actions(),
    });
}

pub fn main() !void {
    try ui.run(.{
        .app_name = "ZUI First Demo",
        .root = App,
    });
}
