# Phase 5: Production Features & Polish

## Overview
Phase 5 focuses on production-ready features that make zig_net suitable for real-world applications. This includes compression support, authentication helpers, cookie management, and request/response interceptors.

## Goals
- Add compression support (gzip, deflate) for efficient data transfer
- Implement authentication helpers for common patterns (Basic Auth, Bearer tokens)
- Add cookie management for session-based APIs
- Implement request/response interceptors for middleware functionality
- Expand integration test coverage
- Ensure production readiness

## Feature Breakdown

### 1. Compression Support (`src/encoding/compression.zig`)

**Purpose:** Handle compressed HTTP responses automatically

**Features:**
- Gzip decompression (RFC 1952)
- Deflate decompression (RFC 1951)
- Automatic decompression based on Content-Encoding header
- Accept-Encoding header management in requests
- Configurable compression support in ClientOptions

**API Design:**
```zig
pub const CompressionType = enum {
    none,
    gzip,
    deflate,
};

pub fn decompress(allocator: Allocator, data: []const u8, compression: CompressionType) ![]u8;
pub fn supportsCompression(compression_type: CompressionType) bool;
```

**Integration:**
- Client checks Content-Encoding header in responses
- Automatically decompresses if compression is detected
- Request builder can set Accept-Encoding header

**Tests:**
- Gzip compression/decompression roundtrip
- Deflate compression/decompression roundtrip
- Mixed content (compressed and uncompressed)
- Malformed compressed data handling
- Integration test with compressed httpbin response

**Implementation Notes:**
- Use Zig's std.compress.gzip and std.compress.deflate
- Handle edge cases like partial compression
- Error handling for corrupted compressed data

---

### 2. Authentication Helpers (`src/auth/`)

**Purpose:** Simplify common authentication patterns

**Modules:**
- `src/auth/basic.zig` - HTTP Basic Authentication
- `src/auth/bearer.zig` - Bearer token authentication
- `src/auth/auth.zig` - Main auth module

**Features:**

#### Basic Authentication
```zig
pub const BasicAuth = struct {
    username: []const u8,
    password: []const u8,

    pub fn init(username: []const u8, password: []const u8) BasicAuth;
    pub fn encode(self: BasicAuth, allocator: Allocator) ![]u8;
    pub fn applyToRequest(self: BasicAuth, request: *Request) !void;
};
```

#### Bearer Token Authentication
```zig
pub const BearerAuth = struct {
    token: []const u8,

    pub fn init(token: []const u8) BearerAuth;
    pub fn applyToRequest(self: BearerAuth, request: *Request) !void;
};
```

**Request Integration:**
```zig
// In Request.zig
pub fn setBasicAuth(self: *Request, username: []const u8, password: []const u8) !*Request;
pub fn setBearerToken(self: *Request, token: []const u8) !*Request;
```

**Tests:**
- Basic auth encoding (base64)
- Bearer token header formatting
- Integration test with httpbin.org/basic-auth
- Integration test with httpbin.org/bearer

**Implementation Notes:**
- Basic Auth: base64 encode "username:password"
- Bearer: "Bearer {token}" in Authorization header
- Memory management for encoded credentials

---

### 3. Cookie Management (`src/cookies/`)

**Purpose:** Handle HTTP cookies for session management

**Modules:**
- `src/cookies/Cookie.zig` - Individual cookie
- `src/cookies/CookieJar.zig` - Cookie storage and management

**Features:**

#### Cookie Structure
```zig
pub const Cookie = struct {
    name: []const u8,
    value: []const u8,
    domain: ?[]const u8,
    path: ?[]const u8,
    expires: ?i64, // Unix timestamp
    max_age: ?i64,
    secure: bool,
    http_only: bool,
    same_site: ?SameSite,

    pub const SameSite = enum { strict, lax, none };

    pub fn parse(allocator: Allocator, cookie_str: []const u8) !Cookie;
    pub fn toString(self: *const Cookie, allocator: Allocator) ![]u8;
};
```

