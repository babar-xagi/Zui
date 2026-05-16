const std = @import("std");
const backend = @import("backend.zig");

var active_allocator: ?std.mem.Allocator = null;

pub const AppOptions = struct {
    app_name: []const u8 = "ZUI App",
    root: *const fn () Node,
};

pub const ViewStyle = struct {
    gap: u16 = 0,
    padding: u16 = 0,
};

pub const TextNode = struct {
    value: []const u8,
};

pub const ViewNode = struct {
    style: ViewStyle,
    children: []const Node,
};

pub const Node = union(enum) {
    text: TextNode,
    view: ViewNode,

    pub fn debugPrint(self: Node, indent: usize) void {
        printIndent(indent);
        switch (self) {
            .text => |node| std.debug.print("Text(\"{s}\")\n", .{node.value}),
            .view => |node| {
                std.debug.print("View(gap={}, padding={})\n", .{ node.style.gap, node.style.padding });
                for (node.children) |child| {
                    child.debugPrint(indent + 2);
                }
            },
        }
    }

    pub fn firstText(self: Node) ?[]const u8 {
        return switch (self) {
            .text => |node| node.value,
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
            .view => |node| {
                var count: usize = 0;
                for (node.children) |child| {
                    count += child.textCount();
                }
                return count;
            },
        };
    }
};

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
    });
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

pub fn text(value: []const u8) Node {
    return .{
        .text = .{
            .value = value,
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
