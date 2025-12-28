# zig_net Usage Guide

Complete guide to using the zig_net HTTP/HTTPS client library.

## Table of Contents

1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Making Requests](#making-requests)
4. [Handling Responses](#handling-responses)
5. [Authentication](#authentication)
6. [Cookie Management](#cookie-management)
7. [Interceptors & Middleware](#interceptors--middleware)
8. [Advanced Features](#advanced-features)
9. [Error Handling](#error-handling)
10. [Best Practices](#best-practices)

---

## Installation

### Adding to Your Project

Currently zig_net is in alpha. To use it:

1. **Clone the repository:**
   ```bash
   git clone https://github.com/TBick/zig_net.git
   ```

2. **Add to your `build.zig`:**
   ```zig
   const zig_net = b.dependency("zig_net", .{
       .target = target,
       .optimize = optimize,
   });
   exe.root_module.addImport("zig_net", zig_net.module("zig_net"));
   ```

3. **Import in your code:**
   ```zig
   const zig_net = @import("zig_net");
   ```

### Requirements

- **Zig 0.15.1 or later**
- **Internet connection** (for HTTPS/TLS and integration tests)

---

## Quick Start

### Simple GET Request

```zig
const std = @import("std");
const zig_net = @import("zig_net");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create client
    var client = try zig_net.Client.init(allocator, .{});
    defer client.deinit();

    // Make GET request
    const response = try client.get("https://httpbin.org/get");
    defer response.deinit();

    // Check result
    if (response.isSuccess()) {
        std.debug.print("Body: {s}\n", .{response.getBody()});
    }
}
```

### Simple POST Request

```zig
const response = try client.post(
    "https://httpbin.org/post",
    "{\"name\": \"Alice\"}",
    "application/json"
);
defer response.deinit();
```

---

## Making Requests

### HTTP Methods

#### GET - Retrieve Data

```zig
const response = try client.get("https://api.example.com/users");
defer response.deinit();
```

#### POST - Create Resource

```zig
const response = try client.post(
    "https://api.example.com/users",
    "{\"name\": \"Bob\", \"email\": \"bob@example.com\"}",
    "application/json"
);
defer response.deinit();
```

#### PUT - Update Resource

```zig
const response = try client.put(
    "https://api.example.com/users/123",
    "{\"name\": \"Robert\"}",
    "application/json"
);
defer response.deinit();
```

#### DELETE - Remove Resource

```zig
const response = try client.delete("https://api.example.com/users/123");
defer response.deinit();
```

### Custom Requests

For full control, use the Request builder:

```zig
var request = try zig_net.Request.init(allocator, .PATCH, "https://api.example.com/users/123");
defer request.deinit();

_ = try request.setHeader("Content-Type", "application/json")
                .setHeader("Accept", "application/json")
                .setHeader("User-Agent", "MyApp/1.0")
                .setBody("{\"status\": \"active\"}");

const response = try client.send(&request);
defer response.deinit();
```

### Request Headers

#### Setting Custom Headers

```zig
_ = try request.setHeader("X-API-Key", "secret-key-123");
_ = try request.setHeader("Accept-Language", "en-US");
```

#### Common Headers

```zig
// User Agent
_ = try request.setHeader("User-Agent", "MyApp/1.0");

// Accept
_ = try request.setHeader("Accept", "application/json");

// Custom Headers
_ = try request.setHeader("X-Request-ID", "abc-123");
```

### Request Body

#### JSON Body

```zig
_ = try request.setJsonBody("{\"name\": \"Alice\", \"age\": 30}");
// Automatically sets Content-Type: application/json
```

#### Form Data

```zig
var form_data = std.StringHashMap([]const u8).init(allocator);
defer form_data.deinit();

try form_data.put("username", "alice");
try form_data.put("email", "alice@example.com");

_ = try request.setFormBody(form_data);
// Automatically sets Content-Type: application/x-www-form-urlencoded
```

#### Plain Text Body

```zig
_ = try request.setBody("Plain text content")
                .setHeader("Content-Type", "text/plain");
```

---

## Handling Responses

### Response Status

```zig
const status = response.getStatus();
const reason = response.getReasonPhrase();

std.debug.print("Status: {d} {s}\n", .{status, reason});
```

### Response Classification

```zig
if (response.isSuccess()) {
    // 2xx status codes
    std.debug.print("Success!\n", .{});
} else if (response.isClientError()) {
    // 4xx status codes
    std.debug.print("Client error: {d}\n", .{response.getStatus()});
} else if (response.isServerError()) {
    // 5xx status codes
    std.debug.print("Server error: {d}\n", .{response.getStatus()});
} else if (response.isRedirection()) {
    // 3xx status codes (usually handled automatically)
    std.debug.print("Redirect\n", .{});
}
```

### Response Headers

```zig
// Get specific header
if (response.getHeader("Content-Type")) |content_type| {
    std.debug.print("Content-Type: {s}\n", .{content_type});
}

// Get Content-Type
if (response.getContentType()) |ct| {
    std.debug.print("Content-Type: {s}\n", .{ct});
}

// Get Content-Length
if (response.getContentLength()) |length| {
    std.debug.print("Content-Length: {d}\n", .{length});
}

// Parse Content-Type
if (try response.getParsedContentType(allocator)) |parsed| {
    defer allocator.free(parsed.mime_type);
    if (parsed.charset) |charset| {
        defer allocator.free(charset);
        std.debug.print("MIME: {s}, Charset: {s}\n", .{parsed.mime_type, charset});
    }
}
```

### Response Body

```zig
const body = response.getBody();
std.debug.print("Body:\n{s}\n", .{body});

// Body is valid until response.deinit() is called
```

---

## Authentication

### Basic Authentication

```zig
var request = try zig_net.Request.init(allocator, .GET, "https://api.example.com/protected");
defer request.deinit();

_ = try request.setBasicAuth("username", "password");

const response = try client.send(&request);
defer response.deinit();
```

**How it works:**
- Encodes `username:password` in Base64
- Sets `Authorization: Basic <encoded>` header
- Follows RFC 7617

### Bearer Token Authentication

```zig
var request = try zig_net.Request.init(allocator, .GET, "https://api.example.com/me");
defer request.deinit();

_ = try request.setBearerToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...");

const response = try client.send(&request);
defer response.deinit();
```

**How it works:**
- Sets `Authorization: Bearer <token>` header
- Commonly used with OAuth 2.0 and JWT
- Follows RFC 6750

### Custom Authentication

```zig
// Manual Authorization header
_ = try request.setHeader("Authorization", "Custom my-custom-token");

// Or use auth helpers
const basic = zig_net.BasicAuth.init("user", "pass");
const auth_header = try basic.toHeader(allocator);
defer allocator.free(auth_header);

_ = try request.setHeader("Authorization", auth_header);
```

### API Keys

```zig
// API key in header
_ = try request.setHeader("X-API-Key", "your-api-key-here");

// API key in query string (manual)
const url = "https://api.example.com/data?api_key=your-api-key";
const response = try client.get(url);
defer response.deinit();
```

---

## Cookie Management

### Parsing Cookies

```zig
// Parse a Set-Cookie header
var cookie = try zig_net.Cookie.parse(allocator, "session=abc123; Path=/; HttpOnly; Secure");
defer cookie.deinit(allocator);

std.debug.print("Name: {s}\n", .{cookie.name});
std.debug.print("Value: {s}\n", .{cookie.value});
std.debug.print("HttpOnly: {}\n", .{cookie.http_only});
```

### Using CookieJar

```zig
var jar = zig_net.CookieJar.init(allocator);
defer jar.deinit();

// Add cookies from Set-Cookie headers
try jar.setCookie("session=xyz123; Path=/; HttpOnly");
try jar.setCookie("user=alice; Domain=.example.com; Max-Age=3600");

// Get cookies for a request
const cookie_header = try jar.getCookiesForRequest(allocator, "https://example.com/api");
defer allocator.free(cookie_header);

// Use in request
var request = try zig_net.Request.init(allocator, .GET, "https://example.com/api");
defer request.deinit();

if (cookie_header.len > 0) {
    _ = try request.setHeader("Cookie", cookie_header);
}
```

### Cookie Attributes

```zig
// Secure (HTTPS only)
try jar.setCookie("token=secret; Secure");

// HttpOnly (not accessible to JavaScript)
try jar.setCookie("session=abc; HttpOnly");

// SameSite (CSRF protection)
try jar.setCookie("id=123; SameSite=Strict");
try jar.setCookie("tracking=xyz; SameSite=Lax");

// Max-Age (expiration in seconds)
try jar.setCookie("temp=value; Max-Age=3600"); // 1 hour

// Domain and Path
try jar.setCookie("pref=dark; Domain=.example.com; Path=/settings");
```

### Cookie Management

```zig
// Get a specific cookie
if (jar.getCookie("session")) |cookie| {
    std.debug.print("Session: {s}\n", .{cookie.value});
}

// Remove expired cookies
jar.removeExpired();

// Count cookies
std.debug.print("Total cookies: {d}\n", .{jar.count()});

// Clear all cookies
jar.clear();
```

---

## Interceptors & Middleware

### Request Interceptors

Modify requests before they're sent:

```zig
fn addTimestamp(request: *zig_net.Request) !void {
    const timestamp = std.time.timestamp();
    const timestamp_str = try std.fmt.allocPrint(
        request.allocator,
        "{d}",
        .{timestamp}
    );
    defer request.allocator.free(timestamp_str);

    _ = try request.setHeader("X-Timestamp", timestamp_str);
}

// Apply interceptor
try addTimestamp(&request);
```

### Response Interceptors

Process responses after they're received:

```zig
fn logResponse(response: *const zig_net.Response) !void {
    std.debug.print("Response: {d} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase()
    });
}

// Apply interceptor
try logResponse(&response);
```

### Built-in Interceptors

```zig
// Logging request
try zig_net.interceptor.loggingRequestInterceptor(&request);

// Logging response
try zig_net.interceptor.loggingResponseInterceptor(&response);
```

### Metrics Collection

```zig
var metrics = zig_net.MetricsCollector.init(allocator);
defer metrics.deinit();

// For each request
metrics.recordRequest();
const response = try client.get(url);
defer response.deinit();
metrics.recordResponse(&response);

// Print statistics
metrics.printStats();

// Get success rate
const success_rate = metrics.getSuccessRate();
std.debug.print("Success rate: {d:.1}%\n", .{success_rate});
```

---

## Advanced Features

### Redirects

Redirects are followed automatically by default:

```zig
var client = try zig_net.Client.init(allocator, .{
    .follow_redirects = true,  // Default: true
    .max_redirects = 10,       // Default: 10
});
defer client.deinit();

// This will follow redirects automatically
const response = try client.get("https://httpbin.org/redirect/3");
defer response.deinit();
```

Disable redirect following:

```zig
var client = try zig_net.Client.init(allocator, .{
    .follow_redirects = false,
});
defer client.deinit();

const response = try client.get("https://httpbin.org/redirect/1");
defer response.deinit();

if (response.isRedirection()) {
    if (response.getHeader("Location")) |location| {
        std.debug.print("Redirect to: {s}\n", .{location});
    }
}
```

### Timeouts

Set request timeout:

```zig
var client = try zig_net.Client.init(allocator, .{
    .timeout_ms = 5000,  // 5 seconds
});
defer client.deinit();
```

### TLS/HTTPS

TLS certificate verification is enabled by default:

```zig
var client = try zig_net.Client.init(allocator, .{
    .verify_tls = true,  // Default: true
});
defer client.deinit();
```

Disable verification (not recommended for production):

```zig
var client = try zig_net.Client.init(allocator, .{
    .verify_tls = false,  // Only for testing!
});
defer client.deinit();
```

### Chunked Transfer Encoding

Chunked responses are handled automatically:

```zig
const response = try client.get("https://httpbin.org/stream/20");
defer response.deinit();

if (response.isChunked()) {
    std.debug.print("Response uses chunked encoding\n", .{});
}

// Body is automatically decoded
const body = response.getBody();
```

---

## Error Handling

### Basic Error Handling

```zig
const response = client.get(url) catch |err| {
    std.debug.print("Request failed: {}\n", .{err});
    return err;
};
defer response.deinit();
```

### Detailed Error Handling

```zig
const response = client.get(url) catch |err| {
    const msg = zig_net.errors.getErrorMessage(err);
    std.debug.print("Error: {s}\n", .{msg});

    switch (err) {
        error.ConnectionTimeout => {
            std.debug.print("Connection timed out\n", .{});
        },
        error.TooManyRedirects => {
            std.debug.print("Too many redirects\n", .{});
        },
        error.InvalidUri => {
            std.debug.print("Invalid URL\n", .{});
        },
        else => {
            std.debug.print("Unknown error: {}\n", .{err});
        },
    }

    return err;
};
defer response.deinit();
```

### Error Categories

```zig
// Connection errors
error.ConnectionFailed
error.ConnectionTimeout
error.TlsHandshakeFailed
error.CertificateValidationFailed

// Protocol errors
error.InvalidHttpVersion
error.MalformedResponse
error.UnsupportedEncoding

// Request errors
error.InvalidUri
error.InvalidMethod
error.InvalidRequestBody

// Redirect errors
error.TooManyRedirects
error.RedirectLoopDetected
error.InvalidRedirectLocation

// Timeout errors
error.RequestTimeout
error.ReadTimeout
error.WriteTimeout
```

---

## Best Practices

### Memory Management

1. **Always defer cleanup:**
   ```zig
   const response = try client.get(url);
   defer response.deinit();  // Always clean up!
   ```

2. **Use appropriate allocators:**
   ```zig
   // For long-lived data: GPA
   var gpa = std.heap.GeneralPurposeAllocator(.{}){};
   const allocator = gpa.allocator();

   // For request-scoped data: Arena
   var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
   defer arena.deinit();
   const request_allocator = arena.allocator();
   ```

3. **Check for leaks in tests:**
   ```zig
   test "my test" {
       const allocator = std.testing.allocator;  // Detects leaks!
       // ... test code ...
   }
   ```

### Performance

1. **Reuse client instances:**
   ```zig
   // Good: Reuse client for multiple requests
   var client = try zig_net.Client.init(allocator, .{});
   defer client.deinit();

   for (urls) |url| {
       const response = try client.get(url);
       defer response.deinit();
       // Process response
   }
   ```

2. **Use appropriate timeouts:**
   ```zig
   var client = try zig_net.Client.init(allocator, .{
       .timeout_ms = 10000,  // Adjust based on your needs
   });
   ```

### Security

1. **Verify TLS certificates in production:**
   ```zig
   var client = try zig_net.Client.init(allocator, .{
       .verify_tls = true,  // Always true in production!
   });
   ```

2. **Never log sensitive data:**
   ```zig
   // Bad: Logs password
   std.debug.print("Auth: {s}:{s}\n", .{username, password});

   // Good: Don't log credentials
   std.debug.print("Authenticating user: {s}\n", .{username});
   ```

3. **Use HTTPS for sensitive data:**
   ```zig
   // Good
   const url = "https://api.example.com/users";

   // Bad for sensitive data
   const url = "http://api.example.com/users";
   ```

### Error Handling

1. **Handle errors appropriately:**
   ```zig
   const response = client.get(url) catch |err| {
       // Log error
       std.log.err("Request failed: {}", .{err});

       // Return or handle gracefully
       return err;
   };
   defer response.deinit();
   ```

2. **Check response status:**
   ```zig
   if (response.isSuccess()) {
       // Process successful response
   } else if (response.isClientError()) {
       // Handle 4xx errors
       std.log.warn("Client error: {d}", .{response.getStatus()});
   } else if (response.isServerError()) {
       // Handle 5xx errors - maybe retry
       std.log.err("Server error: {d}", .{response.getStatus()});
   }
   ```

### Testing

1. **Use integration tests sparingly:**
   ```zig
   // Comment out by default (requires network)
   test "API integration" {
       // const response = try client.get("https://api.example.com");
       // defer response.deinit();
   }
   ```

2. **Test error conditions:**
   ```zig
   test "invalid URL" {
       const allocator = std.testing.allocator;
       try std.testing.expectError(
           zig_net.Error.InvalidUri,
           zig_net.Request.init(allocator, .GET, "not-a-url")
       );
   }
   ```

---

## Common Patterns

### REST API Client

```zig
const ApiClient = struct {
    client: zig_net.Client,
    base_url: []const u8,
    api_key: []const u8,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, base_url: []const u8, api_key: []const u8) !ApiClient {
        return .{
            .client = try zig_net.Client.init(allocator, .{}),
            .base_url = base_url,
            .api_key = api_key,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *ApiClient) void {
        self.client.deinit();
    }

    pub fn getUser(self: *ApiClient, user_id: u32) !zig_net.Response {
        const url = try std.fmt.allocPrint(
            self.allocator,
            "{s}/users/{d}",
            .{self.base_url, user_id}
        );
        defer self.allocator.free(url);

        var request = try zig_net.Request.init(self.allocator, .GET, url);
        defer request.deinit();

        _ = try request.setHeader("X-API-Key", self.api_key);

        return try self.client.send(&request);
    }
};
```

### Retry Logic

```zig
fn requestWithRetry(client: *zig_net.Client, url: []const u8, max_retries: u32) !zig_net.Response {
    var attempts: u32 = 0;

    while (attempts < max_retries) : (attempts += 1) {
        const response = client.get(url) catch |err| {
            if (attempts + 1 < max_retries) {
                std.time.sleep(1_000_000_000); // 1 second
                continue;
            }
            return err;
        };

        if (response.isSuccess()) {
            return response;
        }

        response.deinit();

        if (attempts + 1 < max_retries) {
            std.time.sleep(1_000_000_000);
        }
    }

    return error.RequestFailed;
}
```

---

## Next Steps

- **[API Reference](../api/API_REFERENCE.md)** - Complete API documentation
- **[Examples](../../examples/)** - Working code examples
- **[Architecture](../architecture/ARCHITECTURE.md)** - Library design and internals
- **[Contributing](../../CONTRIBUTING.md)** - How to contribute

---

**Happy coding with zig_net!** 🚀
