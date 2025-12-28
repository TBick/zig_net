//! HTTP Basic Authentication
//!
//! This module implements HTTP Basic Authentication as defined in RFC 7617.
//! Basic authentication transmits credentials as username/password pairs,
//! encoded using base64.
//!
//! # Security Note
//! Basic authentication sends credentials in base64 encoding, which is NOT encryption.
//! Always use HTTPS when using Basic authentication to protect credentials in transit.
//!
//! # Usage
//! ```zig
//! const basic = @import("auth/basic.zig");
//!
//! var auth = basic.BasicAuth.init("username", "password");
//! const header_value = try auth.encode(allocator);
//! defer allocator.free(header_value);
//!
//! // header_value is "Basic dXNlcm5hbWU6cGFzc3dvcmQ="
//! ```

const std = @import("std");

/// HTTP Basic Authentication credentials
///
/// Represents a username/password pair for HTTP Basic Authentication.
/// The credentials are NOT stored in encoded form - encoding happens
/// when generating the Authorization header value.
pub const BasicAuth = struct {
    username: []const u8,
    password: []const u8,

    /// Creates a new BasicAuth with the given credentials
    ///
    /// # Parameters
    /// - `username`: The username for authentication
    /// - `password`: The password for authentication
    ///
    /// # Returns
    /// Returns a BasicAuth instance
    ///
    /// # Security
    /// Credentials are stored as-is (not encrypted or hashed).
    /// Ensure proper memory handling to avoid credential leaks.
    ///
    /// # Example
    /// ```zig
    /// const auth = BasicAuth.init("alice", "secret123");
    /// ```
    pub fn init(username: []const u8, password: []const u8) BasicAuth {
        return .{
            .username = username,
            .password = password,
        };
    }

    /// Encodes the credentials as a Basic Authentication header value
    ///
    /// Formats credentials as "username:password" and encodes with base64,
    /// then prefixes with "Basic " to create the full header value.
    ///
    /// # Parameters
    /// - `self`: The BasicAuth instance
    /// - `allocator`: Memory allocator for the encoded string
    ///
    /// # Returns
    /// Returns the full Authorization header value (e.g., "Basic dXNlcm5hbWU6cGFzc3dvcmQ=").
    /// Caller must free the returned string.
    ///
    /// # Errors
    /// Returns an error if memory allocation fails
    ///
    /// # Example
    /// ```zig
    /// const auth = BasicAuth.init("alice", "secret");
    /// const header = try auth.encode(allocator);
    /// defer allocator.free(header);
    /// // header == "Basic YWxpY2U6c2VjcmV0"
    /// ```
    pub fn encode(self: BasicAuth, allocator: std.mem.Allocator) ![]u8 {
        // Format as "username:password"
        const credentials = try std.fmt.allocPrint(allocator, "{s}:{s}", .{ self.username, self.password });
        defer allocator.free(credentials);

        // Calculate base64 encoded size
        const base64_encoder = std.base64.standard.Encoder;
        const encoded_len = base64_encoder.calcSize(credentials.len);

        // Allocate buffer for "Basic " + base64
        const prefix = "Basic ";
        const total_len = prefix.len + encoded_len;
        const result = try allocator.alloc(u8, total_len);
        errdefer allocator.free(result);

        // Copy prefix
        @memcpy(result[0..prefix.len], prefix);

        // Encode credentials
        const encoded = base64_encoder.encode(result[prefix.len..], credentials);
        std.debug.assert(encoded.len == encoded_len);

        return result;
    }

    /// Applies Basic Authentication to an HTTP request
    ///
    /// This is a convenience method that encodes the credentials and sets
    /// the Authorization header on the request.
    ///
    /// # Parameters
    /// - `self`: The BasicAuth instance
    /// - `request`: The HTTP request to add authentication to
    ///
    /// # Errors
    /// Returns an error if encoding or header setting fails
    ///
    /// # Example
    /// ```zig
    /// var request = try Request.init(allocator, .GET, "https://api.example.com");
    /// const auth = BasicAuth.init("alice", "secret");
    /// try auth.applyToRequest(&request);
    /// ```
    pub fn applyToRequest(self: BasicAuth, request: anytype) !void {
        const allocator = request.allocator;
        const header_value = try self.encode(allocator);
        defer allocator.free(header_value);

        _ = try request.setHeader("Authorization", header_value);
    }
};

// Tests
test "BasicAuth init" {
    const auth = BasicAuth.init("testuser", "testpass");
    try std.testing.expectEqualStrings("testuser", auth.username);
    try std.testing.expectEqualStrings("testpass", auth.password);
}

test "BasicAuth encode" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const auth = BasicAuth.init("alice", "wonderland");
    const encoded = try auth.encode(allocator);
    defer allocator.free(encoded);

    // "alice:wonderland" in base64 is "YWxpY2U6d29uZGVybGFuZA=="
    try testing.expectEqualStrings("Basic YWxpY2U6d29uZGVybGFuZA==", encoded);
}

test "BasicAuth encode with special characters" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const auth = BasicAuth.init("user@example.com", "p@ss:w0rd!");
    const encoded = try auth.encode(allocator);
    defer allocator.free(encoded);

    // Should start with "Basic "
    try testing.expect(std.mem.startsWith(u8, encoded, "Basic "));

    // Should be valid base64 after "Basic "
    const base64_part = encoded["Basic ".len..];
    try testing.expect(base64_part.len > 0);
}

test "BasicAuth encode empty credentials" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const auth = BasicAuth.init("", "");
    const encoded = try auth.encode(allocator);
    defer allocator.free(encoded);

    // ":" in base64 is "Og=="
    try testing.expectEqualStrings("Basic Og==", encoded);
}
