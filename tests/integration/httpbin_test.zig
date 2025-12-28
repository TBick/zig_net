//! Integration tests using httpbin.org
//!
//! These tests make real HTTP requests to httpbin.org to verify the client works correctly.
//! They test various HTTP methods, headers, redirects, and status codes.
//!
//! Note: These tests require internet connectivity and will fail if httpbin.org is unreachable.

const std = @import("std");
const zig_net = @import("zig_net");

// Note: Integration tests are commented out by default because they require network access.
// Uncomment the tests below to run them manually.

// test "integration: GET request" {
//     const testing = std.testing;
//     const allocator = testing.allocator;
//
//     var client = try zig_net.Client.init(allocator, .{});
//     defer client.deinit();
//
//     const response = try client.get("https://httpbin.org/get");
//     defer response.deinit();
//
//     try testing.expect(response.isSuccess());
//     try testing.expectEqual(@as(u16, 200), response.getStatus());
//
//     const body = response.getBody();
//     try testing.expect(body.len > 0);
// }

// test "integration: POST request" {
//     const testing = std.testing;
//     const allocator = testing.allocator;
//
//     var client = try zig_net.Client.init(allocator, .{});
//     defer client.deinit();
//
//     const test_body = "{\"test\": true}";
//     const response = try client.post(
//         "https://httpbin.org/post",
//         test_body,
//         "application/json",
//     );
//     defer response.deinit();
//
//     try testing.expect(response.isSuccess());
//     try testing.expectEqual(@as(u16, 200), response.getStatus());
//
//     const body = response.getBody();
//     try testing.expect(body.len > 0);
// }

// test "integration: Custom headers" {
//     const testing = std.testing;
//     const allocator = testing.allocator;
//
//     var client = try zig_net.Client.init(allocator, .{});
//     defer client.deinit();
//
//     var request = try zig_net.Request.init(allocator, .GET, "https://httpbin.org/headers");
//     defer request.deinit();
//
//     _ = try request.setHeader("X-Custom-Header", "test-value");
//     _ = try request.setHeader("User-Agent", "zig_net/0.1.0");
//
//     const response = try client.send(&request);
//     defer response.deinit();
//
//     try testing.expect(response.isSuccess());
//
//     const body = response.getBody();
//     try testing.expect(std.mem.indexOf(u8, body, "X-Custom-Header") != null);
//     try testing.expect(std.mem.indexOf(u8, body, "test-value") != null);
// }

// test "integration: 404 Not Found" {
//     const testing = std.testing;
//     const allocator = testing.allocator;
//
//     var client = try zig_net.Client.init(allocator, .{});
//     defer client.deinit();
//
//     const response = try client.get("https://httpbin.org/status/404");
//     defer response.deinit();
//
//     try testing.expect(response.isClientError());
//     try testing.expectEqual(@as(u16, 404), response.getStatus());
//     try testing.expectEqualStrings("Not Found", response.getReasonPhrase());
// }

// test "integration: 500 Server Error" {
//     const testing = std.testing;
//     const allocator = testing.allocator;
//
//     var client = try zig_net.Client.init(allocator, .{});
//     defer client.deinit();
//
//     const response = try client.get("https://httpbin.org/status/500");
//     defer response.deinit();
//
//     try testing.expect(response.isServerError());
//     try testing.expectEqual(@as(u16, 500), response.getStatus());
//     try testing.expectEqualStrings("Internal Server Error", response.getReasonPhrase());
// }

// test "integration: Response headers" {
//     const testing = std.testing;
//     const allocator = testing.allocator;
//
//     var client = try zig_net.Client.init(allocator, .{});
//     defer client.deinit();
//
//     const response = try client.get("https://httpbin.org/get");
//     defer response.deinit();
//
//     const content_type = response.getHeader("Content-Type");
//     try testing.expect(content_type != null);
//
//     // httpbin.org returns JSON by default
//     try testing.expect(std.mem.indexOf(u8, content_type.?, "application/json") != null);
// }

// test "integration: PUT request" {
//     const testing = std.testing;
//     const allocator = testing.allocator;
//
//     var client = try zig_net.Client.init(allocator, .{});
//     defer client.deinit();
//
//     const test_data = "{\"update\": true}";
//     const response = try client.put(
//         "https://httpbin.org/put",
//         test_data,
//         "application/json",
//     );
//     defer response.deinit();
//
//     try testing.expect(response.isSuccess());
//     try testing.expectEqual(@as(u16, 200), response.getStatus());
// }

// test "integration: DELETE request" {
//     const testing = std.testing;
//     const allocator = testing.allocator;
//
//     var client = try zig_net.Client.init(allocator, .{});
//     defer client.deinit();
//
//     const response = try client.delete("https://httpbin.org/delete");
//     defer response.deinit();
//
//     try testing.expect(response.isSuccess());
//     try testing.expectEqual(@as(u16, 200), response.getStatus());
// }

// Placeholder test to ensure the file compiles
test "integration tests placeholder" {
    // Integration tests are commented out by default
    // Uncomment the tests above to run them manually
}
