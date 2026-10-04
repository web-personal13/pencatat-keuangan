import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../core/theme.dart';
import '../core/formatters.dart';
import '../core/categories.dart';
import '../services/storage_service.dart';

class ResearchScreen extends StatefulWidget {
  final StorageService storage;

  const ResearchScreen({super.key, required this.storage});

  @override
  State<ResearchScreen> createState() => _ResearchScreenState();
}

class _ResearchScreenState extends State<ResearchScreen> {
  int _selectedPeriodMonths = 1; // 1 = 1 bulan ini, 3 = 3 bulan, 6 = 6 bulan

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final transactions = widget.storage.transactions;

    // Filter by period
    final cutoffDate = DateTime(now.year, now.month - (_selectedPeriodMonths - 1), 1);
    final periodTx = transactions.where((t) => t.date.isAfter(cutoffDate.subtract(const Duration(seconds: 1)))).toList();

    final totalExpense = periodTx.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final totalIncome = periodTx.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);
    final netSavings = totalIncome - totalExpense;

    // Health Score calculation (0 - 100)
    int healthScore = 70;
    if (totalIncome > 0) {
      final savingsRate = netSavings / totalIncome;
      if (savingsRate >= 0.3) {
        healthScore = 95;
      } else if (savingsRate >= 0.15) {
        healthScore = 85;
      } else if (savingsRate >= 0) {
        healthScore = 70;
      } else if (savingsRate >= -0.2) {
        healthScore = 50;
      } else {
        healthScore = 35;
      }
    } else if (totalExpense > 0) {
      healthScore = 60;
    }

    // Day of week spending analysis (1 = Monday, 7 = Sunday)
    final Map<int, double> dayOfWeekSums = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0, 7: 0};
    for (var tx in periodTx.where((t) => t.isExpense)) {
      dayOfWeekSums[tx.date.weekday] = (dayOfWeekSums[tx.date.weekday] ?? 0) + tx.amount;
    }

    // Find highest spending day
    int maxDay = 1;
    double maxDayAmount = 0;
    dayOfWeekSums.forEach((day, amount) {
      if (amount > maxDayAmount) {
        maxDayAmount = amount;
        maxDay = day;
      }
    });

    final dayNames = {1: 'Senin', 2: 'Selasa', 3: 'Rabu', 4: 'Kamis', 5: 'Jumat', 6: 'Sabtu', 7: 'Minggu'};
    final highestDayName = maxDayAmount > 0 ? dayNames[maxDay] : '-';

    // Rokok & Makanan specific tracking
    final rokokExpense = periodTx.where((t) => t.isExpense && t.category.toLowerCase().contains('rokok')).fold(0.0, (s, t) => s + t.amount);
    final makananExpense = periodTx.where((t) => t.isExpense && t.category.toLowerCase().contains('makanan')).fold(0.0, (s, t) => s + t.amount);

    // Breakdown pengeluaran per Jenis/Kategori untuk grafik balok
    final Map<String, double> categorySums = {};
    for (var tx in periodTx.where((t) => t.isExpense)) {
      categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
    }
    final sortedCategorySums = categorySums.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Dynamic AI Insights list
    final List<Map<String, dynamic>> insights = [];

    if (totalExpense > 0 && rokokExpense > 0) {
      final rokokPercent = (rokokExpense / totalExpense) * 100;
      insights.add({
        'icon': Icons.smoking_rooms,
        'color': AppColors.accentGray,
        'title': 'Riset Pengeluaran Rokok',
        'desc': 'Kamu menghabiskan ${AppFormatters.rupiah(rokokExpense)} (${rokokPercent.toStringAsFixed(1)}% dari total). Jika dikurangi 20%, kamu bisa menghemat ${AppFormatters.rupiah(rokokExpense * 0.2)} per periode!',
      });
    }

    if (totalExpense > 0 && makananExpense > 0) {
      final makananPercent = (makananExpense / totalExpense) * 100;
      if (makananPercent > 40) {
        insights.add({
          'icon': Icons.restaurant,
          'color': AppColors.tradingDown,
          'title': 'Alokasi Makanan Cukup Tinggi',
          'desc': 'Makanan menyerap ${makananPercent.toStringAsFixed(1)}% anggaranmu. Memasak sendiri di rumah dapat memangkas hingga 30% pengeluaran makanan.',
        });
      }
    }

    if (maxDayAmount > 0) {
      insights.add({
        'icon': Icons.calendar_today,
        'color': AppColors.accentOrange,
        'title': 'Hari Terboros: $highestDayName',
        'desc': 'Pengeluaranmu cenderung melonjak di hari $highestDayName (${AppFormatters.rupiah(maxDayAmount)}). Waspadai pengeluaran impulsif di hari tersebut!',
      });
    }

    insights.add({
      'icon': Icons.tips_and_updates,
      'color': AppColors.primary,
      'title': 'Aturan Finansial 50/30/20',
      'desc': 'Idealnya alokasikan 50% untuk kebutuhan pokok (tagihan & makan), 30% untuk hiburan, dan 20% disisihkan untuk tabungan/dana darurat.',
    });

    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Text('Riset Finansial', style: AppText.titleLg()),
        backgroundColor: AppColors.canvasDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period Filter Selector
            Row(
              children: [
                _buildPeriodTab('Bulan Ini', 1),
                const SizedBox(width: 8),
                _buildPeriodTab('3 Bulan', 3),
                const SizedBox(width: 8),
                _buildPeriodTab('6 Bulan', 6),
              ],
            ),
            const SizedBox(height: 16),

            // Financial Health Score Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E2329), Color(0xFF262C34)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: Row(
                children: [
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: healthScore >= 80 ? AppColors.tradingUp : (healthScore >= 50 ? AppColors.primary : AppColors.tradingDown),
                        width: 4,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$healthScore',
                        style: AppText.numLg(
                          color: healthScore >= 80 ? AppColors.tradingUp : (healthScore >= 50 ? AppColors.primary : AppColors.tradingDown),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Skor Kesehatan Keuangan', style: AppText.caption()),
                        const SizedBox(height: 4),
                        Text(
                          healthScore >= 80
                              ? 'Sangat Sehat 🎉'
                              : (healthScore >= 50 ? 'Cukup Terkendali 👍' : 'Perlu Dihemat ⚠️'),
                          style: AppText.titleMedium(
                            color: healthScore >= 80 ? AppColors.tradingUp : (healthScore >= 50 ? AppColors.primary : AppColors.tradingDown),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Berdasarkan rasio arus kas, tabungan, dan kedisiplinan pengeluaran.',
                          style: AppText.caption(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Bar Chart Hari Dalam Seminggu
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pola Pengeluaran Mingguan', style: AppText.titleMedium()),
                  const SizedBox(height: 4),
                  Text('Hari apa kamu paling banyak mengeluarkan uang?', style: AppText.caption()),
                  const SizedBox(height: 20),

                  SizedBox(
                    height: 160,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: (maxDayAmount > 0 ? maxDayAmount * 1.25 : 100),
                        barTouchData: BarTouchData(
                          touchTooltipData: BarTouchTooltipData(
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${dayNames[group.x + 1]}\n${AppFormatters.compactRupiah(rod.toY)}',
                                AppText.caption(color: Colors.white),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (val, _) {
                                final idx = val.toInt() + 1;
                                final labels = {1: 'Sen', 2: 'Sel', 3: 'Rab', 4: 'Kam', 5: 'Jum', 6: 'Sab', 7: 'Min'};
                                return Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    labels[idx] ?? '',
                                    style: AppText.caption(
                                      color: idx == maxDay ? AppColors.primary : AppColors.muted,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(7, (i) {
                          final day = i + 1;
                          final amount = dayOfWeekSums[day] ?? 0;
                          final isMax = day == maxDay && amount > 0;
                          return BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: amount,
                                color: isMax ? AppColors.primary : AppColors.surfaceElevated,
                                width: 14,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Grafik Balok Breakdown Pengeluaran per Kategori
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Pengeluaran per Kategori', style: AppText.titleMedium()),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${sortedCategorySums.length} Kategori', style: AppText.caption(color: AppColors.primary)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Perbandingan total uang keluar berdasarkan jenis keperluan', style: AppText.caption()),
                  const SizedBox(height: 20),

                  if (sortedCategorySums.isEmpty)
                    Container(
                      height: 120,
                      alignment: Alignment.center,
                      child: Text('Belum ada data pengeluaran di periode ini.', style: AppText.bodySm()),
                    )
                  else ...[
                    SizedBox(
                      height: 180,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: (sortedCategorySums.first.value * 1.25),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final entry = sortedCategorySums[group.x];
                                return BarTooltipItem(
                                  '${entry.key}\n${AppFormatters.rupiah(rod.toY)}',
                                  AppText.caption(color: Colors.white),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, _) {
                                  final idx = val.toInt();
                                  if (idx >= 0 && idx < sortedCategorySums.length) {
                                    final catName = sortedCategorySums[idx].key;
                                    final shortName = catName.length > 7 ? '${catName.substring(0, 6)}..' : catName;
                                    final cat = getCategoryInfo(catName);
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Text(
                                        shortName,
                                        style: AppText.caption(color: cat?.color ?? AppColors.muted),
                                      ),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                          ),
                          gridData: const FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          barGroups: sortedCategorySums.take(6).toList().asMap().entries.map((item) {
                            final idx = item.key;
                            final entry = item.value;
                            final cat = getCategoryInfo(entry.key);
                            return BarChartGroupData(
                              x: idx,
                              barRods: [
                                BarChartRodData(
                                  toY: entry.value,
                                  color: cat?.color ?? AppColors.primary,
                                  width: 16,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.hairlineDark),
                    const SizedBox(height: 12),
                    // Legend / Breakdown per kategori
                    ...sortedCategorySums.take(5).map((entry) {
                      final cat = getCategoryInfo(entry.key);
                      final percent = totalExpense > 0 ? (entry.value / totalExpense) * 100 : 0.0;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: cat?.color ?? AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(entry.key, style: AppText.caption(color: AppColors.body)),
                            ),
                            Text(
                              '${AppFormatters.compactRupiah(entry.value)} (${percent.toStringAsFixed(0)}%)',
                              style: AppText.numSm(color: AppColors.mutedStrong),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Automatic Insights Cards
            Text('Wawasan & Saran Riset', style: AppText.titleMedium()),
            const SizedBox(height: 10),

            ...insights.map((ins) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.hairlineDark),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (ins['color'] as Color).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(ins['icon'] as IconData, size: 20, color: ins['color'] as Color),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ins['title'] as String, style: AppText.titleSm()),
                          const SizedBox(height: 4),
                          Text(ins['desc'] as String, style: AppText.caption(color: AppColors.body)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodTab(String label, int months) {
    final isSelected = _selectedPeriodMonths == months;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriodMonths = months),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surfaceElevated : AppColors.surfaceCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.hairlineDark,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: AppText.caption(
                color: isSelected ? AppColors.primary : AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
