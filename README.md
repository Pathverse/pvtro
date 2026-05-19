# PVTRO

PVTRO generates a root integration file for multi-package Flutter apps that use [slang](https://pub.dev/packages/slang).

It scans the active package graph, finds packages that expose generated `slang` translation layers, and emits:

- a nested `TranslationProvider` wrapper for the root app
- a public `pvtroSyncPackageLocales(String rawLocale)` helper that forwards `LocaleSettings.setLocaleRaw` to every discovered package

The same project config, `pvtro.yaml`, is used by both supported entrypoints:

- `dart run pvtro`
- `dart run build_runner build`

If no translation layer is discovered, PVTRO performs a no-op and does not generate an output file.

## Generated API

For a project with three participating packages, PVTRO emits code shaped like this:

```dart
import 'package:flutter/widgets.dart';

import 'package:main_app/i18n/translations.g.dart' as _$0;
import 'package:feature_shell/i18n/translations.g.dart' as _$1;
import 'package:shared_checkout_i18n/i18n/translations.g.dart' as _$2;

Widget pvtroWrapper({required Widget child}) {
  return _$0.TranslationProvider(
    child: _$1.TranslationProvider(
      child: _$2.TranslationProvider(
        child: child,
      ),
    ),
  );
}

Future<void> pvtroSyncPackageLocales(String rawLocale) async {
  await Future.wait([
    _$0.LocaleSettings.setLocaleRaw(rawLocale),
    _$1.LocaleSettings.setLocaleRaw(rawLocale),
    _$2.LocaleSettings.setLocaleRaw(rawLocale),
  ]);
}
```

Imports are emitted as `package:` imports with POSIX separators, including on Windows.

## Installation

Add PVTRO to the consuming project:

```yaml
dev_dependencies:
  pvtro:
    path: ../path/to/pvtro
  build_runner: ^2.5.4
```

`build_runner` is only required if the consuming project wants builder-mode generation.

## Shared Config

Create `pvtro.yaml` at the root of the consuming project:

```yaml
output: lib/pvtro.g.dart
verbose: false
excluded_packages:
  - shadcn_ui
```

Field meanings:

- `output`: desired generated file path; PVTRO always generates the canonical artifact at `lib/pvtro.g.dart`, and if `output` differs it also writes the same content to the configured path
- `verbose`: prints package discovery and generation details
- `excluded_packages`: exact package names to skip during discovery, even if they contain a fake or stub `slang` wrapper

CLI flags override values loaded from `pvtro.yaml`.

## Supported Flows

### `dart run pvtro`

Direct CLI mode reads `pvtro.yaml`, applies any explicit CLI overrides, and writes the generated wrapper to disk.

```bash
dart run pvtro
dart run pvtro --verbose
dart run pvtro --output lib/generated/pvtro_wrapper.g.dart
```

### `dart run build_runner build`

Builder mode shares the same discovery logic and `pvtro.yaml` contract.

Run it from the consuming project root:

```bash
dart run build_runner build --delete-conflicting-outputs
```

In builder mode, `lib/pvtro.g.dart` remains the canonical generated source asset. If `output` differs, the builder also emits the configured path as an additional source output.

## Discovery Rules

PVTRO treats a package as a translation layer when it detects `slang` support together with a generated `translations.g.dart` or `strings.g.dart` file under `lib/`.

If a dependency should never be wrapped, add it to `excluded_packages` in `pvtro.yaml`.

Discovery order is:

1. root package first
2. dependent packages after that, alphabetically

The generated wrapper nests `TranslationProvider`s in that order.

## App Usage

Use the generated wrapper at app startup:

```dart
void main() {
  runApp(pvtroWrapper(child: const MyApp()));
}
```

Use the generated sync helper when you need to push a raw locale string through every discovered package layer:

```dart
await pvtroSyncPackageLocales('en');
```

## Examples

Start with [example/example.md](example/example.md).

The repository includes two validated fixtures:

- [example/integration_check_1/README.md](example/integration_check_1/README.md): stub-based nested package graph using the default output path
- [example/integration_check_2/README.md](example/integration_check_2/README.md): real `slang` generation with a custom copied output target

`integration_check_2` is the authoritative end-to-end example for real usage.

## CLI Options

| Option | Short | Description |
|--------|-------|-------------|
| `--output` | `-o` | Output file path |
| `--verbose` | `-v` | Show discovery and generation progress |
| `--help` | `-h` | Show help |

## Requirements

- Dart SDK 3.x
- Flutter project structure for `TranslationProvider` integration
- `slang` and `slang_flutter` in packages that should participate in orchestration

## Roadmap

Planned but not yet implemented:

- slang version compatibility checks across discovered packages
- locale coverage and mismatch warnings across package boundaries
- web-source translation import workflows

## License

MIT
