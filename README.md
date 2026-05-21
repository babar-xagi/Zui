# ZUI

ZUI is a new from-scratch cross-platform UI framework written in Zig 0.16.

The goal is a small, fast, native framework with an API that feels easy to learn:

```zig
const ui = @import("zui");

fn HomeScreen() ui.Element {
    return ui.view(.{
        ui.text("Hello World!"),
    });
}

pub fn main() !void {
    try ui.run(.{
        .app_name = "Hello ZUI",
        .root = HomeScreen,
    });
}
```

Capy is used only as reference material. ZUI is not a Capy fork and does not depend on Capy.

## Current Status

ZUI now has a native Win32 backend, text, layout, buttons, a tiny state model, and a cleaner declarative API:

- `ui.Element`
- `ui.view(.{ ... })`
- `ui.text(...)`
- `ui.textFmt(...)`
- `ui.button(.{ .title = "..." })`
- `ui.state(T, initial)`
- `ui.stateText(...)`

Development notes are kept in [docs/development](docs/development).

## Commands

```powershell
zig build test
zig build run
zig build run-button
zig build run-counter
zig build run-declarative
```

On Windows, these commands open native windows. Close the window to end the app.
