# ZUI

ZUI is a new from-scratch cross-platform UI framework written in Zig 0.16.

The goal is a small, fast, native framework with an API that feels easy to learn:

```zig
const zui = @import("zui");

fn HomeScreen() zui.Node {
    return zui.view(.{}, .{
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

Capy is used only as reference material. ZUI is not a Capy fork and does not depend on Capy.

## Current Status

Milestone 2 is underway. ZUI now has a first Win32 backend that opens a native window and turns multiple `zui.text` nodes into native Win32 `STATIC` controls.

Development notes are kept in [docs/development](docs/development).

## Commands

```powershell
zig build test
zig build run
```

On Windows, `zig build run` opens a native window with the text nodes from `examples/hello.zig`. Close the window to end the app.
