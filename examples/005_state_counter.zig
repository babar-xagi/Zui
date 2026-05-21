const std = @import("std");
const zui = @import("zui");

var count = zui.State(i32).init(0);

fn countLabel(value: i32, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "Count: {}", .{value}) catch @panic("out of memory");
}

fn decrement() void {
    count.set(count.get() - 1);
}

fn increment() void {
    count.set(count.get() + 1);
}

fn reset() void {
    count.set(0);
}

fn CounterScreen() zui.Node {
    return zui.column(.{ .padding = 24, .gap = 12 }, .{
        zui.text("Phase 005: State Counter"),
        zui.text("Buttons can now update visible native text."),
        zui.stateText(i32, &count, countLabel),
        zui.row(.{ .padding = 0, .gap = 12 }, .{
            zui.button(.{
                .label = "-1",
                .on_click = decrement,
            }),
            zui.button(.{
                .label = "+1",
                .on_click = increment,
            }),
            zui.button(.{
                .label = "Reset",
                .on_click = reset,
            }),
        }),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "ZUI State Counter",
        .root = CounterScreen,
    });
}
