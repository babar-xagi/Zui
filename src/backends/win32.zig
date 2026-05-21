const std = @import("std");

const HWND = ?*anyopaque;
const HINSTANCE = ?*anyopaque;
const HICON = ?*anyopaque;
const HCURSOR = ?*anyopaque;
const HBRUSH = ?*anyopaque;
const HMENU = ?*anyopaque;
const HDC = ?*anyopaque;
const HFONT = ?*anyopaque;
const HGDIOBJ = ?*anyopaque;
const LPCWSTR = [*:0]const u16;
const UINT = u32;
const DWORD = u32;
const BOOL = i32;
const ATOM = u16;
const WPARAM = usize;
const LPARAM = isize;
const LRESULT = isize;
const WNDPROC = *const fn (HWND, UINT, WPARAM, LPARAM) callconv(.winapi) LRESULT;

const POINT = extern struct {
    x: i32,
    y: i32,
};

const RECT = extern struct {
    left: i32,
    top: i32,
    right: i32,
    bottom: i32,
};

const MSG = extern struct {
    hwnd: HWND,
    message: UINT,
    wParam: WPARAM,
    lParam: LPARAM,
    time: DWORD,
    pt: POINT,
};

const WNDCLASSEXW = extern struct {
    cbSize: UINT,
    style: UINT,
    lpfnWndProc: ?WNDPROC,
    cbClsExtra: i32,
    cbWndExtra: i32,
    hInstance: HINSTANCE,
    hIcon: HICON,
    hCursor: HCURSOR,
    hbrBackground: HBRUSH,
    lpszMenuName: ?LPCWSTR,
    lpszClassName: LPCWSTR,
    hIconSm: HICON,
};

const PAINTSTRUCT = extern struct {
    hdc: HDC,
    fErase: BOOL,
    rcPaint: RECT,
    fRestore: BOOL,
    fIncUpdate: BOOL,
    rgbReserved: [32]u8,
};

const LayoutRect = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};

const StateHeader = struct {
    relayout: *const fn (*StateHeader, HWND) void,
    refresh: *const fn (*StateHeader, HWND) void,
    command: *const fn (*StateHeader, u16) void,
    paint: *const fn (*StateHeader, HDC) void,
    control_color: *const fn (*StateHeader, HWND, HDC) LRESULT,
};

const COLORREF = u32;

const ControlKind = enum {
    text,
    button,
};

const NativeControl = struct {
    hwnd: HWND,
    kind: ControlKind,
    id: u16 = 0,
    on_click: ?*const fn () void = null,
    text_color: ?COLORREF = null,
    background: ?COLORREF = null,
    background_brush: HBRUSH = null,
    inherited_background: ?COLORREF = null,
    inherited_background_brush: HBRUSH = null,
    font: HFONT = null,
    height: i32,
};

const ViewBackground = struct {
    rect: LayoutRect,
    background: ?COLORREF = null,
};

fn BackendState(comptime Node: type) type {
    return struct {
        header: StateHeader,
        allocator: std.mem.Allocator,
        root: Node,
        controls: []NativeControl,
        view_backgrounds: []ViewBackground,
    };
}

var active_header: ?*StateHeader = null;
var active_hwnd: HWND = null;

const Error = error{
    InvalidUtf8,
    ModuleHandleUnavailable,
    ClassRegistrationFailed,
    WindowCreationFailed,
    ControlCreationFailed,
    MessageLoopFailed,
};

const class_name = std.unicode.utf8ToUtf16LeStringLiteral("ZUIWindowClass");
const static_class = std.unicode.utf8ToUtf16LeStringLiteral("STATIC");
const button_class = std.unicode.utf8ToUtf16LeStringLiteral("BUTTON");

