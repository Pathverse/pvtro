# PVTRO

**PathVerse Translation Orchestrator** - A CLI helper tool for multi-package Flutter apps using [slang](https://pub.dev/packages/slang).

## Overview

With slang 4.0+, locale synchronization across packages is handled natively via streams. PVTRO serves as a **helper and checker tool** rather than a complete solution—it assists with:

- 🔍 **Package Discovery**: Scans your project for slang-enabled packages
- 🏗️ **Wrapper Generation**: Generates nested `TranslationProvider` wrappers
- ✅ **Validation** (planned): Version compatibility and locale matching checks

## Installation

Add to your `dev_dependencies`:

```yaml
dev_dependencies:
  pvtro:
    path: ../path/to/pvtro  # or git/pub reference
```

## Usage

```bash
# Generate TranslationProvider wrapper
dart run pvtro

# With options
dart run pvtro --output lib/pvtro.g.dart --verbose
```

### CLI Options

| Option | Short | Description |
|--------|-------|-------------|
| `--output` | `-o` | Output file path (default: `lib/pvtro.g.dart`) |
| `--verbose` | `-v` | Show detailed output |
| `--help` | `-h` | Show help |

## Generated Output

```dart
import 'package:main_app/i18n/translations.g.dart' as _$0;
import 'package:package_a/i18n/translations.g.dart' as _$1;
import 'package:package_b/i18n/translations.g.dart' as _$2;
import 'package:flutter/widgets.dart';

Widget pvtroWrapper({required Widget child}) {
  return _$0.TranslationProvider(
    child: _$1.TranslationProvider(
      child: _$2.TranslationProvider(
        child: child,
      ),
    ),
  );
}
```

### Using the Generated Wrapper

```dart
void main() {
  runApp(pvtroWrapper(child: const MyApp()));
}
```

## Changing Locale

Use slang directly—all packages sync automatically:

```dart
LocaleSettings.setLocale(AppLocale.es);
```

## Roadmap

- [x] Package discovery and wrapper generation
- [ ] Slang version compatibility check across packages
- [ ] Locale/language matching validation
- [ ] Web source integration for local builds

## Why "Helper Tool"?

Slang 4.11+ made significant improvements to multi-package locale sync. PVTRO doesn't replace slang—it **assists** by:

1. Automating the tedious `TranslationProvider` nesting
2. Checking for potential issues across packages (planned)
3. Bridging web translation sources to local builds (planned)

## Requirements

- Dart SDK ^3.10.4
- slang ^4.11.0 (in your project)
- Flutter project with slang-enabled packages

## License

MIT
