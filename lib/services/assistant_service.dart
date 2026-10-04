import 'package:intl/intl.dart';
import '../core/formatters.dart';
import 'storage_service.dart';

class AssistantMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? quickActions;

  AssistantMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.quickActions,
  });
}

class AssistantService {
  final StorageService storage;

  AssistantService(this.storage);

  static const List<String> defaultSuggestions = [
    'Pengeluaran bulan ini',
    'Pemasukan bulan ini',
    'Sisa budget saya',
    'Kategori paling boros',
    'Pengeluaran minggu ini',
    'Pengeluaran hari ini',
    'Berapa untuk Rokok?',
    'Rata-rata harian',
    '5 Transaksi terakhir',
  ];

  AssistantMessage processQuery(String query) {
    final lower = query.toLowerCase().trim();
    final now = DateTime.now();

    // 1. Pengeluaran hari ini
    if (lower.contains('hari ini') && (lower.contains('keluar') || lower.contains('pengeluaran') || lower.contains('belanja'))) {
      final todayTx = storage.transactions.where((t) =>
          t.isExpense &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day).toList();

      final total = todayTx.fold(0.0, (sum, t) => sum + t.amount);
      if (todayTx.isEmpty) {
        return AssistantMessage(
          text: '📅 **Hari Ini (${AppFormatters.dateShort(now)})**\n\nKamu belum mencatat pengeluaran apa pun hari ini. Bagus, keuanganmu masih aman! 👏',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
      final items = todayTx.take(5).map((t) => '• ${t.title}: **${AppFormatters.rupiah(t.amount)}** (${t.category})').join('\n');
      return AssistantMessage(
        text: '📅 **Pengeluaran Hari Ini (${AppFormatters.dateShort(now)})**\n\nTotal: **${AppFormatters.rupiah(total)}** (${todayTx.length} transaksi)\n\n$items',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 2. Pemasukan hari ini
    if (lower.contains('hari ini') && (lower.contains('masuk') || lower.contains('pemasukan') || lower.contains('gaji'))) {
      final todayIn = storage.transactions.where((t) =>
          t.isIncome &&
          t.date.year == now.year &&
          t.date.month == now.month &&
          t.date.day == now.day).toList();
      final total = todayIn.fold(0.0, (sum, t) => sum + t.amount);
      return AssistantMessage(
        text: '💰 **Pemasukan Hari Ini**\n\nTotal pemasukan tercatat hari ini: **${AppFormatters.rupiah(total)}**.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 3. Pengeluaran minggu ini
    if (lower.contains('minggu ini')) {
      final weekStart = now.subtract(Duration(days: now.weekday - 1));
      final weekStartClean = DateTime(weekStart.year, weekStart.month, weekStart.day);

      final weekTx = storage.transactions.where((t) =>
          t.isExpense && t.date.isAfter(weekStartClean.subtract(const Duration(seconds: 1)))).toList();

      final total = weekTx.fold(0.0, (sum, t) => sum + t.amount);
      return AssistantMessage(
        text: '🗓️ **Pengeluaran Minggu Ini**\n\nTotal: **${AppFormatters.rupiah(total)}** dari **${weekTx.length}** transaksi.\n\nTips: Tetap kendalikan jajan harian ya!',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 4. Pengeluaran bulan ini
    if (lower.contains('pengeluaran bulan') || (lower.contains('pengeluaran') && lower.contains('bulan ini')) || lower == 'pengeluaran') {
      final total = storage.totalExpense(forMonth: now);
      final txList = storage.transactions.where((t) => t.isExpense && t.date.year == now.year && t.date.month == now.month).toList();

      // Group by category
      final Map<String, double> catMap = {};
      for (var t in txList) {
        catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
      }
      final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top3 = sorted.take(3).map((e) => '• ${e.key}: **${AppFormatters.rupiah(e.value)}** (${(e.value / (total == 0 ? 1 : total) * 100).toStringAsFixed(1)}%)').join('\n');

      return AssistantMessage(
        text: '📊 **Laporan Pengeluaran Bulan Ini (${DateFormat('MMMM yyyy', 'id_ID').format(now)})**\n\n'
              '💸 Total Keluar: **${AppFormatters.rupiah(total)}**\n'
              '📝 Banyak Transaksi: **${txList.length}** transaksi\n\n'
              '**Top 3 Kategori Terbesar:**\n$top3',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 5. Pemasukan bulan ini
    if (lower.contains('pemasukan') || lower.contains('gaji') || lower.contains('penghasilan')) {
      final totalIn = storage.totalIncome(forMonth: now);
      final totalOut = storage.totalExpense(forMonth: now);
      final net = totalIn - totalOut;

      return AssistantMessage(
        text: '📈 **Laporan Pemasukan Bulan Ini**\n\n'
              '💰 Total Pemasukan: **${AppFormatters.rupiah(totalIn)}**\n'
              '💸 Total Pengeluaran: **${AppFormatters.rupiah(totalOut)}**\n'
              '⚖️ Saldo Bersih: **${AppFormatters.rupiah(net)}**\n\n'
              '${net >= 0 ? '🟢 Arus kas bulan ini dalam kondisi surplus (sehat)!' : '🔴 Arus kas defisit! Pengeluaran lebih besar dari pemasukan.'}',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 6. Sisa Budget
    if (lower.contains('budget') || lower.contains('sisa') || lower.contains('tekor')) {
      final budget = storage.monthlyBudget;
      final expense = storage.totalExpense(forMonth: now);
      final remaining = budget - expense;

      if (budget <= 0) {
        return AssistantMessage(
          text: '💡 Kamu belum mengatur target **Budget Bulanan**.\n\nKlik ikon pensil di kartu saldo halaman Beranda untuk mengaturnya sekarang.',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }

      final percent = ((expense / budget) * 100).toStringAsFixed(1);
      return AssistantMessage(
        text: '🎯 **Status Budget Bulan Ini**\n\n'
              '• Target Budget: **${AppFormatters.rupiah(budget)}**\n'
              '• Terpakai: **${AppFormatters.rupiah(expense)}** ($percent%)\n'
              '• Sisa Budget: **${AppFormatters.rupiah(remaining)}**\n\n'
              '${remaining < 0 ? '⚠️ **Peringatan!** Pengeluaran sudah melampaui budget!' : (expense / budget > 0.85 ? '⚠️ **Hati-hati!** Sisa budgetmu menipis.' : '✅ Budget kamu masih dalam batas aman.')}',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 7. Kategori spesifik (Rokok, Makanan, Transport, dll)
    final categoriesToCheck = ['rokok', 'makanan', 'transport', 'belanja', 'hiburan', 'tagihan', 'kesehatan'];
    for (var catKey in categoriesToCheck) {
      if (lower.contains(catKey)) {
        final matched = storage.transactions.where((t) =>
            t.isExpense &&
            t.category.toLowerCase().contains(catKey) &&
            t.date.year == now.year &&
            t.date.month == now.month).toList();
        final total = matched.fold(0.0, (sum, t) => sum + t.amount);

        return AssistantMessage(
          text: '🔍 **Analisis Kategori: ${catKey.toUpperCase()} (Bulan Ini)**\n\n'
                '• Total Belanja: **${AppFormatters.rupiah(total)}**\n'
                '• Frekuensi: **${matched.length} kali**\n\n'
                '${matched.isNotEmpty ? 'Catatan terakhir: "${matched.first.title}" (${AppFormatters.rupiah(matched.first.amount)})' : 'Belum ada transaksi untuk kategori ini bulan ini.'}',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
    }

    // 8. Kategori paling boros
    if (lower.contains('boros') || lower.contains('terbesar') || lower.contains('paling banyak')) {
      final txList = storage.transactions.where((t) => t.isExpense && t.date.year == now.year && t.date.month == now.month).toList();
      if (txList.isEmpty) {
        return AssistantMessage(
          text: 'Belum ada pengeluaran yang tercatat di bulan ini.',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
      final Map<String, double> catMap = {};
      for (var t in txList) {
        catMap[t.category] = (catMap[t.category] ?? 0) + t.amount;
      }
      final sorted = catMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      final top = sorted.first;

      return AssistantMessage(
        text: '🔥 **Kategori Paling Boros Bulan Ini:**\n\n'
              'Juara 1: **${top.key}** sebesar **${AppFormatters.rupiah(top.value)}**\n\n'
              '💡 Tips: Coba buat batas alokasi khusus untuk kategori ini agar pengeluaran tidak membengkak.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 9. Rata-rata harian
    if (lower.contains('rata-rata') || lower.contains('rata rata') || lower.contains('per hari')) {
      final total = storage.totalExpense(forMonth: now);
      final daysPassed = now.day;
      final avg = daysPassed > 0 ? total / daysPassed : 0.0;

      return AssistantMessage(
        text: '⏱️ **Rata-Rata Pengeluaran Harian**\n\n'
              'Bulan ini sudah berjalan **$daysPassed hari**.\n'
              'Rata-rata pengeluaranmu: **${AppFormatters.rupiah(avg)} per hari**.',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // 10. List transaksi terakhir
    if (lower.contains('list') || lower.contains('terakhir') || lower.contains('riwayat') || lower.contains('daftar')) {
      final latest = storage.transactions.take(5).toList();
      if (latest.isEmpty) {
        return AssistantMessage(
          text: 'Daftar transaksi masih kosong.',
          isUser: false,
          timestamp: DateTime.now(),
        );
      }
      final items = latest.map((t) =>
        '${t.isExpense ? '🔴' : '🟢'} **${t.title}**\n   ${AppFormatters.rupiah(t.amount)} • ${t.category} • ${AppFormatters.dateShort(t.date)}'
      ).join('\n\n');

      return AssistantMessage(
        text: '📋 **5 Transaksi Terakhir:**\n\n$items',
        isUser: false,
        timestamp: DateTime.now(),
      );
    }

    // Default Fallback
    return AssistantMessage(
      text: '🤖 **Hai! Saya Dompi AI Assistant.**\n\n'
            'Saya bisa membantu menjawab berbagai pertanyaan seputar keuanganmu langsung dari data tersimpan:\n\n'
            '• *"Berapa pengeluaran minggu ini?"*\n'
            '• *"Berapa pengeluaran hari ini?"*\n'
            '• *"Berapa pemasukan bulan ini?"*\n'
            '• *"Kategori apa yang paling boros?"*\n'
            '• *"Berapa pengeluaran untuk rokok?"*\n'
            '• *"Sisa budget saya berapa?"*\n'
            '• *"Rata-rata pengeluaran per hari?"*\n'
            '• *"Tampilkan 5 transaksi terakhir"*',
      isUser: false,
      timestamp: DateTime.now(),
      quickActions: defaultSuggestions,
    );
  }
}
