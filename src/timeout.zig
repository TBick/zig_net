//! Timeout utilities for HTTP operations
//!
//! This module provides utilities for handling request timeouts, including
//! deadline calculation and timeout error mapping.
//!
//! # Note on Implementation
//! Zig's std.http.Client currently has limited timeout support. The timeout_ms
//! configuration in ClientOptions is documented for future use and to guide
//! users on the intended behavior.
//!
//! For production use, consider implementing timeouts at a higher level using
//! async/await patterns or by wrapping requests in timeout logic.

const std = @import("std");

/// Calculates a deadline timestamp from a timeout duration
///
/// # Parameters
/// - `timeout_ms`: Timeout duration in milliseconds (0 = no timeout)
///
/// # Returns
/// Returns the deadline timestamp in nanoseconds since epoch, or null if no timeout
///
/// # Example
/// ```zig
/// const deadline = calculateDeadline(5000); // 5 second timeout
/// ```
pub fn calculateDeadline(timeout_ms: u64) ?u64 {
    if (timeout_ms == 0) return null;

    const now_ns = std.time.nanoTimestamp();
    const timeout_ns = timeout_ms * std.time.ns_per_ms;
    return @as(u64, @intCast(now_ns)) + timeout_ns;
}

/// Checks if a deadline has been exceeded
///
/// # Parameters
/// - `deadline_ns`: Deadline timestamp in nanoseconds (null = no deadline)
///
/// # Returns
/// Returns true if the deadline has passed, false otherwise
pub fn isDeadlineExceeded(deadline_ns: ?u64) bool {
    const deadline = deadline_ns orelse return false;
    const now_ns = std.time.nanoTimestamp();
    return @as(u64, @intCast(now_ns)) >= deadline;
}

/// Calculates remaining time until deadline
///
/// # Parameters
/// - `deadline_ns`: Deadline timestamp in nanoseconds (null = no deadline)
///
/// # Returns
/// Returns remaining milliseconds, or null if no deadline or deadline exceeded
pub fn remainingMs(deadline_ns: ?u64) ?u64 {
    const deadline = deadline_ns orelse return null;
    const now_ns = @as(u64, @intCast(std.time.nanoTimestamp()));

    if (now_ns >= deadline) return null;

    const remaining_ns = deadline - now_ns;
    return remaining_ns / std.time.ns_per_ms;
}

// Tests
test "calculateDeadline with zero timeout" {
    const testing = std.testing;

    const deadline = calculateDeadline(0);
    try testing.expect(deadline == null);
}

test "calculateDeadline with timeout" {
    const testing = std.testing;

    const deadline = calculateDeadline(5000);
    try testing.expect(deadline != null);
    try testing.expect(deadline.? > 0);
}

test "isDeadlineExceeded with null deadline" {
    const testing = std.testing;

    try testing.expect(!isDeadlineExceeded(null));
}

test "isDeadlineExceeded with far future deadline" {
    const testing = std.testing;

    // Deadline far in the future (1 hour from now)
    const now = @as(u64, @intCast(std.time.nanoTimestamp()));
    const future_deadline = now + (3600 * std.time.ns_per_s);

    try testing.expect(!isDeadlineExceeded(future_deadline));
}

test "isDeadlineExceeded with past deadline" {
    const testing = std.testing;

    // Deadline in the past
    const past_deadline: u64 = 1000;

    try testing.expect(isDeadlineExceeded(past_deadline));
}

test "remainingMs with null deadline" {
    const testing = std.testing;

    const remaining = remainingMs(null);
    try testing.expect(remaining == null);
}

test "remainingMs with future deadline" {
    const testing = std.testing;

    const now = @as(u64, @intCast(std.time.nanoTimestamp()));
    const future_deadline = now + (5 * std.time.ns_per_s); // 5 seconds from now

    const remaining = remainingMs(future_deadline);
    try testing.expect(remaining != null);
    // Should be approximately 5000ms (allow some margin)
    try testing.expect(remaining.? > 4900 and remaining.? <= 5000);
}

test "remainingMs with past deadline" {
    const testing = std.testing;

    const past_deadline: u64 = 1000;
    const remaining = remainingMs(past_deadline);
    try testing.expect(remaining == null);
}
