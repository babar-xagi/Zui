const std = @import("std");
const backend = @import("backend.zig");

var active_allocator: ?std.mem.Allocator = null;
var active_invalidator: ?InvalidateHandler = null;

pub const InvalidateHandler = *const fn () void;

pub const AppOptions = struct {
    app_name: []const u8 = "ZUI App",
    root: *const fn () Element,
};

pub const LayoutDirection = enum {
    column,
    row,
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8 = 255,

    pub fn rgb(r: u8, g: u8, b: u8) Color {
        return .{ .r = r, .g = g, .b = b };
    }

    pub fn rgba(r: u8, g: u8, b: u8, a: u8) Color {
        return .{ .r = r, .g = g, .b = b, .a = a };
    }
};

pub const colors = struct {
    pub const white = Color.rgb(255, 255, 255);
    pub const black = Color.rgb(0, 0, 0);
    pub const slate_50 = Color.rgb(248, 250, 252);
    pub const slate_100 = Color.rgb(241, 245, 249);
    pub const slate_700 = Color.rgb(51, 65, 85);
    pub const slate_900 = Color.rgb(15, 23, 42);
    pub const blue_600 = Color.rgb(37, 99, 235);
    pub const emerald_600 = Color.rgb(5, 150, 105);
    pub const amber_500 = Color.rgb(245, 158, 11);
    pub const rose_600 = Color.rgb(225, 29, 72);
};

pub const FontWeight = enum {
    regular,
    medium,
    semibold,
    bold,
};

pub const TextStyle = struct {
    fg: ?Color = null,
    bg: ?Color = null,
    size: ?u16 = null,
    weight: ?FontWeight = null,
    color: ?Color = null,
    background: ?Color = null,
    font_size: u16 = 14,
    font_weight: FontWeight = .regular,
    font_family: ?[]const u8 = null,

    pub fn foreground(self: TextStyle) ?Color {
        return self.fg orelse self.color;
    }

    pub fn fill(self: TextStyle) ?Color {
        return self.bg orelse self.background;
    }

    pub fn fontSize(self: TextStyle) u16 {
        return self.size orelse self.font_size;
    }

    pub fn fontWeight(self: TextStyle) FontWeight {
        return self.weight orelse self.font_weight;
    }
};

pub const ButtonStyle = struct {
    fg: ?Color = null,
    bg: ?Color = null,
    size: ?u16 = null,
    weight: ?FontWeight = null,
    color: ?Color = null,
    background: ?Color = null,
    font_size: u16 = 14,
    font_weight: FontWeight = .regular,
    font_family: ?[]const u8 = null,

    pub fn foreground(self: ButtonStyle) ?Color {
        return self.fg orelse self.color;
    }

    pub fn fill(self: ButtonStyle) ?Color {
        return self.bg orelse self.background;
    }

    pub fn fontSize(self: ButtonStyle) u16 {
        return self.size orelse self.font_size;
    }

    pub fn fontWeight(self: ButtonStyle) FontWeight {
        return self.weight orelse self.font_weight;
    }
};

pub const ViewStyle = struct {
    gap: u16 = 0,
    p: ?u16 = null,
    m: ?u16 = null,
    bg: ?Color = null,
    padding: u16 = 0,
    margin: u16 = 0,
    direction: LayoutDirection = .column,
    background: ?Color = null,

    pub fn paddingValue(self: ViewStyle) u16 {
        return self.p orelse self.padding;
    }

    pub fn marginValue(self: ViewStyle) u16 {
        return self.m orelse self.margin;
    }

    pub fn fill(self: ViewStyle) ?Color {
        return self.bg orelse self.background;
    }
};

pub const TextRenderer = *const fn (context: *anyopaque, allocator: std.mem.Allocator) []const u8;

pub const DynamicText = struct {
    context: *anyopaque,
    render: TextRenderer,
};

pub const TextNode = struct {
    value: []const u8,
    dynamic: ?DynamicText = null,
    style: TextStyle = .{},
};

pub const ClickHandler = *const fn () void;

pub const ButtonOptions = struct {
    title: ?[]const u8 = null,
    label: ?[]const u8 = null,
    on_click: ?ClickHandler = null,
    style: ButtonStyle = .{},
    fg: ?Color = null,
    bg: ?Color = null,
    size: ?u16 = null,
    weight: ?FontWeight = null,
    color: ?Color = null,
    background: ?Color = null,
    font_size: ?u16 = null,
    font_weight: ?FontWeight = null,
};

