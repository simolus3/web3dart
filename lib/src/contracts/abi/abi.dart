import 'dart:convert';
import 'dart:typed_data';

import '../../crypto/formatting.dart';
import '../../crypto/keccak.dart';
import '../../utils/length_tracking_byte_sink.dart';
import 'arrays.dart';
import 'tuple.dart';
import 'types.dart';

enum ContractFunctionType {
  function,
  constructor,
  fallback,
}

const Map<String, ContractFunctionType> _functionTypeNames = {
  'function': ContractFunctionType.function,
  'constructor': ContractFunctionType.constructor,
  'fallback': ContractFunctionType.fallback,
};

/// The state mutability of a contract function defines how that function
/// interacts with the blockchain.
///
/// Functions whose mutability is either [pure] or [view] promise to not write
/// data to the blockchain. This allows Ethereum nodes to execute them locally
/// instead of sending a transaction for the invocation. That in turn makes them
/// free to use. Mutable functions, like [nonPayable] or [payable] may write to
/// the blockchain, which means that they can only be executed as part of a
/// transaction, which has gas costs.
enum StateMutability {
  /// Function whose output depends solely on it's input. It does not ready any
  /// state from the blockchain.
  pure,

  /// Function that reads from the blockchain, but doesn't write to it.
  view,

  /// Function that may write to the blockchain, but doesn't accept any Ether.
  nonPayable,

  /// Function that may write to the blockchain and additionally accepts Ether.
  payable,
}

const Map<String, StateMutability> _mutabilityNames = {
  'pure': StateMutability.pure,
  'view': StateMutability.view,
  'nonpayable': StateMutability.nonPayable,
  'payable': StateMutability.payable,
};

String _encodeParameters(Iterable<FunctionParameter> params) {
  return params.map((p) => p.type.name).join(',');
}

/// Defines the abi of a deployed Ethereum contract. The abi contains
/// information about the functions defined in that contract.
class ContractAbi {
  /// Name of the contract
  final String name;

  /// All functions (including constructors) that the ABI of the contract
  /// defines.
  final List<ContractFunction> functions;
  final List<ContractEvent> events;

  ContractAbi(this.name, this.functions, this.events);

  factory ContractAbi.fromJson(String jsonData, String name) {
    final data = json.decode(jsonData);
    final functions = <ContractFunction>[];
    final events = <ContractEvent>[];

    for (final element in data) {
      final type = element['type'] as String;
      final name = (element['name'] as String?) ?? '';

      if (type == 'event') {
        final anonymous = element['anonymous'] as bool;
        final components = <EventComponent>[];

        for (final entry in element['inputs']) {
          components.add(EventComponent(
              _parseParam(entry as Map), entry['indexed'] as bool));
        }

        events.add(ContractEvent(anonymous, name, components));
        continue;
      }

      final mutability = _mutabilityNames[element['stateMutability']];
      final parsedType = _functionTypeNames[element['type']];
      if (parsedType == null) continue;

      final inputs = _parseParams(element['inputs'] as List?);
      final outputs = _parseParams(element['outputs'] as List?);

      functions.add(ContractFunction(
        name,
        inputs,
        outputs: outputs,
        type: parsedType,
        mutability: mutability ?? StateMutability.nonPayable,
      ));
    }

    return ContractAbi(name, functions, events);
  }

  static List<FunctionParameter> _parseParams(List? data) {
    if (data == null || data.isEmpty) return [];

    final elements = <FunctionParameter>[];
    for (final entry in data) {
      elements.add(_parseParam(entry as Map));
    }

    return elements;
  }

  static FunctionParameter _parseParam(Map entry) {
    final name = entry['name'] as String;
    final typeName = entry['type'] as String;

    if (typeName.contains('tuple')) {
      final components = entry['components'] as List;
      return _parseTuple(name, typeName, _parseParams(components));
    } else {
      final type = parseAbiType(entry['type'] as String);
      return FunctionParameter(name, type);
    }
  }

