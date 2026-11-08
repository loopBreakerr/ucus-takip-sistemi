import 'dart:async';
import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class Account {
  const Account({required this.email, required this.roles});

  factory Account.fromJson(Map<String, dynamic> json) => Account(
    email: json['email'] as String,
    roles: (json['roles'] as List<dynamic>).cast<String>(),
  );

  final String email;
  final List<String> roles;

  bool get isAdmin => roles.contains('Admin');
  String get roleLabel => isAdmin ? 'Yönetici' : 'Kullanıcı';
}

class AccountApiException implements Exception {
  const AccountApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;
}

class AccountApiClient {
  static const _storage = FlutterSecureStorage(
    webOptions: WebOptions(useSessionStorage: true),
  );
  static const _tokenKey = 'account_session';
  static const _timeout = Duration(seconds: 10);

  final _http = http.Client();

  Future<Account?> restore() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) return null;
    try {
      final response = await _request('GET', 'me', token: token);
      return Account.fromJson(
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>,
      );
    } on AccountApiException catch (error) {
      if (error.statusCode != 401) rethrow;
      await _storage.delete(key: _tokenKey);
      return null;
    }
  }

  Future<void> register(String email, String password) async {
    await _request('POST', 'register', credentials: (email, password));
  }

  Future<Account> login(String email, String password) async {
    final response = await _request(
      'POST',
      'login',
      credentials: (email, password),
    );
    final session =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    final user = Account.fromJson(session);
    await _storage.write(key: _tokenKey, value: session['token'] as String);
    return user;
  }

  Future<void> logout() => _storage.delete(key: _tokenKey);

  Future<List<Account>> users() async {
    final token = await _storage.read(key: _tokenKey);
    if (token == null) {
      throw const AccountApiException('Yeniden giriş yap.', 401);
    }
    final response = await _request('GET', 'users', token: token);
    return (jsonDecode(utf8.decode(response.bodyBytes)) as List<dynamic>)
        .map((item) => Account.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<http.Response> _request(
    String method,
    String endpoint, {
    (String, String)? credentials,
    String? token,
  }) async {
    final request = http.Request(
      method,
      Uri.parse(apiBaseUrl).resolve('/api/auth/$endpoint'),
    );
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    if (credentials case (final email, final password)) {
      request.headers['Content-Type'] = 'application/json';
      request.body = jsonEncode({'email': email, 'password': password});
    }

    final http.Response response;
    try {
      response = await _http
          .send(request)
          .then(http.Response.fromStream)
          .timeout(_timeout);
    } on TimeoutException {
      throw const AccountApiException('Hesap servisi zamanında yanıt vermedi.');
    } on http.ClientException {
      throw const AccountApiException('Hesap servisine bağlanılamadı.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response;
    }

    final message = switch (response.statusCode) {
      400 => _validationError(response),
      401 when endpoint == 'login' => 'E-posta veya parola hatalı.',
      401 => 'Oturum sona erdi. Yeniden giriş yap.',
      403 => 'Bu ekran yalnızca yöneticilere açık.',
      429 => 'Çok fazla deneme yapıldı. Bir dakika sonra yeniden dene.',
      503 => 'Hesap servisi yapılandırılmamış.',
      _ => 'İşlem tamamlanamadı. Yeniden dene.',
    };
    throw AccountApiException(message, response.statusCode);
  }

  String _validationError(http.Response response) {
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map<String, dynamic> && body['error'] is String) {
        return body['error'] as String;
      }
    } on FormatException {
      // Some server errors do not include a JSON body.
    }
    return 'E-posta adresini ve parolayı kontrol et.';
  }

  void close() => _http.close();
}
