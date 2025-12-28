import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;

/// Package info from package_config.json
class PackageInfo {
  final String name;
  final String path;

  PackageInfo({required this.name, required this.path});

  @override
  String toString() => 'PackageInfo(name: $name, path: $path)';
}

/// Slang package with import path
class SlangPackageInfo {
  final String name;
  final String path;
  final String importPath; // e.g., 'package:pkg_a/i18n/strings.g.dart'
  final bool isMainPackage; // true if this is the root/main package

  SlangPackageInfo({
    required this.name,
    required this.path,
    required this.importPath,
    this.isMainPackage = false,
  });

  @override
  String toString() =>
      'SlangPackageInfo(name: $name, importPath: $importPath, isMain: $isMainPackage)';
}

/// Read package_config.json and return all package entries
Future<List<PackageInfo>> getPackageConfig(String projectPath) async {
  final configFile = File(p.join(projectPath, '.dart_tool', 'package_config.json'));
  
  if (!await configFile.exists()) {
    return [];
  }

  final content = await configFile.readAsString();
  final config = jsonDecode(content) as Map<String, dynamic>;
  final packages = config['packages'] as List<dynamic>? ?? [];

  final result = <PackageInfo>[];
  
  for (final pkg in packages) {
    final pkgMap = pkg as Map<String, dynamic>;
    final name = pkgMap['name'] as String;
    final rootUri = pkgMap['rootUri'] as String;

    // Resolve path relative to .dart_tool directory
    final resolvedPath = _resolvePackagePath(rootUri, projectPath);
    
    result.add(PackageInfo(name: name, path: resolvedPath));
  }

  return result;
}

/// Resolve package URI to absolute path
String _resolvePackagePath(String rootUri, String projectPath) {
  if (rootUri.startsWith('file:///')) {
    return Uri.parse(rootUri).toFilePath();
  }
  
  // Relative path - resolve from .dart_tool directory
  final dartToolDir = p.join(projectPath, '.dart_tool');
  return p.normalize(p.join(dartToolDir, rootUri));
}

/// Check if a package has slang support
/// Returns true if slang.yaml exists OR slang/slang_flutter is in dependencies
Future<bool> hasSlangSupport(String packagePath) async {
  // Check for slang.yaml
  final slangYaml = File(p.join(packagePath, 'slang.yaml'));
  if (await slangYaml.exists()) {
    return true;
  }

  // Check pubspec.yaml for slang dependencies
  final pubspecFile = File(p.join(packagePath, 'pubspec.yaml'));
  if (!await pubspecFile.exists()) {
    return false;
  }

  final content = await pubspecFile.readAsString();
  // Simple check - look for slang in dependencies
  return content.contains('slang:') || content.contains('slang_flutter:');
}

/// Find slang generated file in a package
/// Returns import path (e.g., 'package:pkg_a/i18n/translations.g.dart') or null
Future<String?> findStringsFile(String packagePath, String packageName) async {
  // Common locations for slang generated files
  // Note: slang can generate as strings.g.dart OR translations.g.dart
  final searchPaths = [
    'lib/i18n/strings.g.dart',
    'lib/i18n/translations.g.dart',
    'lib/l10n/strings.g.dart',
    'lib/l10n/translations.g.dart',
    'lib/translations/strings.g.dart',
    'lib/translations/translations.g.dart',
    'lib/generated/strings.g.dart',
    'lib/generated/translations.g.dart',
  ];

  for (final relativePath in searchPaths) {
    final file = File(p.join(packagePath, relativePath));
    if (await file.exists()) {
      // Convert to package import path
      final importPath = relativePath.replaceFirst('lib/', '');
      return 'package:$packageName/$importPath';
    }
  }

  // Fallback: search lib directory recursively for .g.dart files with slang patterns
  final libDir = Directory(p.join(packagePath, 'lib'));
  if (!await libDir.exists()) {
    return null;
  }

  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File) {
      final filename = p.basename(entity.path);
      if (filename == 'strings.g.dart' || filename == 'translations.g.dart') {
        // Convert absolute path to package import
        final relativePath = p.relative(entity.path, from: p.join(packagePath, 'lib'));
        return 'package:$packageName/$relativePath';
      }
    }
  }

  return null;
}

/// Scan all packages and return only those with slang implementations
/// Returns packages sorted with main package first, then dependencies
Future<List<SlangPackageInfo>> discoverSlangPackages(String projectPath) async {
  final allPackages = await getPackageConfig(projectPath);
  final slangPackages = <SlangPackageInfo>[];
  
  // Get the main package name from pubspec.yaml
  final mainPackageName = await _getMainPackageName(projectPath);

  for (final pkg in allPackages) {
    // Skip pvtro itself
    if (pkg.name == 'pvtro') continue;

    // Check if package has slang support
    if (!await hasSlangSupport(pkg.path)) continue;

    // Find the translations.g.dart file
    final importPath = await findStringsFile(pkg.path, pkg.name);
    if (importPath == null) continue;

    final isMain = pkg.name == mainPackageName;
    
    slangPackages.add(SlangPackageInfo(
      name: pkg.name,
      path: pkg.path,
      importPath: importPath,
      isMainPackage: isMain,
    ));
  }

  // Sort: main package first, then dependencies alphabetically
  slangPackages.sort((a, b) {
    if (a.isMainPackage) return -1;
    if (b.isMainPackage) return 1;
    return a.name.compareTo(b.name);
  });

  return slangPackages;
}

/// Get the main package name from pubspec.yaml
Future<String?> _getMainPackageName(String projectPath) async {
  final pubspecFile = File(p.join(projectPath, 'pubspec.yaml'));
  if (!await pubspecFile.exists()) return null;
  
  final content = await pubspecFile.readAsString();
  // Simple regex to extract name from pubspec
  final match = RegExp(r'^name:\s*(\S+)', multiLine: true).firstMatch(content);
  return match?.group(1);
}