pub const ButtonNode = struct {
    label: []const u8,
    on_click: ?ClickHandler,
    style: ButtonStyle = .{},
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
                    "View(direction={s}, gap={}, padding={}, margin={})\n",
                    .{ @tagName(node.style.direction), node.style.gap, node.style.paddingValue(), node.style.marginValue() },
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

    pub fn viewCount(self: Node) usize {
        return switch (self) {
            .text, .button => 0,
            .view => |node| {
                var count: usize = 1;
                for (node.children) |child| {
                    count += child.viewCount();
                }
                return count;
            },
        };
    }
};

pub const Element = Node;

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

pub fn state(comptime T: type, initial: T) State(T) {
    return State(T).init(initial);
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

pub fn view(children: anytype) Element {
    return makeView(.{}, children);
}

fn makeView(style: ViewStyle, children: anytype) Element {
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

pub fn column(style: ViewStyle, children: anytype) Element {
    var column_style = style;
    column_style.direction = .column;
    return makeView(column_style, children);
}

pub fn row(style: ViewStyle, children: anytype) Element {
    var row_style = style;
    row_style.direction = .row;
    return makeView(row_style, children);
}

pub fn text(value: []const u8) Element {
    return .{
        .text = .{
            .value = value,
        },
    };
}

pub fn textFmt(comptime format: []const u8, args: anytype) Element {
    const allocator = active_allocator orelse @panic("zui.textFmt must be called inside zui.run for now");
    return text(std.fmt.allocPrint(allocator, format, args) catch @panic("out of memory"));
}

pub const TextOptions = struct {
    value: []const u8,
    style: TextStyle = .{},
};

pub fn styledText(options: TextOptions) Element {
    return .{
        .text = .{
            .value = options.value,
            .style = options.style,
        },
    };
}

pub fn styledTextFmt(comptime format: []const u8, args: anytype, style: TextStyle) Element {
    const allocator = active_allocator orelse @panic("zui.styledTextFmt must be called inside zui.run for now");
    return styledText(.{
        .value = std.fmt.allocPrint(allocator, format, args) catch @panic("out of memory"),
        .style = style,
    });
}

pub fn t(value: []const u8, style: TextStyle) Element {
    return styledText(.{
        .value = value,
        .style = style,
    });
}

pub fn button(options: ButtonOptions) Element {
    const title = options.title orelse options.label orelse @panic("zui.button requires .title");
    var style = options.style;
    style.fg = options.fg orelse options.color orelse style.fg;
    style.bg = options.bg orelse options.background orelse style.bg;
    style.size = options.size orelse options.font_size orelse style.size;
    style.weight = options.weight orelse options.font_weight orelse style.weight;

    return .{
        .button = .{
            .label = title,
            .on_click = options.on_click,
            .style = style,
        },
    };
}

pub fn stateText(
    comptime T: type,
    state_value: *const State(T),
    formatter: *const fn (T, std.mem.Allocator) []const u8,
) Element {
    return styledStateText(T, state_value, formatter, .{});
}

pub fn styledStateText(
    comptime T: type,
    state_value: *const State(T),
    formatter: *const fn (T, std.mem.Allocator) []const u8,
    style: TextStyle,
) Element {
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
            .style = style,
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

test "colors create rgb and rgba values" {
    const blue = Color.rgb(1, 2, 3);
    try std.testing.expectEqual(@as(u8, 1), blue.r);
    try std.testing.expectEqual(@as(u8, 2), blue.g);
    try std.testing.expectEqual(@as(u8, 3), blue.b);
    try std.testing.expectEqual(@as(u8, 255), blue.a);

    const translucent = Color.rgba(1, 2, 3, 4);
    try std.testing.expectEqual(@as(u8, 4), translucent.a);
}

test "button creates a button node" {
    const node = button(.{ .title = "Press" });
    try std.testing.expectEqualStrings("Press", node.button.label);
    try std.testing.expectEqual(@as(?ClickHandler, null), node.button.on_click);
}

test "button still accepts label as a compatibility name" {
    const node = button(.{ .label = "Press" });
    try std.testing.expectEqualStrings("Press", node.button.label);
}

test "state stores and updates a value" {
    var counter = state(i32, 3);
    try std.testing.expectEqual(@as(i32, 3), counter.get());

    counter.set(4);
    try std.testing.expectEqual(@as(i32, 4), counter.get());
}

test "view stores children in the active build arena with default style" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const node = view(.{
        text("A"),
        text("B"),
    });

    try std.testing.expectEqual(@as(u16, 0), node.view.style.gap);
    try std.testing.expectEqual(@as(u16, 0), node.view.style.padding);
    try std.testing.expectEqual(LayoutDirection.column, node.view.style.direction);
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

    const node = view(.{
        view(.{
            text("Nested"),
        }),
        text("Later"),
    });

    try std.testing.expectEqualStrings("Nested", node.firstText().?);
}

test "firstText can use a button label" {
    const node = button(.{ .title = "Launch" });
    try std.testing.expectEqualStrings("Launch", node.firstText().?);
}

test "textFmt formats text with the active build arena" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const node = textFmt("Count: {}", .{@as(i32, 5)});
    try std.testing.expectEqualStrings("Count: 5", node.text.value);
}

test "styledText stores text style" {
    const node = styledText(.{
        .value = "Title",
        .style = .{
            .color = colors.blue_600,
            .background = colors.slate_50,
            .font_size = 24,
            .font_weight = .bold,
        },
    });

    try std.testing.expectEqualStrings("Title", node.text.value);
    try std.testing.expectEqual(@as(u16, 24), node.text.style.font_size);
    try std.testing.expectEqual(FontWeight.bold, node.text.style.font_weight);
    try std.testing.expectEqual(colors.blue_600.r, node.text.style.color.?.r);
}

test "short style aliases resolve to the same style model" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const text_node = t("Title", .{
        .fg = colors.white,
        .bg = colors.blue_600,
        .size = 22,
        .weight = .semibold,
    });

    try std.testing.expectEqual(colors.white.r, text_node.text.style.foreground().?.r);
    try std.testing.expectEqual(colors.blue_600.b, text_node.text.style.fill().?.b);
    try std.testing.expectEqual(@as(u16, 22), text_node.text.style.fontSize());
    try std.testing.expectEqual(FontWeight.semibold, text_node.text.style.fontWeight());

    const container = column(.{ .p = 12, .m = 4, .bg = colors.slate_900 }, .{
        text("A"),
    });

    try std.testing.expectEqual(@as(u16, 12), container.view.style.paddingValue());
    try std.testing.expectEqual(@as(u16, 4), container.view.style.marginValue());
    try std.testing.expectEqual(colors.slate_900.g, container.view.style.fill().?.g);
}

