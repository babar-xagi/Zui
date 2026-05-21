# 008 - First Demo App

## What Changed

Added the first polished ZUI demo app:

- `examples/first_demo.zig`

Added a direct run command:

```powershell
zig build run-first-demo
```

## Why

After the first styling pass, ZUI needed a small showcase that uses the current framework pieces together:

- native window
- `column`
- `row`
- styled text through `ui.t`
- colors
- padding, margin, gap, background
- buttons
- reactive state text

The goal is not to fake a design system. The goal is to show the best UI ZUI can make honestly with the primitives that exist today.

## App Shape

The demo is a compact dashboard:

```text
Column bg=slate_900 p=24
+-- Hero card
|   +-- Title
|   +-- Subtitle
|   +-- Status labels
+-- Row
|   +-- Live project pulse card
|   +-- Feature summary card
+-- Action buttons
```

## Code Style

The demo uses short aliases without hiding Zig:

```zig
const ui = @import("zui");
const c = ui.colors;
```

Styled text stays compact:

```zig
ui.t("ZUI First Demo", .{
    .fg = c.slate_900,
    .size = 28,
    .weight = .bold,
})
```

Layout stays predictable:

```zig
ui.column(.{ .p = 24, .gap = 14, .bg = c.slate_900 }, .{
    hero(),
    metrics(),
    actions(),
})
```

## State

The demo includes two pieces of state:

```zig
var focus = ui.state(i32, 72);
var shipped = ui.state(i32, 3);
```

Buttons update the state:

```zig
fn addFocus() void {
    focus.set(@min(100, focus.get() + 6));
}
```

Visible state text updates through native text controls:

```zig
ui.stateText(i32, &focus, focusLabel)
```

## How To Run

```powershell
zig build run-first-demo
```

Try the buttons:

- `Add focus`
- `Ship demo`
- `Reset`

The numbers in the live project pulse card should update.

## Verification

Use:

```powershell
zig build test
zig build
```

Manual GUI check:

```powershell
zig build run-first-demo
```

## Current Limitations Visible In The Demo

- Buttons are still native Win32 buttons, so their colors are system controlled.
- Text does not wrap yet, so labels stay intentionally short.
- Cards are rectangular because borders and radius are not implemented yet.
- `stateText` cannot be styled directly yet, so it is placed on light cards.

## Next

The next useful improvement is a small layout/style refinement phase:

- text wrapping
- per-side spacing
- alignment
- direct styled state text
