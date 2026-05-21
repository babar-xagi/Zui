# 009 - Layout And Rendering Polish

## What Changed

Improved the first demo and the Win32 renderer so the UI feels less rigid.

Renderer changes:

- Root background now fills the whole client area.
- Text height is estimated from font size and available width.
- Longer text can use multiple lines instead of clipping into one short row.
- Row measurement now uses each child's actual row width.
- Repaint no longer asks Windows to erase the background first, reducing white flash.
- `WM_ERASEBKGND` is handled by ZUI because ZUI paints the root background.

API change:

- Added `ui.styledStateText(...)` for reactive state labels with text style.

Demo changes:

- Updated `examples/first_demo.zig`.
- Live state values are now styled.
- The demo uses a more polished structure: hero, metric card, toolkit card, next-steps card, and action buttons.

## Why

The first demo made the current limits obvious:

- A white area appeared below the app because the root background only painted content height.
- Long text clipped inside cards.
- Live values looked plain because `stateText` could not be styled.
- Repaint could flash because Windows erased the background before ZUI painted.

This phase makes the native renderer more predictable before adding new widgets.

## Text Measurement

Before:

```text
Every text node = fixed height
```

After:

```text
Text height = estimated line count * line height
line count = text length / estimated characters per line
characters per line = available width / estimated character width
```

This is still not a final text engine, but it is much better for demos and real screens.

## Root Background

Before:

```text
Root view background = content height only
Window below content = default white
```

After:

```text
Root view background = full client area
Nested view background = actual used content height
```

This keeps app windows visually complete while avoiding giant stretched cards.

## Styled State Text

Use:

```zig
ui.styledStateText(i32, &focus, focusLabel, .{
    .fg = c.blue_600,
    .size = 18,
    .weight = .bold,
})
```

This keeps reactive labels visually consistent with the rest of the UI.

## How To Run

```powershell
zig build run-first-demo
```

## Verification

Verified with:

```powershell
zig build test
zig build
```

Also smoke-tested:

```powershell
zig-out/bin/zui-first-demo.exe
```

The demo stayed alive for two seconds and closed cleanly.

## Current Limitations

- Text measurement is estimated, not native measured text yet.
- Text wrapping is basic.
- Rows still split width equally.
- There is no alignment API yet.
- Buttons still use standard native Win32 rendering.

## Next

The next useful polish phase is layout control:

- alignment
- per-side spacing
- min/max/fixed sizes
- weighted row children
- native text measurement with `DrawTextW`
