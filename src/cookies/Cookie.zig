//! HTTP Cookie
//!
//! This module implements HTTP cookie parsing and handling as defined in RFC 6265.
//! Cookies are used for session management, user tracking, and storing user preferences.
//!
//! # RFC 6265 Compliance
//! - Cookie parsing from Set-Cookie headers
//! - Cookie attributes: Domain, Path, Expires, Max-Age, Secure, HttpOnly, SameSite
//! - Expiration handling
//! - Domain and path matching (for cookie jar)
//!
//! # Usage
//! ```zig
//! const Cookie = @import("cookies/Cookie.zig");
//!
//! // Parse from Set-Cookie header
//! const cookie = try Cookie.parse(allocator, "session=abc123; Path=/; HttpOnly");
//! defer cookie.deinit(allocator);
//! ```

const std = @import("std");

/// SameSite attribute values
pub const SameSite = enum {
    strict,
    lax,
    none,

    pub fn fromString(s: []const u8) ?SameSite {
        if (std.ascii.eqlIgnoreCase(s, "strict")) return .strict;
        if (std.ascii.eqlIgnoreCase(s, "lax")) return .lax;
        if (std.ascii.eqlIgnoreCase(s, "none")) return .none;
        return null;
    }

    pub fn toString(self: SameSite) []const u8 {
        return switch (self) {
            .strict => "Strict",
            .lax => "Lax",
            .none => "None",
        };
    }
};

/// HTTP Cookie
///
/// Represents an HTTP cookie with all its attributes.
/// Memory for string fields is owned by the cookie and must be freed with deinit().
pub const Cookie = @This();

name: []u8,
value: []u8,
domain: ?[]u8,
path: ?[]u8,
expires: ?i64, // Unix timestamp
max_age: ?i64, // Seconds
secure: bool,
http_only: bool,
same_site: ?SameSite,

/// Parses a cookie from a Set-Cookie header value
///
/// # Parameters
/// - `allocator`: Memory allocator for cookie data
/// - `set_cookie_value`: The value from the Set-Cookie header
///
/// # Returns
/// Returns a Cookie instance. Caller must call deinit() to free memory.
///
/// # Errors
/// Returns an error if the cookie is malformed or allocation fails
///
/// # Example
/// ```zig
/// const cookie = try Cookie.parse(allocator, "id=abc; Domain=.example.com; Path=/; Secure");
/// defer cookie.deinit(allocator);
/// ```
pub fn parse(allocator: std.mem.Allocator, set_cookie_value: []const u8) !Cookie {
    var cookie = Cookie{
        .name = &[_]u8{},
        .value = &[_]u8{},
        .domain = null,
        .path = null,
        .expires = null,
        .max_age = null,
        .secure = false,
        .http_only = false,
        .same_site = null,
    };

    // Split by semicolons
    var parts = std.mem.splitScalar(u8, set_cookie_value, ';');

    // First part is name=value
    if (parts.next()) |first_part| {
        const trimmed = std.mem.trim(u8, first_part, &std.ascii.whitespace);
        if (std.mem.indexOfScalar(u8, trimmed, '=')) |eq_pos| {
            cookie.name = try allocator.dupe(u8, trimmed[0..eq_pos]);
            cookie.value = try allocator.dupe(u8, trimmed[eq_pos + 1 ..]);
        } else {
            // Cookie without value
            cookie.name = try allocator.dupe(u8, trimmed);
            cookie.value = try allocator.dupe(u8, "");
        }
    } else {
        return error.InvalidCookie;
    }

    // Parse attributes
    while (parts.next()) |part| {
        const trimmed = std.mem.trim(u8, part, &std.ascii.whitespace);

        if (trimmed.len == 0) continue;

        if (std.mem.indexOfScalar(u8, trimmed, '=')) |eq_pos| {
            const attr_name = trimmed[0..eq_pos];
            const attr_value = trimmed[eq_pos + 1 ..];

            if (std.ascii.eqlIgnoreCase(attr_name, "Domain")) {
                cookie.domain = try allocator.dupe(u8, attr_value);
            } else if (std.ascii.eqlIgnoreCase(attr_name, "Path")) {
                cookie.path = try allocator.dupe(u8, attr_value);
            } else if (std.ascii.eqlIgnoreCase(attr_name, "Max-Age")) {
                cookie.max_age = std.fmt.parseInt(i64, attr_value, 10) catch null;
            } else if (std.ascii.eqlIgnoreCase(attr_name, "SameSite")) {
                cookie.same_site = SameSite.fromString(attr_value);
            } else if (std.ascii.eqlIgnoreCase(attr_name, "Expires")) {
                // For simplicity, we'll not parse the Expires date
                // In production, you'd parse the HTTP date format and convert to timestamp
                // For now, rely on Max-Age for expiration
            }
        } else {
            // Flag attributes
            if (std.ascii.eqlIgnoreCase(trimmed, "Secure")) {
                cookie.secure = true;
            } else if (std.ascii.eqlIgnoreCase(trimmed, "HttpOnly")) {
                cookie.http_only = true;
            }
        }
    }

    return cookie;
}

/// Frees all memory associated with this cookie
pub fn deinit(self: *Cookie, allocator: std.mem.Allocator) void {
    allocator.free(self.name);
    allocator.free(self.value);
    if (self.domain) |d| allocator.free(d);
    if (self.path) |p| allocator.free(p);
}

