# zig_net - HTTP/HTTPS Client Library for Zig

> **AI-Optimized:** Production-ready HTTP/HTTPS client library for Zig 0.15.1+ with comprehensive documentation for AI assistant integration

## Quick Start (AI Summary)

**Purpose:** Full-featured HTTP/HTTPS client with TLS support, redirects, chunked encoding, authentication, cookies, and interceptors
**Zig Version:** 0.15.1+
**Dependencies:** None (uses Zig stdlib only)
**Status:** 🚧 In Development - Phase 5: Authentication & Cookie Management Complete
**Installation:** (Coming soon - package will be available via `zig fetch`)

## Current Development Status

### ✅ Phase 1: Foundation & Infrastructure (COMPLETE)
- Git repository initialized
- Directory structure created
- Custom error types defined (`src/errors.zig`)
- HTTP method enum implemented (`src/protocol/method.zig`)
- HTTP status utilities implemented (`src/protocol/status.zig`)
- Build system configured

### ✅ Phase 2: Core HTTP Client (COMPLETE)
- [x] Request builder implementation (src/client/Request.zig)
- [x] Response parser implementation (src/client/Response.zig)
- [x] Headers management (src/client/Headers.zig)
- [x] Client wrapper around std.http.Client (src/client/Client.zig)
- [x] Basic HTTP methods (GET, POST, PUT, DELETE, etc.)
- [x] Unit tests (34/34 passing)
- [x] Integration tests with httpbin.org (tests/integration/httpbin_test.zig)

### ✅ Phase 3: Advanced Features & HTTPS/TLS (COMPLETE)
- [x] Automatic redirect following with loop detection
- [x] Configurable redirect behavior (follow_redirects, max_redirects)
- [x] Redirect status code handling (301, 302, 303, 307, 308)
- [x] Timeout utilities and configuration
- [x] TLS verification configuration
- [x] Enhanced ClientOptions
- [x] Integration test framework with redirect tests
- [x] 41/41 tests passing

### ✅ Phase 4: Enhanced Features & Convenience Methods (COMPLETE)
- [x] Chunked transfer encoding support (RFC 7230 compliant)
- [x] HTTP protocol utilities (MIME types, URL encoding, Content-Type parsing)
- [x] Request convenience methods (setJsonBody, setFormBody)
- [x] Response enhancements (getContentType, getContentLength, isChunked)
- [x] Basic usage examples
- [x] Integration testing framework enabled
- [x] Compression support (automatic via std.http.Client)

### ✅ Phase 5: Authentication & Cookie Management (COMPLETE)
- [x] HTTP Authentication (Basic Auth RFC 7617, Bearer Token RFC 6750)
- [x] Request auth methods (setBasicAuth, setBearerToken)
- [x] Cookie Management (RFC 6265 compliant parsing)
- [x] Cookie attributes (Domain, Path, Expires, Max-Age, Secure, HttpOnly, SameSite)
- [x] CookieJar for cookie storage and management
- [x] Request/Response Interceptors (middleware pattern)
- [x] MetricsCollector for HTTP statistics
- [x] Integration tests for auth and cookies
- [x] Comprehensive examples (auth, cookies, interceptors)
- [x] 90+ tests passing

### 📋 Upcoming Phases
- **Phase 6:** Documentation & Packaging
- **Phase 7:** CI/CD & Release

## Architecture (5-Minute Overview)

### Design Philosophy

**Leverage Zig Standard Library:**
- Wraps `std.http.Client` (provides connection pooling, redirects)
- Wraps `std.crypto.tls.Client` (provides HTTPS/TLS)
- Adds convenience layer without reimplementing core functionality

**Memory Management:**
- Arena allocators for request-scoped memory
- Caller owns response body (must call `response.deinit()`)
- All tests use test allocator to detect leaks

**API Design:**
- Builder pattern for requests with method chaining
- Allocator-first parameter order (Zig convention)
- Comprehensive error handling with custom error types
- Both high-level convenience functions and low-level control

### Module Structure

```
src/
├── root.zig                 # Public API entry point ✅
├── errors.zig              # Custom error types ✅
├── timeout.zig             # Timeout utilities ✅
├── client/
│   ├── Client.zig          # HTTP/HTTPS client wrapper ✅
│   ├── Request.zig         # Request builder ✅
│   ├── Response.zig        # Response parser ✅
│   └── Headers.zig         # Header management ✅
├── protocol/
│   ├── method.zig          # HTTP method enum ✅
│   ├── status.zig          # Status code utilities ✅
│   └── http.zig            # HTTP/1.1 utilities ✅
├── encoding/
│   └── chunked.zig         # Chunked transfer encoding ✅
├── auth/
│   └── auth.zig            # Authentication (Basic, Bearer) ✅
├── cookies/
│   ├── Cookie.zig          # Cookie parsing (RFC 6265) ✅
│   └── CookieJar.zig       # Cookie storage & management ✅
└── interceptors/
    ├── interceptor.zig     # Request/Response interceptors ✅
    └── metrics.zig         # Metrics collector ✅
```

