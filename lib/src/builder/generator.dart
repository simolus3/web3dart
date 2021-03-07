import 'dart:convert';

import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:web3dart/contracts.dart';
import 'package:path/path.dart' show url;

class ContractGenerator implements Builder {
  const ContractGenerator();

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      '.abi.json': ['.g.dart']
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final inputId = buildStep.inputId;
    final withoutExtension =
        inputId.path.substring(0, inputId.path.length - '.abi.json'.length);
    final name = _suggestName(withoutExtension);
    var abiCode = await buildStep.readAsString(buildStep.inputId);
    // Remove unecessary whitespace
    abiCode = json.encode(json.decode(abiCode));
    final abi = ContractAbi.fromJson(abiCode, name);

    final output = StringBuffer()..writeln('//@dart=2.9');
    _writeImports(output);
    _startClass(output, abiCode, name);
    for (final function in abi.functions) {
      _writeFunction(function, output);
    }
    _endClass(output);

    final outputId = AssetId(inputId.package, '$withoutExtension.g.dart');
    final formatter = DartFormatter();

    await buildStep.writeAsString(
        outputId, formatter.format(output.toString()));
  }

  String _suggestName(String pathWithoutExtension) {
    final base = url.basename(pathWithoutExtension);
    return base[0].toUpperCase() + base.substring(1);
  }

  void _writeImports(StringBuffer into) {
    into
      ..writeln("import 'dart:typed_data';")
      ..writeln("import 'package:web3dart/web3dart.dart';")
      ..writeln("import 'package:meta/meta.dart';");
  }

  void _startClass(StringBuffer into, String abi, String name) {
    into
      ..writeln('class $name {')
      ..writeln('static const _abiDefinition = ${asDartLiteral(abi)};')
      ..writeln('final Web3Client client;')
      ..writeln('final DeployedContract contract;')
      ..writeln('final int chainId;')
      ..writeln(
          '$name({@required this.client, @required EthereumAddress address, this.chainId = 1}):')
      ..writeln(
          "contract = DeployedContract(ContractAbi.fromJson(_abiDefinition, '$name'), address);");
  }

  void _writeFunction(ContractFunction function, StringBuffer into) {}

  void _endClass(StringBuffer into) {
    into.write('}');
  }
}

String asDartLiteral(String value) {
  final escaped = escapeForDart(value);
  return "'$escaped'";
}

String escapeForDart(String value) {
  return value
      .replaceAll("'", "\\'")
      .replaceAll('\$', '\\\$')
      .replaceAll('\r', '\\r')
      .replaceAll('\n', '\\n');
}
