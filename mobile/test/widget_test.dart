import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:ucus_takip_mobile/main.dart';
import 'package:ucus_takip_mobile/services/flight_api_client.dart';

import 'flight_api_client_test.dart' show searchFixture;

void main() {
  Future<void> search(WidgetTester tester) async {
    final button = find.byKey(const Key('searchButton'));
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pump();
  }

  testWidgets(
    'Loads API results, marks simulation and next-day arrival on a narrow screen',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final response = Completer<http.Response>();
      var calls = 0;
      final api = FlightApiClient(
        client: MockClient((_) {
          calls++;
          return response.future;
        }),
      );
      addTearDown(api.close);
      await tester.pumpWidget(MyApp(api: api));
      expect(calls, 0);
      await search(tester);
      expect(find.text('Aranıyor…'), findsOneWidget);
      expect(
        tester
            .widget<FilledButton>(find.byKey(const Key('searchButton')))
            .onPressed,
        isNull,
      );
      response.complete(
        http.Response.bytes(utf8.encode(jsonEncode(searchFixture())), 200),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('TK 1983'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Simüle'), findsOneWidget);
      expect(find.text('250.50 USD'), findsOneWidget);
      expect(find.text('02:20 (+1)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Validates same-airport search without calling API', (
    tester,
  ) async {
    var calls = 0;
    final api = FlightApiClient(
      client: MockClient((_) async {
        calls++;
        return http.Response(jsonEncode(searchFixture()), 200);
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(MyApp(api: api));
    await tester.enterText(find.byKey(const Key('toField')), 'ist');
    await search(tester);
    expect(find.text('Kalkış ve varış farklı olmalı.'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('Displays API error and retries into an empty result', (
    tester,
  ) async {
    var calls = 0;
    final api = FlightApiClient(
      client: MockClient((_) async {
        calls++;
        return calls == 1
            ? http.Response('{"error":"Rota hatasi"}', 400)
            : http.Response(jsonEncode(searchFixture(empty: true)), 200);
      }),
    );
    addTearDown(api.close);
    await tester.pumpWidget(MyApp(api: api));
    await search(tester);
    await tester.pumpAndSettle();
    expect(find.text('Rota hatasi'), findsOneWidget);
    await tester.ensureVisible(find.text('Tekrar dene'));
    await tester.tap(find.text('Tekrar dene'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Sefer bulunamadı.'), findsOneWidget);
    expect(calls, 2);
    expect(tester.takeException(), isNull);
  });
}
