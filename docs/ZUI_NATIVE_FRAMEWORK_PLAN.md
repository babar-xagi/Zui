# ZUI Native Framework Plan

This document records the first study pass over the Capy codebase and turns the goal into small implementation phases for a new framework named ZUI.

ZUI is a from-scratch project. Capy is only research material: useful for ideas, architecture lessons, platform notes, and possible pitfalls. We should not treat Capy as the codebase to port unless we deliberately choose to reimplement a specific idea in new ZUI code.

The target is a cross-platform UI framework that feels as easy as React Native or Flutter, but keeps the core in Zig 0.16, uses native platform controls where possible, stays fast, and produces tiny apps.

## Why ZUI Is Separate From Capy

- We want freedom to design the easiest possible beginner API without preserving Capy's current public API.
- We can start with Zig 0.16 from day one instead of migrating a Zig 0.14.1 codebase first.
- We can keep the architecture smaller and more intentional: public API, runtime, layout, platform backend, packaging.
- We can use Capy's strongest ideas, such as native peers, shared layout, reactive properties, and backend selection, without inheriting unfinished code or old build constraints.
- We can design mobile support as a first-class goal instead of adding it after desktop.

## Verified Starting Point

- Local toolchain: `zig version` reports `0.16.0`.
- Official Zig download page lists `0.16.0` as the stable release dated `2026-04-13`.
- Current Capy package metadata still targets Zig `0.14.1`.
- `build_capy.zig` has a compile-time check that rejects anything except Zig `0.14.1`.
- `zig build test` currently fails before source compilation because Zig 0.16 rejects two dependency hashes in `build.zig.zon` as incomplete:
  - `zig-objc` hash at `build.zig.zon:9`
  - `macos_sdk` hash at `build.zig.zon:14`
- Zig 0.16 release notes call out language, standard library, and build system changes that matter here, including `@Type` replacement work, migration toward unmanaged containers, I/O interface changes, and build system package changes.

Sources checked:

- Zig downloads: https://ziglang.org/download/
- Zig 0.16 release notes: https://ziglang.org/download/0.16.0/release-notes.html

## Capy File Map

### Root

- `README.md`: project overview, goals, example app, supported platform/component matrix.
- `build.zig`: creates the `capy` module, links backend dependencies, builds examples, C shared library, tests, docs, and coverage.
- `build_capy.zig`: reusable build/run helpers, WASM dev server, Android run setup, and Zig version guard.
- `build.zig.zon`: package metadata and dependencies.
- `flake.nix`, `flake.lock`, `.envrc`: Nix development environment pinned around Zig `0.14.1`.
- `LICENSE`: MPL-2.0.

### Public API

- `src/capy.zig`: main public facade. Re-exports `Window`, `Widget`, all components, layouts, colors, data types, backend helpers, audio, HTTP, testing, event loop functions.
- `src/window.zig`: high-level window wrapper around backend windows. Owns root child, window size, frame events, fullscreen, menu bar, DPI source, and animation controller.
- `src/widget.zig`: generic widget handle and vtable-like `Class`. Gives every component a common shape: show, deinit, preferred size, parent lookup, display state, ref/unref.
- `src/backend.zig`: compile-time backend selector. Chooses Win32, macOS, GTK, Android, or WASM based on target and wraps drawing commands in `DrawContext`.

### Component Runtime

- `src/internal.zig`: component machinery. Generates config structs from `Atom` fields, applies configs, provides common events, reference counting, user data lookup, generic widget creation, and tuple-to-widget conversion.
- `src/data.zig`: reactive data layer. Defines `Atom(T)`, `ListAtom(T)`, derived atoms, formatted atoms, implicit animation support, `Size`, `Position`, and `Rectangle`.
- `src/list.zig`: list helpers for mapping data to widgets.
- `src/listener.zig`: event source/listener system.
- `src/timer.zig`: timers driven by Capy's event step.
- `src/AnimationController.zig`: animation frame coordination.
- `src/trait.zig`: compatibility helpers for Zig type traits.
- `src/testing.zig`: early virtual testing surface.

