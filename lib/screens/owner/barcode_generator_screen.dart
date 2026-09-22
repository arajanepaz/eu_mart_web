import 'dart:math';
import 'dart:typed_data';

import 'package:barcode_widget/barcode_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class _BarcodeHoverCard extends StatefulWidget {
  final Widget child;

  const _BarcodeHoverCard({required this.child});

  @override
  State<_BarcodeHoverCard> createState() => _BarcodeHoverCardState();
}

class _BarcodeHoverCardState extends State<_BarcodeHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x2016385A)
                  : const Color(0x1016385A),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class BarcodeGeneratorScreen extends StatefulWidget {
  const BarcodeGeneratorScreen({super.key});

  @override
  State<BarcodeGeneratorScreen> createState() => _BarcodeGeneratorScreenState();
}

class _BarcodeGeneratorScreenState extends State<BarcodeGeneratorScreen> {
  String? _selectedProductId;
  String _selectedProductName = '';
  String _selectedUnit = '';
  double _selectedPrice = 0;

  String? _generatedBarcode;
  bool _generating = false;
  bool _saving = false;

  String _slug(String value) {
    final cleaned = value
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');

    if (cleaned.isEmpty) return 'PRODUCT';

    final parts = cleaned.split('-');
    final short = parts
        .where((part) => part.isNotEmpty)
        .take(3)
        .map((part) => part.length > 4 ? part.substring(0, 4) : part)
        .join('-');

    return short.isEmpty ? 'PRODUCT' : short;
  }

