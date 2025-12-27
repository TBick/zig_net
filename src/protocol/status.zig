//! HTTP status code utilities
//!
//! This module provides utilities for working with HTTP status codes as defined
//! in RFC 7231 and related specifications.
//!
//! Status codes are grouped into five classes:
//! - 1xx: Informational - Request received, continuing process
//! - 2xx: Success - The action was successfully received, understood, and accepted
//! - 3xx: Redirection - Further action must be taken to complete the request
//! - 4xx: Client Error - The request contains bad syntax or cannot be fulfilled
//! - 5xx: Server Error - The server failed to fulfill a valid request
//!
//! # Usage
//! ```zig
//! const status = @import("protocol/status.zig");
//!
//! const code: u16 = 200;
//! if (status.isSuccess(code)) {
//!     // Handle successful response
//! }
//!
//! const msg = status.getReasonPhrase(404); // "Not Found"
//! ```

const std = @import("std");

/// HTTP status code type
pub const StatusCode = u16;

// Common status codes as constants

// 1xx Informational
pub const CONTINUE: StatusCode = 100;
pub const SWITCHING_PROTOCOLS: StatusCode = 101;
pub const PROCESSING: StatusCode = 102;
pub const EARLY_HINTS: StatusCode = 103;

// 2xx Success
pub const OK: StatusCode = 200;
pub const CREATED: StatusCode = 201;
pub const ACCEPTED: StatusCode = 202;
pub const NON_AUTHORITATIVE_INFORMATION: StatusCode = 203;
pub const NO_CONTENT: StatusCode = 204;
pub const RESET_CONTENT: StatusCode = 205;
pub const PARTIAL_CONTENT: StatusCode = 206;
pub const MULTI_STATUS: StatusCode = 207;
pub const ALREADY_REPORTED: StatusCode = 208;
pub const IM_USED: StatusCode = 226;

// 3xx Redirection
pub const MULTIPLE_CHOICES: StatusCode = 300;
pub const MOVED_PERMANENTLY: StatusCode = 301;
pub const FOUND: StatusCode = 302;
pub const SEE_OTHER: StatusCode = 303;
pub const NOT_MODIFIED: StatusCode = 304;
pub const USE_PROXY: StatusCode = 305;
pub const TEMPORARY_REDIRECT: StatusCode = 307;
pub const PERMANENT_REDIRECT: StatusCode = 308;

// 4xx Client Error
pub const BAD_REQUEST: StatusCode = 400;
pub const UNAUTHORIZED: StatusCode = 401;
pub const PAYMENT_REQUIRED: StatusCode = 402;
pub const FORBIDDEN: StatusCode = 403;
pub const NOT_FOUND: StatusCode = 404;
pub const METHOD_NOT_ALLOWED: StatusCode = 405;
pub const NOT_ACCEPTABLE: StatusCode = 406;
pub const PROXY_AUTHENTICATION_REQUIRED: StatusCode = 407;
pub const REQUEST_TIMEOUT: StatusCode = 408;
pub const CONFLICT: StatusCode = 409;
pub const GONE: StatusCode = 410;
pub const LENGTH_REQUIRED: StatusCode = 411;
pub const PRECONDITION_FAILED: StatusCode = 412;
pub const PAYLOAD_TOO_LARGE: StatusCode = 413;
pub const URI_TOO_LONG: StatusCode = 414;
pub const UNSUPPORTED_MEDIA_TYPE: StatusCode = 415;
pub const RANGE_NOT_SATISFIABLE: StatusCode = 416;
pub const EXPECTATION_FAILED: StatusCode = 417;
pub const IM_A_TEAPOT: StatusCode = 418;
pub const MISDIRECTED_REQUEST: StatusCode = 421;
pub const UNPROCESSABLE_ENTITY: StatusCode = 422;
pub const LOCKED: StatusCode = 423;
pub const FAILED_DEPENDENCY: StatusCode = 424;
pub const TOO_EARLY: StatusCode = 425;
pub const UPGRADE_REQUIRED: StatusCode = 426;
pub const PRECONDITION_REQUIRED: StatusCode = 428;
pub const TOO_MANY_REQUESTS: StatusCode = 429;
pub const REQUEST_HEADER_FIELDS_TOO_LARGE: StatusCode = 431;
pub const UNAVAILABLE_FOR_LEGAL_REASONS: StatusCode = 451;