test "button accepts flattened style aliases" {
    const node = button(.{
        .title = "Save",
        .fg = colors.white,
        .bg = colors.emerald_600,
        .size = 16,
        .weight = .bold,
    });

    try std.testing.expectEqualStrings("Save", node.button.label);
    try std.testing.expectEqual(colors.white.r, node.button.style.foreground().?.r);
    try std.testing.expectEqual(colors.emerald_600.g, node.button.style.fill().?.g);
    try std.testing.expectEqual(@as(u16, 16), node.button.style.fontSize());
    try std.testing.expectEqual(FontWeight.bold, node.button.style.fontWeight());
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

    var counter = state(i32, 7);
    const node = stateText(i32, &counter, Formatter.render);
    try std.testing.expectEqualStrings("Count: 7", node.text.value);

    counter.set(8);
    const dynamic = node.text.dynamic.?;
    const next_value = dynamic.render(dynamic.context, arena.allocator());
    try std.testing.expectEqualStrings("Count: 8", next_value);
}

test "styledStateText stores text style" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const Formatter = struct {
        fn render(value: i32, allocator: std.mem.Allocator) []const u8 {
            return std.fmt.allocPrint(allocator, "Value: {}", .{value}) catch @panic("out of memory");
        }
    };

    var value = state(i32, 12);
    const node = styledStateText(i32, &value, Formatter.render, .{
        .fg = colors.blue_600,
        .size = 18,
        .weight = .bold,
    });

    try std.testing.expectEqualStrings("Value: 12", node.text.value);
    try std.testing.expectEqual(colors.blue_600.b, node.text.style.foreground().?.b);
    try std.testing.expectEqual(@as(u16, 18), node.text.style.fontSize());
    try std.testing.expectEqual(FontWeight.bold, node.text.style.fontWeight());
}

test "textCount counts nested text nodes" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const node = view(.{
        text("A"),
        view(.{
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

    const node = view(.{
        text("A"),
        button(.{ .title = "B" }),
        view(.{
            text("C"),
            button(.{ .title = "D" }),
        }),
    });

    try std.testing.expectEqual(@as(usize, 4), node.controlCount());
}

test "viewCount counts logical views for background painting" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();

    active_allocator = arena.allocator();
    defer active_allocator = null;

    const node = column(.{ .background = colors.slate_50 }, .{
        text("A"),
        row(.{ .margin = 8 }, .{
            text("B"),
            text("C"),
        }),
    });

    try std.testing.expectEqual(@as(usize, 2), node.viewCount());
}
