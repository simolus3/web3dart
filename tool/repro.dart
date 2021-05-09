import 'dart:convert';
import 'dart:io';

void main() async {
  final contractSource =
      await File('lib/src/generated/erc20.sol').readAsString();

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

  final contracts = ((response as Map)['contracts'] as Map)['contract'] as Map;
  final contract = contracts.values.single as Map;

  final meta = json.decode(contract['metadata'] as String) as Map;
  print(json.encode(meta['output']));
}

Future<Object?> _solc(Object? input) async {
  final proc = await Process.start('solc', ['--standard-json']);
  final jsonUtf8 = json.fuse(utf8);

  await Stream.value(input).transform(jsonUtf8.encoder).pipe(proc.stdin);
  return proc.stdout.transform(jsonUtf8.decoder).first;
}
