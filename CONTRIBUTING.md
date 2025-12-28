# Contributing to zig_net

Thank you for your interest in contributing to zig_net! This document provides guidelines and instructions for contributing to the project.

## Code of Conduct

This project follows a simple code of conduct: be respectful, be constructive, and focus on what's best for the project and community.

## Getting Started

### Prerequisites

- **Zig 0.15.1 or later** - [Download Zig](https://ziglang.org/download/)
- **Git** - For version control
- **Internet connection** - For running integration tests

### Setting Up the Development Environment

1. **Clone the repository:**
   ```bash
   git clone https://github.com/TBick/zig_net.git
   cd zig_net
   ```

2. **Run the tests:**
   ```bash
   zig build test
   ```

3. **Build the library:**
   ```bash
   zig build
   ```

## Development Workflow

### 1. Create a Branch

Create a feature branch for your work:

```bash
git checkout -b feature/your-feature-name
# or
git checkout -b fix/issue-description
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation improvements
- `refactor/` - Code refactoring
- `test/` - Test improvements

### 2. Make Your Changes

#### Code Style Guidelines

**Zig Code Style:**
- Follow the [Zig Style Guide](https://ziglang.org/documentation/master/#Style-Guide)
- Use 4 spaces for indentation (no tabs)
- Maximum line length: 100 characters
- Use meaningful variable and function names
- Add doc comments (`///` or `//!`) for all public APIs

**Documentation Comments:**
```zig
/// Brief description of the function
///
/// More detailed explanation if needed.
///
/// # Parameters
/// - `param1`: Description of first parameter
/// - `param2`: Description of second parameter
///
/// # Returns
/// Description of return value
///
/// # Errors
/// List of possible errors and when they occur
///
/// # Example
/// ```zig
/// const result = try myFunction(allocator, value);
/// ```
pub fn myFunction(allocator: std.mem.Allocator, value: i32) !ReturnType {
    // Implementation
}
```

**Memory Management:**
- Always use the provided allocator parameter
- Ensure all allocations are properly freed
- Use `defer` for cleanup
- Use `errdefer` for error path cleanup
- Test for memory leaks using `std.testing.allocator`

**Error Handling:**
- Use custom error types from `src/errors.zig`
- Provide meaningful error messages
- Document all possible errors in doc comments

### 3. Write Tests

All contributions must include appropriate tests:

**Unit Tests:**
- Place unit tests in the same file as the code being tested
- Use the `test` keyword
- Test edge cases and error conditions

```zig
test "feature description" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // Test implementation
    try testing.expectEqual(expected, actual);
}
```

**Integration Tests:**
- Place integration tests in `tests/integration/`
- Test real-world scenarios
- Tests requiring network access should be commented out by default

**Test Coverage:**
- Aim for 100% coverage of new code
- Test both success and error paths
- Test boundary conditions

### 4. Run Tests

Before submitting:

```bash
# Run all tests
zig build test

# Run with memory leak detection (automatic with test allocator)
zig build test

# Check for compilation warnings
zig build
```

### 5. Update Documentation

Update relevant documentation:

- **Code comments** - Ensure all public APIs are documented
- **README.md** - Update if adding new features
- **CHANGELOG.md** - Add entry for your changes
- **Examples** - Add examples for new features in `examples/`
- **API docs** - Update `docs/api/` if applicable

### 6. Commit Your Changes

**Commit Message Format:**
```
Type: Brief description (50 chars or less)

More detailed explanation if needed. Wrap at 72 characters.
Explain what and why, not how.

- Bullet points are okay
- Use present tense: "Add feature" not "Added feature"
- Reference issues: Fixes #123

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

**Commit Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `test:` - Test additions or changes
- `refactor:` - Code refactoring
- `perf:` - Performance improvements
- `chore:` - Maintenance tasks

**Examples:**
```
feat: Add support for HTTP/2

Implements HTTP/2 protocol support using std.http.Client's HTTP/2
capabilities. Includes comprehensive tests and examples.

Fixes #42
```

### 7. Submit a Pull Request

1. **Push your branch:**
   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub

3. **PR Description should include:**
   - What changes were made and why
   - Link to related issues
   - Test results
   - Any breaking changes
   - Screenshots/examples if applicable

## What to Contribute

### Good First Issues

Look for issues tagged with `good-first-issue` - these are suitable for newcomers.

### Feature Requests

Before implementing a new feature:
1. Check if an issue already exists
2. Create an issue to discuss the feature
3. Wait for maintainer approval
4. Implement the feature

### Bug Fixes

Bug fixes are always welcome:
1. Create an issue describing the bug (if one doesn't exist)
2. Reference the issue in your PR
3. Include a test that reproduces the bug

### Documentation

Documentation improvements are highly valued:
- Fix typos and grammar
- Improve clarity
- Add examples
- Expand API documentation
- Write tutorials

### Areas Needing Contributions

Current areas where contributions are especially welcome:
- **HTTP/2 Support** - Expand HTTP/2 capabilities
- **WebSocket Support** - Add WebSocket protocol
- **Performance Optimizations** - Profile and optimize hot paths
- **More Examples** - Real-world usage examples
- **Documentation** - API docs, guides, tutorials
- **Platform Testing** - Test on different platforms

## Project Structure

```
zig_net/
├── src/                    # Source code
│   ├── root.zig           # Public API entry point
│   ├── errors.zig         # Error definitions
│   ├── client/            # HTTP client components
│   ├── protocol/          # HTTP protocol utilities
│   ├── auth/              # Authentication
│   ├── cookies/           # Cookie management
│   ├── interceptors/      # Request/Response interceptors
│   └── encoding/          # Transfer encoding
├── tests/
│   ├── unit/              # Unit tests (unused - tests are co-located)
│   └── integration/       # Integration tests
├── examples/              # Usage examples
├── docs/                  # Documentation
│   ├── api/               # API reference
│   ├── guides/            # User guides
│   └── architecture/      # Architecture docs
├── build.zig             # Build configuration
├── build.zig.zon         # Package manifest
├── README.md             # Project overview
├── CHANGELOG.md          # Version history
├── CONTRIBUTING.md       # This file
└── LICENSE               # MIT License
```

## Review Process

1. **Automated Checks** - PR must pass all tests
2. **Code Review** - Maintainer reviews code quality
3. **Discussion** - Address any feedback
4. **Approval** - Maintainer approves PR
5. **Merge** - PR is merged into main branch

## Release Process

zig_net follows [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality
- **PATCH** version for backwards-compatible bug fixes

## Getting Help

If you have questions:

1. **Check the documentation** - README.md, docs/
2. **Search existing issues** - Someone may have asked before
3. **Create an issue** - Ask your question
4. **Be patient** - Maintainers are volunteers

## Recognition

Contributors will be:
- Listed in CHANGELOG.md for their contributions
- Mentioned in release notes
- Added to a CONTRIBUTORS file (coming soon)

## License

By contributing to zig_net, you agree that your contributions will be licensed under the MIT License.

---

**Thank you for contributing to zig_net!** Your efforts help make this library better for everyone.