## Core Types

| Type | Purpose | Status | Key Methods |
|------|---------|--------|-------------|
| `Client` | HTTP/HTTPS client | ✅ Complete | `init()`, `get()`, `post()`, `put()`, `delete()`, `send()` |
| `Request` | Request builder | ✅ Complete | `setHeader()`, `setBody()`, `setBasicAuth()`, `setBearerToken()`, `setJsonBody()` |
| `Response` | Response accessor | ✅ Complete | `getStatus()`, `getHeader()`, `getBody()`, `isSuccess()`, `getContentType()` |
| `Method` | HTTP method enum | ✅ Complete | `toString()`, `fromString()`, `isSafe()`, `isIdempotent()` |
| `StatusCode` | Status code utilities | ✅ Complete | `isSuccess()`, `isError()`, `getReasonPhrase()` |
| `Error` | Custom error types | ✅ Complete | `mapStdError()`, `getErrorMessage()` |
| `Cookie` | HTTP cookie | ✅ Complete | `parse()`, `matchesDomain()`, `matchesPath()`, `isExpired()` |
| `CookieJar` | Cookie storage | ✅ Complete | `setCookie()`, `getCookie()`, `getCookiesForRequest()`, `removeExpired()` |
| `BasicAuth` | Basic authentication | ✅ Complete | `init()`, `toHeader()`, `encode()` |
| `BearerAuth` | Bearer token auth | ✅ Complete | `init()`, `toHeader()` |
| `MetricsCollector` | HTTP metrics | ✅ Complete | `recordRequest()`, `recordResponse()`, `getSuccessRate()`, `printStats()` |

## Usage Examples

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

    if (response.isSuccess()) {
        std.debug.print("Body: {s}\n", .{response.getBody()});
    }
}
```

### POST with JSON

```zig
var client = try zig_net.Client.init(allocator, .{});
defer client.deinit();

var request = try zig_net.Request.init(allocator, .POST, "https://httpbin.org/post");
defer request.deinit();

_ = try request.setJsonBody("{\"name\": \"Alice\", \"age\": 30}");

const response = try client.send(&request);
defer response.deinit();
```

### Authentication

```zig
var request = try zig_net.Request.init(allocator, .GET, "https://httpbin.org/basic-auth/user/passwd");
defer request.deinit();

// Basic Auth
_ = try request.setBasicAuth("user", "passwd");

// Or Bearer Token
// _ = try request.setBearerToken("your-token-here");

const response = try client.send(&request);
defer response.deinit();
```

### Cookie Management

```zig
var jar = zig_net.CookieJar.init(allocator);
defer jar.deinit();

// Store cookies from Set-Cookie headers
try jar.setCookie("session=abc123; Path=/; HttpOnly");

// Get cookies for a request
const cookies = try jar.getCookiesForRequest(allocator, "https://example.com/api");
defer allocator.free(cookies);

// Add to request
_ = try request.setHeader("Cookie", cookies);
```

### Full Control with Request Builder

```zig
var client = try zig_net.Client.init(allocator, .{
    .follow_redirects = true,
    .max_redirects = 10,
    .timeout_ms = 30000,
    .verify_tls = true,
});
defer client.deinit();

var request = try zig_net.Request.init(allocator, .POST, "https://api.example.com/data");
defer request.deinit();

_ = try request.setHeader("Content-Type", "application/json")
                .setHeader("User-Agent", "MyApp/1.0")
                .setBasicAuth("user", "password")
                .setJsonBody("{\"data\": \"value\"}");

const response = try client.send(&request);
defer response.deinit();

if (response.isSuccess()) {
    std.debug.print("Status: {d} {s}\n", .{
        response.getStatus(),
        response.getReasonPhrase()
    });
    std.debug.print("Body: {s}\n", .{response.getBody()});
}
```

### Metrics and Interceptors

```zig
var metrics = zig_net.MetricsCollector.init(allocator);
defer metrics.deinit();

for (urls) |url| {
    metrics.recordRequest();

    const response = try client.get(url);
    defer response.deinit();

    metrics.recordResponse(&response);

    // Optional: Use logging interceptor
    try zig_net.interceptor.loggingResponseInterceptor(&response);
}

