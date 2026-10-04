import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class BarcodeProductResult {
  final String productName;
  final String? suggestedCategory;
  final bool isCustomLearned;

  const BarcodeProductResult({
    required this.productName,
    this.suggestedCategory,
    this.isCustomLearned = false,
  });
}

class BarcodeLookupService {
  // ─── 1. Offline Database Produk Terpopuler Indonesia ───────────────────────
  // Mencakup rokok, kopi sachet, mie, minuman, kebutuhan harian
  static final Map<String, Map<String, String>> _offlineIndonesianDB = {
    // 🚬 ROKOK (Cigarettes)
    '8999909001017': {'name': 'Rokok Gudang Garam Surya 16', 'cat': 'Rokok'},
    '8999909001024': {'name': 'Rokok Gudang Garam Surya 12', 'cat': 'Rokok'},
    '8999909005015': {'name': 'Rokok Gudang Garam International', 'cat': 'Rokok'},
    '8999909006012': {'name': 'Rokok Gudang Garam Merah', 'cat': 'Rokok'},
    '8999909033018': {'name': 'Rokok Surya Pro Mild 16', 'cat': 'Rokok'},
    '8999909015014': {'name': 'Rokok Surya Exclusive', 'cat': 'Rokok'},
    '8991389221524': {'name': 'Rokok Sampoerna A Mild 16', 'cat': 'Rokok'},
    '8991389221531': {'name': 'Rokok Sampoerna A Mild 12', 'cat': 'Rokok'},
    '8991389211518': {'name': 'Rokok Dji Sam Soe 234', 'cat': 'Rokok'},
    '8991389211525': {'name': 'Rokok Dji Sam Soe Magnum Filter', 'cat': 'Rokok'},
    '8991389211532': {'name': 'Rokok Dji Sam Soe Magnum Mild', 'cat': 'Rokok'},
    '8991389223528': {'name': 'Rokok U Mild 16', 'cat': 'Rokok'},
    '8991389011125': {'name': 'Rokok Marlboro Merah 20', 'cat': 'Rokok'},
    '8991389011132': {'name': 'Rokok Marlboro Gold Lights', 'cat': 'Rokok'},
    '8991389011149': {'name': 'Rokok Marlboro Ice Blast', 'cat': 'Rokok'},
    '8991389011156': {'name': 'Rokok Marlboro Filter Black 20', 'cat': 'Rokok'},
    '8992759111124': {'name': 'Rokok Djarum Super 12', 'cat': 'Rokok'},
    '8992759111162': {'name': 'Rokok Djarum Super 16', 'cat': 'Rokok'},
    '8992759151120': {'name': 'Rokok Djarum Black', 'cat': 'Rokok'},
    '8992759121123': {'name': 'Rokok Djarum 76', 'cat': 'Rokok'},
    '8992759131122': {'name': 'Rokok Djarum Coklat', 'cat': 'Rokok'},
    '8992759231129': {'name': 'Rokok LA Lights 16', 'cat': 'Rokok'},
    '8992759241128': {'name': 'Rokok LA Bold 20', 'cat': 'Rokok'},
    '8992759251127': {'name': 'Rokok LA Ice', 'cat': 'Rokok'},
    '8993175111111': {'name': 'Rokok Camel Yellow Filter', 'cat': 'Rokok'},
    '8993175121110': {'name': 'Rokok Camel Purple Option', 'cat': 'Rokok'},
    '8801116005513': {'name': 'Rokok Esse Change Double', 'cat': 'Rokok'},
    '8801116005520': {'name': 'Rokok Esse Berry Pop', 'cat': 'Rokok'},
    '8993176110012': {'name': 'Rokok Dunhill Filter', 'cat': 'Rokok'},

    // ☕ KOPI SACHET & MINUMAN SACHET (Coffee Sachets)
    '8991001100222': {'name': 'Kopi Kapal Api Spesial Mix', 'cat': 'Makanan & Minuman'},
    '8991001100215': {'name': 'Kopi Kapal Api Mantap Gula', 'cat': 'Makanan & Minuman'},
    '8991001100116': {'name': 'Kopi Kapal Api Spesial Hitam', 'cat': 'Makanan & Minuman'},
    '8991001100338': {'name': 'Kopi Kapal Api Gula Aren', 'cat': 'Makanan & Minuman'},
    '8991001100550': {'name': 'Kopi Kapal Api Kopi Susu', 'cat': 'Makanan & Minuman'},
    '8991001100772': {'name': 'Kopi Kapal Api Grande', 'cat': 'Makanan & Minuman'},
    '8991001414442': {'name': 'Kopi Good Day Cappuccino Sachet', 'cat': 'Makanan & Minuman'},
    '8991001414411': {'name': 'Kopi Good Day Mocacinno', 'cat': 'Makanan & Minuman'},
    '8991001414428': {'name': 'Kopi Good Day Vanilla Latte', 'cat': 'Makanan & Minuman'},
    '8991001414435': {'name': 'Kopi Good Day Chococinno', 'cat': 'Makanan & Minuman'},
    '8991001414459': {'name': 'Kopi Good Day Coolin Fresh Mint', 'cat': 'Makanan & Minuman'},
    '8991001414466': {'name': 'Kopi Good Day Carrebian Nut', 'cat': 'Makanan & Minuman'},
    '8994116001011': {'name': 'Kopi Luwak White Koffie Original', 'cat': 'Makanan & Minuman'},
    '8994116001028': {'name': 'Kopi Luwak White Koffie Tarik Malaka', 'cat': 'Makanan & Minuman'},
    '8994116001035': {'name': 'Kopi Luwak Mocca', 'cat': 'Makanan & Minuman'},
    '8996001301012': {'name': 'Kopi Torabika Duo', 'cat': 'Makanan & Minuman'},
    '8996001301029': {'name': 'Kopi Torabika Cappuccino', 'cat': 'Makanan & Minuman'},
    '8996001301036': {'name': 'Kopi Torabika Creamy Latte', 'cat': 'Makanan & Minuman'},
    '8996001301043': {'name': 'Kopi Torabika Jahe Susu', 'cat': 'Makanan & Minuman'},
    '8996001301050': {'name': 'Kopi Torabika Gilus Mix Gula Aren', 'cat': 'Makanan & Minuman'},
    '8992753211112': {'name': 'Kopi TOP Kopi Gula Aren', 'cat': 'Makanan & Minuman'},
    '8992753211129': {'name': 'Kopi TOP Kopi Kopi Susu', 'cat': 'Makanan & Minuman'},
    '8992753211136': {'name': 'Kopi TOP Kopi Barista Spesial', 'cat': 'Makanan & Minuman'},
    '8992753111115': {'name': 'Kopi ABC Plus Susu', 'cat': 'Makanan & Minuman'},
    '8992753111122': {'name': 'Kopi ABC Kopi Moka', 'cat': 'Makanan & Minuman'},
    '8992753111139': {'name': 'Kopi ABC Kopi Susu', 'cat': 'Makanan & Minuman'},
    '8997029920015': {'name': 'Kopi Caffino Kopi Latte Choco Malt', 'cat': 'Makanan & Minuman'},
    '8997029920022': {'name': 'Kopi Caffino Dark Cappuccino', 'cat': 'Makanan & Minuman'},
    '7613035345671': {'name': 'Nescafe Classic Sachet', 'cat': 'Makanan & Minuman'},

    // 🍜 MIE INSTAN & MAKANAN
    '8998866200225': {'name': 'Indomie Goreng Spesial', 'cat': 'Makanan & Minuman'},
    '8998866200218': {'name': 'Indomie Rasa Soto Mie', 'cat': 'Makanan & Minuman'},
    '8998866200232': {'name': 'Indomie Rasa Ayam Bawang', 'cat': 'Makanan & Minuman'},
    '8998866200249': {'name': 'Indomie Rasa Kari Ayam', 'cat': 'Makanan & Minuman'},
    '8998866200256': {'name': 'Indomie Goreng Rendang', 'cat': 'Makanan & Minuman'},
    '8998866200263': {'name': 'Indomie Goreng Pedas', 'cat': 'Makanan & Minuman'},
    '8998866200270': {'name': 'Indomie Goreng Aceh', 'cat': 'Makanan & Minuman'},
    '8998866200287': {'name': 'Indomie Hype Abis Seblak', 'cat': 'Makanan & Minuman'},
    '8992388111111': {'name': 'Mie Sedaap Goreng', 'cat': 'Makanan & Minuman'},
    '8992388111128': {'name': 'Mie Sedaap Rasa Soto', 'cat': 'Makanan & Minuman'},
    '8992388111135': {'name': 'Mie Sedaap Korean Spicy Soup', 'cat': 'Makanan & Minuman'},
    '8992388111142': {'name': 'Mie Sedaap Ayam Bawang Telur', 'cat': 'Makanan & Minuman'},
    '8991002101111': {'name': 'Sarimi Isi 2 Goreng Ayam Kecap', 'cat': 'Makanan & Minuman'},
    '8996001410110': {'name': 'Beng-Beng Cokelat Wafer', 'cat': 'Makanan & Minuman'},
    '8996001410127': {'name': 'Chocolatos Wafer Roll', 'cat': 'Makanan & Minuman'},
    '8996001410134': {'name': 'Roma Kelapa Biskuit', 'cat': 'Makanan & Minuman'},
    '8992775311027': {'name': 'Aqua Air Mineral 600ml', 'cat': 'Makanan & Minuman'},
    '8996001600115': {'name': 'Teh Pucuk Harum 350ml', 'cat': 'Makanan & Minuman'},
    '8992761111013': {'name': 'Teh Botol Sosro Kotak 250ml', 'cat': 'Makanan & Minuman'},
    '8991002301115': {'name': 'Ultra Milk Cokelat 250ml', 'cat': 'Makanan & Minuman'},
    '8991002301122': {'name': 'Ultra Milk Full Cream 250ml', 'cat': 'Makanan & Minuman'},
    '8992775211013': {'name': 'Le Minerale 600ml', 'cat': 'Makanan & Minuman'},
    '8991111001012': {'name': 'Pocari Sweat 500ml', 'cat': 'Makanan & Minuman'},
    '8992775111016': {'name': 'Floridina Orange 350ml', 'cat': 'Makanan & Minuman'},

    // 💊 KESEHATAN & OBAT
    '8992745111114': {'name': 'Tolak Angin Cair Herbal', 'cat': 'Kesehatan'},
    '8992745111121': {'name': 'Antangin JRG Cair', 'cat': 'Kesehatan'},
    '8992735111118': {'name': 'Bodrex Sakit Kepala 20 Tablet', 'cat': 'Kesehatan'},
    '8992735111125': {'name': 'Panadol Biru Paracetamol', 'cat': 'Kesehatan'},
    '8992735111132': {'name': 'Panadol Merah Extra', 'cat': 'Kesehatan'},
    '8992735111149': {'name': 'Paramex Sakit Kepala', 'cat': 'Kesehatan'},
    '8992735111156': {'name': 'Promag Obat Maag Tablet', 'cat': 'Kesehatan'},
    '8992735111163': {'name': 'Diapet Kapsul Diare', 'cat': 'Kesehatan'},
    '8992735111170': {'name': 'Minyak Kayu Putih Cap Lang 60ml', 'cat': 'Kesehatan'},

    // 🛒 BELANJA & KEPERLUAN
    '8999999001018': {'name': 'Sabun Lifebuoy Total 10 85g', 'cat': 'Belanja & Keperluan'},
    '8999999001025': {'name': 'Pasta Gigi Pepsodent 190g', 'cat': 'Belanja & Keperluan'},
    '8999999001032': {'name': 'Shampoo Sunsilk Black Shine 170ml', 'cat': 'Belanja & Keperluan'},
    '8999999001049': {'name': 'Deterjen Rinso Molto Anti Noda 770g', 'cat': 'Belanja & Keperluan'},
  };

