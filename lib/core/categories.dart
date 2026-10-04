import 'package:flutter/material.dart';
import '../models/transaction.dart';
import 'theme.dart';

// ─── Category Info ─────────────────────────────────────────────────────────────
class CategoryInfo {
  final String name;
  final IconData icon;
  final Color color;
  final TransactionType type;

  const CategoryInfo({
    required this.name,
    required this.icon,
    required this.color,
    required this.type,
  });
}

// ─── Category Definitions ─────────────────────────────────────────────────────
const List<CategoryInfo> expenseCategories = [
  CategoryInfo(name: 'Makanan & Minuman',   icon: Icons.restaurant,       color: AppColors.tradingDown,    type: TransactionType.expense),
  CategoryInfo(name: 'Transport',           icon: Icons.directions_car,   color: AppColors.accentBlue,     type: TransactionType.expense),
  CategoryInfo(name: 'Belanja & Keperluan', icon: Icons.shopping_cart,    color: AppColors.accentPurple,   type: TransactionType.expense),
  CategoryInfo(name: 'Hiburan & Healing',   icon: Icons.sports_esports,   color: AppColors.accentOrange,   type: TransactionType.expense),
  CategoryInfo(name: 'Rokok',               icon: Icons.smoking_rooms,    color: AppColors.accentGray,     type: TransactionType.expense),
  CategoryInfo(name: 'Tagihan & Utilities', icon: Icons.electric_bolt,    color: AppColors.tradingUp,      type: TransactionType.expense),
  CategoryInfo(name: 'Kesehatan',           icon: Icons.local_hospital,   color: AppColors.accentTurquoise,type: TransactionType.expense),
  CategoryInfo(name: 'Lainnya',             icon: Icons.category,         color: AppColors.muted,          type: TransactionType.expense),
];

const List<CategoryInfo> incomeCategories = [
  CategoryInfo(name: 'Gaji / Upah',    icon: Icons.work,           color: AppColors.tradingUp,     type: TransactionType.income),
  CategoryInfo(name: 'Freelance',      icon: Icons.laptop_mac,     color: AppColors.accentBlue,    type: TransactionType.income),
  CategoryInfo(name: 'Bisnis',         icon: Icons.storefront,     color: AppColors.primary,       type: TransactionType.income),
  CategoryInfo(name: 'Transfer Masuk', icon: Icons.send_to_mobile, color: AppColors.accentPurple,  type: TransactionType.income),
  CategoryInfo(name: 'Lainnya',        icon: Icons.inbox,          color: AppColors.muted,         type: TransactionType.income),
];

// ─── Old → New category migration ────────────────────────────────────────────
const Map<String, String> categoryMigration = {
  'Makanan':  'Makanan & Minuman',
  'Belanja':  'Belanja & Keperluan',
  'Hiburan':  'Hiburan & Healing',
  'Tagihan':  'Tagihan & Utilities',
};

// ─── Helpers ─────────────────────────────────────────────────────────────────
CategoryInfo? getCategoryInfo(String name) {
  final all = [...expenseCategories, ...incomeCategories];
  try {
    return all.firstWhere((c) => c.name == name);
  } catch (_) {
    return null;
  }
}

IconData categoryIcon(String name) =>
    getCategoryInfo(name)?.icon ?? Icons.category;

Color categoryColor(String name) =>
    getCategoryInfo(name)?.color ?? AppColors.muted;

List<CategoryInfo> categoriesByType(TransactionType type) =>
    type == TransactionType.expense ? expenseCategories : incomeCategories;

String migrateCategory(String old) =>
    categoryMigration[old] ?? old;