metrics.printStats();
std.debug.print("Success Rate: {d:.1}%\n", .{metrics.getSuccessRate()});
```

## Installation (Coming Soon)

Once the library is ready for release, installation will be via Zig package manager:

```bash
# Add dependency to your project
zig fetch --save git+https://github.com/yourusername/zig_net#v0.1.0
```

Then in your `build.zig`:

```zig
const zig_net = b.dependency("zig_net", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("zig_net", zig_net.module("zig_net"));
```

## Error Handling

All errors are defined in `src/errors.zig` and categorized for clarity:

```zig
// Connection errors
ConnectionFailed, ConnectionTimeout, TlsHandshakeFailed, CertificateValidationFailed

// Protocol errors
InvalidHttpVersion, InvalidStatusCode, MalformedResponse, UnsupportedEncoding, InvalidHeaders

// Resource errors
OutOfMemory, BufferTooSmall

// Request errors
InvalidUri, InvalidMethod, InvalidRequestHeaders, InvalidRequestBody

// Redirect errors
TooManyRedirects, RedirectLoopDetected, InvalidRedirectLocation

// Timeout errors
ReadTimeout, WriteTimeout, RequestTimeout
```

Example error handling:

```zig
const response = zig_net.Client.get(allocator, uri) catch |err| {
    const msg = zig_net.errors.getErrorMessage(err);
    std.debug.print("Request failed: {s}\n", .{msg});
    return err;
};
```

## Current Features

### ✅ Implemented (Phase 5: Latest)
- **HTTP Authentication:**
  - Basic Authentication (RFC 7617) with base64 encoding
  - Bearer Token authentication (RFC 6750) for OAuth 2.0 and JWT
  - Convenient request methods: `setBasicAuth()`, `setBearerToken()`
  - Security documentation and best practices
- **Cookie Management:**
  - RFC 6265 compliant cookie parsing
  - Cookie attributes: Domain, Path, Expires, Max-Age, Secure, HttpOnly, SameSite
  - CookieJar for storage with domain/path matching
  - Automatic expiration handling
- **Request/Response Interceptors:**
  - Middleware pattern for request and response processing
  - Built-in logging interceptors
  - MetricsCollector for HTTP statistics
  - Custom interceptor support
- **Examples:** Comprehensive examples for auth, cookies, and interceptors
- **Integration Tests:** Live tests for authentication and cookie handling

### ✅ Implemented (Phase 4)
- **Chunked Encoding:** RFC 7230 compliant chunked transfer encoding decoder
- **HTTP Utilities:** MIME types, URL encoding/decoding, Content-Type parsing
- **Request Enhancements:** `setJsonBody()`, `setFormBody()` convenience methods
- **Response Enhancements:** `getContentType()`, `getContentLength()`, `isChunked()`
- **Compression:** Automatic via std.http.Client (gzip, deflate, zstd)

### ✅ Implemented (Phase 3)
- **Automatic Redirects:** Follows redirects with configurable limits and loop detection
- **Redirect Handling:** Proper handling of 301, 302, 303, 307, 308 status codes
- **Method Conversion:** Automatic method conversion for 303 redirects (to GET)
- **Timeout Utilities:** Deadline calculation and timeout management
- **Enhanced Options:** Configurable follow_redirects, max_redirects, timeout_ms, verify_tls
- **HTTPS Support:** Built-in via std.http.Client with configurable verification

### ✅ Implemented (Phase 2)
- **HTTP Client:** Full request/response abstraction layer wrapping std.http.Client
- **Headers Management:** Case-insensitive header handling with HashMap storage
- **Request Builder:** Fluent API with method chaining for building requests
- **Response Parser:** Convenient accessors for status, headers, and body

### ✅ Implemented (Phase 1: Foundation)
- **Error Handling:** Comprehensive error types with helpful messages
- **HTTP Methods:** All standard methods with safety/idempotency checks
- **Status Codes:** Complete status code utilities with classification helpers

### 📋 Planned
- **Documentation:** Enhanced API documentation and guides
- **Package Management:** Publish to Zig package manager
- **CI/CD:** Automated testing and release pipeline

## Documentation

Comprehensive documentation is available:

- **[API Reference](docs/api/API_REFERENCE.md)** - Complete API documentation with all types, methods, and signatures
- **[Usage Guide](docs/guides/USAGE_GUIDE.md)** - Comprehensive guide with examples and best practices
- **[Architecture](docs/architecture/ARCHITECTURE.md)** - Library design and implementation details
- **[Module Map](docs/architecture/MODULE_MAP.md)** - Quick reference for navigating the codebase
- **[Contributing](CONTRIBUTING.md)** - How to contribute to the project
- **[Changelog](CHANGELOG.md)** - Version history and changes
- **[Examples](examples/)** - Working code examples for common use cases

## For AI Agents

This library is designed with AI assistant integration as a primary use case. AI agents should:

1. **Read This First:** `README.md` (current file) - 5-minute overview
2. **API Reference:** `docs/api/API_REFERENCE.md` - Complete API documentation
3. **Usage Guide:** `docs/guides/USAGE_GUIDE.md` - How to use the library
4. **Navigate Code:** `docs/architecture/MODULE_MAP.md` - Quick file navigation
5. **Understand Design:** `docs/architecture/ARCHITECTURE.md` - Detailed architecture

### Development Process for AI Agents

**IMPORTANT:** When continuing development on this project:

1. **Always Create a Plan First:** Before starting any new phase, create a comprehensive plan that includes:
   - Components to implement
   - Implementation order
   - Success criteria
   - Testing strategy
   - Estimated scope

2. **Use TodoWrite Tool:** Track all tasks using the TodoWrite tool throughout implementation

3. **Follow Existing Patterns:** Match the code style, documentation format, and testing approach used in existing modules

4. **Comprehensive Testing:** Every feature must have unit tests, and integration tests where applicable

5. **Update Documentation:** README.md and inline doc comments must be updated for all changes

### AI Agent Quick Reference

**Finding Code:**
- Error definitions: `src/errors.zig`
- HTTP methods: `src/protocol/method.zig`
- Status codes: `src/protocol/status.zig`
- HTTP client: `src/client/Client.zig`
- Request builder: `src/client/Request.zig`
- Response parser: `src/client/Response.zig`
- Headers: `src/client/Headers.zig`
- Authentication: `src/auth/auth.zig`
- Cookies: `src/cookies/Cookie.zig`, `src/cookies/CookieJar.zig`
- Interceptors: `src/interceptors/interceptor.zig`
- Metrics: `src/interceptors/metrics.zig`
- Chunked encoding: `src/encoding/chunked.zig`
- Timeout utilities: `src/timeout.zig`

**Common Tasks:**
- Adding new error type → Edit `src/errors.zig`
- Adding HTTP method → Edit `src/protocol/method.zig`
- Testing → Add to `tests/unit/` or `tests/integration/`
- Examples → Add to `examples/`

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:

- Setting up your development environment
- Code style and documentation standards
- Submitting pull requests
- Running tests
- Reporting issues

All contributions must include appropriate tests and documentation.

## License

MIT License - see [LICENSE](LICENSE) file for details.

Copyright (c) 2025 zig_net contributors

## References

### Documentation & Specifications

- **[Zig Standard Library Documentation](https://ziglang.org/documentation/master/std/)** - Zig stdlib reference
- **[HTTP/1.1 Specification (RFC 7231)](https://tools.ietf.org/html/rfc7231)** - HTTP semantics
- **[HTTP Authentication: Basic Auth (RFC 7617)](https://tools.ietf.org/html/rfc7617)** - Basic authentication
- **[OAuth 2.0 Bearer Token (RFC 6750)](https://tools.ietf.org/html/rfc6750)** - Bearer token authentication
- **[HTTP State Management (RFC 6265)](https://tools.ietf.org/html/rfc6265)** - Cookie specification
- **[Chunked Transfer Encoding (RFC 7230)](https://tools.ietf.org/html/rfc7230)** - HTTP/1.1 transfer codings
- **[TLS 1.3 Specification (RFC 8446)](https://tools.ietf.org/html/rfc8446)** - Transport Layer Security

### Tools & Services

- **[httpbin.org](https://httpbin.org/)** - HTTP testing service used in integration tests
- **[Zig Package Manager](https://github.com/ziglang/zig/wiki/FAQ#package-manager)** - Package distribution

### Related Projects

- **[std.http](https://ziglang.org/documentation/master/std/#std.http)** - Zig's HTTP client (underlying implementation)
- **[std.crypto.tls](https://ziglang.org/documentation/master/std/#std.crypto.tls)** - Zig's TLS implementation

---

**Project Status:** 🚧 In Development - Phase 6 (Documentation & Packaging)
**Current Version:** 0.1.0-alpha
**Zig Version:** 0.15.1+
**Repository:** https://github.com/TBick/zig_net
**Last Updated:** 2025-12-28
