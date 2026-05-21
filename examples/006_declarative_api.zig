const std = @import("std");
const ui = @import("zui");

const Element = ui.Element;
const view = ui.view;
const text = ui.text;
const run = ui.run;

var count = ui.state(i32, 0);

fn countLabel(value: i32, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "Count: {}", .{value}) catch @panic("out of memory");
}

fn increment() void {
    count.set(count.get() + 1);
}

fn decrement() void {
    count.set(count.get() - 1);
}

fn HomeScreen() Element {
    return view(.{
        text("Hello World!"),
        ui.textFmt("Declarative API cleanup phase: {}", .{6}),
        ui.stateText(i32, &count, countLabel),
        ui.row(.{ .gap = 12 }, .{
            ui.button(.{
                .title = "Decrement",
                .on_click = decrement,
            }),
            ui.button(.{
                .title = "Increment",
                .on_click = increment,
            }),
        }),
    });
}

pub fn main() !void {
    try run(.{
        .app_name = "Hello ZUI",
        .root = HomeScreen,
    });
}
