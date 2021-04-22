import '../credentials/address.dart';
import 'abi/abi.dart';

/// Helper class that defines a contract with a known ABI that has been deployed
/// on a Ethereum blockchain.
///
/// A future version of this library will automatically generate subclasses of
/// this based on the abi given, making it easier to call methods in contracts.
class DeployedContract {
  /// The lower-level ABI of this contract used to encode data to send in
  /// transactions when calling this contract.
  final ContractAbi abi;

  /// The Ethereum address at which this contract is reachable.
  final EthereumAddress address;

  DeployedContract(this.abi, this.address);

  /// Get a list of all functions defined by the contract ABI.
  List<ContractFunction> get functions => abi.functions;

  /// A list of all events defined in the contract ABI.
  List<ContractEvent> get events => abi.events;

  /// Finds all external or public functions defined by the contract that have
  /// the given name. As solidity supports function overloading, this will
  /// return a list as only a combination of name and types will uniquely find
  /// a function.
  Iterable<ContractFunction> findFunctionsByName(String name) =>
      functions.where((f) => f.name == name);

  /// Finds the external or public function defined by the contract that has the
  /// provided [name].
  ///
  /// If no, or more than one function matches that description, this method
  /// will throw.
  ContractFunction function(String name) =>
      functions.singleWhere((f) => f.name == name);

  /// Finds the event defined by the contract that has the matching [name].
  ///
  /// If no, or more than one event matches that name, this method will throw.
  ContractEvent event(String name) => events.singleWhere((e) => e.name == name);

  /// Finds all methods that are constructors of this contract.
  ///
  /// Note that the library at the moment does not support creating contracts.
  Iterable<ContractFunction> get constructors =>
      functions.where((t) => t.isConstructor);
}
