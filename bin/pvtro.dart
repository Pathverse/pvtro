import 'dart:io';
import 'package:pvtro/config/pvtro_config.dart';
import 'package:pvtro/utils/package_scanner.dart';
import 'package:pvtro/utils/wrapper_generator.dart';

Future<void> main(List<String> args) async {
  // Parse arguments
  final PvtroConfig config;
  try {
    config = PvtroConfig.fromArgs(args);
  } catch (e) {
    stderr.writeln('Error: $e');
    PvtroConfig.printHelp();
    exit(1);
  }

  // Show help
  if (config.help) {
    PvtroConfig.printHelp();
    exit(0);
  }

  // Run generation
  await runGenerate(config);
}

Future<void> runGenerate(PvtroConfig config) async {
  final projectPath = Directory.current.path;

  if (config.verbose) {
    print('🔍 Scanning for slang packages in $projectPath...');
  }

  // Check if this is a Flutter/Dart project
  final pubspecFile = File('$projectPath/pubspec.yaml');
  if (!await pubspecFile.exists()) {
    stderr.writeln('Error: No pubspec.yaml found. Run this in a Flutter/Dart project.');
    exit(1);
  }

  // Discover slang packages
  final packages = await discoverSlangPackages(projectPath);

  if (packages.isEmpty) {
    stderr.writeln('Error: No slang packages found.');
    stderr.writeln('Make sure your dependencies have slang configured and run `dart pub get`.');
    exit(1);
  }

  if (config.verbose) {
    print('📦 Found ${packages.length} slang packages:');
    for (final pkg in packages) {
      print('   - ${pkg.name}: ${pkg.importPath}');
    }
  }

  // Generate output
  final output = generateOutputFile(packages);

  // Write to file
  final outputFile = File(config.output);
  await outputFile.parent.create(recursive: true);
  await outputFile.writeAsString(output);

  print('✅ Generated ${config.output}');
  print('   ${packages.length} TranslationProviders wrapped');
}
