# Bütçe Takip — SMS ve Bildirimden Otomatik Harcama Takibi

Flutter + Isar ile yazılmış, tamamen offline çalışan Android (telefon/tablet) harcama takip uygulaması.

## Kurulum (GitHub üzerinden APK)
1. Bu klasörü bir GitHub deposuna push et.
2. **Actions → Build APK** çalışır (veya "Run workflow" ile elle başlat).
3. Bittiğinde çalıştırmanın altındaki **Artifacts → app-release-apk** dosyasını indir, telefona kur.

## İlk açılış
- SMS izni ver.
- "Bildirim Erişimi" ayarında Bütçe Takip'i etkinleştir.
- Bazı telefonlarda (Xiaomi, Samsung vb.) pil optimizasyonundan uygulamayı hariç tutman gerekir, yoksa arka plan dinleme kesilebilir.

## Notlar
- `telephony 0.2.0` eski bir pakettir; bu yüzden workflow Flutter 3.24.5'e sabitlenmiştir.
  Daha yeni Flutter'a geçmek istersen `telephony` yerine `another_telephony` paketini kullan.
- `expense.g.dart` dosyası repoda yoktur; workflow `build_runner` ile üretir.
  Yerelde çalıştırmak için: `dart run build_runner build --delete-conflicting-outputs`
- Banka mesaj formatları farklı olabilir. Tutmayan bir mesaj olursa `lib/services/expense_parser.dart`
  içindeki regex listesine ekleme yapılır; ham mesaj metni her kayıtta `rawMessage` alanında saklanır.
- Aynı işlem hem SMS hem bildirim olarak gelirse 3 dakika içinde aynı tutar tekrar kaydedilmez.
