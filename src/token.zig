const std = @import("std");
const print = std.debug.print;

pub const Token = struct {
    type: TokenType,
    line: usize,
    literal: TokenLiteral,
};

pub const TokenLiteral = union(enum) {
    none,
    number: f64,
    string: []const u8,
    char: u8,
    boolean: bool,
    ident: []const u8,
};

pub const TokenType = enum {
    // Characters
    LEFT_BRACE,
    RIGHT_BRACE,
    LEFT_BRACKET,
    RIGHT_BRACKET,
    SINGLE_QUOTE,
    DOUBLE_QUOTE,
    COMMA,
    DOT,
    SEMICOLON,
    COLON,
    EQUAL,
    AMPERSAND,
    DOLLAR,
    HASH,

    NEWLINE,

    // Arithmetic Operators
    LEFT_PAREN,
    RIGHT_PAREN,
    STAR,
    SLASH,
    MODULO,
    PLUS,
    MINUS,
    GREATER,
    LESS,
    GREATER_EQUAL,
    LESS_EQUAL,
    EQUAL_EQUAL,
    NOT_EQUAL,

    // Logical Operators (AND, OR, NOT)
    UG,
    O,
    DILI,

    // Boolean ("OO", "DILI")
    TRUE,
    FALSE,

    // Unary operator (+, -) // IDK

    // Literals
    IDENTIFIER,
    STRING,
    CHAR,
    NUMBER,

    // Data Types (NUMBER, CHAR, FLOAT, BOOLEAN)
    NUMERO,
    LETRA,
    TIPIK,
    TINUOD,

    // Keywords
    SUGOD,
    KATAPUSAN,
    MUGNA,
    IPAKITA,
    DAWAT,
    KUNG,
    WALA,
    KUNG_WALA,
    KUNG_DILI,
    PULI,
    KASO,
    PUNDOK,
    ALANG_SA,

    // EOF
    EOFILE,
};
