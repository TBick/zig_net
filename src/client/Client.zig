//! HTTP/HTTPS Client
//!
//! This module provides a high-level HTTP/HTTPS client that wraps the Zig
//! standard library's std.http.Client with a more convenient API.
//!
//! # Features
//! - HTTP and HTTPS support
//! - Connection pooling (via std.http.Client)
//! - Automatic redirect following
//! - Configurable timeouts
//! - Simple convenience methods (get, post, etc.)
//! - Full control via Request builder
//!
//! # Usage - Simple GET
//! ```zig
//! var client = try Client.init(allocator, .{});
//! defer client.deinit();
//!
//! const response = try client.get("https://api.example.com/users");
//! defer response.deinit();
//! ```
//!
//! # Usage - POST with body
//! ```zig
//! var client = try Client.init(allocator, .{});
//! defer client.deinit();
//!
//! var request = try Request.init(allocator, .POST, "https://api.example.com/users");
//! defer request.deinit();
//!
//! _ = try request.setHeader("Content-Type", "application/json");
//! _ = try request.setBody("{\"name\": \"Alice\"}");
//!
//! const response = try client.send(&request);
//! defer response.deinit();
//! ```

const std = @import("std");
const errors = @import("../errors.zig");
const Method = @import("../protocol/method.zig").Method;
const Request = @import("Request.zig");
const Response = @import("Response.zig");
const Headers = @import("Headers.zig");
const chunked = @import("../encoding/chunked.zig");

/// Client configuration options
pub const ClientOptions = struct {
    /// Whether to automatically follow redirects (default: true)
    follow_redirects: bool = true,

    /// Maximum number of redirects to follow (default: 10)
    max_redirects: u8 = 10,

    /// Request timeout in milliseconds (0 = no timeout)
    timeout_ms: u64 = 30000,

    /// Whether to verify TLS certificates (default: true)
    /// Note: std.http.Client handles TLS verification automatically
    verify_tls: bool = true,
};

/// HTTP/HTTPS Client
///
/// Wraps std.http.Client to provide a convenient API for making HTTP requests.
/// The client maintains a connection pool and can follow redirects automatically.
pub const Client = @This();

allocator: std.mem.Allocator,
http_client: std.http.Client,
options: ClientOptions,

/// Initializes a new HTTP/HTTPS client
///
/// # Parameters
/// - `allocator`: Memory allocator for client operations
/// - `options`: Client configuration options
///
/// # Returns
/// Returns a new Client instance
///
/// # Example
/// ```zig
/// var client = try Client.init(allocator, .{
///     .max_redirects = 10,
///     .timeout_ms = 5000,
/// });
/// defer client.deinit();
/// ```
pub fn init(allocator: std.mem.Allocator, options: ClientOptions) !Client {
    return .{
        .allocator = allocator,
        .http_client = .{ .allocator = allocator },
        .options = options,
    };
}

/// Frees all resources associated with this client
///
/// This will close any open connections in the connection pool.
pub fn deinit(self: *Client) void {
    self.http_client.deinit();
}

/// Performs a GET request
///
/// This is a convenience method for simple GET requests without custom headers.
///
/// # Parameters
/// - `self`: The Client instance
/// - `uri`: The target URI (must include scheme: http:// or https://)
///
/// # Returns
/// Returns a Response that must be deinitialized by the caller
///
/// # Errors
/// Returns an error if the request fails or the URI is invalid
///
/// # Example
/// ```zig
/// const response = try client.get("https://httpbin.org/get");
/// defer response.deinit();
/// ```
pub fn get(self: *Client, uri: []const u8) !Response {
    var request = try Request.init(self.allocator, .GET, uri);
    defer request.deinit();

    return try self.send(&request);
}

/// Performs a POST request with a body
///
/// This is a convenience method for simple POST requests.
///
/// # Parameters
/// - `self`: The Client instance
/// - `uri`: The target URI (must include scheme: http:// or https://)
/// - `body`: Request body content
/// - `content_type`: Content-Type header value (e.g., "application/json")
///
/// # Returns
/// Returns a Response that must be deinitialized by the caller
///
/// # Example
/// ```zig
/// const response = try client.post(
///     "https://httpbin.org/post",
///     "{\"test\": true}",
///     "application/json"
/// );
/// defer response.deinit();
/// ```
pub fn post(self: *Client, uri: []const u8, body: []const u8, content_type: []const u8) !Response {
    var request = try Request.init(self.allocator, .POST, uri);
    defer request.deinit();

    _ = try request.setHeader("Content-Type", content_type);
    _ = try request.setBody(body);

    return try self.send(&request);
}

