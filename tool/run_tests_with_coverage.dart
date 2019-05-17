import 'dart:convert';
import 'dart:io';

import 'package:coverage/coverage.dart';

void main() async {
  final coverage = await runAndCollect('tool/all_tests.dart',
      onExit: true, printOutput: true);
  File('coverage.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(json.encode(coverage), flush: true);
}
