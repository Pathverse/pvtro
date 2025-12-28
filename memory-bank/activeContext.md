# Active Context

## Current Phase
**Phase 3: Documentation & Planning - Core MVP Complete**

## Project Direction
PVTRO is a **CLI helper tool**, not a complete solution. Slang 4.11+ handles locale sync natively—PVTRO assists with automation and validation.

## What's Working
- ✅ `dart run pvtro` generates wrapper in target project
- ✅ Package discovery via `package_config.json`
- ✅ Main package detected and placed outermost
- ✅ Nested TranslationProvider wrapper generated
- ✅ Tested with pvtro_poc_2 (4 packages including nested deps)

## Current Implementation

### Utils (lib/utils/)
| File | Functions |
|------|-----------|
| `package_scanner.dart` | `getPackageConfig`, `hasSlangSupport`, `findStringsFile`, `discoverSlangPackages` |
| `wrapper_generator.dart` | `generateImports`, `generateWrapper`, `generateOutputFile` |

### CLI (bin/pvtro.dart)
| Option | Description |
|--------|-------------|
| `-o, --output` | Output file path (default: `lib/pvtro.g.dart`) |
| `-v, --verbose` | Verbose logging |
| `-h, --help` | Show help |

### Generated Output Pattern
```dart
import 'package:main_app/i18n/translations.g.dart' as _$0;
import 'package:package_a/i18n/translations.g.dart' as _$1;

Widget pvtroWrapper({required Widget child}) {
  return _$0.TranslationProvider(
    child: _$1.TranslationProvider(
      child: child,
    ),
  );
}
```

## Future Features (Planned)

### 1. Slang Version Compatibility Check
- Scan all dependent packages for slang version
- Warn if versions don't match

### 2. Locale/Language Matching
- Compare available locales across all packages
- Warn about missing translations

### 3. Web Source Integration (Priority)
- Import translations from web CMS/platforms
- Sync remote translations to local slang files
- Easier integration for translation workflows

## Recent Changes
- 2025-12-28: Updated README and memory bank (helper tool positioning)
- 2025-12-28: Core MVP complete and tested
- 2025-12-28: Added package_c (nested dep) to poc_2
- 2025-12-28: Fixed main package ordering (outermost)
