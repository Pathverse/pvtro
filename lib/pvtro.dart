import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pvtro/config/pvtro_config.dart';
import 'package:pvtro/utils/package_scanner.dart';
import 'package:pvtro/utils/wrapper_generator.dart';

/// Describes the generated output for a pvtro run.
class PvtroGenerationResult {
	final String outputPath;
	final String canonicalOutputPath;
	final String content;
	final int packageCount;

	/// Creates a generation result for a completed pvtro run.
	const PvtroGenerationResult({
		required this.outputPath,
		required this.canonicalOutputPath,
		required this.content,
		required this.packageCount,
	});

	/// Reports whether a translation layer was discovered for generation.
	bool get hasTranslations => packageCount > 0;
}

/// Represents a user-facing generation failure.
class PvtroException implements Exception {
	final String message;

	/// Creates a generation exception with a readable message.
	const PvtroException(this.message);

	@override
	String toString() => message;
}

/// Writes verbose messages when requested by the active configuration.
typedef PvtroLogger = void Function(String message);

/// Loads optional project configuration from pvtro.yaml.
Future<PvtroConfig> loadPvtroProjectConfig(String projectPath) {
	return PvtroConfig.loadProjectConfig(projectPath);
}

/// Generates the wrapper content for a project without writing it to disk.
Future<PvtroGenerationResult> generatePvtro({
	required PvtroConfig config,
	required String projectPath,
	PvtroLogger? logger,
}) async {
	final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
	if (!await pubspecFile.exists()) {
		throw const PvtroException(
			'No pubspec.yaml found. Run this in a Flutter/Dart project.',
		);
	}

	if (config.verbose) {
		logger?.call('Scanning for slang packages in $projectPath...');
	}

	final packages = await discoverSlangPackages(projectPath);
	if (config.verbose) {
		logger?.call('Found ${packages.length} slang packages:');
		for (final pkg in packages) {
			logger?.call('  - ${pkg.name}: ${pkg.importPath}');
		}
	}

	if (packages.isEmpty) {
		logger?.call('No translation layer found. Skipping generation.');
		return PvtroGenerationResult(
			outputPath: config.output,
			canonicalOutputPath: PvtroConfig.defaultOutput,
			content: '',
			packageCount: 0,
		);
	}

	return PvtroGenerationResult(
		outputPath: config.output,
		canonicalOutputPath: PvtroConfig.defaultOutput,
		content: generateOutputFile(packages),
		packageCount: packages.length,
	);
}

/// Writes a generated file relative to the project root.
Future<void> writeGeneratedFile({
	required String projectPath,
	required String relativePath,
	required String content,
}) async {
	final outputFile = File(p.join(projectPath, relativePath));
	await outputFile.parent.create(recursive: true);
	await outputFile.writeAsString(content);
}

/// Writes generated output for a project to the configured file path.
Future<PvtroGenerationResult> writePvtroOutput({
	required PvtroConfig config,
	required String projectPath,
	PvtroLogger? logger,
}) async {
	final result = await generatePvtro(
		config: config,
		projectPath: projectPath,
		logger: logger,
	);

	if (!result.hasTranslations) {
		return result;
	}

	await writeGeneratedFile(
		projectPath: projectPath,
		relativePath: result.canonicalOutputPath,
		content: result.content,
	);

	if (result.outputPath != result.canonicalOutputPath) {
		await writeGeneratedFile(
			projectPath: projectPath,
			relativePath: result.outputPath,
			content: result.content,
		);
	}
	return result;
}

/// Runs the pvtro CLI using project config defaults plus explicit arguments.
Future<int> runPvtroCli(List<String> args) async {
	final projectPath = Directory.current.path;
	final projectConfig = await loadPvtroProjectConfig(projectPath);

	final PvtroConfig config;
	try {
		config = PvtroConfig.fromArgs(args, baseConfig: projectConfig);
	} catch (error) {
		stderr.writeln('Error: $error');
		PvtroConfig.printHelp();
		return 1;
	}

	if (config.help) {
		PvtroConfig.printHelp();
		return 0;
	}

	try {
		final result = await writePvtroOutput(
			config: config,
			projectPath: projectPath,
			logger: stdout.writeln,
		);
		if (!result.hasTranslations) {
			stdout.writeln('No translation layer found. Nothing generated.');
			return 0;
		}
		stdout.writeln('Generated ${result.canonicalOutputPath}');
		if (result.outputPath != result.canonicalOutputPath) {
			stdout.writeln('Copied ${result.outputPath}');
		}
		stdout.writeln('  ${result.packageCount} TranslationProviders wrapped');
		return 0;
	} on PvtroException catch (error) {
		stderr.writeln('Error: ${error.message}');
		return 1;
	} on FormatException catch (error) {
		stderr.writeln('Error: $error');
		return 1;
	}
}
