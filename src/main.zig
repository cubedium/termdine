const std = @import("std");
const termdine = @import("termdine");
const stdin  = std.io.getStdIn();

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var window = termdine.Window.create_window(32, 16, .{ .allocator = allocator });
    try window.init();
    defer window.deinit();
    
    //var input_buffer: [512]u8 = undefined;
    
    window.write_character('>');
    window.write_string(" test");
    window.move_cursor(0, 1);
    window.write_character_colored('>', termdine.Color.Green(), null);
    window.write_string_colored(" test colored", termdine.Color.Orange(), null);
    window.move_cursor(0, 15);
    window.write_string_colored(" " ** 32, termdine.Color.White(), termdine.Color.Blue());

    window.draw();
}
