const std = @import("std");
const print = std.debug.print;

const Lexer = @import("./lexer.zig").Lexer;
const Parser = @import("./parser.zig").Parser;
const Token = @import("./lexer.zig").Token;

pub const Interpreter = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Interpreter {
        return .{
            .allocator = allocator,
        };
    }

    pub fn run(self: *Interpreter, source: []const u8) !void {
        print("RUNNING INTERPRETER\n", .{});
        var lexer = Lexer.init(self.allocator, source);
        defer lexer.deinit();
        try lexer.tokenize();

        // for (lexer.tokens.items) |t| {
        //     print("{}-{any}\n", .{t.type, t.literal});
        // }
        for (lexer.tokens.items) |t| {
            print("{} - ", .{t.type});
            switch (t.literal) {
                .none => print("(no literal)\n", .{}),
                .number => |num| print("{d}\n", .{num}),
                .string => |str| print("\"{s}\"\n", .{str}),
                .char => |ch| print("'{c}'\n", .{ch}),
                .boolean => |b| print("{}\n", .{b}),
                .ident => |i| print("{s}\n", .{i}),
            }
        }

        // var parser = Parser.init(self.allocator);
        // defer parser.deinit();
        // try parser.parse(lexer.tokens);

        // defer self.lexer.arena.deinit();
        // const tokens = try self.lexer.tokenize(source);
        // print("Tokens len: {any}\n", .{tokens});
    }

    pub fn testt(self: *Interpreter, file_content: []const u8) ![]Token {
        const tokens = try self.lexer.tokenize(file_content);
        defer self.lexer.arena.deinit();

        print("Tokens len: {}\n", .{tokens.len});
        return tokens;
    }
};
