import 'dart:convert';

import '../../contracts.dart';

/// Parses solidity documentation comments from the generated compiler
/// output.
class Documentation {
  final String? contractDetails;
  final Map<ContractEvent, String> events;
  final Map<ContractFunction, String> functions;

  Documentation._(this.contractDetails, this.events, this.functions);

  String? forContract() => contractDetails?.asDartDoc;
  String? forEvent(ContractEvent e) => events[e]?.asDartDoc;
  String? forFunction(ContractFunction m) => functions[m]?.asDartDoc;

  static Documentation? fromJson(Map<String, Object?> json, ContractAbi abi) {
    if (json['version'] != 1) return null;

    final rawEvents = json['events'] as Map? ?? const {};
    final rawMethods = json['methods'] as Map? ?? const {};

    final details = json['details'] as String?;
    final methods = <ContractFunction, String>{};
    final events = <ContractEvent, String>{};

    for (final event in abi.events) {
      final signature = event.stringSignature;
      final match = (rawEvents[signature] as Map?)?.details;

      if (match != null) {
        events[event] = match;
      }
    }

    for (final method in abi.functions) {
      final signature = method.encodeName();
      final match = (rawMethods[signature] as Map?)?.details;

      if (match != null) {
        methods[method] = match;
      }
    }

    return Documentation._(details, events, methods);
  }
}

extension on Map {
  String? get details => this['details'] as String?;
}

extension on String {
  String get asDartDoc {
    return const LineSplitter()
        .convert(this)
        .map((line) => '/// $line')
        .join('\n');
  }
}
