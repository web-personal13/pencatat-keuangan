import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/storage_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set Android / iOS status bar style to match dark Binance canvas
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1E2329),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Indonesian locale for dates and currencies
  await initializeDateFormatting('id_ID', null);

  // Initialize local persistent storage
  final storageService = StorageService();
  await storageService.init();

  runApp(DompiApp(storage: storageService));
}