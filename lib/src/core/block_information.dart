import 'package:web3dart/src/crypto/formatting.dart';
import 'package:web3dart/web3dart.dart';

class BlockInformation {
  EtherAmount? baseFeePerGas;

  BlockInformation({this.baseFeePerGas});

  factory BlockInformation.fromJson(Map<String, dynamic> json) {
    return BlockInformation(
        baseFeePerGas: json.containsKey('baseFeePerGas')
            ? EtherAmount.fromUnitAndValue(
                EtherUnit.wei, hexToInt(json['baseFeePerGas'] as String))
            : null);
  }

  bool get isSupportEIP1559 => baseFeePerGas != null;
}
