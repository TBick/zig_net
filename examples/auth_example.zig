//! Authentication Example
//!
//! This example demonstrates how to use HTTP authentication with zig_net.
//!
//! Run with:
//! zig build-exe examples/auth_example.zig --dep zig_net -Mroot=examples/auth_example.zig -Mzig_net=src/root.zig
//! OR
//! zig run examples/auth_example.zig

const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== zig_net Authentication Examples ===\n\n", .{});

    // Example 1: Basic Authentication
    try basicAuthExample(allocator);

    // Example 2: Bearer Token Authentication
    try bearerTokenExample(allocator);

    std.debug.print("\n=== All examples completed successfully! ===\n", .{});
}

/// Example 1: Basic Authentication (RFC 7617)
///
/// Basic authentication encodes username:password in base64 and sends it
/// in the Authorization header.
fn basicAuthExample(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Example 1: Basic Authentication ---\n", .{});

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Create a request
    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/basic-auth/user/passwd",
    );
    defer request.deinit();

    // Set Basic Auth credentials
    // This will automatically encode the credentials and set the Authorization header
    _ = try request.setBasicAuth("user", "passwd");

    std.debug.print("Request URI: {s}\n", .{request.getUri()});
    std.debug.print("Sending request with Basic Auth...\n", .{});

    // Send the request
    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Response Status: {d} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase(),
    });

    if (response.isSuccess()) {
        const body = response.getBody();
        std.debug.print("Response Body:\n{s}\n", .{body});
    } else {
        std.debug.print("Authentication failed!\n", .{});
    }

    std.debug.print("\n", .{});
}

/// Example 2: Bearer Token Authentication (RFC 6750)
///
/// Bearer token authentication is commonly used with OAuth 2.0 and JWT.
/// The token is sent in the Authorization header as "Bearer <token>".
fn bearerTokenExample(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Example 2: Bearer Token Authentication ---\n", .{});

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Create a request
    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/bearer",
    );
    defer request.deinit();

    // Set Bearer token
    // This will set the Authorization header to "Bearer <token>"
    _ = try request.setBearerToken("my-secret-token-12345");

    std.debug.print("Request URI: {s}\n", .{request.getUri()});
    std.debug.print("Sending request with Bearer token...\n", .{});

    // Send the request
    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Response Status: {d} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase(),
    });

    if (response.isSuccess()) {
        const body = response.getBody();
        std.debug.print("Response Body:\n{s}\n", .{body});
    } else {
        std.debug.print("Authentication failed!\n", .{});
    }

    std.debug.print("\n", .{});
}

/// Example 3: Manual Authorization Header
///
/// You can also manually set the Authorization header if you need a custom
/// authentication scheme.
fn manualAuthExample(allocator: std.mem.Allocator) !void {
    _ = allocator; // This is just a code example, not executed

    // Example: Custom authentication scheme
    // var request = try zig_net.Request.init(allocator, .GET, "https://api.example.com/data");
    // defer request.deinit();
    //
    // _ = try request.setHeader("Authorization", "Custom my-custom-token");
    //
    // // Or use the auth helpers directly:
    // const basic = zig_net.BasicAuth.init("user", "pass");
    // const auth_header = try basic.toHeader(allocator);
    // defer allocator.free(auth_header);
    //
    // _ = try request.setHeader("Authorization", auth_header);
}
