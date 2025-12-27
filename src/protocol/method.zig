//! HTTP method definitions and utilities
//!
//! This module defines the HTTP request methods (verbs) as specified in RFC 7231
//! and provides utility functions for working with them.
//!
//! # Supported Methods
//! - GET: Request representation of a resource
//! - HEAD: Same as GET but without response body
//! - POST: Submit data to be processed
//! - PUT: Replace a resource with request payload
//! - DELETE: Remove a resource
//! - CONNECT: Establish a tunnel (typically for HTTPS proxying)
//! - OPTIONS: Describe communication options for a resource
//! - TRACE: Perform a message loop-back test
//! - PATCH: Apply partial modifications to a resource
//!
//! # Usage
//! ```zig
//! const method = @import("protocol/method.zig");
//!
//! const m = method.Method.GET;
//! const str = m.toString(); // "GET"
//! const parsed = try method.Method.fromString("POST"); // Method.POST
//! ```

const std = @import("std");
const errors = @import("../errors.zig");

/// HTTP request method (verb)
///
/// Represents the HTTP method to use for a request. Each method has specific
/// semantics defined in RFC 7231 Section 4.3.
///
/// # Common Methods
/// - GET: Retrieve a resource (safe, idempotent, cacheable)
/// - POST: Submit data (not idempotent, not cacheable by default)
/// - PUT: Update/replace a resource (idempotent, not cacheable)
/// - DELETE: Remove a resource (idempotent, not cacheable)
/// - PATCH: Partial update (not idempotent, not cacheable)
///
/// # Example
/// ```zig
/// const method = Method.GET;
/// if (method.isSafe()) {
///     // Safe methods don't modify server state
/// }
/// ```
pub const Method = enum {
    GET,
    HEAD,
    POST,
    PUT,
    DELETE,
    CONNECT,
    OPTIONS,
    TRACE,
    PATCH,

    /// Convert method to string representation
    ///
    /// Returns the uppercase HTTP method name as used in HTTP requests.
    ///
    /// # Returns
    /// Returns a static string containing the method name
    ///
    /// # Example
    /// ```zig
    /// const m = Method.GET;
    /// std.debug.print("{s}\n", .{m.toString()}); // Prints "GET"
    /// ```
    pub fn toString(self: Method) []const u8 {
        return switch (self) {
            .GET => "GET",
            .HEAD => "HEAD",
            .POST => "POST",
            .PUT => "PUT",
            .DELETE => "DELETE",
            .CONNECT => "CONNECT",
            .OPTIONS => "OPTIONS",
            .TRACE => "TRACE",
            .PATCH => "PATCH",
        };
    }

    /// Parse method from string representation
    ///
    /// Converts a string to a Method enum value. The comparison is case-sensitive
    /// and expects uppercase method names.
    ///
    /// # Parameters
    /// - `str`: The method string to parse (must be uppercase)
    ///
    /// # Returns
    /// Returns the corresponding Method enum value
    ///
    /// # Errors
    /// Returns `error.InvalidMethod` if the string is not a recognized HTTP method
    ///
    /// # Example
    /// ```zig
    /// const method = try Method.fromString("GET");
    /// // method == Method.GET
    /// ```
    pub fn fromString(str: []const u8) errors.Error!Method {
        if (std.mem.eql(u8, str, "GET")) return .GET;
        if (std.mem.eql(u8, str, "HEAD")) return .HEAD;
        if (std.mem.eql(u8, str, "POST")) return .POST;
        if (std.mem.eql(u8, str, "PUT")) return .PUT;
        if (std.mem.eql(u8, str, "DELETE")) return .DELETE;
        if (std.mem.eql(u8, str, "CONNECT")) return .CONNECT;
        if (std.mem.eql(u8, str, "OPTIONS")) return .OPTIONS;
        if (std.mem.eql(u8, str, "TRACE")) return .TRACE;
        if (std.mem.eql(u8, str, "PATCH")) return .PATCH;

        return errors.Error.InvalidMethod;
    }

    /// Check if method is safe (doesn't modify server state)
    ///
    /// Safe methods are defined in RFC 7231 Section 4.2.1 as methods that
    /// don't modify server state. These are GET, HEAD, OPTIONS, and TRACE.
    ///
    /// # Returns
    /// Returns true if the method is safe, false otherwise
    ///
    /// # Example
    /// ```zig
    /// if (Method.GET.isSafe()) {
    ///     // Can be cached and retried safely
    /// }
    /// ```
    pub fn isSafe(self: Method) bool {
        return switch (self) {
            .GET, .HEAD, .OPTIONS, .TRACE => true,
            .POST, .PUT, .DELETE, .CONNECT, .PATCH => false,
        };
    }

    /// Check if method is idempotent
    ///
    /// Idempotent methods are defined in RFC 7231 Section 4.2.2 as methods where
    /// multiple identical requests have the same effect as a single request.
    /// These are GET, HEAD, PUT, DELETE, OPTIONS, and TRACE.
    ///
    /// # Returns
    /// Returns true if the method is idempotent, false otherwise
    ///
    /// # Example
    /// ```zig
    /// if (Method.PUT.isIdempotent()) {
    ///     // Safe to retry on failure
    /// }
    /// ```
    pub fn isIdempotent(self: Method) bool {
        return switch (self) {
            .GET, .HEAD, .PUT, .DELETE, .OPTIONS, .TRACE => true,
            .POST, .CONNECT, .PATCH => false,
        };
    }

    /// Check if method typically has a request body
    ///
    /// Some methods (POST, PUT, PATCH) commonly include a request body,
    /// while others typically don't. This is a guideline, not a strict rule.
    ///
    /// # Returns
    /// Returns true if the method typically includes a request body
    ///
    /// # Example
    /// ```zig
    /// if (Method.POST.hasRequestBody()) {
    ///     // Prepare to send body data
    /// }
    /// ```
    pub fn hasRequestBody(self: Method) bool {
        return switch (self) {
            .POST, .PUT, .PATCH => true,
            .GET, .HEAD, .DELETE, .CONNECT, .OPTIONS, .TRACE => false,
        };
    }

    /// Check if method typically has a response body
    ///
    /// Most methods expect a response body except HEAD (which explicitly
    /// excludes the body) and CONNECT (which establishes a tunnel).
    ///
    /// # Returns
    /// Returns true if the method typically includes a response body
    ///
    /// # Example
    /// ```zig
    /// if (method.hasResponseBody()) {
    ///     // Prepare to receive body data
    /// }
    /// ```
    pub fn hasResponseBody(self: Method) bool {
        return switch (self) {
            .HEAD, .CONNECT => false,
            .GET, .POST, .PUT, .DELETE, .OPTIONS, .TRACE, .PATCH => true,
        };
    }
};

