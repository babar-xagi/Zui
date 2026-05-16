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

pub fn run(app: anytype) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

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

    try renderRoot(@TypeOf(app.root), allocator, instance, hwnd, app.root);

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

fn renderRoot(comptime Node: type, allocator: std.mem.Allocator, instance: HINSTANCE, hwnd: HWND, root: Node) !void {
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

    _ = try renderNode(Node, allocator, instance, hwnd, root, rect);
}

fn renderNode(comptime Node: type, allocator: std.mem.Allocator, instance: HINSTANCE, parent: HWND, node: Node, rect: LayoutRect) !i32 {
    return switch (node) {
        .text => |text_node| try createTextControl(allocator, instance, parent, text_node.value, rect),
        .view => |view_node| blk: {
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

                const remaining_height = @max(1, rect.height - used_height - padding);
                const child_height = try renderNode(Node, allocator, instance, parent, child, .{
                    .x = child_x,
                    .y = y,
                    .width = child_width,
                    .height = remaining_height,
                });

                y += child_height;
                used_height += child_height;
            }

            break :blk used_height + padding;
        },
    };
}

fn createTextControl(allocator: std.mem.Allocator, instance: HINSTANCE, parent: HWND, value: []const u8, rect: LayoutRect) !i32 {
    const text = std.unicode.utf8ToUtf16LeAllocZ(allocator, value) catch return Error.InvalidUtf8;
    _ = CreateWindowExW(
        0,
        static_class.ptr,
        text.ptr,
        WS_CHILD | WS_VISIBLE,
        rect.x,
        rect.y,
        @max(1, rect.width),
        default_text_height,
        parent,
        null,
        instance,
        null,
    ) orelse return Error.ControlCreationFailed;

    return default_text_height;
}

fn windowProc(hwnd: HWND, msg: UINT, wparam: WPARAM, lparam: LPARAM) callconv(.winapi) LRESULT {
    switch (msg) {
        WM_DESTROY => {
            PostQuitMessage(0);
            return 0;
        },
        else => return DefWindowProcW(hwnd, msg, wparam, lparam),
    }
}
