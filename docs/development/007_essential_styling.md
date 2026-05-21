# 007 - Essential Styling

## What Changed

This phase was corrected after the first visual test. The original styling API worked, but the app looked rough and the example code was too verbose.

Added the essential style model:

- `ui.Color`
- `ui.colors`
- `ui.FontWeight`
- `ui.TextStyle`
- `ui.ButtonStyle`
- `ViewStyle.margin`
- `ViewStyle.background`

Then added a cleaner authoring layer:

- `ui.t("Text", .{ ... })` for styled text
- `.fg` as short text color
- `.bg` as short background color
- `.size` as short font size
- `.weight` as short font weight
- `.p` as short padding
- `.m` as short margin
- flattened button style fields

The older long names still work:

- `.color`
- `.background`
- `.font_size`
- `.font_weight`
- `.padding`
- `.margin`

## Why

The first styling example exposed three problems:

- Text controls used white native backgrounds instead of inheriting parent view backgrounds.
- Larger text was clipped because every text node used a fixed height.
- View backgrounds painted the entire remaining window height instead of their real content height.

The goal of this correction is simple: ZUI code should stay short, predictable, native, and readable even as apps get more complex.

## Clean API Example

```zig
const ui = @import("zui");
const c = ui.colors;

fn Screen() ui.Element {
    return ui.column(.{ .p = 24, .gap = 14, .bg = c.slate_900 }, .{
        ui.t("Clean Native Styling", .{ .fg = c.white, .size = 26, .weight = .bold }),
        ui.t("Short code, native controls, safer layout.", .{ .fg = c.slate_100, .size = 16 }),
        ui.column(.{ .p = 18, .m = 8, .gap = 10, .bg = c.slate_50 }, .{
            ui.t("Styled card area", .{ .fg = c.slate_900, .size = 20, .weight = .semibold }),
            ui.t("Text inherits the card background.", .{ .fg = c.slate_700, .size = 15 }),
        }),
    });
}
```

## Shorthand Map

```text
.p      -> padding
.m      -> margin
.bg     -> background
.fg     -> foreground/text color
.size   -> font size
.weight -> font weight
```

This keeps simple UI code compact while keeping the longer names available when clarity matters.

## Button Style

Buttons now accept common style fields directly:

```zig
ui.button(.{
    .title = "Primary",
    .on_click = primaryClicked,
    .size = 16,
    .weight = .semibold,
})
```

This is shorter than:

```zig
ui.button(.{
    .title = "Primary",
    .style = .{
        .font_size = 16,
        .font_weight = .semibold,
    },
})
```

Both forms still work.

## Backend Fixes

The Win32 backend now handles style more like a real UI system.

During layout:

```text
View
  -> resolve margin and padding
  -> resolve background from self or parent
  -> layout children
  -> paint background only to used content height
```

For native text controls:

```text
Text
  -> inherit parent background if no explicit text background exists
  -> measure height from font size
  -> use WM_CTLCOLORSTATIC for foreground/background color
```

For native fonts:

```text
Text/Button style
  -> CreateFontW
  -> SendMessageW(WM_SETFONT)
```

Runtime safety fix:

```text
WM_CTLCOLORSTATIC returns an HBRUSH through LRESULT.
That value is pointer-shaped, so ZUI preserves the pointer bits instead of using a checked numeric cast.
```

## Example Shape

The current example is intentionally smaller:

```text
Column p=24 bg=slate_900
+-- Title text, white, 26, bold
+-- Subtitle text, slate_100
+-- Card column p=18 m=8 bg=slate_50
|   +-- Card title
|   +-- Card body
|   +-- Blue label
+-- Button row
    +-- Primary
    +-- Secondary
```

The example file is now about 50 lines instead of around 90.

## How To Use It

Run:

```powershell
zig build run-styling
```

Resize the window. Text should keep readable backgrounds, large headings should not clip, and the card should not stretch into a giant empty block.

## Verification

Use:

```powershell
zig build test
zig build
```

Manual GUI check:

```powershell
zig build run-styling
```

## Current Limitations

- Padding and margin are still single values for all sides.
- Alpha is stored in `Color` but Win32 painting is currently opaque.
- Standard Win32 push buttons do not reliably honor custom button colors while native themes are enabled.
- There is no border, radius, shadow, hover, or disabled style yet.
- Text does not wrap yet.

## Next

Before adding more widgets, the next cleanup should be a small layout/style consolidation:

- per-side spacing
- alignment
- fixed/min/max size
- text wrapping
- a tiny theme object
