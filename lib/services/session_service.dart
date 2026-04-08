import 'package:chatbot/component/authentication.dart';
import 'package:chatbot/models/auth_models.dart';

class SessionService {
  static Future<AuthSession?> loadSession() {
    return AuthStorage.loadSession();
  }

  static Future<bool> hasSession() async {
    return (await loadSession()) != null;
  }

  static Future<bool> hasActiveSession() async {
    final session = await loadSession();
    return session?.isActive ?? false;
  }
}