const CS_VREDRAW = 0x0001;
const CS_HREDRAW = 0x0002;
const CW_USEDEFAULT = @as(i32, @bitCast(@as(u32, 0x80000000)));
const SW_SHOWNORMAL = 1;
const WS_OVERLAPPEDWINDOW = 0x00CF0000;
const WS_CHILD = 0x40000000;
const WS_VISIBLE = 0x10000000;
const WM_DESTROY = 0x0002;
const WM_PAINT = 0x000F;
const WM_ERASEBKGND = 0x0014;
const WM_SIZE = 0x0005;
const WM_COMMAND = 0x0111;
const WM_SETFONT = 0x0030;
const WM_CTLCOLORBTN = 0x0135;
const WM_CTLCOLORSTATIC = 0x0138;
const GWLP_USERDATA = -21;
const COLOR_WINDOW = 5;
const BN_CLICKED = 0;
const TRANSPARENT = 1;
const DEFAULT_CHARSET = 1;

const default_window_width = 800;
const default_window_height = 600;
const default_text_height = 28;
const default_button_height = 34;
const estimated_text_width_percent = 58;
const first_control_id = 1000;

extern "kernel32" fn GetModuleHandleW(lpModuleName: ?LPCWSTR) callconv(.winapi) HINSTANCE;
extern "user32" fn RegisterClassExW(lpWndClass: *const WNDCLASSEXW) callconv(.winapi) ATOM;
extern "user32" fn CreateWindowExW(
    dwExStyle: DWORD,
    lpClassName: LPCWSTR,
    lpWindowName: LPCWSTR,
    dwStyle: DWORD,
    x: i32,
    y: i32,
    nWidth: i32,
    nHeight: i32,
    hWndParent: HWND,
    hMenu: HMENU,
    hInstance: HINSTANCE,
    lpParam: ?*anyopaque,
) callconv(.winapi) HWND;
extern "user32" fn ShowWindow(hWnd: HWND, nCmdShow: i32) callconv(.winapi) BOOL;
extern "user32" fn UpdateWindow(hWnd: HWND) callconv(.winapi) BOOL;
extern "user32" fn GetMessageW(lpMsg: *MSG, hWnd: HWND, wMsgFilterMin: UINT, wMsgFilterMax: UINT) callconv(.winapi) BOOL;
extern "user32" fn TranslateMessage(lpMsg: *const MSG) callconv(.winapi) BOOL;
extern "user32" fn DispatchMessageW(lpMsg: *const MSG) callconv(.winapi) LRESULT;
extern "user32" fn DefWindowProcW(hWnd: HWND, msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
extern "user32" fn PostQuitMessage(nExitCode: i32) callconv(.winapi) void;
extern "user32" fn BeginPaint(hWnd: HWND, lpPaint: *PAINTSTRUCT) callconv(.winapi) HDC;
extern "user32" fn EndPaint(hWnd: HWND, lpPaint: *const PAINTSTRUCT) callconv(.winapi) BOOL;
extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) BOOL;
extern "user32" fn GetSysColorBrush(nIndex: i32) callconv(.winapi) HBRUSH;
extern "user32" fn MoveWindow(hWnd: HWND, x: i32, y: i32, nWidth: i32, nHeight: i32, bRepaint: BOOL) callconv(.winapi) BOOL;
extern "user32" fn SetWindowTextW(hWnd: HWND, lpString: LPCWSTR) callconv(.winapi) BOOL;
extern "user32" fn SendMessageW(hWnd: HWND, Msg: UINT, wParam: WPARAM, lParam: LPARAM) callconv(.winapi) LRESULT;
extern "user32" fn InvalidateRect(hWnd: HWND, lpRect: ?*const RECT, bErase: BOOL) callconv(.winapi) BOOL;
extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: i32, dwNewLong: isize) callconv(.winapi) isize;
extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: i32) callconv(.winapi) isize;
extern "gdi32" fn CreateSolidBrush(color: COLORREF) callconv(.winapi) HBRUSH;
extern "gdi32" fn DeleteObject(ho: HGDIOBJ) callconv(.winapi) BOOL;
extern "gdi32" fn FillRect(hdc: HDC, lprc: *const RECT, hbr: HBRUSH) callconv(.winapi) i32;
extern "gdi32" fn SetTextColor(hdc: HDC, color: COLORREF) callconv(.winapi) COLORREF;
extern "gdi32" fn SetBkColor(hdc: HDC, color: COLORREF) callconv(.winapi) COLORREF;
extern "gdi32" fn SetBkMode(hdc: HDC, mode: i32) callconv(.winapi) i32;
extern "gdi32" fn CreateFontW(
    cHeight: i32,
    cWidth: i32,
    cEscapement: i32,
    cOrientation: i32,
    cWeight: i32,
    bItalic: DWORD,
    bUnderline: DWORD,
    bStrikeOut: DWORD,
    iCharSet: DWORD,
    iOutPrecision: DWORD,
    iClipPrecision: DWORD,
    iQuality: DWORD,
    iPitchAndFamily: DWORD,
    pszFaceName: ?LPCWSTR,
) callconv(.winapi) HFONT;

