import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';

Builder solcBuilder(BuilderOptions _) => _SolcBuilder();

class _SolcBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      '.sol': ['.abi.json']
    };
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;

    final contractSource = await buildStep.readAsString(inputId);
    final response = await _solc(
      {
        'language': 'Solidity',
        'sources': {
          'contract': {
            'content': contractSource,
          }
        },
        'settings': {
          'outputSelection': {
            '*': {
              '*': ['metadata']
            }
          },
        },
      },
    );

    final contracts =
        ((response as Map)['contracts'] as Map)['contract'] as Map;
    final contract = contracts.values.single as Map;

    final outputId = inputId.changeExtension('.abi.json');
    final meta = json.decode(contract['metadata'] as String) as Map;
    await buildStep.writeAsString(outputId, json.encode(meta['output']));
  }

  Future<Object?> _solc(Object? input) async {
    final proc = await Process.start('solc', ['--standard-json']);
    final jsonUtf8 = json.fuse(utf8);

    await Stream.value(input).transform(jsonUtf8.encoder).pipe(proc.stdin);
    return proc.stdout.transform(jsonUtf8.decoder).first;
  }
}