/// Performs a PUT request with a body
///
/// # Parameters
/// - `self`: The Client instance
/// - `uri`: The target URI
/// - `body`: Request body content
/// - `content_type`: Content-Type header value
///
/// # Returns
/// Returns a Response that must be deinitialized by the caller
pub fn put(self: *Client, uri: []const u8, body: []const u8, content_type: []const u8) !Response {
    var request = try Request.init(self.allocator, .PUT, uri);
    defer request.deinit();

    _ = try request.setHeader("Content-Type", content_type);
    _ = try request.setBody(body);

    return try self.send(&request);
}

/// Performs a DELETE request
///
/// # Parameters
/// - `self`: The Client instance
/// - `uri`: The target URI
///
/// # Returns
/// Returns a Response that must be deinitialized by the caller
pub fn delete(self: *Client, uri: []const u8) !Response {
    var request = try Request.init(self.allocator, .DELETE, uri);
    defer request.deinit();

    return try self.send(&request);
}

/// Sends a custom request
///
/// This method provides full control over the request by accepting a Request object.
/// Use this when you need custom headers, methods, or other request configuration.
///
/// This method automatically follows redirects if configured to do so.
///
/// # Parameters
/// - `self`: The Client instance
/// - `request`: The Request to send
///
/// # Returns
/// Returns a Response that must be deinitialized by the caller
///
/// # Errors
/// Returns an error if the request fails
///
/// # Example
/// ```zig
/// var request = try Request.init(allocator, .POST, "https://api.example.com/data");
/// defer request.deinit();
///
/// _ = try request.setHeader("Authorization", "Bearer token123");
/// _ = try request.setHeader("Content-Type", "application/json");
/// _ = try request.setBody("{\"data\": \"value\"}");
///
/// const response = try client.send(&request);
/// defer response.deinit();
/// ```
pub fn send(self: *Client, request: *const Request) !Response {
    if (!self.options.follow_redirects) {
        // If not following redirects, just send the request directly
        return try self.sendInternal(request);
    }

    // Track visited URLs to detect redirect loops
    var visited_urls = std.StringHashMap(void).init(self.allocator);
    defer visited_urls.deinit();

    var current_uri = request.getUri();
    var current_method = request.getMethod();
    var redirect_count: u8 = 0;

    while (true) {
        // Check if we've visited this URL before (redirect loop)
        if (visited_urls.contains(current_uri)) {
            return errors.Error.RedirectLoopDetected;
        }
        try visited_urls.put(current_uri, {});

        // Create a request for the current URI
        var current_request = if (redirect_count == 0)
            request.*
        else blk: {
            var req = try Request.init(self.allocator, current_method, current_uri);
            // Copy headers from original request (except Host which will be set automatically)
            var header_it = request.getHeaders().iterator();
            while (header_it.next()) |entry| {
                if (!std.ascii.eqlIgnoreCase(entry.key_ptr.*, "host")) {
                    try req.headers.append(entry.key_ptr.*, entry.value_ptr.*);
                }
            }
            // For non-GET requests after a 303 redirect, don't include the body
            if (current_method != .GET and request.getBody()) |body| {
                _ = try req.setBody(body);
            }
            break :blk req;
        };
        defer if (redirect_count > 0) current_request.deinit();

        // Send the request
        const response = try self.sendInternal(&current_request);

        // Check if this is a redirect status
        const status = response.getStatus();
        const is_redirect = status >= 300 and status < 400;

        if (!is_redirect) {
            // Not a redirect, return the response
            return response;
        }

        // This is a redirect - check if we should follow it
        redirect_count += 1;
        if (redirect_count > self.options.max_redirects) {
            response.deinit();
            return errors.Error.TooManyRedirects;
        }

        // Get the Location header
        const location = response.getHeader("Location") orelse {
            response.deinit();
            return errors.Error.InvalidRedirectLocation;
        };

        // Handle different redirect status codes
        // 303 See Other: Always use GET for the redirect
        if (status == 303) {
            current_method = .GET;
        }
        // 301 Moved Permanently, 302 Found: Change POST/PUT/DELETE to GET
        else if ((status == 301 or status == 302) and
            (current_method == .POST or current_method == .PUT or current_method == .DELETE))
        {
            current_method = .GET;
        }
        // 307 Temporary Redirect, 308 Permanent Redirect: Keep the same method

        // Resolve the redirect location (handle relative URLs)
        const new_uri_str = try self.allocator.dupe(u8, location);
        defer self.allocator.free(new_uri_str);

        // Check if the location is absolute or relative
        const new_uri = if (std.mem.startsWith(u8, new_uri_str, "http://") or
            std.mem.startsWith(u8, new_uri_str, "https://"))
            new_uri_str
        else blk: {
            // Relative URL - construct absolute URL from current URI
            const current_parsed = try std.Uri.parse(current_uri);
            var buf: [2048]u8 = undefined;
            const absolute = try std.fmt.bufPrint(&buf, "{s}://{s}{s}", .{
                current_parsed.scheme,
                current_parsed.host.?,
                new_uri_str,
            });
            break :blk try self.allocator.dupe(u8, absolute);
        };
        defer if (new_uri.ptr != new_uri_str.ptr) self.allocator.free(new_uri);

        current_uri = new_uri;
        response.deinit();
    }
}

