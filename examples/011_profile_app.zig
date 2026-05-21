const zui = @import("zui");

fn ProfileScreen() zui.Element {
    return zui.column(.{ .padding = 16, .gap = 12 }, .{
        // Header
        zui.column(.{ .padding = 12, .gap = 8, .background = zui.colors.blue_600 }, .{
            zui.t("👤 Profile", .{
                .fg = zui.colors.white,
                .size = 20,
                .weight = .bold,
            }),
        }),

        // Card 1: User Info
        zui.column(.{ .padding = 12, .gap = 6, .background = zui.colors.slate_50 }, .{
            zui.t("Name", .{ .fg = zui.colors.slate_700, .size = 12 }),
            zui.text("Jane Developer"),
        }),

        // Card 2: Stats
        zui.row(.{ .gap = 12 }, .{
            zui.column(.{ .padding = 12, .gap = 4, .background = zui.colors.emerald_600 }, .{
                zui.t("42", .{ .fg = zui.colors.white, .weight = .bold }),
                zui.t("Projects", .{ .fg = zui.colors.white, .size = 12 }),
            }),
            zui.column(.{ .padding = 12, .gap = 4, .background = zui.colors.blue_600 }, .{
                zui.t("128", .{ .fg = zui.colors.white, .weight = .bold }),
                zui.t("Stars", .{ .fg = zui.colors.white, .size = 12 }),
            }),
            zui.column(.{ .padding = 12, .gap = 4, .background = zui.colors.amber_500 }, .{
                zui.t("15", .{ .fg = zui.colors.white, .weight = .bold }),
                zui.t("Followers", .{ .fg = zui.colors.white, .size = 12 }),
            }),
        }),

        // Divider
        zui.text("─────────────────────"),

        // Settings
        zui.column(.{ .gap = 12 }, .{
            zui.button(.{
                .title = "⚙️ Edit Profile",
                .fg = zui.colors.blue_600,
                .size = 14,
            }),
            zui.button(.{
                .title = "🔐 Change Password",
                .fg = zui.colors.blue_600,
                .size = 14,
            }),
            zui.button(.{
                .title = "🚪 Logout",
                .fg = zui.colors.rose_600,
                .size = 14,
            }),
        }),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "ZUI Profile",
        .root = ProfileScreen,
    });
}

