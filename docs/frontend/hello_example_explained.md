# Hello Example Explained

This document explains the current ZUI frontend code in `examples/hello.zig`.

The goal is to understand how this code describes a UI tree, how nested views work, and how `zui.run` sends that tree to the backend.

## Full Code

```zig
const zui = @import("zui");

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

pub fn main() !void {
    try zui.run(.{
        .app_name = "Hello ZUI",
        .root = HomeScreen,
    });
}
```

## Big Idea

The frontend code does not directly call Win32, GTK, Android, or any platform API.

Instead, it builds a simple tree of `zui.Node` values:

- `zui.column(...)` creates a vertical container node.
- `zui.row(...)` creates a horizontal container node.
- `zui.view(...)` creates a generic container node.
- `zui.text(...)` creates a text node.
- `zui.run(...)` starts the app and gives the root node to the backend.

Current backend behavior on Windows:

- Each `zui.text(...)` becomes a native Win32 `STATIC` control.
- Each container is used for layout.
- `padding` creates space inside a view.
- `gap` creates space between child nodes.
- The Win32 backend relayouts controls when the window resizes.

## UI Tree Diagram

The code creates this tree:

```text
App: "Hello ZUI"
+-- HomeScreen()
    +-- Column padding=24 gap=12
        +-- Text "Hello World Well Come to the ZUI!"
        +-- Text "Column layout stacks these text nodes vertically."
        +-- Row padding=12 gap=12
            +-- Text "Row item A"
            +-- Text "Row item B"
            +-- Text "Row item C"
        +-- Column padding=12 gap=6
            +-- Text "Nested columns still work."
            +-- Text "Resize the window to trigger relayout."
```

In memory, that is roughly:

```text
Node.view
  style = { direction = column, padding = 24, gap = 12 }
  children = [
    Node.text("Hello World Well Come to the ZUI!"),
    Node.text("Column layout stacks these text nodes vertically."),
    Node.view
      style = { direction = row, padding = 12, gap = 12 }
      children = [
        Node.text("Row item A"),
        Node.text("Row item B"),
        Node.text("Row item C"),
      ]
    Node.view
      style = { direction = column, padding = 12, gap = 6 }
      children = [
        Node.text("Nested columns still work."),
        Node.text("Resize the window to trigger relayout."),
      ]
  ]
```

## Screen Layout Diagram

Current layout is simple vertical stacking.

```text
Window
+---------------------------------------------------------+
| padding 24                                              |
|                                                         |
| Text: Hello World Well Come to the ZUI!                 |
|                                                         |
| gap 12                                                  |
|                                                         |
| Text: Column layout stacks these text nodes vertically. |
|                                                         |
| gap 12                                                  |
|                                                         |
| Row padding 12                                          |
| +-----------+ gap 12 +-----------+ gap 12 +-----------+ |
| | Row item A|        | Row item B|        | Row item C| |
| +-----------+        +-----------+        +-----------+ |
|                                                         |
| gap 12                                                  |
|                                                         |
| Nested Column padding 12                                |
| Text: Nested columns still work.                        |
| gap 6                                                   |
| Text: Resize the window to trigger relayout.            |
+---------------------------------------------------------+
```

The nested view is not drawn as a visible box yet. The box in the diagram only shows the logical layout area.

## Execution Flow

```text
main()
  |
  +-- zui.run(.{ .app_name = "Hello ZUI", .root = HomeScreen })
      |
      +-- creates temporary arena allocator for this UI build
      |
      +-- calls HomeScreen()
      |   |
      |   +-- returns root Node.view
      |
      +-- sends root node to backend.run(...)
          |
          +-- on Windows:
              +-- creates native window
              +-- walks the Node tree
              +-- turns each Text node into a Win32 STATIC control
              +-- lays out column and row containers
              +-- enters native message loop
```

## Line By Line

### Import ZUI

```zig
const zui = @import("zui");
```

This imports the ZUI module from `src/zui.zig`.

It gives access to:

- `zui.Node`
- `zui.view`
- `zui.column`
- `zui.row`
- `zui.text`
- `zui.run`

### Define A Screen

```zig
fn HomeScreen() zui.Node {
```

`HomeScreen` is a function that returns one UI node.

For now, a screen is just a Zig function. It does not need a class, object, JSX compiler, or builder macro.

### Create The Root View

```zig
return zui.column(.{ .padding = 24, .gap = 12 }, .{
```

This creates a vertical container node.

It receives two arguments:

```zig
zui.column(style, children)
```

The style:

```zig
.{ .padding = 24, .gap = 12 }
```

means:

- `padding = 24`: place children 24 pixels inside the container edges.
- `gap = 12`: place 12 pixels between each child.

The children:

```zig
.{
    ...
}
```

are a Zig tuple containing child nodes.

### Add Text Nodes

```zig
zui.text("Hello World Well Come to the ZUI!"),
zui.text("Column layout stacks these text nodes vertically."),
```

Each `zui.text(...)` creates a `Node.text`.

On Windows today, every text node becomes a Win32 `STATIC` control.

### Add A Nested View

```zig
zui.row(.{ .padding = 12, .gap = 12 }, .{
    zui.text("Row item A"),
    zui.text("Row item B"),
    zui.text("Row item C"),
}),
```

This creates a horizontal row inside the outer column.

Rows place their children left to right. The current Win32 backend gives row children equal widths.

### Add A Nested Column

```zig
zui.column(.{ .padding = 12, .gap = 6 }, .{
    zui.text("Nested columns still work."),
    zui.text("Resize the window to trigger relayout."),
}),
```

Nested columns let us group children and apply vertical layout rules to that group.

Right now, nested views only affect positioning. Later they can become real backend container peers, support row/column direction, background color, borders, flex behavior, and more.

### Start The App

```zig
pub fn main() !void {
    try zui.run(.{
        .app_name = "Hello ZUI",
        .root = HomeScreen,
    });
}
```

`main` starts the app.

`zui.run` receives:

- `app_name`: used as the native window title.
- `root`: the root screen function.

ZUI calls `HomeScreen()` internally. The user does not manually create a window or run a platform event loop.

## How `zui.view` Works Today

Current implementation idea for all containers:

```text
zui.view/style wrapper(style, tuple_children)
  +-- allocates a slice of Node values
  +-- copies tuple children into that slice
  +-- returns Node.view { style, children }
```

`column` and `row` set `style.direction` before calling `view`.

So this:

```zig
zui.row(.{}, .{
    zui.text("A"),
    zui.text("B"),
})
```

becomes:

```text
Node.view
  style.direction = row
  children[0] = Node.text("A")
  children[1] = Node.text("B")
```

## How The Win32 Backend Uses It

Current backend idea:

```text
renderNode(node)
  if node is Text:
      CreateWindowExW("STATIC", text)

  if node is Column:
      apply padding
      for each child:
          renderNode(child)
          move y position by child height + gap

  if node is Row:
      apply padding
      split width across children
      render each child from left to right
```

This is why multiple `zui.text(...)` calls become multiple visible native controls.

## Current Limitations

This is still early.

Current limitations:

- Layout supports simple column and row directions.
- `view` is logical only, not a native visible container.
- Text height is fixed.
- Resize relayouts existing text controls on Win32.
- There are no buttons or inputs yet.
- There is no state or reconciliation yet.
- Styling is only `padding` and `gap`.

## What Comes Next

Next frontend improvements should be:

- text alignment
- `zui.button(...)`
- state for changing UI after events
