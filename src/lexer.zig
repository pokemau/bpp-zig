const std = @import("std");
const print = std.debug.print;

const Token = @import("./token.zig").Token;
const TokenType = @import("./token.zig").TokenType;
const TokenLiteral = @import("./token.zig").TokenLiteral;

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
                '{' => try addToken(self, .LEFT_BRACE, .none),
                '}' => try addToken(self, .RIGHT_BRACE, .none),
                '[' => try addToken(self, .LEFT_BRACKET, .none),
                ']' => try addToken(self, .RIGHT_BRACKET, .none),
                ',' => try addToken(self, .COMMA, .none),
                '.' => try addToken(self, .DOT, .none),
                ';' => try addToken(self, .SEMICOLON, .none),
                ':' => try addToken(self, .COLON, .none),
                '&' => try addToken(self, .AMPERSAND, .none),
                '$' => try addToken(self, .DOLLAR, .none),
                '#' => try addToken(self, .HASH, .none),
                '(' => try addToken(self, .LEFT_PAREN, .none),
                ')' => try addToken(self, .RIGHT_PAREN, .none),
                '*' => try addToken(self, .STAR, .none),
                '/' => try addToken(self, .SLASH, .none),
                '%' => try addToken(self, .MODULO, .none),
                '+' => try addToken(self, .PLUS, .none),
                '-' => {
                    _ = advance(self);
                    if (match(self, '-')) {
                        while (!isAtEnd(self) and peek(self) != '\n') {
                            _ = advance(self);
                        }
                    } else {
                        try addToken(self, .MINUS, .none);
                    }
                },
                '=' => {
                    _ = advance(self);
                    try addToken(
                        self,
                        if (match(self, '=')) .EQUAL_EQUAL else .EQUAL,
                        .none,
                    );
                },
                '>' => {
                    _ = advance(self);
                    try addToken(
                        self,
                        if (match(self, '=')) .GREATER_EQUAL else .GREATER,
                        .none,
                    );
                },
                '<' => {
                    _ = advance(self);
                    if (match(self, '=')) {
                        try addToken(self, .LESS_EQUAL, .none);
                    } else if (match(self, '>')) {
                        try addToken(self, .NOT_EQUAL, .none);
                    } else {
                        try addToken(self, .LESS, .none);
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
            try addToken(self, .CHAR, .none);
            return;
        }

        if (isAtEnd(self) or peek(self) == '\n') {
            try addToken(self, .SINGLE_QUOTE, .none);
            return;
        }

        const char = peek(self);
        _ = advance(self);
        if (!isAtEnd(self) and peek(self) == '\'') {
            try addToken(self, .CHAR, .{ .char = char });
        } else {
            try addToken(self, .SINGLE_QUOTE, .none);
        }
    }

    fn scanNumber(self: *Lexer) !void {
        const start = self.current;
        while (!isAtEnd(self) and (std.ascii.isDigit(peek(self)))) {
            _ = advance(self);
        }

        if (!isAtEnd(self) and peek(self) == '.' and std.ascii.isDigit(peekNext(self))) {
            _ = advance(self);
            while (std.ascii.isDigit(peek(self)))
                _ = advance(self);
        }

        const text = self.source[start..self.current];
        const val = std.fmt.parseFloat(f64, text) catch 0.0;
        try addToken(self, .NUMBER, .{ .number = val });
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
                try addToken(self, .TRUE, .{ .boolean = false });
            } else if (std.mem.eql(u8, text, "OO")) {
                try addToken(self, .FALSE, .{ .boolean = true });
            } else {
                try addToken(self, .STRING, .{ .string = text });
            }
        } else {
            try addToken(self, .DOUBLE_QUOTE, .none);
        }
    }

    fn scanIdentifier(self: *Lexer) !void {
        const start = self.current;
        while (!isAtEnd(self) and (std.ascii.isAlphanumeric(peek(self)) or peek(self) == '_')) {
            _ = advance(self);
        }
        const text = self.source[start..self.current];

        if (try matchMultiWordKeyword(self, text)) |res| {
            try addToken(self, res, .none);
            return;
        }
        const token_type = getKeywordType(text) orelse .IDENTIFIER;
        try addToken(self, token_type, .{ .ident = text });
    }

    fn matchMultiWordKeyword(self: *Lexer, first_word: []const u8) !?TokenType {
        const curr_pos = self.current;
        const curr_line = self.line;

        while (!isAtEnd(self) and (peek(self) == ' ' or peek(self) == '\t')) {
            _ = advance(self);
        }

        if (isAtEnd(self) or !std.ascii.isAlphabetic(peek(self))) {
            self.current = curr_pos;
            self.line = curr_line;
            return null;
        }
        const second_start = self.current;
        while (!isAtEnd(self) and (std.ascii.isAlphanumeric(peek(self)) or peek(self) == '_')) {
            _ = advance(self);
        }
        const second_word = self.source[second_start..self.current];

        if (std.mem.eql(u8, first_word, "KUNG")) {
            if (std.mem.eql(u8, second_word, "WALA")) {
                return .KUNG_WALA;
            } else if (std.mem.eql(u8, second_word, "DILI")) {
                return .KUNG_DILI;
            }
        } else if (std.mem.eql(u8, first_word, "ALANG")) {
            if (std.mem.eql(u8, second_word, "SA")) {
                return .ALANG_SA;
            }
        }

        self.current = curr_pos;
        self.line = curr_line;
        return null;
    }

    fn getKeywordType(text: []const u8) ?TokenType {
        const keywords = std.StaticStringMap(TokenType).initComptime(.{
            .{ "SUGOD", .SUGOD },
            .{ "KATAPUSAN", .KATAPUSAN },
            .{ "MUGNA", .MUGNA },
            .{ "IPAKITA", .IPAKITA },
            .{ "DAWAT", .DAWAT },
            .{ "KUNG", .KUNG },
            .{ "WALA", .WALA },
            .{ "PULI", .PULI },
            .{ "KASO", .KASO },
            .{ "PUNDOK", .PUNDOK },

            .{ "NUMERO", .NUMERO },
            .{ "LETRA", .LETRA },
            .{ "TIPIK", .TIPIK },
            .{ "TINUOD", .TINUOD },

            .{ "UG", .UG },
            .{ "O", .O },
            .{ "DILI", .DILI },
        });

        return keywords.get(text);
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

    fn addToken(self: *Lexer, t: TokenType, literal: TokenLiteral) !void {
        try self.tokens.append(
            self.allocator,
            .{
                .type = t,
                .line = self.line,
                .literal = literal,
            },
        );
    }
};
