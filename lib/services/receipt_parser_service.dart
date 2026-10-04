import 'dart:math';

class ParsedReceiptResult {
  final double amount;
  final String title;
  final String category;
  final bool isExpense;
  final DateTime? date;
  final String rawText;
  final String? merchantName;

  const ParsedReceiptResult({
    required this.amount,
    required this.title,
    required this.category,
    required this.isExpense,
    this.date,
    required this.rawText,
    this.merchantName,
  });
}

class ReceiptParserService {
  /// Menganalisa teks mentah hasil OCR dari struk belanja, nota, atau struk tarik tunai
  static ParsedReceiptResult parse(String rawText) {
    final lines = rawText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final fullTextLower = rawText.toLowerCase();

    // 1. Deteksi apakah ini Struk Tarik Tunai ATM
    final bool isTarikTunai = _checkIsTarikTunai(fullTextLower);

    // 2. Deteksi Toko / Merchant & Kategori
    String? merchantName;
    String category = 'Belanja & Keperluan';
    bool isExpense = true;
    String title = 'Transaksi Struk';

    if (isTarikTunai) {
      isExpense = false; // Masuk ke dompet tunai (Pemasukan tunai)
      category = 'Transfer Masuk';
      final bank = _detectBank(fullTextLower);
      title = bank != null ? 'Tarik Tunai $bank' : 'Tarik Tunai ATM';
      merchantName = title;
    } else {
      final detected = _detectMerchantAndCategory(lines, fullTextLower);
      merchantName = detected.merchant;
      category = detected.category;
      title = detected.title;
      isExpense = true;
    }

    // 3. Deteksi Nominal / Grand Total
    double detectedAmount = 0.0;
    if (isTarikTunai) {
      detectedAmount = _extractTarikTunaiAmount(lines, fullTextLower);
    } else {
      detectedAmount = _extractGrandTotal(lines);
    }

    // 4. Deteksi Tanggal & Waktu
    final detectedDate = _extractDateTime(lines);

    return ParsedReceiptResult(
      amount: detectedAmount,
      title: title,
      category: category,
      isExpense: isExpense,
      date: detectedDate ?? DateTime.now(),
      rawText: rawText,
      merchantName: merchantName,
    );
  }

  // ─── HELPER: Tarik Tunai ───────────────────────────────────────────────────

  static bool _checkIsTarikTunai(String text) {
    return text.contains('tarik tunai') ||
        text.contains('penarikan tunai') ||
        text.contains('penarikan uang') ||
        text.contains('cash withdrawal') ||
        (text.contains('atm') && text.contains('penarikan')) ||
        (text.contains('atm') && text.contains('tarik'));
  }

  static String? _detectBank(String text) {
    if (text.contains('bca')) return 'ATM BCA';
    if (text.contains('mandiri')) return 'ATM Mandiri';
    if (text.contains('bri')) return 'ATM BRI';
    if (text.contains('bni')) return 'ATM BNI';
    if (text.contains('cimb')) return 'ATM CIMB Niaga';
    if (text.contains('permata')) return 'ATM Permata';
    if (text.contains('btn')) return 'ATM BTN';
    if (text.contains('bsi')) return 'ATM BSI';
    return null;
  }

  static double _extractTarikTunaiAmount(List<String> lines, String fullText) {
    // Cari baris yang mengandung 'nominal', 'jumlah', 'tarik', 'rp'
    final keywords = ['nominal', 'jumlah', 'penarikan', 'tarik', 'rp'];
    for (var line in lines) {
      final lower = line.toLowerCase();
      for (var kw in keywords) {
        if (lower.contains(kw)) {
          final amt = _parseAmountFromLine(line);
          if (amt != null && amt >= 20000 && (amt % 10000 == 0)) {
            return amt;
          }
        }
      }
    }

    // Cari angka terbesar kelipatan 50.000 atau 100.000 (standar ATM Indonesia)
    double maxAtmVal = 0.0;
    for (var line in lines) {
      final amt = _parseAmountFromLine(line);
      if (amt != null && amt >= 50000 && amt <= 10000000 && (amt % 50000 == 0)) {
        if (amt > maxAtmVal) maxAtmVal = amt;
      }
    }
    if (maxAtmVal > 0) return maxAtmVal;

    return _extractGrandTotal(lines);
  }