### Layout

- `src/containers.zig`: layout engine and `Container`.
  - `row`, `column`, `stack`, `margin`, `grid`
  - expanded children
  - CSS-grid-inspired partial implementation
  - layout callbacks into backend containers

### Components

- `src/components/Alignment.zig`
- `src/components/Button.zig`
- `src/components/Canvas.zig`
- `src/components/CheckBox.zig`
- `src/components/Dropdown.zig`
- `src/components/Image.zig`
- `src/components/Label.zig`
- `src/components/Menu.zig`
- `src/components/Navigation.zig`
- `src/components/NavigationSidebar.zig`
- `src/components/Scrollable.zig`
- `src/components/Slider.zig`
- `src/components/Tabs.zig`
- `src/components/TextArea.zig`
- `src/components/TextField.zig`

Component pattern:

- Each component owns reactive `Atom` properties.
- `internal.All(Component)` adds widget behavior and event methods.
- `show()` creates a backend peer lazily.
- Property changes update the native peer through atom change listeners.
- Helper constructors such as `capy.button(.{ ... })` allocate components.

### Backends

- `src/backends/shared.zig`: common event enums, mouse button enum, message type, backend errors, gradient data.
- `src/backends/win32/*`: native Win32 controls, Direct2D/GDI drawing, monitor support, dropdown helper, resources, manifest.
- `src/backends/gtk/*`: GTK4 backend. `gtk.zig` is a large generated binding file and should be treated as generated/vendor-like source.
- `src/backends/macos/*`: AppKit backend work in progress, Objective-C bridge helpers, macOS monitor and button support.
- `src/backends/android/backend.zig`: Android backend using JNI and native Android `View` classes.
- `src/backends/wasm/*`: WASM backend with JavaScript host files, DOM/canvas peers, worker, index HTML, and JS imports.
- `src/backends/gles/*`: experimental OpenGL/GLFW-style backend and shaders.

### Mobile Support Package

- `android/Sdk.zig`: Android SDK/APK build helpers.
- `android/build.zig`: standalone Android template build.
- `android/src/*.zig`: Android, JNI, EGL, audio, and support bindings.
- `android/src/*.java`, `.class`, `classes.dex`: Java bridge and precompiled support artifacts.
- `android/examples/*`: minimal, EGL, TextView, invocation handler examples.
- `android/vendor/kuba-zip/*`: APK zip helper dependency.

### C ABI

- `src/c_api.zig`: shared library entry points.
- `include/capy.h`: C header.
- `c_examples/*`: C usage example/build script.

### Assets And Examples

- `assets/ziglogo.png`: sample asset.
- `examples/*`: real usage examples, including calculator, notepad, tabs, graph, media player, weather, demos, 7GUIs, and backend tests.

### Vendor/Generated

- `vendor/zigwin32/*`: vendored/generated Win32 bindings. This is not where the new framework API should be designed.
- `src/backends/gtk/gtk.zig`: generated GTK binding. Avoid manual edits unless regenerating.

## Capy Architecture Lessons

Capy shows a useful foundation for a Zig-native UI framework:

- UI code is Zig-first and declarative.
- Widgets are native peer wrappers, not HTML views or a JS bridge.
- Properties are reactive through `Atom`.
- Layout is in shared Zig code and applies positions/sizes through backend containers.
- Backends are selected at compile time.
- WASM, Android, Win32, GTK, and macOS paths already exist.
- Examples show real apps with a single Zig codebase.

Important gaps to avoid or redesign in ZUI:

