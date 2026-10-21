// -----------------------------------------------------------------------------
// Module overview: Provides cashier barcode scanning and exact product lookup for supported retail barcode formats.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

// Screen widget for provides cashier barcode scanning and exact product lookup for supported retail barcode formats.
class CashierBarcodeScannerScreen extends StatefulWidget {
  // Handles the cashier barcode scanner screen logic used by this module.
  const CashierBarcodeScannerScreen({super.key});

  @override
  State<CashierBarcodeScannerScreen> createState() =>
      _CashierBarcodeScannerScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierBarcodeScannerScreenState
    extends State<CashierBarcodeScannerScreen> {
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    formats: const [
      BarcodeFormat.ean13,
      BarcodeFormat.ean8,
      BarcodeFormat.upcA,
      BarcodeFormat.upcE,
      BarcodeFormat.code128,
      BarcodeFormat.code39,
      BarcodeFormat.itf,
      BarcodeFormat.codabar,
    ],
  );

  final TextEditingController _manualBarcodeController =
      TextEditingController();

  bool _isProcessing = false;
  bool _scannerEnabled = true;
  String? _lastScannedCode;
  Map<String, dynamic>? _product;
  String? _productDocumentId;
  String? _message;

  // Handles the barcode user or system event and updates state as required.
  Future<void> _handleBarcode(String code) async {
    final cleanedCode = code.trim();

    if (cleanedCode.isEmpty || _isProcessing) return;

    if (_lastScannedCode == cleanedCode && _product != null) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = cleanedCode;
      _message = null;
      _product = null;
      _productDocumentId = null;
    });

    try {
      final query = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: cleanedCode)
          .limit(1)
          .get();

      if (!mounted) return;

      if (query.docs.isEmpty) {
        setState(() {
          _message = 'No product was found for barcode $cleanedCode.';
        });
        return;
      }

      final document = query.docs.first;

      setState(() {
        _productDocumentId = document.id;
        _product = document.data();
        _message = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _message = 'Unable to search the product.\n$error';
      });
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // Handles the on detect event for this widget.
  void _onDetect(BarcodeCapture capture) {
    if (!_scannerEnabled || _isProcessing) return;

    for (final barcode in capture.barcodes) {
      final code = barcode.rawValue;

      if (code != null && code.trim().isNotEmpty) {
        _handleBarcode(code);
        break;
      }
    }
  }

  // Handles the scan again logic used by this module.
  void _scanAgain() {
    setState(() {
      _lastScannedCode = null;
      _product = null;
      _productDocumentId = null;
      _message = null;
      _manualBarcodeController.clear();
    });
  }

  // Handles the stock color logic used by this module.
  Color _stockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 10) return Colors.orange;
    return Colors.green;
  }

  // Handles the stock status logic used by this module.
  String _stockStatus(int stock) {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= 10) return 'Low Stock';
    return 'Available';
  }

  // Builds the product result UI from the current data and screen state.
  Widget _buildProductResult() {
    final data = _product;

    if (data == null) {
      if (_message != null) {
        // Handles the container logic used by this module.
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.shade100),
          ),
          child: Column(
            children: [
              // Handles the icon logic used by this module.
              const Icon(Icons.search_off, color: Colors.red, size: 42),
              // Handles the sized box logic used by this module.
              const SizedBox(height: 10),
              Text(
                _message!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Handles the sized box logic used by this module.
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: _scanAgain,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('SCAN AGAIN'),
              ),
            ],
          ),
        );
      }

      // Handles the container logic used by this module.
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EAF0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 46, color: Colors.grey),
            SizedBox(height: 10),
            Text(
              'Scan a barcode to display product information.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final name = (data['productName'] ?? 'Unknown Product').toString();
    final barcode = (data['barcode'] ?? '').toString();
    final category = (data['category'] ?? '').toString();
    final brand = (data['brand'] ?? '').toString();
    final unit = (data['unit'] ?? '').toString();
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final price = (data['sellingPrice'] as num?)?.toDouble() ?? 0;

    final stockColor = _stockColor(stock);

    // Handles the container logic used by this module.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF1565C0),
                  size: 30,
                ),
              ),
              // Handles the sized box logic used by this module.
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 5),
                    Text(
                      [
                        if (brand.isNotEmpty) brand,
                        if (category.isNotEmpty) category,
                        if (unit.isNotEmpty) unit,
                      ].join(' • '),
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: stockColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _stockStatus(stock),
                  style: TextStyle(
                    color: stockColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // Handles the sized box logic used by this module.
          const SizedBox(height: 22),
          // Handles the divider logic used by this module.
          const Divider(),
          // Handles the sized box logic used by this module.
          const SizedBox(height: 14),
          _infoRow('Barcode', barcode),
          _infoRow('Document ID', _productDocumentId ?? ''),
          _infoRow('Selling Price', '₱${price.toStringAsFixed(2)}'),
          _infoRow('Current Stock', '$stock'),
          // Handles the sized box logic used by this module.
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _scanAgain,
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('SCAN ANOTHER PRODUCT'),
            ),
          ),
        ],
      ),
    );
  }

  // Handles the info row logic used by this module.
  Widget _infoRow(String label, String value) {
    // Handles the padding logic used by this module.
    return Padding(
      padding: const EdgeInsets.only(bottom: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value.isEmpty ? 'Not provided' : value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handles the single child scroll view logic used by this module.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 850;

              final scannerPanel = Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x10000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Handles the expanded logic used by this module.
                        const Expanded(
                          child: Text(
                            'Barcode Scanner',
                            style: TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Switch(
                          value: _scannerEnabled,
                          onChanged: (value) {
                            setState(() {
                              _scannerEnabled = value;
                            });

                            if (value) {
                              _scannerController.start();
                            } else {
                              _scannerController.stop();
                            }
                          },
                        ),
                      ],
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (_scannerEnabled)
                              MobileScanner(
                                controller: _scannerController,
                                onDetect: _onDetect,
                                errorBuilder: (context, error) {
                                  // Handles the container logic used by this module.
                                  return Container(
                                    color: Colors.black87,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'Camera unavailable.\n$error',
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                color: Colors.black87,
                                alignment: Alignment.center,
                                child: const Text(
                                  'Scanner is turned off.',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            IgnorePointer(
                              child: Center(
                                child: Container(
                                  width: 260,
                                  height: 130,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                            if (_isProcessing)
                              Container(
                                color: Colors.black45,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 18),
                    // Handles the text logic used by this module.
                    const Text(
                      'Manual Barcode Entry',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _manualBarcodeController,
                            onSubmitted: _handleBarcode,
                            decoration: const InputDecoration(
                              hintText: 'Enter or paste barcode',
                              prefixIcon: Icon(Icons.numbers),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        // Handles the sized box logic used by this module.
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing
                                ? null
                                : () => _handleBarcode(
                                    _manualBarcodeController.text,
                                  ),
                            icon: const Icon(Icons.search),
                            label: const Text('SEARCH'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );

              final resultPanel = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handles the text logic used by this module.
                  const Text(
                    'Product Result',
                    style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                  ),
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 14),
                  _buildProductResult(),
                ],
              );

              if (isWide) {
                // Handles the row logic used by this module.
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: scannerPanel),
                    // Handles the sized box logic used by this module.
                    const SizedBox(width: 22),
                    Expanded(flex: 4, child: resultPanel),
                  ],
                );
              }

              // Handles the column logic used by this module.
              return Column(
                children: [
                  scannerPanel,
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 22),
                  resultPanel,
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _manualBarcodeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }
}
