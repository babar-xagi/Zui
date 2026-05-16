# ZUI Development Roadmap

ZUI is a new from-scratch cross-platform UI framework written in Zig 0.16. Capy is reference material only. This roadmap is the practical build order for turning the idea into a working framework.

## North Star

Build apps with one simple Zig codebase:

```zig
const zui = @import("zui");

fn HomeScreen() zui.Node {
    return zui.view(.{}, .{
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

The framework should be easy to learn, fast, native, small, and honest about platform differences.

## Milestone 0 - Project Foundation

Goal: create the clean ZUI package.

Tasks:

- Create `build.zig` and `build.zig.zon`.
- Add `src/zui.zig`.
- Add `examples/hello.zig`.
- Add `README.md`.
- Add `zig build test`.
- Keep dependencies at zero unless truly needed.

Done when:

- `zig build test` passes.
- `zig build run` runs a placeholder app.
- The package clearly targets Zig `0.16.0`.

## Milestone 1 - First Native Window

Goal: open a real native window from the ZUI API.

Tasks:

- Add `zui.run`.
- Add `Window` abstraction.
- Implement first backend: Win32.
- Add a blocking event loop.
- Add app name/window title support.

Done when:

- `examples/hello.zig` opens a native Windows window.
- User code does not call Win32 directly.

## Milestone 2 - First UI Tree

Goal: render a simple declarative tree.

Tasks:

- Add `Node`.
- Add `view`.
- Add `text`.
- Add one-child and many-child containers.
- Convert a ZUI tree into native peers.

Done when:

- This works:

```zig
return zui.view(.{}, .{
    zui.text("Hello World!"),
});
```

## Milestone 3 - Basic Layout

Goal: make common screens easy.

Tasks:

- Add `row`.
- Add `column`.
- Add `stack`.
- Add gap/spacing.
- Add padding.
- Add alignment.
- Add preferred/minimum size.

Done when:

- Hello, counter, and form examples can be laid out without manual coordinates.

## Milestone 4 - Interactive Controls

Goal: apps can accept user input.

Tasks:

- Add `button`.
- Add `textInput`.
- Add `checkbox`.
- Add `slider`.
- Add click/change event callbacks.
- Add focus and tab order.

Done when:

- Counter example works.
- Form example works.
- Keyboard focus works in a predictable order.

## Milestone 5 - State Model

Goal: UI updates naturally when data changes.

Tasks:

- Add `state(T, initial)`.
- Add subscriptions/invalidation.
- Add state formatting for text.
- Add simple update helpers.
- Keep memory ownership obvious.

Done when:

- Counter state updates text without recreating the full window.
- State examples are beginner-readable.

## Milestone 6 - Reconciliation

Goal: update existing native peers instead of rebuilding everything.

Tasks:

- Add stable node identity.
- Add keyed children.
- Add diff for text changes.
- Add diff for property changes.
- Add insert/remove child operations.

Done when:

- Todo list example can add/remove rows.
- Existing text input focus survives nearby UI updates.

## Milestone 7 - Styling

Goal: common visual customization without losing native behavior.

Tasks:

- Add `ViewStyle`.
- Add `TextStyle`.
- Add colors.
- Add font size/weight where backend supports it.
- Add disabled/visible properties.
- Add capability checks for unsupported style features.

Done when:

- A small settings screen can be styled cleanly.
- Unsupported style behavior is documented.

## Milestone 8 - Backend Interface Cleanup

Goal: make more platforms possible without rewriting the runtime.

Tasks:

- Define required backend functions.
- Define optional capabilities.
- Split platform code from runtime code.
- Add backend conformance tests.
- Add `zui.backend` compile-time selection.

Done when:

- Win32 backend is one implementation of a clear backend contract.

## Milestone 9 - Linux Backend

Goal: support Linux desktop.

Tasks:

- Choose first Linux toolkit, likely GTK4.
- Implement window, text, button, input, containers.
- Add build dependency notes.
- Add Linux example run command.

Done when:

- Hello/counter/form work on Linux.

## Milestone 10 - Web Backend

Goal: run the same app in the browser.

Tasks:

- Add WASM target.
- Add minimal JS host.
- Add DOM-backed text/button/input.
- Add local dev server command.
- Add static output folder.

Done when:

- Hello/counter/form work in browser.

## Milestone 11 - Android Backend

Goal: mobile starts early, not as an afterthought.

Tasks:

- Add Android build/package flow.
- Add Activity lifecycle.
- Add View-backed window/root.
- Add text, button, input, layout.
- Add device/emulator run command.

Done when:

- Hello/counter/form install and run on Android.

## Milestone 12 - macOS And iOS

Goal: Apple platforms.

Tasks:

- Add AppKit backend for macOS.
- Add UIKit backend for iOS.
- Decide Zig/Objective-C bridge strategy.
- Add simulator workflow.
- Add packaging/signing notes.

Done when:

- Hello/counter/form run on macOS.
- Hello/counter/form run in iOS simulator.

## Milestone 13 - Packaging

Goal: make real app output easy.

Tasks:

- Add app manifest.
- Add icons/assets.
- Add `zig build package`.
- Add per-platform output folders.
- Add release-small builds.
- Add signing hooks where needed.

Done when:

- ZUI can produce a runnable desktop package and Android APK.

## Milestone 14 - Size And Performance

Goal: prove the promises with measurements.

Tasks:

- Track binary size.
- Track startup time.
- Track memory usage.
- Track first-window time.
- Add benchmark examples.
- Compare against common frameworks where fair.

Done when:

- Roadmap includes measured numbers, not only claims.
- Regressions are visible during development.

## Immediate Next Steps

1. Create the package skeleton.
2. Add the simplest `zui.run` API.
3. Build the first Win32 window.
4. Add `view` and `text`.
5. Make `examples/hello.zig` real.

