# 006 - Declarative API Cleanup

## What Changed

Cleaned the public API so beginner code reads more like a modern declarative UI framework.

Added:

- `pub const Element = Node`
- `ui.view(.{ ... })`
- `ui.textFmt("Count: {}", .{value})`
- `ui.state(T, initial)`
- `ui.button(.{ .title = "..." })`

Kept compatibility:

- `ui.Node` still exists.
- `ui.button(.{ .label = "..." })` still works for older examples.
- `ui.column(...)`, `ui.row(...)`, `ui.text(...)`, `ui.stateText(...)`, and `ui.run(...)` still work.

Added a new phase example:

- `examples/006_declarative_api.zig`

Added a new build command:

```powershell
zig build run-declarative
```

## Why

The first five phases proved the engine ideas:

- native window
- UI tree
- layout
- buttons
- state refresh

But the public API still looked like internal framework code. ZUI should be easy to teach and easy to remember.

The goal is code that feels close to this:

```zig
const ui = @import("zui");

fn HomeScreen() ui.Element {
    return ui.view(.{
        ui.text("Hello World!"),
    });
}
```

## New Preferred Style

You can import the names you use often:

```zig
const ui = @import("zui");

const Element = ui.Element;
const view = ui.view;
const text = ui.text;
const run = ui.run;
```

Then write a screen like this:

```zig
fn HomeScreen() Element {
    return view(.{
        text("Hello World!"),
        ui.textFmt("Phase: {}", .{6}),
    });
}
```

## State Example

```zig
var count = ui.state(i32, 0);

fn countLabel(value: i32, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "Count: {}", .{value}) catch @panic("out of memory");
}

fn increment() void {
    count.set(count.get() + 1);
}

fn HomeScreen() Element {
    return view(.{
        ui.stateText(i32, &count, countLabel),
        ui.button(.{
            .title = "Increment",
            .on_click = increment,
        }),
    });
}
```

## Why `textFmt` Exists

The ideal API might look like this:

```zig
ui.text("Count: {d}", .{count.get()})
```

Zig does not support function overloading or default function arguments, so one function cannot cleanly be both:

```zig
ui.text("Hello")
ui.text("Count: {}", .{count})
```

For now ZUI keeps the most common case short:

```zig
ui.text("Hello")
```

And uses a clear formatted helper:

```zig
ui.textFmt("Count: {}", .{count.get()})
```

## Why Callbacks Are Named Functions

The ideal JavaScript-like shape might be:

```zig
ui.button(.{
    .title = "Increment",
    .on_click = fn () void {
        count.set(count.get() + 1);
    },
})
```

Zig does not have capturing closures like JavaScript, React Native, or Dart. A callback cannot safely capture local state like that today.

So the current safe style is:

```zig
fn increment() void {
    count.set(count.get() + 1);
}

ui.button(.{
    .title = "Increment",
    .on_click = increment,
})
```

This is slightly less compact, but it is explicit, safe, and fits Zig.

## API Shape Diagram

```text
ui.Element
  +-- text("Hello")
  +-- textFmt("Count: {}", .{count})
  +-- stateText(i32, &count, formatter)
  +-- button(.{ .title = "Increment", .on_click = increment })
  +-- view(.{ children... })
  +-- column(.{ .padding = 24, .gap = 12 }, .{ children... })
  +-- row(.{ .gap = 12 }, .{ children... })
```

## How To Use It

Run the new example:

```powershell
zig build run-declarative
```

The example shows:

- simple `view(.{ ... })`
- `Element` as the return type
- short aliases for common UI functions
- formatted text through `textFmt`
- reactive text through `stateText`
- buttons using `.title`

## Verification

Use:

```powershell
zig build test
zig build
```

Manual GUI check:

```powershell
zig build run-declarative
```

## Limitations

- `textFmt` is separate from `text` because Zig has no overloads/default args.
- Click callbacks are named functions because Zig has no capturing closures.
- Local hook-style state inside a screen function is not implemented yet.
- `stateText` still needs a formatter function.

## Next

After this cleanup, the next feature phase can be text input:

- `ui.textInput`
- native Win32 `EDIT` controls
- change callbacks
- form example
