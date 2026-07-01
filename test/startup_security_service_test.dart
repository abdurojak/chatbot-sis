import 'package:chatbot/services/startup_security_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StartupSecurityService', () {
    test('allows home when session exists and biometric succeeds', () async {
      final service = StartupSecurityService(
        sessionStore: _FakeSessionStore(hasSession: true),
        biometricAuthenticator: _FakeBiometricAuthenticator(
          hasBiometrics: true,
          biometricResults: [true],
          deviceCredentialResults: [],
        ),
      );

      final result = await service.resolveStartup();

      expect(result, StartupSecurityResult.openHome);
    });

    test('uses device credential when biometric is unavailable', () async {
      final sessionStore = _FakeSessionStore(hasSession: true);
      final authenticator = _FakeBiometricAuthenticator(
        hasBiometrics: false,
        hasDeviceCredential: true,
        biometricResults: [],
        deviceCredentialResults: [true],
      );
      final service = StartupSecurityService(
        sessionStore: sessionStore,
        biometricAuthenticator: authenticator,
      );

      final result = await service.resolveStartup();

      expect(result, StartupSecurityResult.openHome);
      expect(authenticator.biometricAttemptCount, 0);
      expect(authenticator.deviceCredentialAttemptCount, 1);
      expect(sessionStore.wasCleared, isFalse);
    });

    test('uses device credential after biometric fails three times', () async {
      final sessionStore = _FakeSessionStore(hasSession: true);
      final authenticator = _FakeBiometricAuthenticator(
        hasBiometrics: true,
        hasDeviceCredential: true,
        biometricResults: [false, false, false],
        deviceCredentialResults: [true],
      );
      final service = StartupSecurityService(
        sessionStore: sessionStore,
        biometricAuthenticator: authenticator,
      );

      final result = await service.resolveStartup();

      expect(result, StartupSecurityResult.openHome);
      expect(authenticator.biometricAttemptCount, 3);
      expect(authenticator.deviceCredentialAttemptCount, 1);
      expect(sessionStore.wasCleared, isFalse);
    });

    test(
      'opens app and clears session after biometric and device credential fail three times',
      () async {
        final sessionStore = _FakeSessionStore(hasSession: true);
        final authenticator = _FakeBiometricAuthenticator(
          hasBiometrics: true,
          hasDeviceCredential: true,
          biometricResults: [false, false, false],
          deviceCredentialResults: [false, false, false],
        );
        final service = StartupSecurityService(
          sessionStore: sessionStore,
          biometricAuthenticator: authenticator,
        );

        final result = await service.resolveStartup();

        expect(result, StartupSecurityResult.openHome);
        expect(authenticator.biometricAttemptCount, 3);
        expect(authenticator.deviceCredentialAttemptCount, 3);
        expect(sessionStore.wasCleared, isTrue);
      },
    );

    test('opens app when no session exists', () async {
      final service = StartupSecurityService(
        sessionStore: _FakeSessionStore(hasSession: false),
        biometricAuthenticator: _FakeBiometricAuthenticator(
          hasBiometrics: true,
          biometricResults: [true],
          deviceCredentialResults: [],
        ),
      );

      final result = await service.resolveStartup();

      expect(result, StartupSecurityResult.openHome);
    });
  });
}

class _FakeSessionStore implements StartupSessionStore {
  bool hasSession;
  bool wasCleared = false;

  _FakeSessionStore({required this.hasSession});

  @override
  Future<void> clearSession() async {
    wasCleared = true;
    hasSession = false;
  }

  @override
  Future<bool> hasLoginSession() async => hasSession;
}

class _FakeBiometricAuthenticator implements BiometricAuthenticator {
  final bool hasBiometrics;
  final bool hasDeviceCredential;
  final List<bool> biometricResults;
  final List<bool> deviceCredentialResults;
  int biometricAttemptCount = 0;
  int deviceCredentialAttemptCount = 0;

  _FakeBiometricAuthenticator({
    required this.hasBiometrics,
    this.hasDeviceCredential = true,
    required this.biometricResults,
    required this.deviceCredentialResults,
  });

  @override
  Future<bool> authenticateWithBiometric() async {
    final index = biometricAttemptCount;
    biometricAttemptCount++;
    return biometricResults.length > index ? biometricResults[index] : false;
  }

  @override
  Future<bool> authenticateWithDeviceCredential() async {
    final index = deviceCredentialAttemptCount;
    deviceCredentialAttemptCount++;
    return deviceCredentialResults.length > index
        ? deviceCredentialResults[index]
        : false;
  }

  @override
  Future<bool> hasBiometricSupport() async => hasBiometrics;

  @override
  Future<bool> hasDeviceCredentialSupport() async => hasDeviceCredential;
}
