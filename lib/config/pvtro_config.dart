import 'package:args/args.dart';

/// CLI configuration options for pvtro
class PvtroConfig {
  final String output;
  final bool verbose;
  final bool web;
  final bool help;

  PvtroConfig({
    required this.output,
    required this.verbose,
    required this.web,
    required this.help,
  });

  /// Parse CLI arguments into config
  factory PvtroConfig.fromArgs(List<String> args) {
    final results = _parser.parse(args);
    
    return PvtroConfig(
      output: results['output'] as String,
      verbose: results['verbose'] as bool,
      web: results['web'] as bool,
      help: results['help'] as bool,
    );
  }

  /// Get the argument parser
  static ArgParser get parser => _parser;

  static final _parser = ArgParser()
    ..addOption(
      'output',
      abbr: 'o',
      help: 'Output file path for generated code',
      defaultsTo: 'lib/pvtro.g.dart',
    )
    ..addFlag(
      'verbose',
      abbr: 'v',
      help: 'Enable verbose logging',
      defaultsTo: false,
    )
    ..addFlag(
      'web',
      abbr: 'w',
      help: 'Enable cookie persistence for web',
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
    print('');
    print('Options:');
    print(_parser.usage);
  }
}
