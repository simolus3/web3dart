import 'dart:async';

import 'package:bignum/bignum.dart';
import 'package:meta/meta.dart';
import 'package:web3dart/src/io/rawtransaction.dart';
import 'package:web3dart/src/utils/credentials.dart';
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
			this._keys = keys;
			this._maxGas = maximumGas;
			this._gasPrice = gasPrice;
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
	void forceNonce(int nonce) => this._forceNonce = nonce;

	/// Configures this transaction so that it will send the specified amount of
	/// Ether to the account at the address specified in to.
	///
	/// Notice that the amount of Ether the recipient will actually receive is a
	/// bit lower due to the gas costs used by this transaction.
	FinalizedTransaction prepareForSimpleTransaction(String to, EtherAmount amount) {
		return new FinalizedTransaction._(this, numbers.hexToInt(to), amount, BigInteger.ZERO);
	}

	FinalizedTransaction prepareCustomTransaction(String to, EtherAmount amount, BigInteger data) {
		return new FinalizedTransaction._(this, numbers.hexToInt(to), amount, BigInteger.ZERO);
	}
}

class FinalizedTransaction {

	final Transaction base;
	final BigInteger receiver;
	final EtherAmount value;
	final BigInteger data;

	FinalizedTransaction._(this.base, this.receiver, this.value, this.data);

	BigInteger _getSenderAddress() => base._keys.address;

	Future<RawTransaction> _asRaw(Web3Client client) async {
		var sender = _getSenderAddress();

		var nonce = base._forceNonce ?? await client.getTransactionCount(
				numbers.toHex(sender, pad: true, include0x: true));

		var gasPrice = (base._gasPrice ?? await client.getGasPrice()).getInWei.intValue();

		return new RawTransaction(
			nonce: nonce,
			gasPrice: gasPrice,
			gasLimit: base._maxGas ?? 0,
			to: receiver,
			value: value.getInWei,
			data: data,
		);
	}

	/// Signs the transaction using the private key given in the constructor and
	/// submits it to an connected Ethereum client.
	Future<List<int>> send(Web3Client client) {
		return _asRaw(client).then((raw) {
			return client.sendRawTransaction(base._keys, raw);
		});
	}
}