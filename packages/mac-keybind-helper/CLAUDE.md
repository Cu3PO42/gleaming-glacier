# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KeybindHelper is a macOS application that displays keybinding overlays. It consists of:

- **KeybindHelperDaemon**: Background daemon that manages overlay windows and IPC communication
- **KeybindHelperClient**: Command-line client for communicating with the daemon
- **KeybindHelperCore**: Shared library containing data models, configuration parsing, and IPC types

The system uses Unix domain sockets for IPC communication between client and daemon.

## Build Commands

- `swift build` - Direct Swift command to build all binaries

### Testing
- `swift test` - Direct Swift Package Manager test command
- `swift test --verbose` - Run tests with verbose output

## Architecture

### Core Components

**KeybindHelperCore** (`Sources/KeybindHelperCore/`):
- `DataModels.swift`: Core data types (KeyCombination, Keymap, KeymapConfiguration)
- `ConfigurationParser.swift`: JSON configuration file parsing
- `Commands.swift`: IPC command definitions (show, hide, quit)
- `IPCTypes.swift`: IPC error types and constants
- `Logger.swift`: Logging infrastructure with categories

**KeybindHelperDaemon** (`Sources/KeybindHelperDaemon/`):
- `main.swift`: Daemon entry point with signal handlers, command routing, overlay management, and configuration handling
- `IPCServer.swift`: Unix domain socket server implementation
- `KeybindingOverlayView.swift`: SwiftUI overlay window implementation

**KeybindHelperClient** (`Sources/KeybindHelperClient/`):
- `main.swift`: Client entry point with argument parsing and daemon auto-launch
- `IPCClient.swift`: Unix domain socket client implementation

### Configuration System

Configuration files are JSON-based with hierarchical keymaps:
- Each keymap has an ID, parent ID, name, description, and bindings
- Key combinations include modifiers (shift, ctrl, alt, super/cmd)
- Sample configuration available in `sample-config.json`

### IPC Communication

- Uses Unix domain socket at `/tmp/keybind-helper.sock`
- Commands: `show <mapId> <configPath>`, `hide`, `quit`
- JSON-encoded command/response protocol
- Client auto-launches daemon if not running

### Error Handling

The project recently simplified error handling (see `SIMPLIFIED_ERROR_HANDLING.md`):
- Removed complex exponential backoff and circuit breaker patterns
- Uses simple retry logic with fixed delays
- Basic fallback mechanisms for transient failures

## Testing Strategy

Tests are organized by module:
- `KeybindHelperCoreTests/`: Core functionality and data model tests
- `KeybindHelperDaemonTests/`: Daemon component and integration tests
- `KeybindHelperClientTests/`: Client and IPC integration tests

Integration tests verify IPC communication and configuration management.

## Development Notes

- Platform: macOS 11.0+
- Language: Swift 5.8+
- Build artifacts placed in `build/` directory
- Uses Swift Package Manager for dependency management
- Logging supports both console and system log output
- Performance measurement utilities for command handling