// 5xx Server Error
pub const INTERNAL_SERVER_ERROR: StatusCode = 500;
pub const NOT_IMPLEMENTED: StatusCode = 501;
pub const BAD_GATEWAY: StatusCode = 502;
pub const SERVICE_UNAVAILABLE: StatusCode = 503;
pub const GATEWAY_TIMEOUT: StatusCode = 504;
pub const HTTP_VERSION_NOT_SUPPORTED: StatusCode = 505;
pub const VARIANT_ALSO_NEGOTIATES: StatusCode = 506;
pub const INSUFFICIENT_STORAGE: StatusCode = 507;
pub const LOOP_DETECTED: StatusCode = 508;
pub const NOT_EXTENDED: StatusCode = 510;
pub const NETWORK_AUTHENTICATION_REQUIRED: StatusCode = 511;

/// Check if status code is in the informational range (100-199)
///
/// Informational responses indicate that the request was received and understood,
/// and the client should wait for a final response.
///
/// # Parameters
/// - `code`: The HTTP status code to check
///
/// # Returns
/// Returns true if the status code is 1xx (informational)
///
/// # Example
/// ```zig
/// if (isInformational(100)) {
///     // Handle 100 Continue
/// }
/// ```
pub fn isInformational(code: StatusCode) bool {
    return code >= 100 and code < 200;
}

/// Check if status code indicates success (200-299)
///
/// Success status codes indicate that the client's request was successfully
/// received, understood, and accepted.
///
/// # Parameters
/// - `code`: The HTTP status code to check
///
/// # Returns
/// Returns true if the status code is 2xx (success)
///
/// # Example
/// ```zig
/// if (isSuccess(response.status)) {
///     // Request completed successfully
/// }
/// ```
pub fn isSuccess(code: StatusCode) bool {
    return code >= 200 and code < 300;
}

/// Check if status code indicates redirection (300-399)
///
/// Redirection status codes indicate that further action needs to be taken
/// by the client to complete the request.
///
/// # Parameters
/// - `code`: The HTTP status code to check
///
/// # Returns
/// Returns true if the status code is 3xx (redirection)
///
/// # Example
/// ```zig
/// if (isRedirection(response.status)) {
///     const location = response.getHeader("Location");
///     // Follow redirect to location
/// }
/// ```
pub fn isRedirection(code: StatusCode) bool {
    return code >= 300 and code < 400;
}

/// Check if status code indicates client error (400-499)
///
/// Client error status codes indicate that the client seems to have made an error.
/// The server should respond with an explanation of the error situation.
///
/// # Parameters
/// - `code`: The HTTP status code to check
///
/// # Returns
/// Returns true if the status code is 4xx (client error)
///
/// # Example
/// ```zig
/// if (isClientError(response.status)) {
///     // Handle client-side error (bad request, auth, not found, etc.)
/// }
/// ```
pub fn isClientError(code: StatusCode) bool {
    return code >= 400 and code < 500;
}

/// Check if status code indicates server error (500-599)
///
/// Server error status codes indicate that the server is aware that it has
/// encountered an error or is otherwise incapable of performing the request.
///
/// # Parameters
/// - `code`: The HTTP status code to check
///
/// # Returns
/// Returns true if the status code is 5xx (server error)
///
/// # Example
/// ```zig
/// if (isServerError(response.status)) {
///     // Server error - may be retryable
/// }
/// ```
pub fn isServerError(code: StatusCode) bool {
    return code >= 500 and code < 600;
}

/// Check if status code represents an error (4xx or 5xx)
///
/// # Parameters
/// - `code`: The HTTP status code to check
///
/// # Returns
/// Returns true if the status code is 4xx or 5xx
pub fn isError(code: StatusCode) bool {
    return isClientError(code) or isServerError(code);
}

