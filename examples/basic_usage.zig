//! Basic usage examples for zig_net HTTP client
//!
//! This file demonstrates common use cases for the zig_net library.
//!
//! To run these examples, you'll need to:
//! 1. Uncomment the example you want to run
//! 2. Build and run: zig build-exe examples/basic_usage.zig
//! 3. Run: ./basic_usage
//!
//! Note: These examples require internet connectivity.

const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== zig_net Examples ===\n\n", .{});

    // Example 1: Simple GET request
    // try exampleSimpleGet(allocator);

    // Example 2: POST with JSON body
    // try examplePostJson(allocator);

    // Example 3: Custom headers
    // try exampleCustomHeaders(allocator);

    // Example 4: Error handling
    // try exampleErrorHandling(allocator);

    // Example 5: Form data
    // try exampleFormData(allocator);

    std.debug.print("Examples are commented out by default.\n", .{});
    std.debug.print("Uncomment the example you want to run in examples/basic_usage.zig\n", .{});
}

/// Example 1: Simple GET request
fn exampleSimpleGet(allocator: std.mem.Allocator) !void {
    std.debug.print("Example 1: Simple GET request\n", .{});
    std.debug.print("------------------------------\n", .{});

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    const response = try client.get("https://httpbin.org/get");
    defer response.deinit();

    std.debug.print("Status: {} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase(),
    });
    std.debug.print("Content-Type: {s}\n", .{
        response.getContentType() orelse "unknown",
    });
    std.debug.print("Body length: {} bytes\n", .{response.getBody().len});
    std.debug.print("\nFirst 200 chars of body:\n{s}\n\n", .{
        response.getBody()[0..@min(200, response.getBody().len)],
    });
}

/// Example 2: POST with JSON body
fn examplePostJson(allocator: std.mem.Allocator) !void {
    std.debug.print("Example 2: POST with JSON body\n", .{});
    std.debug.print("-------------------------------\n", .{});

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(allocator, .POST, "https://httpbin.org/post");
    defer request.deinit();

    _ = try request.setJsonBody(
        \\{
        \\  "name": "Alice",
        \\  "email": "alice@example.com",
        \\  "age": 30
        \\}
    );

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Status: {} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase(),
    });

    if (response.isSuccess()) {
        std.debug.print("Successfully posted JSON data!\n", .{});
        std.debug.print("\nResponse body:\n{s}\n\n", .{response.getBody()});
    }
}

/// Example 3: Custom headers
fn exampleCustomHeaders(allocator: std.mem.Allocator) !void {
    std.debug.print("Example 3: Custom headers\n", .{});
    std.debug.print("-------------------------\n", .{});

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(allocator, .GET, "https://httpbin.org/headers");
    defer request.deinit();

    _ = try (try (try request
        .setHeader("User-Agent", "zig_net-example/0.1.0"))
        .setHeader("X-Custom-Header", "CustomValue"))
        .setHeader("Authorization", "Bearer token123");

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Status: {} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase(),
    });
    std.debug.print("\nResponse shows our custom headers:\n{s}\n\n", .{
        response.getBody(),
    });
}

/// Example 4: Error handling
fn exampleErrorHandling(allocator: std.mem.Allocator) !void {
    std.debug.print("Example 4: Error handling\n", .{});
    std.debug.print("-------------------------\n", .{});

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Try to access a non-existent endpoint
    const response = client.get("https://httpbin.org/status/404") catch |err| {
        std.debug.print("Request failed with error: {}\n", .{err});
        std.debug.print("Error message: {s}\n\n", .{zig_net.errors.getErrorMessage(err)});
        return err;
    };
    defer response.deinit();

    if (response.isClientError()) {
        std.debug.print("Got client error: {} {s}\n", .{
            response.getStatus(),
            response.getReasonPhrase(),
        });
    } else if (response.isServerError()) {
        std.debug.print("Got server error: {} {s}\n", .{
            response.getStatus(),
            response.getReasonPhrase(),
        });
    } else if (response.isSuccess()) {
        std.debug.print("Request succeeded!\n", .{});
    }
    std.debug.print("\n", .{});
}

/// Example 5: Form data
fn exampleFormData(allocator: std.mem.Allocator) !void {
    std.debug.print("Example 5: Form data\n", .{});
    std.debug.print("--------------------\n", .{});

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(allocator, .POST, "https://httpbin.org/post");
    defer request.deinit();

    var form = std.StringHashMap([]const u8).init(allocator);
    defer form.deinit();

    try form.put("username", "alice");
    try form.put("password", "secret123");
    try form.put("remember", "true");

    _ = try request.setFormBody(&form);

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Status: {} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase(),
    });

    if (response.isSuccess()) {
        std.debug.print("Successfully posted form data!\n", .{});
        std.debug.print("\nResponse:\n{s}\n\n", .{response.getBody()});
    }
}
