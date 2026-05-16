const std = @import("std");

pub fn run(app: anytype) !void {
    std.debug.print("ZUI app: {s}\n", .{app.app_name});
    app.root.debugPrint(0);
}
