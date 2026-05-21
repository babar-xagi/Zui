# 003 - Basic Layout

## What Changed

Added the first explicit layout API:

- `zui.column(...)`
- `zui.row(...)`
- `LayoutDirection`
- `ViewStyle.direction`

Updated the Win32 backend so it:

- creates native text controls once
- stores those controls in backend state
- lays them out separately from creation
- handles `WM_SIZE`
- relayouts controls when the native window is resized

Updated:

- `src/zui.zig`
- `src/backends/win32.zig`
- `examples/hello.zig`
- `README.md`

## Why

Before this step, every `view` stacked children vertically and controls were positioned only once.

That proved rendering, but a UI framework needs layout concepts. This milestone introduces the two most important primitives:

- `column`: stack children top to bottom
- `row`: place children left to right

It also separates control creation from layout. That matters because native windows can resize, and resize needs to move existing controls instead of recreating them.

## How The Frontend API Works

The example now uses `column` and `row`:

```zig
fn HomeScreen() zui.Node {
    return zui.column(.{ .padding = 24, .gap = 12 }, .{
        zui.text("Hello World Well Come to the ZUI!"),
        zui.text("Column layout stacks these text nodes vertically."),
        zui.row(.{ .padding = 12, .gap = 12 }, .{
            zui.text("Row item A"),
            zui.text("Row item B"),
            zui.text("Row item C"),
        }),
        zui.column(.{ .padding = 12, .gap = 6 }, .{
            zui.text("Nested columns still work."),
            zui.text("Resize the window to trigger relayout."),
        }),
    });
}
```

`zui.column(style, children)` is a convenience wrapper around `zui.view`:

```zig
pub fn column(style: ViewStyle, children: anytype) Node {
    var column_style = style;
    column_style.direction = .column;
    return view(column_style, children);
}
```

`zui.row(style, children)` does the same but sets `.direction = .row`.

## Layout Diagram

The current example creates this logical layout:

```text
Column padding=24 gap=12
+-- Text "Hello World Well Come to the ZUI!"
+-- Text "Column layout stacks these text nodes vertically."
+-- Row padding=12 gap=12
|   +-- Text "Row item A"
|   +-- Text "Row item B"
|   +-- Text "Row item C"
+-- Column padding=12 gap=6
    +-- Text "Nested columns still work."
    +-- Text "Resize the window to trigger relayout."
```

Approximate screen layout:

```text
+-------------------------------------------------------+
| padding 24                                            |
| Text: Hello World Well Come to the ZUI!               |
| gap 12                                                |
| Text: Column layout stacks these text nodes vertically.|
| gap 12                                                |
| Row padding 12                                        |
| +-------------+  gap 12  +-------------+  gap 12       |
| | Row item A  |          | Row item B  |          ...  |
| +-------------+          +-------------+               |
| gap 12                                                |
| Nested Column padding 12                              |
| Text: Nested columns still work.                      |
| gap 6                                                 |
| Text: Resize the window to trigger relayout.          |
+-------------------------------------------------------+
```

## How The Win32 Backend Works

The backend now has two separate phases.

### 1. Create Controls

The backend walks the tree and creates one Win32 `STATIC` control for each text node.

```text
createTextControlsForNode(node)
  if Text:
      CreateWindowExW("STATIC", ...)
      save HWND in text_controls

  if View:
      recurse into children
```

### 2. Layout Controls

The backend walks the same tree again and moves controls into place.

```text
layoutNode(node, rect)
  if Text:
      MoveWindow(text_hwnd, rect)

  if Column:
      stack children vertically

  if Row:
      split available width across children
```

This is why resize can work:

```text
WM_SIZE
  +-- read backend state from GWLP_USERDATA
  +-- compute new client rect
  +-- layout existing controls with MoveWindow
```

## How To Use It

Use `column` for vertical layout:

```zig
zui.column(.{ .padding = 16, .gap = 8 }, .{
    zui.text("Top"),
    zui.text("Bottom"),
})
```

Use `row` for horizontal layout:

```zig
zui.row(.{ .padding = 16, .gap = 8 }, .{
    zui.text("Left"),
    zui.text("Center"),
    zui.text("Right"),
})
```

Run:

```powershell
zig build run
```

Then resize the window. The existing native text controls should move and resize.

## Verification

Verified with:

```powershell
zig build test
zig build
```

`zig build run` opens a GUI window and should be run manually because it blocks until the window closes.

## Limitations

- Row children are split into equal widths.
- Text still has fixed height.
- There is no wrapping.
- `view` is still logical only.
- No background, border, or visual container drawing yet.
- No buttons or input controls yet.

## Next

The next useful milestone is interactive controls:

- add `zui.button`
- create native Win32 button controls
- wire click events
- build a small counter example
