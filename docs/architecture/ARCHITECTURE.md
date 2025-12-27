# zig_net Architecture

> **Purpose:** Detailed architecture documentation for AI agents and developers

This document explains the design decisions, module organization, and architectural patterns used in the zig_net HTTP/HTTPS client library.

## Table of Contents

1. [Design Philosophy](#design-philosophy)
2. [Module Organization](#module-organization)
3. [Data Flow](#data-flow)
4. [Memory Management Strategy](#memory-management-strategy)
5. [Error Handling Architecture](#error-handling-architecture)
6. [Design Decisions](#design-decisions)
7. [Extension Points](#extension-points)

---

## Design Philosophy

### Principle 1: Leverage, Don't Reimplement

**Rationale:** Zig 0.15.1 includes a mature `std.http.Client` and `std.crypto.tls.Client` that provide the core functionality we need. Rather than reimplementing HTTP and TLS from scratch, we wrap these components to provide:

- Simplified API for common use cases
- Better error messages with context
- Convenience functions (builder patterns, method chaining)
- Additional features (configurable timeouts, redirect limits)

**Implementation:**
- `src/client/Client.zig` wraps `std.http.Client`
- `src/tls/config.zig` wraps `std.crypto.tls.Client` configuration
- Public API provides both high-level convenience and low-level control

### Principle 2: Memory Safety by Default

**Rationale:** Zig's manual memory management requires explicit allocator handling. Our architecture ensures:

- No hidden allocations
- Clear ownership semantics
- Leak detection via test allocators
- Arena allocators for request-scoped cleanup

**Implementation:**
- All public functions take explicit allocator parameters (allocator-first convention)
- Response bodies are caller-owned (must call `response.deinit()`)
- Request-scoped data uses arena allocators
- All tests use `std.testing.allocator` to detect leaks

### Principle 3: AI-First Documentation

**Rationale:** This library is designed to be easily understood and used by AI coding assistants. Documentation should:

- Be structured and parseable (markdown tables, code blocks)
- Explain "why" not just "what"
- Provide quick reference sections
- Include searchable keywords
- Cross-reference related components

**Implementation:**
- Comprehensive doc comments with examples in all source files
- MODULE_MAP.md for quick AI navigation
- Error messages include context and solutions
- Consistent naming conventions

### Principle 4: Composable and Testable

**Rationale:** Each component should be independently testable and composable.

**Implementation:**
- Small, focused modules with single responsibilities
- Protocol utilities (method, status) independent of client
- Unit tests for each component
- Integration tests for end-to-end workflows
- Test utilities for common testing patterns

---

## Module Organization

### Core Modules

```
src/
├── root.zig                 # Public API surface
├── errors.zig              # Error type definitions ✅
└── main.zig                 # CLI demo tool
```

**`root.zig`:** Public API entry point
- Exports all public types and functions
- Provides convenience functions (get, post, etc.)
- Single import point for library users

**`errors.zig`:** Error type definitions ✅
- Custom error types for all failure modes
- Error mapping from stdlib errors
- Human-readable error messages
- See [Error Handling Architecture](#error-handling-architecture)

**`main.zig`:** CLI demo and testing tool
- Demonstrates library usage
- Manual testing against real endpoints
- Not part of library API

### Client Layer

```
src/client/
├── Client.zig              # HTTP/HTTPS client wrapper
├── Request.zig             # Request builder
├── Response.zig            # Response parser
└── Headers.zig             # Header management
```

**`Client.zig`:** Main HTTP/HTTPS client
- Wraps `std.http.Client`
- Manages connection pooling
- Handles HTTP/HTTPS scheme detection
- Orchestrates request/response lifecycle

**`Request.zig`:** Request builder
- Builder pattern with method chaining
- Validates request parameters
- Constructs HTTP request from components
- Example: `request.setHeader("User-Agent", "zig_net").setBody("data")`

**`Response.zig`:** Response parser and accessor
- Parses HTTP response
- Provides convenient accessors (status, headers, body)
- Handles chunked encoding
- Owns response body (caller must deinit)

**`Headers.zig`:** HTTP header management
- Case-insensitive header lookups
- Header validation
- Common header constants
- Header serialization

### Protocol Layer

```
src/protocol/
├── method.zig              # HTTP method enum ✅
├── status.zig              # Status code utilities ✅
└── http.zig                # HTTP/1.1 protocol utilities
```

**`method.zig`:** HTTP methods ✅
- Enum for all HTTP methods (GET, POST, etc.)
- String conversion (toString, fromString)
- Semantic properties (isSafe, isIdempotent)
- Request/response body expectations

**`status.zig`:** Status code utilities ✅
- Status code constants (200, 404, 500, etc.)
- Classification helpers (isSuccess, isRedirection, isError)
- Reason phrase lookup
- Standard status code definitions

**`http.zig`:** HTTP/1.1 utilities (planned)
- HTTP version handling
- Protocol-level constants
- Request/response validation

### TLS Layer

```
src/tls/
├── config.zig              # TLS configuration
└── cert.zig                # Certificate management
```

**`config.zig`:** TLS configuration
- Wraps `std.crypto.tls.Client` configuration
- TLS version preferences (prefer 1.3 over 1.2)
- Cipher suite configuration
- Certificate validation settings

**`cert.zig`:** Certificate management
- System certificate store integration
- Custom certificate bundles
- Certificate validation
- Trust anchor management

### Encoding Layer

```
src/encoding/
└── chunked.zig             # Chunked transfer encoding
```

**`chunked.zig`:** Chunked transfer encoding
- Encode data in chunked format (for requests)
- Decode chunked responses
- Handle chunk extensions
- Trailer header support

### Utilities

```
src/timeout.zig             # Timeout management
```

**`timeout.zig`:** Timeout utilities
- Request timeout wrapper
- Read/write timeout handling
- Timeout error mapping
- Deadline calculation

---

## Data Flow

### HTTP GET Request Flow

```
User Code
    ↓ calls
Client.get(allocator, "https://example.com/api")
    ↓ creates
Request { method: .GET, uri: "https://example.com/api" }
    ↓ detects HTTPS scheme
TlsConfig (certificate validation, TLS 1.3)
    ↓ wraps
std.http.Client (connection pooling)
    ↓ establishes
TLS Connection
    ↓ sends
HTTP Request ("GET /api HTTP/1.1\r\nHost: example.com\r\n\r\n")
    ↓ receives
HTTP Response ("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n\r\n{...}")
    ↓ parses
Response { status: 200, headers: {...}, body: "{...}" }
    ↓ returns to
User Code
    ↓ processes and calls
response.deinit() (cleanup)
```

### HTTP POST Request Flow (with body)

```
User Code
    ↓ creates
Request.init(allocator, .POST, "https://example.com/api")
    ↓ configures
request.setHeader("Content-Type", "application/json")
request.setBody("{\"key\": \"value\"}")
    ↓ sends via
Client.send(request)
    ↓ serializes
HTTP Request with body
    ↓ sends to
Server (via TLS connection)
    ↓ receives
HTTP Response
    ↓ returns
Response
```

### Redirect Flow

```
Client.get(allocator, "https://example.com/old")
    ↓ receives
Response { status: 301, headers: { "Location": "/new" } }
    ↓ checks
isRedirection(301) == true
    ↓ increments redirect count
redirect_count++
    ↓ follows Location header
GET "https://example.com/new"
    ↓ receives
Response { status: 200, ... }
    ↓ returns final response
```

---

## Memory Management Strategy

### Allocation Patterns

1. **Client-Level Allocations**
   - Client structure: Uses provided allocator
   - Connection pool: Managed by std.http.Client
   - Lifetime: Until `client.deinit()`

2. **Request-Level Allocations**
   - Use arena allocator for temporary data
   - All request-scoped allocations freed at once
   - Pattern:
     ```zig
     var arena = std.heap.ArenaAllocator.init(base_allocator);
     defer arena.deinit();
     const request_allocator = arena.allocator();
     // All request building uses request_allocator
     ```

3. **Response-Level Allocations**
   - Response body: Caller-owned (uses provided allocator)
   - Response headers: Caller-owned
   - Caller must call `response.deinit()` to free
   - Pattern:
     ```zig
     const response = try client.get(allocator, uri);
     defer response.deinit();
     // Use response
     ```

### Ownership Rules

| Component | Owner | Lifetime | Cleanup |
|-----------|-------|----------|---------|
| Client | User code | Until `client.deinit()` | Manual |
| Request (builder) | User code | Until request sent | Automatic (arena) |
| Response | User code | Until `response.deinit()` | Manual |
| Response body | User code | Until `response.deinit()` | Manual |
| Request temp data | Request scope | End of request | Automatic (arena) |

### Leak Detection

All tests use `std.testing.allocator`:
```zig
test "no memory leaks" {
    const allocator = std.testing.allocator;

    var client = try Client.init(allocator, null);
    defer client.deinit();

    const response = try client.get(allocator, "https://httpbin.org/get");
    defer response.deinit();

    // std.testing.allocator will fail the test if any leaks detected
}
```

---

## Error Handling Architecture

### Error Type Hierarchy

```
anyerror
    ↓ subset
ErrorSet (all possible errors)
    ↓ includes
Error (custom zig_net errors)
    ↓ includes
std.mem.Allocator.Error
std.fs.File.OpenError
std.fs.File.ReadError
(and other stdlib errors)
```

### Error Categories

**1. Connection Errors:** Network-level failures
- `ConnectionFailed`: TCP connection failed
- `ConnectionTimeout`: Connection attempt timed out
- `TlsHandshakeFailed`: TLS negotiation failed
- `CertificateValidationFailed`: Certificate invalid

**2. Protocol Errors:** HTTP protocol violations
- `InvalidHttpVersion`: Unsupported HTTP version
- `InvalidStatusCode`: Malformed status code
- `MalformedResponse`: Response violates HTTP spec
- `UnsupportedEncoding`: Unsupported compression/encoding
- `InvalidHeaders`: Malformed headers

**3. Resource Errors:** Memory/buffer issues
- `OutOfMemory`: Allocation failed
- `BufferTooSmall`: Buffer cannot hold data

**4. Request Errors:** Invalid request parameters
- `InvalidUri`: URI malformed or unsupported scheme
- `InvalidMethod`: Unrecognized HTTP method
- `InvalidRequestHeaders`: Request headers malformed
- `InvalidRequestBody`: Request body invalid

**5. Redirect Errors:** Redirect handling failures
- `TooManyRedirects`: Exceeded redirect limit
- `RedirectLoopDetected`: Circular redirects
- `InvalidRedirectLocation`: Location header missing/invalid

**6. Timeout Errors:** Operation timeouts
- `ReadTimeout`: Read operation timed out
- `WriteTimeout`: Write operation timed out
- `RequestTimeout`: Overall request timed out

### Error Mapping Strategy

Standard library errors are mapped to zig_net errors for better context:

```zig
std.net errors          →  zig_net errors
────────────────────────────────────────────
ConnectionRefused       →  ConnectionFailed
NetworkUnreachable      →  ConnectionFailed
ConnectionResetByPeer   →  ConnectionFailed
BrokenPipe              →  ConnectionFailed
Timeout                 →  ConnectionTimeout
OutOfMemory             →  OutOfMemory
```

This is implemented in `errors.mapStdError()`.

### Error Handling Pattern

**In library code:**
```zig
pub fn doSomething() !void {
    std.net.connect(...) catch |err| {
        return errors.mapStdError(err);
    };
}
```

**In user code:**
```zig
const response = client.get(allocator, uri) catch |err| {
    const msg = zig_net.errors.getErrorMessage(err);
    std.debug.print("Error: {s}\n", .{msg});
    return err;
};
```

---

## Design Decisions

### Why Wrap std.http.Client Instead of Reimplementing?

**Decision:** Wrap `std.http.Client` rather than implement HTTP from scratch

**Rationale:**
- `std.http.Client` is mature, tested, and maintained
- Provides connection pooling, redirect handling, compression
- Follows Zig stdlib conventions
- Avoids bug-prone protocol implementation
- Allows us to focus on developer experience

**Trade-offs:**
- ✅ Faster development
- ✅ Better stability (stdlib is well-tested)
- ✅ Automatic improvements from Zig updates
- ❌ Less control over low-level behavior
- ❌ Tied to stdlib API changes

### Why Caller-Owned Response Body?

**Decision:** Response body is owned by caller (must call `response.deinit()`)

**Rationale:**
- Clear ownership semantics
- No hidden allocations
- Caller controls lifetime
- Allows streaming in future (caller manages buffer)

**Trade-offs:**
- ✅ Explicit memory management
- ✅ No hidden costs
- ✅ Flexible for different use cases
- ❌ User must remember to call deinit()
- ❌ More verbose than auto-cleanup

### Why Arena Allocators for Request Scope?

**Decision:** Use arena allocators for request-scoped temporary data

**Rationale:**
- Simplifies cleanup (single deinit for all request data)
- Reduces allocation overhead
- Prevents leaks in error paths
- Common pattern in Zig

**Trade-offs:**
- ✅ Simpler error handling
- ✅ No per-allocation tracking
- ✅ Better performance (fewer allocations)
- ❌ Memory not freed until request complete
- ❌ Potential for larger memory usage in long requests

### Why Prefer TLS 1.3 Over TLS 1.2?

**Decision:** Default to TLS 1.3, allow TLS 1.2 as fallback

**Rationale:**
- TLS 1.3 has better security
- TLS 1.2 has known issues in Zig stdlib
- Industry trend toward TLS 1.3
- Most servers support TLS 1.3

**Trade-offs:**
- ✅ Better security
- ✅ Better performance (fewer round trips)
- ✅ More stable in Zig
- ❌ Some legacy servers only support TLS 1.2
- ❌ May fail on old systems

---

## Extension Points

### Adding Custom Headers

Users can add headers via the Request builder:

```zig
var request = try Request.init(allocator, .GET, uri);
try request.setHeader("Authorization", "Bearer token123");
try request.setHeader("X-Custom-Header", "value");
```

### Adding Custom Error Types

To add new error types:

1. Add to `Error` enum in `src/errors.zig`
2. Add case to `getErrorMessage()` function
3. Update documentation
4. Add test case

### Adding New HTTP Methods

To add a new HTTP method:

1. Add to `Method` enum in `src/protocol/method.zig`
2. Add case to `toString()` function
3. Add case to `fromString()` function
4. Update `isSafe()` and `isIdempotent()` if needed
5. Add test cases

### Adding Custom TLS Configuration

Users can configure TLS via Client config:

```zig
var client = try Client.init(allocator, .{
    .tls_config = .{
        .verify_certificates = true,
        .min_tls_version = .tls_1_3,
        .ca_bundle = try loadCustomCertificates(),
    },
});
```

---

## Testing Strategy

### Unit Tests

Each module has its own unit tests:
- `src/errors.zig` → tests error mapping and messages
- `src/protocol/method.zig` → tests method conversion and properties
- `src/protocol/status.zig` → tests status classification
- `src/client/Client.zig` → tests client behavior (with mocks if needed)

### Integration Tests

Integration tests use real HTTP services:
- `tests/integration/httpbin_test.zig` → tests against httpbin.org
- Tests all HTTP methods, status codes, headers, redirects
- Tests HTTPS with real TLS connections

### Test Patterns

**Memory leak testing:**
```zig
test "no leaks" {
    const allocator = std.testing.allocator;
    // All allocations tracked
    var client = try Client.init(allocator, null);
    defer client.deinit();
    // Test will fail if leaks detected
}
```

**Error testing:**
```zig
test "handles connection failure" {
    const allocator = std.testing.allocator;
    try std.testing.expectError(
        Error.ConnectionFailed,
        Client.get(allocator, "https://invalid.invalid")
    );
}
```

---

## References

- [Zig Style Guide](https://ziglang.org/documentation/master/#Style-Guide)
- [Zig Standard Library](https://ziglang.org/documentation/master/std/)
- [HTTP/1.1 Specification (RFC 7231)](https://tools.ietf.org/html/rfc7231)
- [TLS 1.3 Specification (RFC 8446)](https://tools.ietf.org/html/rfc8446)

---

**Last Updated:** 2025-12-26
**Status:** Phase 1 Complete
