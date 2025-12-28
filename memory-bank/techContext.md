# Technical Context

## Technology Stack
- **Language**: Dart (^3.10.4)
- **Target**: Slang 4.11+ (native stream-based locale sync)
- **CLI Framework**: `config` + `cli_tools` packages

## Key Dependencies
```yaml
dependencies:
  config: ^0.8.3        # Typed CLI options + YAML config
  cli_tools: ^0.5.0     # BetterCommandRunner for commands
  yaml: ^3.1.0          # Parse slang.yaml and pvtro.yaml
  path: ^1.9.0          # Cross-platform path handling
```

## File Structure
```
pvtro/
├── bin/pvtro.dart              # CLI entry point
├── lib/
│   ├── pvtro.dart              # Public exports
│   ├── commands/               # CLI commands
│   ├── templates/              # Code generation
│   └── utils/                  # Global utility functions
│       ├── package_scanner.dart
│       └── (future utils)
└── test/
```

## Utils Architecture
**Pattern**: Global functions with helper classes in same file

```dart
// lib/utils/package_scanner.dart

/// Helper class (same file)
class PackageInfo {
  final String name;
  final String path;
  PackageInfo({required this.name, required this.path});
}

/// Global function
Future<List<PackageInfo>> getPackageConfig(String projectPath) async {
  // implementation
}
```

## What We Generate (Slang 4.11+)
| Generate | Don't Generate |
|----------|----------------|
| Nested TranslationProvider wrapper | UnifiedLanguage enum |
| Optional init function | Switch-case locale parsers |
| Optional cookie persistence | LocaleCubit |

## Reference Output
```dart
Widget pvtroWrapper({required Widget child}) {
  return main_i18n.TranslationProvider(
    child: pkg_a.TranslationProvider(
      child: child,
    ),
  );
}
```

## Package Detection
- Read `.dart_tool/package_config.json`
- Check for `slang.yaml` or `lib/i18n/strings.g.dart`
- Filter out non-slang packages

## CLI Configuration (pvtro.yaml)
```yaml
version: 1
web: false
output: lib/generated/pvtro.g.dart
```
