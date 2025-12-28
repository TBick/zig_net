# zig_net API Reference

Complete API reference for the zig_net HTTP/HTTPS client library.

**Version:** 0.1.0-alpha
**Zig Version:** 0.15.1+

## Table of Contents

- [Client API](#client-api)
- [Request API](#request-api)
- [Response API](#response-api)
- [Headers API](#headers-api)
- [Authentication API](#authentication-api)
- [Cookie API](#cookie-api)
- [Interceptor API](#interceptor-api)
- [Protocol Utilities](#protocol-utilities)
- [Error Handling](#error-handling)

---

## Client API

### `Client`

HTTP/HTTPS client for making requests.

**Location:** `src/client/Client.zig`

#### Initialization

```zig
pub fn init(allocator: std.mem.Allocator, options: ClientOptions) !Client
```

Creates a new HTTP client with the specified options.

**Parameters:**
- `allocator`: Memory allocator
- `options`: Configuration options

**Returns:** Initialized Client instance

**Errors:** `OutOfMemory`

**Example:**
```zig
var client = try zig_net.Client.init(allocator, .{
    .follow_redirects = true,
    .max_redirects = 10,
    .timeout_ms = 30000,
    .verify_tls = true,
});
defer client.deinit();
```

#### Client Options

```zig
pub const ClientOptions = struct {
    follow_redirects: bool = true,
    max_redirects: u32 = 10,
    timeout_ms: u64 = 30000,
    verify_tls: bool = true,
};
```

**Fields:**
- `follow_redirects`: Enable automatic redirect following (default: true)
- `max_redirects`: Maximum number of redirects to follow (default: 10)
- `timeout_ms`: Request timeout in milliseconds (default: 30000)
- `verify_tls`: Verify TLS certificates (default: true)

#### Cleanup

```zig
pub fn deinit(self: *Client) void
```

Frees all resources associated with the client.

#### Convenience Methods

##### GET Request

```zig
pub fn get(self: *Client, uri: []const u8) !Response
```

Performs an HTTP GET request.

**Parameters:**
- `uri`: The URL to request

**Returns:** Response object

**Errors:** See [Error Handling](#error-handling)

**Example:**
```zig
const response = try client.get("https://httpbin.org/get");
defer response.deinit();
```

##### POST Request

```zig
pub fn post(self: *Client, uri: []const u8, body: []const u8, content_type: []const u8) !Response
```

Performs an HTTP POST request.

**Parameters:**
- `uri`: The URL to request
- `body`: Request body content
- `content_type`: Content-Type header value

**Returns:** Response object

**Example:**
```zig
const response = try client.post(
    "https://httpbin.org/post",
    "{\"key\": \"value\"}",
    "application/json"
);
defer response.deinit();
```

##### PUT Request

```zig
pub fn put(self: *Client, uri: []const u8, body: []const u8, content_type: []const u8) !Response
```

Performs an HTTP PUT request. Same signature as `post()`.

##### DELETE Request

```zig
pub fn delete(self: *Client, uri: []const u8) !Response
```

Performs an HTTP DELETE request. Same signature as `get()`.

##### Custom Request

```zig
pub fn send(self: *Client, request: *Request) !Response
```

Sends a custom request with full control over all parameters.

**Parameters:**
- `request`: Pointer to configured Request object

**Returns:** Response object

**Example:**
```zig
var request = try zig_net.Request.init(allocator, .GET, uri);
defer request.deinit();

_ = try request.setHeader("User-Agent", "MyApp/1.0");
_ = try request.setBasicAuth("user", "pass");

const response = try client.send(&request);
defer response.deinit();
```

---

## Request API

### `Request`

Builder for HTTP requests with method chaining support.

**Location:** `src/client/Request.zig`

#### Initialization

```zig
pub fn init(allocator: std.mem.Allocator, method: Method, uri: []const u8) !Request
```

Creates a new request builder.

**Parameters:**
- `allocator`: Memory allocator
- `method`: HTTP method (`.GET`, `.POST`, etc.)
- `uri`: Target URL (must start with `http://` or `https://`)

**Returns:** Request builder instance

**Errors:** `InvalidUri`, `OutOfMemory`

**Example:**
```zig
var request = try zig_net.Request.init(allocator, .POST, "https://api.example.com/data");
defer request.deinit();
```

#### Cleanup

```zig
pub fn deinit(self: *Request) void
```

Frees all resources associated with the request.

#### Setting Headers

```zig
pub fn setHeader(self: *Request, name: []const u8, value: []const u8) !*Request
```

Sets an HTTP header. Returns self for method chaining.

**Parameters:**
- `name`: Header name
- `value`: Header value

**Returns:** Self (for chaining)

**Example:**
```zig
_ = try request.setHeader("Content-Type", "application/json")
                .setHeader("Accept", "application/json");
```

#### Setting Request Body

```zig
pub fn setBody(self: *Request, body: []const u8) !*Request
```

Sets the request body content. Returns self for method chaining.

```zig
pub fn setJsonBody(self: *Request, json: []const u8) !*Request
```

Sets JSON body and Content-Type header automatically.

**Example:**
```zig
_ = try request.setJsonBody("{\"name\": \"Alice\", \"age\": 30}");
```

```zig
pub fn setFormBody(self: *Request, form_data: std.StringHashMap([]const u8)) !*Request
```

Sets form-encoded body and Content-Type header automatically.

**Example:**
```zig
var form_data = std.StringHashMap([]const u8).init(allocator);
defer form_data.deinit();
try form_data.put("username", "alice");
try form_data.put("password", "secret");

_ = try request.setFormBody(form_data);
```

#### Authentication

```zig
pub fn setBasicAuth(self: *Request, username: []const u8, password: []const u8) !*Request
```

Sets Basic Authentication header (RFC 7617).

**Parameters:**
- `username`: Username
- `password`: Password

**Returns:** Self (for chaining)

**Example:**
```zig
_ = try request.setBasicAuth("user", "password");
```

```zig
pub fn setBearerToken(self: *Request, token: []const u8) !*Request
```

Sets Bearer token authentication header (RFC 6750).

**Parameters:**
- `token`: Bearer token

**Returns:** Self (for chaining)

**Example:**
```zig
_ = try request.setBearerToken("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...");
```

#### Accessors

```zig
pub fn getMethod(self: *const Request) Method
pub fn getUri(self: *const Request) []const u8
pub fn getBody(self: *const Request) ?[]const u8
pub fn getHeader(self: *const Request, name: []const u8) ?[]const u8
```

---

## Response API

### `Response`

HTTP response accessor.

**Location:** `src/client/Response.zig`

#### Initialization

```zig
pub fn init(allocator: std.mem.Allocator, status: u16, headers: Headers, body: []u8) Response
```

Creates a response (typically called by Client, not user code).

#### Cleanup

```zig
pub fn deinit(self: *Response) void
```

Frees all resources associated with the response.

#### Status Code

```zig
pub fn getStatus(self: *const Response) u16
```

Returns the HTTP status code.

```zig
pub fn getReasonPhrase(self: *const Response) []const u8
```

Returns the HTTP reason phrase (e.g., "OK", "Not Found").

```zig
pub fn isSuccess(self: *const Response) bool
```

Returns true if status is 2xx.

```zig
pub fn isRedirection(self: *const Response) bool
```

Returns true if status is 3xx.

```zig
pub fn isClientError(self: *const Response) bool
```

Returns true if status is 4xx.

```zig
pub fn isServerError(self: *const Response) bool
```

Returns true if status is 5xx.

**Example:**
```zig
if (response.isSuccess()) {
    std.debug.print("Success! Body: {s}\n", .{response.getBody()});
} else if (response.isClientError()) {
    std.debug.print("Client error: {d} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase()
    });
}
```

#### Headers

```zig
pub fn getHeader(self: *const Response, name: []const u8) ?[]const u8
```

Returns header value or null if not present. Header lookup is case-insensitive.

```zig
pub fn getContentType(self: *const Response) ?[]const u8
```

Returns Content-Type header value or null.

```zig
pub fn getParsedContentType(self: *const Response, allocator: std.mem.Allocator) !?ParsedContentType
```

Parses Content-Type into MIME type and charset.

```zig
pub fn getContentLength(self: *const Response) ?usize
```

Returns Content-Length header value as integer or null.

```zig
pub fn isChunked(self: *const Response) bool
```

Returns true if response uses chunked transfer encoding.

#### Body

```zig
pub fn getBody(self: *const Response) []const u8
```

Returns the response body as a byte slice.

**Example:**
```zig
const body = response.getBody();
std.debug.print("Response: {s}\n", .{body});
```

---

## Headers API

### `Headers`

Case-insensitive HTTP header storage.

**Location:** `src/client/Headers.zig`

#### Initialization

```zig
pub fn init(allocator: std.mem.Allocator) Headers
```

Creates a new headers container.

#### Cleanup

```zig
pub fn deinit(self: *Headers) void
```

Frees all resources.

#### Operations

```zig
pub fn set(self: *Headers, name: []const u8, value: []const u8) !void
```

Sets a header value (case-insensitive).

```zig
pub fn get(self: *const Headers, name: []const u8) ?[]const u8
```

Gets a header value (case-insensitive). Returns null if not found.

```zig
pub fn remove(self: *Headers, name: []const u8) bool
```

Removes a header. Returns true if header was removed.

```zig
pub fn contains(self: *const Headers, name: []const u8) bool
```

Checks if header exists (case-insensitive).

```zig
pub fn count(self: *const Headers) usize
```

Returns number of headers.

---

## Authentication API

### `BasicAuth`

Basic Authentication (RFC 7617)

**Location:** `src/auth/auth.zig`

#### Initialization

```zig
pub fn init(username: []const u8, password: []const u8) BasicAuth
```

Creates a Basic Auth instance.

#### Generate Header

```zig
pub fn toHeader(self: *const BasicAuth, allocator: std.mem.Allocator) ![]u8
```

Generates the Authorization header value.

**Returns:** String like `"Basic dXNlcjpwYXNz"` (caller must free)

**Example:**
```zig
const basic = zig_net.BasicAuth.init("user", "password");
const header = try basic.toHeader(allocator);
defer allocator.free(header);
```

#### Encode Credentials

```zig
pub fn encode(self: *const BasicAuth, allocator: std.mem.Allocator) ![]u8
```

Base64-encodes the credentials.

### `BearerAuth`

Bearer Token Authentication (RFC 6750)

**Location:** `src/auth/auth.zig`

#### Initialization

```zig
pub fn init(token: []const u8) BearerAuth
```

Creates a Bearer Auth instance.

#### Generate Header

```zig
pub fn toHeader(self: *const BearerAuth, allocator: std.mem.Allocator) ![]u8
```

Generates the Authorization header value.

**Returns:** String like `"Bearer eyJhbGc..."` (caller must free)

**Example:**
```zig
const bearer = zig_net.BearerAuth.init("my-token");
const header = try bearer.toHeader(allocator);
defer allocator.free(header);
```

---

## Cookie API

### `Cookie`

HTTP cookie (RFC 6265)

**Location:** `src/cookies/Cookie.zig`

#### Fields

```zig
name: []u8,
value: []u8,
domain: ?[]u8,
path: ?[]u8,
expires: ?i64,
max_age: ?i64,
secure: bool,
http_only: bool,
same_site: ?SameSite,
```

#### SameSite Enum

```zig
pub const SameSite = enum {
    strict,
    lax,
    none,
};
```

#### Parsing

```zig
pub fn parse(allocator: std.mem.Allocator, set_cookie_value: []const u8) !Cookie
```

Parses a Set-Cookie header value into a Cookie struct.

**Example:**
```zig
var cookie = try zig_net.Cookie.parse(allocator, "session=abc; Path=/; HttpOnly");
defer cookie.deinit(allocator);
```

#### Cleanup

```zig
pub fn deinit(self: *Cookie, allocator: std.mem.Allocator) void
```

#### Matching

```zig
pub fn matchesDomain(self: *const Cookie, request_domain: []const u8) bool
```

Checks if cookie matches the request domain.

```zig
pub fn matchesPath(self: *const Cookie, request_path: []const u8) bool
```

Checks if cookie matches the request path.

#### Expiration

```zig
pub fn isExpired(self: *const Cookie) bool
```

Checks if cookie has expired based on Max-Age or Expires.

#### Serialization

```zig
pub fn toString(self: *const Cookie, allocator: std.mem.Allocator) ![]u8
```

Converts cookie to "name=value" format for Cookie header.

### `CookieJar`

Cookie storage and management

**Location:** `src/cookies/CookieJar.zig`

#### Initialization

```zig
pub fn init(allocator: std.mem.Allocator) CookieJar
```

#### Cleanup

```zig
pub fn deinit(self: *CookieJar) void
```

#### Managing Cookies

```zig
pub fn setCookie(self: *CookieJar, set_cookie_value: []const u8) !void
```

Parses and stores a cookie from a Set-Cookie header. Automatically replaces duplicates.

```zig
pub fn getCookie(self: *CookieJar, name: []const u8) ?*const Cookie
```

Retrieves a cookie by name. Returns null if not found or expired.

```zig
pub fn getCookiesForRequest(self: *CookieJar, allocator: std.mem.Allocator, uri: []const u8) ![]u8
```

Returns a Cookie header value with all matching cookies for the given URI.

**Example:**
```zig
var jar = zig_net.CookieJar.init(allocator);
defer jar.deinit();

try jar.setCookie("session=abc; Path=/");
try jar.setCookie("user=alice; Domain=.example.com");

const cookies = try jar.getCookiesForRequest(allocator, "https://example.com/api");
defer allocator.free(cookies);
// cookies = "session=abc; user=alice"
```

#### Cleanup

```zig
pub fn removeExpired(self: *CookieJar) void
```

Removes all expired cookies from the jar.

```zig
pub fn clear(self: *CookieJar) void
```

Removes all cookies from the jar.

```zig
pub fn count(self: *const CookieJar) usize
```

Returns the number of cookies in the jar.

---

## Interceptor API

### RequestInterceptorFn

Function type for request interceptors.

**Location:** `src/interceptors/interceptor.zig`

```zig
pub const RequestInterceptorFn = *const fn (request: *Request) anyerror!void;
```

**Example:**
```zig
fn myRequestInterceptor(request: *zig_net.Request) !void {
    _ = try request.setHeader("X-Custom", "value");
    std.debug.print("Request: {s}\n", .{request.getUri()});
}
```

### ResponseInterceptorFn

Function type for response interceptors.

```zig
pub const ResponseInterceptorFn = *const fn (response: *const Response) anyerror!void;
```

**Example:**
```zig
fn myResponseInterceptor(response: *const zig_net.Response) !void {
    std.debug.print("Status: {d}\n", .{response.getStatus()});
}
```

### Built-in Interceptors

```zig
pub fn loggingRequestInterceptor(request: *Request) !void
```

Logs request method and URI to stderr.

```zig
pub fn loggingResponseInterceptor(response: *const Response) !void
```

Logs response status code to stderr.

### MetricsCollector

HTTP statistics collector.

**Location:** `src/interceptors/metrics.zig`

#### Fields

```zig
allocator: std.mem.Allocator,
total_requests: usize,
total_responses: usize,
success_count: usize,
error_count: usize,
total_bytes_received: usize,
```

#### Initialization

```zig
pub fn init(allocator: std.mem.Allocator) MetricsCollector
```

#### Cleanup

```zig
pub fn deinit(self: *MetricsCollector) void
```

#### Recording

```zig
pub fn recordRequest(self: *MetricsCollector) void
```

Increments request counter.

```zig
pub fn recordResponse(self: *MetricsCollector, response: *const Response) void
```

Records response statistics (status, size).

#### Statistics

```zig
pub fn getSuccessRate(self: *const MetricsCollector) f64
```

Returns success rate as percentage (0-100).

```zig
pub fn printStats(self: *const MetricsCollector) void
```

Prints statistics to stderr.

**Example:**
```zig
var metrics = zig_net.MetricsCollector.init(allocator);
defer metrics.deinit();

metrics.recordRequest();
const response = try client.get(url);
defer response.deinit();
metrics.recordResponse(&response);

metrics.printStats();
```

---

## Protocol Utilities

### Method Enum

**Location:** `src/protocol/method.zig`

```zig
pub const Method = enum {
    GET,
    POST,
    PUT,
    DELETE,
    PATCH,
    HEAD,
    OPTIONS,
    TRACE,
    CONNECT,

    pub fn toString(self: Method) []const u8
    pub fn fromString(str: []const u8) !Method
    pub fn isSafe(self: Method) bool
    pub fn isIdempotent(self: Method) bool
    pub fn hasRequestBody(self: Method) bool
    pub fn hasResponseBody(self: Method) bool
};
```

### Status Code Utilities

**Location:** `src/protocol/status.zig`

```zig
pub fn getReasonPhrase(status: u16) []const u8
pub fn isSuccess(status: u16) bool
pub fn isRedirection(status: u16) bool
pub fn isClientError(status: u16) bool
pub fn isServerError(status: u16) bool
```

### HTTP Utilities

**Location:** `src/protocol/http.zig`

#### MIME Types

```zig
pub const MIME_JSON = "application/json";
pub const MIME_FORM_URLENCODED = "application/x-www-form-urlencoded";
pub const MIME_TEXT_PLAIN = "text/plain";
pub const MIME_TEXT_HTML = "text/html";
pub const MIME_OCTET_STREAM = "application/octet-stream";
```

#### URL Encoding

```zig
pub fn urlEncode(allocator: std.mem.Allocator, input: []const u8) ![]u8
pub fn urlDecode(allocator: std.mem.Allocator, input: []const u8) ![]u8
```

#### Content-Type Parsing

```zig
pub const ParsedContentType = struct {
    mime_type: []const u8,
    charset: ?[]const u8,
};

pub fn parseContentType(allocator: std.mem.Allocator, content_type: []const u8) !ParsedContentType
```

---

## Error Handling

### Error Set

**Location:** `src/errors.zig`

All zig_net errors are defined in a single error set:

```zig
pub const Error = error{
    // Connection errors
    ConnectionFailed,
    ConnectionTimeout,
    TlsHandshakeFailed,
    CertificateValidationFailed,

    // Protocol errors
    InvalidHttpVersion,
    InvalidStatusCode,
    MalformedResponse,
    UnsupportedEncoding,
    InvalidHeaders,

    // Resource errors
    OutOfMemory,
    BufferTooSmall,

    // Request errors
    InvalidUri,
    InvalidMethod,
    InvalidRequestHeaders,
    InvalidRequestBody,

    // Redirect errors
    TooManyRedirects,
    RedirectLoopDetected,
    InvalidRedirectLocation,

    // Timeout errors
    ReadTimeout,
    WriteTimeout,
    RequestTimeout,
    TimeoutError,
};
```

### Error Messages

```zig
pub fn getErrorMessage(err: anyerror) []const u8
```

Returns a human-readable error message.

**Example:**
```zig
const response = client.get(url) catch |err| {
    const msg = zig_net.errors.getErrorMessage(err);
    std.debug.print("Request failed: {s}\n", .{msg});
    return err;
};
```

### Error Mapping

```zig
pub fn mapStdError(err: anyerror) Error
```

Maps standard library errors to zig_net errors.

---

## Complete Example

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

    // Create request
    var request = try zig_net.Request.init(allocator, .POST, "https://httpbin.org/post");
    defer request.deinit();

    // Configure request
    _ = try request.setJsonBody("{\"message\": \"Hello\"}")
                    .setHeader("User-Agent", "zig_net/0.1.0")
                    .setBasicAuth("user", "password");

    // Send request
    const response = try client.send(&request);
    defer response.deinit();

    // Handle response
    if (response.isSuccess()) {
        std.debug.print("Success! Body:\n{s}\n", .{response.getBody()});
    } else {
        std.debug.print("Error: {d} {s}\n", .{
            response.getStatus(),
            response.getReasonPhrase()
        });
    }
}
```

---

**End of API Reference**

For more information, see:
- [Usage Guide](../guides/USAGE_GUIDE.md)
- [Examples](../../examples/)
- [CHANGELOG](../../CHANGELOG.md)