#### Cookie Jar
```zig
pub const CookieJar = struct {
    allocator: Allocator,
    cookies: std.StringHashMap(Cookie),

    pub fn init(allocator: Allocator) CookieJar;
    pub fn deinit(self: *CookieJar) void;

    pub fn addCookie(self: *CookieJar, cookie: Cookie) !void;
    pub fn getCookie(self: *CookieJar, name: []const u8) ?*const Cookie;
    pub fn getCookiesForRequest(self: *CookieJar, uri: []const u8) ![]Cookie;
    pub fn updateFromResponse(self: *CookieJar, response: *const Response) !void;
    pub fn isExpired(cookie: *const Cookie) bool;
};
```

**Client Integration:**
```zig
// In ClientOptions
cookie_jar: ?*CookieJar = null,

// In Client.send()
// - Add cookies from jar to request
// - Update jar from Set-Cookie headers in response
```

**Tests:**
- Cookie parsing (various formats)
- Cookie expiration logic
- Domain and path matching
- Cookie jar storage and retrieval
- Integration test with httpbin.org/cookies

**Implementation Notes:**
- RFC 6265 compliance
- Handle multiple Set-Cookie headers
- Proper domain and path matching
- Expiration handling

---

### 4. Request/Response Interceptors (`src/interceptors/`)

**Purpose:** Allow middleware-style processing of requests and responses

**Design:**
```zig
pub const RequestInterceptor = struct {
    context: ?*anyopaque,
    interceptFn: *const fn(context: ?*anyopaque, request: *Request) anyerror!void,
};

pub const ResponseInterceptor = struct {
    context: ?*anyopaque,
    interceptFn: *const fn(context: ?*anyopaque, response: *Response) anyerror!void,
};
```

**Client Integration:**
```zig
// In Client
request_interceptors: std.ArrayList(RequestInterceptor),
response_interceptors: std.ArrayList(ResponseInterceptor),

pub fn addRequestInterceptor(self: *Client, interceptor: RequestInterceptor) !void;
pub fn addResponseInterceptor(self: *Client, interceptor: ResponseInterceptor) !void;
```

**Common Use Cases:**
- Logging (log all requests/responses)
- Metrics (track request duration, response sizes)
- Request signing (add authentication headers)
- Response validation
- Error transformation

**Example Interceptors:**
```zig
// src/interceptors/logging.zig
pub fn createLoggingInterceptor(allocator: Allocator) RequestInterceptor;

// src/interceptors/metrics.zig
pub fn createMetricsInterceptor(allocator: Allocator) ResponseInterceptor;
```

**Tests:**
- Single interceptor execution
- Multiple interceptors in order
- Interceptor error handling
- Request modification in interceptor
- Response modification in interceptor

**Implementation Notes:**
- Interceptors run in order they're added
- Request interceptors run before send
- Response interceptors run after receive
- Error in interceptor propagates to caller

---

### 5. Enhanced Integration Tests

**Coverage Areas:**
- All HTTP methods with httpbin.org
- Compression (gzip/deflate responses)
- Authentication (basic, bearer)
- Cookie handling (set, read, persist)
- Redirects with cookies
- Large file downloads
- Error scenarios (timeout, invalid host, etc.)

**Test Files:**
- `tests/integration/compression_test.zig`
- `tests/integration/auth_test.zig`
- `tests/integration/cookies_test.zig`
- Expand `tests/integration/httpbin_test.zig`

---

## Implementation Order

1. **Compression Support** (High Value, Moderate Complexity)
   - Essential for production use
   - Relatively straightforward with Zig's std library
   - ~200 lines of code + tests

2. **Authentication Helpers** (High Value, Low Complexity)
   - Commonly needed feature
   - Simple implementation
   - ~150 lines of code + tests

3. **Cookie Management** (Medium Value, Medium Complexity)
   - Important for session-based APIs
   - Requires careful RFC compliance
   - ~300 lines of code + tests

4. **Request/Response Interceptors** (Medium Value, Medium Complexity)
   - Powerful extensibility mechanism
   - Clean design required
   - ~200 lines of code + tests

5. **Integration Tests** (High Value, Low Complexity)
   - Ensures everything works together
   - Validates production readiness
   - ~300 lines of tests

