import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../app/theme/app_colors.dart';

class BarcodeScannerView extends StatefulWidget {
  final ValueChanged<String> onBarcodeDetected;

  const BarcodeScannerView({super.key, required this.onBarcodeDetected});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  late final MobileScannerController _controller;

  bool _barcodeHandled = false;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_barcodeHandled) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value == null || value.isEmpty) {
        continue;
      }

      _barcodeHandled = true;

      widget.onBarcodeDetected(value);
      return;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: double.infinity,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            MobileScanner(controller: _controller, onDetect: _handleDetection),

            // Camera scanning overlay
            IgnorePointer(
              child: Container(
                width: 250,
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            // Instruction text
            const Positioned(
              bottom: 12,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Text(
                    'Align product barcode inside the frame',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
