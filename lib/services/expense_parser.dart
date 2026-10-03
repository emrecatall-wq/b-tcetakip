/// SMS ve push bildirim metinlerinden harcama bilgisi çıkaran tek parser.
class ParsedExpense {
  final String bankName;
  final double amount;
  final String merchant;
  final DateTime date;
  final String category;

  ParsedExpense({
    required this.bankName,
    required this.amount,
    required this.merchant,
    required this.date,
    required this.category,
  });
}

class ExpenseParser {
  /// Bildirim dinlerken sadece bu paketlerden gelenlere bakılır.
  static const Map<String, String> bankPackages = {
    'finansbank.enpara': 'Enpara',
    'com.finansbank.enpara': 'Enpara',
    'com.garanti.cepsubesi': 'Garanti BBVA',
    'com.akbank.android.apps.akbank_direkt': 'Akbank',
    'com.pozitron.iscep': 'İş Bankası',
    'com.ykb.android': 'Yapı Kredi',
    'com.tmobtech.halkbank': 'Halkbank',
    'com.vakifbank.mobile': 'VakıfBank',
    'com.ziraat.ziraatmobil': 'Ziraat',
    'com.denizbank.mobildeniz': 'DenizBank',
    'com.qnbfinansbank.cepsubesi': 'QNB',
  };

  static const List<List<String>> _bankKeywords = [
    ['Enpara', 'enpara'],
    ['Garanti BBVA', 'garanti'],
    ['Akbank', 'akbank'],
    ['İş Bankası', 'iş bankası', 'is bankasi', 'işbank', 'isbank', 'maximum'],
    ['Yapı Kredi', 'yapı kredi', 'yapi kredi', 'worldcard', 'yapikredi'],
    ['Halkbank', 'halkbank'],
    ['VakıfBank', 'vakıfbank', 'vakifbank'],
    ['Ziraat', 'ziraat'],
    ['DenizBank', 'denizbank'],
    ['QNB', 'qnb'],
  ];

  static final RegExp _amountRe = RegExp(
    r'(?:(?:TL|TRY)\s*)?(\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?|\d+(?:,\d{1,2})?|\d+\.\d{1,2})\s*(?:TL|TRY|₺)'
    r'|(?:TL|TRY|₺)\s*(\d{1,3}(?:\.\d{3})+(?:,\d{1,2})?|\d+(?:,\d{1,2})?)',
    caseSensitive: false,
  );

  static final List<RegExp> _merchantRes = [
    RegExp(r'(?:İş\s?yeri|Isyeri|Işyeri|Yer|Firma|Üye\s?iş\s?yeri)\s*[:：]\s*([^\n,;]+?)(?=\s{2,}|\s+(?:Tarih|Tutar|Saat|Kart|Limit|Bakiye)|\n|$|[,;])', caseSensitive: false),
    RegExp(r"([A-Za-z0-9ÇĞİÖŞÜçğıöşü&\.\*\-\s/]{2,40}?)\s*(?:işyerinde|isyerinde|işyerinden|iş yerinde|yerinde)", caseSensitive: false),
    RegExp(r"\d{1,2}[./]\d{1,2}[./]\d{2,4}(?:\s+\d{1,2}:\d{2}(?::\d{2})?)?\s+(?:tarihinde\s+)?([A-Za-z0-9ÇĞİÖŞÜçğıöşü&\.\*\-\s/]{2,40}?)\s*(?:'|’)?(?:da|de|ta|te|dan|den)\b", caseSensitive: false),
    RegExp(r"([A-Za-z0-9ÇĞİÖŞÜçğıöşü&\.\*\-/]+(?:\s[A-Za-z0-9ÇĞİÖŞÜçğıöşü&\.\*\-/]+){0,3})\s*(?:'|’)(?:da|de|ta|te)\s", caseSensitive: false),
    RegExp(r'\bat\s+([A-Za-z0-9&\.\*\-\s]{2,30}?)(?:\s+on\b|\.|$)', caseSensitive: false),
  ];

  static final RegExp _dateRe = RegExp(
    r'(\d{1,2})[./](\d{1,2})[./](\d{2,4})(?:\s+(\d{1,2}):(\d{2})(?::(\d{2}))?)?',
  );

  static const List<String> _spendWords = [
    'harcama', 'alışveriş', 'alisveris', 'işlem', 'islem', 'provizyon',
    'kartınız', 'kartiniz', 'kartınızla', 'çekim', 'cekim', 'ödeme', 'odeme',
    'satın', 'satin', 'tutarında', 'tutarinda', 'gerçekleşmiştir', 'gerceklesmistir',
    'spent', 'purchase',
  ];

  static const List<String> _ignoreWords = [
    'şifre', 'sifre', 'doğrulama kodu', 'dogrulama kodu', 'onay kodu', 'otp',
    'tek kullanımlık', 'tek kullanimlik', 'kampanya', 'ekstre', 'son ödeme',
    'hesabınıza', 'hesabiniza', 'gelen havale', 'yatırıldı', 'yatirildi',
    'iade', 'asgari', 'borcunuz',
  ];

