import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class NewTransactionScreen extends StatefulWidget {
  const NewTransactionScreen({super.key});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

class _NewTransactionScreenState extends State<NewTransactionScreen> {
  final _searchController = TextEditingController();
  final _cashController = TextEditingController();
  final Map<String, _CartItem> _cart = {};

  DateTime? _transactionStartedAt;
  Timer? _durationTimer;

  String _query = '';
  bool _processing = false;
  bool _aiSearching = false;
  final Set<String> _aiMatchedProductIds = <String>{};
  String _aiSearchMessage = '';

  double get _total => _cart.values.fold(0, (sum, item) => sum + item.subtotal);

  double get _totalSavings =>
      _cart.values.fold(0, (sum, item) => sum + item.savings);

  double get _cash => double.tryParse(_cashController.text.trim()) ?? 0;

  double get _change => _cash >= _total ? _cash - _total : 0;

  int get _elapsedSeconds {
    final startedAt = _transactionStartedAt;

    if (startedAt == null) return 0;

    return DateTime.now().difference(startedAt).inSeconds;
  }

  String get _formattedElapsedTime {
    final seconds = _elapsedSeconds;
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _serviceSpeedLabel(int durationSeconds) {
    if (durationSeconds <= 120) return 'Normal Service';
    if (durationSeconds <= 300) return 'Minor Delay';
    return 'Long Delay';
  }

  void _ensureTransactionStarted() {
    if (_transactionStartedAt != null) return;

    _transactionStartedAt = DateTime.now();
    _startDurationTimer();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _transactionStartedAt == null) {
        return;
      }

      setState(() {});
    });
  }

  void _resetTransactionTracking() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _transactionStartedAt = null;
  }

  bool _isPromoCurrentlyActive(Map<String, dynamic> data) {
    if (data['promoActive'] != true) return false;

    DateTime? readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = readDate(data['promoStartDate']);
    final endDate = readDate(data['promoEndDate']);

    if (startDate != null) {
      final normalizedStart = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
      );

      if (normalizedStart.isAfter(today)) return false;
    }

    if (endDate != null) {
      final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

      if (normalizedEnd.isBefore(today)) return false;
    }

    return true;
  }

  void _addProduct(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    if (data['isActive'] == false) {
      _message(
        '${(data['productName'] ?? 'This product')} is inactive and cannot be sold.',
        Colors.orange,
      );
      return;
    }

    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final name = (data['productName'] ?? 'Unknown Product').toString();

    if (stock <= 0) {
      _message('$name is out of stock.', Colors.red);
      return;
    }

    _ensureTransactionStarted();

    final existing = _cart[document.id];

    if (existing != null) {
      if (existing.quantity >= stock) {
        _message('Only $stock stock available for $name.', Colors.orange);
        return;
      }

      setState(() => existing.quantity++);
      return;
    }

    final regularPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0;

    final promoActive = _isPromoCurrentlyActive(data);
    final promoType = promoActive ? (data['promoType'] ?? '').toString() : '';
    final promoLabel = promoActive
        ? (data['promoLabel'] ?? promoType).toString()
        : '';

    final promoPrice = promoActive
        ? (data['promoPrice'] as num?)?.toDouble()
        : null;

    final effectivePrice =
        promoActive &&
            promoType != 'Buy 1 Take 1' &&
            promoPrice != null &&
            promoPrice > 0 &&
            promoPrice < regularPrice
        ? promoPrice
        : regularPrice;

    setState(() {
      _cart[document.id] = _CartItem(
        productId: document.id,
        productName: name,
        barcode: (data['barcode'] ?? '').toString(),
        unit: (data['unit'] ?? '').toString(),
        price: effectivePrice,
        regularPrice: regularPrice,
        availableStock: stock,
        promoActive: promoActive,
        promoType: promoType,
        promoLabel: promoLabel,
      );
    });

    if (promoActive) {
      _message(
        promoType == 'Buy 1 Take 1'
            ? '$name: Buy 1 Take 1 applied.'
            : '$name: Promo price applied.',
        Colors.green,
      );
    }
  }

  void _increase(_CartItem item) {
    if (item.quantity >= item.availableStock) {
      _message('Only ${item.availableStock} stock available.', Colors.orange);
      return;
    }

    setState(() => item.quantity++);
  }

  void _decrease(_CartItem item) {
    setState(() {
      if (item.quantity <= 1) {
        _cart.remove(item.productId);

        if (_cart.isEmpty) {
          _resetTransactionTracking();
        }
      } else {
        item.quantity--;
      }
    });
  }

  void _message(String text, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  Future<void> _logAutomaticServiceIssue({
    required String issueType,
    required String description,
    String severity = 'Minor',
    Map<String, dynamic>? details,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('service_issues').add({
        'issueType': issueType,
        'severity': severity,
        'description': description,
        'status': 'open',
        'resolution': '',
        'source': 'POS',
        'automatic': true,
        'details': details ?? <String, dynamic>{},
        'reportedById': user.uid,
        'reportedByEmail': user.email ?? '',
        'reportedByName': user.displayName ?? user.email ?? 'Cashier',
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'resolvedById': '',
        'resolvedByEmail': '',
      });
    } catch (error) {
      debugPrint('Unable to log automatic service issue: $error');
    }
  }

  bool _matches(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    if (_query.isEmpty) return true;

    if (_aiMatchedProductIds.contains(document.id)) {
      return true;
    }

    final data = document.data();

    final searchable = [
      data['productName'],
      data['barcode'],
      data['category'],
      data['brand'],
      data['unit'],
    ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

    if (searchable.contains(_query)) return true;

    final queryWords = _query
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return queryWords.isNotEmpty &&
        queryWords.every((word) {
          return searchable.contains(word) || _hasCloseWord(searchable, word);
        });
  }

  bool _hasCloseWord(String searchable, String queryWord) {
    if (queryWord.length < 3) return false;

    final words = searchable
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty);

    for (final word in words) {
      if (word.startsWith(queryWord) || queryWord.startsWith(word)) {
        return true;
      }

      final lengthDifference = (word.length - queryWord.length).abs();

      if (lengthDifference > 3) continue;

      final allowedDistance = queryWord.length <= 4 ? 1 : 2;

      if (_levenshteinDistance(word, queryWord) <= allowedDistance) {
        return true;
      }
    }

    return false;
  }

  int _levenshteinDistance(String first, String second) {
    final previous = List<int>.generate(second.length + 1, (index) => index);

    for (var i = 0; i < first.length; i++) {
      var diagonal = previous[0];
      previous[0] = i + 1;

      for (var j = 0; j < second.length; j++) {
        final oldValue = previous[j + 1];
        final cost = first[i] == second[j] ? 0 : 1;

        previous[j + 1] = [
          previous[j + 1] + 1,
          previous[j] + 1,
          diagonal + cost,
        ].reduce((a, b) => a < b ? a : b);

        diagonal = oldValue;
      }
    }

    return previous.last;
  }

  Future<void> _runAiSearch(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) async {
    final query = _searchController.text.trim();

    if (query.isEmpty) {
      _message('Enter a product description first.', Colors.orange);
      return;
    }

    setState(() {
      _aiSearching = true;
      _aiMatchedProductIds.clear();
      _aiSearchMessage = '';
    });

    try {
      final productLines = products
          .map((document) {
            final data = document.data();

            return [
              'ID=${document.id}',
              'NAME=${(data['productName'] ?? '').toString()}',
              'BRAND=${(data['brand'] ?? '').toString()}',
              'CATEGORY=${(data['category'] ?? '').toString()}',
              'UNIT=${(data['unit'] ?? '').toString()}',
              'BARCODE=${(data['barcode'] ?? '').toString()}',
            ].join(' | ');
          })
          .join('\n');

      final model = FirebaseAI.googleAI().generativeModel(
        model: 'gemini-2.5-flash',
      );

      final prompt =
          '''
You are a product-search assistant for EÜ MART.
Find products that best match the cashier query.

Cashier query:
$query

Available products:
$productLines

Return only matching Firestore IDs separated by commas.
Return NONE when there is no reasonable match.
Do not explain.
''';

      final response = await model.generateContent([Content.text(prompt)]);

      final text = (response.text ?? '').trim();

      if (text.isEmpty || text.toUpperCase().contains('NONE')) {
        setState(() {
          _aiSearchMessage = 'AI found no relevant product.';
        });
        return;
      }

      final validIds = products.map((item) => item.id).toSet();

      final ids = text
          .split(RegExp(r'[,\s]+'))
          .map((value) => value.trim())
          .where(validIds.contains)
          .toSet();

      setState(() {
        _aiMatchedProductIds.addAll(ids);
        _aiSearchMessage = ids.isEmpty
            ? 'AI found no relevant product.'
            : 'AI suggested ${ids.length} product(s).';
      });
    } catch (_) {
      setState(() {
        _aiSearchMessage =
            'AI service is unavailable. Typo-tolerant search is still active.';
      });
    } finally {
      if (mounted) {
        setState(() => _aiSearching = false);
      }
    }
  }

  Future<String> _saveTransaction({
    required DateTime startedAt,
    required DateTime completedAt,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) throw Exception('No logged-in cashier.');
    if (_cart.isEmpty) throw Exception('The cart is empty.');
    if (_cash < _total) throw Exception('Insufficient cash.');

    final reference = FirebaseFirestore.instance
        .collection('transactions')
        .doc();

    final now = DateTime.now();
    final receiptNumber =
        'EU-${now.millisecondsSinceEpoch}-${reference.id.substring(0, 6).toUpperCase()}';

    final durationSeconds = completedAt
        .difference(startedAt)
        .inSeconds
        .clamp(0, 86400)
        .toInt();

    final serviceSpeed = _serviceSpeedLabel(durationSeconds);

    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final items = <Map<String, dynamic>>[];

    for (final item in _cart.values) {
      final productReference = firestore
          .collection('products')
          .doc(item.productId);

      final productSnapshot = await productReference.get();

      if (!productSnapshot.exists) {
        throw Exception('${item.productName} no longer exists.');
      }

      final productData = productSnapshot.data() ?? <String, dynamic>{};

      final currentStock = (productData['stock'] as num?)?.toInt() ?? 0;

      if (currentStock < item.quantity) {
        throw Exception(
          'Not enough stock for ${item.productName}. '
          'Available: $currentStock.',
        );
      }

      batch.update(productReference, {
        'stock': currentStock - item.quantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      items.add({
        'productId': item.productId,
        'productName': item.productName,
        'barcode': item.barcode,
        'unit': item.unit,
        'price': item.price,
        'regularPrice': item.regularPrice,
        'buyingPrice': (productData['buyingPrice'] as num?)?.toDouble() ?? 0,
        'quantity': item.quantity,
        'chargedQuantity': item.chargedQuantity,
        'subtotal': item.subtotal,
        'promoApplied': item.promoActive,
        'promoType': item.promoType,
        'promoLabel': item.promoLabel,
      });
    }

    batch.set(reference, {
      'receiptNumber': receiptNumber,
      'transactionNumber': receiptNumber,
      'items': items,
      'total': _total,
      'totalSavings': _totalSavings,
      'cash': _cash,
      'change': _change,
      'createdAt': FieldValue.serverTimestamp(),
      'transactionStartedAt': Timestamp.fromDate(startedAt),
      'transactionCompletedAt': Timestamp.fromDate(completedAt),
      'transactionDurationSeconds': durationSeconds,
      'serviceSpeed': serviceSpeed,
      'processedById': user.uid,
      'processedByEmail': user.email ?? '',
      'processedByName': user.displayName ?? user.email ?? 'Cashier',
      'status': 'completed',
      'isViewedByOwner': false,
    });

    await batch.commit();

    return receiptNumber;
  }

  Future<void> _findAndAddByBarcode(
    String barcode,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) async {
    final cleanedBarcode = barcode.trim();

    if (cleanedBarcode.isEmpty) {
      _message('No barcode was detected.', Colors.orange);
      return;
    }

    QueryDocumentSnapshot<Map<String, dynamic>>? matchedProduct;

    for (final product in products) {
      final productBarcode = (product.data()['barcode'] ?? '')
          .toString()
          .trim();

      if (productBarcode == cleanedBarcode) {
        matchedProduct = product;
        break;
      }
    }

    if (matchedProduct == null) {
      await _logAutomaticServiceIssue(
        issueType: 'Barcode Not Recognized',
        severity: 'Moderate',
        description:
            'The POS could not find a product for barcode '
            '$cleanedBarcode.',
        details: {'barcode': cleanedBarcode, 'searchMethod': 'barcode scanner'},
      );

      _message(
        'No product found for barcode $cleanedBarcode. '
        'The issue was automatically recorded.',
        Colors.red,
      );
      return;
    }

    final stock = (matchedProduct.data()['stock'] as num?)?.toInt() ?? 0;

    if (stock <= 0) {
      _message(
        '${(matchedProduct.data()['productName'] ?? 'Product')} is out of stock.',
        Colors.red,
      );
      return;
    }

    _addProduct(matchedProduct);
  }

  Future<void> _openPosBarcodeScanner(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) async {
    final manualController = TextEditingController();
    final scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.itf14,
        BarcodeFormat.codabar,
      ],
    );

    bool processing = false;
    bool detected = false;
    bool scannerIssueLogged = false;

    final scannedBarcode = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> processBarcode(String value) async {
              final cleanedValue = value.trim();

              if (processing || cleanedValue.isEmpty) return;

              setDialogState(() {
                processing = true;
                detected = true;
              });

              try {
                await scannerController.stop();
              } catch (_) {
                // Manual barcode entry must still work even when
                // the browser camera is unavailable or already in use.
              }

              if (!dialogContext.mounted) return;

              Navigator.of(dialogContext).pop(cleanedValue);
            }

            Future<void> closeDialog() async {
              if (processing) return;

              try {
                await scannerController.stop();
              } catch (_) {
                // The scanner may already be stopped or unavailable.
              }

              if (!dialogContext.mounted) return;
              Navigator.of(dialogContext).pop();
            }

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: Color(0xFF1565C0)),
                  SizedBox(width: 10),
                  Text('Scan Product Barcode'),
                ],
              ),
              content: SizedBox(
                width: 620,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 360,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            MobileScanner(
                              controller: scannerController,
                              onDetect: (capture) {
                                if (detected || processing) return;

                                for (final barcode in capture.barcodes) {
                                  final rawValue = barcode.rawValue;

                                  if (rawValue != null &&
                                      rawValue.trim().isNotEmpty) {
                                    processBarcode(rawValue);
                                    break;
                                  }
                                }
                              },
                              errorBuilder: (context, error) {
                                if (!scannerIssueLogged) {
                                  scannerIssueLogged = true;

                                  unawaited(
                                    _logAutomaticServiceIssue(
                                      issueType: 'Scanner Unavailable',
                                      severity: 'Moderate',
                                      description:
                                          'The POS barcode scanner '
                                          'camera was unavailable or '
                                          'already in use.',
                                      details: {
                                        'scannerError': error.toString(),
                                      },
                                    ),
                                  );
                                }

                                return Container(
                                  color: Colors.black87,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(24),
                                  child: Text(
                                    'Camera unavailable or already in use.\n'
                                    'The issue was automatically recorded.\n'
                                    'You can still enter the barcode manually below.\n\n'
                                    '$error',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                );
                              },
                            ),
                            IgnorePointer(
                              child: Center(
                                child: Container(
                                  width: 330,
                                  height: 150,
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
                            if (processing)
                              Container(
                                color: Colors.black45,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: manualController,
                            enabled: !processing,
                            onSubmitted: processBarcode,
                            decoration: const InputDecoration(
                              labelText: 'Manual Barcode Entry',
                              hintText: 'Enter or paste barcode',
                              prefixIcon: Icon(Icons.numbers),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: processing
                                ? null
                                : () => processBarcode(manualController.text),
                            icon: const Icon(Icons.add_shopping_cart),
                            label: const Text('ADD PRODUCT'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: processing ? null : closeDialog,
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );

    // Allow the dialog route and focused TextField to finish
    // their closing animation before disposing their controllers.
    await Future<void>.delayed(const Duration(milliseconds: 500));

    try {
      await scannerController.dispose();
    } catch (_) {
      // Ignore disposal errors from an unavailable browser camera.
    }

    manualController.dispose();

    if (scannedBarcode != null && scannedBarcode.trim().isNotEmpty && mounted) {
      await _findAndAddByBarcode(scannedBarcode.trim(), products);
    }
  }

  Future<void> _printReceipt({
    required String receiptNumber,
    required List<_CartItem> items,
    required double total,
    required double cash,
    required double change,
  }) async {
    final settingsSnapshot = await FirebaseFirestore.instance
        .collection('settings')
        .doc('system')
        .get();

    final settings = settingsSnapshot.data() ?? <String, dynamic>{};

    final storeName = (settings['storeName'] ?? 'EÜ MART').toString();
    final storeAddress = (settings['storeAddress'] ?? '').toString();
    final contactNumber = (settings['contactNumber'] ?? '').toString();
    final receiptFooter =
        (settings['receiptFooter'] ?? 'Thank you for shopping at EÜ MART!')
            .toString();

    final cashier = FirebaseAuth.instance.currentUser;
    final now = DateTime.now();

    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.all(18),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                storeName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (storeAddress.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(
                    storeAddress,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              if (contactNumber.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2),
                  child: pw.Text(
                    contactNumber,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 9),
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Divider(),
              pw.Text(
                'Receipt No.: $receiptNumber',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Cashier: ${cashier?.displayName ?? cashier?.email ?? 'Cashier'}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Text(
                'Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
                '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.Divider(),
              ...items.map(
                (item) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 6),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Text(
                        item.productName,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            item.promoType == 'Buy 1 Take 1'
                                ? '${item.quantity} item(s), pay ${item.chargedQuantity} × PHP ${item.price.toStringAsFixed(2)}'
                                : '${item.quantity} × PHP ${item.price.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            'PHP ${item.subtotal.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              if (_totalSavings > 0)
                _pdfMoneyRow('YOU SAVED', _totalSavings, bold: true),
              _pdfMoneyRow('TOTAL', total, bold: true),
              _pdfMoneyRow('CASH', cash),
              _pdfMoneyRow('CHANGE', change, bold: true),
              pw.SizedBox(height: 12),
              pw.Text(
                receiptFooter,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'EUMART-$receiptNumber.pdf',
      onLayout: (_) async => document.save(),
    );
  }

  pw.Widget _pdfMoneyRow(String label, double value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text('PHP ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  Future<void> _holdTransaction() async {
    if (_cart.isEmpty) {
      _message('The cart is empty.', Colors.orange);
      return;
    }

    final labelController = TextEditingController();

    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hold Transaction'),
          content: SizedBox(
            width: 430,
            child: TextField(
              controller: labelController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Customer name or reference',
                hintText: 'Example: Customer 1 or Maria',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                Navigator.pop(dialogContext, value.trim());
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext, labelController.text.trim());
              },
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('HOLD'),
            ),
          ],
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    labelController.dispose();

    if (label == null) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message('No authenticated user.', Colors.red);
      return;
    }

    setState(() => _processing = true);

    try {
      final reference = FirebaseFirestore.instance
          .collection('held_transactions')
          .doc();

      await reference.set({
        'label': label.isEmpty
            ? 'Held Cart ${DateTime.now().millisecondsSinceEpoch}'
            : label,
        'items': _cart.values.map((item) {
          return {
            'productId': item.productId,
            'productName': item.productName,
            'barcode': item.barcode,
            'unit': item.unit,
            'price': item.price,
            'regularPrice': item.regularPrice,
            'availableStock': item.availableStock,
            'quantity': item.quantity,
            'promoActive': item.promoActive,
            'promoType': item.promoType,
            'promoLabel': item.promoLabel,
          };
        }).toList(),
        'estimatedTotal': _total,
        'estimatedSavings': _totalSavings,
        'transactionStartedAt': Timestamp.fromDate(
          _transactionStartedAt ?? DateTime.now(),
        ),
        'heldById': user.uid,
        'heldByEmail': user.email ?? '',
        'status': 'held',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _cashController.clear();
        _resetTransactionTracking();
      });

      _message('Transaction placed on hold.', Colors.green);
    } catch (error) {
      if (!mounted) return;

      _message('Unable to hold transaction: $error', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _showHeldTransactions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _message('No authenticated user.', Colors.red);
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Held Transactions'),
          content: SizedBox(
            width: 680,
            height: 480,
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('held_transactions')
                  .where('heldById', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load held transactions.\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final held =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                    );

                held.sort((a, b) {
                  final first = _readTimestamp(a.data()['createdAt']);
                  final second = _readTimestamp(b.data()['createdAt']);

                  if (first == null && second == null) {
                    return 0;
                  }
                  if (first == null) return 1;
                  if (second == null) return -1;

                  return second.compareTo(first);
                });

                if (held.isEmpty) {
                  return const Center(
                    child: Text(
                      'No held transactions.',
                      style: TextStyle(color: Colors.grey, fontSize: 17),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: held.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final document = held[index];
                    final data = document.data();

                    final items =
                        data['items'] as List<dynamic>? ?? <dynamic>[];

                    final label = (data['label'] ?? 'Held Cart').toString();

                    final total =
                        (data['estimatedTotal'] as num?)?.toDouble() ?? 0;

                    final createdAt = _readTimestamp(data['createdAt']);

                    return Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          child: Icon(Icons.pause_circle_outline),
                        ),
                        title: Text(
                          label,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${items.length} product(s)'
                          '${createdAt == null ? '' : ' • ${_formatHeldDate(createdAt)}'}',
                        ),
                        trailing: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              '₱${total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final resumed = await _resumeHeldTransaction(
                                  document,
                                  products,
                                );

                                if (!resumed || !dialogContext.mounted) {
                                  return;
                                }

                                Navigator.pop(dialogContext);
                              },
                              child: const Text('RESUME'),
                            ),
                            IconButton(
                              tooltip: 'Delete held transaction',
                              onPressed: () => _deleteHeldTransaction(document),
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatHeldDate(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.month}/${date.day}/${date.year} '
        '$hour:$minute $period';
  }

  Future<bool> _resumeHeldTransaction(
    QueryDocumentSnapshot<Map<String, dynamic>> heldDocument,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) async {
    if (_cart.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Replace Current Cart?'),
            content: const Text(
              'Resuming this transaction will replace '
              'the products currently in the cart.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('REPLACE CART'),
              ),
            ],
          );
        },
      );

      if (replace != true) return false;
    }

    final data = heldDocument.data();
    final rawItems = data['items'] as List<dynamic>? ?? <dynamic>[];

    final productsById = {for (final product in products) product.id: product};

    final restored = <String, _CartItem>{};
    final unavailable = <String>[];

    for (final rawItem in rawItems) {
      if (rawItem is! Map) continue;

      final item = Map<String, dynamic>.from(rawItem);
      final productId = (item['productId'] ?? '').toString();

      final currentProduct = productsById[productId];

      if (currentProduct == null ||
          currentProduct.data()['isActive'] == false) {
        unavailable.add((item['productName'] ?? 'Unknown Product').toString());
        continue;
      }

      final currentData = currentProduct.data();
      final currentStock = (currentData['stock'] as num?)?.toInt() ?? 0;

      final requestedQuantity = (item['quantity'] as num?)?.toInt() ?? 1;

      if (currentStock < requestedQuantity) {
        unavailable.add(
          '${(item['productName'] ?? 'Unknown Product')} '
          '(needs $requestedQuantity, stock $currentStock)',
        );
        continue;
      }

      restored[productId] = _CartItem(
        productId: productId,
        productName: (item['productName'] ?? 'Unknown Product').toString(),
        barcode: (item['barcode'] ?? '').toString(),
        unit: (item['unit'] ?? '').toString(),
        price: (item['price'] as num?)?.toDouble() ?? 0,
        regularPrice:
            (item['regularPrice'] as num?)?.toDouble() ??
            (item['price'] as num?)?.toDouble() ??
            0,
        availableStock: currentStock,
        promoActive: item['promoActive'] == true,
        promoType: (item['promoType'] ?? '').toString(),
        promoLabel: (item['promoLabel'] ?? '').toString(),
        quantity: requestedQuantity,
      );
    }

    if (restored.isEmpty) {
      _message('No held products can currently be resumed.', Colors.red);
      return false;
    }

    final restoredStartedAt =
        _readTimestamp(data['transactionStartedAt']) ??
        _readTimestamp(data['createdAt']) ??
        DateTime.now();

    setState(() {
      _cart
        ..clear()
        ..addAll(restored);
      _cashController.clear();
      _transactionStartedAt = restoredStartedAt;
      _startDurationTimer();
    });

    await heldDocument.reference.delete();

    if (!mounted) return true;

    if (unavailable.isEmpty) {
      _message('Held transaction resumed.', Colors.green);
    } else {
      _message(
        'Transaction resumed, but some products were unavailable: '
        '${unavailable.join(', ')}',
        Colors.orange,
      );
    }

    return true;
  }

  Future<void> _deleteHeldTransaction(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Held Transaction'),
          content: const Text('This will permanently remove the held cart.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await document.reference.delete();

    if (!mounted) return;

    _message('Held transaction deleted.', Colors.green);
  }

  Future<void> _payNow() async {
    if (_cart.isEmpty) {
      _message('The cart is empty.', Colors.orange);
      return;
    }

    if (_cash < _total) {
      _message('Insufficient cash.', Colors.red);
      return;
    }

    setState(() => _processing = true);

    try {
      final items = _cart.values.map((item) => item.copy()).toList();
      final total = _total;
      final cash = _cash;
      final change = _change;
      final completedAt = DateTime.now();
      final startedAt = _transactionStartedAt ?? completedAt;
      final durationSeconds = completedAt
          .difference(startedAt)
          .inSeconds
          .clamp(0, 86400)
          .toInt();
      final serviceSpeed = _serviceSpeedLabel(durationSeconds);

      final receiptNumber = await _saveTransaction(
        startedAt: startedAt,
        completedAt: completedAt,
      );

      if (!mounted) return;

      setState(() {
        _cart.clear();
        _cashController.clear();
        _resetTransactionTracking();
      });

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          final receiptDate = completedAt;
          final dateText =
              '${receiptDate.month.toString().padLeft(2, '0')}/'
              '${receiptDate.day.toString().padLeft(2, '0')}/'
              '${receiptDate.year}';
          final timeText =
              '${receiptDate.hour.toString().padLeft(2, '0')}:'
              '${receiptDate.minute.toString().padLeft(2, '0')}';

          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 30,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
                        decoration: const BoxDecoration(
                          color: Color(0xFF1565C0),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(22),
                            topRight: Radius.circular(22),
                          ),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 76,
                              height: 76,
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(17),
                              ),
                              child: Image.asset(
                                'assets/images/eu_mart_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.storefront_rounded,
                                    size: 45,
                                    color: Color(0xFF1565C0),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'EÜ MART',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'SALES RECEIPT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.16),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 17,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'TRANSACTION COMPLETE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 22),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF6F8FB),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Receipt No.',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Flexible(
                                        child: Text(
                                          receiptNumber,
                                          textAlign: TextAlign.right,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                            color: Color(0xFF172033),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Date / Time',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '$dateText  •  $timeText',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF172033),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Text(
                                          'Transaction Time',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.black54,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        '${durationSeconds ~/ 60}m ${durationSeconds % 60}s  •  $serviceSpeed',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: serviceSpeed == 'Long Delay'
                                              ? Colors.red
                                              : serviceSpeed == 'Minor Delay'
                                              ? Colors.orange
                                              : Colors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 18),
                            const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'ITEM',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    'QTY',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: 76,
                                  child: Text(
                                    'AMOUNT',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 10),
                            ...items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 11),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.productName,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF172033),
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 42,
                                      child: Text(
                                        '${item.quantity}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 76,
                                      child: Text(
                                        '₱${item.subtotal.toStringAsFixed(2)}',
                                        textAlign: TextAlign.right,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(height: 1),
                            const SizedBox(height: 13),
                            if (_totalSavings > 0) ...[
                              _receiptRow('You Saved', _totalSavings),
                              const SizedBox(height: 7),
                            ],
                            _receiptRow('Total', total),
                            const SizedBox(height: 7),
                            _receiptRow('Cash', cash),
                            const SizedBox(height: 7),
                            _receiptRow('Change', change),
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'TOTAL',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1B5E20),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₱${total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1B5E20),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Thank you for shopping with EÜ MART!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF172033),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Please come again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      await _printReceipt(
                                        receiptNumber: receiptNumber,
                                        items: items,
                                        total: total,
                                        cash: cash,
                                        change: change,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.print_outlined,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'PRINT / PDF',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF1565C0),
                                      side: const BorderSide(
                                        color: Color(0xFF1565C0),
                                      ),
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'DONE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1565C0),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      minimumSize: const Size(0, 48),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } on FirebaseException catch (error, stackTrace) {
      debugPrint('POS Firebase error: ${error.code} - ${error.message}');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      _message(
        error.code == 'permission-denied'
            ? 'Permission denied. Check the Firestore rules for '
                  'transactions and product stock updates.'
            : 'Unable to complete transaction: '
                  '${error.message ?? error.code}',
        Colors.red,
      );
    } catch (error, stackTrace) {
      debugPrint('POS payment error: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      final message = error.toString().replaceFirst('Exception: ', '');

      _message(
        message.isEmpty ? 'Unable to complete the transaction.' : message,
        Colors.red,
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Widget _receiptRow(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            '₱${value.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _productPanel(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allProducts,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _query = value.trim().toLowerCase();
                    _aiMatchedProductIds.clear();
                    _aiSearchMessage = '';
                  });
                },
                onSubmitted: (_) => _runAiSearch(allProducts),
                decoration: InputDecoration(
                  hintText:
                      'Search name, barcode, typo, or natural description',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                              _aiMatchedProductIds.clear();
                              _aiSearchMessage = '';
                            });
                          },
                          icon: const Icon(Icons.clear),
                        ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 17,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDDE6F1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFDDE6F1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFF1565C0),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _openPosBarcodeScanner(allProducts),
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('SCAN BARCODE'),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _aiSearching
                    ? null
                    : () => _runAiSearch(allProducts),
                icon: _aiSearching
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.auto_awesome),
                label: Text(_aiSearching ? 'SEARCHING...' : 'AI SEARCH'),
              ),
            ),
          ],
        ),
        if (_aiSearchMessage.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _aiSearchMessage,
              style: const TextStyle(
                color: Color(0xFF1565C0),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('No matching products found.'))
              : GridView.builder(
                  itemCount: products.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 280,
                    mainAxisExtent: 180,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                  ),
                  itemBuilder: (context, index) {
                    final document = products[index];
                    final data = document.data();
                    final name = (data['productName'] ?? 'Unknown Product')
                        .toString();
                    final price =
                        (data['sellingPrice'] as num?)?.toDouble() ?? 0;
                    final stock = (data['stock'] as num?)?.toInt() ?? 0;

                    return _PosProductCard(
                      name: name,
                      price: price,
                      stock: stock,
                      highlighted: _aiMatchedProductIds.contains(document.id),
                      onTap: stock > 0 ? () => _addProduct(document) : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _cartPanel(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFBFDFF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE2EAF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A16395C),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                        ),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.shopping_cart_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shopping Cart',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF172033),
                          ),
                        ),
                        Text(
                          'Review items before payment',
                          style: TextStyle(
                            color: Color(0xFF7D8796),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_transactionStartedAt != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 17,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        _formattedElapsedTime,
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 500),
                      tween: Tween(begin: 0.85, end: 1),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(scale: value, child: child);
                      },
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shopping_cart_checkout_rounded,
                            size: 48,
                            color: Color(0xFFB6C4D5),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Your cart is empty',
                            style: TextStyle(
                              color: Color(0xFF657386),
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Select a product to begin.',
                            style: TextStyle(
                              color: Color(0xFF9AA5B3),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _cart.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _cart.values.elementAt(index);

                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF8FBFF), Colors.white],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE4ECF5)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (item.promoActive)
                                    Text(
                                      item.promoType == 'Buy 1 Take 1'
                                          ? 'Buy 1 Take 1 • Pay for ${item.chargedQuantity}'
                                          : '${item.promoLabel.isEmpty ? item.promoType : item.promoLabel} • ₱${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  if (item.savings > 0)
                                    Text(
                                      'Saved ₱${item.savings.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        color: Colors.green,
                                        fontSize: 11,
                                      ),
                                    ),
                                  Text(
                                    '₱${item.subtotal.toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => _decrease(item),
                              icon: const Icon(
                                Icons.remove_circle,
                                color: Colors.red,
                              ),
                            ),
                            Text('${item.quantity}'),
                            IconButton(
                              onPressed: () => _increase(item),
                              icon: const Icon(
                                Icons.add_circle,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          const Divider(height: 28),
          if (_totalSavings > 0) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.savings_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'CUSTOMER SAVINGS',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    '₱${_totalSavings.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEAF3FF), Color(0xFFF5F9FF)],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFD7E7FA)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'TOTAL AMOUNT',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF53657C),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                TweenAnimationBuilder<double>(
                  key: ValueKey<double>(_total),
                  duration: const Duration(milliseconds: 320),
                  tween: Tween(begin: 0.92, end: 1),
                  curve: Curves.easeOutBack,
                  builder: (context, value, child) {
                    return Transform.scale(scale: value, child: child);
                  },
                  child: Text(
                    '₱${_total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Color(0xFF0F8A4B),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cashController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Cash Received',
              prefixIcon: const Icon(
                Icons.payments_outlined,
                color: Color(0xFF1565C0),
              ),
              filled: true,
              fillColor: const Color(0xFFF7FAFE),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFDDE6F1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFF1565C0),
                  width: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Change',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '₱${_change.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 19,
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _processing ? null : _holdTransaction,
                  icon: const Icon(Icons.pause_circle_outline),
                  label: const Text('HOLD'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _processing
                      ? null
                      : () => _showHeldTransactions(products),
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('RESUME'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _processing ? null : _payNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF9DB7D4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.payment_rounded),
              label: Text(
                _processing ? 'PROCESSING...' : 'PAY NOW',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
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

        final products = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );

        products.sort((a, b) {
          final first = (a.data()['productName'] ?? '')
              .toString()
              .toLowerCase();
          final second = (b.data()['productName'] ?? '')
              .toString()
              .toLowerCase();
          return first.compareTo(second);
        });

        final activeProducts = products.where((document) {
          return document.data()['isActive'] != false;
        }).toList();

        final filtered = activeProducts.where(_matches).toList();

        return Container(
          color: const Color(0xFFF2F6FC),
          padding: const EdgeInsets.all(22),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 980) {
                return Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _productPanel(filtered, activeProducts),
                    ),
                    const SizedBox(width: 22),
                    SizedBox(width: 420, child: _cartPanel(activeProducts)),
                  ],
                );
              }

              return Column(
                children: [
                  Expanded(child: _productPanel(filtered, activeProducts)),
                  const SizedBox(height: 18),
                  SizedBox(height: 500, child: _cartPanel(activeProducts)),
                ],
              );
            },
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _searchController.dispose();
    _cashController.dispose();
    super.dispose();
  }
}

