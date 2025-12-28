//! HTTP Request builder
//!
//! This module provides a builder pattern for constructing HTTP requests.
//! It handles request parameters, headers, and body construction with
//! validation and safety checks.
//!
//! # Features
//! - Builder pattern with method chaining
//! - Automatic header management
//! - Request validation
//! - Support for all HTTP methods
//!
//! # Usage
//! ```zig
//! var request = try Request.init(allocator, .POST, "https://api.example.com/users");
//! defer request.deinit();
//!
//! try request.setHeader("Content-Type", "application/json");
//! try request.setBody("{\"name\": \"Alice\"}");
//! ```

const std = @import("std");
const errors = @import("../errors.zig");
const Method = @import("../protocol/method.zig").Method;
const Headers = @import("Headers.zig");

/// HTTP Request builder
///
/// Represents an HTTP request with method, URI, headers, and optional body.
/// Uses builder pattern for convenient request construction.
pub const Request = @This();

allocator: std.mem.Allocator,
method: Method,
uri: []const u8,
headers: Headers,
body: ?[]const u8,

/// Initializes a new Request instance
///
/// # Parameters
/// - `allocator`: Memory allocator for request data
/// - `method`: HTTP method (GET, POST, etc.)
/// - `uri`: Target URI (must include scheme: http:// or https://)
///
/// # Returns
/// Returns a new Request instance
///
/// # Errors
/// Returns `InvalidUri` if the URI is malformed or has unsupported scheme
///
/// # Example
/// ```zig
/// var request = try Request.init(allocator, .GET, "https://api.example.com/users");
/// defer request.deinit();
/// ```
pub fn init(allocator: std.mem.Allocator, method: Method, uri: []const u8) !Request {
    // Validate URI has proper scheme
    if (!isValidUri(uri)) {
        return errors.Error.InvalidUri;
    }

    // Duplicate the URI for ownership
    const uri_copy = try allocator.dupe(u8, uri);
    errdefer allocator.free(uri_copy);

    return .{
        .allocator = allocator,
        .method = method,
        .uri = uri_copy,
        .headers = Headers.init(allocator),
        .body = null,
    };
}

/// Frees all memory associated with this Request
pub fn deinit(self: *Request) void {
    self.allocator.free(self.uri);
    self.headers.deinit();
    if (self.body) |b| {
        self.allocator.free(b);
    }
}

/// Validates that a URI has a supported scheme (http:// or https://)
fn isValidUri(uri: []const u8) bool {
    return std.mem.startsWith(u8, uri, "http://") or
        std.mem.startsWith(u8, uri, "https://");
}

/// Sets a header on this request
///
/// This is a builder method that allows method chaining.
/// If a header with the same name already exists, it will be replaced.
///
/// # Parameters
/// - `self`: The Request instance
/// - `name`: Header name
/// - `value`: Header value
///
/// # Returns
/// Returns a pointer to self for method chaining
///
/// # Errors
/// Returns an error if the header is invalid or allocation fails
///
/// # Example
/// ```zig
/// try request.setHeader("Content-Type", "application/json");
/// try request.setHeader("Authorization", "Bearer token");
/// ```
pub fn setHeader(self: *Request, name: []const u8, value: []const u8) !*Request {
    try self.headers.append(name, value);
    return self;
}

/// Sets the request body
///
/// This is a builder method that allows method chaining.
/// The body will be duplicated and owned by the Request.
///
/// # Parameters
/// - `self`: The Request instance
/// - `body`: Request body content
///
/// # Returns
/// Returns a pointer to self for method chaining
///
/// # Errors
/// Returns an error if allocation fails
///
/// # Example
/// ```zig
/// try request.setBody("{\"key\": \"value\"}");
/// ```
pub fn setBody(self: *Request, body: []const u8) !*Request {
    // Free existing body if present
    if (self.body) |b| {
        self.allocator.free(b);
    }

    self.body = try self.allocator.dupe(u8, body);
    return self;
}

/// Gets the HTTP method for this request
pub fn getMethod(self: *const Request) Method {
    return self.method;
}

/// Gets the URI for this request
pub fn getUri(self: *const Request) []const u8 {
    return self.uri;
}

/// Gets the headers for this request
pub fn getHeaders(self: *const Request) *const Headers {
    return &self.headers;
}

/// Gets the body for this request (if set)
pub fn getBody(self: *const Request) ?[]const u8 {
    return self.body;
}

/// Checks if this request has a body
pub fn hasBody(self: *const Request) bool {
    return self.body != null;
}

// Tests
test "Request init and deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var request = try Request.init(allocator, .GET, "https://example.com");
    defer request.deinit();

    try testing.expectEqual(Method.GET, request.getMethod());
    try testing.expectEqualStrings("https://example.com", request.getUri());
    try testing.expect(!request.hasBody());
}

test "Request invalid URI" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Missing scheme
    try testing.expectError(
        errors.Error.InvalidUri,
        Request.init(allocator, .GET, "example.com"),
    );

    // Unsupported scheme
    try testing.expectError(
        errors.Error.InvalidUri,
        Request.init(allocator, .GET, "ftp://example.com"),
    );
}

test "Request set headers" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var request = try Request.init(allocator, .POST, "https://api.example.com");
    defer request.deinit();

    _ = try request.setHeader("Content-Type", "application/json");
    _ = try request.setHeader("User-Agent", "zig_net/0.1.0");

    const content_type = request.getHeaders().get("Content-Type");
    try testing.expect(content_type != null);
    try testing.expectEqualStrings("application/json", content_type.?);

    const user_agent = request.getHeaders().get("User-Agent");
    try testing.expect(user_agent != null);
    try testing.expectEqualStrings("zig_net/0.1.0", user_agent.?);
}

test "Request method chaining" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var request = try Request.init(allocator, .POST, "https://api.example.com");
    defer request.deinit();

    // Method chaining
    _ = try (try (try request
        .setHeader("Content-Type", "application/json"))
        .setHeader("Authorization", "Bearer token123"))
        .setBody("{\"test\": true}");

    try testing.expect(request.getHeaders().contains("Content-Type"));
    try testing.expect(request.getHeaders().contains("Authorization"));
    try testing.expect(request.hasBody());
    try testing.expectEqualStrings("{\"test\": true}", request.getBody().?);
}

test "Request set body" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var request = try Request.init(allocator, .POST, "https://api.example.com");
    defer request.deinit();

    _ = try request.setBody("test data");

    try testing.expect(request.hasBody());
    try testing.expectEqualStrings("test data", request.getBody().?);
}

test "Request replace body" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var request = try Request.init(allocator, .POST, "https://api.example.com");
    defer request.deinit();

    _ = try request.setBody("first body");
    try testing.expectEqualStrings("first body", request.getBody().?);

    // Replace with new body
    _ = try request.setBody("second body");
    try testing.expectEqualStrings("second body", request.getBody().?);
}

test "Request http and https URIs" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var http_request = try Request.init(allocator, .GET, "http://example.com");
    defer http_request.deinit();

    var https_request = try Request.init(allocator, .GET, "https://example.com");
    defer https_request.deinit();

    try testing.expectEqualStrings("http://example.com", http_request.getUri());
    try testing.expectEqualStrings("https://example.com", https_request.getUri());
}