pub fn run(app: anytype) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const Node = @TypeOf(app.root);
    const title = std.unicode.utf8ToUtf16LeAllocZ(allocator, app.app_name) catch return Error.InvalidUtf8;
    const instance = GetModuleHandleW(null) orelse return Error.ModuleHandleUnavailable;
    try registerWindowClass(instance);

    const hwnd = CreateWindowExW(
        0,
        class_name.ptr,
        title.ptr,
        WS_OVERLAPPEDWINDOW,
        CW_USEDEFAULT,
        CW_USEDEFAULT,
        default_window_width,
        default_window_height,
        null,
        null,
        instance,
        null,
    ) orelse return Error.WindowCreationFailed;

    const state = try createBackendState(Node, allocator, app.root);
    _ = SetWindowLongPtrW(hwnd, GWLP_USERDATA, pointerToLResult(&state.header));
    active_header = &state.header;
    active_hwnd = hwnd;
    app.set_invalidator(refreshActiveWindow);
    defer {
        app.set_invalidator(null);
        active_header = null;
        active_hwnd = null;
    }

    try createNativeControls(Node, allocator, instance, hwnd, app.root, state.controls);
    relayoutWindow(Node, state, hwnd);

    _ = ShowWindow(hwnd, SW_SHOWNORMAL);
    _ = UpdateWindow(hwnd);

    var msg: MSG = undefined;
    while (true) {
        const result = GetMessageW(&msg, null, 0, 0);
        if (result == -1) {
            return Error.MessageLoopFailed;
        }
        if (result == 0) {
            break;
        }
        _ = TranslateMessage(&msg);
        _ = DispatchMessageW(&msg);
    }
}

fn registerWindowClass(instance: HINSTANCE) !void {
    const window_class = WNDCLASSEXW{
        .cbSize = @sizeOf(WNDCLASSEXW),
        .style = CS_HREDRAW | CS_VREDRAW,
        .lpfnWndProc = windowProc,
        .cbClsExtra = 0,
        .cbWndExtra = 0,
        .hInstance = instance,
        .hIcon = null,
        .hCursor = null,
        .hbrBackground = GetSysColorBrush(COLOR_WINDOW),
        .lpszMenuName = null,
        .lpszClassName = class_name.ptr,
        .hIconSm = null,
    };

    if (RegisterClassExW(&window_class) == 0) {
        return Error.ClassRegistrationFailed;
    }
}

fn createBackendState(comptime Node: type, allocator: std.mem.Allocator, root: Node) !*BackendState(Node) {
    const state = try allocator.create(BackendState(Node));
    state.* = .{
        .header = .{
            .relayout = relayoutHeader(Node),
            .refresh = refreshHeader(Node),
            .command = commandHeader(Node),
            .paint = paintHeader(Node),
            .control_color = controlColorHeader(Node),
        },
        .allocator = allocator,
        .root = root,
        .controls = try allocator.alloc(NativeControl, root.controlCount()),
        .view_backgrounds = try allocator.alloc(ViewBackground, root.viewCount()),
    };
    return state;
}