class _PosProductCard extends StatefulWidget {
  final String name;
  final double price;
  final int stock;
  final bool highlighted;
  final VoidCallback? onTap;

  const _PosProductCard({
    required this.name,
    required this.price,
    required this.stock,
    required this.highlighted,
    required this.onTap,
  });

  @override
  State<_PosProductCard> createState() => _PosProductCardState();
}

class _PosProductCardState extends State<_PosProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final available = widget.stock > 0;
    final accent = widget.highlighted
        ? const Color(0xFF7B1FA2)
        : const Color(0xFF1565C0);

    return MouseRegion(
      cursor: available
          ? SystemMouseCursors.click
          : SystemMouseCursors.forbidden,
      onEnter: (_) {
        if (available) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (_hovered) {
          setState(() => _hovered = false);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -6 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              accent.withValues(alpha: widget.highlighted ? 0.08 : 0.035),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.highlighted
                ? accent.withValues(alpha: 0.55)
                : const Color(0xFFE1E9F3),
            width: widget.highlighted ? 1.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x2416385A)
                  : const Color(0x1016385A),
              blurRadius: _hovered ? 22 : 12,
              offset: Offset(0, _hovered ? 10 : 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Icon(
                          widget.highlighted
                              ? Icons.auto_awesome_rounded
                              : Icons.inventory_2_outlined,
                          color: accent,
                          size: 23,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: available
                              ? const Color(0xFFEAF8F0)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          available
                              ? '${widget.stock} in stock'
                              : 'Out of stock',
                          style: TextStyle(
                            color: available
                                ? const Color(0xFF168653)
                                : const Color(0xFFC62828),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 13),
                  Text(
                    widget.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1B2738),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      height: 1.3,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '₱${widget.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFF0F8A4B),
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: available ? accent : const Color(0xFFCCD5E0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.white,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CartItem {
  final String productId;
  final String productName;
  final String barcode;
  final String unit;
  final double price;
  final double regularPrice;
  final int availableStock;
  final bool promoActive;
  final String promoType;
  final String promoLabel;

  int quantity;

  _CartItem({
    required this.productId,
    required this.productName,
    required this.barcode,
    required this.unit,
    required this.price,
    required this.regularPrice,
    required this.availableStock,
    required this.promoActive,
    required this.promoType,
    required this.promoLabel,
    this.quantity = 1,
  });

  int get chargedQuantity {
    if (promoActive && promoType == 'Buy 1 Take 1') {
      return (quantity / 2).ceil();
    }

    return quantity;
  }

  double get subtotal => price * chargedQuantity;

  double get savings {
    final regularTotal = regularPrice * quantity;
    return regularTotal - subtotal;
  }

  _CartItem copy() {
    return _CartItem(
      productId: productId,
      productName: productName,
      barcode: barcode,
      unit: unit,
      price: price,
      regularPrice: regularPrice,
      availableStock: availableStock,
      promoActive: promoActive,
      promoType: promoType,
      promoLabel: promoLabel,
      quantity: quantity,
    );
  }
}
