# integration_check_1

This example exercises `pvtro` against a two-level nested slang setup:

- `integration_check_1` is the root Flutter app.
- `feature_shell` is a direct path dependency with its own slang layer.
- `shared_checkout_i18n` is a nested path dependency of `feature_shell` with its own slang layer.

The example intentionally does not include `pvtro.yaml` so both entrypoints use the default output path `lib/pvtro.g.dart`.

## Layout

```text
integration_check_1
├─ lib/i18n/translations.g.dart
└─ packages
   └─ feature_shell
      ├─ lib/i18n/translations.g.dart
      └─ packages
         └─ shared_checkout_i18n
            └─ lib/i18n/translations.g.dart
```

## Try It

```bash
flutter pub get
dart run pvtro --verbose
dart run build_runner build --delete-conflicting-outputs
```

After generation, `lib/pvtro.g.dart` should wrap the three translation providers in this order:

1. `integration_check_1`
2. `feature_shell`
3. `shared_checkout_i18n`

The checked-in `lib/pvtro.g.dart` file is a validated sample output and can be regenerated with either command.
