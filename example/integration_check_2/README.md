# integration_check_2

This example uses real `slang` generation in a two-level nested dependency chain.

- `integration_check_2` is the root Flutter app.
- `feature_shell_real` is a direct path dependency with its own `slang` setup.
- `shared_checkout_i18n_real` is a nested path dependency of `feature_shell_real` with its own `slang` setup.

## Regenerate

Run these commands from each package root to regenerate real `slang` outputs:

```bash
# root app
flutter pub get
dart run slang

# first nested package
cd packages/feature_shell_real
flutter pub get
dart run slang

# second nested package
cd packages/shared_checkout_i18n_real
flutter pub get
dart run slang
```

Then return to the root app and run:

```bash
dart run pvtro --verbose
dart run build_runner build --delete-conflicting-outputs
```

This example includes a `pvtro.yaml` with a custom output target:

```yaml
output: lib/generated/pvtro_wrapper.g.dart
verbose: true
```

With that config, PVTRO will:

- always generate the canonical build artifact at `lib/pvtro.g.dart`
- also copy the same generated content to `lib/generated/pvtro_wrapper.g.dart`

The checked-in `translations.g.dart`, `translations_en.g.dart`, `lib/pvtro.g.dart`, and `lib/generated/pvtro_wrapper.g.dart` files can be regenerated with the commands above.