  static CompositeFunctionParameter _parseTuple(
      String name, String typeName, List<FunctionParameter> components) {
    // The type will have the form tuple[3][]...[1], where the indices after the
    // tuple indicate that the type is part of an array.
    assert(RegExp(r'^tuple(?:\[\d*\])*$').hasMatch(typeName),
        '$typeName is an invalid tuple type');

    final arrayLengths = <int?>[];
    var remainingName = typeName;

    while (remainingName != 'tuple') {
      final arrayMatch = array.firstMatch(remainingName)!;
      remainingName = arrayMatch.group(1)!;

      final insideSquareBrackets = arrayMatch.group(2)!;
      if (insideSquareBrackets.isEmpty) {
        arrayLengths.insert(0, null);
      } else {
        arrayLengths.insert(0, int.parse(insideSquareBrackets));
      }
    }

    return CompositeFunctionParameter(name, components, arrayLengths);
  }
}

/// A function defined in the ABI of an compiled contract.
class ContractFunction {
  /// The name of the function. Can be empty if it's an constructor or the
  /// default function.
  final String name;

  /// The type of the contract function, determines whether this [isConstant] or
  /// [isConstructor].
  final ContractFunctionType type;

  /// A list of types that represent the parameters required to call this
  /// function.
  final List<FunctionParameter> parameters;

  /// The return types of this function.
  final List<FunctionParameter> outputs;

  /// The mutability of this function, determines whether this function is going
  /// to read or write to the blockchain when called.
  final StateMutability mutability;

  /// Returns true if this is the default function of a contract, which can be
  /// called when no other functions fit to an request.
  bool get isDefault => type == ContractFunctionType.fallback;

  /// Returns true if this function is an constructor of the contract it belongs
  /// to. Mind that this library does currently not support deploying new
  /// contracts on the blockchain, it only supports calling functions of
  /// existing contracts.
  bool get isConstructor => type == ContractFunctionType.constructor;

  /// Returns true if this function is constant, i.e. it cannot modify the state
  /// of the blockchain when called. This allows the function to be called
  /// without sending Ether or gas as the connected client can compute it
  /// locally, no expensive mining will be required.
  bool get isConstant =>
      mutability == StateMutability.view || mutability == StateMutability.pure;

  /// Returns true if this function can be used to send Ether to a smart
  /// contract that the contract will actually keep. Normally, all Ether sent
  /// with a transaction will be used to pay for gas fees and the rest will be
  /// sent back. Here however, the Ether (minus the fees) will be kept by the
  /// contract.
  bool get isPayable => mutability == StateMutability.payable;

  const ContractFunction(
    this.name,
    this.parameters, {
    this.outputs = const [],
    this.type = ContractFunctionType.function,
    this.mutability = StateMutability.nonPayable,
  });

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
  Uint8List encodeCall(List<dynamic> params) {
    if (params.length != parameters.length) {
      throw ArgumentError.value(
          params.length, 'params', 'Must match function parameters');
    }

    final sink = LengthTrackingByteSink()
      //First four bytes to identify the function with its parameters
      ..add(selector);

    TupleType(parameters.map((param) => param.type).toList())
        .encode(params, sink);

    return sink.asBytes();
  }

  /// Encodes the name of the function and its required parameters.
  ///
  /// The encoding is specified here: https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector
  /// although this method will not apply the hash and just return the name
  /// followed by the types of the parameters, like this: bar(bytes,string[])
  String encodeName() {
    final parameterTypes = _encodeParameters(parameters);
    return '$name($parameterTypes)';
  }

  /// The selector of this function, as described [by solidity].
  ///
  /// [by solidity]: https://solidity.readthedocs.io/en/develop/abi-spec.html#function-selector
  Uint8List get selector {
    return keccakUtf8(encodeName()).sublist(0, 4);
  }

  /// Uses the known types of the function output to decode the value returned
  /// by a contract after making an call to it.
  ///
  /// The type of what this function returns is thus dependent from what it
  /// [outputs] are. For the conversions between dart types and solidity types,
  /// see the documentation for [encodeCall].
  List<dynamic> decodeReturnValues(String data) {
    final tuple = TupleType(outputs.map((p) => p.type).toList());
    final buffer = hexToBytes(data).buffer;

    final parsedData = tuple.decode(buffer, 0);
    return parsedData.data;
  }
}

/// An event that can be emitted by a smart contract during a transaction.
class ContractEvent {
  /// Whether this events was declared as anonymous in solidity.
  final bool anonymous;
  final String name;

  /// A list of types that represent the parameters required to call this
  /// function.
  final List<EventComponent> components;

