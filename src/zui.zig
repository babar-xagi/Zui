const std = @import("std");
const backend = @import("backend.zig");

var active_allocator: ?std.mem.Allocator = null;
var active_invalidator: ?InvalidateHandler = null;

pub const InvalidateHandler = *const fn () void;

pub const AppOptions = struct {
    app_name: []const u8 = "ZUI App",
    root: *const fn () Node,
};

pub const LayoutDirection = enum {
    column,
    row,
};

pub const ViewStyle = struct {
    gap: u16 = 0,
    padding: u16 = 0,
    direction: LayoutDirection = .column,
};

pub const TextRenderer = *const fn (context: *anyopaque, allocator: std.mem.Allocator) []const u8;

pub const DynamicText = struct {
    context: *anyopaque,
    render: TextRenderer,
};

pub const TextNode = struct {
    value: []const u8,
    dynamic: ?DynamicText = null,
};

pub const ClickHandler = *const fn () void;

pub const ButtonOptions = struct {
    label: []const u8,
    on_click: ?ClickHandler = null,
};

pub const ButtonNode = struct {
    label: []const u8,
    on_click: ?ClickHandler,
};

pub const ViewNode = struct {
    style: ViewStyle,
    children: []const Node,
};

pub const Node = union(enum) {
    text: TextNode,
    button: ButtonNode,
    view: ViewNode,

    pub fn debugPrint(self: Node, indent: usize) void {
        printIndent(indent);
        switch (self) {
            .text => |node| std.debug.print("Text(\"{s}\")\n", .{node.value}),
            .button => |node| std.debug.print("Button(\"{s}\")\n", .{node.label}),
            .view => |node| {
                std.debug.print(
                    "View(direction={s}, gap={}, padding={})\n",
                    .{ @tagName(node.style.direction), node.style.gap, node.style.padding },
                );
                for (node.children) |child| {
                    child.debugPrint(indent + 2);
                }
            },
        }
    }

    pub fn firstText(self: Node) ?[]const u8 {
        return switch (self) {
            .text => |node| node.value,
            .button => |node| node.label,
            .view => |node| {
                for (node.children) |child| {
                    if (child.firstText()) |value| {
                        return value;
                    }
                }
                return null;
            },
        };
    }

    pub fn textCount(self: Node) usize {
        return switch (self) {
            .text => 1,
            .button => 0,
            .view => |node| {
                var count: usize = 0;
                for (node.children) |child| {
                    count += child.textCount();
                }
                return count;
            },
        };
    }

    pub fn controlCount(self: Node) usize {
        return switch (self) {
            .text, .button => 1,
            .view => |node| {
                var count: usize = 0;
                for (node.children) |child| {
                    count += child.controlCount();
                }
                return count;
            },
        };
    }
};

pub fn State(comptime T: type) type {
    return struct {
        value: T,

        pub fn init(initial: T) @This() {
            return .{ .value = initial };
        }

        pub fn get(self: *const @This()) T {
            return self.value;
        }

        pub fn set(self: *@This(), value: T) void {
            self.value = value;
            invalidate();
        }
    };
}

pub fn run(options: AppOptions) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const root_node = options.root();
    try backend.run(.{
        .app_name = options.app_name,
        .root_text = root_node.firstText() orelse options.app_name,
        .root = root_node,
        .set_invalidator = setInvalidator,
    });
}

pub fn invalidate() void {
    if (active_invalidator) |handler| {
        handler();
    }
}

fn setInvalidator(handler: ?InvalidateHandler) void {
    active_invalidator = handler;
}

pub fn view(style: ViewStyle, children: anytype) Node {
    const allocator = active_allocator orelse @panic("zui.view must be called inside zui.run for now");
    const fields = std.meta.fields(@TypeOf(children));
    const child_nodes = allocator.alloc(Node, fields.len) catch @panic("out of memory");

    inline for (fields, 0..) |field, index| {
        child_nodes[index] = @field(children, field.name);
    }

    return .{
        .view = .{
            .style = style,
            .children = child_nodes,
        },
    };
}

pub fn column(style: ViewStyle, children: anytype) Node {
    var column_style = style;
    column_style.direction = .column;
    return view(column_style, children);
}

pub fn row(style: ViewStyle, children: anytype) Node {
    var row_style = style;
    row_style.direction = .row;
    return view(row_style, children);
}

