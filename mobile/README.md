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

## Hafta 3 hesap akışı

Uçuş arama ziyaretçiye açıktır. Ana ekrandaki **Hesabım** düğmesi kayıt ve giriş ekranlarını açar. Kayıt olan hesap normal kullanıcı rolü alır. Yönetici hesabında **Kullanıcılar** ekranı görünür ve API listeyi yönetici rolüne göre korur. Çıkış, JWT’yi cihazdan siler. API belirteci süresi dolana kadar geçerli kabul eder. Android’de belirteç güvenli depoda, tarayıcı önizlemesinde sekmenin oturum deposunda tutulur.

### PostgreSQL ve API

Erişebildiğin boş bir PostgreSQL veritabanı oluştur. Bağlantı bilgilerini ve ilk yönetici hesabını API’yi çalıştıran terminalde ortam değişkenleriyle tanımla. API ve web aynı Identity tablolarını kullanır. İlk açılıştan önce ortak migration’ları uygula. Belirtilen yönetici zaten varsa parolası başlangıçta değiştirilmez.

```bash
read -rsp 'PostgreSQL bağlantı dizesi: ' ConnectionStrings__Default; echo
export ConnectionStrings__Default
export Admin__Email=admin@ucus.test
read -rsp 'Yönetici parolası: ' Admin__Password; echo
export Admin__Password
export Jwt__Key="$(openssl rand -hex 32)"
dotnet ef database update --project data/UcusTakip.Data.csproj --startup-project api/UcusTakip.Api.csproj
dotnet run --project api/UcusTakip.Api.csproj --launch-profile http
```

Migration komutu için .NET 10 uyumlu `dotnet-ef` aracı gerekir. Sonraki çalıştırmalarda aynı JWT anahtarını kullanırsan mevcut oturumlar yeniden başlatma sonrasında da süreleri dolana kadar çalışır. Flutter `/api/auth/register`, `/api/auth/login`, `/api/auth/me` ve yönetici için `/api/auth/users` uçlarını kullanır.

Bağlantı dizesi biçimi `Host=localhost;Database=ucus_takip;Username=...;Password=...`. Yönetici değişkenlerini vermeden normal kullanıcı akışını deneyebilirsin. Hesap veritabanı ayarı olmadan uçuş arama çalışır.

### Emülatörsüz önizleme

API çalışırken başka bir terminalde `mobile/` klasöründe çalıştır:

```bash
flutter pub get
flutter run -d web-server --web-hostname localhost --web-port 7357
```

Tarayıcıda `http://localhost:7357` adresini aç. Bu adres, API’nin yalnızca Development ortamında izin verdiği Flutter adresidir. Tarayıcı API için varsayılan olarak `http://localhost:5199` adresini kullanır. Android hedefini emülatör olmadan derleme kontrolünden geçirmek için `flutter build apk --debug` çalıştır.
