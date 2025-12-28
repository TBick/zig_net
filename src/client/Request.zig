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
const http = @import("../protocol/http.zig");
const Headers = @import("Headers.zig");
const auth = @import("../auth/auth.zig");

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

/// Sets a JSON body and Content-Type header
///
/// This is a convenience method that sets the body and automatically
/// sets the Content-Type header to "application/json".
///
/// # Parameters
/// - `self`: The Request instance
/// - `json_body`: JSON string
///
/// # Returns
/// Returns a pointer to self for method chaining
///
/// # Example
/// ```zig
/// try request.setJsonBody("{\"name\": \"Alice\"}");
/// ```
pub fn setJsonBody(self: *Request, json_body: []const u8) !*Request {
    _ = try self.setBody(json_body);
    _ = try self.setHeader("Content-Type", http.MimeType.JSON);
    return self;
}

/// Sets a form-encoded body and Content-Type header
///
/// This is a convenience method that URL-encodes form data and sets
/// the appropriate Content-Type header.
///
/// # Parameters
/// - `self`: The Request instance
/// - `form_data`: Form data as key-value pairs
///
/// # Returns
/// Returns a pointer to self for method chaining
///
/// # Example
/// ```zig
/// var form = std.StringHashMap([]const u8).init(allocator);
/// try form.put("username", "alice");
/// try form.put("password", "secret");
/// try request.setFormBody(&form);
/// ```
pub fn setFormBody(self: *Request, form_data: *const std.StringHashMap([]const u8)) !*Request {
    var result = std.ArrayList(u8){};
    defer result.deinit(self.allocator);

    var first = true;
    var it = form_data.iterator();
    while (it.next()) |entry| {
        if (!first) try result.append(self.allocator, '&');
        first = false;

        const encoded_key = try http.urlEncode(self.allocator, entry.key_ptr.*);
        defer self.allocator.free(encoded_key);
        try result.appendSlice(self.allocator, encoded_key);

        try result.append(self.allocator, '=');

        const encoded_value = try http.urlEncode(self.allocator, entry.value_ptr.*);
        defer self.allocator.free(encoded_value);
        try result.appendSlice(self.allocator, encoded_value);
    }

    const form_body = try result.toOwnedSlice(self.allocator);
    defer self.allocator.free(form_body);

    _ = try self.setBody(form_body);
    _ = try self.setHeader("Content-Type", http.MimeType.FORM_URLENCODED);
    return self;
}

/// Sets HTTP Basic Authentication
///
/// This is a convenience method that encodes the username and password
/// and sets the Authorization header with Basic authentication.
///
/// # Parameters
/// - `self`: The Request instance
/// - `username`: Username for authentication
/// - `password`: Password for authentication
///
/// # Returns
/// Returns a pointer to self for method chaining
///
/// # Security
/// Credentials are base64 encoded, NOT encrypted. Always use HTTPS.
///
/// # Example
/// ```zig
/// _ = try request.setBasicAuth("alice", "secret123");
/// ```
pub fn setBasicAuth(self: *Request, username: []const u8, password: []const u8) !*Request {
    const basic_auth = auth.BasicAuth.init(username, password);
    try basic_auth.applyToRequest(self);
    return self;
}

/// Sets Bearer token authentication
///
/// This is a convenience method that sets the Authorization header
/// with a Bearer token (e.g., OAuth 2.0, JWT).
///
/// # Parameters
/// - `self`: The Request instance
/// - `token`: Bearer token for authentication
///
/// # Returns
/// Returns a pointer to self for method chaining
///
/// # Security
/// Tokens grant access to resources. Always use HTTPS to protect tokens.
///
/// # Example
/// ```zig
/// _ = try request.setBearerToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...");
/// ```
pub fn setBearerToken(self: *Request, token: []const u8) !*Request {
    const bearer_auth = auth.BearerAuth.init(token);
    try bearer_auth.applyToRequest(self);
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
