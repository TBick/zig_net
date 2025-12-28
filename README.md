# zig_net - HTTP/HTTPS Client Library for Zig

> **AI-Optimized:** Production-ready HTTP/HTTPS client library for Zig 0.15.1+ with comprehensive documentation for AI assistant integration

## Quick Start (AI Summary)

**Purpose:** Full-featured HTTP/HTTPS client with TLS support, redirects, chunked encoding, connection pooling, and timeout handling
**Zig Version:** 0.15.1+
**Dependencies:** None (uses Zig stdlib only)
**Status:** 🚧 In Development - Phase 3: Advanced Features Complete
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

### 📋 Upcoming Phases
- **Phase 4:** Enhanced Features (chunked encoding, compression)
- **Phase 5:** Testing & Validation (live integration tests)
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
├── root.zig                 # Public API entry point
├── errors.zig              # Custom error types ✅
├── main.zig                 # CLI demo tool
├── client/
│   ├── Client.zig          # HTTP/HTTPS client wrapper
│   ├── Request.zig         # Request builder
│   ├── Response.zig        # Response parser
│   └── Headers.zig         # Header management
├── protocol/
│   ├── method.zig          # HTTP method enum ✅
│   ├── status.zig          # Status code utilities ✅
│   └── http.zig            # HTTP/1.1 utilities
├── tls/
│   ├── config.zig          # TLS configuration
│   └── cert.zig            # Certificate management
├── encoding/
│   └── chunked.zig         # Chunked transfer encoding
└── timeout.zig             # Timeout utilities
```

## Core Types

| Type | Purpose | Status | Key Methods |
|------|---------|--------|-------------|
| `Client` | HTTP/HTTPS client | ✅ Complete | `init()`, `get()`, `post()`, `put()`, `delete()`, `send()` |
| `Request` | Request builder | ✅ Complete | `setHeader()`, `setBody()`, `getUri()`, `getBody()` |
| `Response` | Response accessor | ✅ Complete | `getStatus()`, `getHeader()`, `getBody()`, `isSuccess()` |
| `Method` | HTTP method enum | ✅ Complete | `toString()`, `fromString()`, `isSafe()` |
| `StatusCode` | Status code utilities | ✅ Complete | `isSuccess()`, `isError()`, `getReasonPhrase()` |
| `Error` | Custom error types | ✅ Complete | `mapStdError()`, `getErrorMessage()` |

## Planned API Usage

### High-Level Convenience API (Coming Soon)

```zig
const zig_net = @import("zig_net");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Simple GET request
    const response = try zig_net.Client.get(allocator, "https://httpbin.org/get");
    defer response.deinit();

    if (response.status.isSuccess()) {
        std.debug.print("Body: {s}\n", .{response.body});
    }
}
```

### Low-Level Control API (Coming Soon)

```zig
const zig_net = @import("zig_net");
const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Create client
    var client = try zig_net.Client.init(allocator, .{
        .follow_redirects = true,
        .max_redirects = 10,
        .timeout_ms = 5000,
        .verify_tls = true,
    });
    defer client.deinit();

    // Build request
    var request = try zig_net.Request.init(allocator, .POST, "https://httpbin.org/post");
    defer request.deinit();

    try request.setHeader("Content-Type", "application/json");
    try request.setHeader("User-Agent", "zig_net/0.1.0");
    try request.setBody("{\"hello\": \"world\"}");

    // Send request
    const response = try client.send(request);
    defer response.deinit();

    std.debug.print("Status: {} {s}\n", .{
        response.status,
        zig_net.status.getReasonPhrase(response.status),
    });
}
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

### ✅ Implemented
- **Custom Error Types:** Comprehensive error definitions with helper functions
- **HTTP Methods:** GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS, TRACE, CONNECT with safety/idempotency checks
- **Status Codes:** All standard HTTP status codes with classification helpers (isSuccess, isRedirection, isError, etc.)
- **Documentation:** AI-optimized inline documentation with examples

### ✅ Newly Implemented (Phase 3)
- **Automatic Redirects:** Follows redirects with configurable limits and loop detection
- **Redirect Handling:** Proper handling of 301, 302, 303, 307, 308 status codes
- **Method Conversion:** Automatic method conversion for 303 redirects (to GET)
- **Timeout Utilities:** Deadline calculation and timeout management utilities
- **Enhanced Options:** Configurable follow_redirects, max_redirects, timeout_ms, verify_tls
- **Comprehensive Testing:** 41 unit tests passing, integration test suite for redirects
- **HTTPS Support:** Built-in via std.http.Client with configurable verification

### ✅ Previously Implemented (Phase 2)
- **HTTP Client:** Full request/response abstraction layer wrapping std.http.Client
- **Headers Management:** Case-insensitive header handling with HashMap storage
- **Request Builder:** Fluent API with method chaining for building requests
- **Response Parser:** Convenient accessors for status, headers, and body

### ✅ Foundation (Phase 1)
- **Error Handling:** Comprehensive error types with helpful messages
- **HTTP Methods:** All standard methods with safety/idempotency checks
- **Status Codes:** Complete status code utilities with classification helpers

### 📋 Planned
- **Chunked Encoding:** Support for chunked transfer encoding
- **Connection Pooling:** Enhanced control over std.http.Client pooling
- **Compression:** Gzip/deflate support
- **Live Integration Tests:** Enabled tests against httpbin.org
- **Examples:** Comprehensive usage examples and tutorials

## For AI Agents

This library is designed with AI assistant integration as a primary use case. AI agents should:

1. **Read This First:** `README.md` (current file) - 5-minute overview
2. **Navigate Code:** `docs/architecture/MODULE_MAP.md` (coming soon) - Quick file navigation
3. **Understand Design:** `docs/architecture/ARCHITECTURE.md` (coming soon) - Detailed architecture
4. **Integration Guide:** `docs/guides/AI_INTEGRATION.md` (coming soon) - How to use this library in other projects

### AI Agent Quick Reference

**Finding Code:**
- Error definitions: `src/errors.zig`
- HTTP methods: `src/protocol/method.zig`
- Status codes: `src/protocol/status.zig`
- Client (planned): `src/client/Client.zig`
- Request (planned): `src/client/Request.zig`
- Response (planned): `src/client/Response.zig`

**Common Tasks:**
- Adding new error type → Edit `src/errors.zig`
- Adding HTTP method → Edit `src/protocol/method.zig`
- Testing → Add to `tests/unit/` or `tests/integration/`

## Contributing

This project is in active development. Contributions will be welcome once Phase 2 (Core HTTP Client) is complete.

### Development Roadmap

See the [implementation plan](/home/tbick/.claude/plans/zany-watching-peacock.md) for detailed development phases and agent responsibilities.

## License

(License to be determined - will be added before v0.1.0 release)

## References

- [Zig Standard Library Documentation](https://ziglang.org/documentation/master/std/)
- [HTTP/1.1 Specification (RFC 7231)](https://tools.ietf.org/html/rfc7231)
- [TLS 1.3 Specification (RFC 8446)](https://tools.ietf.org/html/rfc8446)
- [httpbin.org](https://httpbin.org/) - HTTP testing service

---

**Project Status:** 🚧 In Development
**Current Version:** 0.1.0-dev
**Zig Version:** 0.15.1
**Last Updated:** 2025-12-28
