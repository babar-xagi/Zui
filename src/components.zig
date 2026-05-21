/// ZUI Components - React Native inspired components
const std = @import("std");
const zui = @import("zui.zig");

/// SafeAreaView - Container that respects device safe areas
/// Currently just creates a column with padding
pub fn SafeAreaView(padding: u16) zui.Element {
    return zui.view(.{});
}

/// ScrollView - Vertically scrollable container
/// Currently just creates a column
pub fn ScrollView() zui.Element {
    return zui.view(.{});
}

/// TouchableOpacity - Interactive pressable component
pub fn TouchableOpacity(title: []const u8, on_click: zui.ClickHandler) zui.Element {
    return zui.button(.{
        .title = title,
        .on_click = on_click,
    });
}

/// Image - Display images (placeholder)
pub fn Image(source: []const u8) zui.Element {
    return zui.text(source);
}

/// TextInput - Text input field (placeholder)
pub fn TextInput(placeholder: []const u8) zui.Element {
    return zui.text(placeholder);
}

/// Spacer - Empty space component
pub fn Spacer() zui.Element {
    return zui.text("");
}

/// ActivityIndicator - Loading spinner
pub fn ActivityIndicator() zui.Element {
    return zui.text("⏳");
}

/// Divider - Visual separator
pub fn Divider() zui.Element {
    return zui.text("━━━━━");
}

/// Badge - Small notification badge
pub fn Badge(value: []const u8, bg_color: zui.Color) zui.Element {
    return zui.t(value, .{
        .bg = bg_color,
        .size = 12,
    });
}

/// Helper: Create a card with styling
pub fn Card(bg_color: zui.Color) zui.ViewStyle {
    return .{
        .padding = 12,
        .background = bg_color,
    };
}

/// Helper: Create a header with styling
pub fn HeaderStyle() zui.ViewStyle {
    return .{
        .padding = 12,
        .background = zui.colors.blue_600,
    };
}