/// Get the standard reason phrase for a status code
///
/// Returns the standard HTTP reason phrase (e.g., "OK" for 200, "Not Found" for 404).
/// For unknown status codes, returns "Unknown Status Code".
///
/// # Parameters
/// - `code`: The HTTP status code
///
/// # Returns
/// Returns a static string containing the reason phrase
///
/// # Example
/// ```zig
/// const reason = getReasonPhrase(404);
/// // reason == "Not Found"
/// ```
pub fn getReasonPhrase(code: StatusCode) []const u8 {
    return switch (code) {
        // 1xx Informational
        100 => "Continue",
        101 => "Switching Protocols",
        102 => "Processing",
        103 => "Early Hints",

        // 2xx Success
        200 => "OK",
        201 => "Created",
        202 => "Accepted",
        203 => "Non-Authoritative Information",
        204 => "No Content",
        205 => "Reset Content",
        206 => "Partial Content",
        207 => "Multi-Status",
        208 => "Already Reported",
        226 => "IM Used",

        // 3xx Redirection
        300 => "Multiple Choices",
        301 => "Moved Permanently",
        302 => "Found",
        303 => "See Other",
        304 => "Not Modified",
        305 => "Use Proxy",
        307 => "Temporary Redirect",
        308 => "Permanent Redirect",

        // 4xx Client Error
        400 => "Bad Request",
        401 => "Unauthorized",
        402 => "Payment Required",
        403 => "Forbidden",
        404 => "Not Found",
        405 => "Method Not Allowed",
        406 => "Not Acceptable",
        407 => "Proxy Authentication Required",
        408 => "Request Timeout",
        409 => "Conflict",
        410 => "Gone",
        411 => "Length Required",
        412 => "Precondition Failed",
        413 => "Payload Too Large",
        414 => "URI Too Long",
        415 => "Unsupported Media Type",
        416 => "Range Not Satisfiable",
        417 => "Expectation Failed",
        418 => "I'm a teapot",
        421 => "Misdirected Request",
        422 => "Unprocessable Entity",
        423 => "Locked",
        424 => "Failed Dependency",
        425 => "Too Early",
        426 => "Upgrade Required",
        428 => "Precondition Required",
        429 => "Too Many Requests",
        431 => "Request Header Fields Too Large",
        451 => "Unavailable For Legal Reasons",

        // 5xx Server Error
        500 => "Internal Server Error",
        501 => "Not Implemented",
        502 => "Bad Gateway",
        503 => "Service Unavailable",
        504 => "Gateway Timeout",
        505 => "HTTP Version Not Supported",
        506 => "Variant Also Negotiates",
        507 => "Insufficient Storage",
        508 => "Loop Detected",
        510 => "Not Extended",
        511 => "Network Authentication Required",

        else => "Unknown Status Code",
    };
}

// Tests

test "status code classification" {
    const testing = std.testing;

    // Informational
    try testing.expect(isInformational(100));
    try testing.expect(isInformational(101));
    try testing.expect(!isInformational(200));

    // Success
    try testing.expect(isSuccess(200));
    try testing.expect(isSuccess(201));
    try testing.expect(isSuccess(299));
    try testing.expect(!isSuccess(300));

    // Redirection
    try testing.expect(isRedirection(301));
    try testing.expect(isRedirection(302));
    try testing.expect(isRedirection(308));
    try testing.expect(!isRedirection(200));

    // Client error
    try testing.expect(isClientError(400));
    try testing.expect(isClientError(404));
    try testing.expect(isClientError(499));
    try testing.expect(!isClientError(500));

    // Server error
    try testing.expect(isServerError(500));
    try testing.expect(isServerError(503));
    try testing.expect(isServerError(599));
    try testing.expect(!isServerError(400));

    // Error (4xx or 5xx)
    try testing.expect(isError(400));
    try testing.expect(isError(500));
    try testing.expect(!isError(200));
    try testing.expect(!isError(300));
}

test "getReasonPhrase" {
    const testing = std.testing;

    try testing.expectEqualStrings("OK", getReasonPhrase(200));
    try testing.expectEqualStrings("Created", getReasonPhrase(201));
    try testing.expectEqualStrings("Moved Permanently", getReasonPhrase(301));
    try testing.expectEqualStrings("Not Found", getReasonPhrase(404));
    try testing.expectEqualStrings("Internal Server Error", getReasonPhrase(500));
    try testing.expectEqualStrings("Unknown Status Code", getReasonPhrase(999));
}

test "status code constants" {
    const testing = std.testing;

    try testing.expectEqual(@as(StatusCode, 200), OK);
    try testing.expectEqual(@as(StatusCode, 404), NOT_FOUND);
    try testing.expectEqual(@as(StatusCode, 500), INTERNAL_SERVER_ERROR);
}