---

## File Structure

```
src/
├── encoding/
│   ├── chunked.zig (existing)
│   └── compression.zig (new)
├── auth/
│   ├── basic.zig (new)
│   ├── bearer.zig (new)
│   └── auth.zig (new - exports both)
├── cookies/
│   ├── Cookie.zig (new)
│   └── CookieJar.zig (new)
├── interceptors/
│   ├── interceptor.zig (new - core types)
│   ├── logging.zig (new - example)
│   └── metrics.zig (new - example)
└── client/
    ├── Client.zig (update - add interceptors, cookies)
    ├── Request.zig (update - add auth helpers)
    └── ... (existing files)

tests/integration/
├── compression_test.zig (new)
├── auth_test.zig (new)
├── cookies_test.zig (new)
└── httpbin_test.zig (expand)

examples/
├── basic_usage.zig (existing)
├── auth_example.zig (new)
├── cookies_example.zig (new)
└── interceptors_example.zig (new)
```

---

## Success Criteria

- [ ] Compression: Automatic gzip/deflate decompression working
- [ ] Authentication: Basic and Bearer auth helpers implemented
- [ ] Cookies: Full cookie jar with RFC 6265 compliance
- [ ] Interceptors: Request and response interceptors working
- [ ] All unit tests passing (target: 80+ tests)
- [ ] Integration tests covering all new features
- [ ] Examples demonstrating all new features
- [ ] Documentation updated (README, CHANGELOG)
- [ ] No memory leaks in all test scenarios
- [ ] Production-ready error handling

---

## Testing Strategy

### Unit Tests
- Each module has comprehensive unit tests
- Edge cases covered (malformed data, expired cookies, etc.)
- Memory leak testing with allocator checks

### Integration Tests
- Live tests with httpbin.org (when available)
- Compression: /gzip, /deflate endpoints
- Auth: /basic-auth, /bearer endpoints
- Cookies: /cookies/set, /cookies endpoints
- Combined scenarios (auth + cookies + compression)

### Example Tests
- All examples compile and run
- Examples demonstrate best practices
- Examples show error handling

---

## Documentation Updates

### README.md
- Add compression support to features
- Add authentication examples
- Add cookie management examples
- Add interceptor examples

### CHANGELOG.md
- Document all Phase 5 additions
- Note any breaking changes (if any)

### API Documentation
- Doc comments for all public APIs
- Usage examples in doc comments
- Error documentation

---

## Potential Challenges

1. **Compression Edge Cases**
   - Handling partial compression
   - Dealing with corrupted compressed data
   - Memory management for decompressed data

2. **Cookie RFC Compliance**
   - Domain matching rules are complex
   - Path matching edge cases
   - Expiration and Max-Age precedence

3. **Interceptor Design**
   - Balancing flexibility and simplicity
   - Error handling in interceptor chains
   - Performance impact of interceptors

4. **Memory Management**
   - Cookies stored in jar need proper cleanup
   - Compressed data requires careful allocation
   - Interceptor context lifetime management

---

## Performance Considerations

- Compression/decompression impact on throughput
- Cookie lookup performance (O(1) with HashMap)
- Interceptor overhead (minimize allocations)
- Memory pooling for frequently allocated objects

---

## Future Enhancements (Post Phase 5)

- HTTP/2 support
- WebSocket support
- Connection pooling improvements
- Request retry logic
- Circuit breaker pattern
- Rate limiting
- Streaming request/response bodies
- Multipart form data
- File upload/download progress callbacks

---

## Estimated Effort

- **Compression:** 1-2 sessions
- **Authentication:** 1 session
- **Cookies:** 2-3 sessions
- **Interceptors:** 1-2 sessions
- **Integration Tests:** 1-2 sessions
- **Documentation:** 1 session

**Total:** ~7-11 sessions

---

## Notes

- All features should be optional (can be disabled via ClientOptions)
- Maintain backward compatibility with Phase 4 API
- Focus on production readiness and robustness
- Prioritize common use cases over edge cases
- Keep API simple and intuitive
