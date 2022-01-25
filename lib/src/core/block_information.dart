import 'package:web3dart/src/crypto/formatting.dart';
import 'package:web3dart/web3dart.dart';

class BlockInformation {
  final EtherAmount? baseFeePerGas;
  final int timestamp;

  BlockInformation({
    required this.baseFeePerGas,
    required this.timestamp,
  });

  factory BlockInformation.fromJson(Map<String, dynamic> json) {
    return BlockInformation(
      baseFeePerGas: json.containsKey('baseFeePerGas')
          ? EtherAmount.fromUnitAndValue(
              EtherUnit.wei, hexToInt(json['baseFeePerGas'] as String))
          : null,
      timestamp: hexToDartInt(json['timestamp'] as String),
    );
  }

  bool get isSupportEIP1559 => baseFeePerGas != null;
}
