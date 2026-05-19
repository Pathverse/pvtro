import 'dart:io';

import 'package:args/args.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// CLI configuration options for pvtro
class PvtroConfig {
  /// The default generated wrapper output path.
  static const defaultOutput = 'lib/pvtro.g.dart';

  final String output;
  final bool verbose;
  final bool help;
  final List<String> excludedPackages;

  PvtroConfig({
    required this.output,
    required this.verbose,
    required this.help,
    required this.excludedPackages,
  });

  /// Returns the default configuration when no overrides are provided.
  factory PvtroConfig.defaults() {
    return PvtroConfig(
      output: defaultOutput,
      verbose: false,
      help: false,
      excludedPackages: const [],
    );
  }

  /// Parse CLI arguments into config
  factory PvtroConfig.fromArgs(List<String> args, {PvtroConfig? baseConfig}) {
    final results = _parser.parse(args);
    final defaults = baseConfig ?? PvtroConfig.defaults();
    
    return PvtroConfig(
      output: results.wasParsed('output')
          ? results['output'] as String
          : defaults.output,
      verbose: results.wasParsed('verbose')
          ? results['verbose'] as bool
          : defaults.verbose,
      help: results['help'] as bool,
      excludedPackages: defaults.excludedPackages,
    );
  }

  /// Loads project configuration from pvtro.yaml when it exists.
  static Future<PvtroConfig> loadProjectConfig(String projectPath) async {
    final configFile = File(p.join(projectPath, 'pvtro.yaml'));
    if (!await configFile.exists()) {
      return PvtroConfig.defaults();
    }

    return _parseConfig(await configFile.readAsString());
  }

  /// Loads project configuration synchronously for builder setup.
  static PvtroConfig loadProjectConfigSync(String projectPath) {
    final configFile = File(p.join(projectPath, 'pvtro.yaml'));
    if (!configFile.existsSync()) {
      return PvtroConfig.defaults();
    }

    return _parseConfig(configFile.readAsStringSync());
  }

  /// Returns a copy of this config with selected fields replaced.
  PvtroConfig copyWith({
    String? output,
    bool? verbose,
    bool? help,
    List<String>? excludedPackages,
  }) {
    return PvtroConfig(
      output: output ?? this.output,
      verbose: verbose ?? this.verbose,
      help: help ?? this.help,
      excludedPackages: excludedPackages ?? this.excludedPackages,
    );
  }

  /// Parses project configuration from raw YAML content.
  static PvtroConfig _parseConfig(String yamlContent) {
    final parsed = loadYaml(yamlContent);
    if (parsed == null) {
      return PvtroConfig.defaults();
    }

    if (parsed is! YamlMap) {
      throw FormatException('pvtro.yaml must contain a top-level mapping.');
    }

    return PvtroConfig(
      output: _readString(parsed, 'output') ?? defaultOutput,
      verbose: _readBool(parsed, 'verbose') ?? false,
      help: false,
      excludedPackages: _readStringList(parsed, 'excluded_packages') ?? const [],
    );
  }

  /// Reads a string key from YAML and validates its type.
  static String? _readString(YamlMap yamlMap, String key) {
    final value = yamlMap[key];
    if (value == null) {
      return null;
    }

    if (value is! String) {
      throw FormatException('pvtro.yaml key "$key" must be a string.');
    }

    return value;
  }

  /// Reads a boolean key from YAML and validates its type.
  static bool? _readBool(YamlMap yamlMap, String key) {
    final value = yamlMap[key];
    if (value == null) {
      return null;
    }

    if (value is! bool) {
      throw FormatException('pvtro.yaml key "$key" must be a boolean.');
    }

    return value;
  }

  /// Reads a string list key from YAML and validates its type.
  static List<String>? _readStringList(YamlMap yamlMap, String key) {
    final value = yamlMap[key];
    if (value == null) {
      return null;
    }

    if (value is! YamlList) {
      throw FormatException('pvtro.yaml key "$key" must be a list of strings.');
    }

    final result = <String>[];
    for (final item in value) {
      if (item is! String) {
        throw FormatException('pvtro.yaml key "$key" must be a list of strings.');
      }
      result.add(item);
    }
    return result;
  }

  /// Get the argument parser
  static ArgParser get parser => _parser;

  static final _parser = ArgParser()
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output file path for generated code',
      defaultsTo: defaultOutput,
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Enable verbose logging',
      defaultsTo: false,
    )
    ..addFlag(
      'help',
      abbr: 'h',
      help: 'Show this help message',
      negatable: false,
    );

  /// Print help message
  static void printHelp() {
    print('pvtro - Flutter translation coordination tool');
    print('');
    print('Usage: dart run pvtro [options]');
    print('Config file: pvtro.yaml (optional, project root)');
    print('');
    print('Options:');
    print(_parser.usage);
  }
}
