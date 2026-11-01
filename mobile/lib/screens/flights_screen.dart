import 'package:flutter/material.dart';

import '../models/flight_search_response.dart';
import '../services/flight_api_client.dart';
import '../widgets/flight_card.dart';

class FlightsScreen extends StatefulWidget {
  const FlightsScreen({super.key, this.api});
  final FlightApiClient? api;

  @override
  State<FlightsScreen> createState() => _FlightsScreenState();
}

class _FlightsScreenState extends State<FlightsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _from = TextEditingController(text: 'IST');
  final _to = TextEditingController(text: 'FCO');
  final _dateText = TextEditingController();
  late final FlightApiClient _api;
  late DateTime _date;
  bool _loading = false;
  String? _error;
  FlightSearchResponse? _result;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? FlightApiClient();
    final now = DateTime.now();
    _date = DateTime(now.year, now.month, now.day + 1);
    _dateText.text = displayDate(_date);
  }

  @override
  void dispose() {
    _from.dispose();
    _to.dispose();
    _dateText.dispose();
    if (widget.api == null) _api.close();
    super.dispose();
  }

  String? _airportError(String? value) =>
      RegExp(r'^[A-Za-z]{3}$').hasMatch(value?.trim() ?? '')
      ? null
      : '3 harfli kod gir (örn. IST).';

  Future<void> _chooseDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(today.year + 2, today.month, today.day),
      helpText: 'Uçuş tarihini seç',
      cancelText: 'Vazgeç',
      confirmText: 'Seç',
    );
    if (!mounted || selected == null) return;
    setState(() {
      _date = selected;
      _dateText.text = displayDate(selected);
    });
  }

  Future<void> _search() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final from = _from.text.trim().toUpperCase();
    final to = _to.text.trim().toUpperCase();
    final date = _date;
    _from.text = from;
    _to.text = to;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await _api.search(from: from, to: to, date: date);
      if (!mounted) return;
      setState(() => _result = result);
    } on FlightApiException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  InputDecoration _decoration(String label, IconData icon, {String? hint}) =>
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E7FF)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E7FF)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final result = _result;
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E7FF),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.flight_takeoff_rounded,
                                color: primary,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'UÇUŞ TAKİP',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.6,
                                      color: Color(0xFF006194),
                                    ),
                                  ),
                                  Text(
                                    'Uçuş ara',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF131B2E),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Rotanı ve tarihini seç, uçuş tekliflerini incele.',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF3F4850),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                key: const Key('fromField'),
                                controller: _from,
                                enabled: !_loading,
                                textCapitalization:
                                    TextCapitalization.characters,
                                autocorrect: false,
                                decoration: _decoration(
                                  'Kalkış kodu',
                                  Icons.flight_takeoff_rounded,
                                  hint: 'IST',
                                ),
                                validator: _airportError,
                                textInputAction: TextInputAction.next,
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('toField'),
                                controller: _to,
                                enabled: !_loading,
                                textCapitalization:
                                    TextCapitalization.characters,
                                autocorrect: false,
                                decoration: _decoration(
                                  'Varış kodu',
                                  Icons.flight_land_rounded,
                                  hint: 'FCO',
                                ),
                                validator: (value) {
                                  final error = _airportError(value);
                                  if (error != null) return error;
                                  return value!.trim().toUpperCase() ==
                                          _from.text.trim().toUpperCase()
                                      ? 'Kalkış ve varış farklı olmalı.'
                                      : null;
                                },
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _search(),
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                key: const Key('dateField'),
                                controller: _dateText,
                                readOnly: true,
                                enabled: !_loading,
                                decoration: _decoration(
                                  'Uçuş tarihi',
                                  Icons.calendar_month_rounded,
                                ),
                                onTap: _chooseDate,
                              ),
                              const SizedBox(height: 18),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  key: const Key('searchButton'),
                                  onPressed: _loading ? null : _search,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  icon: _loading
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.search_rounded),
                                  label: Text(
                                    _loading ? 'Aranıyor…' : 'Uçuş Ara',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .errorContainer,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _error!,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onErrorContainer,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _search,
                                  child: const Text('Tekrar dene'),
                                ),
                              ],
                            ),
                          ),
                        if (!_loading && _error == null && result == null)
                          const Text(
                            'Arama yaptığında uçuşlar burada listelenecek.',
                            style: TextStyle(color: Color(0xFF596474)),
                          ),
                        if (result != null) ...[
                          Text(
                            '${result.from} → ${result.to}',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${displayDate(result.date)} · ${result.flights.length} sefer',
                            style: const TextStyle(color: Color(0xFF596474)),
                          ),
                          if (result.isSimulated) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEBD5),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Text(
                                'Fiyatlar ve saatler simülasyon verisidir; gerçek sefer bilgisi değildir.',
                                style: TextStyle(
                                  color: Color(0xFF684000),
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                          if (result.flights.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                'Sefer bulunamadı. Farklı bir rota veya tarih dene.',
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (result != null)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverList.separated(
                      itemCount: result.flights.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 14),
                      itemBuilder: (context, index) => FlightCard(
                        flight: result.flights[index],
                        from: result.from,
                        to: result.to,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
