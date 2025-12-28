//! zig_net CLI Demo
//!
//! This is a simple CLI tool to demonstrate the zig_net HTTP client library.
//! It performs basic HTTP requests to showcase the library's functionality.

const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== zig_net HTTP Client Demo ===\n\n", .{});

    // Initialize the client
    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Demo 1: Simple GET request
    std.debug.print("Demo 1: Simple GET request to httpbin.org\n", .{});
    std.debug.print("Note: This demo is configured for https://httpbin.org/get\n", .{});
    std.debug.print("Note: Requires internet connection\n\n", .{});

    // Uncomment the following code to run the demo:
    // (commented out by default to avoid requiring network access for builds)

    // const response = try client.get("https://httpbin.org/get");
    // defer response.deinit();
    //
    // std.debug.print("Status: {} {s}\n", .{
    //     response.getStatus(),
    //     response.getReasonPhrase(),
    // });
    //
    // if (response.isSuccess()) {
    //     std.debug.print("Response body length: {} bytes\n", .{response.getBody().len});
    //     std.debug.print("Content-Type: {s}\n", .{response.getHeader("Content-Type") orelse "unknown"});
    //     std.debug.print("\nFirst 200 chars of body:\n{s}\n", .{response.getBody()[0..@min(200, response.getBody().len)]});
    // }

    std.debug.print("\nDemo complete! Uncomment the code in src/main.zig to run actual HTTP requests.\n", .{});
    std.debug.print("\nFor more examples, see:\n", .{});
    std.debug.print("  - README.md for usage examples\n", .{});
    std.debug.print("  - tests/integration/httpbin_test.zig for integration tests\n", .{});
    std.debug.print("  - Run 'zig build test' to run unit tests\n", .{});
}