  static const Map<String, List<String>> _categories = {
    'Market': ['market', 'migros', 'bim', 'a101', 'şok', 'sok market', 'carrefour', 'macro', 'file', 'kasap', 'manav', 'bakkal'],
    'Akaryakıt': ['petrol', 'opet', 'shell', 'bp ', 'total', 'aytemiz', 'akaryakıt', 'lukoil', 'po '],
    'Yeme-İçme': ['restoran', 'restaurant', 'cafe', 'kafe', 'kahve', 'starbucks', 'yemek', 'burger', 'döner', 'lokanta', 'pastane', 'getir', 'yemeksepeti', 'trendyol yemek'],
    'Giyim': ['lc waikiki', 'lcw', 'koton', 'defacto', 'zara', 'mavi', 'boyner', 'giyim', 'tekstil', 'ayakkabı'],
    'Online': ['trendyol', 'hepsiburada', 'amazon', 'n11', 'aliexpress', 'temu', 'çiçeksepeti'],
    'Fatura': ['turkcell', 'vodafone', 'türk telekom', 'enerjisa', 'igdaş', 'iski', 'fatura', 'bedaş', 'avea'],
    'Ulaşım': ['istanbulkart', 'otobüs', 'metro', 'taksi', 'uber', 'bitaksi', 'otopark', 'hgs', 'ogs', 'thy', 'pegasus', 'otoyol'],
    'Sağlık': ['eczane', 'hastane', 'klinik', 'sağlık', 'medikal', 'diş'],
    'Yapı-Tadilat': ['koçtaş', 'koctas', 'bauhaus', 'tekzen', 'hırdavat', 'hirdavat', 'yapı', 'nalbur', 'boya', 'elektrik'],
  };

  /// Ham metni ayrıştırır. Harcama değilse null döner.
  /// [source]: SMS gönderen adı veya bildirimin paket adı/başlığı (banka tespiti için).
  /// [fallbackDate]: metinde tarih yoksa kullanılacak tarih.
  static ParsedExpense? parse(String text, {String source = '', DateTime? fallbackDate}) {
    final body = text.replaceAll(' ', ' ').trim();
    if (body.isEmpty) return null;
    final lower = body.toLowerCase();

    if (_ignoreWords.any(lower.contains)) return null;
    if (!_spendWords.any(lower.contains)) return null;

    final amount = _extractAmount(body);
    if (amount == null || amount <= 0) return null;

    final bank = _detectBank(lower, source.toLowerCase());
    final merchant = _extractMerchant(body);
    final date = _extractDate(body) ?? fallbackDate ?? DateTime.now();
    final category = _guessCategory(merchant.toLowerCase());

    return ParsedExpense(
      bankName: bank,
      amount: amount,
      merchant: merchant,
      date: date,
      category: category,
    );
  }

  static double? parseTurkishNumber(String s) {
    var t = s.trim();
    if (t.contains(',')) {
      t = t.replaceAll('.', '').replaceAll(',', '.');
    } else if (RegExp(r'^\d{1,3}(\.\d{3})+$').hasMatch(t)) {
      t = t.replaceAll('.', '');
    }
    return double.tryParse(t);
  }

  static double? _extractAmount(String body) {
    final matches = _amountRe.allMatches(body).toList();
    if (matches.isEmpty) return null;
    // "tutarında/harcama" kelimesine en yakın tutarı tercih et; yoksa ilk tutar.
    for (final m in matches) {
      final start = (m.start - 40).clamp(0, body.length);
      final ctx = body.substring(start, m.end).toLowerCase();
      final isBalance = ctx.contains('bakiye') || ctx.contains('limit');
      if (!isBalance) {
        final raw = m.group(1) ?? m.group(2);
        if (raw != null) return parseTurkishNumber(raw);
      }
    }
    final raw = matches.first.group(1) ?? matches.first.group(2);
    return raw == null ? null : parseTurkishNumber(raw);
  }

  static String _detectBank(String lowerBody, String lowerSource) {
    final map = bankPackages[lowerSource];
    if (map != null) return map;
    for (final entry in _bankKeywords) {
      for (final kw in entry.skip(1)) {
        if (lowerSource.contains(kw) || lowerBody.contains(kw)) return entry.first;
      }
    }
    return 'Diğer';
  }

  static String _extractMerchant(String body) {
    for (final re in _merchantRes) {
      final m = re.firstMatch(body);
      if (m != null) {
        final v = _cleanMerchant(m.group(1) ?? '');
        if (v.length >= 2) return v;
      }
    }
    return 'Bilinmeyen';
  }

  static String _cleanMerchant(String s) {
    var v = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    v = v.replaceAll(RegExp(r'^[\-:*\s]+|[\-:*\s.]+$'), '');
    if (v.length > 40) v = v.substring(0, 40).trim();
    return v;
  }

  static DateTime? _extractDate(String body) {
    final m = _dateRe.firstMatch(body);
    if (m == null) return null;
    try {
      final d = int.parse(m.group(1)!);
      final mo = int.parse(m.group(2)!);
      var y = int.parse(m.group(3)!);
      if (y < 100) y += 2000;
      final h = int.tryParse(m.group(4) ?? '') ?? 0;
      final mi = int.tryParse(m.group(5) ?? '') ?? 0;
      final s = int.tryParse(m.group(6) ?? '') ?? 0;
      if (mo < 1 || mo > 12 || d < 1 || d > 31) return null;
      return DateTime(y, mo, d, h, mi, s);
    } catch (_) {
      return null;
    }
  }

  static String _guessCategory(String lowerMerchant) {
    for (final e in _categories.entries) {
      if (e.value.any(lowerMerchant.contains)) return e.key;
    }
    return 'Genel';
  }
}
