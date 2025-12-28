//! HTTP Bearer Token Authentication
//!
//! This module implements HTTP Bearer Token Authentication as defined in RFC 6750.
//! Bearer tokens are typically used with OAuth 2.0 and other token-based
//! authentication systems.
//!
//! # Security Note
//! Bearer tokens grant access to protected resources. Always use HTTPS to
//! protect tokens in transit. Treat bearer tokens as sensitive credentials.
//!
//! # Usage
//! ```zig
//! const bearer = @import("auth/bearer.zig");
//!
//! var auth = bearer.BearerAuth.init("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...");
//! const header_value = auth.getHeaderValue();
//!
//! // header_value is "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
//! ```

const std = @import("std");

/// HTTP Bearer Token Authentication
///
/// Represents a bearer token for HTTP authentication.
/// The token is stored as-is and prefixed with "Bearer " when
/// generating the Authorization header value.
pub const BearerAuth = struct {
    token: []const u8,

    /// Creates a new BearerAuth with the given token
    ///
    /// # Parameters
    /// - `token`: The bearer token (e.g., JWT, OAuth access token)
    ///
    /// # Returns
    /// Returns a BearerAuth instance
    ///
    /// # Security
    /// The token is stored as-is (not encrypted).
    /// Ensure proper memory handling to avoid token leaks.
    ///
    /// # Example
    /// ```zig
    /// const auth = BearerAuth.init("abc123xyz");
    /// ```
    pub fn init(token: []const u8) BearerAuth {
        return .{ .token = token };
    }

    /// Gets the full Authorization header value
    ///
    /// Prefixes the token with "Bearer " to create the full header value.
    /// This method does NOT allocate memory - it returns a static string
    /// concatenation that's only valid while the BearerAuth instance exists.
    ///
    /// # Parameters
    /// - `self`: The BearerAuth instance
    /// - `allocator`: Memory allocator for the header value
    ///
    /// # Returns
    /// Returns the full Authorization header value (e.g., "Bearer abc123").
    /// Caller must free the returned string.
    ///
    /// # Errors
    /// Returns an error if memory allocation fails
    ///
    /// # Example
    /// ```zig
    /// const auth = BearerAuth.init("mytoken");
    /// const header = try auth.getHeaderValue(allocator);
    /// defer allocator.free(header);
    /// // header == "Bearer mytoken"
    /// ```
    pub fn getHeaderValue(self: BearerAuth, allocator: std.mem.Allocator) ![]u8 {
        return try std.fmt.allocPrint(allocator, "Bearer {s}", .{self.token});
    }

    /// Applies Bearer Authentication to an HTTP request
    ///
    /// This is a convenience method that creates the header value and sets
    /// the Authorization header on the request.
    ///
    /// # Parameters
    /// - `self`: The BearerAuth instance
    /// - `request`: The HTTP request to add authentication to
    ///
    /// # Errors
    /// Returns an error if header setting fails
    ///
    /// # Example
    /// ```zig
    /// var request = try Request.init(allocator, .GET, "https://api.example.com");
    /// const auth = BearerAuth.init("mytoken123");
    /// try auth.applyToRequest(&request);
    /// ```
    pub fn applyToRequest(self: BearerAuth, request: anytype) !void {
        const allocator = request.allocator;
        const header_value = try self.getHeaderValue(allocator);
        defer allocator.free(header_value);

        _ = try request.setHeader("Authorization", header_value);
    }
};

// Tests
test "BearerAuth init" {
    const auth = BearerAuth.init("test_token_123");
    try std.testing.expectEqualStrings("test_token_123", auth.token);
}

test "BearerAuth getHeaderValue" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const auth = BearerAuth.init("myaccesstoken");
    const header = try auth.getHeaderValue(allocator);
    defer allocator.free(header);

    try testing.expectEqualStrings("Bearer myaccesstoken", header);
}

test "BearerAuth with JWT token" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Example JWT token (not a valid token, just for testing format)
    const jwt = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U";
    const auth = BearerAuth.init(jwt);
    const header = try auth.getHeaderValue(allocator);
    defer allocator.free(header);

    const expected = try std.fmt.allocPrint(allocator, "Bearer {s}", .{jwt});
    defer allocator.free(expected);

    try testing.expectEqualStrings(expected, header);
}

test "BearerAuth with empty token" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const auth = BearerAuth.init("");
    const header = try auth.getHeaderValue(allocator);
    defer allocator.free(header);

    try testing.expectEqualStrings("Bearer ", header);
}
