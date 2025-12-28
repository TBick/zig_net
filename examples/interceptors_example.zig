//! Interceptors Example
//!
//! This example demonstrates how to use interceptors with zig_net for
//! logging, metrics collection, and custom request/response processing.
//!
//! Run with:
//! zig build-exe examples/interceptors_example.zig --dep zig_net -Mroot=examples/interceptors_example.zig -Mzig_net=src/root.zig
//! OR
//! zig run examples/interceptors_example.zig

const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== zig_net Interceptors Examples ===\n\n", .{});

    // Example 1: Basic Logging Interceptors
    try loggingInterceptorExample(allocator);

    // Example 2: Metrics Collection
    try metricsInterceptorExample(allocator);

    // Example 3: Custom Interceptor
    try customInterceptorExample(allocator);

    std.debug.print("\n=== All interceptor examples completed successfully! ===\n", .{});
}

/// Example 1: Basic Logging Interceptors
///
/// Use the built-in logging interceptors to track requests and responses
fn loggingInterceptorExample(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Example 1: Logging Interceptors ---\n", .{});

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Create a request
    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/get",
    );
    defer request.deinit();

    _ = try request.setHeader("User-Agent", "zig_net/0.1.0");

    // Apply request interceptor (logs the request)
    std.debug.print("\nApplying request interceptor:\n", .{});
    try zig_net.interceptor.loggingRequestInterceptor(&request);

    // Send the request
    const response = try client.send(&request);
    defer response.deinit();

    // Apply response interceptor (logs the response)
    std.debug.print("Applying response interceptor:\n", .{});
    try zig_net.interceptor.loggingResponseInterceptor(&response);

    std.debug.print("\n", .{});
}

/// Example 2: Metrics Collection
///
/// Use the MetricsCollector to gather HTTP statistics
fn metricsInterceptorExample(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Example 2: Metrics Collection ---\n", .{});

    var metrics = zig_net.MetricsCollector.init(allocator);
    defer metrics.deinit();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Make several requests
    const urls = [_][]const u8{
        "https://httpbin.org/get",
        "https://httpbin.org/status/200",
        "https://httpbin.org/status/404",
    };

    for (urls) |url| {
        metrics.recordRequest();

        const response = try client.get(url);
        defer response.deinit();

        metrics.recordResponse(&response);

        std.debug.print("Request to {s}: {d} {s}\n", .{
            url,
            response.getStatus(),
            response.getReasonPhrase(),
        });
    }

    // Print collected metrics
    std.debug.print("\n", .{});
    metrics.printStats();

    const success_rate = metrics.getSuccessRate();
    std.debug.print("Success Rate: {d:.2}%\n", .{success_rate});

    std.debug.print("\n", .{});
}

/// Example 3: Custom Interceptor
///
/// Create a custom interceptor to add authentication headers automatically
fn customInterceptorExample(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Example 3: Custom Interceptor ---\n", .{});

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Create a request
    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/headers",
    );
    defer request.deinit();

    // Apply custom interceptor (adds headers)
    try authInterceptor(&request);

    // Apply logging to see what headers were added
    try zig_net.interceptor.loggingRequestInterceptor(&request);

    // Send the request
    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Response Status: {d}\n", .{response.getStatus()});

    if (response.isSuccess()) {
        const body = response.getBody();
        std.debug.print("Response shows our custom headers:\n{s}\n", .{body});
    }

    std.debug.print("\n", .{});
}

/// Custom Request Interceptor: Add Authentication
///
/// This interceptor automatically adds authentication headers to requests
fn authInterceptor(request: *zig_net.Request) !void {
    std.debug.print("[Auth Interceptor] Adding authentication headers\n", .{});

    // Add API key header
    _ = try request.setHeader("X-API-Key", "secret-api-key-12345");

    // Add custom user agent
    _ = try request.setHeader("User-Agent", "MyApp/1.0 (zig_net)");
}

/// Custom Response Interceptor: Validate Content Type
///
/// This interceptor validates that responses have the expected content type
fn contentTypeValidationInterceptor(response: *const zig_net.Response) !void {
    const content_type = response.getContentType();

    if (content_type == null) {
        std.debug.print("[Validation] Warning: No Content-Type header\n", .{});
        return;
    }

    std.debug.print("[Validation] Content-Type: {s}\n", .{content_type.?});

    // Check if it's JSON
    if (std.mem.indexOf(u8, content_type.?, "application/json") != null) {
        std.debug.print("[Validation] ✓ JSON response detected\n", .{});
    }
}

/// Custom Response Interceptor: Error Handler
///
/// This interceptor logs errors with additional context
fn errorHandlerInterceptor(response: *const zig_net.Response) !void {
    if (response.isClientError() or response.isServerError()) {
        std.debug.print("[Error Handler] HTTP Error: {d} {s}\n", .{
            response.getStatus(),
            response.getReasonPhrase(),
        });

        const body = response.getBody();
        if (body.len > 0 and body.len < 500) {
            std.debug.print("[Error Handler] Error Body: {s}\n", .{body});
        }
    }
}

/// Example: Chaining Multiple Interceptors
///
/// Apply multiple interceptors in sequence
fn chainingExample(allocator: std.mem.Allocator) !void {
    _ = allocator; // This is just a code example, not executed

    // Example: Apply multiple request interceptors
    // var request = try zig_net.Request.init(allocator, .GET, "https://api.example.com/data");
    // defer request.deinit();
    //
    // // Chain interceptors
    // try authInterceptor(&request);  // Add auth headers
    // try zig_net.interceptor.loggingRequestInterceptor(&request);  // Log the request
    //
    // var client = try zig_net.Client.init(allocator, .{});
    // defer client.deinit();
    //
    // const response = try client.send(&request);
    // defer response.deinit();
    //
    // // Chain response interceptors
    // try contentTypeValidationInterceptor(&response);  // Validate content type
    // try errorHandlerInterceptor(&response);  // Handle errors
    // try zig_net.interceptor.loggingResponseInterceptor(&response);  // Log response
}

/// Example: Implementing an Interceptor Manager
///
/// For more complex scenarios, you might want to manage multiple interceptors
fn interceptorManagerExample() void {
    // This is a conceptual example showing how you might organize interceptors
    //
    // const InterceptorManager = struct {
    //     request_interceptors: std.ArrayList(zig_net.interceptor.RequestInterceptorFn),
    //     response_interceptors: std.ArrayList(zig_net.interceptor.ResponseInterceptorFn),
    //
    //     pub fn applyRequestInterceptors(self: *InterceptorManager, request: *zig_net.Request) !void {
    //         for (self.request_interceptors.items) |interceptor| {
    //             try interceptor(request);
    //         }
    //     }
    //
    //     pub fn applyResponseInterceptors(self: *InterceptorManager, response: *const zig_net.Response) !void {
    //         for (self.response_interceptors.items) |interceptor| {
    //             try interceptor(response);
    //         }
    //     }
    // };
}
