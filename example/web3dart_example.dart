import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

const String _PRIVATE_KEY = "c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3";
const String _URL = "http://localhost:7545";

main() async {
	var httpClient = new Client();
	Web3Client client = new Web3Client(_URL, httpClient);
	client.printErrors = true;

	var credentials = Credentials.fromHexPrivateKey(_PRIVATE_KEY);
  
	//Set up a new transaction
	new Transaction(keys: credentials, maximumGas: 100000)
		.prepareForSimpleTransaction( //that will transfer 2 ether
			"0xf17f52151EbEF6C7334FAD080c5704D77216b732",
			EtherAmount.fromUnitAndValue(EtherUnit.ETHER, 2))
		.send(client); //and send.
}
