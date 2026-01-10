const std = @import("std");
const print = std.debug.print;

const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;
const AstNode = @import("./ast.zig").AstNode;


// TODO: implement error handling when parsing

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
            else => {},
        }

        // TODO:
        // var decl
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
        // TODO: not done
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
        // var inits: std.ArrayList(?*AstNode) = .empty;

        while (!self.match(.NEWLINE)) {
            const name_tok = self.peek();
            if (name_tok.type != .IDENTIFIER) {
                print("ERROR: EXPECT VAR NAME\n", .{});
            }

            try names.append(aa, name_tok);
            self.advance();
        }

        for (names.items) |n| {
            print("{}\n", .{n});
        }

        return try self.createNode(.{ .literal = .{ .token = t } });
    }

    fn parseExpression(self: *Parser) !*AstNode {
        return self.parseBinary(0);
    }

    fn parseBinary(self: *Parser, min_prec: i32) !*AstNode {
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
    }

    fn parseUnary(self: *Parser) !*AstNode {
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

    fn parsePrimary(self: *Parser) !*AstNode {
        const token = self.peek();

        switch (token.type) {
            .NUMBER, .STRING, .CHAR, .TRUE, .FALSE => {
                self.advance();
                return self.createNode(.{ .literal = .{ .token = token } });
            },

            .IDENTIFIER => {
                self.advance();
                return self.createNode(.{ .variabl = .{ .name = token } });
            },
            .LEFT_PAREN => {
                self.advance();
                const expr = try self.parseExpression();
                if (!self.match(.RIGHT_PAREN)) {
                }
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
        if (self.tokens[self.current].type != t) {
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
        switch (t) {
            .STAR, .SLASH, .MODULO => 3,
            .PLUS, .MINUS => 2,
            .LESS, .GREATER, .LESS_EQUAL, .GREATER_EQUAL, .EQUAL_EQUAL, .NOT_EQUAL => 1,
            .UG, .O => 0,
            else => -1,
        }
    }
};

pub const ParserError = struct {
    message: []const u8,
    token: Token,
    line: usize,
};
