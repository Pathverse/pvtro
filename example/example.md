# Examples

This directory contains two end-to-end fixtures that show how PVTRO discovers `slang` translation layers across a package graph and generates a single integration file for the root app.

Use this document as the entry point, then open the fixture-specific READMEs for the exact package layout and commands.

## What PVTRO Does In These Examples

For each example, PVTRO runs from the root app and:

1. reads the root package graph from `.dart_tool/package_config.json`
2. finds packages that expose a generated `slang` layer under `lib/`
3. orders them with the root package first and dependencies after that
4. generates `lib/pvtro.g.dart` in the root app
5. emits:
   - `pvtroWrapper({required Widget child})`
   - `pvtroSyncPackageLocales(String rawLocale)`

The generated wrapper nests each package's `TranslationProvider` in discovery order. The locale sync helper forwards `LocaleSettings.setLocaleRaw(rawLocale)` to every discovered package.

If no translation layer is found, PVTRO does nothing.

## Included Fixtures

### integration_check_1

See [integration_check_1/README.md](d:\pvtro\example\integration_check_1\README.md).

This is the lightweight fixture.

- Uses checked-in stub translation files.
- Has no `pvtro.yaml`, so both entrypoints use the default output path.
- Good for verifying package discovery and output shape quickly.

Expected generated file:

- `lib/pvtro.g.dart`

### integration_check_2

See [integration_check_2/README.md](d:\pvtro\example\integration_check_2\README.md).

This is the real fixture.

- Uses actual `slang.yaml` plus locale JSON inputs.
- Uses real `dart run slang` outputs in all three packages.
- Includes `pvtro.yaml` with a custom copied output target.
- Good for validating the real dual-mode contract.

Expected generated files:

- `lib/pvtro.g.dart`
- `lib/generated/pvtro_wrapper.g.dart`

## How The Graph Is Structured

Both fixtures model the same dependency chain:

1. Root app
2. Direct path dependency with its own `slang` layer
3. Nested path dependency under that package with its own `slang` layer

That means the generated wrapper should compose three `TranslationProvider`s, and the sync helper should call `LocaleSettings.setLocaleRaw` three times.

## How To Run An Example

From the fixture root:

```bash
flutter pub get
dart run pvtro --verbose
dart run build_runner build --delete-conflicting-outputs
```

For `integration_check_2`, regenerate the `slang` outputs in each package first, as described in its local README.

## Output Behavior

Both fixtures demonstrate the same core behavior:

- `dart run pvtro` and `dart run build_runner build` share the same discovery logic
- the canonical generated artifact is always `lib/pvtro.g.dart`
- if `pvtro.yaml` sets a different `output`, PVTRO also writes a copy to that configured path

In practice:

- `integration_check_1` shows the default-path flow
- `integration_check_2` shows the canonical-plus-copy flow

## What To Inspect After Generation

Open the generated root file and confirm these points:

1. all imports use `package:` paths with POSIX separators
2. the root app provider is the outermost `TranslationProvider`
3. nested package providers appear inside it in dependency order
4. `pvtroSyncPackageLocales` includes one call per discovered package

If one of those conditions is wrong, the example has exposed a regression in discovery or generation.