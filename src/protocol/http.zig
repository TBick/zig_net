//! HTTP protocol utilities
//!
//! This module provides HTTP protocol constants, version information,
//! and utility functions for working with HTTP.

const std = @import("std");

/// HTTP version constants
pub const Version = enum {
    HTTP_1_0,
    HTTP_1_1,
    HTTP_2,

    /// Converts version to string representation
    pub fn toString(self: Version) []const u8 {
        return switch (self) {
            .HTTP_1_0 => "HTTP/1.0",
            .HTTP_1_1 => "HTTP/1.1",
            .HTTP_2 => "HTTP/2",
        };
    }
};

/// Common User-Agent string for zig_net
pub const USER_AGENT = "zig_net/0.1.0";

/// Common MIME types
pub const MimeType = struct {
    pub const JSON = "application/json";
    pub const FORM_URLENCODED = "application/x-www-form-urlencoded";
    pub const TEXT_PLAIN = "text/plain";
    pub const TEXT_HTML = "text/html";
    pub const OCTET_STREAM = "application/octet-stream";
};

/// Parses a Content-Type header value
///
/// # Parameters
/// - `content_type`: The Content-Type header value
///
/// # Returns
/// Returns a struct with mime_type and optional charset
pub fn parseContentType(content_type: []const u8) ParsedContentType {
    var result = ParsedContentType{
        .mime_type = content_type,
        .charset = null,
    };

    // Look for semicolon separating mime type from parameters
    if (std.mem.indexOfScalar(u8, content_type, ';')) |semi_pos| {
        result.mime_type = std.mem.trim(u8, content_type[0..semi_pos], &std.ascii.whitespace);

        // Look for charset parameter
        const params = content_type[semi_pos + 1 ..];
        if (std.mem.indexOf(u8, params, "charset=")) |charset_pos| {
            const charset_start = charset_pos + "charset=".len;
            const charset_value = std.mem.trim(u8, params[charset_start..], &std.ascii.whitespace);

            // Remove quotes if present
            if (charset_value.len >= 2 and
                charset_value[0] == '"' and
                charset_value[charset_value.len - 1] == '"')
            {
                result.charset = charset_value[1 .. charset_value.len - 1];
            } else {
                result.charset = charset_value;
            }
        }
    }

    return result;
}

pub const ParsedContentType = struct {
    mime_type: []const u8,
    charset: ?[]const u8,
};

/// URL-encodes a string for use in query parameters or form data
///
/// # Parameters
/// - `allocator`: Memory allocator
/// - `input`: String to encode
///
/// # Returns
/// Returns URL-encoded string. Caller must free.
///
/// # Example
/// ```zig
/// const encoded = try urlEncode(allocator, "hello world");
/// defer allocator.free(encoded);
/// // encoded == "hello+world"
/// ```
pub fn urlEncode(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var result = std.ArrayList(u8){};
    defer result.deinit(allocator);

    for (input) |c| {
        if (std.ascii.isAlphanumeric(c) or c == '-' or c == '_' or c == '.' or c == '~') {
            try result.append(allocator, c);
        } else if (c == ' ') {
            try result.append(allocator, '+');
        } else {
            try result.append(allocator, '%');
            try result.append(allocator, std.fmt.digitToChar(@as(u8, c >> 4), .upper));
            try result.append(allocator, std.fmt.digitToChar(@as(u8, c & 0x0F), .upper));
        }
    }

    return try result.toOwnedSlice(allocator);
}

/// URL-decodes a string
///
/// # Parameters
/// - `allocator`: Memory allocator
/// - `input`: URL-encoded string
///
/// # Returns
/// Returns decoded string. Caller must free.
pub fn urlDecode(allocator: std.mem.Allocator, input: []const u8) ![]u8 {
    var result = std.ArrayList(u8){};
    defer result.deinit(allocator);

    var i: usize = 0;
    while (i < input.len) : (i += 1) {
        const c = input[i];
        if (c == '+') {
            try result.append(allocator, ' ');
        } else if (c == '%' and i + 2 < input.len) {
            const hex = input[i + 1 .. i + 3];
            const value = try std.fmt.parseInt(u8, hex, 16);
            try result.append(allocator, value);
            i += 2;
        } else {
            try result.append(allocator, c);
        }
    }

    return try result.toOwnedSlice(allocator);
}

// Tests
test "Version toString" {
    const testing = std.testing;

    try testing.expectEqualStrings("HTTP/1.0", Version.HTTP_1_0.toString());
    try testing.expectEqualStrings("HTTP/1.1", Version.HTTP_1_1.toString());
    try testing.expectEqualStrings("HTTP/2", Version.HTTP_2.toString());
}

test "parseContentType simple" {
    const result = parseContentType("application/json");
    try std.testing.expectEqualStrings("application/json", result.mime_type);
    try std.testing.expect(result.charset == null);
}

test "parseContentType with charset" {
    const result = parseContentType("text/html; charset=utf-8");
    try std.testing.expectEqualStrings("text/html", result.mime_type);
    try std.testing.expect(result.charset != null);
    try std.testing.expectEqualStrings("utf-8", result.charset.?);
}

test "parseContentType with quoted charset" {
    const result = parseContentType("text/html; charset=\"utf-8\"");
    try std.testing.expectEqualStrings("text/html", result.mime_type);
    try std.testing.expect(result.charset != null);
    try std.testing.expectEqualStrings("utf-8", result.charset.?);
}

test "urlEncode basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const encoded = try urlEncode(allocator, "hello world");
    defer allocator.free(encoded);

    try testing.expectEqualStrings("hello+world", encoded);
}

test "urlEncode special chars" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const encoded = try urlEncode(allocator, "hello@world.com");
    defer allocator.free(encoded);

    try testing.expectEqualStrings("hello%40world.com", encoded);
}

test "urlDecode basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const decoded = try urlDecode(allocator, "hello+world");
    defer allocator.free(decoded);

    try testing.expectEqualStrings("hello world", decoded);
}

test "urlDecode special chars" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const decoded = try urlDecode(allocator, "hello%40world.com");
    defer allocator.free(decoded);

    try testing.expectEqualStrings("hello@world.com", decoded);
}

test "urlEncode and urlDecode roundtrip" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const original = "Hello World! @#$%";
    const encoded = try urlEncode(allocator, original);
    defer allocator.free(encoded);

    const decoded = try urlDecode(allocator, encoded);
    defer allocator.free(decoded);

    try testing.expectEqualStrings(original, decoded);
}
