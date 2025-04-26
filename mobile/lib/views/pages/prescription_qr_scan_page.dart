// pages/prescription_qr_scan_page.dart
import 'package:flutter/material.dart';
import 'package:mobile/views/pages/prescription_detail_page.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class PrescriptionScanPage extends StatefulWidget {
  const PrescriptionScanPage({super.key});

  @override
  State<PrescriptionScanPage> createState() => _PrescriptionScanPageState();
}

class _PrescriptionScanPageState extends State<PrescriptionScanPage> {
  final MobileScannerController controller = MobileScannerController();
  bool isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Reçete Tarama"),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.flash_on),
            onPressed: () => controller.toggleTorch(),
          ),
          IconButton(
            icon: Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
              child: Stack(
                children: [
                  MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      if (isProcessing) return; // Önlem: çift işlemden kaçın

                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        final String code = barcode.rawValue ?? "";

                        if (code.startsWith("RX-")) {
                          setState(() {
                            isProcessing = true;
                          });

                          // Taramayı duraklatın
                          controller.stop();

                          // Detay sayfasına git
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PrescriptionDetailPage(receteNo: code),
                            ),
                          ).then((_) {
                            // Geri döndüğünde taramayı yeniden başlat
                            setState(() {
                              isProcessing = false;
                            });
                            controller.start();
                          });

                          break;
                        }
                      }
                    },
                  ),

                  // Tarama çerçevesi
                  Center(
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.qr_code_scanner,
                            color: Colors.white.withOpacity(0.6),
                            size: 50,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Reçete QR Kodunu Tarayın",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // İşlem durumu göstergesi
                  if (isProcessing)
                    Container(
                      color: Colors.black54,
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Bilgi mesajı
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
                SizedBox(height: 16),
                Text(
                  "Reçete bilgilerini görmek için QR kodu tarayın",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "Kamera, reçete üzerindeki QR kodu otomatik olarak algılayacaktır.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}