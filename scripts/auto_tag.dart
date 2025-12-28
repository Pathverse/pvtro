import 'dart:io';

void main() async {
  // Get the last commit message
  final result = await Process.run('git', ['log', '-1', '--pretty=%B']);
  final commitMessage = result.stdout.toString().trim();

  print('Commit message: $commitMessage');

  String? newVersion;

  if (commitMessage.startsWith('env: bump ver')) {
    // Read version from pubspec.yaml
    newVersion = await readPubspecVersion();
    print('Using version from pubspec.yaml: $newVersion');
  } else if (commitMessage.startsWith('feat!:')) {
    // Bump minor version (y in x.y.z)
    newVersion = await bumpVersion(BumpType.minor);
    print('Bumped minor version: $newVersion');
  } else if (commitMessage.startsWith('feat:')) {
    // Bump patch version (z in x.y.z)
    newVersion = await bumpVersion(BumpType.patch);
    print('Bumped patch version: $newVersion');
  } else {
    print('No auto-tag trigger found in commit message.');
    return;
  }

  if (newVersion != null) {
    await createTag(newVersion);
  }
}

Future<String?> readPubspecVersion() async {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found');
    return null;
  }

  final content = await pubspecFile.readAsString();
  final versionMatch = RegExp(r'^version:\s*(.+)$', multiLine: true).firstMatch(content);
  
  if (versionMatch == null) {
    print('Error: version not found in pubspec.yaml');
    return null;
  }

  return versionMatch.group(1)!.trim();
}

Future<String?> getLatestTagVersion() async {
  // Try to get the latest tag
  final result = await Process.run('git', ['describe', '--tags', '--abbrev=0']);
  
  if (result.exitCode != 0) {
    // No tags exist, start from 0.0.0
    return '0.0.0';
  }

  final tag = result.stdout.toString().trim();
  // Remove 'v' prefix if present
  return tag.startsWith('v') ? tag.substring(1) : tag;
}

enum BumpType { patch, minor }

Future<String?> bumpVersion(BumpType type) async {
  final currentVersion = await getLatestTagVersion();
  if (currentVersion == null) return null;

  final parts = currentVersion.split('.');
  if (parts.length < 3) {
    print('Error: Invalid version format: $currentVersion');
    return null;
  }

  var major = int.tryParse(parts[0]) ?? 0;
  var minor = int.tryParse(parts[1]) ?? 0;
  var patch = int.tryParse(parts[2].split('-').first.split('+').first) ?? 0;

  switch (type) {
    case BumpType.minor:
      minor += 1;
      patch = 0;
      break;
    case BumpType.patch:
      patch += 1;
      break;
  }

  final newVersion = '$major.$minor.$patch';
  
  // Update pubspec.yaml with new version
  await updatePubspecVersion(newVersion);
  
  return newVersion;
}

Future<void> updatePubspecVersion(String newVersion) async {
  final pubspecFile = File('pubspec.yaml');
  if (!pubspecFile.existsSync()) {
    print('Error: pubspec.yaml not found');
    return;
  }

  var content = await pubspecFile.readAsString();
  content = content.replaceFirst(
    RegExp(r'^version:\s*.+$', multiLine: true),
    'version: $newVersion',
  );

  await pubspecFile.writeAsString(content);
  print('Updated pubspec.yaml to version $newVersion');

  // Amend the commit to include the version bump
  await Process.run('git', ['add', 'pubspec.yaml']);
  await Process.run('git', ['commit', '--amend', '--no-edit']);
}

Future<void> createTag(String version) async {
  final tagName = 'v$version';
  
  // Check if tag already exists
  final checkResult = await Process.run('git', ['tag', '-l', tagName]);
  if (checkResult.stdout.toString().trim().isNotEmpty) {
    print('Tag $tagName already exists, skipping.');
    return;
  }

  final result = await Process.run('git', ['tag', tagName]);
  
  if (result.exitCode == 0) {
    print('Created tag: $tagName');
    print('Run "git push origin $tagName" to push the tag and trigger publish.');
  } else {
    print('Error creating tag: ${result.stderr}');
  }
}
