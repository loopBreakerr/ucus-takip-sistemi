import 'package:flutter/material.dart';

import '../models/flight_search_response.dart';

class FlightCard extends StatelessWidget {
  const FlightCard({
    super.key,
    required this.flight,
    required this.from,
    required this.to,
  });

  final FlightOffer flight;
  final String from;
  final String to;

  String _time(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final hours = flight.durationMinutes ~/ 60;
    final minutes = flight.durationMinutes % 60;
    final duration = [
      if (hours > 0) '$hours sa',
      if (minutes > 0 || hours == 0) '$minutes dk',
    ].join(' ');
    final departureDay = DateTime(
      flight.departureTime.year,
      flight.departureTime.month,
      flight.departureTime.day,
    );
    final arrivalDay = DateTime(
      flight.arrivalTime.year,
      flight.arrivalTime.month,
      flight.arrivalTime.day,
    );
    final dayOffset = arrivalDay.difference(departureDay).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFEAEDFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flight_rounded, color: primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      flight.flightNumber,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      flight.airline,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF596474),
                      ),
                    ),
                  ],
                ),
              ),
              if (flight.isSimulated)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDDB8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Simüle',
                    style: TextStyle(fontSize: 11, color: Color(0xFF684000)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: _airport(from, _time(flight.departureTime), false),
              ),
              Expanded(
                child: Column(
                  children: [
                    Icon(Icons.east_rounded, color: primary),
                    const SizedBox(height: 6),
                    Text(
                      duration,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF596474),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _airport(
                  to,
                  '${_time(flight.arrivalTime)}${dayOffset > 0 ? ' (+$dayOffset)' : ''}',
                  true,
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: Color(0xFFEAEDFF)),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                'Teklif fiyatı',
                style: TextStyle(fontSize: 13, color: Color(0xFF596474)),
              ),
              Text(
                '${flight.price.toStringAsFixed(flight.price == flight.price.roundToDouble() ? 0 : 2)} ${flight.currency}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _airport(String code, String time, bool alignEnd) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: [
      Text(
        code,
        style: const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.w800,
          color: Color(0xFF131B2E),
        ),
      ),
      const SizedBox(height: 6),
      Text(
        time,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ],
  );
}
