import 'dart:async';

import 'package:meta/meta.dart';
import 'package:web3dart/conversions.dart';
import 'package:web3dart/src/io/rawtransaction.dart';
import "package:web3dart/src/utils/numbers.dart" as numbers;
import 'package:web3dart/web3dart.dart';

class Transaction {

	Credentials _keys;
	int _maxGas;
	EtherAmount _gasPrice;

	int _forceNonce;

	/// Constructs a new transaction which will be sent from the account
	/// associated with the given Credentials.
	///
	/// You can control the maximum amount of gas this transaction may use when being
	/// mined. Transferring Ether from one account to another will usually just
	/// require the base fee of transactions, about 21k gas total. Executing functions
	/// provided by a smart contract can take much more gas.
	/// You can optionally set a [gasPrice] to pay for gas. Higher gas prices
	/// mean that it is more attractive for miners to include this transaction in
	/// their blocks, meaning that it will be processed faster. By default, the
	/// library will query [Web3Client.getGasPrice] and use that value, which
	/// should result in your transaction being handled reasonably fast.
	Transaction({@required Credentials keys, @required int maximumGas, EtherAmount gasPrice}) {
			_keys = keys;
			_maxGas = maximumGas;
			_gasPrice = gasPrice;

			if (_maxGas == 0)
				_gasPrice = new EtherAmount.zero();
	}

	/// Forces this transaction to use the specified nonce.
	///
	/// Ethereum transaction include a nonce field so that an attacker won't be
	/// able to intercept a signed transaction and apply it multiple times. The
	/// nonce-field thus needs to be incremented by one for every transaction
	/// sent. By default, the library will lookup the amount of transactions sent
	/// by the sender before finalizing this transaction, so that the field will
	/// be set automatically. However, you can also set the field manually if you
	/// need to.
	void forceNonce(int nonce) => _forceNonce = nonce;

	/// Configures this transaction so that it will send the specified amount of
	/// Ether to the account at the address specified in to.
	FinalizedTransaction prepareForSimpleTransaction(EthereumAddress to, EtherAmount amount) {
		return new FinalizedTransaction._(this, to.number, amount, []);
	}

	/// Configures this transaction so that it will call the specified function
	/// in the deployed contract with the specified parameters.
	FinalizedTransaction prepareForCall(DeployedContract contract, ContractFunction function, List<dynamic> params) {
		return prepareForPaymentCall(contract, function, params, new EtherAmount.zero());
	}

	/// Configures this transaction so that it will call the specified function in
	/// the deployed contract with the specified parameters and send the specified
	/// amount of Ether to the contract.
	FinalizedTransaction prepareForPaymentCall(DeployedContract contract, ContractFunction function, List<dynamic> params, EtherAmount amount) {

		var isNoAmount = amount.getInWei == BigInt.zero;

		if (!isNoAmount && !function.isPayable)
			throw new Exception("Can't send Ether to to function that is not payable");

		var data = numbers.hexToBytes(function.encodeCall(params));

		return new FinalizedTransaction._(
				this, contract.address.number, amount, data,
				isConst: function.isConstant && isNoAmount, function: function);
	}

	FinalizedTransaction prepareCustomTransaction(String to, EtherAmount amount, List<int> data) {
		return new FinalizedTransaction._(this, to != null ? numbers.hexToInt(to) : to, amount, data);
	}
}

class FinalizedTransaction {

	final Transaction base;
	final BigInt receiver;
	final EtherAmount value;
	final List<int> data;

	final bool isConst;
	ContractFunction _function;

	FinalizedTransaction._(this.base, this.receiver, this.value, this.data, {this.isConst = false, ContractFunction function}) {
		_function = function;
	}

	Future<RawTransaction> _asRaw(Web3Client client) async {
		var nonce = base._forceNonce ?? await client.getTransactionCount(base._keys.address);

		var gasPrice = (base._gasPrice ?? await client.getGasPrice()).getInWei.toInt();

		return new RawTransaction(
			nonce: nonce,
			gasPrice: gasPrice,
			gasLimit: base._maxGas ?? 0,
			to: receiver,
			value: value.getInWei,
			data: data,
		);
	}

	/// Sends this transaction to the Ethereum client.
	Future<List<int>> send(Web3Client client, {int chainId = 1}) {
		return _asRaw(client).then((raw) {
			return client.sendRawTransaction(base._keys, raw, chainId: chainId);
		});
	}

	/// Sends this transaction to be executed immediately without modifying the
	/// state of the Blockchain. The data returned by the called contract will
	/// be returned here immediately as well.
	Future<List<dynamic>> call(Web3Client client, {int chainId = 1}) {
		if (!isConst)
			throw new Exception("Tried to call a transaction that modifys state");

		return _asRaw(client).then((raw) {
			return client.call(base._keys, raw, _function, chainId: chainId);
		});
	}
}

class TransactionInformation {

	/// The hash of the block containing this transaction. If this transaction has
	/// not been mined yet and is thus in no block, it will be `null`
	final String blockHash;

	/// [BlockNum] of the block containing this transaction. `null` when it's
	/// pending
	final BlockNum blockNumber;

	final EthereumAddress from;
	final int gas;
	final EtherAmount gasPrice;
	final String hash;
	final List<int> input;
	final int nonce;

	/// Address of the receiver. `null` when its a contract creation transaction
	final EthereumAddress to;

	/// Integer of the transaction's index position in the block. `null` when it's
	/// pending.
	int transactionIndex;

	final EtherAmount value;
	final int v;
	final List<int> r;
	final List<int> s;

	TransactionInformation.fromMap(Map<String, dynamic> map) :
			blockHash = map['blockHash'],
			blockNumber = map['blockNumber'] != null ?
			BlockNum.exact(int.parse(map['blockNumber'])) :
			BlockNum.pending(),
			from = EthereumAddress(map['from']),
			gas = int.parse(map['gas']),
			gasPrice = EtherAmount.inWei(BigInt.parse(map['gasPrice'])),
			hash = map['hash'],
			input = hexToBytes(map['input']),
			nonce = int.parse(map['nonce']),
			to = map['to'] != null ? EthereumAddress(map['to']) : null,
			transactionIndex = map['transactionIndex'] != null ?
				int.parse(map['transactionIndex']) :
				null,
			value = EtherAmount.inWei(BigInt.parse(map['value'])),
			v = int.parse(map['v']),
			r = hexToBytes(map['r']),
			s = hexToBytes(map['s']);
}