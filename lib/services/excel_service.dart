import 'dart:io';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart' as excel_lib;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../core/formatters.dart';

class ExcelExportService {
  static Future<void> exportTransactions({
    required BuildContext context,
    required List<Transaction> transactions,
    required double monthlyBudget,
    String? periodLabel,
  }) async {
    if (transactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Belum ada data transaksi untuk diekspor!')),
      );
      return;
    }

    try {
      final excel = excel_lib.Excel.createExcel();
      const sheetName = 'Laporan Dompi';
      final sheet = excel[sheetName];
      excel.setDefaultSheet(sheetName);

      sheet.setColumnWidth(0, 26); // Tanggal & Waktu
      sheet.setColumnWidth(1, 14); // Tipe
      sheet.setColumnWidth(2, 34); // Keterangan
      sheet.setColumnWidth(3, 24); // Kategori
      sheet.setColumnWidth(4, 8);  // Rp
      sheet.setColumnWidth(5, 20); // Jumlah

      final border = excel_lib.Border(
        borderStyle: excel_lib.BorderStyle.Thin,
        borderColorHex: excel_lib.ExcelColor.fromHexString('#000000'),
      );

      final titleStyle = excel_lib.CellStyle(
        bold: true,
        fontSize: 16,
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('#FCD535'), // Binance Yellow
        fontColorHex: excel_lib.ExcelColor.fromHexString('#181A20'),
        horizontalAlign: excel_lib.HorizontalAlign.Center,
        verticalAlign: excel_lib.VerticalAlign.Center,
        leftBorder: border, rightBorder: border, topBorder: border, bottomBorder: border,
      );

      final headerStyle = excel_lib.CellStyle(
        bold: true,
        backgroundColorHex: excel_lib.ExcelColor.fromHexString('#1E2329'),
        fontColorHex: excel_lib.ExcelColor.fromHexString('#FFFFFF'),
        horizontalAlign: excel_lib.HorizontalAlign.Center,
        verticalAlign: excel_lib.VerticalAlign.Center,
        leftBorder: border, rightBorder: border, topBorder: border, bottomBorder: border,
      );

      final leftStyle = excel_lib.CellStyle(
        leftBorder: border, rightBorder: border, topBorder: border, bottomBorder: border,
        horizontalAlign: excel_lib.HorizontalAlign.Left,
      );

      final centerStyle = excel_lib.CellStyle(
        leftBorder: border, rightBorder: border, topBorder: border, bottomBorder: border,
        horizontalAlign: excel_lib.HorizontalAlign.Center,
      );

      final rightStyle = excel_lib.CellStyle(
        leftBorder: border, rightBorder: border, topBorder: border, bottomBorder: border,
        horizontalAlign: excel_lib.HorizontalAlign.Right,
      );

      final boldRightStyle = excel_lib.CellStyle(
        bold: true,
        leftBorder: border, rightBorder: border, topBorder: border, bottomBorder: border,
        horizontalAlign: excel_lib.HorizontalAlign.Right,
      );

      // Title Banner
      sheet.merge(
        excel_lib.CellIndex.indexByString("A1"),
        excel_lib.CellIndex.indexByString("F2"),
      );

      for (int r = 0; r < 2; r++) {
        for (int c = 0; c < 6; c++) {
          sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: r)).cellStyle = titleStyle;
        }
      }

      final titleCell = sheet.cell(excel_lib.CellIndex.indexByString("A1"));
      titleCell.value = excel_lib.TextCellValue(
        periodLabel != null && periodLabel.isNotEmpty
            ? "LAPORAN KEUANGAN - DOMPI ($periodLabel)"
            : "LAPORAN KEUANGAN - DOMPI",
      );
      titleCell.cellStyle = titleStyle;

      int row = 3;

      // Budget Info
      if (monthlyBudget > 0) {
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).cellStyle = leftStyle;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).cellStyle = leftStyle;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).cellStyle = leftStyle;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = excel_lib.TextCellValue("Budget Bulanan :");
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).cellStyle = leftStyle;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = excel_lib.TextCellValue("Rp");
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).cellStyle = centerStyle;
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = excel_lib.TextCellValue(NumberFormat('#,##0', 'id_ID').format(monthlyBudget));
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).cellStyle = rightStyle;
        row++;
      }

      row++;

      // Table Headers
      final headers = ['Tanggal & Waktu', 'Tipe', 'Keterangan', 'Kategori', '', 'Jumlah (Rp)'];
      for (int i = 0; i < headers.length; i++) {
        final cell = sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: row));
        cell.value = excel_lib.TextCellValue(headers[i]);
        cell.cellStyle = headerStyle;
      }

      row++;

      double totalExpense = 0;
      double totalIncome = 0;

      for (final item in transactions) {
        if (item.isExpense) {
          totalExpense += item.amount;
        } else {
          totalIncome += item.amount;
        }

        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: row)).value = excel_lib.TextCellValue(AppFormatters.dateFull(item.date));
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: row)).value = excel_lib.TextCellValue(item.isExpense ? 'Pengeluaran' : 'Pemasukan');
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: row)).value = excel_lib.TextCellValue(item.title);
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = excel_lib.TextCellValue(item.category);
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = excel_lib.TextCellValue("Rp");
        sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = excel_lib.TextCellValue(NumberFormat('#,##0', 'id_ID').format(item.amount));

        for (int c = 0; c < 6; c++) {
          sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: c, rowIndex: row)).cellStyle =
              c == 5 ? rightStyle : (c == 4 || c == 1 ? centerStyle : leftStyle);
        }
        row++;
      }

      // Summary rows
      row++;
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = excel_lib.TextCellValue("Total Pemasukan:");
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).cellStyle = leftStyle;
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = excel_lib.TextCellValue("Rp");
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).cellStyle = centerStyle;
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = excel_lib.TextCellValue(NumberFormat('#,##0', 'id_ID').format(totalIncome));
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).cellStyle = boldRightStyle;

      row++;
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = excel_lib.TextCellValue("Total Pengeluaran:");
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).cellStyle = leftStyle;
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = excel_lib.TextCellValue("Rp");
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).cellStyle = centerStyle;
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = excel_lib.TextCellValue(NumberFormat('#,##0', 'id_ID').format(totalExpense));
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).cellStyle = boldRightStyle;

      row++;
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).value = excel_lib.TextCellValue("Saldo Bersih:");
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: row)).cellStyle = leftStyle;
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).value = excel_lib.TextCellValue("Rp");
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: row)).cellStyle = centerStyle;
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).value = excel_lib.TextCellValue(NumberFormat('#,##0', 'id_ID').format(totalIncome - totalExpense));
      sheet.cell(excel_lib.CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: row)).cellStyle = boldRightStyle;

      final bytes = excel.save();
      if (bytes == null) return;

      final tempDir = await getTemporaryDirectory();
      final dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final cleanPeriod = periodLabel != null ? '${periodLabel.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}_' : '';
      final filePath = "${tempDir.path}/Laporan_Dompi_$cleanPeriod$dateStr.xlsx";
      final file = File(filePath);

      await file.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(filePath, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        text: 'Laporan Keuangan Dompi - Ekspor Excel',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengekspor file: $e')),
        );
      }
    }
  }
}

