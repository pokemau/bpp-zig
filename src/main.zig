const std = @import("std");
const print = std.debug.print;

const Interpreter = @import("./interpreter.zig").Interpreter;

pub fn main() !void {
    var gpa = std.heap.DebugAllocator(.{}){};
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    var interp = Interpreter.init(allocator);

    if (args.len >= 2) {
        const input_file = args[1];
        const source = try std.fs.cwd().readFileAlloc(
            allocator,
            input_file,
            1024 * 1024 * 5,
        );
        defer allocator.free(source);
        try interp.run(source);
    } else {
        print("Error: Invalid Arguments\n", .{});
        return;
    }
}
