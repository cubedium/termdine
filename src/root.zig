const std = @import("std");
const testing = std.testing;

// --------------------
// Colors               
// --------------------
pub const Color = struct {
    red: u8,
    green: u8,
    blue: u8,

    pub fn create_color(red: u8, green: u8, blue: u8) Color {
        return Color{ .red = red, .green = green, .blue = blue};
    }

    pub fn Red()    Color { return Color.create_color(255, 0  , 0  ); }
    pub fn Blue()   Color { return Color.create_color(0  , 0  , 255); }
    pub fn Green()  Color { return Color.create_color(0  , 255, 0  ); }
    pub fn Black()  Color { return Color.create_color(0  , 0  , 0  ); }
    pub fn White()  Color { return Color.create_color(255, 255, 255); }
    pub fn Orange() Color { return Color.create_color(255, 165, 0  ); }
    pub fn Yellow() Color { return Color.create_color(255, 255, 0  ); }
    pub fn Purple() Color { return Color.create_color(255, 0  , 255); }

    pub fn get_red(self: Color)   u8 { return self.red;   }
    pub fn get_blue(self: Color)  u8 { return self.blue;  }
    pub fn get_green(self: Color) u8 { return self.green; }
};

// --------------------
// Cells                
// --------------------
pub const Cell = struct {
    background_color: ?Color,
    foreground_color: Color,
    character: u8,

    pub fn create_cell(background_color: ?Color, foreground_color: Color, character: u8) Cell {
        return Cell{ .background_color = background_color, .foreground_color = foreground_color, .character = character};
    }

    pub fn draw(self: Cell) void {
        const character = switch (self.get_character()) {
            '\n' => ' ',
            else => self.get_character(),
        };

        if (self.get_background_color() != null) {
            std.debug.print("\x1b[48;2;{d};{d};{d}m", .{
                self.get_background_color().?.red,
                self.get_background_color().?.green,
                self.get_background_color().?.blue,
            });
        }
        std.debug.print("\x1b[38;2;{d};{d};{d}m", .{
            self.get_foreground_color().red,
            self.get_foreground_color().green,
            self.get_foreground_color().blue,
        });
        std.debug.print("{c}\x1b[0m", .{character});
    }

    pub fn change_character(self: *Cell, new_character: u8) void {
        self.character = new_character;
    }

    pub fn change_background_color(self: *Cell, new_background_color: Color) void {
        self.background_color = new_background_color;
    }

    pub fn change_foreground_color(self: *Cell, new_foreground_color: Color) void {
        self.foreground_color = new_foreground_color;
    }

    pub fn get_background_color(self: Cell) ?Color { return self.background_color; }
    pub fn get_foreground_color(self: Cell) Color  { return self.foreground_color; }
    pub fn get_character(self: Cell)        u8     { return self.character;        }
};

// --------------------
// Windows              
// --------------------
pub const WindowOptions = struct {
    border: bool = false,
    allocator: std.mem.Allocator,
};

pub const Window = struct {
    width: u16,
    height: u16,
    cursor: u16 = 0,
    border: bool,
    allocator: std.mem.Allocator,
    contents: []Cell = undefined,

    pub fn create_window(width: u16, height: u16, options: WindowOptions) Window {
        return Window{.width = width, .height = height, .border = options.border, .allocator = options.allocator}; 
    }

    pub fn init(self: *Window) !void {
        self.contents = try self.allocator.alloc(Cell, self.width * self.height);

        for (0..self.height) |y| {
            for (0..self.width) |x| {
                self.contents[x+y*self.width] = Cell.create_cell(null, Color.create_color(255, 255, 255), ' ');
            }
        }
    }

    pub fn deinit(self: *Window) void {
        self.allocator.free(self.contents);
    }

    pub fn write_character(self: *Window, character: u8) void {
        self.contents[self.cursor].change_character(character);
        self.cursor += 1;
    }

    pub fn write_string(self: *Window, string: []const u8) void {
        for (string) |character| {
            self.contents[self.cursor].change_character(character);
            self.cursor += 1;
        }
    }

    pub fn write_character_colored(self: *Window, character: u8, foreground_color: Color, background_color: ?Color) void {
        self.contents[self.cursor].change_character(character);
        self.contents[self.cursor].change_foreground_color(foreground_color);
        if (background_color != null) {
            self.contents[self.cursor].change_background_color(background_color.?);
        }
        self.cursor += 1;
    }

    pub fn write_string_colored(self: *Window, string: []const u8, foreground_color: Color, background_color: ?Color) void {
        for (string) |character| {
            self.contents[self.cursor].change_character(character);
            self.contents[self.cursor].change_foreground_color(foreground_color);
            if (background_color != null) {
                self.contents[self.cursor].change_background_color(background_color.?);
            }
            self.cursor += 1;
        }
    }

    pub fn move_cursor(self: *Window, x: u8, y: u8) void {
        self.cursor = x+y*self.width;
    }

    pub fn draw(self: *Window) void {
        // draw top border
        if (self.border) {
            std.debug.print("+", .{});
            for (0..self.width) |x| {
                std.debug.print("-", .{});
                _ = x;
            }
            std.debug.print("+\n", .{});
        }
        // draw contents
        for (0..self.height) |y| {
            // draw left border
            if (self.border) {
                std.debug.print("|", .{});
            }
            // draw contents
            for (0..self.width) |x| {
                self.contents[x+y*self.width].draw();
            }
            // draw right border
            if (self.border) {
                std.debug.print("|", .{});
            }
            std.debug.print("\n", .{});
        }
        // draw bottom border
        if (self.border) {
            std.debug.print("+", .{});
            for (0..self.width) |x| {
                std.debug.print("-", .{});
                _ = x;
            }
            std.debug.print("+\n", .{});
        }
        self.cursor = 0;
        std.debug.print("\x1b", .{});
    }

    pub fn get_string(self: Window, reader: anytype, buffer: []u8) ![]u8 {
        std.debug.print(": ", .{});
        _ = self;
        const read_bytes = try reader.read(buffer);

        return buffer[0..read_bytes];
    }

    pub fn has_border(self: Window) bool { return self.border; }
    pub fn get_width(self: Window)  u16  { return self.width;  }
    pub fn get_height(self: Window) u16  { return self.height; }
};