fn createNativeControls(
    comptime Node: type,
    allocator: std.mem.Allocator,
    instance: HINSTANCE,
    parent: HWND,
    root: Node,
    controls: []NativeControl,
) !void {
    var next_index: usize = 0;
    try createNativeControlsForNode(Node, allocator, instance, parent, root, controls, &next_index);
}

fn createNativeControlsForNode(
    comptime Node: type,
    allocator: std.mem.Allocator,
    instance: HINSTANCE,
    parent: HWND,
    node: Node,
    controls: []NativeControl,
    next_index: *usize,
) !void {
    switch (node) {
        .text => |text_node| {
            const text = std.unicode.utf8ToUtf16LeAllocZ(allocator, text_node.value) catch return Error.InvalidUtf8;
            const background = optionalColorToRef(text_node.style.fill());
            const font = try createFont(allocator, text_node.style);
            const text_hwnd = CreateWindowExW(
                0,
                static_class.ptr,
                text.ptr,
                WS_CHILD | WS_VISIBLE,
                0,
                0,
                1,
                1,
                parent,
                null,
                instance,
                null,
            ) orelse return Error.ControlCreationFailed;
            applyFont(text_hwnd, font);

            controls[next_index.*] = .{
                .hwnd = text_hwnd,
                .kind = .text,
                .text_color = optionalColorToRef(text_node.style.foreground()),
                .background = background,
                .background_brush = createOptionalBrush(background),
                .font = font,
                .height = textHeight(text_node.style),
            };
            next_index.* += 1;
        },
        .button => |button_node| {
            const label = std.unicode.utf8ToUtf16LeAllocZ(allocator, button_node.label) catch return Error.InvalidUtf8;
            const background = optionalColorToRef(button_node.style.fill());
            const font = try createFont(allocator, button_node.style);
            const control_id: u16 = @intCast(first_control_id + next_index.*);
            const button_hwnd = CreateWindowExW(
                0,
                button_class.ptr,
                label.ptr,
                WS_CHILD | WS_VISIBLE,
                0,
                0,
                1,
                1,
                parent,
                @ptrFromInt(control_id),
                instance,
                null,
            ) orelse return Error.ControlCreationFailed;
            applyFont(button_hwnd, font);

            controls[next_index.*] = .{
                .hwnd = button_hwnd,
                .kind = .button,
                .id = control_id,
                .on_click = button_node.on_click,
                .text_color = optionalColorToRef(button_node.style.foreground()),
                .background = background,
                .background_brush = createOptionalBrush(background),
                .font = font,
                .height = buttonHeight(button_node.style),
            };
            next_index.* += 1;
        },
        .view => |view_node| {
            for (view_node.children) |child| {
                try createNativeControlsForNode(Node, allocator, instance, parent, child, controls, next_index);
            }
        },
    }
}

fn optionalColorToRef(maybe_color: anytype) ?COLORREF {
    if (maybe_color) |color| {
        return colorToRef(color);
    }
    return null;
}

fn colorToRef(color: anytype) COLORREF {
    return @as(COLORREF, color.r) |
        (@as(COLORREF, color.g) << 8) |
        (@as(COLORREF, color.b) << 16);
}

fn createOptionalBrush(color: ?COLORREF) HBRUSH {
    if (color) |value| {
        return CreateSolidBrush(value);
    }
    return null;
}

fn createFont(allocator: std.mem.Allocator, style: anytype) !HFONT {
    if (style.fontSize() == 14 and style.fontWeight() == .regular and style.font_family == null) {
        return null;
    }

    const face_name = if (style.font_family) |family|
        (std.unicode.utf8ToUtf16LeAllocZ(allocator, family) catch return Error.InvalidUtf8).ptr
    else
        null;

    return CreateFontW(
        -@as(i32, @intCast(style.fontSize())),
        0,
        0,
        0,
        fontWeightToWin32(style.fontWeight()),
        0,
        0,
        0,
        DEFAULT_CHARSET,
        0,
        0,
        0,
        0,
        face_name,
    );
}

