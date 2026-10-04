import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/categories.dart';
import '../core/formatters.dart';
import '../services/storage_service.dart';
import '../services/excel_service.dart';

class ReportsScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback? onExportExcel;

  const ReportsScreen({
    super.key,
    required this.storage,
    this.onExportExcel,
  });

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late DateTime _selectedMonth;
  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  }

  bool _canGoPrevious(List<DateTime> available) {
    if (available.isEmpty) return false;
    final oldest = available.last;
    return _selectedMonth.isAfter(oldest);
  }

  bool _canGoNext(List<DateTime> available) {
    if (available.isEmpty) return false;
    final newest = available.first;
    return _selectedMonth.isBefore(newest);
  }

  void _previousMonth(List<DateTime> available) {
    if (_canGoPrevious(available)) {
      setState(() {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      });
    }
  }

  void _nextMonth(List<DateTime> available) {
    if (_canGoNext(available)) {
      setState(() {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
      });
    }
  }

  void _showMonthPicker(List<DateTime> availableMonths) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.hairlineDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Pilih Periode Laporan', style: AppText.titleLg()),
            const SizedBox(height: 6),
            Text(
              'Riwayat dari awal instalasi aplikasi hingga bulan berjalan saat ini.',
              style: AppText.caption(),
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.45,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: availableMonths.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final monthDate = availableMonths[index];
                  final isSelected = _selectedMonth.year == monthDate.year &&
                      _selectedMonth.month == monthDate.month;
                  final monthTx = widget.storage.transactions.where((t) =>
                      t.date.year == monthDate.year && t.date.month == monthDate.month);
                  final count = monthTx.length;

                  return Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.surfaceElevated : AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : AppColors.hairlineDark,
                      ),
                    ),
                    child: ListTile(
                      leading: Icon(
                        Icons.calendar_month,
                        color: isSelected ? AppColors.primary : AppColors.muted,
                      ),
                      title: Text(
                        DateFormat('MMMM yyyy', 'id_ID').format(monthDate),
                        style: AppText.titleSm(
                          color: isSelected ? AppColors.primary : AppColors.onDark,
                        ),
                      ),
                      subtitle: Text(
                        count > 0 ? '$count transaksi' : 'Belum ada transaksi',
                        style: AppText.caption(),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _selectedMonth = monthDate);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _showDeleteMonthDialog() {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);
    final monthTransactions = widget.storage.transactions.where((t) =>
        t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month).toList();

    if (monthTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak ada data transaksi di $monthName untuk dihapus.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppColors.tradingDown, size: 24),
            const SizedBox(width: 8),
            Expanded(child: Text('Hapus Data $monthName?', style: AppText.titleMedium())),
          ],
        ),
        content: Text(
          'Akan menghapus seluruh ${monthTransactions.length} transaksi di bulan $monthName secara permanen agar penyimpanan tidak menumpuk. Tindakan ini tidak dapat dibatalkan.',
          style: AppText.bodyMd(color: AppColors.body),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Batal', style: AppText.button(color: AppColors.muted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tradingDown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final count = await widget.storage.deleteTransactionsForMonth(
                _selectedMonth.year,
                _selectedMonth.month,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Berhasil menghapus $count transaksi di $monthName.'),
                    backgroundColor: AppColors.tradingDown,
                  ),
                );
              }
            },
            child: const Text('Hapus Semua'),
          ),
        ],
      ),
    );
  }

  void _showExportOptions() {
    final monthName = DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth);
    final monthTransactions = widget.storage.transactions.where((t) =>
        t.date.year == _selectedMonth.year && t.date.month == _selectedMonth.month).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.hairlineDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Pilih Jenis Ekspor Excel', style: AppText.titleLg()),
            const SizedBox(height: 6),
            Text(
              'Pilih apakah ingin mengekspor data bulan terpilih saja atau semua riwayat.',
              style: AppText.caption(),
            ),
            const SizedBox(height: 16),
            // Opsi 1: Bulan Terpilih
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month, color: AppColors.primary, size: 20),
                ),
                title: Text('Data Bulan Ini ($monthName)', style: AppText.titleSm()),
                subtitle: Text('${monthTransactions.length} Transaksi', style: AppText.caption()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted),
                onTap: () {
                  Navigator.pop(ctx);
                  ExcelExportService.exportTransactions(
                    context: context,
                    transactions: monthTransactions,
                    monthlyBudget: widget.storage.monthlyBudget,
                    periodLabel: monthName,
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            // Opsi 2: Semua Data
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.tradingUp.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.all_inbox, color: AppColors.tradingUp, size: 20),
                ),
                title: Text('Semua Data Transaksi', style: AppText.titleSm()),
                subtitle: Text('${widget.storage.transactions.length} Total Transaksi', style: AppText.caption()),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.muted),
                onTap: () {
                  Navigator.pop(ctx);
                  ExcelExportService.exportTransactions(
                    context: context,
                    transactions: widget.storage.transactions,
                    monthlyBudget: widget.storage.monthlyBudget,
                    periodLabel: 'Semua Data',
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableMonths = widget.storage.getAvailableMonths();
    if (availableMonths.isNotEmpty && _selectedMonth.isAfter(availableMonths.first)) {
      _selectedMonth = availableMonths.first;
    }
    final canPrev = _canGoPrevious(availableMonths);
    final canNext = _canGoNext(availableMonths);

    final totalExpense = widget.storage.totalExpense(forMonth: _selectedMonth);
    final totalIncome = widget.storage.totalIncome(forMonth: _selectedMonth);
    final netBalance = totalIncome - totalExpense;

    // Filter transactions for this month
    final monthExpenses = widget.storage.transactions.where((t) =>
        t.isExpense &&
        t.date.year == _selectedMonth.year &&
        t.date.month == _selectedMonth.month).toList();

    // Group by category
    final Map<String, double> categorySums = {};
    final Map<String, int> categoryCounts = {};
    for (var tx in monthExpenses) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
      categoryCounts[tx.category] = (categoryCounts[tx.category] ?? 0) + 1;
    }

    final sortedEntries = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Text('Laporan & Grafik', style: AppText.titleLg()),
        backgroundColor: AppColors.canvasDark,
        elevation: 0,
        actions: [
          // Tombol Hapus Data per Bulan
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: AppColors.tradingDown),
            tooltip: 'Hapus Data Bulan Ini',
            onPressed: _showDeleteMonthDialog,
          ),
          // Tombol Ekspor dengan Pilihan
          IconButton(
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary),
            tooltip: 'Ekspor Excel',
            onPressed: _showExportOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Month Switcher
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: canPrev ? AppColors.primary : AppColors.muted.withOpacity(0.3),
                    ),
                    tooltip: canPrev ? 'Bulan Sebelumnya' : null,
                    onPressed: canPrev ? () => _previousMonth(availableMonths) : null,
                  ),
                  Expanded(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _showMonthPicker(availableMonths),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_month, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              DateFormat('MMMM yyyy', 'id_ID').format(_selectedMonth),
                              style: AppText.titleMedium(),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.arrow_drop_down, color: AppColors.muted, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: canNext ? AppColors.primary : AppColors.muted.withOpacity(0.3),
                    ),
                    tooltip: canNext ? 'Bulan Berikutnya' : null,
                    onPressed: canNext ? () => _nextMonth(availableMonths) : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. Summary 3-Column
            Row(
              children: [
                Expanded(
                  child: _buildSummaryBox('Pemasukan', totalIncome, AppColors.tradingUp),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox('Pengeluaran', totalExpense, AppColors.tradingDown),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryBox('Bersih', netBalance, netBalance >= 0 ? AppColors.primary : AppColors.tradingDown),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 3. Donut Pie Chart Distribusi Kategori
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distribusi Pengeluaran', style: AppText.titleMedium()),
                  const SizedBox(height: 4),
                  Text('Berdasarkan kategori pengeluaran bulan ini', style: AppText.caption()),
                  const SizedBox(height: 24),

                  if (monthExpenses.isEmpty)
                    Container(
                      height: 180,
                      alignment: Alignment.center,
                      child: Text('Belum ada transaksi di bulan ini', style: AppText.bodySm()),
                    )
                  else
                    SizedBox(
                      height: 200,
                      child: PieChart(
                        PieChartData(
                          pieTouchData: PieTouchData(
                            touchCallback: (FlTouchEvent event, pieTouchResponse) {
                              setState(() {
                                if (!event.isInterestedForInteractions ||
                                    pieTouchResponse == null ||
                                    pieTouchResponse.touchedSection == null) {
                                  _touchedPieIndex = -1;
                                  return;
                                }
                                _touchedPieIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                              });
                            },
                          ),
                          sectionsSpace: 3,
                          centerSpaceRadius: 50,
                          sections: sortedEntries.asMap().entries.map((entry) {
                            final i = entry.key;
                            final e = entry.value;
                            final isTouched = i == _touchedPieIndex;
                            final radius = isTouched ? 45.0 : 35.0;
                            final cat = getCategoryInfo(e.key);
                            final percent = totalExpense > 0 ? (e.value / totalExpense) * 100 : 0.0;

                            return PieChartSectionData(
                              color: cat?.color ?? AppColors.muted,
                              value: e.value,
                              title: percent >= 5 ? '${percent.toStringAsFixed(0)}%' : '',
                              radius: radius,
                              titleStyle: AppText.caption(color: Colors.white),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Detail Kategori List
            Text('Rincian Kategori', style: AppText.titleMedium()),
            const SizedBox(height: 10),

            if (sortedEntries.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairlineDark),
                ),
                child: Center(
                  child: Text('Tidak ada pengeluaran di bulan ini', style: AppText.bodySm()),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: sortedEntries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final entry = sortedEntries[index];
                  final cat = getCategoryInfo(entry.key);
                  final count = categoryCounts[entry.key] ?? 0;
                  final percent = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.hairlineDark),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (cat?.color ?? AppColors.muted).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(cat?.icon ?? Icons.category, size: 18, color: cat?.color ?? AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key, style: AppText.titleSm()),
                                  Text('$count Transaksi • ${percent.toStringAsFixed(1)}%', style: AppText.caption()),
                                ],
                              ),
                            ),
                            Text(
                              AppFormatters.rupiah(entry.value),
                              style: AppText.numMd(color: AppColors.onDark),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: (percent / 100).clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: AppColors.surfaceElevated,
                            valueColor: AlwaysStoppedAnimation<Color>(cat?.color ?? AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBox(String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.hairlineDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption()),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppFormatters.compactRupiah(value),
              style: AppText.numMd(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

