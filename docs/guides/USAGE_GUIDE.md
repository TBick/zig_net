# zig_net - Complete Usage Guide

**A comprehensive step-by-step guide to using the zig_net HTTP/HTTPS client library**

This guide demonstrates all features of zig_net using real examples tested against httpbin.org, a free HTTP testing service.

---

## Table of Contents

1. [Setup and Prerequisites](#1-setup-and-prerequisites)
2. [Basic GET Request](#2-basic-get-request)
3. [POST with JSON](#3-post-with-json)
4. [PUT Request](#4-put-request)
5. [DELETE Request](#5-delete-request)
6. [Custom Headers](#6-custom-headers)
7. [Query Parameters](#7-query-parameters)
8. [HTTP Authentication](#8-http-authentication)
   - [Basic Authentication](#basic-authentication)
   - [Bearer Token Authentication](#bearer-token-authentication)
9. [Cookie Management](#9-cookie-management)
10. [Redirect Handling](#10-redirect-handling)
11. [Error Handling](#11-error-handling)
12. [Form Data](#12-form-data)
13. [Request/Response Interceptors](#13-requestresponse-interceptors)
14. [Metrics Collection](#14-metrics-collection)
15. [Client Configuration](#15-client-configuration)
16. [Advanced Features](#16-advanced-features)
17. [Complete Working Examples](#17-complete-working-examples)

---

## 1. Setup and Prerequisites

### Requirements

- **Zig version**: 0.15.1 or later
- **Internet connection**: For testing against httpbin.org
- **No external dependencies**: zig_net uses only the Zig standard library

### Project Structure

```
your_project/
├── build.zig
├── build.zig.zon
└── src/
    └── main.zig
```

### Build Configuration

In your `build.zig`:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "my_http_app",
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Add zig_net dependency (adjust path as needed)
    const zig_net = b.addModule("zig_net", .{
        .root_source_file = b.path("../zig_net/src/root.zig"),
    });
    exe.root_module.addImport("zig_net", zig_net);

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);
}
```

### Basic Program Template

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    // Setup allocator
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Your HTTP code goes here
}
```

---

## 2. Basic GET Request

The simplest HTTP operation - fetching data from a server.

### Example: Simple GET

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create an HTTP client
    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Make a GET request
    const response = try client.get("https://httpbin.org/get");
    defer response.deinit();

    // Check if successful
    if (response.isSuccess()) {
        std.debug.print("Status: {d} {s}\n", .{
            response.getStatus(),
            response.getReasonPhrase(),
        });
        std.debug.print("Body:\n{s}\n", .{response.getBody()});
    }
}
```

**What httpbin.org returns:**

```json
{
  "args": {},
  "headers": {
    "Host": "httpbin.org",
    "User-Agent": "zig-std-http-client"
  },
  "origin": "your.ip.address",
  "url": "https://httpbin.org/get"
}
```

### Key Points

- `Client.init()` creates an HTTP client with connection pooling
- `client.get()` is a convenience method for simple GET requests
- Always `defer response.deinit()` to free memory
- Response body is available via `response.getBody()`

---

## 3. POST with JSON

Send JSON data to a server.

### Example: POST JSON Data

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Create a POST request
    var request = try zig_net.Request.init(
        allocator,
        .POST,
        "https://httpbin.org/post",
    );
    defer request.deinit();

    // Set JSON body (automatically sets Content-Type header)
    _ = try request.setJsonBody(
        \\{
        \\  "name": "Alice",
        \\  "email": "alice@example.com",
        \\  "age": 30
        \\}
    );

    // Send the request
    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Status: {d}\n", .{response.getStatus()});
    std.debug.print("Response:\n{s}\n", .{response.getBody()});
}
```

**What httpbin.org returns:**

```json
{
  "data": "{\"name\":\"Alice\",\"email\":\"alice@example.com\",\"age\":30}",
  "headers": {
    "Content-Type": "application/json",
    "Content-Length": "54"
  },
  "json": {
    "name": "Alice",
    "email": "alice@example.com",
    "age": 30
  },
  "url": "https://httpbin.org/post"
}
```

### Alternative: Using Convenience Method

```zig
// Shorthand for simple POST requests
const response = try client.post(
    "https://httpbin.org/post",
    "{\"name\": \"Bob\"}",
    "application/json",
);
defer response.deinit();
```

---

## 4. PUT Request

Update a resource with PUT.

### Example: PUT Request

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Create a PUT request
    var request = try zig_net.Request.init(
        allocator,
        .PUT,
        "https://httpbin.org/put",
    );
    defer request.deinit();

    _ = try request.setJsonBody(
        \\{
        \\  "id": 123,
        \\  "name": "Updated Resource"
        \\}
    );

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("PUT Status: {d}\n", .{response.getStatus()});
    std.debug.print("Response:\n{s}\n", .{response.getBody()});
}
```

**Alternative: Using Convenience Method**

```zig
const response = try client.put(
    "https://httpbin.org/put",
    "{\"id\": 123}",
    "application/json",
);
defer response.deinit();
```

---

## 5. DELETE Request

Remove a resource with DELETE.

### Example: DELETE Request

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Simple DELETE
    const response = try client.delete("https://httpbin.org/delete");
    defer response.deinit();

    if (response.isSuccess()) {
        std.debug.print("Resource deleted successfully\n", .{});
        std.debug.print("Status: {d}\n", .{response.getStatus()});
    }
}
```

### DELETE with Body (Less Common)

```zig
var request = try zig_net.Request.init(
    allocator,
    .DELETE,
    "https://httpbin.org/delete",
);
defer request.deinit();

_ = try request.setJsonBody("{\"reason\": \"deprecated\"}");

const response = try client.send(&request);
defer response.deinit();
```

---

## 6. Custom Headers

Add custom headers to your requests.

### Example: Multiple Custom Headers

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/headers",
    );
    defer request.deinit();

    // Add multiple headers using method chaining
    _ = try request
        .setHeader("User-Agent", "MyApp/1.0")
        .setHeader("X-API-Version", "v2")
        .setHeader("X-Request-ID", "abc-123-def")
        .setHeader("Accept", "application/json");

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Status: {d}\n", .{response.getStatus()});
    std.debug.print("Server received these headers:\n{s}\n", .{
        response.getBody(),
    });
}
```

**httpbin.org will echo your headers:**

```json
{
  "headers": {
    "Accept": "application/json",
    "Host": "httpbin.org",
    "User-Agent": "MyApp/1.0",
    "X-Api-Version": "v2",
    "X-Request-Id": "abc-123-def"
  }
}
```

### Reading Response Headers

```zig
if (response.getHeader("Content-Type")) |content_type| {
    std.debug.print("Content-Type: {s}\n", .{content_type});
}

// Or use convenience method
if (response.getContentType()) |ct| {
    std.debug.print("Content-Type: {s}\n", .{ct});
}
```

---

## 7. Query Parameters

Add query parameters to URLs.

### Example: Manual Query String

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // URL with query parameters
    const url = "https://httpbin.org/get?name=Alice&age=30&city=NewYork";

    const response = try client.get(url);
    defer response.deinit();

    std.debug.print("Response:\n{s}\n", .{response.getBody()});
}
```

**httpbin.org response shows parsed args:**

```json
{
  "args": {
    "age": "30",
    "city": "NewYork",
    "name": "Alice"
  },
  "url": "https://httpbin.org/get?name=Alice&age=30&city=NewYork"
}
```

### Example: Building Query String with URL Encoding

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Build URL with encoded parameters
    const base_url = "https://httpbin.org/get";

    // For special characters, use zig_net's URL encoding
    const search = "hello world";
    const encoded_search = try zig_net.urlEncode(allocator, search);
    defer allocator.free(encoded_search);

    const url = try std.fmt.allocPrint(
        allocator,
        "{s}?search={s}&filter=active",
        .{ base_url, encoded_search },
    );
    defer allocator.free(url);

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    const response = try client.get(url);
    defer response.deinit();

    std.debug.print("Response:\n{s}\n", .{response.getBody()});
}
```

---

## 8. HTTP Authentication

### Basic Authentication

HTTP Basic Authentication (RFC 7617) - encodes username:password in base64.

**⚠️ Security Warning**: Basic auth credentials are only base64-encoded, NOT encrypted. Always use HTTPS!

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // httpbin.org/basic-auth/{user}/{password} requires those exact credentials
    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/basic-auth/user/passwd",
    );
    defer request.deinit();

    // Set Basic Auth - automatically encodes and sets Authorization header
    _ = try request.setBasicAuth("user", "passwd");

    const response = try client.send(&request);
    defer response.deinit();

    if (response.isSuccess()) {
        std.debug.print("✓ Authentication successful!\n", .{});
        std.debug.print("Response:\n{s}\n", .{response.getBody()});
    } else if (response.getStatus() == 401) {
        std.debug.print("✗ Authentication failed: 401 Unauthorized\n", .{});
    }
}
```

**Successful response:**

```json
{
  "authenticated": true,
  "user": "user"
}
```

### Bearer Token Authentication

Bearer token authentication (RFC 6750) - commonly used with OAuth 2.0 and JWT.

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/bearer",
    );
    defer request.deinit();

    // Set Bearer token - sets Authorization: Bearer <token>
    _ = try request.setBearerToken("my-secret-token-12345");

    const response = try client.send(&request);
    defer response.deinit();

    if (response.isSuccess()) {
        std.debug.print("✓ Token authentication successful!\n", .{});
        std.debug.print("Response:\n{s}\n", .{response.getBody()});
    } else if (response.getStatus() == 401) {
        std.debug.print("✗ Invalid or missing token\n", .{});
    }
}
```

**Successful response:**

```json
{
  "authenticated": true,
  "token": "my-secret-token-12345"
}
```

---

## 9. Cookie Management

zig_net provides RFC 6265 compliant cookie parsing and management.

### Example: Basic Cookie Usage

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create a cookie jar to store cookies
    var jar = zig_net.CookieJar.init(allocator);
    defer jar.deinit();

    // Parse and store cookies (like from Set-Cookie headers)
    try jar.setCookie("session=abc123; Path=/; HttpOnly; Secure");
    try jar.setCookie("user_id=42; Path=/; Max-Age=3600");

    std.debug.print("Cookies in jar: {d}\n", .{jar.count()});

    // Retrieve a specific cookie
    if (jar.getCookie("session")) |cookie| {
        std.debug.print("Session cookie: {s}={s}\n", .{
            cookie.name,
            cookie.value,
        });
    }

    // Get all cookies for a request (as Cookie header value)
    const cookie_header = try jar.getCookiesForRequest(
        allocator,
        "https://httpbin.org/cookies",
    );
    defer allocator.free(cookie_header);

    std.debug.print("Cookie header: {s}\n", .{cookie_header});
}
```

### Example: Using Cookies with HTTP Requests

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var jar = zig_net.CookieJar.init(allocator);
    defer jar.deinit();

    // Step 1: Make a request that sets cookies
    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    const set_cookie_response = try client.get(
        "https://httpbin.org/cookies/set?session=xyz&theme=dark",
    );
    defer set_cookie_response.deinit();

    // Store cookies from response
    if (set_cookie_response.getHeader("Set-Cookie")) |set_cookie| {
        try jar.setCookie(set_cookie);
    }

    // Step 2: Make another request with the stored cookies
    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/cookies",
    );
    defer request.deinit();

    // Add cookies to request
    const cookie_header = try jar.getCookiesForRequest(
        allocator,
        "https://httpbin.org/cookies",
    );
    defer allocator.free(cookie_header);

    if (cookie_header.len > 0) {
        _ = try request.setHeader("Cookie", cookie_header);
    }

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Server sees these cookies:\n{s}\n", .{
        response.getBody(),
    });
}
```

**httpbin.org response:**

```json
{
  "cookies": {
    "session": "xyz",
    "theme": "dark"
  }
}
```

---

## 10. Redirect Handling

zig_net automatically follows HTTP redirects with loop detection.

### Example: Automatic Redirects

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Client with redirect following enabled (default)
    var client = try zig_net.Client.init(allocator, .{
        .follow_redirects = true,
        .max_redirects = 10,
    });
    defer client.deinit();

    // This URL redirects to /get
    const response = try client.get("https://httpbin.org/redirect-to?url=/get");
    defer response.deinit();

    std.debug.print("Final status: {d}\n", .{response.getStatus()});
    std.debug.print("Response:\n{s}\n", .{response.getBody()});
}
```

### Example: Testing Different Redirect Types

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    const redirects = [_]struct { url: []const u8, description: []const u8 }{
        .{
            .url = "https://httpbin.org/redirect/3",
            .description = "3 redirects",
        },
        .{
            .url = "https://httpbin.org/absolute-redirect/2",
            .description = "2 absolute redirects",
        },
        .{
            .url = "https://httpbin.org/relative-redirect/2",
            .description = "2 relative redirects",
        },
    };

    for (redirects) |redir| {
        std.debug.print("\nTesting: {s}\n", .{redir.description});

        const response = try client.get(redir.url);
        defer response.deinit();

        std.debug.print("Final status: {d}\n", .{response.getStatus()});
    }
}
```

### Example: Disabling Redirects

```zig
// Get the redirect response directly without following
var client = try zig_net.Client.init(allocator, .{
    .follow_redirects = false,
});
defer client.deinit();

const response = try client.get("https://httpbin.org/redirect/1");
defer response.deinit();

std.debug.print("Status: {d}\n", .{response.getStatus()}); // 302
if (response.getHeader("Location")) |location| {
    std.debug.print("Redirects to: {s}\n", .{location});
}
```

---

## 11. Error Handling

Comprehensive error handling for HTTP operations.

### Example: Response Status Checking

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    const urls = [_][]const u8{
        "https://httpbin.org/status/200", // OK
        "https://httpbin.org/status/404", // Not Found
        "https://httpbin.org/status/500", // Server Error
    };

    for (urls) |url| {
        const response = try client.get(url);
        defer response.deinit();

        std.debug.print("\n{s}\n", .{url});
        std.debug.print("Status: {d} {s}\n", .{
            response.getStatus(),
            response.getReasonPhrase(),
        });

        if (response.isSuccess()) {
            std.debug.print("✓ Success (2xx)\n", .{});
        } else if (response.isClientError()) {
            std.debug.print("✗ Client Error (4xx)\n", .{});
        } else if (response.isServerError()) {
            std.debug.print("✗ Server Error (5xx)\n", .{});
        }
    }
}
```

### Example: Network Error Handling

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Try to connect to invalid URL
    const response = client.get("https://this-domain-does-not-exist-12345.com") catch |err| {
        std.debug.print("Request failed: {}\n", .{err});

        // Get human-readable error message
        const msg = zig_net.errors.getErrorMessage(err);
        std.debug.print("Error description: {s}\n", .{msg});

        return err;
    };
    defer response.deinit();
}
```

### Example: Comprehensive Error Handling

```zig
const std = @import("std");
const zig_net = @import("zig_net");

fn handleRequest(allocator: std.mem.Allocator, url: []const u8) !void {
    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    const response = client.get(url) catch |err| {
        switch (err) {
            error.InvalidUri => {
                std.debug.print("Error: Invalid URL format\n", .{});
            },
            error.ConnectionFailed => {
                std.debug.print("Error: Could not connect to server\n", .{});
            },
            error.ConnectionTimeout => {
                std.debug.print("Error: Connection timed out\n", .{});
            },
            error.TooManyRedirects => {
                std.debug.print("Error: Too many redirects\n", .{});
            },
            else => {
                std.debug.print("Error: {}\n", .{err});
            },
        }
        return err;
    };
    defer response.deinit();

    // Check response status
    if (response.isSuccess()) {
        std.debug.print("Success!\n", .{});
    } else if (response.isClientError()) {
        std.debug.print("Client error: {d}\n", .{response.getStatus()});
    } else if (response.isServerError()) {
        std.debug.print("Server error: {d}\n", .{response.getStatus()});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    try handleRequest(allocator, "https://httpbin.org/get");
}
```

---

## 12. Form Data

Send form-encoded data (application/x-www-form-urlencoded).

### Example: Submitting Form Data

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(
        allocator,
        .POST,
        "https://httpbin.org/post",
    );
    defer request.deinit();

    // Create form data
    var form = std.StringHashMap([]const u8).init(allocator);
    defer form.deinit();

    try form.put("username", "alice");
    try form.put("password", "secret123");
    try form.put("remember_me", "true");

    // Set form body (automatically URL-encodes and sets Content-Type)
    _ = try request.setFormBody(&form);

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Status: {d}\n", .{response.getStatus()});
    std.debug.print("Response:\n{s}\n", .{response.getBody()});
}
```

**httpbin.org response:**

```json
{
  "form": {
    "password": "secret123",
    "remember_me": "true",
    "username": "alice"
  },
  "headers": {
    "Content-Type": "application/x-www-form-urlencoded"
  }
}
```

### Example: Form Data with Special Characters

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(
        allocator,
        .POST,
        "https://httpbin.org/post",
    );
    defer request.deinit();

    var form = std.StringHashMap([]const u8).init(allocator);
    defer form.deinit();

    // Special characters are automatically URL-encoded
    try form.put("message", "Hello, World!");
    try form.put("email", "test@example.com");
    try form.put("query", "a=1&b=2");

    _ = try request.setFormBody(&form);

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Response:\n{s}\n", .{response.getBody()});
}
```

---

## 13. Request/Response Interceptors

Interceptors provide middleware-style hooks for requests and responses.

### Example: Logging Interceptors

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/get",
    );
    defer request.deinit();

    _ = try request.setHeader("User-Agent", "MyApp/1.0");

    // Log the outgoing request
    std.debug.print("=== Outgoing Request ===\n", .{});
    try zig_net.interceptor.loggingRequestInterceptor(&request);

    const response = try client.send(&request);
    defer response.deinit();

    // Log the incoming response
    std.debug.print("\n=== Incoming Response ===\n", .{});
    try zig_net.interceptor.loggingResponseInterceptor(&response);
}
```

### Example: Custom Request Interceptor

```zig
const std = @import("std");
const zig_net = @import("zig_net");

// Custom interceptor that adds authentication
fn authInterceptor(request: *zig_net.Request) !void {
    std.debug.print("[Auth] Adding API key\n", .{});
    _ = try request.setHeader("X-API-Key", "my-secret-key");
}

// Custom interceptor that adds tracking headers
fn trackingInterceptor(request: *zig_net.Request) !void {
    const request_id = "req-12345"; // In real app, generate unique ID
    std.debug.print("[Tracking] Request ID: {s}\n", .{request_id});
    _ = try request.setHeader("X-Request-ID", request_id);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/headers",
    );
    defer request.deinit();

    // Apply multiple interceptors
    try authInterceptor(&request);
    try trackingInterceptor(&request);

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Response:\n{s}\n", .{response.getBody()});
}
```

### Example: Custom Response Interceptor

```zig
const std = @import("std");
const zig_net = @import("zig_net");

// Validate response content type
fn contentTypeValidator(response: *const zig_net.Response) !void {
    if (response.getContentType()) |ct| {
        if (std.mem.indexOf(u8, ct, "application/json") != null) {
            std.debug.print("✓ Valid JSON response\n", .{});
        } else {
            std.debug.print("⚠ Warning: Expected JSON, got {s}\n", .{ct});
        }
    } else {
        std.debug.print("⚠ Warning: No Content-Type header\n", .{});
    }
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    const response = try client.get("https://httpbin.org/json");
    defer response.deinit();

    // Apply custom response interceptor
    try contentTypeValidator(&response);

    if (response.isSuccess()) {
        std.debug.print("Body:\n{s}\n", .{response.getBody()});
    }
}
```

---

## 14. Metrics Collection

Track HTTP request statistics with the built-in MetricsCollector.

### Example: Basic Metrics

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var metrics = zig_net.MetricsCollector.init(allocator);
    defer metrics.deinit();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Make multiple requests and track metrics
    const urls = [_][]const u8{
        "https://httpbin.org/status/200",
        "https://httpbin.org/status/200",
        "https://httpbin.org/status/404",
        "https://httpbin.org/status/500",
        "https://httpbin.org/status/200",
    };

    for (urls) |url| {
        // Record request
        metrics.recordRequest();

        const response = try client.get(url);
        defer response.deinit();

        // Record response
        metrics.recordResponse(&response);

        std.debug.print("Request to {s}: {d}\n", .{ url, response.getStatus() });
    }

    // Print statistics
    std.debug.print("\n=== HTTP Metrics ===\n", .{});
    metrics.printStats();

    const success_rate = metrics.getSuccessRate();
    std.debug.print("Success Rate: {d:.1}%\n", .{success_rate});
}
```

**Output:**

```
Request to https://httpbin.org/status/200: 200
Request to https://httpbin.org/status/200: 200
Request to https://httpbin.org/status/404: 404
Request to https://httpbin.org/status/500: 500
Request to https://httpbin.org/status/200: 200

=== HTTP Metrics ===
Total Requests: 5
Successful (2xx): 3
Client Errors (4xx): 1
Server Errors (5xx): 1
Success Rate: 60.0%
```

### Example: Detailed Metrics Analysis

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var metrics = zig_net.MetricsCollector.init(allocator);
    defer metrics.deinit();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Simulate a batch of requests
    const endpoints = [_][]const u8{
        "https://httpbin.org/get",
        "https://httpbin.org/post",
        "https://httpbin.org/put",
        "https://httpbin.org/delete",
    };

    for (endpoints) |endpoint| {
        metrics.recordRequest();

        var request = try zig_net.Request.init(allocator, .GET, endpoint);
        defer request.deinit();

        const response = try client.send(&request);
        defer response.deinit();

        metrics.recordResponse(&response);
    }

    // Custom metrics reporting
    std.debug.print("\n=== Custom Metrics Report ===\n", .{});
    std.debug.print("Total API calls: {d}\n", .{metrics.total_requests});
    std.debug.print("Successful calls: {d}\n", .{metrics.successful_requests});
    std.debug.print("Failed calls: {d}\n", .{
        metrics.total_requests - metrics.successful_requests,
    });
}
```

---

## 15. Client Configuration

Configure client behavior with ClientOptions.

### Example: Timeout Configuration

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create client with 5-second timeout
    var client = try zig_net.Client.init(allocator, .{
        .timeout_ms = 5000, // 5 seconds
        .follow_redirects = true,
        .max_redirects = 5,
        .verify_tls = true,
    });
    defer client.deinit();

    // Test with delayed response (httpbin.org can delay responses)
    const response = try client.get("https://httpbin.org/delay/2");
    defer response.deinit();

    std.debug.print("Response received after delay\n", .{});
    std.debug.print("Status: {d}\n", .{response.getStatus()});
}
```

### Example: Redirect Configuration

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Client that follows up to 3 redirects
    var client = try zig_net.Client.init(allocator, .{
        .follow_redirects = true,
        .max_redirects = 3,
    });
    defer client.deinit();

    // This should work (3 redirects)
    const response1 = try client.get("https://httpbin.org/redirect/3");
    defer response1.deinit();
    std.debug.print("3 redirects: OK\n", .{});

    // This should fail (5 redirects > max 3)
    const response2 = client.get("https://httpbin.org/redirect/5") catch |err| {
        std.debug.print("5 redirects: Failed with {}\n", .{err});
        return;
    };
    defer response2.deinit();
}
```

### Example: TLS Configuration

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Client with TLS verification enabled (default and recommended)
    var secure_client = try zig_net.Client.init(allocator, .{
        .verify_tls = true, // Verify SSL/TLS certificates
    });
    defer secure_client.deinit();

    const response = try secure_client.get("https://httpbin.org/get");
    defer response.deinit();

    std.debug.print("Secure HTTPS request successful\n", .{});
}
```

---

## 16. Advanced Features

### Example: Chunked Transfer Encoding

zig_net automatically handles chunked transfer encoding (RFC 7230).

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // httpbin.org can stream responses
    const response = try client.get("https://httpbin.org/stream/10");
    defer response.deinit();

    // Check if response is chunked
    if (response.isChunked()) {
        std.debug.print("Response uses chunked encoding\n", .{});
    }

    // Body is automatically decoded
    std.debug.print("Decoded body:\n{s}\n", .{response.getBody()});
}
```

### Example: Response Content Analysis

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    const response = try client.get("https://httpbin.org/json");
    defer response.deinit();

    // Get content type
    if (response.getContentType()) |ct| {
        std.debug.print("Content-Type: {s}\n", .{ct});
    }

    // Get content length
    if (response.getContentLength()) |length| {
        std.debug.print("Content-Length: {d} bytes\n", .{length});
    }

    // Get status information
    std.debug.print("Status Code: {d}\n", .{response.getStatus()});
    std.debug.print("Reason Phrase: {s}\n", .{response.getReasonPhrase()});

    // Check response categories
    std.debug.print("Is Success: {}\n", .{response.isSuccess()});
    std.debug.print("Is Redirect: {}\n", .{response.isRedirection()});
    std.debug.print("Is Error: {}\n", .{response.isError()});
}
```

### Example: User-Agent String

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var request = try zig_net.Request.init(
        allocator,
        .GET,
        "https://httpbin.org/user-agent",
    );
    defer request.deinit();

    // Set custom User-Agent
    _ = try request.setHeader("User-Agent", "MyBot/2.0 (zig_net; +https://example.com)");

    const response = try client.send(&request);
    defer response.deinit();

    std.debug.print("Response:\n{s}\n", .{response.getBody()});
}
```

