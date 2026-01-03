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

        for (lexer.tokens.items) |t| {
            print("{}\n", .{t.type});
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
