# Basic Layout Explained

This document explains the current ZUI layout API: `view`, `column`, and `row`.

## Layout Functions

ZUI currently has three container helpers.

```zig
zui.view(style, children)
zui.column(style, children)
zui.row(style, children)
```

`view` is the generic container. By default it behaves like a column.

`column` stacks children vertically.

`row` places children horizontally.

## Style

The current style is intentionally small:

```zig
pub const ViewStyle = struct {
    gap: u16 = 0,
    padding: u16 = 0,
    direction: LayoutDirection = .column,
};
```

Meaning:

- `padding`: space inside the container.
- `gap`: space between children.
- `direction`: `.column` or `.row`.

Most users should call `zui.column` and `zui.row` instead of setting `direction` manually.

## Column Example

```zig
zui.column(.{ .padding = 16, .gap = 8 }, .{
    zui.text("First"),
    zui.text("Second"),
    zui.text("Third"),
})
```

Diagram:

```text
Column padding=16 gap=8
+-- Text "First"
+-- gap 8
+-- Text "Second"
+-- gap 8
+-- Text "Third"
```

## Row Example

```zig
zui.row(.{ .padding = 16, .gap = 8 }, .{
    zui.text("Left"),
    zui.text("Center"),
    zui.text("Right"),
})
```

Diagram:

```text
Row padding=16 gap=8
+-- Text "Left" -- gap -- Text "Center" -- gap -- Text "Right"
```

The current Win32 backend gives row children equal width.

## Nested Layout

Containers can be nested:

```zig
zui.column(.{ .padding = 24, .gap = 12 }, .{
    zui.text("Header"),
    zui.row(.{ .padding = 12, .gap = 12 }, .{
        zui.text("A"),
        zui.text("B"),
        zui.text("C"),
    }),
    zui.text("Footer"),
})
```

Diagram:

```text
Column
+-- Text "Header"
+-- Row
|   +-- Text "A"
|   +-- Text "B"
|   +-- Text "C"
+-- Text "Footer"
```

## Resize Behavior

On Windows, resizing the native window sends `WM_SIZE`.

The backend handles it like this:

```text
WM_SIZE
  +-- get backend state from the window
  +-- compute new client area
  +-- walk the ZUI tree again
  +-- move existing native controls with MoveWindow
```

This means ZUI does not recreate controls on resize. It reuses and moves them.

## Current Limits

- Text height is fixed.
- Row widths are equal.
- There is no wrapping.
- There is no flex grow/shrink yet.
- There are no visual backgrounds for containers yet.

