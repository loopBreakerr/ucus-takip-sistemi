import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/flight_search_response.dart';

class FlightApiException implements Exception {
  const FlightApiException(this.message);
  final String message;
}

class FlightApiClient {
  FlightApiClient({http.Client? client, this.baseUrl = apiBaseUrl})
    : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<FlightSearchResponse> search({
    required String from,
    required String to,
    required DateTime date,
  }) async {
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    final uri = Uri.parse(base)
        .resolve('api/flights/search')
        .replace(
          queryParameters: {
            'from': from.trim().toUpperCase(),
            'to': to.trim().toUpperCase(),
            'date': apiDate(date),
          },
        );

    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 10));
      if (response.statusCode == 400) {
        final error =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        throw FlightApiException(
          error['error'] as String? ?? 'Arama bilgilerini kontrol et.',
        );
      }
      if (response.statusCode != 200) {
        throw FlightApiException(
          'Uçuş servisi yanıt veremedi (HTTP ${response.statusCode}). Lütfen tekrar dene.',
        );
      }
      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return FlightSearchResponse.fromJson(json);
    } on TimeoutException {
      throw const FlightApiException(
        'Uçuş servisi zamanında yanıt vermedi. Lütfen tekrar dene.',
      );
    } on http.ClientException {
      throw const FlightApiException(
        'Uçuş servisine bağlanılamadı. Bağlantını kontrol edip tekrar dene.',
      );
    } on FormatException {
      throw const FlightApiException(
        'Uçuş servisinden geçersiz bir yanıt alındı.',
      );
    } on TypeError {
      throw const FlightApiException(
        'Uçuş servisinden beklenmeyen bir veri biçimi alındı.',
      );
    }
  }

  void close() => _client.close();
}