- Capy does not build on Zig 0.16 yet.
- The current API is easy for Zig users, but not yet React/Flutter-easy for beginners.
- Literal JSX cannot be parsed by Zig. A JSX-like syntax requires either a separate `.zui`/`.jsx` build step or a pure Zig DSL that looks similar.
- Android is experimental. iOS does not exist yet.
- Several backend methods are TODO or partial, especially post-empty-event, mobile drawing, advanced input, menus, and some component support.
- The current component model allocates many widgets and uses runtime peer objects. It is still much smaller than Electron/React Native style stacks, but needs measurement and optimization.

## Product Goal

ZUI should be:

- Easy: beginner-friendly screen functions, simple state, predictable layout, few required concepts.
- Native: platform controls by default, native accessibility by default, no JS bridge on desktop/mobile.
- Fast: compile-time backend selection, direct native calls, no VM, no garbage collector, no browser engine for desktop/mobile.
- Tiny: tree-shaken Zig binaries, optional features, `ReleaseSmall`, stripped symbols, no bundled engine unless selected.
- Single-codebase: one app source can target Windows, Linux, macOS, Android, iOS, and Web.
- Honest: expose escape hatches for platform-specific code instead of pretending all platforms are identical.

## Recommended ZUI API Direction

Start with a pure Zig DSL. It can be made very easy without inventing a parser first.

```zig
const zui = @import("zui");

pub fn HomeScreen() zui.Node {
    return zui.view(.{}, .{
        zui.text("Hello World!"),
    });
}

pub fn main() !void {
    try zui.run(.{
        .app_name = "HelloZUI",
        .root = HomeScreen,
    });
}
```

FastAPI-style app registration can come next:

```zig
const zui = @import("zui");

pub fn build(app: *zui.App) void {
    app.screen("/", HomeScreen);
    app.screen("/settings", SettingsScreen);
}

fn HomeScreen() zui.Node {
    return zui.view(.{}, .{
        zui.text("Hello World!"),
    });
}
```

State should be simple:

```zig
fn Counter() zui.Node {
    const count = zui.state(i32, 0);

    return zui.row(.{ .gap = 8 }, .{
        zui.text(count.format("{}")),
        zui.button(.{
            .text = "Count",
            .on_click = zui.fn0(struct {
                fn run() void {
                    count.update(.add, 1);
                }
            }.run),
        }),
    });
}
```

Optional JSX-like syntax should be Phase 4 or later:

```tsx
function HomeScreen() {
  return (
    <View>
      <Text>Hello World!</Text>
    </View>
  );
}
```

That syntax should compile to the pure Zig DSL through a build step. The Zig DSL must stay the source of truth so the framework remains simple, debuggable, and independent of a custom language.

## Architecture Target

### Layers

1. `zui` public API
   - `run`, `App`, `screen`, `view`, `text`, `button`, `input`, `image`, `list`, `stack`, `row`, `column`
   - beginner-friendly names and defaults

2. Runtime/reconciler
   - stable `Node` tree
   - keyed children
   - diff and patch existing native peers
   - state invalidation and redraw scheduling

3. Reactive data
   - keep Capy's `Atom` ideas
   - simplify public state API
   - keep lower-level `Atom` available for advanced apps

4. Layout/style
   - shared layout engine
   - row/column/grid/stack first
   - later: flexbox-like layout if needed
   - style tokens that map to native controls where possible

5. Backend interface
   - small required peer API per component
   - feature flags/capabilities per platform
   - shared tests that run against each backend

6. Platform packages
   - Desktop: Win32, GTK, AppKit
   - Mobile: Android Views, iOS UIKit
   - Web: WASM with DOM/canvas

7. Tooling
   - `zig build run`
   - `zig build web`
   - `zig build android`
   - `zig build ios`
   - `zig build package`
   - app manifest and icons in Zig/ZON

### Native Controls vs Custom Drawing

Recommended hybrid:

- Default to native controls for buttons, text fields, menus, tabs, accessibility, keyboard input, focus, and platform look.
- Use shared Zig layout for consistency.
- Add optional custom/canvas components for charts, games, drawing, and advanced visuals.
- Avoid a full custom-rendered UI engine until the native layer is stable.

