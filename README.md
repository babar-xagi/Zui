# ZUI - Fast, Native, Cross-Platform UI Framework

ZUI is a from-scratch cross-platform UI framework written in pure Zig 0.16, inspired by React Native and Flutter.

**Goal**: Small, fast, native apps with an easy-to-learn declarative API that feels like React Native.

```zig
const ui = @import("zui");

fn HomeScreen() ui.Element {
    return ui.column(.{ .padding = 16, .gap = 12 }, .{
        ui.t("Hello World 👋", .{ .size = 24, .weight = .bold }),
        ui.text("Cross-platform UI, written in Zig!"),
    });
}

pub fn main() !void {
    try ui.run(.{
        .app_name = "My App",
        .root = HomeScreen,
    });
}
```

## ✨ Features

- **Declarative API** - React Native & Flutter-inspired syntax
- **Fully Native** - Direct platform integration, no abstraction layers
- **Zero GC** - Memory-safe with deterministic allocators
- **Tiny Binaries** - Typically < 5MB executable size
- **Type-Safe** - Leverages Zig's powerful type system
- **Cross-Platform** - Windows (now), Linux/macOS (coming)

## 🎯 Current Status

✅ **Implemented**:
- Native Win32 backend for Windows
- Core components: `view`, `text`, `button`, `column`, `row`
- State management with `zui.state(T)`
- Styling with predefined color palette
- Keyboard and mouse input
- Reactive invalidation
- Clean, declarative API

🚀 **In Development**:
- Linux backend (X11/Wayland)
- macOS backend (Cocoa)
- More components (Input, ScrollView, etc.)
- Advanced layouts (Flexbox polish)

## 📖 Quick Start

### 1. Run Examples

```powershell
# Hello world
zig build run

# Interactive button
zig build run-button

# State counter
zig build run-counter

# Todo app
zig build run-todo

# Profile screen
zig build run-profile

# Advanced counter
zig build run-advanced-counter
```

### 2. Basic Component

```zig
const zui = @import("zui");

fn App() zui.Element {
    return zui.column(.{ .padding = 16, .gap = 8 }, .{
        zui.t("Welcome!", .{ 
            .fg = zui.colors.blue_600, 
            .size = 20, 
            .weight = .bold 
        }),
        zui.text("This is a simple app"),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "My App",
        .root = App,
    });
}
```

### 3. Interactive State

```zig
var count = zui.state(i32, 0);

fn increment() void {
    count.set(count.get() + 1);
}

fn App() zui.Element {
    return zui.column(.{ .padding = 24, .gap = 12 }, .{
        zui.textFmt("Count: {}", .{count.get()}),
        zui.button(.{
            .title = "Increment",
            .on_click = increment,
        }),
    });
}
```

## 🎨 API Overview

### Layout Components
- `ui.view(children)` - Generic container
- `ui.column(style, children)` - Vertical flex layout
- `ui.row(style, children)` - Horizontal flex layout

### Text Components
- `ui.text(value)` - Plain text
- `ui.textFmt(format, args)` - Formatted text
- `ui.t(value, style)` - Styled text (shorthand)
- `ui.styledText(options)` - Text with detailed styling

### Interactive
- `ui.button(options)` - Clickable button
- State management with `ui.state(T, initial)`

### Styling
- Predefined colors: `ui.colors.*`
- Text styles with font size and weight
- Layout styles (gap, padding, margin)

## 📚 Documentation

- **[CROSSPLATFORM_GUIDE.md](docs/CROSSPLATFORM_GUIDE.md)** - Complete API reference and best practices
- **[docs/development/](docs/development/)** - Architecture and development notes

## 🏗️ Build & Run

```powershell
# Run tests
zig build test

# Run hello example
zig build run

# Build all examples
zig build

# List all available commands
zig build --help
```

## 🚀 Why ZUI?

| Feature | ZUI | React Native | Flutter |
|---------|-----|--------------|---------|
| Language | Zig | JavaScript | Dart |
| Binary Size | ~2MB | ~50MB | ~15MB |
| Native | ✅ Direct | ⚠️ Bridge | ⚠️ Engine |
| Startup | <50ms | ~1s | ~500ms |
| Learning Curve | 📖 Beginner | 📖 Beginner | 📖 Beginner |

## 📋 Roadmap

**Phase 1** (Current): Windows native backend + core components
**Phase 2** (Next): Linux backend + more components  
**Phase 3** (Future): macOS backend + advanced features
**Phase 4** (Vision): Web backend + ecosystem

## 🤝 Contributing

We welcome contributions! Areas of interest:

- Platform backends (Linux, macOS, Web)
- New components (Input, ScrollView, Modal, etc.)
- Performance optimization
- Documentation
- Examples and tutorials

## 📝 Architecture

ZUI uses a modular backend architecture:

```
zui.zig (Core API)
    ↓
backend.zig (Platform abstraction)
    ↓
backends/
    ├── win32.zig (Windows)
    ├── linux.zig (Coming)
    └── macos.zig (Coming)
```

This allows the same Zig API to work across all platforms!

## 🐛 Testing

```powershell
zig build test
```

## 📄 License

ZUI is an open-source project.

---

**Ready to build fast, native apps?** 🚀

Start with: `zig build run`