// --------------------
// Tests                
// --------------------
test "Window: create window" {
    const test_window  = Window.create_window(16, 9, .{.border = true, .allocator = testing.allocator});

    try testing.expectEqual(16, test_window.get_width());
    try testing.expectEqual(9, test_window.get_height());
    try testing.expectEqual(true, test_window.has_border());
    try testing.expectEqual(testing.allocator, test_window.allocator);
}

test "Window: get width" {
    const test_window  = Window.create_window(16, 9, .{.border = true, .allocator = testing.allocator});

    try testing.expectEqual(16, test_window.get_width());
}

test "Window: get height" {
    const test_window  = Window.create_window(16, 9, .{.border = true, .allocator = testing.allocator});

    try testing.expectEqual(9, test_window.get_height());
}

test "Window: has border" {
    const test_window  = Window.create_window(16, 9, .{.border = true, .allocator = testing.allocator});

    try testing.expect(test_window.has_border());
}

test "Window: init and deinit" {
    var test_window = Window.create_window(16, 9, .{.allocator = testing.allocator});

    try test_window.init();
    defer test_window.deinit();
}


test "Color: create color" {
    const yellow = Color.create_color(255, 255, 0);

    try testing.expectEqual(Color{.red = 255, .green = 255, .blue = 0}, yellow);
}

test "Color: color defaults" {
    try testing.expectEqual(Color{.red = 255, .green = 0  , .blue = 0  }, Color.Red()   );
    try testing.expectEqual(Color{.red = 0  , .green = 0  , .blue = 255}, Color.Blue()  );
    try testing.expectEqual(Color{.red = 0  , .green = 255, .blue = 0  }, Color.Green() );
    try testing.expectEqual(Color{.red = 0  , .green = 0  , .blue = 0  }, Color.Black() ); 
    try testing.expectEqual(Color{.red = 255, .green = 255, .blue = 255}, Color.White() );
    try testing.expectEqual(Color{.red = 255, .green = 165, .blue = 0  }, Color.Orange());
    try testing.expectEqual(Color{.red = 255, .green = 255, .blue = 0  }, Color.Yellow());
    try testing.expectEqual(Color{.red = 255, .green = 0  , .blue = 255}, Color.Purple());
}

test "Color: get red" {
    const yellow = Color.create_color(255, 255, 0);

    try testing.expectEqual(255, yellow.get_red());
}

test "Color: get green" {
    const yellow = Color.create_color(255, 255, 0);

    try testing.expectEqual(255, yellow.get_green());
}

test "Color: get blue" {
    const yellow = Color.create_color(255, 255, 0);

    try testing.expectEqual(0, yellow.get_blue());
}

test "Cell: create cell" {
    const test_cell = Cell.create_cell(Color.create_color(0, 0, 0), Color.create_color(255, 255, 255), 'E');

    try testing.expectEqual(Cell{.background_color = Color.create_color(0, 0, 0), .foreground_color = Color.create_color(255, 255, 255),
        .character = 'E'}, test_cell);
}

test "Cell: get character" {
    const test_cell = Cell.create_cell(Color.create_color(0, 0, 0), Color.create_color(255, 255, 255), 'E');

    try testing.expectEqual('E', test_cell.get_character());
}

test "Cell: get background color" {
    const test_cell = Cell.create_cell(Color.create_color(0, 0, 0), Color.create_color(255, 255, 255), 'E');

    try testing.expectEqual(Color.create_color(0, 0, 0), test_cell.get_background_color());
}

test "Cell: get foreground color" {
    const test_cell = Cell.create_cell(Color.create_color(0, 0, 0), Color.create_color(255, 255, 255), 'E');

    try testing.expectEqual(Color.create_color(255, 255, 255), test_cell.get_foreground_color());
}

test "Cell: change character" {
    var test_cell = Cell.create_cell(Color.create_color(0, 0, 0), Color.create_color(255, 255, 255), 'E');
    test_cell.change_character('W');

    try testing.expectEqual('W', test_cell.get_character());
}

test "Cell: change background color" {
    var test_cell = Cell.create_cell(Color.create_color(0, 0, 0), Color.create_color(255, 255, 255), 'E');
    test_cell.change_background_color(Color.create_color(255, 255, 0));

    try testing.expectEqual(Color.create_color(255, 255, 0), test_cell.get_background_color());
}

test "Cell: change foreground color" {
    var test_cell = Cell.create_cell(Color.create_color(0, 0, 0), Color.create_color(255, 255, 255), 'E');
    test_cell.change_foreground_color(Color.create_color(255, 0, 255));

    try testing.expectEqual(Color.create_color(255, 0, 255), test_cell.get_foreground_color());
}
