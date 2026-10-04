import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme.dart';
import '../services/receipt_parser_service.dart';

class ScannerResult {
  final String? barcode;
  final ParsedReceiptResult? receipt;

  const ScannerResult.barcode(this.barcode) : receipt = null;
  const ScannerResult.receipt(this.receipt) : barcode = null;
}

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  int _selectedMode = 0; // 0 = Barcode Produk, 1 = Struk & Bukti
  bool _isScanned = false;
  bool _isTorchOn = false;
  bool _isProcessingOcr = false;

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  void _onBarcodeDetect(BarcodeCapture capture) {
    if (_isScanned || _selectedMode != 0) return;
    final barcode = capture.barcodes.firstOrNull?.rawValue;
    if (barcode != null && barcode.isNotEmpty) {
      _isScanned = true;
      Navigator.pop(context, ScannerResult.barcode(barcode));
    }
  }

  Future<void> _pickAndProcessReceipt(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: source,
        imageQuality: 90,
      );

      if (photo == null) return;

      setState(() => _isProcessingOcr = true);

      final inputImage = InputImage.fromFilePath(photo.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      await textRecognizer.close();

      if (!mounted) return;
      setState(() => _isProcessingOcr = false);

      if (recognizedText.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Teks pada foto tidak terbaca. Pastikan foto struk jelas dan terang.'),
            backgroundColor: AppColors.tradingDown,
          ),
        );
        return;
      }

      final parsed = ReceiptParserService.parse(recognizedText.text);

      if (parsed.amount <= 0 && parsed.title == 'Transaksi Struk') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nominal struk tidak terdeteksi otomatis. Silakan foto ulang lebih dekat.'),
            backgroundColor: AppColors.tradingDown,
          ),
        );
        return;
      }

      Navigator.pop(context, ScannerResult.receipt(parsed));
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessingOcr = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menganalisis foto struk: $e'),
            backgroundColor: AppColors.tradingDown,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          _selectedMode == 0 ? 'Scan Barcode Produk' : 'Scan Struk / Tarik Tunai',
          style: AppText.titleMedium(),
        ),
        actions: [
          if (_selectedMode == 0) ...[
            IconButton(
              icon: Icon(
                _isTorchOn ? Icons.flash_on : Icons.flash_off,
                color: _isTorchOn ? AppColors.primary : AppColors.muted,
              ),
              onPressed: () {
                _scannerController.toggleTorch();
                setState(() => _isTorchOn = !_isTorchOn);
              },
            ),
            IconButton(
              icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
              onPressed: () => _scannerController.switchCamera(),
            ),
          ],
        ],
      ),
      body: Stack(
        children: [
          // Konten Berdasarkan Mode
          if (_selectedMode == 0) _buildBarcodeScannerView() else _buildReceiptScannerView(),

          // Mode Selector Tab di bagian atas
          Positioned(
            top: 12,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withOpacity(0.92),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.hairlineDark),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMode = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedMode == 0 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.barcode_reader,
                              size: 18,
                              color: _selectedMode == 0 ? AppColors.canvasDark : AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Barcode Produk',
                              style: AppText.button(
                                color: _selectedMode == 0 ? AppColors.canvasDark : AppColors.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMode = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedMode == 1 ? AppColors.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 18,
                              color: _selectedMode == 1 ? AppColors.canvasDark : AppColors.muted,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Struk & Bukti',
                              style: AppText.button(
                                color: _selectedMode == 1 ? AppColors.canvasDark : AppColors.muted,
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
          ),

          // Loading Overlay Saat OCR Berjalan
          if (_isProcessingOcr)
            Container(
              color: Colors.black87,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.hairlineDark),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text('Membaca Struk & Bukti...', style: AppText.titleMedium()),
                      const SizedBox(height: 6),
                      Text(
                        'Mengekstrak nominal, toko, tanggal & kategori...',
                        style: AppText.caption(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // View Mode 0: Live Barcode Scanner
  Widget _buildBarcodeScannerView() {
    return Stack(
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: _onBarcodeDetect,
        ),
        // Overlay Target Box
        Center(
          child: Container(
            width: 270,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 2.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 8,
                  right: 8,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Posisikan Kode Batang / QR di Dalam Kotak',
                        style: AppText.caption(color: AppColors.primary),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 36,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surfaceCard.withOpacity(0.92),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.hairlineDark),
            ),
            child: Text(
              'Arahkan kamera ke barcode rokok, kopi sachet, atau makanan. Produk otomatis terdeteksi!',
              textAlign: TextAlign.center,
              style: AppText.bodySm(color: AppColors.body),
            ),
          ),
        ),
      ],
    );
  }

  // View Mode 1: Receipt / Struk / Tarik Tunai OCR Scanner
  Widget _buildReceiptScannerView() {
    return Container(
      color: AppColors.canvasDark,
      padding: const EdgeInsets.fromLTRB(20, 70, 20, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ilustrasi Bingkai Struk
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.hairlineDark),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.document_scanner_outlined,
                        color: AppColors.primary,
                        size: 48,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Scan Struk, Nota, atau Tarik Tunai',
                      textAlign: TextAlign.center,
                      style: AppText.titleLg(),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'AI OCR otomatis menyerap:\n• Nominal Belanja / Tarik Tunai\n• Nama Toko / Minimarket / Bank ATM\n• Kategori Pengeluaran & Tanggal Transaksi',
                      textAlign: TextAlign.center,
                      style: AppText.bodyMd(color: AppColors.body),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_outline, color: AppColors.tradingUp, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Indomaret • Alfamart • SPBU • ATM • Resto',
                            style: AppText.caption(color: AppColors.tradingUp),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tombol Aksi: Kamera & Galeri
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.canvasDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: Text('Foto Struk', style: AppText.button(color: AppColors.canvasDark)),
                  onPressed: () => _pickAndProcessReceipt(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.onDark,
                    side: const BorderSide(color: AppColors.hairlineDark),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.photo_library, size: 20, color: AppColors.primary),
                  label: Text('Dari Galeri', style: AppText.button(color: AppColors.onDark)),
                  onPressed: () => _pickAndProcessReceipt(ImageSource.gallery),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
