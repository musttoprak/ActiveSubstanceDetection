import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';

import '../../service/pages_service.dart';

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({Key? key}) : super(key: key);

  @override
  _BarcodeScannerPageState createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  String _barcodeResult = "Barkod Okutulmadı";

  // Barkod okutma işlemi
  Future<void> _scanBarcode() async {
    final barcode = await FlutterBarcodeScanner.scanBarcode(
        '#ff6666', 'İptal', true, ScanMode.BARCODE);
    if (barcode != '-1') {
      setState(() {
        _barcodeResult = barcode;
      });

      // Barkodla ilaç bilgisini çekmek için API çağrısı yapıyoruz
      await PagesService.fetchMedicineDetails(_barcodeResult);
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Barkod Okut"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _scanBarcode,
              child: const Text("Barkod Okut"),
            ),
            const SizedBox(height: 16),
            Text(
              _barcodeResult,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}
