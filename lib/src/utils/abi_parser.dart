import 'package:code_builder/code_builder.dart' hide FunctionType;

import '../../contracts.dart';

const package = 'package:web3dart/web3dart.dart';

/// Refers to the [EthereumAddress] type.
final ethereumAddress = refer('EthereumAddress', package);

final dartInt = refer('int', 'dart:core');
final dartBool = refer('bool', 'dart:core');
final string = refer('String', 'dart:core');
final bigInt = TypeReference((b) => b
  ..symbol = 'BigInt'
  ..url = 'dart:core');
final uint8List = refer('Uint8List', 'dart:typed_data');

/// [Web3Client]
final web3Client = refer('Web3Client', package);

/// [Credentials].
final credentials = refer('Credentials', package);

/// [ContractAbi]
final contractAbi = refer('ContractAbi', package);

/// [DeployedContract]
final deployedContract = refer('DeployedContract', package);

/// [ContractFunction]
final contractFunction = refer('ContractFunction', package);

/// [FunctionParameter]
final functionParameter = refer('FunctionParameter', package);

/// [CompositeFunctionParameter]
final compositeFunctionParameter = refer('CompositeFunctionParameter', package);

/// [UintType]
final uIntType = refer('UintType', package);

/// [IntType]
final intType = refer('IntType', package);

/// [BoolType]
final boolType = refer('BoolType', package);

/// [AddressType]
final addressType = refer('AddressType', package);

/// [FixedBytes]
final fixedBytes = refer('FixedBytes', package);

/// [FunctionType]
final functionType = refer('FunctionType', package);

/// [DynamicType]
final dynamicType = refer('dynamic');

/// [DynamicBytes]
final dynamicBytes = refer('dynamicBytes', package);

/// [StringType]
final stringType = refer('StringType', package);

/// [transactionType]
final transactionType = refer('Transaction', package);

/// [FixedLengthArray]
final fixedLengthArray = refer('FixedLengthArray', package);

/// [DynamicLengthArray]
final dynamicLengthArray = refer('DynamicLengthArray', package);

/// [TupleType]
final tupleType = refer('TupleType', package);

final mutabilities = {
  StateMutability.pure: refer('StateMutability.pure', package),
  StateMutability.view: refer('StateMutability.view', package),
  StateMutability.nonPayable: refer('StateMutability.nonPayable', package),
  StateMutability.payable: refer('StateMutability.payable', package),
};

final functionTypes = {
  ContractFunctionType.function: refer('ContractFunctionType.function', package),
  ContractFunctionType.fallback: refer('ContractFunctionType.fallback', package),
  ContractFunctionType.constructor: refer('ContractFunctionType.constructor', package),
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

//=======================================

///[Functions]

final funSendTransaction = refer('client.sendTransaction');
final funCall = refer('client.call');
final funFunction = refer('contract.function');
final funWrite = refer('_write').call([argCredentials, argTransaction]).returned;
final funConstantReturn = refer('_read').call([argContract, argFunction, argParams]).asA(futurize(bigInt)).awaited.returned;
final funCredentialsFromPrivateKey = refer('client.credentialsFromPrivateKey').awaited;
final funCallContract = refer('Transaction.callContract');
final funDeployedContract = refer('DeployedContract');
final funContractABI = refer('ContractAbi.fromJson');

///[Arguments]

final argCredentials = refer('credentials');
final argTransaction = refer('transaction');

final argContract = refer('contract');
final argFunction = refer('function');
final argParams = refer('params');

final argPrivateKey = refer('privateKey');

final argContractAddress = refer('contractAddress');

///[NamedArguments]

final nArgContract = refer('contract: contract');
final nArgFunction = refer('function: function');
final nArgParams = refer('params: params');
final nArgParameters = refer('parameters: params');

final nArgChainId = refer('chainId: chainId');

///[Methods]

final readAndWriteMethods = [
  Method((b) => b
    ..name = '_read'
    ..lambda = false
    ..modifier = MethodModifier.async
    ..returns = futurize(listify(dynamicType))
    ..body = CodeExpression(funCall.call([nArgContract, nArgFunction, nArgParams]).code).awaited.returned.statement
    ..requiredParameters.addAll([
      Parameter((b) => b
        ..name = 'contract'
        ..type = deployedContract),
      Parameter((b) => b
        ..name = 'function'
        ..type = contractFunction),
      Parameter((b) => b
        ..name = 'params'
        ..type = listify(dynamicType))
    ])),
  Method((b) => b
    ..name = '_write'
    ..lambda = false
    ..modifier = MethodModifier.async
    ..returns = futurize(string)
    ..body = funSendTransaction.call([argCredentials, argTransaction, nArgChainId]).awaited.returned.statement
    ..requiredParameters.addAll([
      Parameter((b) => b
        ..name = 'credentials'
        ..type = credentials),
      Parameter((b) => b
        ..name = 'transaction'
        ..type = transactionType)
    ]))
];

extension ABIParsing on String {
  Reference toDart() {
    switch (this) {
      case 'uint256':
        return bigInt;
        break;
      case 'string':
        return string;
        break;
      case 'address':
        return ethereumAddress;
        break;
      default:
        return refer(this);
    }
  }
}
