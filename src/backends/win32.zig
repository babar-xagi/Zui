const std = @import("std");

const HWND = ?*anyopaque;
const HINSTANCE = ?*anyopaque;
const HICON = ?*anyopaque;
const HCURSOR = ?*anyopaque;
const HBRUSH = ?*anyopaque;
const HMENU = ?*anyopaque;
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

const LayoutRect = struct {
    x: i32,
    y: i32,
    width: i32,
    height: i32,
};

const StateHeader = struct {
    relayout: *const fn (*StateHeader, HWND) void,
};

const TextControl = struct {
    hwnd: HWND,
};

fn BackendState(comptime Node: type) type {
    return struct {
        header: StateHeader,
        root: Node,
        text_controls: []TextControl,
    };
}

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

const CS_VREDRAW = 0x0001;
const CS_HREDRAW = 0x0002;
const CW_USEDEFAULT = @as(i32, @bitCast(@as(u32, 0x80000000)));
const SW_SHOWNORMAL = 1;
const WS_OVERLAPPEDWINDOW = 0x00CF0000;
const WS_CHILD = 0x40000000;
const WS_VISIBLE = 0x10000000;
const WM_DESTROY = 0x0002;
const WM_SIZE = 0x0005;
const GWLP_USERDATA = -21;
const COLOR_WINDOW = 5;

const default_window_width = 800;
const default_window_height = 600;
const default_text_height = 28;

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
extern "user32" fn GetClientRect(hWnd: HWND, lpRect: *RECT) callconv(.winapi) BOOL;
extern "user32" fn GetSysColorBrush(nIndex: i32) callconv(.winapi) HBRUSH;
extern "user32" fn MoveWindow(hWnd: HWND, x: i32, y: i32, nWidth: i32, nHeight: i32, bRepaint: BOOL) callconv(.winapi) BOOL;
extern "user32" fn SetWindowLongPtrW(hWnd: HWND, nIndex: i32, dwNewLong: isize) callconv(.winapi) isize;
extern "user32" fn GetWindowLongPtrW(hWnd: HWND, nIndex: i32) callconv(.winapi) isize;

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
    _ = SetWindowLongPtrW(hwnd, GWLP_USERDATA, @as(isize, @intCast(@intFromPtr(&state.header))));

    try createTextControls(Node, allocator, instance, hwnd, app.root, state.text_controls);
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
        .header = .{ .relayout = relayoutHeader(Node) },
        .root = root,
        .text_controls = try allocator.alloc(TextControl, root.textCount()),
    };
    return state;
}

fn createTextControls(
    comptime Node: type,
    allocator: std.mem.Allocator,
    instance: HINSTANCE,
    parent: HWND,
    root: Node,
    text_controls: []TextControl,
) !void {
    var next_index: usize = 0;
    try createTextControlsForNode(Node, allocator, instance, parent, root, text_controls, &next_index);
}

fn createTextControlsForNode(
    comptime Node: type,
    allocator: std.mem.Allocator,
    instance: HINSTANCE,
    parent: HWND,
    node: Node,
    text_controls: []TextControl,
    next_index: *usize,
) !void {
    switch (node) {
        .text => |text_node| {
            const text = std.unicode.utf8ToUtf16LeAllocZ(allocator, text_node.value) catch return Error.InvalidUtf8;
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

            text_controls[next_index.*] = .{ .hwnd = text_hwnd };
            next_index.* += 1;
        },
        .view => |view_node| {
            for (view_node.children) |child| {
                try createTextControlsForNode(Node, allocator, instance, parent, child, text_controls, next_index);
            }
        },
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

    var next_index: usize = 0;
    _ = layoutNode(Node, state.root, state.text_controls, &next_index, rect);
}

fn measureNode(comptime Node: type, node: Node, available_width: i32) i32 {
    return switch (node) {
        .text => default_text_height,
        .view => |view_node| {
            const padding: i32 = @intCast(view_node.style.padding);
            const gap: i32 = @intCast(view_node.style.gap);
            if (view_node.children.len == 0) return padding * 2;

            return switch (view_node.style.direction) {
                .column => blk: {
                    var height = padding * 2 + gap * @as(i32, @intCast(view_node.children.len - 1));
                    for (view_node.children) |child| {
                        height += measureNode(Node, child, available_width);
                    }
                    break :blk height;
                },
                .row => blk: {
                    var height: i32 = 0;
                    for (view_node.children) |child| {
                        height = @max(height, measureNode(Node, child, available_width));
                    }
                    break :blk height + padding * 2;
                },
            };
        },
    };
}

fn layoutNode(comptime Node: type, node: Node, text_controls: []TextControl, next_index: *usize, rect: LayoutRect) i32 {
    return switch (node) {
        .text => {
            const control = text_controls[next_index.*];
            next_index.* += 1;
            _ = MoveWindow(
                control.hwnd,
                rect.x,
                rect.y,
                @max(1, rect.width),
                default_text_height,
                1,
            );
            return default_text_height;
        },
        .view => |view_node| switch (view_node.style.direction) {
            .column => layoutColumn(Node, view_node, text_controls, next_index, rect),
            .row => layoutRow(Node, view_node, text_controls, next_index, rect),
        },
    };
}

fn layoutColumn(comptime Node: type, view_node: anytype, text_controls: []TextControl, next_index: *usize, rect: LayoutRect) i32 {
    const padding: i32 = @intCast(view_node.style.padding);
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

        const child_height = layoutNode(Node, child, text_controls, next_index, .{
            .x = child_x,
            .y = y,
            .width = child_width,
            .height = @max(1, rect.height - used_height - padding),
        });

        y += child_height;
        used_height += child_height;
    }

    return used_height + padding;
}

fn layoutRow(comptime Node: type, view_node: anytype, text_controls: []TextControl, next_index: *usize, rect: LayoutRect) i32 {
    const padding: i32 = @intCast(view_node.style.padding);
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

        const used_height = layoutNode(Node, child, text_controls, next_index, .{
            .x = x,
            .y = rect.y + padding,
            .width = child_width,
            .height = child_height,
        });

        measured_height = @max(measured_height, used_height);
        x += child_width;
    }

    return measured_height + padding * 2;
}

fn windowProc(hwnd: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT {
    switch (msg) {
        WM_SIZE => {
            const raw_state = GetWindowLongPtrW(hwnd, GWLP_USERDATA);
            if (raw_state != 0) {
                const header: *StateHeader = @ptrFromInt(@as(usize, @intCast(raw_state)));
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
