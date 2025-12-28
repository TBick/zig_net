//! Cookie Management Example
//!
//! This example demonstrates how to use cookies and CookieJar with zig_net.
//!
//! Run with:
//! zig build-exe examples/cookies_example.zig --dep zig_net -Mroot=examples/cookies_example.zig -Mzig_net=src/root.zig
//! OR
//! zig run examples/cookies_example.zig

const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    std.debug.print("\n=== zig_net Cookie Examples ===\n\n", .{});

    // Example 1: Basic Cookie Parsing
    try basicCookieExample(allocator);

    // Example 2: Cookie Jar Management
    try cookieJarExample(allocator);

    // Example 3: Using CookieJar with Requests
    try cookieJarRequestExample(allocator);

    std.debug.print("\n=== All cookie examples completed successfully! ===\n", .{});
}

/// Example 1: Basic Cookie Parsing
///
/// Parse Set-Cookie headers into Cookie objects
fn basicCookieExample(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Example 1: Basic Cookie Parsing ---\n", .{});

    // Parse a Set-Cookie header value
    const set_cookie = "session=abc123; Path=/; HttpOnly; Secure; SameSite=Lax";
    var cookie = try zig_net.Cookie.parse(allocator, set_cookie);
    defer cookie.deinit(allocator);

    std.debug.print("Cookie Name: {s}\n", .{cookie.name});
    std.debug.print("Cookie Value: {s}\n", .{cookie.value});
    std.debug.print("Path: {s}\n", .{cookie.path orelse "/"});
    std.debug.print("HttpOnly: {}\n", .{cookie.http_only});
    std.debug.print("Secure: {}\n", .{cookie.secure});

    if (cookie.same_site) |same_site| {
        std.debug.print("SameSite: {s}\n", .{@tagName(same_site)});
    }

    std.debug.print("\n", .{});
}

/// Example 2: Cookie Jar Management
///
/// Store and manage multiple cookies in a CookieJar
fn cookieJarExample(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Example 2: Cookie Jar Management ---\n", .{});

    var jar = zig_net.CookieJar.init(allocator);
    defer jar.deinit();

    // Add cookies from Set-Cookie headers
    try jar.setCookie("session=xyz123; Path=/; HttpOnly");
    try jar.setCookie("user=alice; Path=/; Max-Age=3600");
    try jar.setCookie("theme=dark; Path=/settings; Max-Age=86400");

    std.debug.print("Total cookies in jar: {d}\n", .{jar.count()});

    // Get a specific cookie
    if (jar.getCookie("session")) |cookie| {
        std.debug.print("Session cookie value: {s}\n", .{cookie.value});
    }

    // Replace a cookie (same name and path)
    try jar.setCookie("user=bob; Path=/; Max-Age=3600");
    std.debug.print("After replacing user cookie: {d} cookies\n", .{jar.count()});

    if (jar.getCookie("user")) |cookie| {
        std.debug.print("Updated user: {s}\n", .{cookie.value});
    }

    // Remove expired cookies
    jar.removeExpired();
    std.debug.print("After removing expired: {d} cookies\n", .{jar.count()});

    std.debug.print("\n", .{});
}

/// Example 3: Using CookieJar with HTTP Requests
///
/// Use CookieJar to automatically send cookies with requests
fn cookieJarRequestExample(allocator: std.mem.Allocator) !void {
    std.debug.print("--- Example 3: CookieJar with Requests ---\n", .{});

    var jar = zig_net.CookieJar.init(allocator);
    defer jar.deinit();

    // Simulate receiving Set-Cookie headers from a server
    try jar.setCookie("session=server-session-id; Path=/; Domain=.httpbin.org");
    try jar.setCookie("preferences=lang:en; Path=/; Domain=.httpbin.org");

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Create a request
    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/cookies",
    );
    defer request.deinit();

    // Get cookies that match this request's domain and path
    const cookie_header = try jar.getCookiesForRequest(
        allocator,
        "https://httpbin.org/cookies",
    );
    defer allocator.free(cookie_header);

    std.debug.print("Cookie header for request: {s}\n", .{cookie_header});

    // Set the Cookie header on the request
    if (cookie_header.len > 0) {
        _ = try request.setHeader("Cookie", cookie_header);
    }

    // Send the request
    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Response Status: {d} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase(),
    });

    if (response.isSuccess()) {
        const body = response.getBody();
        std.debug.print("Response Body:\n{s}\n", .{body});
    }

    std.debug.print("\n", .{});
}

/// Example 4: Domain and Path Matching
///
/// Cookies are matched based on domain and path rules (RFC 6265)
fn domainPathExample(allocator: std.mem.Allocator) !void {
    _ = allocator; // This is just a code example, not executed

    // Example: Domain matching
    // var cookie = try zig_net.Cookie.parse(allocator, "session=abc; Domain=.example.com");
    // defer cookie.deinit(allocator);
    //
    // // This cookie matches:
    // // - example.com
    // // - www.example.com
    // // - api.example.com
    // // But NOT:
    // // - notexample.com
    // // - example.org
    //
    // std.debug.print("Matches example.com: {}\n", .{cookie.matchesDomain("example.com")});
    // std.debug.print("Matches www.example.com: {}\n", .{cookie.matchesDomain("www.example.com")});
    // std.debug.print("Matches example.org: {}\n", .{cookie.matchesDomain("example.org")});
}

/// Example 5: Cookie Expiration
///
/// Cookies can expire based on Max-Age or Expires attributes
fn expirationExample(allocator: std.mem.Allocator) !void {
    _ = allocator; // This is just a code example, not executed

    // Example: Max-Age (seconds until expiration)
    // var cookie1 = try zig_net.Cookie.parse(allocator, "session=abc; Max-Age=3600");
    // defer cookie1.deinit(allocator);
    // std.debug.print("Cookie expires in 1 hour\n", .{});
    //
    // // Session cookies (no Max-Age or Expires) are valid until browser closes
    // var cookie2 = try zig_net.Cookie.parse(allocator, "temp=xyz");
    // defer cookie2.deinit(allocator);
    // std.debug.print("Session cookie (no expiration)\n", .{});
    //
    // // Check if expired
    // if (cookie1.isExpired()) {
    //     std.debug.print("Cookie has expired\n", .{});
    // } else {
    //     std.debug.print("Cookie is still valid\n", .{});
    // }
}
