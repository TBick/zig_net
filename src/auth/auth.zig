//! HTTP Authentication
//!
//! This module provides authentication helpers for HTTP requests.
//! It supports common authentication schemes used in REST APIs and web services.
//!
//! # Supported Authentication Schemes
//! - **Basic Authentication** (RFC 7617): Username/password authentication
//! - **Bearer Token** (RFC 6750): Token-based authentication (OAuth 2.0, JWT, etc.)
//!
//! # Security Best Practices
//! - Always use HTTPS when sending authentication credentials
//! - Store credentials securely (use environment variables, secure vaults)
//! - Never log or display authentication credentials
//! - Rotate tokens and passwords regularly
//! - Use token expiration and refresh mechanisms where available
//!
//! # Usage
//! ```zig
//! const auth = @import("auth/auth.zig");
//!
//! // Basic Authentication
//! const basic = auth.BasicAuth.init("username", "password");
//! try basic.applyToRequest(&request);
//!
//! // Bearer Token
//! const bearer = auth.BearerAuth.init("your-token-here");
//! try bearer.applyToRequest(&request);
//! ```

// Re-export authentication types
pub const BasicAuth = @import("basic.zig").BasicAuth;
pub const BearerAuth = @import("bearer.zig").BearerAuth;

// Run tests from submodules
const std = @import("std");

test {
    std.testing.refAllDecls(@This());
    _ = @import("basic.zig");
    _ = @import("bearer.zig");
}
