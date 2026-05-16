const zui = @import("zui");

fn HomeScreen() zui.Node {
    return zui.view(.{ .padding = 24, .gap = 10 }, .{
        zui.text("Hello World Well Come to the ZUI!"),
        zui.text("This is rendered from multiple ZUI text nodes."),
        zui.view(.{ .padding = 24, .gap = 10 }, .{
            zui.text("Nested views can contribute text too."),
            zui.text("Next step: richer layout and controls."),
        }),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "Hello ZUI",
        .root = HomeScreen,
    });
}
