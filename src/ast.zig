const std = @import("std");
const print = std.debug.print;
const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;

pub const AstNode = union(enum) {
    program: struct {
        statements: []*AstNode,
    },

    var_decl: struct {
        d_type: TokenType,
        names: []const Token,
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

fn printIndent(indent: usize) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        print("  ", .{});
    }
}

pub fn printAstNode(node: *const AstNode, indent: usize) void {
    printIndent(indent);

    switch (node.*) {
        .program => |prog| {
            print("Program:\n", .{});
            for (prog.statements) |stmt| {
                printAstNode(stmt, indent + 1);
            }
        },

        .var_decl => |decl| {
            print("VarDecl [type: {s}]:\n", .{@tagName(decl.d_type)});
            printIndent(indent + 1);
            print("Names: ", .{});
            for (decl.names) |name| {
                print("{s} ", .{name.literal.identifier});
            }
            print("\n", .{});

            if (decl.inits.len > 0) {
                printIndent(indent + 1);
                print("Initializers:\n", .{});
                for (decl.inits) |init| {
                    if (init) |init_node| {
                        printAstNode(init_node, indent + 2);
                    } else {
                        printIndent(indent + 2);
                        print("null\n", .{});
                    }
                }
            }
        },

        .assignment => |assign| {
            print("Assignment:\n", .{});
            printIndent(indent + 1);
            print("Name: {s}\n", .{assign.name.literal.identifier});
            printIndent(indent + 1);
            print("Value:\n", .{});
            printAstNode(assign.value, indent + 2);
        },

        .print => |p| {
            print("Print:\n", .{});
            for (p.expressions) |expr| {
                printAstNode(expr, indent + 1);
            }
        },

        .input => |inp| {
            print("Input:\n", .{});
            printIndent(indent + 1);
            print("Variables: ", .{});
            for (inp.variables) |v| {
                print("{s} ", .{v.literal.identifier});
            }
            print("\n", .{});
        },

        .block => |blk| {
            print("Block:\n", .{});
            for (blk.statements) |stmt| {
                printAstNode(stmt, indent + 1);
            }
        },

        .binary => |bin| {
            print("Binary [{s}]:\n", .{@tagName(bin.operator.type)});
            printIndent(indent + 1);
            print("Left:\n", .{});
            printAstNode(bin.left, indent + 2);
            printIndent(indent + 1);
            print("Right:\n", .{});
            printAstNode(bin.right, indent + 2);
        },

        .unary => |un| {
            print("Unary [{s}]:\n", .{@tagName(un.operator.type)});
            printIndent(indent + 1);
            print("Expression:\n", .{});
            printAstNode(un.expression, indent + 2);
        },

        .literal => |lit| {
            print("Literal: ", .{});
            switch (lit.token.literal) {
                .number => |n| print("{d}\n", .{n}),
                .string => |s| print("\"{s}\"\n", .{s}),
                .char => |c| print("'{c}'\n", .{c}),
                .boolean => |b| print("{}\n", .{b}),
                .identifier => |id| print("{s}\n", .{id}),
                .none => print("none\n", .{}),
            }
        },

        .variable => |v| {
            print("Variable: {s}\n", .{v.name.literal.identifier});
        },
    }
}
