import 'dart:io';

import 'package:coverage/coverage.dart';

Future<void> main() async {
  final dir = Directory('test_coverage');
  final resolver = Resolver(packagesPath: '.packages', packageRoot: '.');

  final files = await dir
      .list(recursive: true)
      .where((entity) => entity is File)
      .map((entity) => entity as File)
      .toList();
  final coverage = await parseCoverage(files, 0);

  final formatter =
      LcovFormatter(resolver, reportOn: ['lib', 'test'], basePath: '.');
  final output = await formatter.format(coverage);

  await File('lcov.info').writeAsString(output);
}
