//! Metrics Interceptor Example
//!
//! This module provides an example interceptor for collecting HTTP metrics
//! such as request timing, response sizes, and status codes.
//!
//! # Usage
//! ```zig
//! var metrics = MetricsCollector.init(allocator);
//! defer metrics.deinit();
//!
//! // Use with requests/responses
//! try metrics.recordResponse(&response);
//!
//! // Print statistics
//! metrics.printStats();
//! ```

const std = @import("std");
const Response = @import("../client/Response.zig");

/// HTTP Metrics Collector
///
/// Collects statistics about HTTP requests and responses.
pub const MetricsCollector = struct {
    allocator: std.mem.Allocator,
    total_requests: usize,
    total_responses: usize,
    success_count: usize,
    error_count: usize,
    total_bytes_received: usize,

    /// Initialize a new metrics collector
    pub fn init(allocator: std.mem.Allocator) MetricsCollector {
        return .{
            .allocator = allocator,
            .total_requests = 0,
            .total_responses = 0,
            .success_count = 0,
            .error_count = 0,
            .total_bytes_received = 0,
        };
    }

    /// Free resources (currently nothing to free, but included for consistency)
    pub fn deinit(self: *MetricsCollector) void {
        _ = self;
    }

    /// Record a request
    pub fn recordRequest(self: *MetricsCollector) void {
        self.total_requests += 1;
    }

    /// Record a response
    pub fn recordResponse(self: *MetricsCollector, response: *const Response) void {
        self.total_responses += 1;

        if (response.isSuccess()) {
            self.success_count += 1;
        } else {
            self.error_count += 1;
        }

        self.total_bytes_received += response.getBody().len;
    }

    /// Print collected statistics
    pub fn printStats(self: *const MetricsCollector) void {
        std.debug.print("=== HTTP Metrics ===\n", .{});
        std.debug.print("Total Requests:  {d}\n", .{self.total_requests});
        std.debug.print("Total Responses: {d}\n", .{self.total_responses});
        std.debug.print("Success Count:   {d}\n", .{self.success_count});
        std.debug.print("Error Count:     {d}\n", .{self.error_count});
        std.debug.print("Bytes Received:  {d}\n", .{self.total_bytes_received});
        std.debug.print("==================\n", .{});
    }

    /// Get success rate as a percentage (0-100)
    pub fn getSuccessRate(self: *const MetricsCollector) f64 {
        if (self.total_responses == 0) return 0.0;
        return (@as(f64, @floatFromInt(self.success_count)) / @as(f64, @floatFromInt(self.total_responses))) * 100.0;
    }
};

// Tests
test "MetricsCollector basic" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var metrics = MetricsCollector.init(allocator);
    defer metrics.deinit();

    try testing.expectEqual(@as(usize, 0), metrics.total_requests);
    try testing.expectEqual(@as(usize, 0), metrics.total_responses);

    metrics.recordRequest();
    try testing.expectEqual(@as(usize, 1), metrics.total_requests);
}

test "MetricsCollector recordResponse" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var metrics = MetricsCollector.init(allocator);
    defer metrics.deinit();

    const Headers = @import("../client/Headers.zig");
    var headers = Headers.init(allocator);
    defer headers.deinit();

    const body = try allocator.dupe(u8, "test response");
    var response = Response.init(allocator, 200, headers, body);
    defer response.deinit();

    metrics.recordResponse(&response);

    try testing.expectEqual(@as(usize, 1), metrics.total_responses);
    try testing.expectEqual(@as(usize, 1), metrics.success_count);
    try testing.expectEqual(@as(usize, 0), metrics.error_count);
    try testing.expectEqual(@as(usize, 13), metrics.total_bytes_received);
}

test "MetricsCollector getSuccessRate" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var metrics = MetricsCollector.init(allocator);
    defer metrics.deinit();

    const Headers = @import("../client/Headers.zig");

    // Add 3 successful responses
    for (0..3) |_| {
        var headers = Headers.init(allocator);
        defer headers.deinit();
        const body = try allocator.dupe(u8, "ok");
        var response = Response.init(allocator, 200, headers, body);
        defer response.deinit();
        metrics.recordResponse(&response);
    }

    // Add 1 error response
    {
        var headers = Headers.init(allocator);
        defer headers.deinit();
        const body = try allocator.dupe(u8, "error");
        var response = Response.init(allocator, 500, headers, body);
        defer response.deinit();
        metrics.recordResponse(&response);
    }

    const success_rate = metrics.getSuccessRate();
    try testing.expectApproxEqAbs(@as(f64, 75.0), success_rate, 0.01);
}
