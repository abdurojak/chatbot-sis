class AuthSession {
  final String token;
  final String idLogin;
  final String userId;
  final String nim;
  final String? color;
  final String? photoBase64;
  final String? active;
  final String? role;

  const AuthSession({
    required this.token,
    required this.idLogin,
    required this.userId,
    required this.nim,
    this.color,
    this.photoBase64,
    this.active,
    this.role,
  });

  factory AuthSession.fromLoginJson(Map<String, dynamic> json) {
    return AuthSession(
      token: _readString(json['token']),
      idLogin: _readString(json['IdLogin']),
      userId: _readString(json['userid']),
      nim: _readString(json['nim']),
      color: _readNullableString(json['color']),
      photoBase64: _readNullableString(json['photo']),
      active: _readNullableString(json['Active']),
      role: _readNullableString(json['role']),
    );
  }

  bool get isActive => active == '1';
  bool get isStudent => role == 'STD';
  bool get isLecturer => role == 'DSN';
  bool get isGuardian => role == 'OTW';

  AuthSession copyWith({String? role}) {
    return AuthSession(
      token: token,
      idLogin: idLogin,
      userId: userId,
      nim: nim,
      color: color,
      photoBase64: photoBase64,
      active: active,
      role: role ?? this.role,
    );
  }
}

class LoginResult {
  final bool isSuccess;
  final String message;
  final String? idOtp;
  final AuthSession? session;

  const LoginResult({
    required this.isSuccess,
    required this.message,
    this.idOtp,
    this.session,
  });

  factory LoginResult.fromJson(
    Map<String, dynamic> json, {
    required int statusCode,
  }) {
    final session = statusCode == 200 ? AuthSession.fromLoginJson(json) : null;
    final idOtp = _readNullableString(json['id_otp']);

    return LoginResult(
      isSuccess:
          statusCode == 200 &&
          session != null &&
          session.token.isNotEmpty &&
          idOtp != null &&
          idOtp.isNotEmpty,
      message: _readString(
        json['message'] ?? json['status'],
        fallback: statusCode == 200 ? 'Login berhasil' : 'Login gagal',
      ),
      idOtp: idOtp,
      session: session,
    );
  }
}

class OtpVerificationResult {
  final bool isSuccess;
  final String message;

  const OtpVerificationResult({required this.isSuccess, required this.message});

  factory OtpVerificationResult.fromJson(
    Map<String, dynamic> json, {
    required int statusCode,
  }) {
    return OtpVerificationResult(
      isSuccess: statusCode == 200,
      message: _readString(
        json['message'] ?? json['status'],
        fallback: statusCode == 200 ? 'OTP valid' : 'OTP tidak valid',
      ),
    );
  }
}

String _readString(dynamic value, {String fallback = ''}) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return fallback;
  }
  return text;
}

String? _readNullableString(dynamic value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) {
    return null;
  }
  return text;
}
