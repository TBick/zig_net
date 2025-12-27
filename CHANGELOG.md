# Changelog

All notable changes to the zig_net HTTP/HTTPS client library will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### In Progress
- Phase 2: Core HTTP Client implementation
  - Request builder with method chaining
  - Response parser with convenient accessors
  - Headers management (case-insensitive)
  - Client wrapper around std.http.Client
  - Basic HTTP methods (GET, POST, PUT, DELETE, etc.)
  - Unit and integration tests

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
