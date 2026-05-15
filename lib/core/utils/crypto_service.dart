import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:archive/archive.dart';
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
    final encryptedData = base64.decode(encryptedBase64);
    final iv = encryptedData.sublist(0, 16);
    final encryptedBytes = encryptedData.sublist(16);

    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    cipher.init(
      false,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );

    final decryptedBytes = cipher.process(encryptedBytes);
    return utf8.decode(decryptedBytes);
  }

  /// Decrypt a response that was compressed-then-encrypted by the backend.
  /// Pipeline: base64 → AES-256-CBC decrypt → zlib decompress → UTF-8 string
  String decryptCompressed(String encryptedBase64) {
    final raw = base64.decode(encryptedBase64);
    final iv = Uint8List.fromList(raw.sublist(0, 16));
    final encryptedBytes = Uint8List.fromList(raw.sublist(16));

    final cipher = PaddedBlockCipher('AES/CBC/PKCS7');
    cipher.init(
      false,
      PaddedBlockCipherParameters(
        ParametersWithIV(KeyParameter(key), iv),
        null,
      ),
    );

    final compressed = Uint8List.fromList(cipher.process(encryptedBytes));
    final decompressed = const ZLibDecoder().decodeBytes(compressed);
    return utf8.decode(decompressed);
  }

  // Helper function to generate random bytes
  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
        List<int>.generate(length, (_) => random.nextInt(256)));
  }
}
