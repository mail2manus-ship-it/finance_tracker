import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores and verifies the app's local PIN. The PIN itself is never
/// written to disk -- only a salted SHA-256 hash is, via
/// flutter_secure_storage (Keychain on iOS, EncryptedSharedPreferences /
/// Keystore-backed on Android). `SettingsModel.pinEnabled` (in Isar) only
/// tracks whether the feature is turned on; the credential lives here.
class PinService {
  static const _storage = FlutterSecureStorage();
  static const _saltKey = 'pin_salt';
  static const _hashKey = 'pin_hash';

  Future<void> setPin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _saltKey, value: salt);
    await _storage.write(key: _hashKey, value: hash);
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _saltKey);
    final storedHash = await _storage.read(key: _hashKey);
    if (salt == null || storedHash == null) return false;
    return _hashPin(pin, salt) == storedHash;
  }

  Future<bool> hasPinSet() async {
    return (await _storage.read(key: _hashKey)) != null;
  }

  Future<void> clearPin() async {
    await _storage.delete(key: _saltKey);
    await _storage.delete(key: _hashKey);
  }

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}
