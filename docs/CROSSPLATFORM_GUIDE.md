# ZUI Cross-Platform Framework
## React Native & Dart-Inspired Declarative UI

Welcome to ZUI - a fast, lightweight, and fully native cross-platform UI framework written in Zig 0.16!

## 🎯 Core Philosophy

ZUI brings the simplicity and elegance of declarative UI frameworks (like React Native and Flutter) to native platforms, all in pure Zig. We believe in:

- **Easy to Learn**: Simple, intuitive API inspired by proven frameworks
- **Blazingly Fast**: Direct native code, no runtime overhead
- **Tiny & Native**: Minimal binary sizes, full platform integration
- **Declarative**: Functional, composable UI components
- **Type-Safe**: Leveraging Zig's powerful type system

## 🚀 Quick Start

### Basic App

Create your first ZUI app in just a few lines:

```zig
const zui = @import("zui");

fn HomeScreen() zui.Element {
    return zui.view(.{
        zui.text("Hello World 👋"),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "My App",
        .root = HomeScreen,
    });
}
```

### Running Examples

```powershell
# Basic hello world
zig build run

# Interactive buttons
zig build run-button

# State management & counter
zig build run-counter

# Todo app
zig build run-todo

# Profile screen
zig build run-profile

# Advanced counter
zig build run-advanced-counter
```

## 📦 Core Components

### Layout

#### `view(children)`
Generic container for any content.

```zig
zui.view(.{
    zui.text("Item 1"),
    zui.text("Item 2"),
})
```

#### `column(style, children)`
Vertical layout (flexbox column).

```zig
zui.column(.{ .padding = 16, .gap = 8 }, .{
    zui.text("Top"),
    zui.text("Middle"),
    zui.text("Bottom"),
})
```

#### `row(style, children)`
Horizontal layout (flexbox row).

```zig
zui.row(.{ .gap = 12 }, .{
    zui.text("Left"),
    zui.text("Right"),
})
```

### Typography

#### `text(value: []const u8)`
Display plain text.

```zig
zui.text("Hello World")
```

#### `textFmt(comptime format, args)`
Formatted text with runtime values.

```zig
zui.textFmt("Count: {}", .{42})
```

#### `t(value, style)`
Styled text (shorthand).

```zig
zui.t("Title", .{
    .fg = zui.colors.blue_600,
    .size = 24,
    .weight = .bold,
})
```

#### `styledText(TextOptions)`
Text with detailed styling.

```zig
zui.styledText(.{
    .value = "Styled Text",
    .style = .{
        .fg = zui.colors.white,
        .bg = zui.colors.blue_600,
        .font_size = 18,
        .font_weight = .semibold,
    },
})
```

### Interactive Components

#### `button(ButtonOptions)`
Clickable button element.

```zig
var clicked = false;

fn handleClick() void {
    clicked = true;
    zui.invalidate();
}

zui.button(.{
    .title = "Press Me",
    .on_click = handleClick,
    .fg = zui.colors.white,
    .bg = zui.colors.blue_600,
})
```

### State Management

#### `state(T, initial_value)`
Create reactive state.

```zig
var counter = zui.state(i32, 0);

fn increment() void {
    counter.set(counter.get() + 1);
}

fn CounterScreen() zui.Element {
    return zui.column(.{ .gap = 16 }, .{
        zui.textFmt("Count: {}", .{counter.get()}),
        zui.button(.{
            .title = "Increment",
            .on_click = increment,
        }),
    });
}
```

#### `stateText(T, state, formatter)`
Display formatted state changes.

```zig
const Formatter = struct {
    fn format(value: i32, allocator: std.mem.Allocator) []const u8 {
        return std.fmt.allocPrint(allocator, "Count: {}", .{value}) catch @panic("oom");
    }
};

var counter = zui.state(i32, 0);

zui.stateText(i32, &counter, Formatter.format)
```

## 🎨 Styling

All components support intuitive style options:

### ViewStyle
```zig
.{
    .gap = 8,           // Space between children
    .padding = 16,      // Internal padding
    .margin = 4,        // External margin
    .bg = color,        // Background color
    .direction = .row,  // .row or .column
}
```

### TextStyle & ButtonStyle
```zig
.{
    .fg = zui.colors.blue_600,      // Foreground color
    .bg = zui.colors.slate_50,      // Background color
    .size = 14,                     // Font size
    .weight = .bold,                // .regular, .medium, .semibold, .bold
    .font_family = "Arial",         // Font family (optional)
}
```

### Built-in Palette

ZUI includes a predefined color palette inspired by Tailwind CSS:

```zig
zui.colors.white
zui.colors.black
zui.colors.slate_50
zui.colors.slate_100
zui.colors.slate_700
zui.colors.slate_900
zui.colors.blue_600
zui.colors.emerald_600
zui.colors.amber_500
zui.colors.rose_600
```

## 💾 Memory Management

ZUI uses Zig's arena allocator during app execution:

- All UI nodes are allocated in a central arena
- Memory is automatically cleaned up on each frame
- Write code without worrying about manual memory

```zig
// Safe - automatic memory management
fn renderList() zui.Element {
    return zui.column(.{}, .{
        zui.textFmt("Item {}", .{1}),
        zui.textFmt("Item {}", .{2}),
        zui.textFmt("Item {}", .{3}),
    });
}
```