---

## 17. Complete Working Examples

### Example 1: Complete REST API Client

```zig
const std = @import("std");
const zig_net = @import("zig_net");

const ApiClient = struct {
    allocator: std.mem.Allocator,
    client: zig_net.Client,
    base_url: []const u8,
    api_key: []const u8,

    pub fn init(
        allocator: std.mem.Allocator,
        base_url: []const u8,
        api_key: []const u8,
    ) !ApiClient {
        return .{
            .allocator = allocator,
            .client = try zig_net.Client.init(allocator, .{
                .timeout_ms = 10000,
                .follow_redirects = true,
            }),
            .base_url = base_url,
            .api_key = api_key,
        };
    }

    pub fn deinit(self: *ApiClient) void {
        self.client.deinit();
    }

    fn buildUrl(self: *ApiClient, endpoint: []const u8) ![]u8 {
        return try std.fmt.allocPrint(
            self.allocator,
            "{s}{s}",
            .{ self.base_url, endpoint },
        );
    }

    fn addAuthHeaders(self: *ApiClient, request: *zig_net.Request) !void {
        _ = try request.setHeader("X-API-Key", self.api_key);
        _ = try request.setHeader("User-Agent", "MyApiClient/1.0");
    }

    pub fn get(self: *ApiClient, endpoint: []const u8) !zig_net.Response {
        const url = try self.buildUrl(endpoint);
        defer self.allocator.free(url);

        var request = try zig_net.Request.init(self.allocator, .GET, url);
        defer request.deinit();

        try self.addAuthHeaders(&request);

        return try self.client.send(&request);
    }

    pub fn post(self: *ApiClient, endpoint: []const u8, json_body: []const u8) !zig_net.Response {
        const url = try self.buildUrl(endpoint);
        defer self.allocator.free(url);

        var request = try zig_net.Request.init(self.allocator, .POST, url);
        defer request.deinit();

        try self.addAuthHeaders(&request);
        _ = try request.setJsonBody(json_body);

        return try self.client.send(&request);
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var api = try ApiClient.init(
        allocator,
        "https://httpbin.org",
        "my-secret-api-key",
    );
    defer api.deinit();

    // GET request
    const get_response = try api.get("/get");
    defer get_response.deinit();
    std.debug.print("GET Status: {d}\n", .{get_response.getStatus()});

    // POST request
    const post_response = try api.post("/post", "{\"name\": \"Alice\"}");
    defer post_response.deinit();
    std.debug.print("POST Status: {d}\n", .{post_response.getStatus()});
}
```