  // ─── HELPER: Merchant & Kategori ──────────────────────────────────────────

  static _MerchantCategoryResult _detectMerchantAndCategory(
      List<String> lines, String fullText) {
    // Cek beberapa baris teratas struk (biasanya nama toko ada di 5 baris pertama)
    final topLines = lines.take(min(8, lines.length)).toList();
    final topText = topLines.join(' ').toLowerCase();

    // Minimarket & Supermarket
    if (topText.contains('indomaret')) {
      return _MerchantCategoryResult('Indomaret', 'Belanja di Indomaret', 'Belanja & Keperluan');
    }
    if (topText.contains('alfamart')) {
      return _MerchantCategoryResult('Alfamart', 'Belanja di Alfamart', 'Belanja & Keperluan');
    }
    if (topText.contains('alfamidi')) {
      return _MerchantCategoryResult('Alfamidi', 'Belanja di Alfamidi', 'Belanja & Keperluan');
    }
    if (topText.contains('super indo') || topText.contains('superindo')) {
      return _MerchantCategoryResult('Super Indo', 'Belanja di Super Indo', 'Belanja & Keperluan');
    }
    if (topText.contains('hypermart')) {
      return _MerchantCategoryResult('Hypermart', 'Belanja di Hypermart', 'Belanja & Keperluan');
    }
    if (topText.contains('transmart') || topText.contains('carrefour')) {
      return _MerchantCategoryResult('Transmart', 'Belanja di Transmart', 'Belanja & Keperluan');
    }
    if (topText.contains('lawson')) {
      return _MerchantCategoryResult('Lawson', 'Jajan di Lawson', 'Makanan & Minuman');
    }
    if (topText.contains('circle k')) {
      return _MerchantCategoryResult('Circle K', 'Belanja di Circle K', 'Belanja & Keperluan');
    }
    if (topText.contains('familymart')) {
      return _MerchantCategoryResult('FamilyMart', 'Belanja di FamilyMart', 'Belanja & Keperluan');
    }

    // SPBU & Bensin
    if (fullText.contains('spbu') ||
        fullText.contains('pertamina') ||
        fullText.contains('pertalite') ||
        fullText.contains('pertamax') ||
        fullText.contains('solar') ||
        fullText.contains('dexlite') ||
        fullText.contains('shell') ||
        fullText.contains('bp akr')) {
      String name = 'SPBU Pertamina';
      if (fullText.contains('shell')) name = 'SPBU Shell';
      if (fullText.contains('bp akr') || fullText.contains('bp ')) name = 'SPBU BP';
      return _MerchantCategoryResult(name, 'Beli BBM $name', 'Transport');
    }

    // Cafe, Resto & Kopi
    final foodKeywords = [
      'starbucks', 'kfc', 'mcdonald', 'hokben', 'solaria', 'pizza hut',
      'domino', 'burger king', 'kopi kenangan', 'janji jiwa', 'fore',
      'tomoro', 'point coffee', 'chatime', 'haus', 'dcrepes', 'gacoan',
      'bakso', 'soto', 'ayam geprek', 'cafe', 'resto', 'warung', 'kedai'
    ];
    for (var kw in foodKeywords) {
      if (topText.contains(kw) || fullText.contains(kw)) {
        final titleName = kw[0].toUpperCase() + kw.substring(1);
        return _MerchantCategoryResult(titleName, 'Makan / Jajan $titleName', 'Makanan & Minuman');
      }
    }

    // Apotek & Kesehatan
    if (fullText.contains('apotek') ||
        fullText.contains('apotik') ||
        fullText.contains('kimia farma') ||
        fullText.contains('k-24') ||
        fullText.contains('k24') ||
        fullText.contains('century') ||
        fullText.contains('guardian') ||
        fullText.contains('watsons') ||
        fullText.contains('klinik') ||
        fullText.contains('rumah sakit')) {
      return _MerchantCategoryResult('Apotek', 'Beli Obat / Keperluan Medis', 'Kesehatan');
    }

    // Tagihan & Listrik / Air
    if (fullText.contains('pln') ||
        fullText.contains('pdam') ||
        fullText.contains('bpjs') ||
        fullText.contains('indihome') ||
        fullText.contains('biznet') ||
        fullText.contains('token listrik')) {
      return _MerchantCategoryResult('Tagihan', 'Bayar Tagihan / Utilitas', 'Tagihan & Utilities');
    }

    // Default: Ambil baris pertama teratas yang menyerupai nama toko
    String firstLine = topLines.isNotEmpty ? topLines.first : 'Toko';
    // Hapus karakter non-alphanumeric berlebih
    firstLine = firstLine.replaceAll(RegExp(r'[^\w\s]'), '').trim();
    if (firstLine.length > 25) firstLine = firstLine.substring(0, 25).trim();
    if (firstLine.isEmpty) firstLine = 'Struk Pembelian';

    return _MerchantCategoryResult(firstLine, 'Belanja di $firstLine', 'Belanja & Keperluan');
  }