  ContractEvent(this.anonymous, this.name, this.components);

  /// The user-visible signature of this event, consisting of its name and the
  /// type of its parameters.
  String get stringSignature {
    final parameters = components.map((c) => c.parameter);
    return '$name(${_encodeParameters(parameters)})';
  }

  /// The signature of this event, which is the keccak hash of the event's name
  /// followed by it's components.
  late final Uint8List signature = keccakUtf8(stringSignature);

  /// Decodes the fields of this event from the event's [topics] and its [data]
  /// payload.
  ///
  /// [components] of this event which are [EventComponent.indexed] will be
  /// read from the topics, whereas non-indexed components will be read from the
  /// data section of the event.
  /// Indexed parameters which would take more than 32 bytes to encode are not
  /// included in the result. Apart from that, the order of the data returned
  /// is identical to the order of the [components].
  List<dynamic> decodeResults(List<String> topics, String data) {
    final topicOffset = anonymous ? 0 : 1;

    // non-indexed parameters are decoded like a tuple
    final notIndexed = components
        .where((c) => !c.indexed)
        .map((c) => c.parameter.type)
        .toList();
    final tuple = TupleType(notIndexed);

    final decodedNotIndexed = tuple.decode(hexToBytes(data).buffer, 0).data;

    // Merge indexed components (which are encoded as topics) and non-indexed
    // components (which were already decoded in decodedNotIndexed) together
    // into the result list.
    var dataIndex = 0;
    var topicIndex = topicOffset;

    final result = [];
    for (final component in components) {
      if (component.indexed) {
        // components that are bigger than 32 bytes when decoded, or have a
        // dynamic type, are not included in [topics]. A hash of the data will
        // be included instead. We can't decode these, so they will be skipped.
        final length = component.parameter.type.encodingLength;
        if (length.isDynamic || length.length! > 32) {
          topicIndex++;
          continue;
        }

        final topicBuffer = hexToBytes(topics[topicIndex]).buffer;
        result.add(component.parameter.type.decode(topicBuffer, 0).data);

        topicIndex++;
      } else {
        result.add(decodedNotIndexed[dataIndex]);
        dataIndex++;
      }
    }

    return result;
  }
}

/// A [FunctionParameter] that is a component of an event. Contains additional
/// information about whether the parameter is [indexed].
class EventComponent<T> {
  final FunctionParameter<T> parameter;
  final bool indexed;

  const EventComponent(this.parameter, this.indexed);
}

/// The parameter of a function with its name and the expected type.
class FunctionParameter<T> {
  final String name;
  final AbiType<T> type;

  const FunctionParameter(this.name, this.type);
}

/// A function parameter that includes other named parameter instead of just
/// wrapping single types.
///
/// Consider this contract:
/// ```solidity
/// pragma solidity >=0.4.19 <0.7.0;
/// pragma experimental ABIEncoderV2;
///
/// contract Test {
///   struct S { uint a; uint[] b; T[] c; }
///   struct T { uint x; uint y; }
///   function f(S memory s, T memory t, uint a) public;
///   function g() public returns (S memory s, T memory t, uint a);
/// }
/// ```
/// For the parameter `s` in the function `f`, we still want to know the names
/// of the components in the tuple. Simply knowing that it's a tuple is not
/// enough. Similarly, we want to know the names of the parameters of `T` in
/// `S.c`.
class CompositeFunctionParameter extends FunctionParameter<dynamic> {
  final List<FunctionParameter> components;

  /// If the composite type is wrapped in arrays, contains the length of these
  /// arrays. For instance, given a struct `S`, the type `S[3][][4]` would be
  /// represented with a [CompositeFunctionParameter] that has the components of
  /// `S` and [arrayLengths] of `[3, null, 4]`.
  final List<int?> arrayLengths;

  CompositeFunctionParameter(String name, this.components, this.arrayLengths)
      : super(name, _constructType(components, arrayLengths));

  static AbiType<dynamic> _constructType(
      List<FunctionParameter> components, List<int?> arrayLengths) {
    AbiType type = TupleType(components.map((c) => c.type).toList());

    for (final len in arrayLengths) {
      if (len != null) {
        type = FixedLengthArray(type: type, length: len);
      } else {
        type = DynamicLengthArray(type: type);
      }
    }

    return type;
  }
}
