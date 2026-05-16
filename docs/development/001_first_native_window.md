# 001 - First Native Window

## What Changed

Added the first backend boundary and a Win32 implementation.

Added:

- `src/backend.zig`
- `src/backends/debug.zig`
- `src/backends/win32.zig`

Updated:

- `src/zui.zig`
- `build.zig`
- `README.md`

## Why

Milestone 0 proved that the package, example, and tests work. Milestone 1 starts the real framework: `zui.run` now delegates to a platform backend instead of only printing a debug tree.

Win32 is the first backend because the current development machine is Windows and Zig can call Win32 APIs directly without adding dependencies.

## How The Code Works

`src/backend.zig` chooses a backend at compile time:

```zig
const native_backend = switch (builtin.os.tag) {
    .windows => @import("backends/win32.zig"),
    else => @import("backends/debug.zig"),
};
```

On Windows, `src/backends/win32.zig`:

- registers a `ZUIWindowClass`
- creates an overlapped native Win32 window
- stores a small `WindowState` pointer in `GWLP_USERDATA`
- handles `WM_PAINT`
- draws the first text node using `DrawTextW`
- handles `WM_DESTROY` by posting quit
- runs the standard `GetMessageW` event loop

`src/zui.zig` still owns the public API and tree construction. It now extracts the first text from the root node:

```zig
try backend.run(.{
    .app_name = options.app_name,
    .root_text = root_node.firstText() orelse options.app_name,
    .root = root_node,
});
```

For non-Windows platforms, `src/backends/debug.zig` keeps the old debug-tree behavior. This lets the package stay buildable while platform backends are added one by one.

`build.zig` links `user32` and `kernel32` when the target OS is Windows:

```zig
module.linkSystemLibrary("user32", .{});
module.linkSystemLibrary("kernel32", .{});
```

## How To Use It

Example app:

```zig
const zui = @import("zui");

fn HomeScreen() zui.Node {
    return zui.view(.{ .padding = 16, .gap = 8 }, .{
        zui.text("Hello World!"),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "Hello ZUI",
        .root = HomeScreen,
    });
}
```

Run it:

```powershell
zig build run
```

On Windows this opens a native window titled `Hello ZUI` and draws `Hello World!` in the client area. Close the window to end the app.

## Verification

Verified with:

```powershell
zig build test
zig build
```

`zig build` confirms that the native example compiles and links. `zig build run` is intentionally not run by automation here because it opens a GUI window and blocks until the window is closed.

## Limitations

- Only the first text node is rendered.
- There is no real layout yet.
- The Win32 declarations are intentionally minimal.
- No buttons, inputs, state updates, or reconciliation yet.
- Window size is fixed at creation time to `800x600`.

## Next

Milestone 2 turns the UI tree into real backend nodes:

- create backend peers for `view` and `text`
- render multiple text children
- start a minimal layout pass
- keep Win32 code behind the backend interface
