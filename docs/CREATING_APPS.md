## How to Create a New ZUI App

This guide will help you create a new ZUI application from scratch.

### Step 1: Create Your App File

Create a new `.zig` file in the `examples/` directory:

```bash
# Example: examples/my_first_app.zig
```

### Step 2: Basic Structure

Every ZUI app needs this structure:

```zig
const zui = @import("zui");

fn App() zui.Element {
    return zui.column(.{ .padding = 16, .gap = 8 }, .{
        zui.text("Hello App!"),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "My App",
        .root = App,
    });
}
```

### Step 3: Add to build.zig

Add a build entry for your app in `build.zig`:

```zig
const my_app = b.addExecutable(.{
    .name = "zui-my-app",
    .root_module = b.createModule(.{
        .root_source_file = b.path("examples/my_first_app.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "zui", .module = zui_mod },
        },
    }),
});
addPlatformLinks(my_app.root_module, target);
b.installArtifact(my_app);

const run_my_app = b.addRunArtifact(my_app);
run_my_app.step.dependOn(b.getInstallStep());
if (b.args) |args| {
    run_my_app.addArgs(args);
}

const run_my_app_step = b.step("run-my-app", "Run my first app");
run_my_app_step.dependOn(&run_my_app.step);
```

### Step 4: Run Your App

```powershell
zig build run-my-app
```

### Example Patterns

#### Pattern 1: State Management

```zig
var counter = zui.state(i32, 0);

fn increment() void {
    counter.set(counter.get() + 1);
    zui.invalidate();
}

fn App() zui.Element {
    return zui.column(.{ .gap = 12 }, .{
        zui.textFmt("Count: {}", .{counter.get()}),
        zui.button(.{
            .title = "Increment",
            .on_click = increment,
        }),
    });
}
```

#### Pattern 2: Formatted State

```zig
const std = @import("std");
const zui = @import("zui");

var value = zui.state(i32, 42);

const Formatter = struct {
    fn format(val: i32, allocator: std.mem.Allocator) []const u8 {
        return std.fmt.allocPrint(allocator, "Value: {}", .{val}) 
            catch @panic("oom");
    }
};

fn App() zui.Element {
    return zui.stateText(i32, &value, Formatter.format);
}
```

#### Pattern 3: Complex Layouts

```zig
fn Header(title: []const u8) zui.Element {
    return zui.column(.{
        .padding = 12,
        .background = zui.colors.blue_600,
    }, .{
        zui.t(title, .{
            .fg = zui.colors.white,
            .weight = .bold,
        }),
    });
}

fn Card(content: zui.Element) zui.Element {
    return zui.column(.{
        .padding = 12,
        .background = zui.colors.slate_50,
    }, .{
        content,
    });
}

fn App() zui.Element {
    return zui.column(.{}, .{
        Header("My App"),
        zui.column(.{ .padding = 16, .gap = 12 }, .{
            Card(zui.text("Card 1")),
            Card(zui.text("Card 2")),
        }),
    });
}
```

#### Pattern 4: Multiple Buttons

```zig
fn handleSave() void {
    // Handle save
}

fn handleCancel() void {
    // Handle cancel
}

fn App() zui.Element {
    return zui.row(.{ .gap = 8 }, .{
        zui.button(.{
            .title = "Save",
            .on_click = handleSave,
            .bg = zui.colors.emerald_600,
        }),
        zui.button(.{
            .title = "Cancel",
            .on_click = handleCancel,
            .bg = zui.colors.rose_600,
        }),
    });
}
```

#### Pattern 5: Conditional Rendering

```zig
var show_details = false;

fn toggleDetails() void {
    show_details = !show_details;
    zui.invalidate();
}

fn App() zui.Element {
    return zui.column(.{ .gap = 12 }, .{
        zui.button(.{
            .title = "Show Details",
            .on_click = toggleDetails,
        }),
        if (show_details)
            zui.t("Details: Lorem ipsum dolor sit amet", .{ .size = 12 })
        else
            zui.text("Click to see details"),
    });
}
```

### Component Reference

See [CROSSPLATFORM_GUIDE.md](CROSSPLATFORM_GUIDE.md) for all available components.

### Quick Tips

1. **Use shorthand style properties**:
   ```zig
   .{ .fg = color, .bg = color, .size = 14, .weight = .bold }
   ```

2. **Leverage Zig's type safety**:
   ```zig
   var counter = zui.state(i32, 0);  // Type-safe!
   counter.set(counter.get() + 1);   // Type checking at compile time
   ```

3. **Always call `zui.invalidate()` after state changes**:
   ```zig
   fn handleClick() void {
       counter.set(counter.get() + 1);
       zui.invalidate();  // Trigger re-render
   }
   ```

4. **Use arena allocator-friendly APIs**:
   ```zig
   // These automatcally use the active arena:
   zui.textFmt("Value: {}", .{42})
   ```

5. **Compose functions for reusable components**:
   ```zig
   fn PrimaryButton(label: []const u8, handler: zui.ClickHandler) zui.Element {
       return zui.button(.{
           .title = label,
           .on_click = handler,
           .fg = zui.colors.white,
           .bg = zui.colors.blue_600,
       });
   }
   ```

### Testing Your App

```powershell
# Build all examples
zig build

# Run your app
zig build run-my-app

# Run tests
zig build test
```

### Common Patterns to Avoid

❌ Don't forget `zui.invalidate()` after state changes:
```zig
// BAD
counter.set(counter.get() + 1);  // Won't re-render!

// GOOD
counter.set(counter.get() + 1);
zui.invalidate();
```

❌ Don't manually allocate - use the arena:
```zig
// BAD
const allocator = std.heap.page_allocator;
const text = try allocator.alloc(u8, 100);

// GOOD
const text = try std.fmt.allocPrint(allocator, "text", .{});
```

### Next Steps

1. Check out examples in `examples/` for inspiration
2. Read [CROSSPLATFORM_GUIDE.md](CROSSPLATFORM_GUIDE.md) for detailed API docs
3. Join our community and share your creations!

Happy building! 🚀