fn textHeight(style: anytype) i32 {
    return textLineHeight(style);
}

fn textLineHeight(style: anytype) i32 {
    const size: i32 = @intCast(style.fontSize());
    return @max(default_text_height, size + 10);
}

fn estimatedTextHeight(value: []const u8, style: anytype, available_width: i32) i32 {
    const line_height = textLineHeight(style);
    if (available_width <= 0 or value.len == 0) return line_height;

    const size: i32 = @intCast(style.fontSize());
    const estimated_char_width = @max(6, @divTrunc(size * estimated_text_width_percent, 100));
    const chars_per_line: usize = @intCast(@max(1, @divTrunc(available_width, estimated_char_width)));
    const line_count = @max(@as(usize, 1), std.math.divCeil(usize, value.len, chars_per_line) catch 1);
    return line_height * @as(i32, @intCast(line_count));
}

fn buttonHeight(style: anytype) i32 {
    const size: i32 = @intCast(style.fontSize());
    return @max(default_button_height, size + 18);
}

fn fontWeightToWin32(weight: anytype) i32 {
    return switch (weight) {
        .regular => 400,
        .medium => 500,
        .semibold => 600,
        .bold => 700,
    };
}

fn applyFont(hwnd: HWND, font: HFONT) void {
    if (font) |value| {
        _ = SendMessageW(hwnd, WM_SETFONT, @intFromPtr(value), 1);
    }
}

fn relayoutHeader(comptime Node: type) *const fn (*StateHeader, HWND) void {
    return struct {
        fn relayout(header: *StateHeader, hwnd: HWND) void {
            const state: *BackendState(Node) = @fieldParentPtr("header", header);
            relayoutWindow(Node, state, hwnd);
        }
    }.relayout;
}

fn refreshHeader(comptime Node: type) *const fn (*StateHeader, HWND) void {
    return struct {
        fn refresh(header: *StateHeader, hwnd: HWND) void {
            const state: *BackendState(Node) = @fieldParentPtr("header", header);
            refreshWindow(Node, state, hwnd) catch {};
        }
    }.refresh;
}

fn commandHeader(comptime Node: type) *const fn (*StateHeader, u16) void {
    return struct {
        fn command(header: *StateHeader, control_id: u16) void {
            const state: *BackendState(Node) = @fieldParentPtr("header", header);
            for (state.controls) |control| {
                if (control.kind == .button and control.id == control_id) {
                    if (control.on_click) |on_click| {
                        on_click();
                    }
                    return;
                }
            }
        }
    }.command;
}

fn paintHeader(comptime Node: type) *const fn (*StateHeader, HDC) void {
    return struct {
        fn paint(header: *StateHeader, hdc: HDC) void {
            const state: *BackendState(Node) = @fieldParentPtr("header", header);
            paintViewBackgrounds(state, hdc);
        }
    }.paint;
}

fn controlColorHeader(comptime Node: type) *const fn (*StateHeader, HWND, HDC) LRESULT {
    return struct {
        fn controlColor(header: *StateHeader, control_hwnd: HWND, hdc: HDC) LRESULT {
            const state: *BackendState(Node) = @fieldParentPtr("header", header);
            for (state.controls) |control| {
                if (control.hwnd == control_hwnd) {
                    if (control.text_color) |text_color| {
                        _ = SetTextColor(hdc, text_color);
                    }

                    if (effectiveControlBackground(control)) |background| {
                        _ = SetBkColor(hdc, background);
                        return brushToResult(effectiveControlBackgroundBrush(control));
                    }

                    _ = SetBkMode(hdc, TRANSPARENT);
                    return brushToResult(GetSysColorBrush(COLOR_WINDOW));
                }
            }

            return brushToResult(GetSysColorBrush(COLOR_WINDOW));
        }
    }.controlColor;
}

