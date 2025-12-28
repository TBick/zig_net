//! zig_net - HTTP/HTTPS Client Library for Zig
//!
//! This is the public API entry point for the zig_net library.
//! It provides a convenient HTTP/HTTPS client with support for:
//! - All HTTP methods (GET, POST, PUT, DELETE, etc.)
//! - HTTPS/TLS connections
//! - Custom headers
//! - Request body support
//! - Response parsing
//!
//! # Quick Start
//!
//! ```zig
//! const zig_net = @import("zig_net");
//!
//! var client = try zig_net.Client.init(allocator, .{});
//! defer client.deinit();
//!
//! const response = try client.get("https://httpbin.org/get");
//! defer response.deinit();
//!
//! if (response.isSuccess()) {
//!     std.debug.print("Body: {s}\n", .{response.getBody()});
//! }
//! ```

const std = @import("std");

// Re-export core types
pub const Client = @import("client/Client.zig");
pub const Request = @import("client/Request.zig");
pub const Response = @import("client/Response.zig");
pub const Headers = @import("client/Headers.zig");

// Re-export protocol types
pub const Method = @import("protocol/method.zig").Method;
pub const status = @import("protocol/status.zig");
pub const StatusCode = status.StatusCode;

// Re-export error types
pub const errors = @import("errors.zig");
pub const Error = errors.Error;
pub const ErrorSet = errors.ErrorSet;

// Run all tests
test {
    std.testing.refAllDecls(@This());
    _ = @import("errors.zig");
    _ = @import("protocol/method.zig");
    _ = @import("protocol/status.zig");
    _ = @import("client/Headers.zig");
    _ = @import("client/Request.zig");
    _ = @import("client/Response.zig");
    _ = @import("client/Client.zig");
}
