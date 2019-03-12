import 'dart:convert';
import 'dart:typed_data';

import 'package:web3dart/src/contracts/types/arrays.dart';
import 'package:web3dart/src/contracts/types/integers.dart';
import 'package:web3dart/src/contracts/types/type.dart';
import 'package:web3dart/src/utils/crypto.dart' as crypto;
import 'package:web3dart/src/utils/numbers.dart' as numbers;
import 'package:web3dart/web3dart.dart';

/// Helper class that defines a contract with a known ABI that has been deployed
/// on a Ethereum blockchain.
///
/// A future version of this library will automatically generate subclasses of
/// this based on the abi given, making it easier to call methods in contracts.
class DeployedContract {
  /// The lower-level ABI of this contract used to encode data to send in
  /// transactions when calling this contract.
  final ContractABI abi;

  /// The Ethereum address at which this contract is reachable.
  final EthereumAddress address;

  /// The client that will be used to send transactions or method calls.
  final Web3Client client;

  /// The credentials specify from which address transactions or calls will be
  /// made.
  final Credentials auth;

  /// Creates a new contract instance in the libary based on the given abi at
  /// the specified [address]. The contract needs to be deployed on the Ethereum
  /// net the [client] is connected to. The [auth] parameter controlls the
  /// address used to send transactions or calls.
  DeployedContract(this.abi, this.address, this.client, this.auth);

  /// Get a list of all functions defined by the contract ABI.
  List<ContractFunction> get functions => abi.functions;

  /// Finds all external or public functions defined by the contract that have
  /// the given name. As solidity supports function overloading, this will
  /// return a list as only a combination of name and types will uniquely find
  /// a function.
  Iterable<ContractFunction> findFunctionsByName(String name) =>
      functions.where((f) => f.name == name);

  /// Finds all methods that are constructors of this contract.
  ///
  /// Note that the library at the moment does not support creating contracts.
  Iterable<ContractFunction> get constructors =>
      functions.where((t) => t.isConstructor);
}

class ContractABI {
  static final RegExp _matchArray = RegExp(r'^(.+)\[(\d*)\]$');
  static final RegExp _arrayIndex = RegExp(r'(?=.*)(\d)+(?=\]$)');
  static final RegExp _beforeArray = RegExp(r'(.*)(?=\[)');

  /// Name of the contract
  final String name;

  /// All functions (including constructors) that the ABI of the contract
  /// defines.
  final List<ContractFunction> functions;

  ContractABI._(this.name, this.functions);

  static _ContractFunctionMutability _parseMutability(String m) {
    switch (m) {
      case 'pure':
        return _ContractFunctionMutability.pure;
      case 'view':
        return _ContractFunctionMutability.view;
      case 'nonpayable':
        return _ContractFunctionMutability.nonPayable;
      case 'payable':
        return _ContractFunctionMutability.payable;
      default:
        throw ArgumentError.value('Unknown mutability', 'm', m);
    }
  }

  static _ContractFunctionType _parseType(String t) {
    switch (t) {
      case 'function':
        return _ContractFunctionType.function;
      case 'constructor':
        return _ContractFunctionType.constructor;
      case 'default':
        return _ContractFunctionType.defaultConstr;
      default:
        throw ArgumentError.value('Unknown type', 't', t);
    }
  }

  static List<FunctionParameter> parseParameters(List<dynamic> data) {
    if (data == null || data.isEmpty) return [];

    final elements = <FunctionParameter>[];

    for (var element in data) {
      final name = element['name'] as String;
      final type = element['type'] as String;

      elements.add(FunctionParameter(name, parseType(type)));
    }

    return elements;
  }

