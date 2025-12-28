# Product Context

## Product Vision
PVTRO is a **CLI helper tool** for multi-package Flutter apps using slang 4.11+. It assists rather than replaces—slang handles the heavy lifting, PVTRO helps with setup and validation.

## Core Problem
Developers must manually nest `TranslationProvider` widgets and ensure consistency across packages. PVTRO automates and validates this.

## CLI Flow
```
dart run pvtro
├── Check Flutter package
├── Scan for slang packages
└── Generate nested TranslationProvider wrapper
```

## What PVTRO Generates
```dart
Widget pvtroWrapper({required Widget child}) {
  return main_i18n.TranslationProvider(
    child: pkg_a.TranslationProvider(
      child: pkg_b.TranslationProvider(
        child: child,
      ),
    ),
  );
}
```

## Why Helper Tool, Not Solution
Slang 4.11+ made massive improvements:
- Native stream-based locale sync
- No manual coordination needed
- PVTRO just assists with wrapper generation and validation

## User Workflow
1. Add `pvtro` to dev_dependencies
2. Run `dart run pvtro`
3. Use generated wrapper:
   ```dart
   runApp(pvtroWrapper(child: MyApp()));
   ```

## Changing Locale (Use Slang Directly)
```dart
LocaleSettings.setLocale(AppLocale.es);
// All packages sync automatically via stream
```

## Target Users
- Flutter developers using slang 4.11+ across multiple packages
- Monorepo projects with slang-enabled subpackages

```yaml
version: 1
web: false                              # Cookie persistence
output: lib/generated/pvtro.g.dart      # Output file
base_package: main_app                  # Optional explicit base
```

## CLI Options

| Option | Description |
|--------|-------------|
| `--web, -w` | Enable cookie persistence |
| `--output, -o` | Output file path |
| `--verbose, -v` | Verbose output |

## Future: Web Source Integration
Planned feature to bridge web translation sources to local builds:
- Import translations from web CMS/platforms
- Sync remote translations to local slang files
- Easier integration for translation workflows

## Success Metrics
- Setup time < 1 minute
- Assists without getting in the way
- Future: seamless web source integration
