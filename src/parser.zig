const std = @import("std");
const print = std.debug.print;

const Token = @import("./lexer.zig").Token;

pub const Parser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Parser {
        return .{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Parser) void {
        _ = self;
        print("Parser DEINIT\n", .{});
    }

    pub fn parse(self: *Parser, tokens: std.ArrayList(Token)) !void {
        _ = self;
        _ = tokens;
    }
};
