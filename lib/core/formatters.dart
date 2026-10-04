import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Keep only digits
    String digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    // Parse into integer or double
    int value = int.tryParse(digits) ?? 0;
    // Format Indonesian number with dot thousand separator
    String newText = NumberFormat('#,##0', 'id_ID').format(value);

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}

class AppFormatters {
  AppFormatters._();

  static String rupiah(double amount, {bool showPrefix = true}) {
    final formatted = NumberFormat('#,##0', 'id_ID').format(amount.abs());
    final sign = amount < 0 ? '- ' : '';
    final prefix = showPrefix ? 'Rp ' : '';
    return '$sign$prefix$formatted';
  }

  static String compactRupiah(double amount) {
    if (amount >= 1000000000) {
      return 'Rp ${(amount / 1000000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}jt';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(0)}rb';
    }
    return rupiah(amount);
  }

  static String dateFull(DateTime date) {
    return DateFormat('EEEE, dd MMM yyyy HH:mm', 'id_ID').format(date);
  }

  static String dateShort(DateTime date) {
    return DateFormat('dd MMM yyyy', 'id_ID').format(date);
  }

  static String timeShort(DateTime date) {
    return DateFormat('HH:mm', 'id_ID').format(date);
  }

  static String monthYear(DateTime date) {
    return DateFormat('MMMM yyyy', 'id_ID').format(date);
  }

  static String dayOfWeek(DateTime date) {
    return DateFormat('EEEE', 'id_ID').format(date);
  }
}

