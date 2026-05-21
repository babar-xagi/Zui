const zui = @import("zui");

fn HomeScreen() zui.Node {
    return zui.column(.{ .padding = 24, .gap = 12 }, .{
        zui.text("Hello World Well Come to the ZUI!"),
        zui.text("Column layout stacks these text nodes vertically."),
        zui.row(.{ .padding = 12, .gap = 12 }, .{
            zui.text("Row item A"),
            zui.text("Row item B"),
            zui.text("Row item C"),
        }),
        zui.column(.{ .padding = 12, .gap = 6 }, .{
            zui.text("Nested columns still work."),
            zui.text("Resize the window to trigger relayout."),
        }),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "Hello ZUI",
        .root = HomeScreen,
    });
}
