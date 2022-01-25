import 'dart:io';

import 'package:coverage/coverage.dart';

Future<void> main() async {
  final dir = Directory('test_coverage');
  final resolver = Resolver(packagesPath: '.packages');

  final files = await dir
      .list(recursive: true)
      .where((entity) => entity is File)
      .map((entity) => entity as File)
      .toList();

  final coverage = await HitMap.parseFiles(files);

  final output =
      coverage.formatLcov(resolver, reportOn: ['lib', 'test'], basePath: '.');
  await File('lcov.info').writeAsString(output);
}
