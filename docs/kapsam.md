Kapsam – Web ve Mobil Uçuş Takip Sistemi (TRackers)
1. Amaç

Kullanıcıların uçuş arayıp ilgilendikleri seferleri hesaplarına kaydedebildiği, bu uçuşları harita üzerinde canlı takip edebildiği ve seçtikleri rotalar için fiyat alarmı kurup fiyat düşünce bildirim alabildiği bir web (ASP.NET Core MVC) ve mobil (Flutter) uygulaması. İki istemci ortak bir .NET API ve PostgreSQL veritabanı kullanır.

2. Hedef kullanıcılar

Yolculuğunu planlayanlar, uygun fiyatlı bilet arayanlar, belirli bir seferi takip etmek isteyenler (örneğin havalimanında birini karşılayacak kişi) ve havacılığa ilgi duyanlar.

3. Roller
Ziyaretçi: Uçuş arama, canlı harita, çağrı koduyla uçak arama.
Kullanıcı: Ziyaretçi yetkilerine ek olarak kayıt/giriş, kişisel uçuş listesi, kaydedilen seferin canlı takibi, fiyat alarmı ve bildirimler.
Yönetici: Kullanıcı yönetimi.
4. Kullanıcı hikayeleri
Ziyaretçi olarak kalkış, varış ve tarih seçip uçuşları sefer numarası, saat ve fiyat bilgisiyle görebilmeliyim.
Ziyaretçi olarak haritada uçakları görüp çağrı koduyla arama yapabilmeli, hız, irtifa ve yön bilgisine bakabilmeliyim.
Kullanıcı olarak hesap açıp giriş yapabilmeliyim.
Kullanıcı olarak bir seferi kişisel listeme ekleyip çıkarabilmeliyim.
Kullanıcı olarak kaydettiğim seferin uçağı havadaysa canlı konumunu görebilmeliyim; eşleşme veya güncel veri yoksa bunun açıkça belirtilmesini istiyorum.
Kullanıcı olarak bir rota ve tarih için fiyat alarmı kurabilmeliyim (hedef fiyat veya fiyat düşüşü).
Kullanıcı olarak fiyat alarmım tetiklendiğinde bildirim alıp bildirimlerimi listeleyebilmeliyim.
Kullanıcı olarak bir rotanın fiyat geçmişini görebilmeliyim.
Yönetici olarak kullanıcıları görüntüleyip yönetebilmeliyim.
5. İlk sürümün kapsamı
Uçuş arama (SerpApi)
Hesap, giriş ve roller
Kişisel uçuş listesi
Canlı harita ve çağrı koduyla arama (ADSB.lol)
Kaydedilen seferin hava aracıyla eşleştirilip canlı takibi
Fiyat alarmı: kullanıcı rota, tarih ve hedef fiyat belirler; sistem günde bir kez fiyatı kontrol eder
Bildirim: alarm tetiklendiğinde uygulama içi bildirim (web ve mobil). Mobilde telefona anlık bildirim (Firebase Cloud Messaging, Android) zamana bağlı olarak eklenecektir.
Fiyat geçmişi: kontrol edilen fiyatlar kaydedilir ve rota için gösterilir
6. Kapsam dışı
Bilet satın alma ve rezervasyon.
iOS anlık bildirimi.
7. Bilinen sınırlar
Canlı konum yalnızca havadaki uçaklar için görülebilir; kalkış öncesi seferlerin konumu yoktur.
Sefer numarası ile uçağın çağrı kodu her zaman aynı olmayabilir; eşleştirme bu yüzden her sefer için başarılı olmayabilir.
Fiyatlar veri sağlayıcıya bağlıdır; simüle fiyatlar arayüzde “simüle” olarak işaretlenir.
Aynı anda takip edilebilecek farklı rota-tarih çifti sayısı API kotası nedeniyle sınırlıdır.
8. API kotası ve fiyat servisi

SerpApi ücretsiz planda ayda 250 istek verir. Bu nedenle:

Aramalar ve alarm kontrolleri önbelleğe alınacak; aynı rota ve tarih için tek istek atılacak ve sonuç bu rotayı takip eden tüm kullanıcılar için kullanılacaktır.
Fiyat kontrolü günde bir kez yapılacaktır.
Geliştirmede ve kota dolduğunda otomatik olarak simüle fiyat sağlayıcı kullanılacaktır.
Fiyat düşüşünün gösterilebilmesi için simüle sağlayıcıda yöneticinin fiyatı elle değiştirebildiği bir test işlevi bulunacaktır.
9. Teknolojiler

ASP.NET Core MVC (web), Flutter (mobil), ASP.NET Core API (zamanlanmış görev için BackgroundService), PostgreSQL, SerpApi (uçuş arama ve fiyat), ADSB.lol (canlı konum), Firebase Cloud Messaging (opsiyonel anlık bildirim).