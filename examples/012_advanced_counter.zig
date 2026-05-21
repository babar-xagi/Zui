const zui = @import("zui");
const std = @import("std");

var counter = zui.state(i32, 0);

fn CounterFormatter(value: i32, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "{}", .{value}) catch @panic("oom");
}

fn IncrementCounter() void {
    counter.set(counter.get() + 1);
}

fn DecrementCounter() void {
    counter.set(counter.get() - 1);
}

fn ResetCounter() void {
    counter.set(0);
}

fn CounterScreen() zui.Element {
    return zui.column(.{ .padding = 24, .gap = 16 }, .{
        // Title
        zui.t("🔢 Advanced Counter", .{
            .fg = zui.colors.slate_900,
            .size = 28,
            .weight = .bold,
        }),

        // Current count display
        zui.column(.{
            .padding = 24,
            .gap = 8,
            .background = zui.colors.blue_600,
        }, .{
            zui.t("Current Count", .{
                .fg = zui.colors.slate_100,
                .size = 14,
            }),
            zui.styledStateText(i32, &counter, CounterFormatter, .{
                .fg = zui.colors.white,
                .size = 48,
                .weight = .bold,
            }),
        }),

        // Buttons for increment/decrement
        zui.row(.{ .gap = 12 }, .{
            zui.button(.{
                .title = "➖ Decrease",
                .on_click = DecrementCounter,
                .fg = zui.colors.white,
                .bg = zui.colors.rose_600,
                .size = 14,
                .weight = .bold,
            }),
            zui.button(.{
                .title = "➕ Increase",
                .on_click = IncrementCounter,
                .fg = zui.colors.white,
                .bg = zui.colors.emerald_600,
                .size = 14,
                .weight = .bold,
            }),
        }),

        // Reset button
        zui.button(.{
            .title = "🔄 Reset",
            .on_click = ResetCounter,
            .fg = zui.colors.slate_700,
            .bg = zui.colors.slate_100,
        }),

        // Info box
        zui.column(.{
            .padding = 12,
            .gap = 4,
            .background = zui.colors.slate_50,
        }, .{
            zui.t("💡 Tip", .{
                .fg = zui.colors.slate_900,
                .weight = .semibold,
            }),
            zui.text("Click buttons to change the counter value. This demonstrates reactive state management in ZUI!"),
        }),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "ZUI Advanced Counter",
        .root = CounterScreen,
    });
}

