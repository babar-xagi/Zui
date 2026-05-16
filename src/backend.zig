const builtin = @import("builtin");

const native_backend = switch (builtin.os.tag) {
    .windows => @import("backends/win32.zig"),
    else => @import("backends/debug.zig"),
};

pub const run = native_backend.run;