fn paintViewBackgrounds(state: anytype, hdc: HDC) void {
    for (state.view_backgrounds) |view_background| {
        const background = view_background.background orelse continue;
        const brush = CreateSolidBrush(background) orelse continue;
        var rect = toWin32Rect(view_background.rect);
        _ = FillRect(hdc, &rect, brush);
        _ = DeleteObject(brush);
    }
}

fn brushToResult(brush: HBRUSH) LRESULT {
    if (brush) |value| {
        return pointerToLResult(value);
    }
    return 0;
}

fn pointerToLResult(pointer: *anyopaque) LRESULT {
    return @as(LRESULT, @bitCast(@intFromPtr(pointer)));
}

fn updateInheritedBackground(control: *NativeControl, background: ?COLORREF) void {
    if (control.background != null) return;
    if (control.inherited_background == background) return;

    control.inherited_background = background;
    control.inherited_background_brush = createOptionalBrush(background);
}

fn effectiveControlBackground(control: NativeControl) ?COLORREF {
    return control.background orelse control.inherited_background;
}

fn effectiveControlBackgroundBrush(control: NativeControl) HBRUSH {
    if (control.background_brush != null) return control.background_brush;
    if (control.inherited_background_brush != null) return control.inherited_background_brush;
    return GetSysColorBrush(COLOR_WINDOW);
}

fn refreshActiveWindow() void {
    if (active_header) |header| {
        if (active_hwnd != null) {
            header.refresh(header, active_hwnd);
        }
    }
}

fn relayoutWindow(comptime Node: type, state: *BackendState(Node), hwnd: HWND) void {
    var client: RECT = undefined;
    const rect = if (GetClientRect(hwnd, &client) != 0)
        LayoutRect{
            .x = 0,
            .y = 0,
            .width = @max(1, client.right - client.left),
            .height = @max(1, client.bottom - client.top),
        }
    else
        LayoutRect{
            .x = 0,
            .y = 0,
            .width = default_window_width,
            .height = default_window_height,
        };

    var next_control_index: usize = 0;
    var next_view_index: usize = 0;
    _ = layoutNode(Node, state, state.root, &next_control_index, &next_view_index, rect, null);
    _ = InvalidateRect(hwnd, null, 0);
}

fn refreshWindow(comptime Node: type, state: *BackendState(Node), hwnd: HWND) !void {
    var next_index: usize = 0;
    try refreshNode(Node, state.allocator, state.root, state.controls, &next_index);
    relayoutWindow(Node, state, hwnd);
}

fn refreshNode(
    comptime Node: type,
    allocator: std.mem.Allocator,
    node: Node,
    controls: []NativeControl,
    next_index: *usize,
) !void {
    switch (node) {
        .text => |text_node| {
            const control = controls[next_index.*];
            next_index.* += 1;

            if (text_node.dynamic) |dynamic| {
                const value = dynamic.render(dynamic.context, allocator);
                const text = std.unicode.utf8ToUtf16LeAllocZ(allocator, value) catch return Error.InvalidUtf8;
                _ = SetWindowTextW(control.hwnd, text.ptr);
            }
        },
        .button => {
            next_index.* += 1;
        },
        .view => |view_node| {
            for (view_node.children) |child| {
                try refreshNode(Node, allocator, child, controls, next_index);
            }
        },
    }
}

fn shrinkRect(rect: LayoutRect, amount: i32) LayoutRect {
    return .{
        .x = rect.x + amount,
        .y = rect.y + amount,
        .width = @max(1, rect.width - amount * 2),
        .height = @max(1, rect.height - amount * 2),
    };
}

fn toWin32Rect(rect: LayoutRect) RECT {
    return .{
        .left = rect.x,
        .top = rect.y,
        .right = rect.x + @max(1, rect.width),
        .bottom = rect.y + @max(1, rect.height),
    };
}

