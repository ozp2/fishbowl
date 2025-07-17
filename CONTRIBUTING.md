# Contributing to Fishbowl

We welcome contributions in the form of bug reports, feature requests, code improvements, and documentation updates.

## Development Setup

1. **Fork and clone**
   ```bash
   git clone https://github.com/YOUR_USERNAME/fishbowl.git
   cd fishbowl
   ```

2. **Install dependencies**
   ```bash
   # Install Ollama
   brew install ollama
   ollama pull llama3.2:1b
   
   # Optional: SwiftLint for code style
   brew install swiftlint
   ```

3. **Build and test**
   ```bash
   open fishbowl.xcodeproj
   # Run tests: ⌘+U
   ```

## Bug Reports

Include the following information:

- Clear description of the issue
- Steps to reproduce
- Expected vs actual behavior
- Environment details:
  - macOS version
  - Xcode version
  - Ollama version and model
  - App version

**Template:**
```markdown
**Bug Description**
Clear description of the issue.

**Reproduction Steps**
1. Go to '...'
2. Click on '...'
3. Observe error

**Expected Behavior**
What should happen.

**Environment**
- macOS: [version]
- Xcode: [version]
- Ollama: [version]
- Model: [model name]
```

## Feature Requests

Before submitting:
- Check existing issues for duplicates
- Describe the problem being solved
- Propose a solution
- Consider implementation complexity

## Code Guidelines

### Style
- Follow Swift best practices
- Use descriptive names
- Comment complex logic
- Keep files focused

### Architecture
- Maintain separation of concerns
- Write testable code
- Use proper error handling
- Preserve user privacy

### Testing
Write tests for:
- Service classes (FileService, LLMService, etc.)
- Business logic
- Error scenarios
- Edge cases

**Test structure:**
```swift
@Test("FileService saves entry successfully")
func testSaveEntry() async throws {
    // Given
    let service = FileService(customBaseDirectory: testDirectory)
    let entry = "Test entry"
    
    // When
    try service.saveJournalEntry(entry)
    
    // Then
    let entries = try service.readJournalEntries()
    #expect(entries.contains { $0.contains(entry) })
}
```

### Commit Messages
Use conventional format:
```
type: short description

Optional longer description

- Additional details
- Context for the change
```

**Types:**
- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation
- `test:` - Tests
- `refactor:` - Code refactoring
- `style:` - Formatting

## Pull Request Process

### Before Submitting
1. Create feature branch: `git checkout -b feature/description`
2. Write/update tests
3. Ensure all tests pass
4. Update documentation if needed
5. Follow code style guidelines

### PR Template
```markdown
## Changes
Brief description of what this PR does

## Context
Why this change is needed

## Testing
- [ ] Unit tests added/updated
- [ ] Manual testing performed
- [ ] All tests pass

## Checklist
- [ ] Code follows style guidelines
- [ ] Tests cover new functionality
- [ ] Documentation updated
- [ ] No breaking changes
```

## Project Structure

```
fishbowl/
├── fishbowl/
│   ├── Views/               # SwiftUI components
│   ├── Services/            # Business logic
│   │   ├── FileService.swift
│   │   ├── LLMService.swift
│   │   └── ErrorHandlingService.swift
│   ├── Utils/               # Utilities
│   ├── Models/              # Data structures
│   └── ThoughtAnalyzer.swift
├── fishbowlTests/           # Unit tests
└── fishbowlUITests/         # UI tests
```

## Testing

### Running Tests
```bash
# All tests
xcodebuild test -scheme fishbowl -destination 'platform=macOS'

# Specific test file
xcodebuild test -scheme fishbowl -destination 'platform=macOS' -only-testing:fishbowlTests/FileServiceTests

# With coverage
xcodebuild test -scheme fishbowl -destination 'platform=macOS' -enableCodeCoverage YES
```

### Test Guidelines
- Test behavior, not implementation
- Use descriptive test names
- Follow Given-When-Then structure
- Test edge cases and error conditions
- Mock external dependencies

## Code Review

We look for:
- **Functionality** - Does it work correctly?
- **Tests** - Are there appropriate tests?
- **Code Quality** - Is it maintainable?
- **Performance** - Any negative impact?
- **Security** - Are there security implications?

## Areas Needing Help

**High Priority:**
- Error handling improvements
- Performance optimization
- Test coverage expansion
- UI/UX enhancements

**Medium Priority:**
- Accessibility support
- Localization
- Advanced features
- Documentation improvements

**Good First Issues:**
Look for issues labeled `good first issue` - these are suitable for new contributors.

## Getting Help

If you need assistance:
1. Check existing documentation
2. Search existing issues
3. Open a discussion for questions
4. Reference this guide

## Communication

- **GitHub Issues** - Bug reports and feature requests
- **GitHub Discussions** - Questions and general discussion
- **Pull Requests** - Code review and collaboration

## Recognition

Contributors are recognized in release notes and the GitHub contributors section.

---

Questions? Open an issue or start a discussion. 