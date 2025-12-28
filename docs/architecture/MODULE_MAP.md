# Module Map - AI Agent Quick Reference

> **Purpose:** Fast navigation guide for AI agents working with zig_net codebase

This document provides a quick reference for locating code, understanding file purposes, and finding the right place to make changes.

## Quick Reference Table

| File Path | Status | Purpose | Key Types/Functions | Modify When |
|-----------|--------|---------|---------------------|-------------|
| **Core API** |
| `src/root.zig` | ✅ Complete | Public API entry point | Exports all public types | Adding new public API |
| `src/errors.zig` | ✅ Complete | Error type definitions | `Error`, `ErrorSet`, `mapStdError()`, `getErrorMessage()` | Adding new error type |
| `src/timeout.zig` | ✅ Complete | Timeout utilities | Deadline calculation, expiration checking | Timeout features |
| **HTTP Client** |
| `src/client/Client.zig` | ✅ Complete | HTTP/HTTPS client | `Client`, `init()`, `get()`, `post()`, `send()` | Client behavior |
| `src/client/Request.zig` | ✅ Complete | Request builder | `Request`, `setHeader()`, `setBody()`, `setBasicAuth()` | Request building |
| `src/client/Response.zig` | ✅ Complete | Response parser | `Response`, `getStatus()`, `getBody()`, `isSuccess()` | Response parsing |
| `src/client/Headers.zig` | ✅ Complete | Header management | `Headers`, `get()`, `set()`, case-insensitive | Header handling |
| **Protocol** |
| `src/protocol/method.zig` | ✅ Complete | HTTP methods | `Method`, `toString()`, `fromString()`, `isSafe()`, `isIdempotent()` | Adding HTTP method |
| `src/protocol/status.zig` | ✅ Complete | Status codes | `StatusCode`, `isSuccess()`, `getReasonPhrase()` | Adding status code |
| `src/protocol/http.zig` | ✅ Complete | HTTP utilities | MIME types, URL encoding, Content-Type parsing | HTTP protocol utilities |
| **Encoding** |
| `src/encoding/chunked.zig` | ✅ Complete | Chunked encoding | RFC 7230 compliant decoder | Chunked transfer |
| **Authentication** |
| `src/auth/auth.zig` | ✅ Complete | HTTP Auth | `BasicAuth`, `BearerAuth`, `toHeader()` | Auth methods |
| **Cookies** |
| `src/cookies/Cookie.zig` | ✅ Complete | Cookie parsing | `Cookie`, `parse()`, `matchesDomain()`, RFC 6265 | Cookie features |
| `src/cookies/CookieJar.zig` | ✅ Complete | Cookie storage | `CookieJar`, `setCookie()`, `getCookiesForRequest()` | Cookie management |
| **Interceptors** |
| `src/interceptors/interceptor.zig` | ✅ Complete | Interceptor types | `RequestInterceptorFn`, `ResponseInterceptorFn`, logging | Interceptor features |
| `src/interceptors/metrics.zig` | ✅ Complete | Metrics collection | `MetricsCollector`, `recordResponse()`, statistics | Metrics features |
| **Build System** |
| `build.zig` | ✅ Complete | Build configuration | Module/executable setup | Adding modules/tests |
| `build.zig.zon` | ✅ v0.1.0-alpha | Package manifest | Dependencies, metadata, paths | Package metadata |

Legend: ✅ Complete | 🚧 In Progress | 📋 Planned

---

## Common Tasks - Where to Look

### "I want to add a new HTTP method (e.g., PROPFIND)"

1. **Edit:** `src/protocol/method.zig`
   - Add variant to `Method` enum
   - Update `toString()` function
   - Update `fromString()` function
   - Update `isSafe()` and `isIdempotent()` if applicable
   - Add test cases

2. **Update:** `src/root.zig` (if method needs special export)

### "I want to add a new error type"

1. **Edit:** `src/errors.zig`
   - Add variant to `Error` enum (with doc comment)
   - Add case to `getErrorMessage()` function
   - Add test case in bottom of file

2. **Use:** Return the new error from appropriate modules

### "I want to implement a new feature (e.g., proxy support)"

1. **Read:** `docs/architecture/ARCHITECTURE.md` - Understand design patterns
2. **Create:** New module under appropriate directory (`src/client/`, `src/protocol/`, etc.)
3. **Export:** Add to `src/root.zig` public API
4. **Test:** Add tests to `tests/unit/` or `tests/integration/`
5. **Document:** Add examples to `examples/` directory

### "I want to add a test"

**Unit test (single component):**
- **Add to:** `tests/unit/<component>_test.zig`
- **Import:** Module being tested
- **Use:** `std.testing.allocator` for leak detection

