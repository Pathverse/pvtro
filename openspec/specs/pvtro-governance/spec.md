# pvtro-governance Specification

## Purpose
The repository SHALL define and preserve PVTRO governance through OpenSpec by
capturing package behavior, configuration, discovery rules, examples, and verification
flow from project documentation and validated implementation paths.

## Requirements

### Requirement: Discovery and shared generation path
Generation SHALL be driven by the shared orchestration in the package library
layer and SHALL run from the consuming project root in both CLI and builder modes.

#### Scenario: generation behavior is consistent across execution modes
- **WHEN** the CLI mode (`dart run pvtro`) and builder mode (`dart run build_runner build --delete-conflicting-outputs`) run from the same project root
- **THEN** both SHALL use the same `pvtro.yaml` contract and the same package
  discovery logic to determine participants
- **AND** both SHALL treat `lib/pvtro.g.dart` as the canonical generated output

### Requirement: Canonical output plus configured copy
The configured `output` path SHALL be honored as an additional output target,
while keeping canonical output stable at `lib/pvtro.g.dart`.

#### Scenario: non-default output is configured
- **WHEN** `pvtro.yaml` (or CLI override) sets `output` to a non-default path
- **THEN** generated content SHALL be written to `lib/pvtro.g.dart`
- **AND** the same content SHALL be written to the configured output path

### Requirement: Configuration contract and precedence
`pvtro.yaml` SHALL be optional and interpreted with explicit defaults.
The supported keys SHALL be:
- `output`
- `verbose`
- `excluded_packages`

#### Scenario: missing `pvtro.yaml`
- **WHEN** no configuration file is present at repository root
- **THEN** defaults SHALL apply as `output: lib/pvtro.g.dart`, `verbose: false`,
  and `excluded_packages: []`

#### Scenario: CLI flags override config
- **WHEN** CLI flags are passed
- **THEN** `--output` and `--verbose` SHALL override values loaded from `pvtro.yaml`
- **AND** the command help SHALL remain available via `--help`

#### Scenario: invalid config values
- **WHEN** `pvtro.yaml` has wrong value types
- **THEN** generation SHALL fail fast with a clear format/validation error

### Requirement: Package-graph driven integration
The root app SHALL be the intended generation destination, and integration SHALL
cover every discovered slang translation layer in dependency order.

#### Scenario: translation layer discovery succeeds
- **WHEN** scanning succeeds across the package graph
- **THEN** the generator SHALL produce a nested wrapper of `TranslationProvider`
  instances in dependency order
- **AND** root package wrappers SHALL be outermost, with dependencies nested inward
- **AND** generated output SHALL expose `pvtroWrapper({required Widget child})`
- **AND** generated output SHALL expose
  `pvtroSyncPackageLocales(String rawLocale)` forwarding locale sync across every discovered package

### Requirement: Discovery source and order
Discovery SHALL be based on `.dart_tool/package_config.json` and package naming
from root `pubspec.yaml`.

#### Scenario: package graph scan
- **WHEN** package discovery executes
- **THEN** it SHALL read package config and identify package roots
- **AND** it SHALL sort participants as root package first, then dependencies
  alphabetically
- **AND** it SHALL skip package `pvtro` from discovery

### Requirement: Slang layer selection
A package SHALL be included only when slang support and generated output are
present.

#### Scenario: qualifying package
- **WHEN** a package has `slang.yaml` or `slang` / `slang_flutter` references
- **AND** contains generated slang output under accepted `lib` locations
  (`i18n/strings.g.dart`, `i18n/translations.g.dart`,
  `l10n/strings.g.dart`, `l10n/translations.g.dart`,
  `translations/strings.g.dart`, `translations/translations.g.dart`,
  `generated/strings.g.dart`, `generated/translations.g.dart`)
- **THEN** it SHALL be emitted into the discovered layer list
- **AND** fallback recursive `lib` scans for `strings.g.dart` or
  `translations.g.dart` MAY include additional matches when needed

#### Scenario: excluded package
- **WHEN** a package appears in `excluded_packages`
- **THEN** it SHALL not be included in wrappers or locale sync output

### Requirement: Excluded participants and no-op behavior
Packages listed in `excluded_packages` MUST be ignored even when they expose
`TranslationProvider` artifacts.

#### Scenario: package explicitly excluded
- **WHEN** `shadcn_ui` is listed in exclusions
- **THEN** generated output SHALL not contain imports or calls for that package

### Requirement: Generated output API shape and import rules
The generated output SHOULD keep deterministic formatting and import hygiene.

#### Scenario: generated API and imports
- **WHEN** generation outputs code
- **THEN** it SHALL include a generated-code header and `flutter/widgets.dart` import
- **AND** each translated package import SHALL be a `package:` import with POSIX
  separators
- **AND** the file SHALL include a sync helper that dispatches one
  `LocaleSettings.setLocaleRaw(rawLocale)` call per package

### Requirement: No-op on zero translation layers
The system SHALL not emit wrapper output when discovery resolves zero packages.

#### Scenario: no translation layers discovered
- **WHEN** discovery returns no packages
- **THEN** no translation content SHALL be written and run completion SHALL still
  be reported clearly

### Requirement: Builder output declarations
Builder mode SHALL emit canonical and configured outputs according to resolved config.

#### Scenario: custom output in builder
- **WHEN** the config sets an output path that differs from canonical
- **THEN** build outputs SHALL declare both `pubspec.yaml -> lib/pvtro.g.dart`
  and `pubspec.yaml -> <configured_output>`

### Requirement: Example-driven acceptance is normative
The fixture documentation in `example/` SHALL remain the reference for end-to-end
integration shape.

#### Scenario: `integration_check_1` default path behavior
- **WHEN** `integration_check_1` runs without `pvtro.yaml`
- **THEN** generation SHALL use `lib/pvtro.g.dart` as the only target
- **AND** the wrapper ordering SHALL reflect
  `integration_check_1 -> feature_shell -> shared_checkout_i18n`

#### Scenario: `integration_check_2` canonical-plus-copy behavior
- **WHEN** `integration_check_2` uses `output: lib/generated/pvtro_wrapper.g.dart`
- **THEN** canonical `lib/pvtro.g.dart` and copy output SHALL both be present
- **AND** both files SHALL contain identical generated content

### Requirement: Validation loop
Repository validation SHALL include unit tests and example checks matching documented
usage.

#### Scenario: behavioral change validation
- **WHEN** generation behavior changes
- **THEN** maintainers SHALL run `dart test` and `dart analyze`
- **AND** validate both fixture docs and generation paths by running documented
  example flows (`dart run pvtro --verbose`, and build_runner invocation)