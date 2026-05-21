# 004 - Interactive Button

## What Changed

Added the first interactive ZUI control:

- `zui.button(...)`
- `ButtonOptions`
- `ButtonNode`
- `ClickHandler`
- native Win32 `BUTTON` controls
- Win32 click dispatch through `WM_COMMAND`

Added a new phase example:

- `examples/004_interactive_button.zig`

Added a new build command:

```powershell
zig build run-button
```

The earlier `examples/hello.zig` file was left unchanged.

## Why

Text and layout prove that ZUI can describe and display a native UI tree.

This phase proves the next important idea: user code can attach behavior to UI nodes, and the backend can call that behavior from a real native platform event.

This is still intentionally small. We do not have state updates yet. For now, clicking a button runs a Zig callback.

## Frontend Example

```zig
const std = @import("std");
const zui = @import("zui");

fn onPrimaryClick() void {
    std.debug.print("Primary button clicked from native Win32.\n", .{});
}

fn ButtonScreen() zui.Node {
    return zui.column(.{ .padding = 24, .gap = 12 }, .{
        zui.text("Phase 004: Interactive Button"),
        zui.button(.{
            .label = "Primary Action",
            .on_click = onPrimaryClick,
        }),
    });
}
```

The beginner-facing idea is:

```text
button options
+-- label: what the user sees
+-- on_click: what ZUI calls after a native click
```

## UI Tree Diagram

The new example builds this tree:

```text
Column padding=24 gap=12
+-- Text "Phase 004: Interactive Button"
+-- Text "Click a button and watch the terminal output."
+-- Row gap=12
|   +-- Button "Primary Action"
|   +-- Button "Secondary Action"
+-- Button "Button without callback"
```

Screen shape:

```text
+--------------------------------------------------+
| Phase 004: Interactive Button                    |
| Click a button and watch the terminal output.    |
|                                                  |
| +----------------+   +------------------+         |
| | Primary Action |   | Secondary Action |         |
| +----------------+   +------------------+         |
|                                                  |
| +--------------------------------------+           |
| | Button without callback              |           |
| +--------------------------------------+           |
+--------------------------------------------------+
```

## How The Core API Works

The public callback type is small:

```zig
pub const ClickHandler = *const fn () void;
```

Button options hold the visible label and optional callback:

```zig
pub const ButtonOptions = struct {
    label: []const u8,
    on_click: ?ClickHandler = null,
};
```

`zui.button(...)` creates a new `Node.button` variant:

```zig
pub fn button(options: ButtonOptions) Node {
    return .{
        .button = .{
            .label = options.label,
            .on_click = options.on_click,
        },
    };
}
```

That means button is now a normal part of the UI tree, just like text and view.

## How The Win32 Backend Works

The backend now creates one native control for each leaf UI node:

```text
Text node   -> Win32 STATIC control
Button node -> Win32 BUTTON control
View node   -> logical layout only
```

When creating a button, ZUI assigns it a small native command ID:

```text
Button "Primary Action"
+-- CreateWindowExW("BUTTON", ...)
+-- command id = 1000 + control_index
+-- save on_click callback beside the HWND
```

When Windows sends a click event:

```text
WM_COMMAND
+-- check notification is BN_CLICKED
+-- read command id from wParam
+-- find matching ZUI button control
+-- call the Zig on_click function
```

So the click travels like this:

```text
Native button click
  -> Win32 WM_COMMAND
  -> ZUI backend state
  -> saved ButtonNode callback
  -> user Zig function
```

## How To Use It

Create a callback:

```zig
fn saveClicked() void {
    std.debug.print("Save clicked.\n", .{});
}
```

Attach it to a button:

```zig
zui.button(.{
    .label = "Save",
    .on_click = saveClicked,
})
```

A button can also have no callback:

```zig
zui.button(.{
    .label = "Coming Soon",
})
```

Run the phase example:

```powershell
zig build run-button
```

Click the buttons and watch the terminal. The first two buttons print messages. The third button has no callback, so it does nothing.

## Verification

Use:

```powershell
zig build test
zig build
```

Manual GUI check:

```powershell
zig build run-button
```

## Limitations

- Callbacks do not receive event data yet.
- Callbacks cannot capture local variables.
- There is no `state(...)` API yet, so button clicks do not update text on screen.
- There is no disabled button style yet.
- Keyboard focus behavior is still platform default.

## Next

The next phase should add the first simple state primitive or a text input control.

My preference is state first:

- build `zui.state`
- make a counter example
- let a button click change visible text

That will make ZUI feel much closer to React Native, Flutter, or SwiftUI while still staying native and tiny.
