//! HTTP Cookie Jar
//!
//! This module implements a cookie storage container (cookie jar) that manages
//! cookies for HTTP requests. It handles cookie storage, expiration, and
//! domain/path matching according to RFC 6265.
//!
//! # Features
//! - Store cookies from Set-Cookie headers
//! - Retrieve cookies for outgoing requests
//! - Automatic expiration handling
//! - Domain and path matching
//! - Cookie replacement when setting duplicate cookies
//!
//! # Usage
//! ```zig
//! const CookieJar = @import("cookies/CookieJar.zig");
//!
//! var jar = CookieJar.init(allocator);
//! defer jar.deinit();
//!
//! // Add cookie from Set-Cookie header
//! try jar.setCookie("session=abc; Path=/; HttpOnly");
//!
//! // Get cookies for a request
//! const cookies = try jar.getCookiesForRequest(allocator, "https://example.com/api");
//! defer allocator.free(cookies);
//! ```

const std = @import("std");
const Cookie = @import("Cookie.zig");

/// Cookie Jar for managing HTTP cookies
///
/// Stores cookies and manages their lifecycle, expiration, and matching.
pub const CookieJar = @This();

allocator: std.mem.Allocator,
cookies: std.ArrayList(Cookie),

/// Initializes a new empty cookie jar
///
/// # Parameters
/// - `allocator`: Memory allocator for the jar
///
/// # Returns
/// Returns a new CookieJar instance
pub fn init(allocator: std.mem.Allocator) CookieJar {
    return .{
        .allocator = allocator,
        .cookies = std.ArrayList(Cookie){},
    };
}

/// Frees all resources associated with this cookie jar
pub fn deinit(self: *CookieJar) void {
    for (self.cookies.items) |*cookie| {
        cookie.deinit(self.allocator);
    }
    self.cookies.deinit(self.allocator);
}

/// Adds a cookie to the jar from a Set-Cookie header value
///
/// If a cookie with the same name, domain, and path already exists,
/// it will be replaced.
///
/// # Parameters
/// - `self`: The CookieJar instance
/// - `set_cookie_value`: The value from the Set-Cookie header
///
/// # Errors
/// Returns an error if cookie parsing or allocation fails
///
/// # Example
/// ```zig
/// try jar.setCookie("session=xyz123; Path=/; HttpOnly; Secure");
/// ```
pub fn setCookie(self: *CookieJar, set_cookie_value: []const u8) !void {
    var new_cookie = try Cookie.parse(self.allocator, set_cookie_value);
    errdefer new_cookie.deinit(self.allocator);

    // Check if we should replace an existing cookie
    for (self.cookies.items, 0..) |*existing, i| {
        if (self.cookiesMatch(existing, &new_cookie)) {
            // Replace existing cookie
            existing.deinit(self.allocator);
            self.cookies.items[i] = new_cookie;
            return;
        }
    }

    // Add new cookie
    try self.cookies.append(self.allocator, new_cookie);
}

/// Checks if two cookies match (same name, domain, path)
fn cookiesMatch(self: *CookieJar, a: *const Cookie, b: *const Cookie) bool {
    _ = self;

    if (!std.mem.eql(u8, a.name, b.name)) return false;

    // Compare domains
    const a_domain = a.domain orelse "";
    const b_domain = b.domain orelse "";
    if (!std.mem.eql(u8, a_domain, b_domain)) return false;

    // Compare paths
    const a_path = a.path orelse "";
    const b_path = b.path orelse "";
    if (!std.mem.eql(u8, a_path, b_path)) return false;

    return true;
}

/// Gets cookies that match the given URI for inclusion in a request
///
/// Returns a Cookie header value string with all matching cookies.
/// Filters out expired cookies and matches by domain and path.
///
/// # Parameters
/// - `self`: The CookieJar instance
/// - `allocator`: Memory allocator for the result string
/// - `uri`: The request URI (e.g., "https://example.com/api/users")
///
/// # Returns
/// Returns a string suitable for the Cookie header (e.g., "session=abc; id=xyz").
/// Returns empty string if no cookies match. Caller must free the returned string.
///
/// # Errors
/// Returns an error if allocation fails
///
/// # Example
/// ```zig
/// const cookie_header = try jar.getCookiesForRequest(allocator, "https://example.com/api");
/// defer allocator.free(cookie_header);
/// // Use in request: request.setHeader("Cookie", cookie_header)
/// ```
pub fn getCookiesForRequest(self: *CookieJar, allocator: std.mem.Allocator, uri: []const u8) ![]u8 {
    // Parse the URI to extract domain and path
    const parsed = try std.Uri.parse(uri);
    const domain = parsed.host orelse return try allocator.dupe(u8, "");
    const path_component = parsed.path;
    const path = if (path_component.percent_encoded.len > 0) path_component.percent_encoded else "/";

    var result = std.ArrayList(u8){};
    defer result.deinit(allocator);

    var first = true;
    for (self.cookies.items) |*cookie| {
        // Skip expired cookies
        if (cookie.isExpired()) continue;

        // Check domain and path match
        if (!cookie.matchesDomain(domain.percent_encoded)) continue;
        if (!cookie.matchesPath(path)) continue;

        // Add to result
        if (!first) {
            try result.appendSlice(allocator, "; ");
        }
        first = false;

        const cookie_str = try cookie.toString(allocator);
        defer allocator.free(cookie_str);
        try result.appendSlice(allocator, cookie_str);
    }

    return try result.toOwnedSlice(allocator);
}