This keeps app size small and accessibility strong. The cost is that some controls will look and behave slightly differently across platforms.

## Differentiators To Aim For

- No JS bridge for native apps.
- No embedded Chromium or heavy UI engine by default.
- Full Zig frontend/backend in one language.
- C ABI export for embedding into other apps.
- Compile-time typed UI properties.
- Small native binaries when using platform toolkits already present on the OS.
- Built-in cross-compilation mindset.
- Direct platform escape hatches:

```zig
zui.platform(.windows).setWindowAccent(...);
zui.platform(.android).requestPermission(.camera);
```

- Capability checks:

```zig
if (zui.capabilities.menu_bar) {
    window.setMenuBar(...);
}
```

- App package metadata in Zig/ZON, not scattered Gradle/Xcode/project files where avoidable.
- Shared test harness for UI trees and layout without launching a full desktop app.

## Honest Tradeoffs

- Zig is lower-level than JavaScript or Dart, so the framework must hide common memory and event complexity.
- Native widgets make accessibility and size better, but pixel-perfect cross-platform identity harder.
- Mobile requires platform bridge work. Android is started; iOS is a full backend project.
- Hot reload will be harder than React Native/Flutter. Start with fast rebuilds and state-preserving dev mode later.
- Linux native UI means choosing a toolkit. Capy currently uses GTK4.
- Tiny size on Linux depends on dynamic system GTK. Bundling GTK would make distribution larger.
- Capy's Zig 0.16 migration is optional reference work. ZUI starts on Zig 0.16 directly.
- A JSX-like syntax is not free. It adds a parser/transpiler/toolchain surface.

## Implementation Phases

### Phase 0 - Fresh ZUI Skeleton

Goal: create a clean Zig 0.16 project that belongs to ZUI, not Capy.

Tasks:

- Add `build.zig` and `build.zig.zon` for a new `zui` package.
- Add `src/zui.zig` as the public API entry point.
- Add `src/main.zig` or `examples/hello.zig` for the first app.
- Add a tiny test target.
- Add `README.md` explaining that Capy is reference material only.
- Keep the package dependency-free at first.
- Run `zig build test`.

Exit criteria:

- `zig build test` passes.
- `zig build run` can run a placeholder console example.
- Package metadata clearly requires Zig `0.16.0`.

### Phase 1 - Minimal Native Hello

Goal: make the first native window with the beginner API.

Tasks:

- Add `zui.run`, `zui.Node`, `zui.view`, and `zui.text`.
- Implement one backend first. On this machine, Win32 is the practical first backend.
- Create `examples/hello.zig`.
- Keep the first layout simple: one window, one root view, one text child.
- Add a beginner quickstart page.

Exit criteria:

- Hello app is under 20 lines.
- User does not need to manually create a platform window or event loop for the simplest app.
- The app shows native text in a native window.

### Phase 2 - Screen/App Model

Goal: make apps feel like single-codebase mobile/desktop/web apps.

Tasks:

- Add screen registration.
- Add navigation primitives.
- Add app lifecycle hooks.
- Add platform capability checks.
- Add simple app config: name, bundle id/package name, icon, permissions.

Exit criteria:

- One source file can define two screens and navigate between them.
- Desktop and web use the same screen function.

### Phase 3 - State And Reconciliation

Goal: make UI updates natural and avoid full rebuild/recreate on every change.

Tasks:

- Design `zui.state`.
- Design a new state store, borrowing only the good ideas from Capy's `Atom`.
- Add keyed nodes.
- Add minimal diff/patch for children.
- Keep internals small enough that a user can understand the state model.

Exit criteria:

- Counter, todo list, and form examples are concise.
- Updating state changes native peers without rebuilding the whole window.

### Phase 4 - Layout And Styling Upgrade

Goal: make `View` and `Text` feel familiar while staying native.

Tasks:

