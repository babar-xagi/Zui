# 002 - Render The UI Tree

## What Changed

The Win32 backend now walks the ZUI tree and creates native text controls for every `zui.text` node.

Updated:

- `src/zui.zig`
- `src/backends/win32.zig`
- `examples/hello.zig`
- `README.md`

Added behavior:

- multiple text nodes render in the native window
- nested `view` nodes contribute layout spacing
- `view.padding` and `view.gap` affect child placement
- `Node.textCount()` counts nested text nodes for tests and future tooling

## Why

The first native window milestone proved that ZUI can open a real platform window. This milestone proves something more important: the public UI tree can drive backend rendering.

Instead of drawing one extracted string, the backend now receives the root `Node`, walks it recursively, and creates controls from it.

## How The Code Works

`src/zui.zig` still builds the tree:

```zig
return zui.view(.{ .padding = 24, .gap = 10 }, .{
    zui.text("Hello World Well Come to the ZUI!"),
    zui.text("This is rendered from multiple ZUI text nodes."),
    zui.view(.{ .padding = 12, .gap = 6 }, .{
        zui.text("Nested views can contribute text too."),
        zui.text("Next step: richer layout and controls."),
    }),
});
```

The backend receives the full root:

```zig
try backend.run(.{
    .app_name = options.app_name,
    .root_text = root_node.firstText() orelse options.app_name,
    .root = root_node,
});
```

`src/backends/win32.zig` then calls:

```zig
try renderRoot(@TypeOf(app.root), allocator, instance, hwnd, app.root);
```

The renderer has two cases:

- `text`: create a native Win32 `STATIC` child window
- `view`: apply padding/gap and recursively render children vertically

The layout is intentionally simple:

- root starts at the window client area
- a `view` adds padding around children
- siblings are stacked vertically
- gap is inserted between siblings
- every text line currently gets a fixed height of `28`

## How To Use It

Run:

```powershell
zig build run
```

On Windows, this opens a native window titled `Hello ZUI` and shows multiple text lines from `examples/hello.zig`.

Example:

```zig
fn HomeScreen() zui.Node {
    return zui.view(.{ .padding = 24, .gap = 10 }, .{
        zui.text("First line"),
        zui.text("Second line"),
        zui.view(.{ .padding = 12, .gap = 6 }, .{
            zui.text("Nested line"),
        }),
    });
}
```

## Verification

Verified with:

```powershell
zig build test
zig build
```

`zig build` confirms the native example compiles and links. `zig build run` opens a GUI window and should be run manually because it blocks until the window is closed.

## Limitations

- Only text nodes create native controls.
- `view` is still a logical layout node, not a native container peer.
- Layout is vertical only.
- Text height is fixed.
- Resizing the window does not relayout children yet.
- No buttons, inputs, state, or reconciliation yet.

## Next

Milestone 3 should focus on basic layout:

- create a clearer layout model
- support row/column directions
- handle window resizing
- keep layout separate from raw Win32 calls where possible