### Example 2: Batch Requests with Metrics

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    var metrics = zig_net.MetricsCollector.init(allocator);
    defer metrics.deinit();

    const urls = [_][]const u8{
        "https://httpbin.org/get",
        "https://httpbin.org/headers",
        "https://httpbin.org/user-agent",
        "https://httpbin.org/status/200",
        "https://httpbin.org/status/404",
    };

    std.debug.print("Making {d} requests...\n\n", .{urls.len});

    for (urls) |url| {
        metrics.recordRequest();

        const response = try client.get(url);
        defer response.deinit();

        metrics.recordResponse(&response);

        // Log each request
        try zig_net.interceptor.loggingResponseInterceptor(&response);
        std.debug.print("\n", .{});
    }

    // Print final metrics
    std.debug.print("\n=== Final Statistics ===\n", .{});
    metrics.printStats();
    std.debug.print("Success Rate: {d:.1}%\n", .{metrics.getSuccessRate()});
}
```

### Example 3: Session Management with Cookies

```zig
const std = @import("std");
const zig_net = @import("zig_net");

const Session = struct {
    allocator: std.mem.Allocator,
    client: zig_net.Client,
    cookies: zig_net.CookieJar,

    pub fn init(allocator: std.mem.Allocator) !Session {
        return .{
            .allocator = allocator,
            .client = try zig_net.Client.init(allocator, .{}),
            .cookies = zig_net.CookieJar.init(allocator),
        };
    }

    pub fn deinit(self: *Session) void {
        self.client.deinit();
        self.cookies.deinit();
    }

    pub fn login(self: *Session, username: []const u8, password: []const u8) !bool {
        var request = try zig_net.Request.init(
            self.allocator,
            .POST,
            "https://httpbin.org/cookies/set?session=active",
        );
        defer request.deinit();

        _ = try request.setBasicAuth(username, password);

        const response = try self.client.send(&request);
        defer response.deinit();

        // Store session cookies
        if (response.getHeader("Set-Cookie")) |set_cookie| {
            try self.cookies.setCookie(set_cookie);
        }

        return response.isSuccess();
    }

    pub fn makeAuthenticatedRequest(self: *Session, url: []const u8) !zig_net.Response {
        var request = try zig_net.Request.init(self.allocator, .GET, url);
        errdefer request.deinit();

        // Add cookies to request
        const cookie_header = try self.cookies.getCookiesForRequest(
            self.allocator,
            url,
        );
        defer self.allocator.free(cookie_header);

        if (cookie_header.len > 0) {
            _ = try request.setHeader("Cookie", cookie_header);
        }

        const response = try self.client.send(&request);
        errdefer response.deinit();

        // Update cookies from response
        if (response.getHeader("Set-Cookie")) |set_cookie| {
            try self.cookies.setCookie(set_cookie);
        }

        request.deinit();
        return response;
    }
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var session = try Session.init(allocator);
    defer session.deinit();

    // Login
    if (try session.login("alice", "password123")) {
        std.debug.print("✓ Login successful\n", .{});

        // Make authenticated request
        const response = try session.makeAuthenticatedRequest(
            "https://httpbin.org/cookies",
        );
        defer response.deinit();

        std.debug.print("Response:\n{s}\n", .{response.getBody()});
    } else {
        std.debug.print("✗ Login failed\n", .{});
    }
}
```

### Example 4: Testing All HTTP Methods

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    std.debug.print("\n=== Testing All HTTP Methods ===\n\n", .{});

    // GET
    {
        std.debug.print("1. GET Request\n", .{});
        const response = try client.get("https://httpbin.org/get");
        defer response.deinit();
        std.debug.print("   Status: {d}\n\n", .{response.getStatus()});
    }

    // POST
    {
        std.debug.print("2. POST Request\n", .{});
        const response = try client.post(
            "https://httpbin.org/post",
            "{\"test\": true}",
            "application/json",
        );
        defer response.deinit();
        std.debug.print("   Status: {d}\n\n", .{response.getStatus()});
    }

    // PUT
    {
        std.debug.print("3. PUT Request\n", .{});
        const response = try client.put(
            "https://httpbin.org/put",
            "{\"updated\": true}",
            "application/json",
        );
        defer response.deinit();
        std.debug.print("   Status: {d}\n\n", .{response.getStatus()});
    }

    // DELETE
    {
        std.debug.print("4. DELETE Request\n", .{});
        const response = try client.delete("https://httpbin.org/delete");
        defer response.deinit();
        std.debug.print("   Status: {d}\n\n", .{response.getStatus()});
    }

    // PATCH
    {
        std.debug.print("5. PATCH Request\n", .{});
        var request = try zig_net.Request.init(
            allocator,
            .PATCH,
            "https://httpbin.org/patch",
        );
        defer request.deinit();

        _ = try request.setJsonBody("{\"patched\": true}");

        const response = try client.send(&request);
        defer response.deinit();
        std.debug.print("   Status: {d}\n\n", .{response.getStatus()});
    }

    std.debug.print("All HTTP methods tested successfully!\n", .{});
}
```