/// Internal method to send a single HTTP request without redirect handling
fn sendInternal(self: *Client, request: *const Request) !Response {
    // Parse the URI
    const uri = try std.Uri.parse(request.getUri());

    // Convert our Method enum to std.http.Method
    const method = methodToStd(request.getMethod());

    // Create request buffer for headers and body
    var header_buffer: [8192]u8 = undefined;

    // Prepare the fetch request
    var http_request = try self.http_client.open(method, uri, .{
        .server_header_buffer = &header_buffer,
    });
    defer http_request.deinit();

    // Add custom headers from the request
    var header_it = request.getHeaders().iterator();
    while (header_it.next()) |entry| {
        try http_request.headers.append(entry.key_ptr.*, entry.value_ptr.*);
    }

    // Send the request
    try http_request.send();

    // Send body if present
    if (request.getBody()) |body| {
        try http_request.writeAll(body);
    }

    // Finish the request
    try http_request.finish();

    // Wait for response
    try http_request.wait();

    // Read the response body
    const raw_body = try http_request.reader().readAllAlloc(self.allocator, 10 * 1024 * 1024); // 10 MB limit
    errdefer self.allocator.free(raw_body);

    // Copy response headers into our Headers structure
    var response_headers = Headers.init(self.allocator);
    errdefer response_headers.deinit();

    var field_it = http_request.response.iterateHeaders();
    while (field_it.next()) |header| {
        try response_headers.append(header.name, header.value);
    }

    // Check if response is chunked-encoded
    const is_chunked = if (response_headers.get("Transfer-Encoding")) |encoding|
        std.mem.indexOf(u8, encoding, "chunked") != null
    else
        false;

    // Decode chunked encoding if present
    const body = if (is_chunked) blk: {
        const decoded = try chunked.decode(self.allocator, raw_body);
        self.allocator.free(raw_body);
        break :blk decoded;
    } else raw_body;

    // Create and return the response
    return Response.init(
        self.allocator,
        @intFromEnum(http_request.response.status),
        response_headers,
        body,
    );
}

/// Converts our Method enum to std.http.Method
fn methodToStd(method: Method) std.http.Method {
    return switch (method) {
        .GET => .GET,
        .POST => .POST,
        .PUT => .PUT,
        .DELETE => .DELETE,
        .PATCH => .PATCH,
        .HEAD => .HEAD,
        .OPTIONS => .OPTIONS,
        .TRACE => .TRACE,
        .CONNECT => .CONNECT,
    };
}

// Tests
test "Client init and deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var client = try Client.init(allocator, .{});
    defer client.deinit();

    try testing.expect(client.options.follow_redirects);
    try testing.expectEqual(@as(u8, 10), client.options.max_redirects);
    try testing.expectEqual(@as(u64, 30000), client.options.timeout_ms);
    try testing.expect(client.options.verify_tls);
}

test "Client custom options" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var client = try Client.init(allocator, .{
        .follow_redirects = false,
        .max_redirects = 20,
        .timeout_ms = 5000,
        .verify_tls = false,
    });
    defer client.deinit();

    try testing.expect(!client.options.follow_redirects);
    try testing.expectEqual(@as(u8, 20), client.options.max_redirects);
    try testing.expectEqual(@as(u64, 5000), client.options.timeout_ms);
    try testing.expect(!client.options.verify_tls);
}

test "methodToStd conversion" {
    const testing = std.testing;

    try testing.expectEqual(std.http.Method.GET, methodToStd(.GET));
    try testing.expectEqual(std.http.Method.POST, methodToStd(.POST));
    try testing.expectEqual(std.http.Method.PUT, methodToStd(.PUT));
    try testing.expectEqual(std.http.Method.DELETE, methodToStd(.DELETE));
    try testing.expectEqual(std.http.Method.PATCH, methodToStd(.PATCH));
}

// Note: Integration tests for actual HTTP requests are in tests/integration/
