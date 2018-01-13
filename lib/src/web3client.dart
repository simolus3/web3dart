import 'dart:async';

import "package:jsonrpc2/jsonrpc_io_client.dart";
import 'package:web3dart/src/io/rawtransaction.dart';
import 'package:web3dart/src/utils/amounts.dart';
import 'package:web3dart/src/utils/credentials.dart';
import "package:web3dart/src/utils/numbers.dart" as numbers;

/// Class for sending requests over an HTTP JSON-RPC API endpoint to Ethereum
/// clients. This library won't use the accounts feature of clients to use them
/// to create transactions, you will instead have to obtain private keys of
/// accounts yourself.
class Web3Client {

	ServerProxy _proxy;
	///Whether errors, handled or not, should be printed to the console.
	bool printErrors = false;

	Web3Client(String connectionUrl) {
		_proxy = new ServerProxy(connectionUrl);
	}

	Future _makeRPCCall(String function, [List<String> params = null]) async {
		try {
			var data = await _proxy.call(function, params);
			if (data is Error || data is Exception)
				throw data;

			return data;
		} catch (e) {
			if (printErrors)
				print(e);

			rethrow;
		}
	}

	/// Returns the version of the client we're sending requests to.
	Future<String> getClientVersion() {
		return _makeRPCCall("web3_clientVersion");
	}

	/// Returns the id of the network the client is currently connected to.
	///
	/// In a non-private network, the network ids usually correspond to the
	/// following networks:
	/// 1: Ethereum Mainnet
	/// 2: Morden Testnet (deprecated)
	/// 3: Ropsten Testnet
	/// 4: Rinkeby Testnet
	/// 42: Kovan Testnet
	Future<int> getNetworkId() {
		return _makeRPCCall("net_version").then((s) => int.parse(s));
	}

	/// Returns true if the node is actively listening for network connections.
	Future<bool> isListeningForNetwork() {
		return _makeRPCCall("net_listening");
	}

	/// Returns the amount of Ethereum nodes currently connected to the client.
	Future<int> getPeerCount() {
		return _makeRPCCall("net_peerCount")
				.then((s) => numbers.hexToInt(s).intValue());
	}

	/// Returns the version of the Ethereum-protocol the client is using.
	Future<int> getEtherProtocolVersion() {
		return _makeRPCCall("eth_protocolVersion");
	}

	/// Returns an object indicating whether the node is currently synchronising
	/// with its network.
	///
	/// If so, progress information is returned via [SyncInformation].
	Future<SyncInformation> getSyncStatus() async {
		var data = await _makeRPCCall("eth_syncing");

		if (data is Map) {
			return new SyncInformation.
				_(data["startingBlock"], data["currentBlock"], data["highestBlock"]);
		} else
			return new SyncInformation._(null, null, null);
	}

	/// Returns the amount of Ether typically needed to pay for one unit of gas.
	///
	/// Although not strictly defined, this value will typically be a sensible
	/// amount to use in the public blockchain and
	Future<EtherAmount> getGasPrice() async {
		var data = await _makeRPCCall("eth_gasPrice");

		return EtherAmount.fromUnitAndValue(EtherUnit.WEI, numbers.hexToInt(data));
	}

	/// Gets the balance of the account with the specified address.
	///
	/// If [atBlock] is set, it will not return the current balance but rather the
	/// balance the account has had at that block.
	Future<EtherAmount> getBalance(String address, {int atBlock}) {
		var blockParam = atBlock != null ?
			numbers.toHex(atBlock, pad:true, include0x: true) : "latest";
		
		return _makeRPCCall("eth_getBalance", [address, blockParam]).then((data) {
			return EtherAmount.fromUnitAndValue(EtherUnit.WEI, numbers.hexToInt(data));
		});
	}

	Future<int> getTransactionCount(String address, {int atBlock}) async {
		var blockParam = atBlock != null ?
			numbers.toHex(atBlock, pad:true, include0x: true) : "latest";
			
		return _makeRPCCall("eth_getTransactionCount", [address, blockParam])
				.then(numbers.hexToInt).then((d) => d.intValue());
	}

	/// Signs the given transaction using the keys supplied in the Credentials
	/// object to upload it to the client so that it can be executed.
	///
	/// Returns a hash of the transaction which, after the transaction has been
	/// included in a mined block, can be used to obtain detailed information
	/// about the transaction.
	Future<List<int>> sendRawTransaction(Credentials cred, RawTransaction transaction, {int chainId}) {
		chainId = chainId ?? 1;
		var data = transaction.sign(numbers.numberToBytes(cred.privateKey), chainId);

		return _makeRPCCall("eth_sendRawTransaction", [numbers.bytesToHex(data, include0x: true)])
				.then(numbers.hexToBytes);
	}
}

/// When the client is currently syncing its blockchain with the network, this
/// representation can be used to find information about at which block the node
/// was before the sync, at which node it currently is and at which block the
/// node will complete its sync.
class SyncInformation {

	/// The field represents the index of the block used in the synchronisation
	/// currently in progress.
	/// [startingBlock] is the block at which the sync started, [currentBlock] is
	/// the block that is currently processed and [finalBlock] is an estimate of
	/// the highest block number this synchronisation will contain.
	/// When the client is not syncing at the moment, these fields will be null
	/// and [isSyncing] will be false.
	final int startingBlock, currentBlock, finalBlock;

	/// Indicates whether this client is currently syncing its blockchain with
	/// other nodes.
	bool get isSyncing => startingBlock != null;

	SyncInformation._(this.startingBlock, this.currentBlock, this.finalBlock);

	@override
	String toString() {
		if (isSyncing)
			return "SyncInformation: from $startingBlock to $finalBlock, current: $currentBlock";
		else
			return "SyncInformation: Currently not performing a synchronisation";
	}
}