import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../app/theme/app_colors.dart';
import '../../data/services/health_report_ocr_service.dart';
import '../../data/services/health_report_parser_service.dart';
import '../../data/models/health_measurement_model.dart';
import 'confirm_detected_values_page.dart';

class ScanHealthReportPage extends StatefulWidget {
  const ScanHealthReportPage({super.key});

  @override
  State<ScanHealthReportPage> createState() => _ScanHealthReportPageState();
}

class _ScanHealthReportPageState extends State<ScanHealthReportPage> {
  final ImagePicker _imagePicker = ImagePicker();

  XFile? _selectedImage;
  bool _isPickingImage = false;

  final HealthReportOcrService _ocrService = HealthReportOcrService();

  bool _isExtracting = false;
  String? _extractedText;

  final HealthReportParserService _parserService = HealthReportParserService();

  List<HealthMeasurementModel> _detectedMeasurements = [];

  Future<void> _pickImage(ImageSource source) async {
    if (_isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final image = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _extractedText = null;
          _detectedMeasurements = [];
        });
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to select image. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _removeImage() {
    if (_isExtracting) return;

    setState(() {
      _selectedImage = null;
      _extractedText = null;
      _detectedMeasurements = [];
    });
  }

  Future<void> _extractReportText() async {
    if (_selectedImage == null || _isExtracting) return;

    setState(() {
      _isExtracting = true;
      _extractedText = null;
    });

    try {
      final text = await _ocrService.extractText(_selectedImage!.path);

      if (!mounted) return;

      final measurements = _parserService.extractMeasurements(text);

      setState(() {
        _extractedText = text;
        _detectedMeasurements = measurements;
      });

      if (text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No text detected. Try a clearer report image.'),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Text extraction failed. Please try another image.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExtracting = false;
        });
      }
    }
  }

  void _reviewDetectedMeasurements() {
    if (_detectedMeasurements.isEmpty || _isExtracting) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConfirmDetectedValuesPage(
          detectedMeasurements: List.of(_detectedMeasurements),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFC),
      appBar: AppBar(
        title: const Text(
          'Scan Health Report',
          style: TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFFF5FAFC),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE7F4FF),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Take a clear photo of your laboratory '
                      'report or select an image from your gallery.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.document_scanner_outlined,
                    size: 54,
                    color: AppColors.primary,
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Upload Your Health Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Choose how you want to add your report.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isPickingImage
                          ? null
                          : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take Photo'),
                    ),
                  ),

                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isPickingImage
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: const Text('Choose from Gallery'),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 22),

            if (_selectedImage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selected Report Preview',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 14),

                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_selectedImage!.path),
                        width: double.infinity,
                        height: 260,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Padding(
                            padding: EdgeInsets.all(24),
                            child: Text(
                              'Unable to preview the selected image.',
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextButton.icon(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Remove Image'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isExtracting ? null : _extractReportText,
                  icon: _isExtracting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.document_scanner),
                  label: Text(
                    _isExtracting
                        ? 'Extracting Text...'
                        : 'Extract Report Text',
                  ),
                ),
              ),

              if (_extractedText != null &&
                  _extractedText!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Text — Not Yet Verified',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Compare this text with your original '
                        'laboratory report. OCR can make mistakes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),

                      const SizedBox(height: 14),

                      SelectableText(
                        _extractedText!,
                        style: const TextStyle(fontSize: 13, height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                if (_detectedMeasurements.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _isExtracting
                          ? null
                          : _reviewDetectedMeasurements,
                      icon: const Icon(Icons.fact_check_outlined),
                      label: const Text('Review Detected Measurements'),
                    ),
                  )
                else
                  const Text(
                    'No measurement candidates are available for review. '
                    'Use manual entry if this report format is not supported.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],

              if (_extractedText != null &&
                  _extractedText!.trim().isNotEmpty) ...[
                const SizedBox(height: 20),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Detected Measurements — Unverified',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (_detectedMeasurements.isEmpty)
                        const Text(
                          'No supported measurements were identified '
                          'automatically. You can enter your report '
                          'values manually.',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        )
                      else
                        for (final measurement in _detectedMeasurements)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    measurement.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${measurement.value} ${measurement.unit}',
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ],
                            ),
                          ),

                      const SizedBox(height: 8),

                      const Text(
                        'These values are suggestions from OCR. '
                        'They must be checked against the original '
                        'laboratory report before saving.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],

            const SizedBox(height: 16),

            const Text(
              'Your selected image will not be uploaded '
              'to Firebase during this stage. '
              'Extracted values must be reviewed before saving.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