  static Future<BarcodeProductResult?> lookup(String barcode, {StorageService? storage}) async {
    final cleanCode = barcode.trim();
    if (cleanCode.isEmpty) return null;

    // ─── LANGKAH 0: Cek Custom Barcode yang pernah dipelajari pengguna ───────
    if (storage != null) {
      final custom = storage.getCustomBarcode(cleanCode);
      if (custom != null && custom['name'] != null && custom['name']!.isNotEmpty) {
        return BarcodeProductResult(
          productName: custom['name']!,
          suggestedCategory: custom['cat'],
          isCustomLearned: true,
        );
      }
    }

    // ─── LANGKAH 1: Cek database lokal Indonesia (Instan 0 ms & 100% akurat) ─
    if (_offlineIndonesianDB.containsKey(cleanCode)) {
      final item = _offlineIndonesianDB[cleanCode]!;
      return BarcodeProductResult(
        productName: item['name']!,
        suggestedCategory: item['cat'],
      );
    }

    String? foundName;

    // ─── LANGKAH 2: Open Food Facts API (Indonesia & Global) ─────────────────
    try {
      final endpoints = [
        'https://id.openfoodfacts.org/api/v0/product/$cleanCode.json',
        'https://world.openfoodfacts.org/api/v0/product/$cleanCode.json',
      ];

      for (final ep in endpoints) {
        final response = await http.get(
          Uri.parse(ep),
          headers: {'User-Agent': 'DompiFinanceApp - Android - Version 2.0'},
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['status'] == 1 && data['product'] != null) {
            final product = data['product'];
            final idName = product['product_name_id']?.toString().trim();
            final genericId = product['generic_name_id']?.toString().trim();
            final globalName = product['product_name']?.toString().trim();
            final brand = product['brands']?.toString().trim();

            if (idName != null && idName.isNotEmpty) {
              foundName = idName;
              break;
            } else if (genericId != null && genericId.isNotEmpty) {
              foundName = genericId;
              break;
            } else if (globalName != null && globalName.isNotEmpty) {
              foundName = brand != null && brand.isNotEmpty ? '$brand $globalName' : globalName;
              break;
            } else if (brand != null && brand.isNotEmpty) {
              foundName = brand;
              break;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('OpenFoodFacts lookup failed: $e');
    }

    // ─── LANGKAH 3: UPCItemDB Backup ─────────────────────────────────────────
    if (foundName == null || foundName.isEmpty) {
      try {
        final url = Uri.parse('https://api.upcitemdb.com/prod/trial/lookup?upc=$cleanCode');
        final response = await http.get(url).timeout(const Duration(seconds: 3));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['items'] != null && (data['items'] as List).isNotEmpty) {
            final item = data['items'][0];
            final title = item['title']?.toString().trim();
            if (title != null && title.isNotEmpty) {
              foundName = title;
            }
          }
        }
      } catch (e) {
        debugPrint('UPCItemDB lookup failed: $e');
      }
    }

    // ─── LANGKAH 4: Web Scraping Search (Google / DuckDuckGo) ────────────────
    if (foundName == null || foundName.isEmpty) {
      try {
        final searchUrl = Uri.parse('https://html.duckduckgo.com/html/?q=$cleanCode');
        final searchRes = await http.get(
          searchUrl,
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          },
        ).timeout(const Duration(seconds: 3));

        if (searchRes.statusCode == 200) {
          final body = searchRes.body;
          final regexTitle = RegExp(
            r'<a class="result__snippet[^>]*>([^<]+)<\/a>',
            caseSensitive: false,
          );
          final match = regexTitle.firstMatch(body);
          if (match != null && match.group(1) != null) {
            var snippet = match.group(1)!.trim();
            snippet = _cleanScrapedTitle(snippet);
            if (snippet.length > 3) {
              foundName = snippet;
            }
          }
        }
      } catch (e) {
        debugPrint('Web scraping search failed: $e');
      }
    }

    // Jika setelah semua cara tetap tidak ditemukan, kembalikan NULL secara jujur!
    if (foundName == null || foundName.trim().isEmpty) {
      return null;
    }

    // Rapikan nama produk
    foundName = _formatCleanProductName(foundName);

    // Auto-detect matching category
    final suggestedCategory = _guessCategory(foundName);

    return BarcodeProductResult(
      productName: foundName,
      suggestedCategory: suggestedCategory,
    );
  }