---

## Building and Running Examples

### Compile and Run

```bash
# Navigate to your project directory
cd your_project

# Build
zig build

# Run
zig build run

# Or build and run directly
zig run src/main.zig
```

### Run with Zig Cache

```bash
# If importing zig_net from local path
zig run src/main.zig --dep zig_net -Mzig_net=/path/to/zig_net/src/root.zig
```

---

## Quick Reference

### Client Methods

| Method | Description | Example |
|--------|-------------|---------|
| `init()` | Create new client | `var client = try Client.init(allocator, .{});` |
| `deinit()` | Free client resources | `client.deinit();` |
| `get()` | Simple GET request | `const r = try client.get(url);` |
| `post()` | Simple POST request | `const r = try client.post(url, body, ct);` |
| `put()` | Simple PUT request | `const r = try client.put(url, body, ct);` |
| `delete()` | Simple DELETE request | `const r = try client.delete(url);` |
| `send()` | Send custom request | `const r = try client.send(&request);` |

### Request Methods

| Method | Description | Example |
|--------|-------------|---------|
| `init()` | Create request | `var req = try Request.init(a, .GET, url);` |
| `deinit()` | Free request | `req.deinit();` |
| `setHeader()` | Add header | `_ = try req.setHeader("Key", "Value");` |
| `setBody()` | Set body | `_ = try req.setBody("data");` |
| `setJsonBody()` | Set JSON body | `_ = try req.setJsonBody("{}");` |
| `setFormBody()` | Set form data | `_ = try req.setFormBody(&form);` |
| `setBasicAuth()` | Basic auth | `_ = try req.setBasicAuth("u", "p");` |
| `setBearerToken()` | Bearer token | `_ = try req.setBearerToken("token");` |

