const std = @import("std");
const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;

pub const AstNode = union(enum) {
    program: struct {
        statements: []*AstNode,
    },

    var_decl: struct {
        d_type: TokenType,
        names: []const u8,
        inits: []?*AstNode,
        name_count: usize,
    },

    assignment: struct {
        name: Token,
        value: *AstNode,
    },

    print: struct {
        expressions: []const *AstNode,
    },

    input: struct {
        variables: []const Token,
    },
    block: struct {
        statements: []const *AstNode,
    },

    binary: struct {
        left: *AstNode,
        operator: Token,
        right: *AstNode,
    },
    unary: struct {
        operator: Token,
        expression: *AstNode,
    },

    literal: struct {
        token: Token,
    },

    variable: struct {
        name: Token,
    },

    // TODO:
    // if-else statement
    // switch statement
    // for statement
};