/// Gets a cookie by name
///
/// # Parameters
/// - `self`: The CookieJar instance
/// - `name`: The cookie name to search for
///
/// # Returns
/// Returns a pointer to the cookie if found, null otherwise
pub fn getCookie(self: *CookieJar, name: []const u8) ?*const Cookie {
    for (self.cookies.items) |*cookie| {
        if (std.mem.eql(u8, cookie.name, name)) {
            if (!cookie.isExpired()) {
                return cookie;
            }
        }
    }
    return null;
}

/// Removes expired cookies from the jar
///
/// This should be called periodically to clean up the jar.
pub fn removeExpired(self: *CookieJar) void {
    var i: usize = 0;
    while (i < self.cookies.items.len) {
        if (self.cookies.items[i].isExpired()) {
            var cookie = self.cookies.orderedRemove(i);
            cookie.deinit(self.allocator);
        } else {
            i += 1;
        }
    }
}

/// Returns the number of cookies in the jar (including expired)
pub fn count(self: *const CookieJar) usize {
    return self.cookies.items.len;
}

/// Clears all cookies from the jar
pub fn clear(self: *CookieJar) void {
    for (self.cookies.items) |*cookie| {
        cookie.deinit(self.allocator);
    }
    self.cookies.clearRetainingCapacity();
}

// Tests
test "CookieJar init and deinit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var jar = CookieJar.init(allocator);
    defer jar.deinit();

    try testing.expectEqual(@as(usize, 0), jar.count());
}

test "CookieJar setCookie" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var jar = CookieJar.init(allocator);
    defer jar.deinit();

    try jar.setCookie("session=abc123; Path=/");
    try testing.expectEqual(@as(usize, 1), jar.count());

    try jar.setCookie("id=xyz; Domain=.example.com");
    try testing.expectEqual(@as(usize, 2), jar.count());
}

test "CookieJar replace cookie" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var jar = CookieJar.init(allocator);
    defer jar.deinit();

    try jar.setCookie("session=old; Path=/");
    try testing.expectEqual(@as(usize, 1), jar.count());

    // Set same cookie with new value - should replace
    try jar.setCookie("session=new; Path=/");
    try testing.expectEqual(@as(usize, 1), jar.count());

    const cookie = jar.getCookie("session");
    try testing.expect(cookie != null);
    try testing.expectEqualStrings("new", cookie.?.value);
}

test "CookieJar getCookie" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var jar = CookieJar.init(allocator);
    defer jar.deinit();

    try jar.setCookie("session=abc123");
    try jar.setCookie("user=alice");

    const session = jar.getCookie("session");
    try testing.expect(session != null);
    try testing.expectEqualStrings("abc123", session.?.value);

    const user = jar.getCookie("user");
    try testing.expect(user != null);
    try testing.expectEqualStrings("alice", user.?.value);

    const missing = jar.getCookie("nonexistent");
    try testing.expect(missing == null);
}

test "CookieJar getCookiesForRequest" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var jar = CookieJar.init(allocator);
    defer jar.deinit();

    try jar.setCookie("session=abc; Path=/");
    try jar.setCookie("user=alice; Domain=.example.com; Path=/api");

    const cookies = try jar.getCookiesForRequest(allocator, "https://example.com/api/users");
    defer allocator.free(cookies);

    // Should contain both cookies
    try testing.expect(std.mem.indexOf(u8, cookies, "session=abc") != null);
    try testing.expect(std.mem.indexOf(u8, cookies, "user=alice") != null);
}

test "CookieJar removeExpired" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var jar = CookieJar.init(allocator);
    defer jar.deinit();

    try jar.setCookie("valid=abc; Max-Age=3600");
    try jar.setCookie("expired=xyz; Max-Age=-1");

    try testing.expectEqual(@as(usize, 2), jar.count());

    jar.removeExpired();

    try testing.expectEqual(@as(usize, 1), jar.count());

    const valid = jar.getCookie("valid");
    try testing.expect(valid != null);

    const expired = jar.getCookie("expired");
    try testing.expect(expired == null);
}

test "CookieJar clear" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var jar = CookieJar.init(allocator);
    defer jar.deinit();

    try jar.setCookie("session=abc");
    try jar.setCookie("user=alice");
    try testing.expectEqual(@as(usize, 2), jar.count());

    jar.clear();
    try testing.expectEqual(@as(usize, 0), jar.count());
}