### Response Methods

| Method | Description | Example |
|--------|-------------|---------|
| `deinit()` | Free response | `response.deinit();` |
| `getStatus()` | Get status code | `const s = response.getStatus();` |
| `getBody()` | Get body | `const b = response.getBody();` |
| `getHeader()` | Get header value | `const h = response.getHeader("Key");` |
| `getContentType()` | Get content type | `const ct = response.getContentType();` |
| `isSuccess()` | Check if 2xx | `if (response.isSuccess()) {}` |
| `isClientError()` | Check if 4xx | `if (response.isClientError()) {}` |
| `isServerError()` | Check if 5xx | `if (response.isServerError()) {}` |

---

## Additional Resources

- **httpbin.org endpoints**: https://httpbin.org/
- **zig_net GitHub**: https://github.com/TBick/zig_net
- **Zig Documentation**: https://ziglang.org/documentation/
- **HTTP Specifications**: https://httpwg.org/specs/

---

## Troubleshooting

### Common Issues

**Issue**: `error: InvalidUri`
- **Solution**: Make sure URLs start with `http://` or `https://`

**Issue**: Connection timeout
- **Solution**: Increase timeout or check network connectivity
  ```zig
  var client = try Client.init(allocator, .{ .timeout_ms = 60000 });
  ```

**Issue**: TLS/SSL errors
- **Solution**: Ensure certificates are valid and `verify_tls` is configured
  ```zig
  var client = try Client.init(allocator, .{ .verify_tls = true });
  ```

**Issue**: Too many redirects
- **Solution**: Increase max_redirects or check for redirect loops
  ```zig
  var client = try Client.init(allocator, .{ .max_redirects = 20 });
  ```

---

**Last Updated**: 2025-12-28
**zig_net Version**: 0.1.0-alpha
**Author**: zig_net contributors
