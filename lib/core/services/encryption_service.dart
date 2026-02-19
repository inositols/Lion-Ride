import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  // 32-character key for AES-256
  // TODO: Move this to an environment variable (.env) for production
  static const String _keyString = 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6';
  final _key = Key.fromUtf8(_keyString);
  final _iv = IV.fromLength(16);

  late final Encrypter _encrypter;

  void init() {
    _encrypter = Encrypter(AES(_key));
  }

  /// Encrypt plain text using AES-256
  static String? encrypt(String? plainText) {
    if (plainText == null || plainText.isEmpty) return null;
    try {
      final encryptionService = EncryptionService();
      encryptionService.init(); // Ensure initialized
      final encrypted = encryptionService._encrypter.encrypt(plainText, iv: encryptionService._iv);
      return encrypted.base64;
    } catch (e) {
      print('Encryption Error: $e');
      return plainText; // Return original text on error to avoid data loss
    }
  }

  /// Decrypt encrypted text using AES-256
  static String? decrypt(String? encryptedText) {
    if (encryptedText == null || encryptedText.isEmpty) return null;
    try {
      final encryptionService = EncryptionService();
      encryptionService.init(); // Ensure initialized
      final decrypted = encryptionService._encrypter.decrypt64(encryptedText, iv: encryptionService._iv);
      return decrypted;
    } catch (e) {
      print('Decryption Error: $e');
      return encryptedText; // Return original text if decryption fails (might not be encrypted)
    }
  }
}
