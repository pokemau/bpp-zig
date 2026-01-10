const std = @import("std");
const print = std.debug.print;

const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;
const AstNode = @import("./ast.zig").AstNode;

const ast = @import("./ast.zig");

// TODO: fix anyerror

pub const Parser = struct {
    arena: std.heap.ArenaAllocator,
    tokens: []const Token,
    current: usize,
    errors: std.ArrayList(ParserError),
    had_errors: bool,
    max_errors: usize, // max errors before ending parse

    pub fn init(allocator: std.mem.Allocator) Parser {
        return .{
            .arena = std.heap.ArenaAllocator.init(allocator),
            .tokens = &[_]Token{},
            .current = 0,
            .errors = .empty,
            .had_errors = false,
            .max_errors = 10,
        };
    }

    pub fn deinit(self: *Parser) void {
        self.arena.deinit();
    }

    pub fn parse(self: *Parser, tokens: []const Token) !*AstNode {
        self.tokens = tokens;

        const aa = self.arena.allocator();

        var statements: std.ArrayList(*AstNode) = .empty;

        _ = expect(self, .SUGOD);
        _ = expect(self, .NEWLINE);

        while (!isAtEnd(self)) {
            if (match(self, .NEWLINE)) {
                self.advance();
                continue;
            }

            const stmt = try parseStatement(self);
            _ = stmt;

            advance(self);
        }

        // TODO: add check that last token is .KATAPUSAN

        const r = try statements.toOwnedSlice(aa);

        const program_node = try createNode(self, .{
            .program = .{ .statements = r },
        });
        return program_node;
    }

    fn isAtEnd(self: *Parser) bool {
        return self.current == self.tokens.len;
    }

    fn parseStatement(self: *Parser) !*AstNode {
        const token = peek(self);

        switch (token.type) {
            .MUGNA => return parseVarDecl(self),
            // .KATAPUSAN => {
            //     while (!self.isAtEnd()) {
            //         self.advance();
            //     }
            //     self.prev();
            // },
            else => {},
        }

        // TODO:
        // ipakita
        // identifier
        // alang sa
        // dawat
        // kung
        // dili
        // katapusan

        return try createNode(self, .{ .literal = .{ .token = peek(self) } });
    }

    fn parseVarDecl(self: *Parser) !*AstNode {
        self.advance();

        print("PARSE VAR DECL\n", .{});
        const t = self.peek();
        const d_type = t.type;

        switch (d_type) {
            .NUMERO, .LETRA, .TIPIK, .TINUOD => {
                self.advance();
            },
            else => {
                print("ERROR: Expected Data Type\n", .{});
            },
        }

        const aa = self.arena.allocator();
        var names: std.ArrayList(Token) = .empty;
        var inits: std.ArrayList(?*AstNode) = .empty;

        while (!self.match(.NEWLINE)) {
            const name_tok = self.peek();

            print("==={}===\n", .{name_tok.type});

            if (name_tok.type != .IDENTIFIER) {
                self.printCurrTok();
                print("ERROR: EXPECT VAR NAME\n", .{});
                break;
            }

            try names.append(aa, name_tok);
            self.advance();

            if (self.match(.EQUAL)) {
                self.advance();
                const init_var = try self.parseExpression();
                try inits.append(aa, init_var);
            } else {
                try inits.append(aa, null);
            }

            if (self.match(.COMMA)) {
                self.advance();
                continue;
            }
            // break;
            // self.advance();
        }

        const res = try self.createNode(.{ .var_decl = .{
            .d_type = d_type,
            .names = names.items,
            .inits = inits.items,
            .name_count = names.items.len,
        } });

        ast.printAstNode(res, 0);

        return res;
    }

    fn parseExpression(self: *Parser) anyerror!*AstNode {
        return self.parseBinary(0);
    }

    fn parseBinary(self: *Parser, min_prec: i32) anyerror!*AstNode {
        var left = try self.parseUnary();

        while (!self.isAtEnd()) {
            const op_token = self.peek();
            const prec = getPrecedence(op_token.type);

            if (prec < min_prec) break;
            self.advance();

            const right = try self.parseBinary(prec + 1);

            left = try self.createNode(.{ .binary = .{
                .left = left,
                .operator = op_token,
                .right = right,
            } });
        }
        return left;
    }

    fn parseUnary(self: *Parser) anyerror!*AstNode {
        const token = self.peek();

        if (token.type == .MINUS or token.type == .PLUS or token.type == .DILI) {
            self.advance();
            const right = try self.parseUnary();
            return self.createNode(.{
                .unary = .{
                    .operator = token,
                    .expression = right,
                },
            });
        }

        return self.parsePrimary();
    }

    fn parsePrimary(self: *Parser) anyerror!*AstNode {
        const token = self.peek();

        switch (token.type) {
            .NUMBER, .STRING, .CHAR, .TRUE, .FALSE => {
                self.advance();
                return self.createNode(.{ .literal = .{ .token = token } });
            },

            .IDENTIFIER => {
                self.advance();
                return self.createNode(.{ .variable = .{ .name = token } });
            },
            .LEFT_PAREN => {
                self.advance();
                const expr = try self.parseExpression();
                if (!self.match(.RIGHT_PAREN)) {}
                self.advance();
                return expr;
            },
            else => {
                print("Parse Primary\n", .{});
            },
        }

        return try createNode(self, .{ .literal = .{ .token = token } });
    }

    fn expect(self: *Parser, t: TokenType) bool {
        if (self.peek().type != t) {
            print("ERROR: Expected [{}] Actual [{}]\n", .{ t, self.tokens[self.current].type });
            return false;
        }
        self.advance();
        return true;
    }

    fn match(self: *Parser, t: TokenType) bool {
        return self.peek().type == t;
    }

    fn peek(self: *Parser) Token {
        return self.tokens[self.current];
    }

    fn advance(self: *Parser) void {
        self.current += 1;
    }

    fn prev(self: *Parser) void {
        self.current -= 1;
    }

    fn printCurrTok(self: *Parser) void {
        print("curr tok: {}\n", .{self.tokens[self.current]});
    }

    fn createNode(self: *Parser, node: AstNode) !*AstNode {
        const ptr = try self.arena.allocator().create(AstNode);
        ptr.* = node;
        return ptr;
    }

    fn synchronize(self: *Parser) void {
        if (self.match(.NEWLINE)) {
            self.advance();
            return;
        }

        if (self.current + 1 < self.tokens.len) {
            self.advance();
        } else {
            return;
        }

        while (!self.isAtEnd() and self.peekPrev().type != .NEWLINE) {
            const curr = self.peek();
            switch (curr.type) {
                .MUGNA, .IPAKITA, .DAWAT, .KUNG, .ALANG_SA => return,
                else => self.advance(),
            }
        }
    }

    fn peekPrev(self: *Parser) Token {
        if (self.current == 0) return self.tokens[0];
        return self.tokens[self.current - 1];
    }

    fn peekNext(self: *Parser) ?Token {
        if (self.current + 1 >= self.tokens.len) return null;
        return self.tokens[self.current + 1];
    }

    fn getPrecedence(t: TokenType) i32 {
        return switch (t) {
            .STAR, .SLASH, .MODULO => 3,
            .PLUS, .MINUS => 2,
            .LESS, .GREATER, .LESS_EQUAL, .GREATER_EQUAL, .EQUAL_EQUAL, .NOT_EQUAL => 1,
            .UG, .O => 0,
            else => -1,
        };
    }

    // TODO: implement error handling when parsing
    fn addError() void {}
};

pub const ParserError = struct {
    message: []const u8,
    token: Token,
    line: usize,
};
