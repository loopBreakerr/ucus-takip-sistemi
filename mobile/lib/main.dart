import 'package:flutter/material.dart';

import 'screens/flights_screen.dart';
import 'services/flight_api_client.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.api});

  final FlightApiClient? api;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Uçuş Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006194),
          primary: const Color(0xFF006194),
          surface: const Color(0xFFFAF8FF),
        ),
        scaffoldBackgroundColor: const Color(0xFFFAF8FF),
      ),
      home: FlightsScreen(api: api),
    );
  }
}