/// Converts the cookie to a string for the Cookie header
///
/// Returns just "name=value" for sending to server.
/// Does NOT include attributes (those are only for Set-Cookie).
///
/// # Parameters
/// - `self`: The Cookie instance
/// - `allocator`: Memory allocator
///
/// # Returns
/// Returns the cookie string. Caller must free.
pub fn toString(self: *const Cookie, allocator: std.mem.Allocator) ![]u8 {
    return try std.fmt.allocPrint(allocator, "{s}={s}", .{ self.name, self.value });
}

/// Checks if this cookie is expired
///
/// # Parameters
/// - `self`: The Cookie instance
///
/// # Returns
/// Returns true if the cookie is expired, false otherwise
pub fn isExpired(self: *const Cookie) bool {
    // If max_age is set and <= 0, it's expired
    if (self.max_age) |max_age| {
        return max_age <= 0;
    }

    // If expires is set, check against current time
    if (self.expires) |expires| {
        const now = std.time.timestamp();
        return now > expires;
    }

    // No expiration set - session cookie, not expired
    return false;
}

/// Checks if this cookie matches the given domain
///
/// Implements RFC 6265 domain matching rules.
///
/// # Parameters
/// - `self`: The Cookie instance
/// - `request_domain`: The domain from the request URL
///
/// # Returns
/// Returns true if the cookie matches the domain
pub fn matchesDomain(self: *const Cookie, request_domain: []const u8) bool {
    const cookie_domain = self.domain orelse return true;

    // Exact match
    if (std.mem.eql(u8, cookie_domain, request_domain)) {
        return true;
    }

    // Domain with leading dot matches subdomains
    if (cookie_domain.len > 0 and cookie_domain[0] == '.') {
        return std.mem.endsWith(u8, request_domain, cookie_domain) or
            std.mem.endsWith(u8, request_domain, cookie_domain[1..]);
    }

    return false;
}

/// Checks if this cookie matches the given path
///
/// Implements RFC 6265 path matching rules.
///
/// # Parameters
/// - `self`: The Cookie instance
/// - `request_path`: The path from the request URL
///
/// # Returns
/// Returns true if the cookie matches the path
pub fn matchesPath(self: *const Cookie, request_path: []const u8) bool {
    const cookie_path = self.path orelse return true;

    // Exact match
    if (std.mem.eql(u8, cookie_path, request_path)) {
        return true;
    }

    // Cookie path is a prefix of request path
    if (std.mem.startsWith(u8, request_path, cookie_path)) {
        // Must be followed by / or be the full path
        if (cookie_path[cookie_path.len - 1] == '/') {
            return true;
        }
        if (request_path.len > cookie_path.len and request_path[cookie_path.len] == '/') {
            return true;
        }
    }

    return false;
}

// Tests
test "Cookie parse simple" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var cookie = try Cookie.parse(allocator, "session=abc123");
    defer cookie.deinit(allocator);

    try testing.expectEqualStrings("session", cookie.name);
    try testing.expectEqualStrings("abc123", cookie.value);
    try testing.expect(cookie.domain == null);
    try testing.expect(cookie.path == null);
    try testing.expect(!cookie.secure);
    try testing.expect(!cookie.http_only);
}

test "Cookie parse with attributes" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var cookie = try Cookie.parse(allocator, "id=xyz; Domain=.example.com; Path=/api; Secure; HttpOnly");
    defer cookie.deinit(allocator);

    try testing.expectEqualStrings("id", cookie.name);
    try testing.expectEqualStrings("xyz", cookie.value);
    try testing.expect(cookie.domain != null);
    try testing.expectEqualStrings(".example.com", cookie.domain.?);
    try testing.expect(cookie.path != null);
    try testing.expectEqualStrings("/api", cookie.path.?);
    try testing.expect(cookie.secure);
    try testing.expect(cookie.http_only);
}

test "Cookie parse with SameSite" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var cookie = try Cookie.parse(allocator, "token=abc; SameSite=Strict");
    defer cookie.deinit(allocator);

    try testing.expect(cookie.same_site != null);
    try testing.expectEqual(SameSite.strict, cookie.same_site.?);
}

test "Cookie toString" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var cookie = try Cookie.parse(allocator, "session=abc123; Secure");
    defer cookie.deinit(allocator);

    const str = try cookie.toString(allocator);
    defer allocator.free(str);

    try testing.expectEqualStrings("session=abc123", str);
}

test "Cookie isExpired with max_age" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var cookie = try Cookie.parse(allocator, "id=xyz; Max-Age=-1");
    defer cookie.deinit(allocator);

    try testing.expect(cookie.isExpired());

    var cookie2 = try Cookie.parse(allocator, "id=xyz; Max-Age=3600");
    defer cookie2.deinit(allocator);

    try testing.expect(!cookie2.isExpired());
}

test "Cookie matchesDomain" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var cookie = try Cookie.parse(allocator, "id=xyz; Domain=.example.com");
    defer cookie.deinit(allocator);

    try testing.expect(cookie.matchesDomain("example.com"));
    try testing.expect(cookie.matchesDomain("www.example.com"));
    try testing.expect(cookie.matchesDomain("api.example.com"));
    try testing.expect(!cookie.matchesDomain("different.com"));
}

test "Cookie matchesPath" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var cookie = try Cookie.parse(allocator, "id=xyz; Path=/api");
    defer cookie.deinit(allocator);

    try testing.expect(cookie.matchesPath("/api"));
    try testing.expect(cookie.matchesPath("/api/users"));
    try testing.expect(cookie.matchesPath("/api/users/123"));
    try testing.expect(!cookie.matchesPath("/other"));
    try testing.expect(!cookie.matchesPath("/"));
}
