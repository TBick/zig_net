//! HTTP header management with case-insensitive lookups
//!
//! This module provides utilities for managing HTTP headers with proper
//! case-insensitive handling as required by the HTTP specification (RFC 7230).
//!
//! # Features
//! - Case-insensitive header name lookups
//! - Header validation
//! - Common header constants
//! - Header serialization for requests
//!
//! # Usage
//! ```zig
//! var headers = Headers.init(allocator);
//! defer headers.deinit();
//!
//! try headers.append("Content-Type", "application/json");
//! try headers.append("User-Agent", "zig_net/0.1.0");
//!
//! const content_type = headers.get("content-type"); // Case-insensitive
//! ```

const std = @import("std");
const errors = @import("../errors.zig");

/// HTTP header management structure
///
/// Headers are stored in a StringHashMap for efficient lookup.
/// Header names are normalized to lowercase for case-insensitive comparison.
pub const Headers = @This();

allocator: std.mem.Allocator,
map: std.StringHashMap([]const u8),

/// Common HTTP header names as constants
pub const ContentType = "Content-Type";
pub const ContentLength = "Content-Length";
pub const UserAgent = "User-Agent";
pub const Accept = "Accept";
pub const Authorization = "Authorization";
pub const Host = "Host";
pub const Connection = "Connection";
pub const TransferEncoding = "Transfer-Encoding";
pub const Location = "Location";
pub const AcceptEncoding = "Accept-Encoding";
pub const ContentEncoding = "Content-Encoding";

/// Initializes a new Headers instance
///
/// # Parameters
/// - `allocator`: Memory allocator for header storage
///
/// # Returns
/// Returns a new Headers instance
pub fn init(allocator: std.mem.Allocator) Headers {
    return .{
        .allocator = allocator,
        .map = std.StringHashMap([]const u8).init(allocator),
    };
}

/// Frees all memory associated with this Headers instance
///
/// This will free both the header names and values that were added.
pub fn deinit(self: *Headers) void {
    var it = self.map.iterator();
    while (it.next()) |entry| {
        self.allocator.free(entry.key_ptr.*);
        self.allocator.free(entry.value_ptr.*);
    }
    self.map.deinit();
}

/// Normalizes a header name to lowercase for case-insensitive comparison
///
/// # Parameters
/// - `allocator`: Memory allocator for the normalized name
/// - `name`: Header name to normalize
///
/// # Returns
/// Returns the lowercase version of the header name
fn normalizeName(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const normalized = try allocator.alloc(u8, name.len);
    for (name, 0..) |c, i| {
        normalized[i] = std.ascii.toLower(c);
    }
    return normalized;
}

/// Appends a header to the collection
///
/// If a header with the same name (case-insensitive) already exists,
/// it will be replaced with the new value.
///
/// # Parameters
/// - `self`: The Headers instance
/// - `name`: Header name (will be normalized to lowercase)
/// - `value`: Header value
///
/// # Returns
/// Returns an error if allocation fails or if the header is invalid
///
/// # Example
/// ```zig
/// try headers.append("Content-Type", "application/json");
/// ```
pub fn append(self: *Headers, name: []const u8, value: []const u8) !void {
    if (name.len == 0) return errors.Error.InvalidRequestHeaders;

    const normalized_name = try normalizeName(self.allocator, name);
    errdefer self.allocator.free(normalized_name);

    const value_copy = try self.allocator.dupe(u8, value);
    errdefer self.allocator.free(value_copy);

    // If header already exists, remove and free it first
    if (self.map.fetchRemove(normalized_name)) |old_entry| {
        self.allocator.free(old_entry.key);
        self.allocator.free(old_entry.value);
    }

    try self.map.put(normalized_name, value_copy);
}

/// Retrieves a header value by name (case-insensitive)
///
/// # Parameters
/// - `self`: The Headers instance
/// - `name`: Header name to look up (case-insensitive)
///
/// # Returns
/// Returns the header value if found, or null if not present
///
/// # Example
/// ```zig
/// const content_type = headers.get("content-type");
/// if (content_type) |value| {
///     std.debug.print("Content-Type: {s}\n", .{value});
/// }
/// ```
pub fn get(self: *const Headers, name: []const u8) ?[]const u8 {
    const normalized = normalizeName(self.allocator, name) catch return null;
    defer self.allocator.free(normalized);

    return self.map.get(normalized);
}

/// Checks if a header exists (case-insensitive)
///
/// # Parameters
/// - `self`: The Headers instance
/// - `name`: Header name to check
///
/// # Returns
/// Returns true if the header exists, false otherwise
pub fn contains(self: *const Headers, name: []const u8) bool {
    return self.get(name) != null;
}

