import 'dart:convert';
import 'dart:typed_data';
import 'package:test/test.dart';
import 'package:web3dart/crypto.dart';

const Map<String, String> _privateKeysToAddress = {
  'a2fd51b96dc55aeb14b30d55a6b3121c7b9c599500c1beb92a389c3377adc86e':
      '76778e046D73a5B8ce3d03749cE6B1b3D6a12E36',
  'f1f7a560cf6a730df8404eca67e28c1d61a611634417aaa45aa3e2bec84dd71b':
      'C914Bb2ba888e3367bcecEb5C2d99DF7C7423706',
  '07a0eeacaf4eb0a43a75c4da0c22c22ab1b4bcc29cac198432b93fa71ec62b39':
      'ea7624696aA08Cec594e292eC16dcFC5dA9bDa1f',
};

void main() {
  _privateKeysToAddress.forEach((key, address) {
    test('finds correct address for private key', () {
      final publicKey = privateKeyBytesToPublic(hexToBytes(key));
      final foundAddress = publicKeyToAddress(publicKey);

      expect(bytesToHex(foundAddress), equalsIgnoringCase(address));
    });
  });

  test('finds public key for private key', () {
    expect(
        bytesToHex(privateKeyBytesToPublic(hexToBytes(
            'a392604efc2fad9c0b3da43b5f698a2e3f270f170d859912be0d54742275c5f6'))),
        '506bc1dc099358e5137292f4efdd57e400f29ba5132aa5d12b18dac1c1f6aab'
        'a645c0b7b58158babbfa6c6cd5a48aa7340a8749176b120e8516216787a13dc76');
  });

  test('produces a valid signature', () {
    // https://github.com/ethereumjs/ethereumjs-util/blob/8ffe697fafb33cefc7b7ec01c11e3a7da787fe0e/test/index.js#L523
    final hashedPayload = hexToBytes(
        '82ff40c0a986c6a5cfad4ddf4c3aa6996f1a7837f9c398e17e5de5cbd5a12b28');
    final privKey = hexToBytes(
        '3c9229289a6125f7fdf1885a77bb12c37a8d3b4962d936f7e3084dece32a3ca1');
    final sig = sign(hashedPayload, privKey);

    expect(
        sig.r,
        hexToInt(
            '99e71a99cb2270b8cac5254f9e99b6210c6c10224a1579cf389ef88b20a1abe9'));
    expect(
        sig.s,
        hexToInt(
            '129ff05af364204442bdb53ab6f18a99ab48acc9326fa689f228040429e3ca66'));
    expect(sig.v, 27);
  });

  test('signatures recover the public key of the signer', () {
    final messages = [
      'Hello world',
      'UTF8 chars ©âèíöu ∂øµ€',
      '🚀✨🌎',
      DateTime.now().toString()
    ];
    final privateKeys = [
      '3c9229289a6125f7fdf1885a77bb12c37a8d3b4962d936f7e3084dece32a3ca1',
      'a69ab6a98f9c6a98b9a6b8e9b6a8e69c6ea96b5050eb77a17e3ba685805aeb88',
      'ca7eb9798e79c8799ea79aec7be98a7b9a7c98ae7b98061a53be764a85b8e785',
      '192b519765c9589a6b8c9a486ab938cba9638ab876056237649264b9cb96d88f',
      'b6a8f6a96931ad89d3a98e69ad6b98794673615b74675d7b5a674ba82b648a6d'
    ];

    for (final message in messages) {
      final messageHash = keccak256(Uint8List.fromList(utf8.encode(message)));

      for (final privateKey in privateKeys) {
        final publicKey = privateKeyBytesToPublic(hexToBytes(privateKey));
        final signature = sign(messageHash, hexToBytes(privateKey));

        final recoveredPublicKey = ecRecover(messageHash, signature);
        expect(bytesToHex(publicKey), bytesToHex(recoveredPublicKey));
      }
    }
  });

  test('signature validity can be properly verified', () {
    final messages = [
      'Hello world',
      'UTF8 chars ©âèíöu ∂øµ€',
      '🚀✨🌎',
      DateTime.now().toString()
    ];
    final privateKeys = [
      '3c9229289a6125f7fdf1885a77bb12c37a8d3b4962d936f7e3084dece32a3ca1',
      'a69ab6a98f9c6a98b9a6b8e9b6a8e69c6ea96b5050eb77a17e3ba685805aeb88',
      'ca7eb9798e79c8799ea79aec7be98a7b9a7c98ae7b98061a53be764a85b8e785',
      '192b519765c9589a6b8c9a486ab938cba9638ab876056237649264b9cb96d88f',
      'b6a8f6a96931ad89d3a98e69ad6b98794673615b74675d7b5a674ba82b648a6d'
    ];
    final invalidPublicKeys = [
      '1cb507195305b0c70da9f0a60f06ae8d605a80f0abc05a08df50a50f8e085da0f5a8f0e508adf510f0b1827538649a7bc79a47d49ae64b06ac60a96195231241',
      '0c7a0980f1803b09c88a4c78a4186d48a76739a34a685075a084179a46c96a5d8705a0845a365254a34679a67413567a426ca1436e5758f96a57a5f78a4321a7',
      'c6b6a1c431b4a374d38a549ef7a659e7505fa07e574648a63537a6d546f85a48e73765a37a4d64c976a449a64e853a75684e9a75d964a8563e684a66ea058494',
      'ba969f86a968e76ba9769f6a98e6f98a6d9876f9a87b9f876eb987ac6b98a6d98f5a97645865e37a4264d3a63865187687917619876bc9a876d986fa9b861972',
      'a9173ba7961b6fdb37d618036b0abd8a7e6b9a7f6b98e769a861982639451982739ba9afd9e8a487146728354198a9fda9e481239145972364597a9da5976129',
    ];

    for (final message in messages) {
      final messageHash = keccak256(Uint8List.fromList(utf8.encode(message)));

      for (final privateKey in privateKeys) {
        final originalPublicKey =
            privateKeyBytesToPublic(hexToBytes(privateKey));
        final signature = sign(messageHash, hexToBytes(privateKey));

        expect(
          isValidSignature(messageHash, signature, originalPublicKey),
          isTrue,
          reason: 'The signature should be valid',
        );

        for (final invalidPublicKey in invalidPublicKeys) {
          expect(
            isValidSignature(
                messageHash, signature, hexToBytes(invalidPublicKey)),
            isFalse,
            reason: 'The signature should be invalid',
          );
        }
      }
    }
  });
}
