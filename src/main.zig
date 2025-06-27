const std = @import("std");
const termdine = @import("termdine");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var window = termdine.Window.create_window(16, 9, .{.allocator = allocator, .border = true});
    try window.init();
    defer window.deinit();
    
    window.write_character('>');
    window.write_string(" test");
    window.move_cursor(0, 1);
    window.write_character_colored('>', termdine.Color.Green(), null);
    window.write_string_colored(" test colored", termdine.Color.Orange(), null);

    window.draw();
}
