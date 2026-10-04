import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/categories.dart';
import '../core/formatters.dart';
import '../models/transaction.dart';
import '../services/storage_service.dart';
import '../widgets/add_transaction_sheet.dart';

class TransactionsScreen extends StatefulWidget {
  final StorageService storage;

  const TransactionsScreen({super.key, required this.storage});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  TransactionType? _typeFilter; // null = all, expense, income
  DateTime? _monthFilter = DateTime(DateTime.now().year, DateTime.now().month); // default current month, null for all

  List<DateTime> _getAvailableMonths() {
    return widget.storage.getAvailableMonths();
  }

  void _showMonthPicker() {
    final availableMonths = _getAvailableMonths();

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
            Text('Pilih Bulan Transaksi', style: AppText.titleLg()),
            const SizedBox(height: 6),
            Text(
              'Hanya menampilkan bulan yang memiliki data riil & bulan berjalan.',
              style: AppText.caption(),
            ),
            const SizedBox(height: 16),
            // Opsi: Semua Waktu
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: _monthFilter == null ? AppColors.surfaceElevated : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _monthFilter == null ? AppColors.primary : AppColors.hairlineDark,
                ),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.all_inbox,
                  color: _monthFilter == null ? AppColors.primary : AppColors.muted,
                ),
                title: Text('Semua Waktu', style: AppText.titleSm()),
                subtitle: Text('Tampilkan seluruh riwayat transaksi', style: AppText.caption()),
                trailing: _monthFilter == null
                    ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                    : null,
                onTap: () {
                  setState(() => _monthFilter = null);
                  Navigator.pop(ctx);
                },
              ),
            ),
            // Daftar Bulan yang Ada Datanya
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: availableMonths.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final monthDate = availableMonths[index];
                  final isSelected = _monthFilter != null &&
                      _monthFilter!.year == monthDate.year &&
                      _monthFilter!.month == monthDate.month;
                  final count = widget.storage.transactions.where((t) =>
                      t.date.year == monthDate.year && t.date.month == monthDate.month).length;

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
                      subtitle: Text('$count Transaksi', style: AppText.caption()),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _monthFilter = monthDate);
                        Navigator.pop(ctx);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showTransactionActions(Transaction item) {
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
              if (item.barcode != null)
                Padding(
                  padding: const EdgeInsets.only(left: 16, bottom: 8),
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
                            storage: widget.storage,
                            existingTransaction: item,
                            onSave: (updated) => widget.storage.updateTransaction(updated),
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
                        widget.storage.deleteTransaction(item.id);
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
    // Filter transactions
    var filtered = widget.storage.transactions.where((t) {
      if (_monthFilter != null && (t.date.year != _monthFilter!.year || t.date.month != _monthFilter!.month)) {
        return false;
      }
      if (_typeFilter != null && t.type != _typeFilter) return false;
      if (_selectedCategory != null && t.category != _selectedCategory) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final inTitle = t.title.toLowerCase().contains(q);
        final inCategory = t.category.toLowerCase().contains(q);
        final inBarcode = t.barcode?.toLowerCase().contains(q) ?? false;
        if (!inTitle && !inCategory && !inBarcode) return false;
      }
      return true;
    }).toList();

    // Grouping by date string
    final Map<String, List<Transaction>> grouped = {};
    for (var tx in filtered) {
      final dateKey = AppFormatters.dateShort(tx.date);
      grouped.putIfAbsent(dateKey, () => []).add(tx);
    }

    // Calculate sum of filtered
    final totalFilteredExpense = filtered.where((t) => t.isExpense).fold(0.0, (s, t) => s + t.amount);
    final totalFilteredIncome = filtered.where((t) => t.isIncome).fold(0.0, (s, t) => s + t.amount);

    // Kategori dinamis sesuai pilihan tipe (Pengeluaran / Pemasukan / Semua)
    final activeCategories = _typeFilter == TransactionType.income
        ? incomeCategories
        : (_typeFilter == TransactionType.expense
            ? expenseCategories
            : [...expenseCategories, ...incomeCategories]);

    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      appBar: AppBar(
        title: Text('Daftar Transaksi', style: AppText.titleLg()),
        backgroundColor: AppColors.canvasDark,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: AppText.bodyMd(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari transaksi, toko, produk...',
                prefixIcon: const Icon(Icons.search, color: AppColors.muted),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.muted, size: 18),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
            ),
          ),

          // 2. Filter Bulan (Pilih Bulan Tertentu vs Semua)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showMonthPicker,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceCard,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _monthFilter != null ? AppColors.primary : AppColors.hairlineDark,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_month,
                            size: 16,
                            color: _monthFilter != null ? AppColors.primary : AppColors.muted,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _monthFilter != null
                                  ? 'Bulan: ${DateFormat('MMMM yyyy', 'id_ID').format(_monthFilter!)}'
                                  : 'Periode: Semua Waktu',
                              style: AppText.caption(
                                color: _monthFilter != null ? AppColors.onDark : AppColors.muted,
                              ),
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_monthFilter != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => setState(() => _monthFilter = null),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.hairlineDark),
                      ),
                      child: Text('Semua', style: AppText.caption(color: AppColors.primary)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 3. Type Filter Tabs (Semua / Keluar / Masuk)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildTypeFilterChip('Semua', null),
                const SizedBox(width: 8),
                _buildTypeFilterChip('Pengeluaran', TransactionType.expense),
                const SizedBox(width: 8),
                _buildTypeFilterChip('Pemasukan', TransactionType.income),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 4. Category Horizontal Chips (Otomatis ganti sesuai tipe Pengeluaran/Pemasukan)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Semua Kategori'),
                  selected: _selectedCategory == null,
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceCard,
                  labelStyle: AppText.caption(
                    color: _selectedCategory == null ? AppColors.onPrimary : AppColors.muted,
                  ),
                  side: const BorderSide(color: AppColors.hairlineDark),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  onSelected: (_) => setState(() => _selectedCategory = null),
                ),
                const SizedBox(width: 8),
                ...activeCategories.map((cat) {
                  final isSelected = _selectedCategory == cat.name;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      avatar: Icon(cat.icon, size: 14, color: isSelected ? AppColors.onPrimary : cat.color),
                      label: Text(cat.name),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surfaceCard,
                      labelStyle: AppText.caption(
                        color: isSelected ? AppColors.onPrimary : AppColors.body,
                      ),
                      side: const BorderSide(color: AppColors.hairlineDark),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (_) => setState(() {
                        _selectedCategory = isSelected ? null : cat.name;
                      }),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Filter Summary Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filtered.length} Transaksi ditemukan',
                  style: AppText.caption(color: AppColors.muted),
                ),
                Row(
                  children: [
                    if (totalFilteredIncome > 0) ...[
                      Text(
                        '+ ${AppFormatters.compactRupiah(totalFilteredIncome)}',
                        style: AppText.caption(color: AppColors.tradingUp),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (totalFilteredExpense > 0)
                      Text(
                        '- ${AppFormatters.compactRupiah(totalFilteredExpense)}',
                        style: AppText.caption(color: AppColors.tradingDown),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColors.hairlineDark),

          // 4. Grouped Transactions List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: AppColors.muted),
                        const SizedBox(height: 12),
                        Text('Tidak ada transaksi yang cocok', style: AppText.titleSm(color: AppColors.muted)),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, gIndex) {
                      final dateKey = grouped.keys.elementAt(gIndex);
                      final items = grouped[dateKey]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              dateKey,
                              style: AppText.caption(color: AppColors.mutedStrong),
                            ),
                          ),
                          ...items.map((item) {
                            final cat = getCategoryInfo(item.category);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceCard,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.hairlineDark),
                              ),
                              child: ListTile(
                                onTap: () => _showTransactionActions(item),
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
                                  style: AppText.titleSm(),
                                ),
                                subtitle: Text(
                                  '${item.category} • ${AppFormatters.timeShort(item.date)}',
                                  style: AppText.caption(),
                                ),
                                trailing: Text(
                                  '${item.isExpense ? '-' : '+'} ${AppFormatters.rupiah(item.amount)}',
                                  style: AppText.numMd(
                                    color: item.isExpense ? AppColors.tradingDown : AppColors.tradingUp,
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeFilterChip(String label, TransactionType? type) {
    final isSelected = _typeFilter == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _typeFilter = type;
            // Jika kategori yang sedang aktif tidak ada di daftar tipe baru, reset ke Semua Kategori
            if (_selectedCategory != null) {
              final newCategories = type == TransactionType.income
                  ? incomeCategories
                  : (type == TransactionType.expense
                      ? expenseCategories
                      : [...expenseCategories, ...incomeCategories]);
              if (!newCategories.any((c) => c.name == _selectedCategory)) {
                _selectedCategory = null;
              }
            }
          });
        },
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
