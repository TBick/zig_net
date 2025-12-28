//! HTTP Response parser and accessor
//!
//! This module provides convenient accessors for HTTP responses received from
//! the server. It wraps response data with helper methods for common operations.
//!
//! # Features
//! - Convenient status code accessors
//! - Header lookups (case-insensitive)
//! - Body content access
//! - Response validation
//!
//! # Usage
//! ```zig
//! const response = try client.get(allocator, "https://example.com");
//! defer response.deinit();
//!
//! if (response.isSuccess()) {
//!     const body = response.getBody();
//!     std.debug.print("Body: {s}\n", .{body});
//! }
//! ```

const std = @import("std");
const errors = @import("../errors.zig");
const status_utils = @import("../protocol/status.zig");
const Headers = @import("Headers.zig");

/// HTTP Response
///
/// Represents an HTTP response with status code, headers, and body.
/// The response owns its data and must be deinitialized by the caller.
pub const Response = @This();

allocator: std.mem.Allocator,
status: status_utils.StatusCode,
headers: Headers,
body: []const u8,

/// Creates a new Response instance
///
/// This is typically called internally by the Client, not by users directly.
///
/// # Parameters
/// - `allocator`: Memory allocator for response data
/// - `status_code`: HTTP status code from the response
/// - `headers`: Response headers
/// - `body`: Response body content
///
/// # Returns
/// Returns a new Response instance
///
/// # Note
/// The Response takes ownership of the body slice. The headers are moved
/// into the Response.
pub fn init(
    allocator: std.mem.Allocator,
    status_code: status_utils.StatusCode,
    headers: Headers,
    body: []const u8,
) Response {
    return .{
        .allocator = allocator,
        .status = status_code,
        .headers = headers,
        .body = body,
    };
}

/// Frees all memory associated with this Response
///
/// This must be called by the user when they're done with the response.
pub fn deinit(self: *Response) void {
    self.allocator.free(self.body);
    self.headers.deinit();
}

/// Gets the HTTP status code
///
/// # Returns
/// Returns the status code (e.g., 200, 404, 500)
pub fn getStatus(self: *const Response) status_utils.StatusCode {
    return self.status;
}

/// Gets the response body
///
/// # Returns
/// Returns the response body as a byte slice
pub fn getBody(self: *const Response) []const u8 {
    return self.body;
}

/// Gets a header value by name (case-insensitive)
///
/// # Parameters
/// - `name`: Header name to look up
///
/// # Returns
/// Returns the header value if found, or null if not present
pub fn getHeader(self: *const Response, name: []const u8) ?[]const u8 {
    return self.headers.get(name);
}

/// Gets all headers
///
/// # Returns
/// Returns a reference to the headers map
pub fn getHeaders(self: *const Response) *const Headers {
    return &self.headers;
}

/// Checks if the response status indicates success (2xx)
///
/// # Returns
/// Returns true if the status code is in the 200-299 range
pub fn isSuccess(self: *const Response) bool {
    return status_utils.isSuccess(self.status);
}

/// Checks if the response status indicates redirection (3xx)
///
/// # Returns
/// Returns true if the status code is in the 300-399 range
pub fn isRedirection(self: *const Response) bool {
    return status_utils.isRedirection(self.status);
}

/// Checks if the response status indicates client error (4xx)
///
/// # Returns
/// Returns true if the status code is in the 400-499 range
pub fn isClientError(self: *const Response) bool {
    return status_utils.isClientError(self.status);
}

/// Checks if the response status indicates server error (5xx)
///
/// # Returns
/// Returns true if the status code is in the 500-599 range
pub fn isServerError(self: *const Response) bool {
    return status_utils.isServerError(self.status);
}

/// Checks if the response status indicates any error (4xx or 5xx)
///
/// # Returns
/// Returns true if the status code is 4xx or 5xx
pub fn isError(self: *const Response) bool {
    return status_utils.isError(self.status);
}

/// Gets the reason phrase for the status code
///
/// # Returns
/// Returns the standard HTTP reason phrase (e.g., "OK", "Not Found")
pub fn getReasonPhrase(self: *const Response) []const u8 {
    return status_utils.getReasonPhrase(self.status);
}

// Tests
test "Response init and deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const body = try allocator.dupe(u8, "Hello, World!");
    const headers = Headers.init(allocator);

    var response = Response.init(allocator, 200, headers, body);
    defer response.deinit();

    try testing.expectEqual(@as(status_utils.StatusCode, 200), response.getStatus());
    try testing.expectEqualStrings("Hello, World!", response.getBody());
}

test "Response status classification" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Success response
    const success_body = try allocator.dupe(u8, "success");
    const success_headers = Headers.init(allocator);
    var success_response = Response.init(allocator, 200, success_headers, success_body);
    defer success_response.deinit();

    try testing.expect(success_response.isSuccess());
    try testing.expect(!success_response.isError());
    try testing.expect(!success_response.isRedirection());

    // Error response
    const error_body = try allocator.dupe(u8, "error");
    const error_headers = Headers.init(allocator);
    var error_response = Response.init(allocator, 404, error_headers, error_body);
    defer error_response.deinit();

    try testing.expect(!error_response.isSuccess());
    try testing.expect(error_response.isError());
    try testing.expect(error_response.isClientError());
    try testing.expect(!error_response.isServerError());

    // Redirect response
    const redirect_body = try allocator.dupe(u8, "");
    const redirect_headers = Headers.init(allocator);
    var redirect_response = Response.init(allocator, 301, redirect_headers, redirect_body);
    defer redirect_response.deinit();

    try testing.expect(!redirect_response.isSuccess());
    try testing.expect(!redirect_response.isError());
    try testing.expect(redirect_response.isRedirection());
}

test "Response headers" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const body = try allocator.dupe(u8, "test");
    var temp_headers = Headers.init(allocator);
    try temp_headers.append("Content-Type", "application/json");
    try temp_headers.append("Server", "zig_net/0.1.0");

    var response = Response.init(allocator, 200, temp_headers, body);
    defer response.deinit();

    const content_type = response.getHeader("Content-Type");
    try testing.expect(content_type != null);
    try testing.expectEqualStrings("application/json", content_type.?);

    const server = response.getHeader("server"); // Case-insensitive
    try testing.expect(server != null);
    try testing.expectEqualStrings("zig_net/0.1.0", server.?);

    const missing = response.getHeader("X-Missing");
    try testing.expect(missing == null);
}

test "Response reason phrase" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const body = try allocator.dupe(u8, "");
    const headers = Headers.init(allocator);

    var response = Response.init(allocator, 404, headers, body);
    defer response.deinit();

    try testing.expectEqualStrings("Not Found", response.getReasonPhrase());
}