  // ─── HELPER: Total Amount Extraction ───────────────────────────────────────

  static double _extractGrandTotal(List<String> lines) {
    // 1. Prioritas Utama: Cari baris dengan keyword Total spesifik
    final primaryTotalKeywords = [
      'grand total',
      'total bayar',
      'total belanja',
      'total tagihan',
      'total akhir',
      'harga total',
      'total harga',
      'subtotal',
      'total',
    ];

    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final lower = line.toLowerCase();
      // Selalu abaikan baris uang kembali / change
      if (lower.contains('kembali') || lower.contains('kembalian') || lower.contains('change')) {
        continue;
      }

      for (var kw in primaryTotalKeywords) {
        if (lower.contains(kw)) {
          final amt = _parseAmountFromLine(line);
          if (amt != null && amt > 0 && amt < 100000000) {
            return amt;
          }

          if (i + 1 < lines.length) {
            final nextAmt = _parseAmountFromLine(lines[i + 1]);
            if (nextAmt != null && nextAmt > 0 && nextAmt < 100000000) {
              return nextAmt;
            }
          }
        }
      }
    }

    // 2. Prioritas Kedua: Keyword metode bayar (hanya jika baris Total tidak ditemukan)
    final secondaryKeywords = [
      'jumlah bayar',
      'tagihan',
      'bayar',
      'debit',
      'debet',
      'qris',
      'tunai',
      'cash',
    ];

    for (int i = lines.length - 1; i >= 0; i--) {
      final line = lines[i];
      final lower = line.toLowerCase();
      if (lower.contains('kembali') || lower.contains('kembalian') || lower.contains('change')) {
        continue;
      }

      for (var kw in secondaryKeywords) {
        if (lower.contains(kw)) {
          final amt = _parseAmountFromLine(line);
          if (amt != null && amt > 0 && amt < 100000000) {
            return amt;
          }

          if (i + 1 < lines.length) {
            final nextAmt = _parseAmountFromLine(lines[i + 1]);
            if (nextAmt != null && nextAmt > 0 && nextAmt < 100000000) {
              return nextAmt;
            }
          }
        }
      }
    }

    // 2. Fallback: Cari angka rupiah terbesar yang wajar di struk
    double maxVal = 0.0;
    for (var line in lines) {
      final amt = _parseAmountFromLine(line);
      if (amt != null && amt > maxVal && amt < 50000000) {
        // Hindari mencocokkan nomor barcode atau nomor kartu (panjang 13-16 digit)
        if (amt >= 500 && amt.toStringAsFixed(0).length <= 9) {
          maxVal = amt;
        }
      }
    }

