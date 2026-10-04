import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../core/theme.dart';
import '../core/categories.dart';
import '../core/formatters.dart';
import '../models/transaction.dart';
import 'barcode_scanner_page.dart';

import '../services/barcode_lookup_service.dart';
import '../services/storage_service.dart';

class AddTransactionSheet extends StatefulWidget {
  final Transaction? existingTransaction;
  final StorageService? storage;
  final Function(Transaction) onSave;

  const AddTransactionSheet({
    super.key,
    this.existingTransaction,
    this.storage,
    required this.onSave,
  });

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  late TransactionType _type;
  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _noteController;
  late String _selectedCategory;
  late DateTime _transactionDate;
  String? _scannedBarcode;
  bool _isLoadingProduct = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingTransaction;
    if (existing != null) {
      _type = existing.type;
      _titleController = TextEditingController(text: existing.title);
      _amountController = TextEditingController(
        text: NumberFormat('#,##0', 'id_ID').format(existing.amount.toInt()),
      );
      _noteController = TextEditingController(text: existing.note ?? '');
      _selectedCategory = existing.category;
      _transactionDate = existing.date;
      _scannedBarcode = existing.barcode;
    } else {
      _type = TransactionType.expense;
      _titleController = TextEditingController();
      _amountController = TextEditingController();
      _noteController = TextEditingController();
      _selectedCategory = expenseCategories.first.name;
      _transactionDate = DateTime.now(); // Tanggal & waktu otomatis tanpa setting manual!
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _onTypeChanged(TransactionType newType) {
    if (_type == newType) return;
    setState(() {
      _type = newType;
      final available = categoriesByType(newType);
      _selectedCategory = available.first.name;
    });
  }

  Future<void> _scanBarcode() async {
    final result = await Navigator.push<ScannerResult>(
      context,
      MaterialPageRoute(builder: (context) => const BarcodeScannerPage()),
    );

    if (result == null) return;

    // ─── KASUS 1: Hasil Scan Barcode Produk ─────────────────────────────────
    if (result.barcode != null && result.barcode!.isNotEmpty) {
      final code = result.barcode!;
      setState(() {
        _scannedBarcode = code;
        _isLoadingProduct = true;
      });

      // Auto-lookup nama produk
      final lookupResult = await BarcodeLookupService.lookup(code, storage: widget.storage);

      if (mounted) {
        setState(() {
          _isLoadingProduct = false;
          if (lookupResult != null && lookupResult.productName.isNotEmpty) {
            _titleController.text = lookupResult.productName;
            // Auto select matching category if found
            if (lookupResult.suggestedCategory != null) {
              final available = categoriesByType(_type);
              if (available.any((c) => c.name == lookupResult.suggestedCategory)) {
                _selectedCategory = lookupResult.suggestedCategory!;
              }
            }
          }
        });

        if (lookupResult != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(lookupResult.isCustomLearned
                  ? '✨ Produk "${lookupResult.productName}" dikenali dari riwayat Anda! Silakan isi harga.'
                  : '✅ Produk "${lookupResult.productName}" terdeteksi! Silakan isi harga.'),
              backgroundColor: AppColors.primaryActive,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ Produk belum terdaftar di database. Silakan ketik nama produk, aplikasi akan otomatis mengingatnya untuk scan berikutnya!'),
              backgroundColor: AppColors.tradingDown,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    }

    // ─── KASUS 2: Hasil Scan Struk / Tarik Tunai (OCR Cerdas) ────────────────
    else if (result.receipt != null) {
      final receipt = result.receipt!;
      setState(() {
        if (receipt.amount > 0) {
          _amountController.text = AppFormatters.rupiah(receipt.amount, showPrefix: false);
        }
        _titleController.text = receipt.title;
        _type = receipt.isExpense ? TransactionType.expense : TransactionType.income;

        final available = categoriesByType(_type);
        if (available.any((c) => c.name == receipt.category)) {
          _selectedCategory = receipt.category;
        } else {
          _selectedCategory = available.first.name;
        }

        if (receipt.date != null) {
          _transactionDate = receipt.date!;
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            receipt.amount > 0
                ? '🧾 Struk terbaca: ${receipt.title} (Rp ${AppFormatters.compactRupiah(receipt.amount)}). Periksa lalu tekan Simpan.'
                : '🧾 Struk terbaca: ${receipt.title}. Silakan masukkan nominalnya.',
          ),
          backgroundColor: AppColors.tradingUp,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleSave() {
    final title = _titleController.text.trim();
    final amountStr = _amountController.text.replaceAll('.', '').trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keterangan tidak boleh kosong!')),
      );
      return;
    }

    final amount = double.tryParse(amountStr);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan nominal harga yang valid!')),
      );
      return;
    }

    final tx = Transaction(
      id: widget.existingTransaction?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      amount: amount,
      category: _selectedCategory,
      date: _transactionDate,
      type: _type,
      barcode: _scannedBarcode,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    // Auto-learn barcode jika transaksi ini memiliki barcode
    if (_scannedBarcode != null && widget.storage != null) {
      widget.storage!.saveCustomBarcode(_scannedBarcode!, title, _selectedCategory);
    }

    widget.onSave(tx);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingTransaction != null;
    final availableCategories = categoriesByType(_type);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 16,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
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

            // Header Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEdit ? 'Edit Transaksi' : 'Catat Transaksi',
                  style: AppText.titleLg(),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Toggle Tipe: Pengeluaran vs Pemasukan
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.expense),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.expense ? AppColors.tradingDown : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 16,
                              color: _type == TransactionType.expense ? Colors.white : AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pengeluaran',
                              style: AppText.titleSm(
                                color: _type == TransactionType.expense ? Colors.white : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _onTypeChanged(TransactionType.income),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _type == TransactionType.income ? AppColors.tradingUp : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              size: 16,
                              color: _type == TransactionType.income ? Colors.white : AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Pemasukan',
                              style: AppText.titleSm(
                                color: _type == TransactionType.income ? Colors.white : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Keterangan + Tombol Scan Barcode
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _titleController,
                    style: AppText.bodyMd(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Keterangan',
                      hintText: 'Contoh: Nasi Goreng, Rokok Surya, dsb',
                      prefixIcon: const Icon(Icons.edit_note, color: AppColors.muted),
                      suffixIcon: _isLoadingProduct
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                            )
                          : (_scannedBarcode != null
                              ? const Tooltip(
                                  message: 'Dari Barcode',
                                  child: Icon(Icons.qr_code, color: AppColors.primary, size: 20),
                                )
                              : null),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Tombol Scan Barcode
                Tooltip(
                  message: 'Scan Barcode Produk',
                  child: InkWell(
                    onTap: _scanBarcode,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.primary, width: 1.2),
                      ),
                      child: const Icon(Icons.qr_code_scanner, color: AppColors.primary, size: 26),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Nominal Uang (Auto Titik Format)
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                CurrencyInputFormatter(),
              ],
              style: AppText.numLg(
                color: _type == TransactionType.expense ? AppColors.tradingDown : AppColors.tradingUp,
              ),
              decoration: InputDecoration(
                labelText: 'Jumlah Nominal (Rp)',
                hintText: '0',
                prefixIcon: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  child: Text(
                    'Rp',
                    style: AppText.numLg(color: AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Dropdown Kategori
            DropdownButtonFormField<String>(
              dropdownColor: AppColors.surfaceElevated,
              value: availableCategories.any((c) => c.name == _selectedCategory)
                  ? _selectedCategory
                  : availableCategories.first.name,
              items: availableCategories.map((c) {
                return DropdownMenuItem<String>(
                  value: c.name,
                  child: Row(
                    children: [
                      Icon(c.icon, size: 18, color: c.color),
                      const SizedBox(width: 10),
                      Text(c.name, style: AppText.bodyMd(color: Colors.white)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedCategory = val);
              },
              decoration: const InputDecoration(
                labelText: 'Kategori',
                prefixIcon: Icon(Icons.category_outlined, color: AppColors.muted),
              ),
            ),
            const SizedBox(height: 14),

            // Info Tanggal & Jam Otomatis (Tanpa Perlu Disetting Manual)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: Row(
                children: [
                  const Icon(Icons.access_time_filled, color: AppColors.primary, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Waktu otomatis: ${AppFormatters.dateFull(_transactionDate)}',
                      style: AppText.caption(color: AppColors.body),
                    ),
                  ),
                  const Icon(Icons.check_circle_outline, color: AppColors.tradingUp, size: 14),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Simpan (Binance Button Signature)
            ElevatedButton(
              onPressed: _handleSave,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text(
                isEdit ? 'PERBARUI TRANSAKSI' : 'SIMPAN TRANSAKSI',
                style: AppText.button(color: AppColors.onPrimary),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

