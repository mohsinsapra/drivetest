import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';

class CryptoService {
  final Uint8List key;

  CryptoService(this.key);

  String encrypt(String plaintext) {
    // Generate a random IV
    final iv = _generateRandomBytes(16);

    // Initialize cipher
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    cipher.init(
      true,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );

    // Encrypt
    final plaintextBytes = utf8.encode(plaintext);
    final encryptedBytes = cipher.process(Uint8List.fromList(plaintextBytes));

    // Prepend IV to encrypted data
    final encryptedData = Uint8List.fromList(iv + encryptedBytes);

    // Encode to Base64
    return base64.encode(encryptedData);
  }

  String decrypt(String encryptedBase64) {
    // Decode from Base64
    final encryptedData = base64.decode(encryptedBase64);

    // Extract IV and encrypted message
    final iv = encryptedData.sublist(0, 16);
    final encryptedBytes = encryptedData.sublist(16);

    // Initialize cipher
    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    cipher.init(
      false,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );

    // Decrypt
    final decryptedBytes = cipher.process(encryptedBytes);

    // Convert bytes to string
    return utf8.decode(decryptedBytes);
  }

  // Helper function to generate random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => random.nextInt(256)));
  }
}
