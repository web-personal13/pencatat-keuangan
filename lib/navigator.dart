import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'services/storage_service.dart';
import 'services/excel_service.dart';
import 'screens/home_screen.dart';
import 'screens/transactions_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/research_screen.dart';
import 'screens/assistant_screen.dart';
import 'widgets/add_transaction_sheet.dart';

class MainNavigator extends StatefulWidget {
  final StorageService storage;

  const MainNavigator({super.key, required this.storage});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  void _onNavigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _exportExcel() {
    ExcelExportService.exportTransactions(
      context: context,
      transactions: widget.storage.transactions,
      monthlyBudget: widget.storage.monthlyBudget,
    );
  }

  void _openAddTransactionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => AddTransactionSheet(
        storage: widget.storage,
        onSave: (newTx) => widget.storage.addTransaction(newTx),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(
        storage: widget.storage,
        onNavigateToTab: _onNavigateToTab,
      ),
      TransactionsScreen(storage: widget.storage),
      ReportsScreen(storage: widget.storage, onExportExcel: _exportExcel),
      ResearchScreen(storage: widget.storage),
      AssistantScreen(storage: widget.storage),
    ];

    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),

      // Tombol Tambah (+) hanya muncul di Halaman Transaksi (Tab index 1)
      floatingActionButton: _currentIndex == 1
          ? FloatingActionButton(
              onPressed: _openAddTransactionSheet,
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: const Icon(Icons.add, size: 28, color: AppColors.ink),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      // Binance-style 5-Destination Navigation Bar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        backgroundColor: AppColors.surfaceCard,
        indicatorColor: AppColors.surfaceElevated,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.home, color: AppColors.primary),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Transaksi',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline, color: AppColors.muted),
            selectedIcon: Icon(Icons.pie_chart, color: AppColors.primary),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.insights, color: AppColors.primary),
            label: 'Riset',
          ),
          NavigationDestination(
            icon: Icon(Icons.smart_toy_outlined, color: AppColors.muted),
            selectedIcon: Icon(Icons.smart_toy, color: AppColors.primary),
            label: 'Asisten AI',
          ),
        ],
      ),
    );
  }
}