## 🔄 Reactive Updates

The `zui.invalidate()` function triggers UI re-render:

```zig
var count = 0;

fn handleClick() void {
    count += 1;
    zui.invalidate();  // Trigger re-render
}
```

## 🎯 Best Practices

### 1. Functional Component Style

Create functions that return elements:

```zig
fn Button(title: []const u8, on_click: zui.ClickHandler) zui.Element {
    return zui.button(.{
        .title = title,
        .on_click = on_click,
        .fg = zui.colors.white,
        .bg = zui.colors.blue_600,
    });
}

// Usage
zui.column(.{}, .{
    Button("Save", handleSave),
    Button("Cancel", handleCancel),
})
```

### 2. State Management

Define state at module level for simplicity:

```zig
var counter = zui.state(i32, 0);
var input_text: []const u8 = "";

fn increment() void {
    counter.set(counter.get() + 1);
}

fn handleInput(text: []const u8) void {
    input_text = text;
    zui.invalidate();
}
```

### 3. Composition

Build complex UIs from simple components:

```zig
fn Header(title: []const u8) zui.Element {
    return zui.column(.{ .padding = 12, .bg = blue_600 }, .{
        zui.t(title, .{ .fg = colors.white, .weight = .bold }),
    });
}

fn App() zui.Element {
    return zui.column(.{}, .{
        Header("My App"),
        zui.column(.{ .padding = 16 }, .{
            // Content here
        }),
    });
}
```

## 🔧 Advanced Styling

### Shorthand Aliases

For convenience, styles accept both full and short names:

```zig
zui.t("Text", .{
    .fg = color,           // foreground (short)
    .color = color,        // foreground (long)
    .bg = color,           // background (short)
    .background = color,   // background (long)
    .size = 14,            // font_size (short)
    .weight = .bold,       // font_weight (short)
})
```

### Dynamic Styling

Style components based on state:

```zig
var is_active = zui.state(bool, false);

fn toggleActive() void {
    is_active.set(!is_active.get());
}

fn StyledButton() zui.Element {
    const bg_color = if (is_active.get()) 
        zui.colors.emerald_600 
    else 
        zui.colors.slate_300;
    
    return zui.button(.{
        .title = "Toggle",
        .on_click = toggleActive,
        .bg = bg_color,
    });
}
```

## 📱 Cross-Platform Support

ZUI is designed for cross-platform apps:

- **Windows**: Native Win32 backend (fully implemented)
- **Linux**: Coming soon
- **macOS**: Coming soon
- **Web**: Future platform

The same code runs on all platforms!

## 🚀 Performance Features

- **Zero Garbage Collection**: Deterministic memory management
- **Direct Native Code**: No interpreter or VM overhead
- **Minimal Dependencies**: Only system libraries
- **Optimized Binary Size**: Tiny executables (typically < 5MB)

## 📖 Complete Example

```zig
const zui = @import("zui");
const std = @import("std");

var counter = zui.state(i32, 0);

fn increment() void {
    counter.set(counter.get() + 1);
}

fn decrement() void {
    counter.set(counter.get() - 1);
}

fn formatter(value: i32, allocator: std.mem.Allocator) []const u8 {
    return std.fmt.allocPrint(allocator, "Count: {}", .{value}) 
        catch @panic("out of memory");
}

fn App() zui.Element {
    return zui.column(.{ .padding = 24, .gap = 16 }, .{
        zui.t("Counter App", .{
            .fg = zui.colors.slate_900,
            .size = 28,
            .weight = .bold,
        }),
        
        zui.column(.{
            .padding = 16,
            .background = zui.colors.blue_600,
        }, .{
            zui.styledStateText(i32, &counter, formatter, .{
                .fg = zui.colors.white,
                .size = 32,
                .weight = .bold,
            }),
        }),
        
        zui.row(.{ .gap = 12 }, .{
            zui.button(.{
                .title = "➖ Decrease",
                .on_click = decrement,
                .bg = zui.colors.rose_600,
                .fg = zui.colors.white,
            }),
            zui.button(.{
                .title = "➕ Increase",
                .on_click = increment,
                .bg = zui.colors.emerald_600,
                .fg = zui.colors.white,
            }),
        }),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "Counter",
        .root = App,
    });
}
```

## 🐛 Debugging

Enable debug output:

```zig
fn App() zui.Element {
    const root = zui.column(.{}, .{
        // ... content ...
    });
    
    // Debug print the node tree
    root.debugPrint(0);
    
    return root;
}
```

## 📚 Learn More

- See `examples/` directory for complete working apps
- Check `docs/development/` for architecture details
- Run examples with `zig build run-*` commands

## 🤝 Contributing

We welcome contributions! Areas of interest:

- New platform backends (Linux, macOS, Web)
- New components (Input, ScrollView, etc.)
- Performance optimizations
- Documentation and examples
- Bug fixes and improvements

## 📝 License

ZUI is an open-source project. See LICENSE for details.

---

**Happy Building! 🚀**

Quick links:
- `zig build run` - Run hello example
- `zig build test` - Run tests
- `zig build run-todo` - Run todo app
- `zig build run-profile` - Run profile app

