String apiDate(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

String displayDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';

class FlightOffer {
  const FlightOffer({
    required this.flightNumber,
    required this.airline,
    required this.departureTime,
    required this.arrivalTime,
    required this.durationMinutes,
    required this.price,
    required this.currency,
    required this.isSimulated,
  });

  factory FlightOffer.fromJson(Map<String, dynamic> json) => FlightOffer(
    flightNumber: json['flightNumber'] as String,
    airline: json['airline'] as String,
    departureTime: DateTime.parse(json['departureTime'] as String),
    arrivalTime: DateTime.parse(json['arrivalTime'] as String),
    durationMinutes: json['durationMinutes'] as int,
    price: (json['price'] as num).toDouble(),
    currency: json['currency'] as String,
    isSimulated: json['isSimulated'] as bool,
  );

  final String flightNumber;
  final String airline;
  final DateTime departureTime;
  final DateTime arrivalTime;
  final int durationMinutes;
  final double price;
  final String currency;
  final bool isSimulated;
}

class FlightSearchResponse {
  const FlightSearchResponse({
    required this.from,
    required this.to,
    required this.date,
    required this.source,
    required this.flights,
  });

  factory FlightSearchResponse.fromJson(Map<String, dynamic> json) =>
      FlightSearchResponse(
        from: json['from'] as String,
        to: json['to'] as String,
        date: DateTime.parse(json['date'] as String),
        source: json['source'] as String,
        flights: (json['flights'] as List<dynamic>)
            .map((item) => FlightOffer.fromJson(item as Map<String, dynamic>))
            .toList(),
      );

  final String from;
  final String to;
  final DateTime date;
  final String source;
  final List<FlightOffer> flights;

  bool get isSimulated =>
      source == 'simulated' || flights.any((flight) => flight.isSimulated);
}
