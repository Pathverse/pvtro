import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pvtro/config/pvtro_config.dart';
import 'package:pvtro/pvtro.dart';
import 'package:pvtro/utils/package_scanner.dart';
import 'package:pvtro/utils/wrapper_generator.dart';
import 'package:test/test.dart';

/// Validates scanner behavior for generated package import paths.
void main() {
	group('findStringsFile', () {
		test('returns POSIX package import paths for discovered files', () async {
			final tempDir = await Directory.systemTemp.createTemp('pvtro_test_');
			addTearDown(() async {
				if (await tempDir.exists()) {
					await tempDir.delete(recursive: true);
				}
			});

			final generatedFile = File(
				p.join(tempDir.path, 'lib', 'feature', 'i18n', 'strings.g.dart'),
			);
			await generatedFile.parent.create(recursive: true);
			await generatedFile.writeAsString('// generated');

			final importPath = await findStringsFile(tempDir.path, 'sample_pkg');

			expect(importPath, 'package:sample_pkg/feature/i18n/strings.g.dart');
			expect(importPath, isNot(contains(r'\')));
		});
	});

	group('PvtroConfig', () {
		test('loads defaults when pvtro.yaml is missing', () async {
			final tempDir = await Directory.systemTemp.createTemp('pvtro_config_');
			addTearDown(() async {
				if (await tempDir.exists()) {
					await tempDir.delete(recursive: true);
				}
			});

			final config = await PvtroConfig.loadProjectConfig(tempDir.path);

			expect(config.output, PvtroConfig.defaultOutput);
			expect(config.verbose, isFalse);
			expect(config.excludedPackages, isEmpty);
		});

		test('merges CLI flags over pvtro.yaml defaults', () async {
			final tempDir = await Directory.systemTemp.createTemp('pvtro_config_');
			addTearDown(() async {
				if (await tempDir.exists()) {
					await tempDir.delete(recursive: true);
				}
			});

			final configFile = File(p.join(tempDir.path, 'pvtro.yaml'));
			await configFile.writeAsString(
				[
					'output: lib/generated_wrapper.dart',
					'verbose: false',
					'excluded_packages:',
					'  - shadcn_ui',
					'  - fake_wrapper_pkg',
				].join('\n'),
			);

			final baseConfig = await PvtroConfig.loadProjectConfig(tempDir.path);
			final config = PvtroConfig.fromArgs(
				['--verbose'],
				baseConfig: baseConfig,
			);

			expect(config.output, 'lib/generated_wrapper.dart');
			expect(config.verbose, isTrue);
			expect(config.excludedPackages, ['shadcn_ui', 'fake_wrapper_pkg']);
		});
	});

	group('generatePvtro', () {
		test('skips output when no translation layer exists', () async {
			final tempDir = await Directory.systemTemp.createTemp('pvtro_generate_');
			addTearDown(() async {
				if (await tempDir.exists()) {
					await tempDir.delete(recursive: true);
				}
			});

			await File(p.join(tempDir.path, 'pubspec.yaml')).writeAsString('''
name: example_app
environment:
  sdk: ^3.0.0
''');
			await Directory(p.join(tempDir.path, '.dart_tool')).create();
			await File(
				p.join(tempDir.path, '.dart_tool', 'package_config.json'),
			).writeAsString('''
{
  "configVersion": 2,
  "packages": []
}
''');

			final result = await writePvtroOutput(
				config: PvtroConfig.defaults(),
				projectPath: tempDir.path,
			);

			expect(result.hasTranslations, isFalse);
			expect(File(p.join(tempDir.path, PvtroConfig.defaultOutput)).existsSync(), isFalse);
		});

		test('writes canonical and configured output when custom output is set', () async {
			final tempDir = await Directory.systemTemp.createTemp('pvtro_generate_');
			addTearDown(() async {
				if (await tempDir.exists()) {
					await tempDir.delete(recursive: true);
				}
			});

			await File(p.join(tempDir.path, 'pubspec.yaml')).writeAsString('''
name: example_app
environment:
  sdk: ^3.0.0
''');
			await Directory(p.join(tempDir.path, '.dart_tool')).create();
			await File(
				p.join(tempDir.path, '.dart_tool', 'package_config.json'),
			).writeAsString('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "example_app",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    }
  ]
}
''');
			await File(p.join(tempDir.path, 'slang.yaml')).writeAsString('''
base_locale: en
input_directory: lib/i18n
output_directory: lib/i18n
output_file_name: translations.g.dart
''');
			await File(
				p.join(tempDir.path, 'lib', 'i18n', 'translations.g.dart'),
			).create(recursive: true);

			final result = await writePvtroOutput(
				config: PvtroConfig(
					output: 'lib/generated/pvtro.g.dart',
					verbose: false,
					help: false,
					excludedPackages: const [],
				),
				projectPath: tempDir.path,
			);

			expect(result.hasTranslations, isTrue);
			expect(result.canonicalOutputPath, PvtroConfig.defaultOutput);
			expect(
				File(p.join(tempDir.path, PvtroConfig.defaultOutput)).existsSync(),
				isTrue,
			);
			expect(
				File(p.join(tempDir.path, 'lib', 'generated', 'pvtro.g.dart')).existsSync(),
				isTrue,
			);
		});

		test('excludes configured packages from generation', () async {
			final tempDir = await Directory.systemTemp.createTemp('pvtro_generate_');
			addTearDown(() async {
				if (await tempDir.exists()) {
					await tempDir.delete(recursive: true);
				}
			});

			await File(p.join(tempDir.path, 'pubspec.yaml')).writeAsString('''
name: example_app
environment:
  sdk: ^3.0.0
''');
			await Directory(p.join(tempDir.path, '.dart_tool')).create();
			await File(
				p.join(tempDir.path, '.dart_tool', 'package_config.json'),
			).writeAsString('''
{
  "configVersion": 2,
  "packages": [
    {
      "name": "example_app",
      "rootUri": "../",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "shadcn_ui",
      "rootUri": "../packages/shadcn_ui",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    },
    {
      "name": "feature_shell",
      "rootUri": "../packages/feature_shell",
      "packageUri": "lib/",
      "languageVersion": "3.0"
    }
  ]
}
''');

			await File(p.join(tempDir.path, 'slang.yaml')).writeAsString('''
base_locale: en
input_directory: lib/i18n
output_directory: lib/i18n
output_file_name: translations.g.dart
''');
			await File(
				p.join(tempDir.path, 'lib', 'i18n', 'translations.g.dart'),
			).create(recursive: true);

			await File(p.join(tempDir.path, 'packages', 'shadcn_ui', 'slang.yaml')).create(recursive: true);
			await File(
				p.join(tempDir.path, 'packages', 'shadcn_ui', 'lib', 'i18n', 'translations.g.dart'),
			).create(recursive: true);

			await File(p.join(tempDir.path, 'packages', 'feature_shell', 'slang.yaml')).create(recursive: true);
			await File(
				p.join(tempDir.path, 'packages', 'feature_shell', 'lib', 'i18n', 'translations.g.dart'),
			).create(recursive: true);

			final result = await generatePvtro(
				config: PvtroConfig(
					output: PvtroConfig.defaultOutput,
					verbose: false,
					help: false,
					excludedPackages: const ['shadcn_ui'],
				),
				projectPath: tempDir.path,
			);

			expect(result.hasTranslations, isTrue);
			expect(result.packageCount, 2);
			expect(result.content, contains('package:example_app/i18n/translations.g.dart'));
			expect(result.content, contains('package:feature_shell/i18n/translations.g.dart'));
			expect(result.content, isNot(contains('package:shadcn_ui/i18n/translations.g.dart')));
		});
	});

	group('generateOutputFile', () {
		test('includes exported locale sync helper for discovered packages', () {
			final output = generateOutputFile([
				SlangPackageInfo(
					name: 'main_app',
					path: '/tmp/main_app',
					importPath: 'package:main_app/i18n/translations.g.dart',
					isMainPackage: true,
				),
				SlangPackageInfo(
					name: 'feature_shell',
					path: '/tmp/feature_shell',
					importPath: 'package:feature_shell/i18n/translations.g.dart',
				),
			]);

			expect(
				output,
				contains('Future<void> pvtroSyncPackageLocales(String rawLocale) async {'),
			);
			expect(
				output,
				contains('_\$0.LocaleSettings.setLocaleRaw(rawLocale),'),
			);
			expect(
				output,
				contains('_\$1.LocaleSettings.setLocaleRaw(rawLocale),'),
			);
		});

		test('keeps locale sync helper valid for empty package lists', () {
			final output = generateOutputFile([]);

			expect(
				output,
				contains('Future<void> pvtroSyncPackageLocales(String rawLocale) async {}'),
			);
		});
	});
}
