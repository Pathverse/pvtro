import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:pvtro/utils/package_scanner.dart';
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
}
