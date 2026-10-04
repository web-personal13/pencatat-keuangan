import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/categories.dart';
import '../core/formatters.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../widgets/add_transaction_sheet.dart';

class HomeScreen extends StatelessWidget {
  final StorageService storage;
  final Function(int) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.storage,
    required this.onNavigateToTab,
  });

  void _showSettingsModal(BuildContext context) {
    final nameController = TextEditingController(text: storage.userName);
    final budgetController = TextEditingController(
      text: storage.monthlyBudget > 0
          ? NumberFormat('#,##0', 'id_ID').format(storage.monthlyBudget.toInt())
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 16,
        ),
        child: SingleChildScrollView(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.settings, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text('Pengaturan Dompi', style: AppText.titleLg()),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.muted),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                style: AppText.bodyMd(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'Nama Panggilan',
                  hintText: 'Masukkan nama sapaan Anda',
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                style: AppText.numLg(color: AppColors.primary),
                decoration: const InputDecoration(
                  labelText: 'Target Budget Bulanan (Rp)',
                  hintText: '0',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  final newName = nameController.text.trim();
                  final newBudget = double.tryParse(budgetController.text.replaceAll('.', '').trim()) ?? 0.0;
                  if (newName.isNotEmpty) {
                    storage.updateProfile(name: newName, budget: newBudget);
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pengaturan berhasil disimpan!')),
                    );
                  }
                },
                child: Text('SIMPAN PENGATURAN', style: AppText.button()),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _showTransactionDetail(BuildContext context, Transaction item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.hairlineDark,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: Icon(
                  item.isExpense ? Icons.arrow_downward : Icons.arrow_upward,
                  color: item.isExpense ? AppColors.tradingDown : AppColors.tradingUp,
                ),
                title: Text(item.title, style: AppText.titleMedium()),
                subtitle: Text(
                  '${item.category} • ${AppFormatters.dateFull(item.date)}',
                  style: AppText.caption(),
                ),
                trailing: Text(
                  '${item.isExpense ? '-' : '+'} ${AppFormatters.rupiah(item.amount)}',
                  style: AppText.numLg(
                    color: item.isExpense ? AppColors.tradingDown : AppColors.tradingUp,
                  ),
                ),
              ),
              if (item.barcode != null && item.barcode!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 4, bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.qr_code, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Barcode: ${item.barcode}', style: AppText.caption(color: AppColors.primary)),
                    ],
                  ),
                ),
              const Divider(color: AppColors.hairlineDark, height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.hairlineDark),
                        foregroundColor: AppColors.body,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.edit, size: 18, color: AppColors.primary),
                      label: const Text('Edit'),
                      onPressed: () {
                        Navigator.pop(ctx);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: AppColors.surfaceCard,
                          builder: (_) => AddTransactionSheet(
                            storage: storage,
                            existingTransaction: item,
                            onSave: (updated) => storage.updateTransaction(updated),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.tradingDown.withOpacity(0.15),
                        foregroundColor: AppColors.tradingDown,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus'),
                      onPressed: () {
                        storage.deleteTransaction(item.id);
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transaksi berhasil dihapus')),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final totalExpense = storage.totalExpense(forMonth: now);
    final totalIncome = storage.totalIncome(forMonth: now);
    final netBalance = totalIncome - totalExpense;
    final budget = storage.monthlyBudget;
    final remainingBudget = budget - totalExpense;
    final budgetPercent = budget > 0 ? (totalExpense / budget).clamp(0.0, 1.0) : 0.0;

    // Greeting logic
    final hour = now.hour;
    String greetingTime = 'Selamat Pagi';
    if (hour >= 12 && hour < 15) {
      greetingTime = 'Selamat Siang';
    } else if (hour >= 15 && hour < 19) {
      greetingTime = 'Selamat Sore';
    } else if (hour >= 19 || hour < 4) {
      greetingTime = 'Selamat Malam';
    }

    final recentTransactions = storage.transactions.take(5).toList();

    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with greeting to user name
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _showSettingsModal(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '$greetingTime, ',
                              style: AppText.bodySm(color: AppColors.muted),
                            ),
                            Text(
                              storage.userName.isNotEmpty ? storage.userName : 'Kawan',
                              style: AppText.titleSm(color: AppColors.primary),
                            ),
                            const SizedBox(width: 6),
                            const Text('👋', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Dompi Wallet',
                          style: AppText.titleLg(color: AppColors.onDark),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      // Tombol Pengaturan (Setting)
                      IconButton(
                        onPressed: () => _showSettingsModal(context),
                        tooltip: 'Pengaturan Profil & Budget',
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.hairlineDark),
                          ),
                          child: const Icon(Icons.settings_outlined, color: AppColors.primary, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0),

              const SizedBox(height: 18),

              // 2. Main Saldo & Budget Card (Signature Binance Style)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E2329), Color(0xFF232830)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.hairlineDark),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saldo Bersih Bulan Ini', style: AppText.bodySm(color: AppColors.muted)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceElevated,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            DateFormat('MMM yyyy', 'id_ID').format(now),
                            style: AppText.caption(color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppFormatters.rupiah(netBalance),
                      style: AppText.numDisplay(
                        color: netBalance >= 0 ? AppColors.onDark : AppColors.tradingDown,
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Row Pemasukan & Pengeluaran
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.canvasDark.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.hairlineDark),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward, size: 14, color: AppColors.tradingUp),
                                    const SizedBox(width: 4),
                                    Text('Pemasukan', style: AppText.caption(color: AppColors.muted)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.rupiah(totalIncome),
                                  style: AppText.numSm(color: AppColors.tradingUp),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.canvasDark.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.hairlineDark),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_downward, size: 14, color: AppColors.tradingDown),
                                    const SizedBox(width: 4),
                                    Text('Pengeluaran', style: AppText.caption(color: AppColors.muted)),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppFormatters.rupiah(totalExpense),
                                  style: AppText.numSm(color: AppColors.tradingDown),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: AppColors.hairlineDark),
                    const SizedBox(height: 12),

                    // Budget Status & Progress Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          budget > 0 ? 'Target Budget: ${AppFormatters.rupiah(budget)}' : 'Budget Belum Diatur',
                          style: AppText.caption(color: AppColors.muted),
                        ),
                        if (budget > 0)
                          Text(
                            'Sisa: ${AppFormatters.rupiah(remainingBudget)}',
                            style: AppText.caption(
                              color: remainingBudget < 0 ? AppColors.tradingDown : AppColors.tradingUp,
                            ),
                          ),
                      ],
                    ),
                    if (budget > 0) ...[
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: budgetPercent,
                          minHeight: 6,
                          backgroundColor: AppColors.surfaceElevated,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            budgetPercent > 0.9
                                ? AppColors.tradingDown
                                : (budgetPercent > 0.75 ? AppColors.accentOrange : AppColors.primary),
                          ),
                        ),
                      ),
                      if (remainingBudget < 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.tradingDown),
                            const SizedBox(width: 4),
                            Text(
                              'Pengeluaran melebihi budget bulanan!',
                              style: AppText.caption(color: AppColors.tradingDown),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 20),

              // 3. Quick Stats Cards (4 compact cards)
              Text('Statistik Cepat', style: AppText.titleSm(color: AppColors.muted)),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final cardWidth = (constraints.maxWidth - 12) / 2;
                  return Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      // Hari Ini
                      _buildQuickStatTile(
                        width: cardWidth,
                        title: 'Hari Ini',
                        amount: storage.transactions
                            .where((t) => t.isExpense && t.date.year == now.year && t.date.month == now.month && t.date.day == now.day)
                            .fold(0.0, (s, t) => s + t.amount),
                        icon: Icons.today,
                        color: AppColors.accentBlue,
                      ),
                      // Minggu Ini
                      _buildQuickStatTile(
                        width: cardWidth,
                        title: 'Minggu Ini',
                        amount: storage.transactions
                            .where((t) => t.isExpense && t.date.isAfter(now.subtract(Duration(days: now.weekday))))
                            .fold(0.0, (s, t) => s + t.amount),
                        icon: Icons.date_range,
                        color: AppColors.accentOrange,
                      ),
                    ],
                  );
                },
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 24),

              // 4. Transaksi Terbaru Header & List
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaksi Terakhir', style: AppText.titleMedium()),
                  TextButton(
                    onPressed: () => onNavigateToTab(1), // Jump to tab Transaksi
                    child: Row(
                      children: [
                        Text('Lihat Semua', style: AppText.caption(color: AppColors.primary)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (recentTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.hairlineDark),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.receipt_long_outlined, size: 40, color: AppColors.muted),
                      const SizedBox(height: 12),
                      Text('Belum Ada Transaksi', style: AppText.titleSm(color: AppColors.body)),
                      const SizedBox(height: 4),
                      Text(
                        'Tap tombol kuning (+) di bawah untuk mulai mencatat keuanganmu.',
                        textAlign: TextAlign.center,
                        style: AppText.caption(),
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recentTransactions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = recentTransactions[index];
                    final cat = getCategoryInfo(item.category);
                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.hairlineDark),
                      ),
                      child: ListTile(
                        onTap: () => _showTransactionDetail(context, item),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (cat?.color ?? AppColors.muted).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            cat?.icon ?? Icons.category,
                            color: cat?.color ?? AppColors.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.titleSm(),
                        ),
                        subtitle: Text(
                          '${item.category} • ${AppFormatters.timeShort(item.date)}',
                          style: AppText.caption(),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${item.isExpense ? '-' : '+'} ${AppFormatters.rupiah(item.amount)}',
                              style: AppText.numMd(
                                color: item.isExpense ? AppColors.tradingDown : AppColors.tradingUp,
                              ),
                            ),
                            if (item.barcode != null)
                              const Icon(Icons.qr_code, size: 12, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  },
                ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 60), // Room for FAB
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickStatTile({
    required double width,
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.hairlineDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.caption()),
                const SizedBox(height: 2),
                Text(
                  AppFormatters.compactRupiah(amount),
                  style: AppText.numMd(color: AppColors.onDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
