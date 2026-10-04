import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'services/storage_service.dart';
import 'screens/onboarding_screen.dart';
import 'navigator.dart';

class DompiApp extends StatelessWidget {
  final StorageService storage;

  const DompiApp({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Dompi',
          theme: AppTheme.dark(),
          home: storage.hasUserConfiguredName
              ? MainNavigator(storage: storage)
              : OnboardingScreen(
                  storage: storage,
                  onCompleted: () {},
                ),
        );
      },
    );
  }
}

