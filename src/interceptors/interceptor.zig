//! HTTP Request/Response Interceptors
//!
//! This module provides middleware-style interceptor support for HTTP requests
//! and responses. Interceptors allow you to modify requests before they're sent
//! and responses after they're received.
//!
//! # Common Use Cases
//! - Logging all requests and responses
//! - Adding authentication headers automatically
//! - Collecting metrics (timing, sizes, status codes)
//! - Request/response validation
//! - Error transformation
//!
//! # Usage
//! ```zig
//! // Define an interceptor function
//! fn logRequest(request: *Request) !void {
//!     std.debug.print("Request: {s} {s}\n", .{request.getMethod(), request.getUri()});
//! }
//!
//! // Use with Client (if integrated) or call manually
//! try logRequest(&request);
//! ```

const std = @import("std");
const Request = @import("../client/Request.zig");
const Response = @import("../client/Response.zig");

/// Request Interceptor Function Type
///
/// A function that processes a request before it's sent.
/// Can modify the request (add headers, change body, etc.).
///
/// # Parameters
/// - `request`: The request to process
///
/// # Errors
/// Should return an error if the request should be aborted
pub const RequestInterceptorFn = *const fn (request: *Request) anyerror!void;

/// Response Interceptor Function Type
///
/// A function that processes a response after it's received.
/// Can inspect or modify the response.
///
/// # Parameters
/// - `response`: The response to process
///
/// # Errors
/// Should return an error if the response should be rejected
pub const ResponseInterceptorFn = *const fn (response: *const Response) anyerror!void;

/// Example: Logging Request Interceptor
///
/// Logs request method and URI to stderr.
///
/// # Example
/// ```zig
/// try loggingRequestInterceptor(&request);
/// ```
pub fn loggingRequestInterceptor(request: *Request) !void {
    std.debug.print("[HTTP Request] {s} {s}\n", .{
        @tagName(request.getMethod()),
        request.getUri(),
    });
}

/// Example: Logging Response Interceptor
///
/// Logs response status code to stderr.
///
/// # Example
/// ```zig
/// try loggingResponseInterceptor(&response);
/// ```
pub fn loggingResponseInterceptor(response: *const Response) !void {
    std.debug.print("[HTTP Response] Status: {d}\n", .{response.getStatus()});
}

// Tests
test "RequestInterceptorFn type" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var request = try Request.init(allocator, .GET, "https://example.com");
    defer request.deinit();

    // Should be able to call the interceptor
    try loggingRequestInterceptor(&request);
}

test "ResponseInterceptorFn type" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const Headers = @import("../client/Headers.zig");
    var headers = Headers.init(allocator);
    defer headers.deinit();

    const body = try allocator.dupe(u8, "test");
    var response = Response.init(allocator, 200, headers, body);
    defer response.deinit();

    // Should be able to call the interceptor
    try loggingResponseInterceptor(&response);
}
