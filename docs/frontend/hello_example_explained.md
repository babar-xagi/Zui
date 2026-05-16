# Hello Example Explained

This document explains the current ZUI frontend code in `examples/hello.zig`.

The goal is to understand how this code describes a UI tree, how nested views work, and how `zui.run` sends that tree to the backend.

## Full Code

```zig
const zui = @import("zui");

fn HomeScreen() zui.Node {
    return zui.view(.{ .padding = 24, .gap = 10 }, .{
        zui.text("Hello World Well Come to the ZUI!"),
        zui.text("This is rendered from multiple ZUI text nodes."),
        zui.view(.{ .padding = 24, .gap = 10 }, .{
            zui.text("Nested views can contribute text too."),
            zui.text("Next step: richer layout and controls."),
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

- `zui.view(...)` creates a container node.
- `zui.text(...)` creates a text node.
- `zui.run(...)` starts the app and gives the root node to the backend.

Current backend behavior on Windows:

- Each `zui.text(...)` becomes a native Win32 `STATIC` control.
- Each `zui.view(...)` is used for layout.
- `padding` creates space inside a view.
- `gap` creates space between child nodes.

## UI Tree Diagram

The code creates this tree:

```text
App: "Hello ZUI"
+-- HomeScreen()
    +-- View padding=24 gap=10
        +-- Text "Hello World Well Come to the ZUI!"
        +-- Text "This is rendered from multiple ZUI text nodes."
        +-- View padding=24 gap=10
            +-- Text "Nested views can contribute text too."
            +-- Text "Next step: richer layout and controls."
```

In memory, that is roughly:

```text
Node.view
  style = { padding = 24, gap = 10 }
  children = [
    Node.text("Hello World Well Come to the ZUI!"),
    Node.text("This is rendered from multiple ZUI text nodes."),
    Node.view
      style = { padding = 24, gap = 10 }
      children = [
        Node.text("Nested views can contribute text too."),
        Node.text("Next step: richer layout and controls."),
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
|  Text: Hello World Well Come to the ZUI!                |
|                                                         |
|  gap 10                                                 |
|                                                         |
|  Text: This is rendered from multiple ZUI text nodes.   |
|                                                         |
|  gap 10                                                 |
|                                                         |
|  Nested View padding 24                                 |
|  +---------------------------------------------------+  |
|  | Text: Nested views can contribute text too.       |  |
|  |                                                   |  |
|  | gap 10                                            |  |
|  |                                                   |  |
|  | Text: Next step: richer layout and controls.      |  |
|  +---------------------------------------------------+  |
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
              +-- turns each Text node into Win32 STATIC control
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
return zui.view(.{ .padding = 24, .gap = 10 }, .{
```

This creates a container node.

It receives two arguments:

```zig
zui.view(style, children)
```

The style:

```zig
.{ .padding = 24, .gap = 10 }
```

means:

- `padding = 24`: place children 24 pixels inside the container edges.
- `gap = 10`: place 10 pixels between each child.

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
zui.text("This is rendered from multiple ZUI text nodes."),
```

Each `zui.text(...)` creates a `Node.text`.

On Windows today, every text node becomes a Win32 `STATIC` control.

### Add A Nested View

```zig
zui.view(.{ .padding = 24, .gap = 10 }, .{
    zui.text("Nested views can contribute text too."),
    zui.text("Next step: richer layout and controls."),
}),
```

This creates a view inside another view.

Nested views let us group children and apply layout rules to that group.

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

Current implementation idea:

```text
zui.view(style, tuple_children)
  +-- allocates a slice of Node values
  +-- copies tuple children into that slice
  +-- returns Node.view { style, children }
```

So this:

```zig
zui.view(.{}, .{
    zui.text("A"),
    zui.text("B"),
})
```

becomes:

```text
Node.view
  children[0] = Node.text("A")
  children[1] = Node.text("B")
```

## How The Win32 Backend Uses It

Current backend idea:

```text
renderNode(node)
  if node is Text:
      CreateWindowExW("STATIC", text)

  if node is View:
      apply padding
      for each child:
          renderNode(child)
          move y position by child height + gap
```

This is why multiple `zui.text(...)` calls become multiple visible native controls.

## Current Limitations

This is still early.

Current limitations:

- Layout is only vertical.
- `view` is logical only, not a native visible container.
- Text height is fixed.
- Resize does not relayout yet.
- There are no buttons or inputs yet.
- There is no state or reconciliation yet.
- Styling is only `padding` and `gap`.

## What Comes Next

Next frontend improvements should be:

- `zui.column(...)`
- `zui.row(...)`
- text alignment
- window resize relayout
- `zui.button(...)`
- state for changing UI after events
