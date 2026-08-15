import 'package:local_auth/local_auth.dart';

/// Thin wrapper around `local_auth` so the rest of the app never touches
/// the plugin API directly -- keeps device-capability checks and error
/// handling in one place.
class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> isAvailable() async {
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      return canCheck && isSupported;
    } catch (_) {
      return false;
    }
  }

  /// Prompts Face ID / fingerprint / device-credential unlock. Returns
  /// false (rather than throwing) on any failure, including the user
  /// cancelling -- callers should fall back to the PIN screen either way.
  Future<bool> authenticate({String reason = 'Unlock My Personal Finance Tracker'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // allow device PIN/pattern as OS-level fallback
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
