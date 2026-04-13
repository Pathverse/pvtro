import 'dart:io';

import 'package:build/build.dart';
import 'package:path/path.dart' as p;
import 'package:pvtro/config/pvtro_config.dart';
import 'package:pvtro/pvtro.dart';

/// The fixed build_runner output path supported by the pvtro builder.
const pvtroBuilderOutput = PvtroConfig.defaultOutput;

/// Creates the build_runner builder for generating the wrapper file.
Builder pvtroBuilder(BuilderOptions options) {
  final projectPath = Directory.current.path;
  final config = PvtroConfig.loadProjectConfigSync(projectPath);
  return _PvtroBuilder(configuredOutput: _normalizeAssetPath(config.output));
}

/// Normalizes a configured output path into a package asset path.
String _normalizeAssetPath(String outputPath) {
  return p.posix.normalize(outputPath.replaceAll('\\', '/'));
}

/// Computes all build outputs that must be declared for the current config.
Map<String, List<String>> _buildExtensionsFor(String configuredOutput) {
  final outputs = <String>[pvtroBuilderOutput];
  if (configuredOutput != pvtroBuilderOutput) {
    outputs.add(configuredOutput);
  }
  return {'pubspec.yaml': outputs};
}

/// Generates the pvtro wrapper as a source asset during a build.
class _PvtroBuilder implements Builder {
  final String configuredOutput;

  /// Creates the pvtro build_runner builder.
  _PvtroBuilder({required this.configuredOutput});

  @override
  Map<String, List<String>> get buildExtensions =>
    _buildExtensionsFor(configuredOutput);

  @override
  Future<void> build(BuildStep buildStep) async {
    final projectPath = Directory.current.path;
    final config = PvtroConfig.loadProjectConfigSync(
      projectPath,
    ).copyWith(output: configuredOutput);
    final result = await generatePvtro(
      config: config,
      projectPath: projectPath,
    );
    if (!result.hasTranslations) {
      return;
    }
    final outputId = AssetId(buildStep.inputId.package, pvtroBuilderOutput);
    await buildStep.writeAsString(outputId, result.content);
    if (result.outputPath != result.canonicalOutputPath) {
      final copyOutputId = AssetId(buildStep.inputId.package, result.outputPath);
      await buildStep.writeAsString(copyOutputId, result.content);
    }
  }
}