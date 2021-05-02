import 'package:code_builder/code_builder.dart' hide FunctionType;

import '../../contracts.dart';
import '../../web3dart.dart';

const package = 'package:web3dart/web3dart.dart';

TypeReference referType(String name, [String? uri]) {
  return TypeReference((b) => b
    ..symbol = name
    ..url = uri);
}

final dartInt = referType('int', 'dart:core');
final dartBool = referType('bool', 'dart:core');
final string = referType('String', 'dart:core');
final bigInt = referType('BigInt', 'dart:core');
final uint8List = referType('Uint8List', 'dart:typed_data');

/// [Web3Client]
final web3Client = referType('Web3Client', package);

/// Refers to the [EthereumAddress] type.
final ethereumAddress = referType('EthereumAddress', package);

/// [Credentials].
final credentials = referType('Credentials', package);

/// [ContractAbi]
final contractAbi = referType('ContractAbi', package);

/// [DeployedContract]
final deployedContract = referType('DeployedContract', package);

final generatedContract = referType('GeneratedContract', package);

/// [ContractFunction]
final contractFunction = referType('ContractFunction', package);

/// [FunctionParameter]
final functionParameter = referType('FunctionParameter', package);

/// [CompositeFunctionParameter]
final compositeFunctionParameter =
    referType('CompositeFunctionParameter', package);

/// [UintType]
final uIntType = referType('UintType', package);

/// [IntType]
final intType = referType('IntType', package);

/// [BoolType]
final boolType = referType('BoolType', package);

/// [AddressType]
final addressType = referType('AddressType', package);

/// [FixedBytes]
final fixedBytes = referType('FixedBytes', package);

/// [FunctionType]
final functionType = referType('FunctionType', package);

/// Unknown, dynamic types.
final dynamicType = referType('dynamic', 'dart:core');

/// [DynamicBytes]
final dynamicBytes = referType('DynamicBytes', package);

/// [StringType]
final stringType = referType('StringType', package);

/// [transactionType]
final transactionType = referType('Transaction', package);

/// [FixedLengthArray]
final fixedLengthArray = referType('FixedLengthArray', package);

/// [DynamicLengthArray]
final dynamicLengthArray = referType('DynamicLengthArray', package);

/// [TupleType]
final tupleType = referType('TupleType', package);

final mutabilities = {
  StateMutability.pure: refer('StateMutability.pure', package),
  StateMutability.view: refer('StateMutability.view', package),
  StateMutability.nonPayable: refer('StateMutability.nonPayable', package),
  StateMutability.payable: refer('StateMutability.payable', package),
};

final functionTypes = {
  ContractFunctionType.function:
      refer('ContractFunctionType.function', package),
  ContractFunctionType.fallback:
      refer('ContractFunctionType.fallback', package),
  ContractFunctionType.constructor:
      refer('ContractFunctionType.constructor', package),
};

Reference futurize(Reference r) {
  return TypeReference((b) => b
    ..symbol = 'Future'
    ..types.add(r));
}

Reference listify(Reference r) {
  return TypeReference((b) => b
    ..symbol = 'List'
    ..types.add(r));
}

Expression callSuper(List<Expression> args) {
  return refer('super')(args);
}

/// Functions

final funSendTransaction = refer('client.sendTransaction');
final funCall = refer('client.call');
final funFunction = refer('self.function');
final funWrite = refer('write').call([argCredentials, argTransaction]).returned;
// final funConstantReturn = ;
final funCredentialsFromPrivateKey =
    refer('client.credentialsFromPrivateKey').awaited;
final funCallContract = refer('Transaction.callContract');
final funContractABI = refer('ContractAbi.fromJson');

/// Arguments

final argCredentials = refer('credentials');
final argTransaction = refer('transaction');

final argContract = refer('self');
final argFunction = refer('function');
final argParams = refer('params');

final argPrivateKey = refer('privateKey');

final argContractAddress = refer('contractAddress');

extension AbiTypeToDart on AbiType {
  TypeReference toDart() {
    if (this is AddressType) {
      return ethereumAddress;
    } else if (this is UintType || this is IntType) {
      return bigInt;
    } else if (this is StringType) {
      return string;
    } else if (this is BoolType) {
      return dartBool;
    }

    throw UnsupportedError('Type $this');
  }
}
