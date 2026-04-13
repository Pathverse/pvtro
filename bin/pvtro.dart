import 'dart:io';
import 'package:pvtro/pvtro.dart';

/// Runs the default pvtro CLI entrypoint.
Future<void> main(List<String> args) async {
  exit(await runPvtroCli(args));
}