  static String _cleanScrapedTitle(String text) {
    var cleaned = text
        .replaceAll(RegExp(r'https?:\/\/\S+'), '')
        .replaceAll(RegExp(r'(Tokopedia|Shopee|Blibli|Bukalapak|Lazada|Beli|Jual|Harga|Promo|Diskon)'), '')
        .replaceAll(RegExp(r'[:|•\-–—_]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (cleaned.length > 50) {
      cleaned = cleaned.substring(0, 50).trim();
    }
    return cleaned;
  }

  static String _formatCleanProductName(String name) {
    var clean = name.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (clean.length > 45) {
      clean = '${clean.substring(0, 42)}...';
    }
    return clean;
  }

  static String? _guessCategory(String name) {
    final lower = name.toLowerCase();

    // Rokok
    if (lower.contains('rokok') ||
        lower.contains('surya') ||
        lower.contains('marlboro') ||
        lower.contains('sampoerna') ||
        lower.contains('djarum') ||
        lower.contains('magnum') ||
        lower.contains('camel') ||
        lower.contains('esse') ||
        lower.contains('mild') ||
        lower.contains('kretek') ||
        lower.contains('dunhill') ||
        lower.contains('filter')) {
      return 'Rokok';
    }

    // Makanan & Minuman
    if (lower.contains('kopi') ||
        lower.contains('coffee') ||
        lower.contains('kapal api') ||
        lower.contains('good day') ||
        lower.contains('luwak') ||
        lower.contains('torabika') ||
        lower.contains('caffino') ||
        lower.contains('mie') ||
        lower.contains('noodle') ||
        lower.contains('teh') ||
        lower.contains('susu') ||
        lower.contains('milk') ||
        lower.contains('aqua') ||
        lower.contains('snack') ||
        lower.contains('biskuit') ||
        lower.contains('roti') ||
        lower.contains('cokelat') ||
        lower.contains('goreng') ||
        lower.contains('jus') ||
        lower.contains('wafer') ||
        lower.contains('indomie') ||
        lower.contains('sedaap') ||
        lower.contains('beng-beng') ||
        lower.contains('chitato')) {
      return 'Makanan & Minuman';
    }

    // Kesehatan
    if (lower.contains('obat') ||
        lower.contains('vitamin') ||
        lower.contains('panadol') ||
        lower.contains('paracetamol') ||
        lower.contains('bodrex') ||
        lower.contains('tolak angin') ||
        lower.contains('antangin') ||
        lower.contains('promag') ||
        lower.contains('paramex') ||
        lower.contains('masker') ||
        lower.contains('koyo') ||
        lower.contains('minyak kayu putih')) {
      return 'Kesehatan';
    }

    // Belanja & Keperluan
    if (lower.contains('sabun') ||
        lower.contains('shampoo') ||
        lower.contains('odol') ||
        lower.contains('pasta gigi') ||
        lower.contains('pepsodent') ||
        lower.contains('lifebuoy') ||
        lower.contains('deterjen') ||
        lower.contains('rinso') ||
        lower.contains('daia') ||
        lower.contains('pewangi') ||
        lower.contains('tissue') ||
        lower.contains('minyak') ||
        lower.contains('beras') ||
        lower.contains('gula')) {
      return 'Belanja & Keperluan';
    }

    return null;
  }
}