fn measureNode(comptime Node: type, node: Node, available_width: i32) i32 {
    return switch (node) {
        .text => |text_node| estimatedTextHeight(text_node.value, text_node.style, available_width),
        .button => |button_node| buttonHeight(button_node.style),
        .view => |view_node| {
            const padding: i32 = @intCast(view_node.style.paddingValue());
            const margin: i32 = @intCast(view_node.style.marginValue());
            const gap: i32 = @intCast(view_node.style.gap);
            if (view_node.children.len == 0) return padding * 2 + margin * 2;

            const content_height = switch (view_node.style.direction) {
                .column => blk: {
                    var height = padding * 2 + gap * @as(i32, @intCast(view_node.children.len - 1));
                    const child_width = @max(1, available_width - padding * 2 - margin * 2);
                    for (view_node.children) |child| {
                        height += measureNode(Node, child, child_width);
                    }
                    break :blk height;
                },
                .row => blk: {
                    const child_count: i32 = @intCast(view_node.children.len);
                    const total_gap = gap * @max(0, child_count - 1);
                    const content_width = @max(1, available_width - padding * 2 - margin * 2 - total_gap);
                    const child_width = @max(1, @divTrunc(content_width, child_count));
                    var height: i32 = 0;
                    for (view_node.children) |child| {
                        height = @max(height, measureNode(Node, child, child_width));
                    }
                    break :blk height + padding * 2;
                },
            };
            return content_height + margin * 2;
        },
    };
}

fn layoutNode(
    comptime Node: type,
    state: *BackendState(Node),
    node: Node,
    next_control_index: *usize,
    next_view_index: *usize,
    rect: LayoutRect,
    inherited_background: ?COLORREF,
) i32 {
    return switch (node) {
        .text => |text_node| {
            const control = &state.controls[next_control_index.*];
            next_control_index.* += 1;
            updateInheritedBackground(control, inherited_background);
            const height = estimatedTextHeight(text_node.value, text_node.style, rect.width);
            control.height = height;
            _ = MoveWindow(
                control.hwnd,
                rect.x,
                rect.y,
                @max(1, rect.width),
                height,
                1,
            );
            return height;
        },
        .button => {
            const control = &state.controls[next_control_index.*];
            next_control_index.* += 1;
            updateInheritedBackground(control, inherited_background);
            _ = MoveWindow(
                control.hwnd,
                rect.x,
                rect.y,
                @max(1, rect.width),
                control.height,
                1,
            );
            return control.height;
        },
        .view => |view_node| layoutView(Node, state, view_node, next_control_index, next_view_index, rect, inherited_background),
    };
}

fn layoutView(
    comptime Node: type,
    state: *BackendState(Node),
    view_node: anytype,
    next_control_index: *usize,
    next_view_index: *usize,
    rect: LayoutRect,
    inherited_background: ?COLORREF,
) i32 {
    const margin: i32 = @intCast(view_node.style.marginValue());
    const view_rect = shrinkRect(rect, margin);
    const background_index = next_view_index.*;
    next_view_index.* += 1;
    const is_root_view = background_index == 0;
    const view_background = optionalColorToRef(view_node.style.fill()) orelse inherited_background;

    const used_height = switch (view_node.style.direction) {
        .column => layoutColumn(Node, state, view_node, next_control_index, next_view_index, view_rect, view_background),
        .row => layoutRow(Node, state, view_node, next_control_index, next_view_index, view_rect, view_background),
    };

    state.view_backgrounds[background_index] = .{
        .rect = .{
            .x = view_rect.x,
            .y = view_rect.y,
            .width = view_rect.width,
            .height = if (is_root_view) view_rect.height else @min(view_rect.height, @max(1, used_height)),
        },
        .background = view_background,
    };

    return used_height + margin * 2;
}