**Integration test (full workflow):**
- **Add to:** `tests/integration/<feature>_test.zig`
- **Test against:** httpbin.org or similar service
- **Cover:** Real HTTP/HTTPS requests

### "I want to add an example"

1. **Create:** `examples/<feature>_example.zig`
2. **Update:** `build.zig` to compile the example
3. **Reference:** From README.md
4. **Ensure:** Example is runnable and well-commented

### "I want to add authentication support"

1. **Look at:** `src/auth/auth.zig` - Basic and Bearer auth implementations
2. **Look at:** `src/client/Request.zig` - `setBasicAuth()` and `setBearerToken()` methods
3. **Add:** New auth type to `src/auth/auth.zig` if needed
4. **Test:** Add tests to verify auth header generation

### "I want to add cookie support"

1. **Look at:** `src/cookies/Cookie.zig` - Cookie parsing (RFC 6265)
2. **Look at:** `src/cookies/CookieJar.zig` - Cookie storage and management
3. **Modify:** Cookie attributes in `Cookie.zig`
4. **Modify:** Cookie matching logic in `CookieJar.zig`
5. **Test:** Ensure domain/path matching works correctly

### "I want to add request/response interceptors"

1. **Look at:** `src/interceptors/interceptor.zig` - Interceptor function types
2. **Create:** New interceptor function following `RequestInterceptorFn` or `ResponseInterceptorFn` signature
3. **Example:** See `loggingRequestInterceptor()` and `loggingResponseInterceptor()`
4. **Use:** Call interceptor before/after request/response

### "I want to collect HTTP metrics"

1. **Look at:** `src/interceptors/metrics.zig` - `MetricsCollector` implementation
2. **Use:** Initialize MetricsCollector, call `recordRequest()` and `recordResponse()`
3. **Extend:** Add new metrics to `MetricsCollector` struct
4. **Display:** Use `printStats()` or `getSuccessRate()`

### "I want to find where TLS is configured"

1. **Look at:** `src/client/Client.zig` - `ClientOptions.verify_tls`
2. **Look at:** Zig stdlib `std.http.Client` - Underlying TLS implementation
3. **Note:** TLS is handled automatically by `std.http.Client`

### "I want to understand error handling patterns"

1. **Read:** `src/errors.zig` - All error definitions
2. **Read:** `docs/architecture/ARCHITECTURE.md` - Error handling section
3. **Look at:** Existing code in `src/protocol/*.zig` for error usage patterns
4. **Use:** `errors.getErrorMessage()` for human-readable error messages

---

## Module Dependencies

### Dependency Graph

```
root.zig (public API)
    ├─→ errors.zig (no dependencies)
    ├─→ protocol/method.zig
    │       └─→ errors.zig
    ├─→ protocol/status.zig (no dependencies)
    ├─→ client/Client.zig (planned)
    │       ├─→ client/Request.zig
    │       ├─→ client/Response.zig
    │       ├─→ client/Headers.zig
    │       ├─→ tls/config.zig
    │       ├─→ protocol/method.zig
    │       ├─→ protocol/status.zig
    │       └─→ errors.zig
    ├─→ client/Request.zig (planned)
    │       ├─→ protocol/method.zig
    │       ├─→ client/Headers.zig
    │       └─→ errors.zig
    ├─→ client/Response.zig (planned)
    │       ├─→ protocol/status.zig
    │       ├─→ client/Headers.zig
    │       └─→ errors.zig
    ├─→ tls/config.zig (planned)
    │       └─→ errors.zig
    └─→ encoding/chunked.zig (planned)
            └─→ errors.zig
```

### Import Rules

1. **Bottom-up imports:** Low-level modules (errors, protocol) don't import high-level modules (client)
2. **No circular dependencies:** Module graph must be acyclic
3. **Explicit imports:** Always import modules explicitly, don't rely on transitive imports
4. **Public API:** Users only import `zig_net` (from root.zig), not internal modules

---

## File Templates

### New Error Type Template

```zig
// In src/errors.zig

pub const Error = error{
    // ... existing errors ...

    /// [One-line description of when this error occurs]
    /// [Additional context: causes, common scenarios, how to handle]
    YourNewError,
};

pub fn getErrorMessage(err: anyerror) []const u8 {
    return switch (err) {
        // ... existing cases ...
        Error.YourNewError => "Clear, actionable error message",
        else => "Unknown error",
    };
}

test "your new error" {
    const testing = std.testing;
    const msg = getErrorMessage(Error.YourNewError);
    try testing.expect(msg.len > 0);
}
```

### New Module Template

```zig
//! Module purpose and overview
//!
//! Detailed description of what this module does and when to use it.
//!
//! # Usage
//! ```zig
//! const module = @import("your_module.zig");
//! // Example usage
//! ```