pub fn text(value: []const u8) Node {
    return .{
        .text = .{
            .value = value,
        },
    };
}

pub fn button(options: ButtonOptions) Node {
    return .{
        .button = .{
            .label = options.label,
            .on_click = options.on_click,
        },
    };
}

pub fn stateText(
    comptime T: type,
    state_value: *const State(T),
    formatter: *const fn (T, std.mem.Allocator) []const u8,
) Node {
    const allocator = active_allocator orelse @panic("zui.stateText must be called inside zui.run for now");

    const Binding = struct {
        state: *const State(T),
        format: *const fn (T, std.mem.Allocator) []const u8,

        fn render(context: *anyopaque, render_allocator: std.mem.Allocator) []const u8 {
            const binding: *@This() = @ptrCast(@alignCast(context));
            return binding.format(binding.state.get(), render_allocator);
        }
    };

    const binding = allocator.create(Binding) catch @panic("out of memory");
    binding.* = .{
        .state = state_value,
        .format = formatter,
    };

    return .{
        .text = .{
            .value = Binding.render(binding, allocator),
            .dynamic = .{
                .context = binding,
                .render = Binding.render,
            },
        },
    };
}

fn printIndent(indent: usize) void {
    for (0..indent) |_| {
        std.debug.print(" ", .{});
    }
}

test "text creates a text node" {
    const node = text("Hello");
    try std.testing.expectEqualStrings("Hello", node.text.value);
}

test "button creates a button node" {
    const node = button(.{ .label = "Press" });
    try std.testing.expectEqualStrings("Press", node.button.label);
    try std.testing.expectEqual(@as(?ClickHandler, null), node.button.on_click);
}

test "state stores and updates a value" {
    var counter = State(i32).init(3);
    try std.testing.expectEqual(@as(i32, 3), counter.get());

    counter.set(4);
    try std.testing.expectEqual(@as(i32, 4), counter.get());
}

test "view stores children in the active build arena" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const node = view(.{ .gap = 8, .padding = 12 }, .{
        text("A"),
        text("B"),
    });

    try std.testing.expectEqual(@as(u16, 8), node.view.style.gap);
    try std.testing.expectEqual(@as(u16, 12), node.view.style.padding);
    try std.testing.expectEqual(@as(usize, 2), node.view.children.len);
    try std.testing.expectEqualStrings("A", node.view.children[0].text.value);
    try std.testing.expectEqualStrings("B", node.view.children[1].text.value);
}

test "column and row set layout direction" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const column_node = column(.{ .gap = 4 }, .{
        text("A"),
    });
    const row_node = row(.{ .gap = 4 }, .{
        text("B"),
    });

    try std.testing.expectEqual(LayoutDirection.column, column_node.view.style.direction);
    try std.testing.expectEqual(LayoutDirection.row, row_node.view.style.direction);
}

test "firstText returns first nested text node" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const node = view(.{}, .{
        view(.{}, .{
            text("Nested"),
        }),
        text("Later"),
    });

    try std.testing.expectEqualStrings("Nested", node.firstText().?);
}

test "firstText can use a button label" {
    const node = button(.{ .label = "Launch" });
    try std.testing.expectEqualStrings("Launch", node.firstText().?);
}

test "stateText renders current state through a formatter" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const Formatter = struct {
        fn render(value: i32, allocator: std.mem.Allocator) []const u8 {
            return std.fmt.allocPrint(allocator, "Count: {}", .{value}) catch @panic("out of memory");
        }
    };

    var counter = State(i32).init(7);
    const node = stateText(i32, &counter, Formatter.render);
    try std.testing.expectEqualStrings("Count: 7", node.text.value);

    counter.set(8);
    const dynamic = node.text.dynamic.?;
    const next_value = dynamic.render(dynamic.context, arena.allocator());
    try std.testing.expectEqualStrings("Count: 8", next_value);
}

test "textCount counts nested text nodes" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const node = view(.{}, .{
        text("A"),
        view(.{}, .{
            text("B"),
            text("C"),
        }),
    });

    try std.testing.expectEqual(@as(usize, 3), node.textCount());
}

test "controlCount counts native text and button controls" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const node = view(.{}, .{
        text("A"),
        button(.{ .label = "B" }),
        view(.{}, .{
            text("C"),
            button(.{ .label = "D" }),
        }),
    });

    try std.testing.expectEqual(@as(usize, 4), node.controlCount());
}
