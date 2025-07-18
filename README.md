# Fishbowl

A macOS menu bar app for journaling and AI-powered thought analysis using local models.

## Features

- Quick journal entry from the menu bar
- AI analysis of thinking patterns using Ollama
- Theme discovery and pattern recognition
- Daily and weekly insights
- Automated analysis scheduling
- Local-only processing (no cloud dependencies)

## Installation

### Prerequisites
- macOS 15.5+
- Xcode 16+ (for building)
- 4GB+ RAM
- [Ollama](https://ollama.com)

### Setup

1. Install Ollama:
   ```bash
   brew install ollama
   ollama pull llama3.2:1b
   ```

2. Start Ollama:
   ```bash
   ollama run llama3.2:1b
   ```
   *You can exit the chat (Ctrl+C) and the server keeps running for Fishbowl.*

3. Build the app:
   ```bash
   git clone <repo-url>
   cd fishbowl
   open fishbowl.xcodeproj
   ```

## Architecture

### Core Components
- **ContentView** - Main SwiftUI interface
- **ThoughtAnalyzer** - Analysis coordination
- **LLMService** - Ollama communication
- **FileService** - Data persistence
- **ThemeManager** - Theme discovery and tracking
- **SchedulerService** - Automated analysis timing
- **NotificationService** - User notifications

### Data Flow
```
User Input → FileService → ThoughtAnalyzer → LLMService → Analysis Results
                                        ↓
                        ThemeManager ← Analysis Results
```

### File Structure
```
fishbowl/
├── fishbowl/               # Main app
│   ├── Views/               # SwiftUI components
│   ├── Services/            # Business logic
│   ├── Utils/               # Utilities
│   └── Models/              # Data structures
├── fishbowlTests/           # Unit tests
└── fishbowlUITests/         # UI tests
```

## Development

### Running Tests
```bash
# All tests
xcodebuild test -scheme fishbowl -destination 'platform=macOS'

# Specific test file
xcodebuild test -scheme fishbowl -destination 'platform=macOS' -only-testing:fishbowlTests/FileServiceTests
```

### Test Coverage
- **FileService**: File operations, error handling
- **LLMService**: AI communication (mocked)
- **ThemeManager**: Theme discovery
- **ErrorHandling**: Error scenarios

### Configuration
- **Ollama URL**: Default `http://localhost:11434`
- **AI Model**: Default `llama3.2:1b`
- **Storage**: `~/Documents/fishbowl/`

### Debug Logging
Debug builds include detailed logging in the Xcode console covering analysis timing, theme discovery, and file operations.

## Troubleshooting

**Analysis not working?**
1. Ensure Ollama is running: `ollama run llama3.2:1b`
2. Check model installation: `ollama list`
3. Verify connectivity to localhost:11434

**No themes appearing?**
- Requires 3-5 days of entries minimum
- Check analysis logs for errors

**Performance issues?**
- Try smaller model: `llama3.2:1b`
- Ensure 4GB+ RAM available
- Close memory-intensive apps

## Privacy

All processing happens locally. No data leaves your machine.

**Data stored in:**
- `~/Documents/fishbowl/thoughts/` - Journal entries
- `~/Documents/fishbowl/analysis/` - Analysis results
- `~/Documents/fishbowl/theme_index.json` - Theme tracking

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, coding standards, and pull request process.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Acknowledgments

- [Ollama](https://ollama.com) for local AI infrastructure
- Swift/SwiftUI community resources 


Made to help untagle 🧶 your thoughts 🧠 
