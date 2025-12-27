//! Custom error types for zig_net HTTP/HTTPS client library
//!
//! This module defines all error types that can occur during HTTP client operations.
//! Error types are organized by category for better error handling and debugging.
//!
//! # Error Categories
//! - Connection errors: Network connectivity issues
//! - Protocol errors: HTTP protocol violations or unexpected responses
//! - Resource errors: Memory and buffer management issues
//! - Request errors: Invalid request parameters or configuration
//! - Redirect errors: Issues with HTTP redirect handling
//! - Timeout errors: Operation timeout failures
//!
//! # Usage
//! ```zig
//! const errors = @import("errors.zig");
//!
//! fn makeRequest() errors.ErrorSet!Response {
//!     // Function that may return any zig_net error
//! }
//! ```

const std = @import("std");

/// Custom error types for HTTP client operations
///
/// These errors provide specific context for failures that occur during
/// HTTP/HTTPS client operations. They are designed to be wrapped around
/// standard library errors to provide better error messages and handling.
pub const Error = error{
    // Connection errors

    /// Failed to establish TCP connection to the server
    /// This can occur due to network issues, incorrect host/port, or firewall blocking
    ConnectionFailed,

    /// Connection attempt timed out
    /// The server did not respond within the configured timeout period
    ConnectionTimeout,

    /// TLS handshake failed during HTTPS connection
    /// This can occur due to certificate validation failure, protocol mismatch,
    /// or cipher suite incompatibility
    TlsHandshakeFailed,

    /// TLS certificate validation failed
    /// The server's certificate is invalid, expired, or not trusted
    CertificateValidationFailed,

    // Protocol errors

    /// HTTP version in response is not supported
    /// Currently only HTTP/1.1 is fully supported
    InvalidHttpVersion,

    /// HTTP status code in response is malformed or unrecognized
    InvalidStatusCode,

    /// HTTP response is malformed and cannot be parsed
    /// This indicates the server sent a response that violates the HTTP specification
    MalformedResponse,

    /// Response uses an unsupported transfer or content encoding
    /// This can occur with unsupported compression algorithms
    UnsupportedEncoding,

    /// Response headers are malformed or invalid
    InvalidHeaders,

    /// Chunked transfer encoding is malformed
    InvalidChunkedEncoding,

    // Resource errors

    /// Memory allocation failed
    /// This typically indicates the system is out of memory
    OutOfMemory,

    /// Buffer is too small to hold the data
    /// Increase buffer size or use streaming APIs
    BufferTooSmall,

    // Request errors

    /// URI is malformed or uses an unsupported scheme
    /// Only http:// and https:// schemes are supported
    InvalidUri,

    /// HTTP method is invalid or not supported
    InvalidMethod,

    /// Request headers contain invalid values
    InvalidRequestHeaders,

    /// Request body is invalid or malformed
    InvalidRequestBody,

    // Redirect errors

    /// Too many redirects followed (exceeded configured limit)
    /// Default limit is 5 redirects
    TooManyRedirects,

    /// Redirect loop detected
    /// The server is redirecting in a circular pattern
    RedirectLoopDetected,

    /// Redirect location header is missing or invalid
    InvalidRedirectLocation,

    // Timeout errors

    /// Read operation timed out
    /// The server did not send data within the configured timeout
    ReadTimeout,

    /// Write operation timed out
    /// The server did not accept data within the configured timeout
    WriteTimeout,

    /// Overall request timed out
    /// The entire request/response cycle exceeded the configured timeout
    RequestTimeout,
};

/// Combined error set for HTTP client operations
///
/// This error set includes all custom errors plus common standard library errors
/// that can occur during HTTP operations. Use this as the error return type for
/// public API functions.
///
/// # Example
/// ```zig
/// pub fn get(allocator: std.mem.Allocator, uri: []const u8) ErrorSet!Response {
///     // Implementation
/// }
/// ```
pub const ErrorSet = Error || std.mem.Allocator.Error || std.fs.File.OpenError || std.fs.File.ReadError;

/// Maps standard library network errors to custom zig_net errors
///
/// This function provides better error messages by mapping generic std library
/// errors to more specific zig_net errors with clearer context.
///
/// # Parameters
/// - `err`: The standard library error to map
///
/// # Returns
/// Returns a zig_net Error with more specific context, or the original error
/// if no mapping is available.
pub fn mapStdError(err: anyerror) anyerror {
    return switch (err) {
        error.ConnectionRefused => Error.ConnectionFailed,
        error.NetworkUnreachable => Error.ConnectionFailed,
        error.ConnectionResetByPeer => Error.ConnectionFailed,
        error.BrokenPipe => Error.ConnectionFailed,
        error.Timeout => Error.ConnectionTimeout,
        error.OutOfMemory => Error.OutOfMemory,
        else => err,
    };
}

/// Returns a human-readable error message for the given error
///
/// This function provides detailed error messages that can be shown to users
/// or logged for debugging purposes.
///
/// # Parameters
/// - `err`: The error to get a message for
///
/// # Returns
/// Returns a static string describing the error
///
/// # Example
/// ```zig
/// const err = Error.ConnectionFailed;
/// std.debug.print("Error: {s}\n", .{errors.getErrorMessage(err)});
/// ```
pub fn getErrorMessage(err: anyerror) []const u8 {
    return switch (err) {
        Error.ConnectionFailed => "Failed to establish connection to server",
        Error.ConnectionTimeout => "Connection attempt timed out",
        Error.TlsHandshakeFailed => "TLS handshake failed - check certificate and protocol version",
        Error.CertificateValidationFailed => "Server certificate validation failed",
        Error.InvalidHttpVersion => "Unsupported HTTP version (only HTTP/1.1 supported)",
        Error.InvalidStatusCode => "HTTP response contains invalid status code",
        Error.MalformedResponse => "HTTP response is malformed and cannot be parsed",
        Error.UnsupportedEncoding => "Response uses unsupported encoding",
        Error.InvalidHeaders => "Response headers are malformed",
        Error.InvalidChunkedEncoding => "Chunked transfer encoding is malformed",
        Error.OutOfMemory => "Memory allocation failed - out of memory",
        Error.BufferTooSmall => "Buffer too small to hold data",
        Error.InvalidUri => "URI is malformed or uses unsupported scheme (use http:// or https://)",
        Error.InvalidMethod => "HTTP method is invalid",
        Error.InvalidRequestHeaders => "Request headers contain invalid values",
        Error.InvalidRequestBody => "Request body is invalid",
        Error.TooManyRedirects => "Too many redirects (exceeded configured limit)",
        Error.RedirectLoopDetected => "Redirect loop detected",
        Error.InvalidRedirectLocation => "Redirect location is missing or invalid",
        Error.ReadTimeout => "Read operation timed out",
        Error.WriteTimeout => "Write operation timed out",
        Error.RequestTimeout => "Request timed out",
        else => "Unknown error",
    };
}

test "error message retrieval" {
    const testing = std.testing;

    const msg = getErrorMessage(Error.ConnectionFailed);
    try testing.expect(msg.len > 0);
    try testing.expectEqualStrings("Failed to establish connection to server", msg);
}

test "mapStdError maps connection errors" {
    const testing = std.testing;

    const mapped = mapStdError(error.ConnectionRefused);
    try testing.expectEqual(Error.ConnectionFailed, mapped);
}