const std = @import("std");
const errors = @import("../errors.zig");

/// Main type description
///
/// # Fields
/// - `field1`: Description
/// - `field2`: Description
///
/// # Example
/// ```zig
/// var instance = YourType.init();
/// defer instance.deinit();
/// ```
pub const YourType = struct {
    field1: u32,
    field2: []const u8,

    /// Initialize YourType
    ///
    /// # Parameters
    /// - `param1`: Description
    ///
    /// # Returns
    /// Returns initialized YourType
    ///
    /// # Errors
    /// - `Error.SomeError`: When this error occurs
    pub fn init(param1: u32) !YourType {
        return YourType{
            .field1 = param1,
            .field2 = "",
        };
    }

    /// Cleanup resources
    pub fn deinit(self: *YourType) void {
        // Cleanup code
    }
};

// Tests
test "YourType initialization" {
    const testing = std.testing;
    var instance = try YourType.init(42);
    defer instance.deinit();
    try testing.expectEqual(@as(u32, 42), instance.field1);
}
```

---

## Testing File Locations

### Unit Tests

| Component | Test File | What to Test |
|-----------|-----------|--------------|
| Error handling | `tests/unit/errors_test.zig` | Error mapping, messages |
| HTTP methods | `tests/unit/method_test.zig` | Method conversion, properties |
| Status codes | `tests/unit/status_test.zig` | Status classification |
| Client | `tests/unit/client_test.zig` | Client initialization, config |
| Request | `tests/unit/request_test.zig` | Request building, validation |
| Response | `tests/unit/response_test.zig` | Response parsing, accessors |
| Headers | `tests/unit/headers_test.zig` | Header storage, lookup |

### Integration Tests

| Feature | Test File | What to Test |
|---------|-----------|--------------|
| HTTP requests | `tests/integration/httpbin_test.zig` | All methods against httpbin.org |
| HTTPS requests | `tests/integration/https_test.zig` | TLS connections, cert validation |
| Redirects | `tests/integration/redirect_test.zig` | Redirect following, loops |
| Timeouts | `tests/integration/timeout_test.zig` | Timeout handling |
| Chunked encoding | `tests/integration/chunked_test.zig` | Chunked responses |

---

## Code Location by Feature

### Feature: HTTP Methods
- **Definition:** `src/protocol/method.zig`
- **Tests:** Built-in at bottom of `src/protocol/method.zig`
- **Usage:** Imported by `Client`, `Request`
- **Public API:** Exported from `src/root.zig`

### Feature: Status Codes
- **Definition:** `src/protocol/status.zig`
- **Tests:** Built-in at bottom of `src/protocol/status.zig`
- **Usage:** Imported by `Response`
- **Public API:** Exported from `src/root.zig`

### Feature: Error Handling
- **Definition:** `src/errors.zig`
- **Tests:** Built-in at bottom of `src/errors.zig`
- **Usage:** Imported by all modules
- **Public API:** Exported from `src/root.zig`

### Feature: HTTP Client (planned)
- **Definition:** `src/client/Client.zig`
- **Dependencies:** `Request`, `Response`, `Headers`, `TlsConfig`
- **Tests:** `tests/unit/client_test.zig`, `tests/integration/httpbin_test.zig`
- **Public API:** Exported from `src/root.zig`

### Feature: TLS/HTTPS (planned)
- **Configuration:** `src/tls/config.zig`
- **Certificates:** `src/tls/cert.zig`
- **Integration:** `src/client/Client.zig`
- **Tests:** `tests/integration/https_test.zig`

---

## Quick Navigation Commands

If you need to find something quickly:

**Find all error definitions:**
```bash
grep -r "Error\." src/
```

**Find all public API exports:**
```bash
grep "pub const" src/root.zig
```

**Find all test files:**
```bash
find tests/ -name "*_test.zig"
```

**Find where a type is defined:**
```bash
grep -r "pub const YourType" src/
```

**Find all TODOs:**
```bash
grep -r "TODO" src/
```

---

## AI Agent Workflow

### Initial Codebase Understanding
1. Read `README.md` (5-minute overview)
2. Read this file (`MODULE_MAP.md`) for navigation
3. Read `ARCHITECTURE.md` for design principles

### Making Changes
1. Use this file to find relevant module
2. Read the module file (includes doc comments)
3. Understand dependencies from dependency graph
4. Make changes following existing patterns
5. Add/update tests
6. Update documentation if needed

### Adding New Features
1. Determine appropriate module/directory
2. Create new module file using template
3. Add to dependency graph above
4. Export from `src/root.zig` if public
5. Add tests to `tests/`
6. Add example to `examples/`
7. Update this MODULE_MAP.md

---

**Last Updated:** 2025-12-26
**Status:** Phase 1 Complete
