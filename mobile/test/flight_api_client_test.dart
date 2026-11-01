import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ucus_takip_mobile/services/flight_api_client.dart';

Map<String, dynamic> searchFixture({bool empty = false}) => {
  'from': 'IST',
  'to': 'FCO',
  'date': '2026-12-15',
  'source': 'simulated',
  'flights': empty
      ? []
      : [
          {
            'flightNumber': 'TK 1983',
            'airline': 'Türk Hava Yolları',
            'departureTime': '2026-12-15T23:30:00',
            'arrivalTime': '2026-12-16T02:20:00',
            'durationMinutes': 170,
            'price': 250.5,
            'currency': 'USD',
            'isSimulated': true,
          },
        ],
};

void main() {
  test('Uses shared endpoint, normalizes codes, and parses API JSON', () async {
    final api = FlightApiClient(
      baseUrl: 'http://localhost:5199',
      client: MockClient((request) async {
        expect(request.url.path, '/api/flights/search');
        expect(request.url.queryParameters, {
          'from': 'IST',
          'to': 'FCO',
          'date': '2026-12-15',
        });
        return http.Response.bytes(
          utf8.encode(jsonEncode(searchFixture())),
          200,
        );
      }),
    );
    addTearDown(api.close);
    final result = await api.search(
      from: ' ist ',
      to: 'fco',
      date: DateTime(2026, 12, 15),
    );
    expect(result.flights.single.airline, 'Türk Hava Yolları');
    expect(result.flights.single.price, 250.5);
    expect(result.flights.single.arrivalTime.day, 16);
    expect(result.isSimulated, isTrue);
  });

  for (final scenario in [
    (400, '{"error":"Geçersiz rota"}', 'Geçersiz rota'),
    (503, 'Unavailable', 'HTTP 503'),
    (200, '<html>Bad response</html>', 'geçersiz bir yanıt'),
    (200, '{}', 'beklenmeyen bir veri biçimi'),
  ]) {
    test('Handles response ${scenario.$1}: ${scenario.$3}', () async {
      final api = FlightApiClient(
        client: MockClient(
          (_) async =>
              http.Response.bytes(utf8.encode(scenario.$2), scenario.$1),
        ),
      );
      addTearDown(api.close);
      await expectLater(
        api.search(from: 'IST', to: 'FCO', date: DateTime(2026, 12, 15)),
        throwsA(
          isA<FlightApiException>().having(
            (error) => error.message,
            'message',
            contains(scenario.$3),
          ),
        ),
      );
    });
  }

  test('Connection failure becomes a readable error', () async {
    final api = FlightApiClient(
      client: MockClient((_) async => throw http.ClientException('offline')),
    );
    addTearDown(api.close);
    await expectLater(
      api.search(from: 'IST', to: 'FCO', date: DateTime(2026, 12, 15)),
      throwsA(
        isA<FlightApiException>().having(
          (error) => error.message,
          'message',
          contains('bağlanılamadı'),
        ),
      ),
    );
  });
}