- Define `ViewStyle`, `TextStyle`, spacing, padding, alignment, colors.
- Map styles to native control capabilities.
- Add clear behavior for unsupported style properties.
- Improve grid/flex behavior or integrate a proven small layout algorithm if needed.

Exit criteria:

- Common screens can be built without dropping to backend-specific code.
- Unsupported style properties are reported or ignored predictably.

### Phase 5 - Desktop Native MVP

Goal: stable desktop support first.

Tasks:

- Windows: stabilize Win32 controls, input, DPI, menus, text, scroll, tabs.
- Linux: stabilize GTK4 backend and build dependencies.
- macOS: complete AppKit window/button/text/input/container basics.
- Add per-backend component conformance tests.

Exit criteria:

- Hello, counter, form, tabs, scroll/list, and canvas examples work on Windows, Linux, and macOS.

### Phase 6 - Web/WASM MVP

Goal: compile the same app to the browser.

Tasks:

- Update WASM build/run to Zig 0.16.
- Stabilize `capy.js`, worker, DOM peers, events, and assets.
- Add `zig build web` convenience command.
- Add static hosting output folder.

Exit criteria:

- Hello/counter/form examples run in browser.
- Generated assets are small and cacheable.

### Phase 7 - Android MVP

Goal: turn the experimental Android backend into a real target.

Tasks:

- Update Android helper package to Zig 0.16.
- Stabilize APK building/signing.
- Replace deprecated `AbsoluteLayout` direction with a sustainable layout/view strategy.
- Add app lifecycle handling.
- Add text input, keyboard, scroll, permissions, icons, orientation.

Exit criteria:

- Hello/counter/form examples install and run on a device/emulator.

### Phase 8 - iOS MVP

Goal: add native iOS support.

Tasks:

- Decide bridge strategy: Objective-C runtime from Zig, generated bindings, or small Objective-C shim.
- Implement UIKit window/root view/controller.
- Implement basic controls.
- Build `.app`/simulator workflow.
- Add signing/export notes.

Exit criteria:

- Hello/counter/form examples run in iOS simulator.

### Phase 9 - Tooling And Packaging

Goal: make running all platforms easy.

Tasks:

- `zui init`
- `zig build run`
- `zig build run -Dplatform=web`
- `zig build run -Dplatform=android`
- `zig build package -Dplatform=windows/linux/macos/android/ios/web`
- app icons/assets/permissions from one manifest
- local dev server for web
- device install/run for Android and iOS

Exit criteria:

- A beginner can create, run, and package an app without learning every platform tool first.

### Phase 10 - Optional JSX-Like Syntax

Goal: offer React-like syntax after the pure Zig API is stable.

Tasks:

- Define `.zui` or `.zui.tsx` syntax.
- Write parser/transpiler to Zig DSL.
- Integrate with `build.zig`.
- Source maps or readable generated Zig for debugging.

Exit criteria:

- JSX-like screens compile to the same `zui.Node` tree as the Zig DSL.
- Pure Zig users are not forced to use the transpiler.

### Phase 11 - Performance And Size Program

Goal: prove the promises.

Tasks:

- Add benchmark apps.
- Measure binary size in `Debug`, `ReleaseFast`, `ReleaseSmall`.
- Measure startup time, memory, first window time, event latency.
- Compare against Electron, Tauri, React Native, Flutter where fair.
- Tree-shake optional components/backends.
- Strip symbols in release packages.

Exit criteria:

- Published size/performance table.
- Regressions caught in CI.

## First Implementation Recommendation

Do not begin with JSX. Begin with a fresh ZUI skeleton and the easiest native hello-world path:

1. Create the new `zui` package skeleton.
2. Add `zui.run`, `zui.view`, `zui.text`, and a tiny app example.
3. Implement one desktop backend first, probably Win32 on this machine.
4. Measure the binary.
5. Add the next backend only after the core API feels right.
6. Decide later whether to add JSX-like syntax tooling.

This gives us a real working base quickly and avoids spending time on syntax before the native foundation is proven.
