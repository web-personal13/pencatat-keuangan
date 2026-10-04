import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/storage_service.dart';

class OnboardingScreen extends StatefulWidget {
  final StorageService storage;
  final VoidCallback onCompleted;

  const OnboardingScreen({
    super.key,
    required this.storage,
    required this.onCompleted,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final TextEditingController _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan masukkan nama atau panggilan Anda.')),
      );
      return;
    }
    widget.storage.setUserName(name);
    widget.onCompleted();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvasDark,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / Brand Icon
              Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_balance_wallet,
                        color: AppColors.primary,
                        size: 45,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Selamat Datang di Dompi!',
                textAlign: TextAlign.center,
                style: AppText.displayMd(color: AppColors.primary),
              ),
              const SizedBox(height: 8),

              Text(
                'Pencatat keuangan harian pintar, rapi, dan transparan.',
                textAlign: TextAlign.center,
                style: AppText.bodyMd(color: AppColors.muted),
              ),
              const SizedBox(height: 36),

              // Input Nama
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
                    Text(
                      'Siapa nama / panggilan Anda?',
                      style: AppText.titleSm(),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Dompi akan menyapa Anda secara personal setiap kali membuka aplikasi.',
                      style: AppText.caption(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.words,
                      style: AppText.bodyMd(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Contoh: Alex, Budi, Rian',
                        prefixIcon: Icon(Icons.person_outline, color: AppColors.primary),
                      ),
                      onSubmitted: (_) => _handleSubmit(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Tombol Mulai
              ElevatedButton(
                onPressed: _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Mulai Sekarang', style: AppText.button()),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, size: 18, color: AppColors.onPrimary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

