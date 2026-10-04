import 'package:flutter_test/flutter_test.dart';
import 'package:pencatat_keuangan/services/receipt_parser_service.dart';

void main() {
  group('ReceiptParserService Tests', () {
    test('Parse Indomaret receipt', () {
      const sampleIndomaret = '''
PT INDOMARCO PRISMATAMA
INDOMARET RAYA BOGOR
JL. RAYA BOGOR NO. 12
TGL 12/09/2026 14:30
--------------------------------
ROKOK SURYA 16         34.000
INDOMIE GORENG          3.500
AQUA 600ML              4.000
--------------------------------
TOTAL BELANJA          41.500
TUNAI                  50.000
KEMBALI                 8.500
''';
      final result = ReceiptParserService.parse(sampleIndomaret);
      expect(result.amount, equals(41500.0));
      expect(result.merchantName, equals('Indomaret'));
      expect(result.category, equals('Belanja & Keperluan'));
      expect(result.isExpense, isTrue);
    });

    test('Parse Alfamart receipt', () {
      const sampleAlfamart = '''
ALFAMART CIPUTAT
TGL 10-09-2026 09:15
KOPI KAPAL API          2.000
ROTI TAWAR SARI ROTI   15.000
SUBTOTAL               17.000
TOTAL BAYAR            17.000
''';
      final result = ReceiptParserService.parse(sampleAlfamart);
      expect(result.amount, equals(17000.0));
      expect(result.merchantName, equals('Alfamart'));
      expect(result.category, equals('Belanja & Keperluan'));
      expect(result.isExpense, isTrue);
    });

    test('Parse ATM BCA Tarik Tunai slip', () {
      const sampleAtmBca = '''
BANK CENTRAL ASIA
STRUK PENARIKAN TUNAI
LOKASI ATM: KCP SUDIRMAN
TANGGAL: 12/09/2026 10:20
NOMINAL PENARIKAN: RP 500.000
SALDO AKHIR: RP 4.500.000
STATUS: BERHASIL
''';
      final result = ReceiptParserService.parse(sampleAtmBca);
      expect(result.amount, equals(500000.0));
      expect(result.isExpense, isFalse);
      expect(result.title, contains('Tarik Tunai'));
      expect(result.category, equals('Transfer Masuk'));
    });

    test('Parse SPBU Pertamina receipt', () {
      const sampleSpbu = '''
SPBU PERTAMINA 34.12345
JL. GATOT SUBROTO
PERTAMAX 92
LITER: 7.81
TOTAL: RP 100.000
''';
      final result = ReceiptParserService.parse(sampleSpbu);
      expect(result.amount, equals(100000.0));
      expect(result.category, equals('Transport'));
      expect(result.isExpense, isTrue);
    });
  });
}

