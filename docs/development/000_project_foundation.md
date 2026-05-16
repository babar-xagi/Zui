# 000 - Project Foundation

## What Changed

Created ZUI as a fresh Zig 0.16 project and initialized it as its own git repository.

Added:

- `build.zig`
- `build.zig.zon`
- `.gitignore`
- `src/zui.zig`
- `examples/hello.zig`
- `README.md`
- `docs/development/README.md`

## Why

ZUI is a from-scratch framework. We want a clean package boundary before adding native windowing, layout, state, and platform backends.

This first step gives us a working Zig package that can build, test, and run an example without pulling in Capy or any other dependency.

## How The Code Works

`src/zui.zig` currently defines the smallest useful API:

- `zui.Node`: a tagged union for UI nodes.
- `zui.text(value)`: creates a text node.
- `zui.view(style, children)`: creates a container node.
- `zui.run(options)`: builds the root UI tree and prints it for now.

`zui.view` accepts tuple children:

```zig
return zui.view(.{}, .{
    zui.text("Hello World!"),
});
```

For this first milestone, `zui.run` creates an arena allocator and `zui.view` stores children in that arena. This is temporary. The runtime will later own tree building, reconciliation, and native peer lifetime more explicitly.

`build.zig` creates:

- a `zui` module from `src/zui.zig`
- a `zui-hello` executable from `examples/hello.zig`
- a `run` step for the hello example
- a `test` step for the module tests

## How To Use It

Run tests:

```powershell
zig build test
```

Run the example:

```powershell
zig build run
```

Example app:

```zig
const zui = @import("zui");

fn HomeScreen() zui.Node {
    return zui.view(.{ .padding = 16, .gap = 8 }, .{
        zui.text("Hello World!"),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "Hello ZUI",
        .root = HomeScreen,
    });
}
```

Current output is a debug tree, not a native window yet:

```text
ZUI app: Hello ZUI
View(gap=8, padding=16)
  Text("Hello World!")
```

## Verification

Verified with:

```powershell
zig build test
zig build run
```

`zig build run` prints:

```text
ZUI app: Hello ZUI
View(gap=8, padding=16)
  Text("Hello World!")
```

## Next

Milestone 1 replaces the debug tree output with the first native window backend, starting with Win32.