  Future<bool> _barcodeExists(String barcode) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('barcode', isEqualTo: barcode)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty;
  }

  Future<void> _generateBarcode() async {
    if (_selectedProductId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select an actual product first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _generating = true);

    try {
      final random = Random.secure();
      String candidate = '';
      bool exists = true;

      for (int attempt = 0; attempt < 10 && exists; attempt++) {
        final date = DateTime.now();
        final year = date.year.toString().substring(2);
        final randomNumber = 1000 + random.nextInt(9000);

        candidate = 'EUM-${_slug(_selectedProductName)}-$year-$randomNumber';

        exists = await _barcodeExists(candidate);
      }

      if (exists) {
        throw Exception(
          'Unable to generate a unique barcode. Please try again.',
        );
      }

      if (!mounted) return;

      setState(() {
        _generatedBarcode = candidate;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Barcode generation failed: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<void> _saveBarcodeToProduct() async {
    if (_selectedProductId == null || _generatedBarcode == null) return;

    setState(() => _saving = true);

    try {
      final duplicate = await _barcodeExists(_generatedBarcode!);

      if (duplicate) {
        throw Exception('This barcode already exists. Generate a new barcode.');
      }

      await FirebaseFirestore.instance
          .collection('products')
          .doc(_selectedProductId)
          .update({
            'barcode': _generatedBarcode,
            'barcodeType': 'CODE128',
            'barcodeSource': 'internal',
            'barcodeGeneratedAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Internal barcode saved to the product.'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedProductId = null;
        _selectedProductName = '';
        _selectedUnit = '';
        _selectedPrice = 0;
        _generatedBarcode = null;
      });
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save barcode: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<Uint8List> _generateLabelPdf() async {
    if (_generatedBarcode == null) {
      throw Exception('Generate a barcode first.');
    }

    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(210, 125, marginAll: 10),
        build: (context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(border: pw.Border.all(width: 1)),
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text(
                  'EÜ MART',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 3),
                pw.Text(
                  _selectedProductName,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (_selectedUnit.isNotEmpty)
                  pw.Text(
                    _selectedUnit,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                pw.SizedBox(height: 5),
                pw.BarcodeWidget(
                  barcode: pw.Barcode.code128(),
                  data: _generatedBarcode!,
                  width: 170,
                  height: 38,
                  drawText: false,
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  _generatedBarcode!,
                  style: const pw.TextStyle(fontSize: 8),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  '₱${_selectedPrice.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    return document.save();
  }

  Future<void> _printOrSaveLabel() async {
    if (_generatedBarcode == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Generate a barcode first.')),
      );
      return;
    }

    await Printing.layoutPdf(
      name: 'EU_MART_${_slug(_selectedProductName)}_Barcode',
      onLayout: (_) => _generateLabelPdf(),
    );
  }

  Widget _buildProductSelector(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) {
    return DropdownButtonFormField<String>(
      initialValue: _selectedProductId,
      decoration: InputDecoration(
        labelText: 'Select product without barcode',
        prefixIcon: const Icon(
          Icons.inventory_2_outlined,
          color: Color(0xFF1565C0),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAFE),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFDDE6F1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFDDE6F1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
        ),
      ),
      items: products.map((document) {
        final data = document.data();
        final name = (data['productName'] ?? 'Unknown Product').toString();
        final unit = (data['unit'] ?? '').toString();

        return DropdownMenuItem<String>(
          value: document.id,
          child: Text(
            unit.isEmpty ? name : '$name — $unit',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value == null) return;

        final selected = products.firstWhere(
          (document) => document.id == value,
        );
        final data = selected.data();

        setState(() {
          _selectedProductId = value;
          _selectedProductName = (data['productName'] ?? 'Unknown Product')
              .toString();
          _selectedUnit = (data['unit'] ?? '').toString();
          _selectedPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
          _generatedBarcode = null;
        });
      },
    );
  }

  Widget _buildPreview() {
    if (_generatedBarcode == null) {
      return _BarcodeHoverCard(
        child: Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF7FAFE)],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFFDDE6F1)),
          ),
          child: Center(
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 520),
              tween: Tween(begin: 0.88, end: 1),
              curve: Curves.easeOutBack,
              builder: (context, value, child) {
                return Transform.scale(scale: value, child: child);
              },
              child: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 82,
                    color: Color(0xFFB8C5D5),
                  ),
                  SizedBox(height: 14),
                  Text(
                    'Barcode preview will appear here',
                    style: TextStyle(
                      color: Color(0xFF657386),
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Select a product and generate its internal barcode.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF9AA5B3)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return _BarcodeHoverCard(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFBFDFF)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFD7E7FA)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.qr_code_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Barcode Label Preview',
                        style: TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Code 128 internal product label',
                        style: TextStyle(
                          color: Color(0xFF8A95A4),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'READY',
                    style: TextStyle(
                      color: Color(0xFF168653),
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x1016385A),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'EÜ MART',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedProductName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF172033),
                    ),
                  ),
                  if (_selectedUnit.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      _selectedUnit,
                      style: const TextStyle(color: Color(0xFF8A95A4)),
                    ),
                  ],
                  const SizedBox(height: 22),
                  BarcodeWidget(
                    barcode: Barcode.code128(),
                    data: _generatedBarcode!,
                    width: 420,
                    height: 110,
                    drawText: true,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '₱${_selectedPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F8A4B),
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Internal EÜ MART barcode • Code 128',
                    style: TextStyle(color: Color(0xFF8A95A4)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load products.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final products =
            (snapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                .where((document) {
                  final barcode = (document.data()['barcode'] ?? '')
                      .toString()
                      .trim();

                  return barcode.isEmpty;
                })
                .toList()
              ..sort((a, b) {
                final first = (a.data()['productName'] ?? '')
                    .toString()
                    .toLowerCase();
                final second = (b.data()['productName'] ?? '')
                    .toString()
                    .toLowerCase();

                return first.compareTo(second);
              });

        return Container(
          color: const Color(0xFFF2F6FC),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1080),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x291565C0),
                            blurRadius: 20,
                            offset: Offset(0, 9),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.qr_code_2_rounded,
                            color: Colors.white,
                            size: 29,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Internal Barcode Generator',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Create printable internal barcodes '
                                  'for actual store products without '
                                  'manufacturer-provided codes.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 850;

                        final setupCard = _BarcodeHoverCard(
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Colors.white, Color(0xFFFBFDFF)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFE1E9F3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEAF3FF),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Product Setup',
                                            style: TextStyle(
                                              color: Color(0xFF172033),
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            'Choose a product that does not '
                                            'have a barcode yet.',
                                            style: TextStyle(
                                              color: Color(0xFF8A95A4),
                                              fontSize: 11.5,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 18),
                                if (products.isEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF8F0),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Color(0xFF168653),
                                        ),
                                        SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            'All current products already '
                                            'have barcodes.',
                                            style: TextStyle(
                                              color: Color(0xFF168653),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  _buildProductSelector(products),
                                const SizedBox(height: 16),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: products.isEmpty || _generating
                                        ? null
                                        : _generateBarcode,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1565C0),
                                      foregroundColor: Colors.white,
                                      disabledBackgroundColor: const Color(
                                        0xFF9DB7D4,
                                      ),
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    icon: _generating
                                        ? const SizedBox(
                                            width: 19,
                                            height: 19,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Colors.white,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.auto_awesome_rounded,
                                          ),
                                    label: Text(
                                      _generating
                                          ? 'GENERATING...'
                                          : 'GENERATE UNIQUE BARCODE',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        final infoCard = _BarcodeHoverCard(
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFEAF3FF), Color(0xFFF7FAFF)],
                              ),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: const Color(0xFFD7E7FA),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.lightbulb_outline_rounded,
                                  color: Color(0xFFF59E0B),
                                  size: 30,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'When to use this',
                                  style: TextStyle(
                                    color: Color(0xFF172033),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Use internal barcodes for eggs, '
                                  'repacked rice, cooking oil sold by '
                                  'volume, and other real products '
                                  'without printed manufacturer barcodes.',
                                  style: TextStyle(
                                    color: Color(0xFF607086),
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );

                        if (isWide) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: setupCard),
                              const SizedBox(width: 16),
                              Expanded(flex: 2, child: infoCard),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            setupCard,
                            const SizedBox(height: 16),
                            infoCard,
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    _buildPreview(),
                    if (_generatedBarcode != null) ...[
                      const SizedBox(height: 18),
                      _BarcodeHoverCard(
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEAF3FF), Color(0xFFF7FAFF)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFD7E7FA)),
                          ),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.end,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _printOrSaveLabel,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(190, 48),
                                ),
                                icon: const Icon(Icons.print_outlined),
                                label: const Text('PRINT / SAVE PDF'),
                              ),
                              ElevatedButton.icon(
                                onPressed: _saving
                                    ? null
                                    : _saveBarcodeToProduct,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(190, 48),
                                  elevation: 0,
                                ),
                                icon: _saving
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded),
                                label: Text(
                                  _saving ? 'SAVING...' : 'SAVE TO PRODUCT',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
