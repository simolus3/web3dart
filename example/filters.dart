import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

const String rpcUrl = 'http://localhost:7545';

void main() async {
  final client = Web3Client(rpcUrl, Client());

  await client.events(FilterOptions()).take(3).listen(print).asFuture();

  await client.dispose();
}
