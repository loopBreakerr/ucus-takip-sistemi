# Uçuş Takip mobil

Hafta 2: Android Flutter uygulaması, web ile aynı .NET API üzerinden rota ve tarihe göre uçuş teklifleri gösterir. Yerel örnek uçuş listesi kullanılmaz. API şu anda simülasyon verisi üretir ve bu durum ekranda belirtilir.

## Çalıştırma

Repo kökünde bir terminalde API'yi HTTP profiliyle başlat:

```bash
dotnet run --project api/UcusTakip.Api.csproj --launch-profile http
```

Android Studio Device Manager'dan emülatörü başlat. Başka terminalde `mobile/` klasöründe:

```bash
flutter pub get
flutter devices
flutter run -d emulator-5554
```

Cihaz kimliği farklıysa `flutter devices` çıktısındaki kimliği kullan. Android Studio'dan `mobile/` klasörünü açıp Android emülatörünü seçerek Run da kullanılabilir. Android manifest değişikliklerinden sonra uygulamayı durdurup yeniden Run yapmak gerekir; hot reload yeterli değildir.

Varsayılan API adresi `http://10.0.2.2:5199`; `10.0.2.2`, Android emülatöründen geliştirici bilgisayarına ulaşır. Web sunucusu aynı API'ye `localhost` üzerinden erişir. Her geliştirici aynı API kodunu kendi bilgisayarında çalıştırabilir.

Adres `lib/config/api_config.dart` içinde tek noktada tanımlıdır. Başka sunucu için:

```bash
flutter run --dart-define=API_BASE_URL=https://api.example.com
```

Yerel HTTP erişimi sadece Android debug yapılandırmasında `10.0.2.2`, `localhost` ve `127.0.0.1` için açıktır. Release/uzak sunucu için geçerli sertifikalı HTTPS adresi kullanılır; sertifika doğrulaması devre dışı bırakılmaz. Native Android istemcisi için CORS ayarı gerekmez.

## API sözleşmesi

```http
GET /api/flights/search?from=IST&to=FCO&date=2026-12-15
```

Yanıtın üst düzey alanları: `from`, `to`, `date`, `source`, `flights`.

Her teklif: `flightNumber`, `airline`, `departureTime`, `arrivalTime`, `durationMinutes`, `price`, `currency`, `isSimulated`.

Tarih `yyyy-MM-dd` gönderilir. API'nin mevcut simülasyon saatleri UTC farkı içermez; mobil bu değerleri saat dilimine dönüştürmeden gösterir. Gerçek sağlayıcıya geçişte saat dilimi sözleşmesi iki istemciyle birlikte netleştirilmelidir. Ertesi gün varan seferde `(+1)` gösterilir.

HTTP 400 yanıtındaki `error` mesajı kullanıcıya gösterilir. Bağlantı hatası, 10 saniye zaman aşımı, geçersiz yanıt, boş sonuç ve yeniden deneme durumları ele alınır. Hata durumunda sahte sonuç üretilmez.

## Kod düzeni

- `lib/main.dart`: uygulama ve ortak tema.
- `lib/config/api_config.dart`: API adresi.
- `lib/models/flight_search_response.dart`: API yanıt modelleri.
- `lib/services/flight_api_client.dart`: HTTP isteği ve hata yönetimi.
- `lib/screens/flights_screen.dart`: form ve arama durumu.
- `lib/widgets/flight_card.dart`: sonuç kartı.

## Kontrol

```bash
flutter analyze
flutter test
```

16 GB RAM'li geliştirme ortamında bellek baskısını azaltmak için Gradle Java heap sınırı 2 GB, worker sınırı 2 tutulur. Emülatörü bir kez başlat; tekrar tekrar yeni emülatör açma.