    return maxVal;
  }

  /// Ekstraksi angka nominal rupiah dari sebuah string baris struk
  static double? _parseAmountFromLine(String line) {
    // Hapus teks 'Rp', 'RP', spasi berlebih
    var clean = line.replaceAll(RegExp(r'[rR][pP]\.?'), ' ').trim();

    // Pola angka dengan pemisah titik/koma ribuan: 45.000, 45,000, 45000, 45.000,00
    final matches = RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?|\d+)').allMatches(clean);

    double? candidate;
    for (var match in matches) {
      var numStr = match.group(0)!;
      // Abaikan jika mirip nomor tahun (misal 2024, 2025, 2026) atau jam (misal 14:30)
      if (numStr.length == 4 && (numStr.startsWith('202') || numStr.startsWith('199'))) {
        continue;
      }

      // Normalisasi format Indonesia: titik adalah ribuan, koma adalah sen
      // Contoh: 25.000 -> 25000; 25.000,00 -> 25000
      if (numStr.contains('.') && numStr.contains(',')) {
        if (numStr.indexOf('.') < numStr.indexOf(',')) {
          // Format 25.000,00 -> hapus titik, jadikan koma titik
          numStr = numStr.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // Format 25,000.00 -> hapus koma
          numStr = numStr.replaceAll(',', '');
        }
      } else if (numStr.contains('.')) {
        // Jika terdapat lebih dari 1 titik, pasti ribuan (e.g. 1.500.000)
        final dotCount = '.'.allMatches(numStr).length;
        if (dotCount > 1) {
          numStr = numStr.replaceAll('.', '');
        } else {
          // Cek 3 digit setelah titik: 25.000 -> ribuan (25000)
          final parts = numStr.split('.');
          if (parts[1].length == 3) {
            numStr = parts[0] + parts[1];
          }
        }
      } else if (numStr.contains(',')) {
        final commaCount = ','.allMatches(numStr).length;
        if (commaCount > 1) {
          numStr = numStr.replaceAll(',', '');
        } else {
          final parts = numStr.split(',');
          if (parts[1].length == 3) {
            numStr = parts[0] + parts[1];
          } else if (parts[1].length == 2) {
            // sen desimal e.g. 25000,50
            numStr = '${parts[0]}.${parts[1]}';
          }
        }
      }

      final parsed = double.tryParse(numStr);
      if (parsed != null && parsed > 0) {
        // Ambil yang paling masuk akal (jika ada beberapa, prioritaskan yang terakhir di baris)
        candidate = parsed;
      }
    }

    return candidate;
  }

  // ─── HELPER: Tanggal & Waktu ───────────────────────────────────────────────

  static DateTime? _extractDateTime(List<String> lines) {
    for (var line in lines) {
      // Format DD/MM/YYYY atau DD-MM-YYYY atau YYYY-MM-DD
      final dateMatch = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})').firstMatch(line);
      if (dateMatch != null) {
        try {
          int d = int.parse(dateMatch.group(1)!);
          int m = int.parse(dateMatch.group(2)!);
          int y = int.parse(dateMatch.group(3)!);
          if (y < 100) y += 2000;
          if (m > 12 && d <= 12) {
            // Swap jika MM/DD
            final temp = m;
            m = d;
            d = temp;
          }
          // Jam & Menit jika ada
          final timeMatch = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(line);
          int hour = DateTime.now().hour;
          int minute = DateTime.now().minute;
          if (timeMatch != null) {
            hour = int.tryParse(timeMatch.group(1)!) ?? hour;
            minute = int.tryParse(timeMatch.group(2)!) ?? minute;
          }

          if (m >= 1 && m <= 12 && d >= 1 && d <= 31 && y >= 2020 && y <= 2030) {
            return DateTime(y, m, d, hour, minute);
          }
        } catch (_) {}
      }
    }
    return null;
  }
}

class _MerchantCategoryResult {
  final String merchant;
  final String title;
  final String category;

  _MerchantCategoryResult(this.merchant, this.title, this.category);
}