/// Removes a header by name (case-insensitive)
///
/// # Parameters
/// - `self`: The Headers instance
/// - `name`: Header name to remove
///
/// # Returns
/// Returns true if a header was removed, false if it didn't exist
pub fn remove(self: *Headers, name: []const u8) bool {
    const normalized = normalizeName(self.allocator, name) catch return false;
    defer self.allocator.free(normalized);

    if (self.map.fetchRemove(normalized)) |entry| {
        self.allocator.free(entry.key);
        self.allocator.free(entry.value);
        return true;
    }
    return false;
}

/// Returns the number of headers in the collection
///
/// # Returns
/// Returns the count of headers
pub fn count(self: *const Headers) usize {
    return self.map.count();
}

/// Iterator for iterating over all headers
///
/// # Example
/// ```zig
/// var it = headers.iterator();
/// while (it.next()) |entry| {
///     std.debug.print("{s}: {s}\n", .{entry.key_ptr.*, entry.value_ptr.*});
/// }
/// ```
pub fn iterator(self: *const Headers) std.StringHashMap([]const u8).Iterator {
    return self.map.iterator();
}

// Tests
test "Headers init and deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var headers = init(allocator);
    defer headers.deinit();

    try testing.expectEqual(@as(usize, 0), headers.count());
}

test "Headers append and get" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var headers = init(allocator);
    defer headers.deinit();

    try headers.append("Content-Type", "application/json");
    try headers.append("User-Agent", "zig_net/0.1.0");

    try testing.expectEqual(@as(usize, 2), headers.count());

    const content_type = headers.get("Content-Type");
    try testing.expect(content_type != null);
    try testing.expectEqualStrings("application/json", content_type.?);

    const user_agent = headers.get("User-Agent");
    try testing.expect(user_agent != null);
    try testing.expectEqualStrings("zig_net/0.1.0", user_agent.?);
}

test "Headers case-insensitive lookup" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var headers = init(allocator);
    defer headers.deinit();

    try headers.append("Content-Type", "text/plain");

    // All of these should find the header
    try testing.expect(headers.get("Content-Type") != null);
    try testing.expect(headers.get("content-type") != null);
    try testing.expect(headers.get("CONTENT-TYPE") != null);
    try testing.expect(headers.get("CoNtEnT-TyPe") != null);

    // All should return the same value
    try testing.expectEqualStrings("text/plain", headers.get("Content-Type").?);
    try testing.expectEqualStrings("text/plain", headers.get("content-type").?);
    try testing.expectEqualStrings("text/plain", headers.get("CONTENT-TYPE").?);
}

test "Headers replace existing" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var headers = init(allocator);
    defer headers.deinit();

    try headers.append("Content-Type", "text/plain");
    try testing.expectEqualStrings("text/plain", headers.get("Content-Type").?);

    // Append again with different value should replace
    try headers.append("Content-Type", "application/json");
    try testing.expectEqualStrings("application/json", headers.get("Content-Type").?);

    // Should still only have one header
    try testing.expectEqual(@as(usize, 1), headers.count());
}

test "Headers contains" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var headers = init(allocator);
    defer headers.deinit();

    try headers.append("Authorization", "Bearer token123");

    try testing.expect(headers.contains("Authorization"));
    try testing.expect(headers.contains("authorization"));
    try testing.expect(!headers.contains("Content-Type"));
}

test "Headers remove" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var headers = init(allocator);
    defer headers.deinit();

    try headers.append("Content-Type", "application/json");
    try headers.append("User-Agent", "zig_net/0.1.0");

    try testing.expectEqual(@as(usize, 2), headers.count());

    const removed = headers.remove("Content-Type");
    try testing.expect(removed);
    try testing.expectEqual(@as(usize, 1), headers.count());
    try testing.expect(!headers.contains("Content-Type"));

    // Removing again should return false
    const removed_again = headers.remove("Content-Type");
    try testing.expect(!removed_again);
}

test "Headers iterator" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var headers = init(allocator);
    defer headers.deinit();

    try headers.append("Content-Type", "application/json");
    try headers.append("User-Agent", "zig_net/0.1.0");

    var count_found: usize = 0;
    var it = headers.iterator();
    while (it.next()) |_| {
        count_found += 1;
    }

    try testing.expectEqual(@as(usize, 2), count_found);
}

test "Headers empty name validation" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var headers = init(allocator);
    defer headers.deinit();

    try testing.expectError(errors.Error.InvalidRequestHeaders, headers.append("", "value"));
}
