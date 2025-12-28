//! Chunked Transfer Encoding support
//!
//! This module provides support for decoding chunked transfer encoding as
//! defined in RFC 7230 Section 4.1.
//!
//! Chunked transfer encoding allows an HTTP message body to be sent in a series
//! of chunks, each with its own size indicator. This is useful when the total
//! size of the content is not known in advance.
//!
//! # Format
//! ```
//! <chunk-size-hex>\r\n
//! <chunk-data>\r\n
//! ...
//! 0\r\n
//! [optional-trailer-headers]\r\n
//! \r\n
//! ```
//!
//! # Usage
//! ```zig
//! const chunked = @import("encoding/chunked.zig");
//!
//! const encoded = "5\r\nhello\r\n0\r\n\r\n";
//! const decoded = try chunked.decode(allocator, encoded);
//! defer allocator.free(decoded);
//! // decoded == "hello"
//! ```

const std = @import("std");
const errors = @import("../errors.zig");

/// Decodes a chunked-encoded message body
///
/// # Parameters
/// - `allocator`: Memory allocator for the decoded body
/// - `encoded`: The chunked-encoded data
///
/// # Returns
/// Returns the fully decoded body. Caller must free the returned slice.
///
/// # Errors
/// Returns `InvalidChunkedEncoding` if the chunked data is malformed
///
/// # Example
/// ```zig
/// const encoded = "5\r\nhello\r\n6\r\n world\r\n0\r\n\r\n";
/// const decoded = try decode(allocator, encoded);
/// defer allocator.free(decoded);
/// // decoded == "hello world"
/// ```
pub fn decode(allocator: std.mem.Allocator, encoded: []const u8) ![]u8 {
    var result = std.ArrayList(u8){};
    errdefer result.deinit(allocator);

    var pos: usize = 0;

    while (pos < encoded.len) {
        // Find the end of the chunk size line (look for \r\n)
        const size_end = std.mem.indexOfPos(u8, encoded, pos, "\r\n") orelse
            return errors.Error.InvalidChunkedEncoding;

        // Parse chunk size (hex)
        const size_str = encoded[pos..size_end];

        // Handle chunk extensions (ignore them for now - they come after semicolon)
        const size_str_clean = if (std.mem.indexOfScalar(u8, size_str, ';')) |semi_pos|
            size_str[0..semi_pos]
        else
            size_str;

        // Trim whitespace
        const size_str_trimmed = std.mem.trim(u8, size_str_clean, &std.ascii.whitespace);

        const chunk_size = std.fmt.parseInt(usize, size_str_trimmed, 16) catch
            return errors.Error.InvalidChunkedEncoding;

        // Move past the \r\n after the size
        pos = size_end + 2;

        // Check if this is the last chunk (size 0)
        if (chunk_size == 0) {
            // Last chunk - may have trailer headers, skip to end
            // Look for final \r\n\r\n or just \r\n if no trailers
            break;
        }

        // Read chunk data
        if (pos + chunk_size > encoded.len) {
            return errors.Error.InvalidChunkedEncoding;
        }

        try result.appendSlice(allocator, encoded[pos .. pos + chunk_size]);
        pos += chunk_size;

        // Expect \r\n after chunk data
        if (pos + 2 > encoded.len or
            encoded[pos] != '\r' or
            encoded[pos + 1] != '\n')
        {
            return errors.Error.InvalidChunkedEncoding;
        }

        pos += 2; // Skip \r\n after chunk data
    }

    return try result.toOwnedSlice(allocator);
}

/// Checks if data appears to be chunked-encoded
///
/// This is a heuristic check - looks for hex digits followed by \r\n
///
/// # Parameters
/// - `data`: The data to check
///
/// # Returns
/// Returns true if the data appears to be chunked-encoded
pub fn looksLikeChunked(data: []const u8) bool {
    if (data.len < 3) return false;

    // Look for hex digits followed by \r\n
    var i: usize = 0;
    while (i < @min(data.len, 10)) : (i += 1) {
        const c = data[i];
        if (c == '\r') {
            return i + 1 < data.len and data[i + 1] == '\n';
        }
        if (!std.ascii.isHex(c)) return false;
    }

    return false;
}

// Tests
test "decode simple chunk" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const encoded = "5\r\nhello\r\n0\r\n\r\n";
    const decoded = try decode(allocator, encoded);
    defer allocator.free(decoded);

    try testing.expectEqualStrings("hello", decoded);
}

test "decode multiple chunks" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const encoded = "5\r\nhello\r\n6\r\n world\r\n0\r\n\r\n";
    const decoded = try decode(allocator, encoded);
    defer allocator.free(decoded);

    try testing.expectEqualStrings("hello world", decoded);
}

test "decode empty chunk" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const encoded = "0\r\n\r\n";
    const decoded = try decode(allocator, encoded);
    defer allocator.free(decoded);

    try testing.expectEqualStrings("", decoded);
}

test "decode with chunk extensions" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Chunk extensions are ignored
    const encoded = "5;ext=value\r\nhello\r\n0\r\n\r\n";
    const decoded = try decode(allocator, encoded);
    defer allocator.free(decoded);

    try testing.expectEqualStrings("hello", decoded);
}

test "decode hex uppercase" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const encoded = "A\r\n0123456789\r\n0\r\n\r\n";
    const decoded = try decode(allocator, encoded);
    defer allocator.free(decoded);

    try testing.expectEqualStrings("0123456789", decoded);
}

test "decode malformed - missing CRLF" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const encoded = "5\nhello\n0\n\n"; // Missing \r
    try testing.expectError(errors.Error.InvalidChunkedEncoding, decode(allocator, encoded));
}

test "decode malformed - invalid size" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const encoded = "XYZ\r\nhello\r\n0\r\n\r\n"; // Non-hex size
    try testing.expectError(errors.Error.InvalidChunkedEncoding, decode(allocator, encoded));
}

test "decode malformed - incomplete chunk" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const encoded = "10\r\nhello"; // Claims 16 bytes but only has 5
    try testing.expectError(errors.Error.InvalidChunkedEncoding, decode(allocator, encoded));
}

test "looksLikeChunked with valid chunk" {
    try std.testing.expect(looksLikeChunked("5\r\nhello"));
    try std.testing.expect(looksLikeChunked("1a\r\ndata"));
    try std.testing.expect(looksLikeChunked("0\r\n\r\n"));
}

test "looksLikeChunked with invalid data" {
    try std.testing.expect(!looksLikeChunked("hello world"));
    try std.testing.expect(!looksLikeChunked("GET /"));
    try std.testing.expect(!looksLikeChunked(""));
    try std.testing.expect(!looksLikeChunked("5\n")); // Missing \r
}