fn layoutColumn(
    comptime Node: type,
    state: *BackendState(Node),
    view_node: anytype,
    next_control_index: *usize,
    next_view_index: *usize,
    rect: LayoutRect,
    inherited_background: ?COLORREF,
) i32 {
    const padding: i32 = @intCast(view_node.style.paddingValue());
    const gap: i32 = @intCast(view_node.style.gap);
    const child_x = rect.x + padding;
    const child_width = @max(1, rect.width - padding * 2);
    var y = rect.y + padding;
    var used_height = padding;

    for (view_node.children, 0..) |child, index| {
        if (index > 0) {
            y += gap;
            used_height += gap;
        }

        const child_height = layoutNode(Node, state, child, next_control_index, next_view_index, .{
            .x = child_x,
            .y = y,
            .width = child_width,
            .height = @max(1, rect.height - used_height - padding),
        }, inherited_background);

        y += child_height;
        used_height += child_height;
    }

    return used_height + padding;
}

fn layoutRow(
    comptime Node: type,
    state: *BackendState(Node),
    view_node: anytype,
    next_control_index: *usize,
    next_view_index: *usize,
    rect: LayoutRect,
    inherited_background: ?COLORREF,
) i32 {
    const padding: i32 = @intCast(view_node.style.paddingValue());
    const gap: i32 = @intCast(view_node.style.gap);
    if (view_node.children.len == 0) return padding * 2;

    const child_count: i32 = @intCast(view_node.children.len);
    const total_gap = gap * @max(0, child_count - 1);
    const content_width = @max(1, rect.width - padding * 2 - total_gap);
    const child_width = @max(1, @divTrunc(content_width, child_count));
    const child_height = @max(1, rect.height - padding * 2);
    var x = rect.x + padding;
    var measured_height: i32 = 0;

    for (view_node.children, 0..) |child, index| {
        if (index > 0) x += gap;

        const used_height = layoutNode(Node, state, child, next_control_index, next_view_index, .{
            .x = x,
            .y = rect.y + padding,
            .width = child_width,
            .height = child_height,
        }, inherited_background);

        measured_height = @max(measured_height, used_height);
        x += child_width;
    }

    return measured_height + padding * 2;
}

fn lowWord(value: WPARAM) u16 {
    return @intCast(value & 0xffff);
}

fn highWord(value: WPARAM) u16 {
    return @intCast((value >> 16) & 0xffff);
}

fn hwndFromLParam(value: LPARAM) HWND {
    return @ptrFromInt(@as(usize, @bitCast(value)));
}

fn hdcFromWParam(value: WPARAM) HDC {
    return @ptrFromInt(value);
}

fn stateHeaderFromWindow(hwnd: HWND) ?*StateHeader {
    const raw_state = GetWindowLongPtrW(hwnd, GWLP_USERDATA);
    if (raw_state == 0) return null;
    return @ptrFromInt(@as(usize, @bitCast(raw_state)));
}

fn windowProc(hwnd: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT {
    switch (msg) {
        WM_ERASEBKGND => {
            return 1;
        },
        WM_PAINT => {
            var paint: PAINTSTRUCT = undefined;
            const hdc = BeginPaint(hwnd, &paint);
            if (stateHeaderFromWindow(hwnd)) |header| {
                header.paint(header, hdc);
            }
            _ = EndPaint(hwnd, &paint);
            return 0;
        },
        WM_CTLCOLORSTATIC, WM_CTLCOLORBTN => {
            if (stateHeaderFromWindow(hwnd)) |header| {
                return header.control_color(header, hwndFromLParam(lparam), hdcFromWParam(wparam));
            }
            return brushToResult(GetSysColorBrush(COLOR_WINDOW));
        },
        WM_COMMAND => {
            if (highWord(wparam) == BN_CLICKED) {
                if (stateHeaderFromWindow(hwnd)) |header| {
                    header.command(header, lowWord(wparam));
                }
                return 0;
            }
            return DefWindowProcW(hwnd, msg, wparam, lparam);
        },
        WM_SIZE => {
            if (stateHeaderFromWindow(hwnd)) |header| {
                header.relayout(header, hwnd);
            }
            return 0;
        },
        WM_DESTROY => {
            PostQuitMessage(0);
            return 0;
        },
        else => return DefWindowProcW(hwnd, msg, wparam, lparam),
    }
}