// Tests

test "Method.toString" {
    const testing = std.testing;

    try testing.expectEqualStrings("GET", Method.GET.toString());
    try testing.expectEqualStrings("POST", Method.POST.toString());
    try testing.expectEqualStrings("PUT", Method.PUT.toString());
    try testing.expectEqualStrings("DELETE", Method.DELETE.toString());
    try testing.expectEqualStrings("PATCH", Method.PATCH.toString());
    try testing.expectEqualStrings("HEAD", Method.HEAD.toString());
    try testing.expectEqualStrings("OPTIONS", Method.OPTIONS.toString());
    try testing.expectEqualStrings("TRACE", Method.TRACE.toString());
    try testing.expectEqualStrings("CONNECT", Method.CONNECT.toString());
}

test "Method.fromString" {
    const testing = std.testing;

    try testing.expectEqual(Method.GET, try Method.fromString("GET"));
    try testing.expectEqual(Method.POST, try Method.fromString("POST"));
    try testing.expectEqual(Method.PUT, try Method.fromString("PUT"));
    try testing.expectEqual(Method.DELETE, try Method.fromString("DELETE"));
    try testing.expectEqual(Method.PATCH, try Method.fromString("PATCH"));

    // Invalid method should return error
    try testing.expectError(errors.Error.InvalidMethod, Method.fromString("INVALID"));
    try testing.expectError(errors.Error.InvalidMethod, Method.fromString("get")); // lowercase
}

test "Method.isSafe" {
    const testing = std.testing;

    // Safe methods
    try testing.expect(Method.GET.isSafe());
    try testing.expect(Method.HEAD.isSafe());
    try testing.expect(Method.OPTIONS.isSafe());
    try testing.expect(Method.TRACE.isSafe());

    // Unsafe methods
    try testing.expect(!Method.POST.isSafe());
    try testing.expect(!Method.PUT.isSafe());
    try testing.expect(!Method.DELETE.isSafe());
    try testing.expect(!Method.PATCH.isSafe());
    try testing.expect(!Method.CONNECT.isSafe());
}

test "Method.isIdempotent" {
    const testing = std.testing;

    // Idempotent methods
    try testing.expect(Method.GET.isIdempotent());
    try testing.expect(Method.HEAD.isIdempotent());
    try testing.expect(Method.PUT.isIdempotent());
    try testing.expect(Method.DELETE.isIdempotent());
    try testing.expect(Method.OPTIONS.isIdempotent());
    try testing.expect(Method.TRACE.isIdempotent());

    // Non-idempotent methods
    try testing.expect(!Method.POST.isIdempotent());
    try testing.expect(!Method.PATCH.isIdempotent());
    try testing.expect(!Method.CONNECT.isIdempotent());
}

test "Method.hasRequestBody" {
    const testing = std.testing;

    // Methods that typically have request body
    try testing.expect(Method.POST.hasRequestBody());
    try testing.expect(Method.PUT.hasRequestBody());
    try testing.expect(Method.PATCH.hasRequestBody());

    // Methods that typically don't have request body
    try testing.expect(!Method.GET.hasRequestBody());
    try testing.expect(!Method.HEAD.hasRequestBody());
    try testing.expect(!Method.DELETE.hasRequestBody());
    try testing.expect(!Method.OPTIONS.hasRequestBody());
}

test "Method.hasResponseBody" {
    const testing = std.testing;

    // Methods that typically have response body
    try testing.expect(Method.GET.hasResponseBody());
    try testing.expect(Method.POST.hasResponseBody());
    try testing.expect(Method.PUT.hasResponseBody());
    try testing.expect(Method.DELETE.hasResponseBody());
    try testing.expect(Method.PATCH.hasResponseBody());
    try testing.expect(Method.OPTIONS.hasResponseBody());
    try testing.expect(Method.TRACE.hasResponseBody());

    // Methods that don't have response body
    try testing.expect(!Method.HEAD.hasResponseBody());
    try testing.expect(!Method.CONNECT.hasResponseBody());
}
