import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/services/session_service.dart';
import 'package:local_auth/local_auth.dart';

enum StartupSecurityResult { openHome, requireLogin, locked }

abstract class StartupSessionStore {
  Future<bool> hasLoginSession();
  Future<void> clearSession();
}

abstract class BiometricAuthenticator {
  Future<bool> hasBiometricSupport();
  Future<bool> hasDeviceCredentialSupport();
  Future<bool> authenticateWithBiometric();
  Future<bool> authenticateWithDeviceCredential();
}

class StartupSecurityService {
  static const int maxAttempts = 3;

  final StartupSessionStore sessionStore;
  final BiometricAuthenticator biometricAuthenticator;

  StartupSecurityService({
    this.sessionStore = const SessionStartupStore(),
    BiometricAuthenticator? biometricAuthenticator,
  }) : biometricAuthenticator =
           biometricAuthenticator ?? LocalAuthBiometricAuthenticator();

  Future<StartupSecurityResult> resolveStartup() async {
    if (!await sessionStore.hasLoginSession()) {
      return StartupSecurityResult.openHome;
    }

    if (await _hasBiometricSupport()) {
      final biometricAuthenticated = await _authenticateWithBiometric();
      if (biometricAuthenticated) {
        return StartupSecurityResult.openHome;
      }
    }

    if (!await _hasDeviceCredentialSupport()) {
      await sessionStore.clearSession();
      return StartupSecurityResult.openHome;
    }

    final deviceCredentialAuthenticated =
        await _authenticateWithDeviceCredential();
    if (deviceCredentialAuthenticated) {
      return StartupSecurityResult.openHome;
    }

    await sessionStore.clearSession();
    return StartupSecurityResult.openHome;
  }

  Future<bool> _hasBiometricSupport() async {
    try {
      return biometricAuthenticator.hasBiometricSupport();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _hasDeviceCredentialSupport() async {
    try {
      return biometricAuthenticator.hasDeviceCredentialSupport();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _authenticateWithBiometric() {
    return _authenticateWithRetry(
      biometricAuthenticator.authenticateWithBiometric,
    );
  }

  Future<bool> _authenticateWithDeviceCredential() {
    return _authenticateWithRetry(
      biometricAuthenticator.authenticateWithDeviceCredential,
    );
  }

  Future<bool> _authenticateWithRetry(Future<bool> Function() action) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      try {
        if (await action()) {
          return true;
        }
      } catch (_) {
        // Treat plugin errors like a failed attempt so the fallback can run.
      }
    }
    return false;
  }
}

class SessionStartupStore implements StartupSessionStore {
  const SessionStartupStore();

  @override
  Future<void> clearSession() => AuthStorage.clear();

  @override
  Future<bool> hasLoginSession() async {
    final session = await SessionService.loadSession();
    return session?.token != null && session?.idLogin != null;
  }
}

class LocalAuthBiometricAuthenticator implements BiometricAuthenticator {
  final LocalAuthentication _localAuth;

  LocalAuthBiometricAuthenticator([LocalAuthentication? localAuth])
    : _localAuth = localAuth ?? LocalAuthentication();

  @override
  Future<bool> hasBiometricSupport() async {
    final canCheck = await _localAuth.canCheckBiometrics;
    if (!canCheck) {
      return false;
    }

    final availableBiometrics = await _localAuth.getAvailableBiometrics();
    return availableBiometrics.isNotEmpty;
  }

  @override
  Future<bool> hasDeviceCredentialSupport() {
    return _localAuth.isDeviceSupported();
  }

  @override
  Future<bool> authenticateWithBiometric() {
    return _localAuth.authenticate(
      localizedReason: 'Gunakan sidik jari untuk membuka aplikasi',
      biometricOnly: true,
      persistAcrossBackgrounding: true,
    );
  }

  @override
  Future<bool> authenticateWithDeviceCredential() {
    return _localAuth.authenticate(
      localizedReason: 'Gunakan PIN atau pola perangkat untuk membuka aplikasi',
      biometricOnly: false,
      persistAcrossBackgrounding: true,
    );
  }
}
