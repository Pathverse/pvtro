# System Patterns

## Core Principle
**SLANG 4.11+ handles locale sync natively** - PVTRO discovers packages and generates wrapper code.

## Code Organization
```
lib/
├── commands/         # CLI commands (scan, generate)
├── wizard/           # Interactive setup (future)
├── templates/        # Code generation templates
└── utils/            # Global utility functions
```

## Utils Architecture Pattern
**Global functions, not classes**

```dart
// ✅ Correct: Global functions
Future<List<PackageInfo>> getPackageConfig(String path);
Future<bool> hasSlangSupport(String path);

// ❌ Avoid: Static class methods
class PackageScanner {
  static Future<List<PackageInfo>> getPackageConfig(String path);
}
```

**Helper classes in same file when needed:**
```dart
// lib/utils/package_scanner.dart
class PackageInfo {
  final String name;
  final String path;
  PackageInfo({required this.name, required this.path});
}

Future<List<PackageInfo>> getPackageConfig(String projectPath) async {
  // implementation
}
```

## Development Workflow Pattern
**User-determined implementation flow:**
1. Propose function signatures in markdown
2. Wait for user approval/modification
3. Implement approved functions only
4. Move to next utility

## CLI Architecture (using `config` package)
```dart
enum PvtroOption<V> implements OptionDefinition<V> {
  web(FlagOption(argName: 'web', defaultsTo: false)),
  output(DirOption(argName: 'output')),
  verbose(FlagOption(argName: 'verbose', defaultsTo: false));

  const PvtroOption(this.option);
  @override
  final ConfigOptionBase<V> option;
}
```

## Detection Pattern
```dart
Future<void> main(List<String> args) async {
  if (!await isFlutterPackage()) exit(1);
  final packages = await discoverSlangPackages('.');
  await generateWrapper(packages);
}
```

## Generation Pattern (Slang 4.11+)
**Minimal output - no switch-case parsers:**
```dart
Widget pvtroWrapper({required Widget child}) {
  return main_i18n.TranslationProvider(
    child: pkg_a.TranslationProvider(
      child: child,
    ),
  );
}
```

## Best Practices
- Use `LocaleSettings.getLocaleStream()` for sync (native slang)
- Nest `TranslationProvider` widgets (native slang)
- No custom LocaleCubit or UnifiedLanguage enum needed
- Generate minimal wrapper code only