  static ABIType parseType(String type) {
    //TODO Tuples
    if (_matchArray.hasMatch(type)) {
      final parsedType = parseType(_beforeArray.firstMatch(type).group(0));

      if (_arrayIndex.hasMatch(type)) {
        //fixed length array
        final length = int.parse(_arrayIndex.firstMatch(type).group(0));
        return StaticLengthArrayType(parsedType, length);
      }

      return DynamicLengthArrayType(parsedType);
    }

    if (type.startsWith('uint')) {
      if (type.length == 4) //just uint
        return UintType();
      final M = int.parse(type.substring(4));
      return UintType(M: M);
    } else if (type.startsWith('int')) {
      //TODO
    } else if (type.startsWith('fixed')) {
    } else if (type.startsWith('ufixed')) {
    } else if (type.startsWith('bytes')) {
      if (type.length == 5) //just bytes
        return DynamicLengthBytes();

      final length = int.parse(type.substring(5));
      return StaticLengthBytes(length);
    }
    //Names that only have a single name
    switch (type) {
      case 'string':
        return StringType();
      case 'address':
        return AddressType();
      case 'function':
        return FunctionType();
      case 'bool':
        return BoolType();

      default:
        throw ArgumentError.value('Unsupported type', 'type', type);
    }
  }

  static ContractABI parseFromJSON(String encoded, String name) {
    final data = json.decode(encoded);

    final functions = <ContractFunction>[];

    for (var element in data) {
      final type = element['type'] as String;
      if (type == 'event') continue;

      final name = element['name'] as String;
      final mutability = _parseMutability(element['stateMutability'] as String);

      final tp = _parseType(type);

      final inputs = parseParameters(element['inputs'] as List);
      final outputs = parseParameters(element['outputs'] as List);

      functions.add(ContractFunction(name, inputs,
          outputs: outputs, type: tp, mutability: mutability));
    }

    return ContractABI._(name, functions);
  }
}

/// A function defined in the ABI of an compiled contract.
class ContractFunction {
  /// The name of the function. Can be empty if it's an constructor or the
  /// default function.
  final String name;
  _ContractFunctionType _type;

  /// A list of types that represent the parameters required to call this
  /// function.
  final List<FunctionParameter> parameters;

  /// The return types of this function.
  final List<FunctionParameter> outputs;

  _ContractFunctionMutability _mutability;

  /// Returns true if this is the default function of a contract, which can be
  /// called when no other functions fit to an request.
  bool get isDefault => _type == _ContractFunctionType.defaultConstr;

  /// Returns true if this function is an constructor of the contract it belongs
  /// to. Mind that this library does currently not support deploying new
  /// contracts on the blockchain, it only supports calling functions of
  /// existing contracts.
  bool get isConstructor => _type == _ContractFunctionType.constructor;

  /// Returns true if this function is constant, i.e. it cannot modify the state
  /// of the blockchain when called. This allows the function to be called
  /// without sending Ether or gas as the connected client can compute it
  /// locally, no expensive mining will be required.
  bool get isConstant =>
      _mutability == _ContractFunctionMutability.view ||
      _mutability == _ContractFunctionMutability.pure;

  /// Returns true if this function can be used to send Ether to a smart
  /// contract that the contract will actually keep. Normally, all Ether sent
  /// with a transaction will be used to pay for gas fees and the rest will be
  /// sent back. Here however, the Ether (minus the fees) will be kept by the
  /// contract.
  bool get isPayable => _mutability == _ContractFunctionMutability.payable;

  ContractFunction(this.name, this.parameters,
      {this.outputs = const [],
      _ContractFunctionType type = _ContractFunctionType.function,
      _ContractFunctionMutability mutability =
          _ContractFunctionMutability.nonPayable}) {
    _type = type;
    _mutability = mutability;
  }

