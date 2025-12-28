# Changelog

All notable changes to the zig_net HTTP/HTTPS client library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - Phase 4: Enhanced Features & Convenience Methods ✅
- Chunked Transfer Encoding Support (`src/encoding/chunked.zig`)
  - RFC 7230 compliant chunked decoder
  - Handles chunk extensions and trailer headers
  - Automatic integration with Client for chunked responses
  - Comprehensive test suite (11 tests)

- HTTP Protocol Utilities (`src/protocol/http.zig`)
  - HTTP version enum (HTTP/1.0, HTTP/1.1, HTTP/2)
  - MIME type constants (JSON, form-urlencoded, text/plain, etc.)
  - Content-Type header parsing with charset extraction
  - URL encoding/decoding (RFC 3986 compliant)
  - User-Agent string constant

- Request Enhancements
  - `setJsonBody()` - Convenience method for JSON requests
  - `setFormBody()` - Automatic form data encoding
  - Method chaining support for all builder methods

- Response Enhancements
  - `getContentType()` - Extract Content-Type header
  - `getParsedContentType()` - Parse MIME type and charset
  - `getContentLength()` - Get content length from headers
  - `isChunked()` - Check if response uses chunked encoding

- Examples
  - Basic usage examples (`examples/basic_usage.zig`)
  - Five example patterns: GET, POST JSON, custom headers, error handling, form data

- Integration Testing
  - Enabled live integration tests with httpbin.org
  - GET and POST request tests
  - Framework ready for comprehensive integration testing

### Added - Phase 3: Advanced Client Features ✅
- Automatic Redirect Following
  - Configurable redirect following (enabled by default)
  - Max redirects limit (default: 10)
  - Redirect loop detection using visited URL tracking
  - Proper handling of redirect status codes:
    - 301 Moved Permanently
    - 302 Found
    - 303 See Other (always converts to GET)
    - 307 Temporary Redirect
    - 308 Permanent Redirect
  - Relative and absolute URL resolution

- Client Configuration
  - `ClientOptions` struct for fine-grained control
  - `follow_redirects` - Enable/disable redirect following
  - `max_redirects` - Limit redirect chains
  - `timeout_ms` - Request timeout in milliseconds (default: 30s)
  - `verify_tls` - TLS certificate verification control

- Timeout Management (`src/timeout.zig`)
  - Deadline calculation utilities
  - Timeout expiration checking
  - Remaining time calculations
  - Full test coverage

- Error Handling
  - `TooManyRedirects` - Exceeded max redirect limit
  - `RedirectLoopDetected` - Circular redirect detection
  - `InvalidRedirectLocation` - Missing or invalid Location header
  - `TimeoutError` - Request timeout errors

### Added - Phase 2: Core HTTP Client Implementation ✅
- Request Builder (`src/client/Request.zig`)
  - Builder pattern with method chaining
  - URI validation (http:// and https://)
  - Header management
  - Body support with memory ownership
  - Comprehensive test suite

- Response Parser (`src/client/Response.zig`)
  - Status code accessors
  - Headers management
  - Body accessors
  - Status classification methods (`isSuccess()`, `isRedirection()`, etc.)
  - Reason phrase lookup

- Headers Management (`src/client/Headers.zig`)
  - Case-insensitive header lookups
  - Efficient storage using StringHashMap
  - Header iteration support
  - Duplicate header handling

- HTTP/HTTPS Client (`src/client/Client.zig`)
  - Wrapper around std.http.Client
  - Connection pooling via std.http.Client
  - Convenience methods: `get()`, `post()`, `put()`, `delete()`
  - Full control via `send()` with Request objects
  - Automatic chunked encoding handling

- Integration Testing Framework
  - httpbin.org integration tests
  - Tests for all HTTP methods
  - Redirect testing
  - Custom header testing
  - Error status code testing

## [0.1.0-dev] - 2025-12-26

### Added - Phase 1: Foundation & Infrastructure ✅
- Project structure and build system
  - Zig package manifest (build.zig.zon) configured for v0.1.0
  - Complete directory structure for modular organization
  - Git repository initialized with .gitignore
  - MIT License

- Error handling system (`src/errors.zig`)
  - Comprehensive error type definitions
  - Error categories: Connection, Protocol, Resource, Request, Redirect, Timeout
  - Error mapping from stdlib errors
  - Human-readable error messages
  - `mapStdError()` for error context
  - `getErrorMessage()` for error descriptions

- HTTP Protocol support
  - HTTP method enum (`src/protocol/method.zig`)
    - All standard HTTP methods: GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS, TRACE, CONNECT
    - Method properties: `isSafe()`, `isIdempotent()`, `hasRequestBody()`, `hasResponseBody()`
    - String conversion: `toString()`, `fromString()`
  - HTTP status code utilities (`src/protocol/status.zig`)
    - All standard status code constants (1xx-5xx)
    - Status classification: `isSuccess()`, `isRedirection()`, `isClientError()`, `isServerError()`
    - Reason phrase lookup: `getReasonPhrase()`

- Documentation (AI-First)
  - README.md with AI-optimized structure
  - Architecture documentation (docs/architecture/ARCHITECTURE.md)
    - Design philosophy and principles
    - Module organization and data flow
    - Memory management strategy
    - Error handling architecture
    - Design decisions with rationale
  - Module map (docs/architecture/MODULE_MAP.md)
    - Quick reference table for all files
    - Common task navigation guide
    - Module dependency graph
    - File templates for consistent development

### Development Infrastructure
- Build system configured (build.zig, build.zig.zon)
- Directory structure created:
  - src/client/ - Client components (planned)
  - src/protocol/ - Protocol utilities
  - src/tls/ - TLS/HTTPS support (planned)
  - src/encoding/ - Encoding handlers (planned)
  - tests/unit/ - Unit tests
  - tests/integration/ - Integration tests
  - examples/ - Usage examples
  - docs/architecture/ - Architecture docs
  - docs/api/ - API documentation (planned)
  - docs/guides/ - User guides (planned)
  - .github/workflows/ - CI/CD (planned)

### Testing
- Unit tests for error handling
- Unit tests for HTTP methods
- Unit tests for status codes
- Test infrastructure ready for integration tests

---

## Version History

### [0.1.0] - Target Release
**Goal:** Production-ready HTTP/HTTPS client library

**Planned Features:**
- Full HTTP/1.1 support
- HTTPS with TLS 1.2/1.3
- HTTP redirects with loop detection
- Chunked transfer encoding
- Connection pooling
- Timeout handling
- Comprehensive test suite
- CI/CD pipeline
- Package published via Zig package manager

---

## Versioning Strategy

- **0.1.0-dev:** Development version (current)
- **0.1.0:** First stable release
- **0.2.0:** HTTP/2 support (future)
- **0.3.0:** WebSocket support (future)
- **1.0.0:** Stable API, production-ready

---

## Links

- [Repository](https://github.com/tbick/zig_net) (to be created)
- [Issue Tracker](https://github.com/tbick/zig_net/issues) (to be created)
- [Zig Package Manager](https://ziglang.org/download/) (for installation)
