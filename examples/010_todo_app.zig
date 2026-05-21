const zui = @import("zui");

fn TodoApp() zui.Element {
    return zui.column(.{ .padding = 16, .gap = 12 }, .{
        zui.t("📝 Todo List", .{
            .fg = zui.colors.slate_900,
            .size = 24,
            .weight = .bold,
        }),
        zui.row(.{ .gap = 8 }, .{
            zui.button(.{
                .title = "✓ Learn Zig",
                .fg = zui.colors.white,
                .bg = zui.colors.emerald_600,
            }),
        }),
        zui.row(.{ .gap = 8 }, .{
            zui.button(.{
                .title = "✓ Build ZUI",
                .fg = zui.colors.white,
                .bg = zui.colors.emerald_600,
            }),
        }),
        zui.row(.{ .gap = 8 }, .{
            zui.button(.{
                .title = "○ Deploy App",
                .fg = zui.colors.slate_700,
                .bg = zui.colors.slate_100,
            }),
        }),
        zui.column(.{ .padding = 12, .gap = 8, .background = zui.colors.slate_50 }, .{
            zui.t("📊 Progress", .{
                .fg = zui.colors.slate_700,
                .size = 14,
                .weight = .semibold,
            }),
            zui.text("2 of 3 tasks completed (67%)"),
        }),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "ZUI Todo App",
        .root = TodoApp,
    });
}

