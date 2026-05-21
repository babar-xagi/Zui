# 005 - State Counter

## What Changed

Added the first small state model:

- `zui.State(T)`
- `State(T).init(initial)`
- `state.get()`
- `state.set(value)`
- `zui.stateText(T, &state, formatter)`
- `zui.invalidate()`

Updated the Win32 backend so existing native text controls can be refreshed with `SetWindowTextW`.

Added a new phase example:

- `examples/005_state_counter.zig`

Added a new build command:

```powershell
zig build run-counter
```

The previous examples were left unchanged.

## Why

Phase 004 proved that a button click can call Zig code.

This phase proves the next layer: a button click can change state, and state can update visible UI.

This is a major idea for ZUI because the framework should feel easy like React Native, Flutter, SwiftUI, or FastAPI-style app code, while still staying native and tiny.

## Frontend Example

```zig
const std = @import("std");
const zui = @import("zui");

var count = zui.State(i32).init(0);

fn countLabel(value: i32, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "Count: {}", .{value}) catch @panic("out of memory");
}

fn increment() void {
    count.set(count.get() + 1);
}

fn CounterScreen() zui.Node {
    return zui.column(.{ .padding = 24, .gap = 12 }, .{
        zui.text("Phase 005: State Counter"),
        zui.stateText(i32, &count, countLabel),
        zui.button(.{
            .label = "+1",
            .on_click = increment,
        }),
    });
}
```

The important beginner mental model:

```text
State holds data
+-- stateText displays that data
+-- button changes that data
+-- ZUI refreshes the native text control
```

## UI Tree Diagram

The new counter example builds this tree:

```text
Column padding=24 gap=12
+-- Text "Phase 005: State Counter"
+-- Text "Buttons can now update visible native text."
+-- StateText count -> "Count: 0"
+-- Row gap=12
|   +-- Button "-1"
|   +-- Button "+1"
|   +-- Button "Reset"
```

Screen shape:

```text
+------------------------------------------------+
| Phase 005: State Counter                       |
| Buttons can now update visible native text.    |
| Count: 0                                       |
|                                                |
| +------+   +------+   +--------+               |
| | -1   |   | +1   |   | Reset  |               |
| +------+   +------+   +--------+               |
+------------------------------------------------+
```

## How The State API Works

Create state:

```zig
var count = zui.State(i32).init(0);
```

Read state:

```zig
count.get()
```

Update state:

```zig
count.set(count.get() + 1);
```

When `set` runs, ZUI calls `invalidate()`. If an app window is active, the backend refreshes dynamic text controls.

## How Dynamic Text Works

`zui.stateText` binds a piece of state to a formatter:

```zig
zui.stateText(i32, &count, countLabel)
```

The formatter turns the raw value into visible text:

```zig
fn countLabel(value: i32, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "Count: {}", .{value}) catch @panic("out of memory");
}
```

This keeps the frontend code explicit:

```text
state value: 3
+-- formatter
    +-- "Count: 3"
```

## How The Win32 Backend Refreshes

The backend now keeps a lightweight active window refresh hook.

When a button changes state:

```text
Button click
  -> user callback
  -> count.set(...)
  -> zui.invalidate()
  -> backend refresh
  -> stateText formatter runs again
  -> SetWindowTextW updates the native STATIC control
```

The important detail: ZUI does not destroy and recreate the whole window for this phase. It updates the existing native text control.

## How To Use It

Run:

```powershell
zig build run-counter
```

Click:

- `+1` to increment
- `-1` to decrement
- `Reset` to return to zero

The `Count: ...` text should update inside the native window.

## Verification

Use:

```powershell
zig build test
zig build
```

Manual GUI check:

```powershell
zig build run-counter
```

## Limitations

- `State` is single-threaded and minimal.
- `stateText` currently needs a formatter function.
- Callbacks still cannot capture local variables.
- Refresh only updates dynamic text controls.
- There is no diffing/reconciliation yet.
- Repeated dynamic text refreshes use the current backend arena; a later phase should add a refresh scratch allocator.

## Next

The next useful phase is text input:

- add `zui.textInput`
- create native Win32 `EDIT` controls
- read user-entered text
- support change callbacks

After that, ZUI will have text, layout, buttons, state, and input: enough to build a tiny form app.
