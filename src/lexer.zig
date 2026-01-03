const std = @import("std");
const print = std.debug.print;

const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;

// TODO: store token value where it appliess

pub const Lexer = struct {
    allocator: std.mem.Allocator,
    line: u32,
    tokens: std.ArrayList(Token),
    current: u32,
    source: []const u8,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Lexer {
        return .{
            .allocator = allocator,
            .line = 0,
            .current = 0,
            .tokens = .empty,
            .source = source,
        };
    }

    pub fn deinit(self: *Lexer) void {
        self.tokens.deinit(self.allocator);
    }

    pub fn tokenize(self: *Lexer) !void {
        while (!isAtEnd(self)) {
            const c = peek(self);
            switch (c) {
                ' ',
                '\t',
                '\r',
                => {},
                '\n' => self.line += 1,
                '{' => try addToken(self, .LEFT_BRACE),
                '}' => try addToken(self, .RIGHT_BRACE),
                '[' => try addToken(self, .LEFT_BRACKET),
                ']' => try addToken(self, .RIGHT_BRACKET),
                ',' => try addToken(self, .COMMA),
                '.' => try addToken(self, .DOT),
                ';' => try addToken(self, .SEMICOLON),
                ':' => try addToken(self, .COLON),
                '&' => try addToken(self, .AMPERSAND),
                '$' => try addToken(self, .DOLLAR),
                '#' => try addToken(self, .HASH),
                '(' => try addToken(self, .LEFT_PAREN),
                ')' => try addToken(self, .RIGHT_PAREN),
                '*' => try addToken(self, .STAR),
                '/' => try addToken(self, .SLASH),
                '%' => try addToken(self, .MODULO),
                '+' => try addToken(self, .PLUS),
                // TODO: scan for comments
                '-' => {
                    _ = advance(self);
                    if (match(self, '-')) {
                        while (!isAtEnd(self) and peek(self) != '\n') {
                            _ = advance(self);
                        }
                    } else {
                        try addToken(self, .MINUS);
                    }
                },
                '=' => {
                    _ = advance(self);
                    try addToken(self, if (match(self, '=')) .EQUAL_EQUAL else .EQUAL);
                },
                '>' => {
                    _ = advance(self);
                    try addToken(self, if (match(self, '=')) .GREATER_EQUAL else .GREATER);
                },
                '<' => {
                    _ = advance(self);
                    if (match(self, '=')) {
                        try addToken(self, .LESS_EQUAL);
                    } else if (match(self, '>')) {
                        try addToken(self, .NOT_EQUAL);
                    } else {
                        try addToken(self, .LESS);
                    }
                },
                '\'' => {
                    try scanChar(self);
                },
                '\"' => {
                    try scanString(self);
                },
                else => {
                    if (std.ascii.isDigit(c)) {
                        try scanNumber(self);
                    } else if (std.ascii.isAlphabetic(c)) {
                        try scanIdentifier(self);
                    }
                    continue;
                },
            }
            _ = advance(self);
        }
    }

    fn scanChar(self: *Lexer) !void {
        _ = advance(self);
        if (!isAtEnd(self) and peek(self) == '\'') {
            try addToken(self, .CHAR);
            return;
        }

        if (isAtEnd(self) or peek(self) == '\n') {
            try addToken(self, .SINGLE_QUOTE);
            return;
        }

        _ = advance(self);
        if (!isAtEnd(self) and peek(self) == '\'') {
            try addToken(self, .CHAR);
        } else {
            try addToken(self, .SINGLE_QUOTE);
        }
    }

    fn scanNumber(self: *Lexer) !void {
        const start = self.current;
        while (!isAtEnd(self) and (std.ascii.isDigit(peek(self)))) {
            _ = advance(self);
        }
        const text = self.source[start..self.current];
        _ = text;
        try addToken(self, .NUMBER);
    }

    fn scanString(self: *Lexer) !void {
        const start = self.current;
        _ = advance(self);
        while (!isAtEnd(self) and peek(self) != '\"' and peek(self) != '\n') {
            _ = advance(self);
        }

        if (!isAtEnd(self) and peek(self) == '\"') {
            const text = self.source[start + 1 .. self.current];
            if (std.mem.eql(u8, text, "DILI")) {
                try addToken(self, .TRUE);
            } else if (std.mem.eql(u8, text, "OO")) {
                try addToken(self, .FALSE);
            } else {
                try addToken(self, .STRING);
            }
        } else {
            try addToken(self, .DOUBLE_QUOTE);
        }
    }

    fn scanIdentifier(self: *Lexer) !void {
        const start = self.current;
        while (!isAtEnd(self) and (std.ascii.isAlphanumeric(peek(self)) or peek(self) == '_')) {
            _ = advance(self);
        }
        const text = self.source[start..self.current];
        _ = text;
        // TODO: add check for ALANG, ALANG SA etc...
        try addToken(self, .IDENTIFIER);
    }

    fn advance(self: *Lexer) u8 {
        if (isAtEnd(self)) {
            return 0;
        }
        const c = self.source[self.current];
        self.current += 1;
        return c;
    }

    fn printCurr(self: *Lexer) void {
        print("{c}\n", .{peek(self)});
    }

    fn peek(self: *Lexer) u8 {
        if (isAtEnd(self)) return '|';
        return self.source[self.current];
    }

    fn peekNext(self: *Lexer) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn isAtEnd(self: *Lexer) bool {
        return self.current == self.source.len;
    }

    fn match(self: *Lexer, expected: u8) bool {
        if (isAtEnd(self)) return false;
        if (self.source[self.current] != expected)
            return false;
        self.current += 1;
        return true;
    }

    fn addToken(self: *Lexer, t: TokenType) !void {
        try self.tokens.append(self.allocator, .{ .type = t, .line = self.line });
    }
};