  /// Encodes a call to this function with the specified parameters for a
  /// transaction or a call that can be sent to the network.
  ///
  /// The [params] must be a list of dart types that will be converted. The
  /// following list shows what dart types are supported by what solidity/abi
  /// parameter types.
  ///
  /// * arrays (static and dynamic size), unless otherwise specified, will
  /// 	accept a dart List of the type of the array. The type "bytes" will
  /// 	accept a list of ints that should be in [0; 256].
  /// * strings will accept an dart string
  /// * bool will accept a dart bool
  /// * uint<x> and int<x> will accept a dart int
  ///
  /// Other types are not supported at the moment.
  String encodeCall(List<dynamic> params) {
    if (params.length != parameters.length)
      throw ArgumentError.value(
          params.length, 'params', 'Must match function parameters');

    //First four bytes to identify the function with its parameters
    final startHash = crypto.sha3(Uint8List.fromList(utf8.encode(encodeName()))).sublist(0, 4);

    /*
		We first have to encode every parameter that has a static length. For
		dynamic parameters, we will just create an integer that points to the position
		of where it will be after we're done entirely. Take for instance this example
		()
		 */

    final finishedEncodings = <String>[];
    final dynamicEncodings = <String>[];

    for (var i = 0; i < parameters.length; i++) {
      final parameter = parameters[i];
      final value = params[i];

      final encoded = parameter.type.encode(value);

      if (parameter.type.isDynamic) {
        dynamicEncodings.add(encoded);
        finishedEncodings.add('00' * 32); //will be set later
      } else {
        finishedEncodings.add(encoded);
      }
    }

    //Go trough all dynamic parameters again and calculate their position

    //First, calculate the size (in bytes) of the first part of the data, which
    //only includes static encodings and the relative positions for the dynamic
    //data.
    var currentOffset = finishedEncodings.fold<int>(0, (a, s) => a + s.length ~/ 2);
    for (var param in parameters.where((p) => p.type.isDynamic)) {
      final index = parameters.indexOf(param);

      finishedEncodings[index] =
          UintType().encode(BigInt.from(currentOffset));

      final firstDynamicEncoding = dynamicEncodings.first;
      dynamicEncodings.removeAt(0);

      finishedEncodings.add(firstDynamicEncoding);
      currentOffset += firstDynamicEncoding.length ~/ 2;
    }

    return numbers.bytesToHex(startHash, include0x: true) +
        finishedEncodings.join();
  }

  /// Encodes the name of the function and its required parameters.
  ///
  /// The encoding is specified here: https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector
  /// although this method will not apply the hash and just return the name
  /// followed by the types of the parameters, like this: bar(bytes,string[])
  String encodeName() {
    final parameterTypes = parameters.map((p) => p.type.name).join(',');
    return '$name($parameterTypes)';
  }

  /// Uses the known types of the function output to decode the value returned
  /// by a contract after making an call to it.
  ///
  /// The type of what this function returns is thus dependent from what it
  /// [outputs] are. For the conversions between dart types and solidity types,
  /// see the documentation for [encodeCall].
  List<dynamic> decodeReturnValues(String data) {
    var modifiedData = numbers.strip0x(data);

    final decoded = <dynamic>[];

    for (var param in outputs) {
      if (param.type.isDynamic) {
        decoded.add(null); //will be decoded later
        final decodedRaw = UintType().decodeRest(modifiedData);

        modifiedData = decodedRaw.item2; //remaining data
      } else {
        final decodedRaw = param.type.decodeRest(modifiedData);

        decoded.add(decodedRaw.item1);
        modifiedData = decodedRaw.item2; //remaining data
      }
    }

    //now that the data only consists of the dynamic data, decode it
    for (var i = 0; i < outputs.length; i++) {
      final param = outputs[i];

      if (param.type.isDynamic) {
        final decodedRaw = param.type.decodeRest(modifiedData);

        decoded[i] = decodedRaw.item1;
        modifiedData = decodedRaw.item2;
      }
    }

    return decoded;
  }
}

enum _ContractFunctionType { function, constructor, defaultConstr }

enum _ContractFunctionMutability { pure, view, nonPayable, payable }

/// The parameter of a function with its name and the expected type.
class FunctionParameter {
  final String name;
  final ABIType type;

  const FunctionParameter(this.name, this.type);
}
