// -----------------------------------------------------------------------------
// Module overview: Owner product and inventory management including product creation, editing, stock data, pricing, and expiration information.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'dart:convert';
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';
import 'restock_suggestions_screen.dart';
import 'stock_movement_screen.dart';
import 'supplier_management_screen.dart';
import 'barcode_generator_screen.dart';
import 'promotions_management_screen.dart';

// Single Inventory Management workspace. All original product/stock functions
// remain in their existing widgets; the sidebar needs only this one entry.
class ProductsInventoryScreen extends StatefulWidget {
  const ProductsInventoryScreen({super.key});

  @override
  State<ProductsInventoryScreen> createState() =>
      _UnifiedInventoryWorkspaceState();
}

class _UnifiedInventoryWorkspaceState extends State<ProductsInventoryScreen> {
  int _section = 0;

  static const _sections = <({String name, IconData icon})>[
    (name: 'Products', icon: Icons.inventory_2_outlined),
    (name: 'Stock Movements', icon: Icons.swap_horiz_outlined),
    (name: 'Restock', icon: Icons.low_priority_outlined),
    (name: 'Suppliers', icon: Icons.local_shipping_outlined),
    (name: 'Barcodes', icon: Icons.qr_code_rounded),
    (name: 'Promotions', icon: Icons.local_offer_outlined),
  ];

  // Visited tabs remain mounted; their search, pagination and loaded data survive
  // a tab switch. Unvisited tabs are not created until opened.
  final Set<int> _visitedSections = <int>{0};

  Widget _contentFor(int section) => switch (section) {
    0 => const _ProductsCatalogScreen(),
    1 => const StockMovementScreen(),
    2 => const RestockSuggestionsScreen(),
    3 => const SupplierManagementScreen(),
    4 => const BarcodeGeneratorScreen(),
    5 => const PromotionsManagementScreen(),
    _ => const SizedBox.shrink(),
  };

  void _openSection(int index) {
    if (_section == index) return;
    setState(() {
      _visitedSections.add(index);
      _section = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1559A6);
    const ink = Color(0xFF243247);
    const gray = Color(0xFFF3F5F8);

    return ColoredBox(
      color: gray,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Inventory Management',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Products, stock, suppliers and promotions in one workspace.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF67758A)),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (var index = 0; index < _sections.length; index++)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: OutlinedButton.icon(
                            onPressed: () => _openSection(index),
                            icon: Icon(_sections[index].icon, size: 17),
                            label: Text(_sections[index].name),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _section == index
                                  ? Colors.white
                                  : ink,
                              backgroundColor: _section == index
                                  ? navy
                                  : Colors.white,
                              side: BorderSide(
                                color: _section == index
                                    ? navy
                                    : const Color(0xFFD7DEE9),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 15,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _section,
              children: [
                for (var index = 0; index < _sections.length; index++)
                  _visitedSections.contains(index)
                      ? TickerMode(
                          enabled: _section == index,
                          child: _contentFor(index),
                        )
                      : const SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _InventoryEmptyState extends StatelessWidget {
  // Handles the inventory empty state logic used by this module.
  const _InventoryEmptyState();

  @override
  Widget build(BuildContext context) {
    // Handles the center logic used by this module.
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.88, end: 1),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 60,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No products found',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try another search or add a new product.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}

// Private UI/data helper used only inside this module.
class _InventoryProductCard extends StatefulWidget {
  final String productName;
  final String category;
  final String unit;
  final String barcode;
  final double price;
  final int stock;
  final int lowStockThreshold;
  final bool active;
  final bool expired;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // Handles the inventory product card logic used by this module.
  const _InventoryProductCard({
    required this.productName,
    required this.category,
    required this.unit,
    required this.barcode,
    required this.price,
    required this.stock,
    required this.lowStockThreshold,
    required this.active,
    required this.expired,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_InventoryProductCard> createState() => _InventoryProductCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _InventoryProductCardState extends State<_InventoryProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lowStock =
        widget.stock > 0 && widget.stock <= widget.lowStockThreshold;

    // Handles the mouse region logic used by this module.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFFBFDFF)],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _hovered
                  ? const Color(0xFFB9D6F8)
                  : const Color(0xFFE1E9F3),
            ),
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
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.inventory_2_outlined,
                  color: Color(0xFF1565C0),
                  size: 27,
                ),
              ),
              // Handles the sized box logic used by this module.
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.productName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF172033),
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: widget.active
                                ? const Color(0xFF1565C0)
                                : const Color(0xFFF1F3F5),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.expired
                                ? 'EXPIRED'
                                : (widget.active ? 'ACTIVE' : 'INACTIVE'),
                            style: TextStyle(
                              color: widget.active
                                  ? const Color(0xFF1565C0)
                                  : Colors.grey,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 5),
                    Text(
                      '${widget.category} • ${widget.unit}',
                      style: const TextStyle(
                        color: Color(0xFF7A8494),
                        fontSize: 12,
                      ),
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 4),
                    Text(
                      widget.barcode.trim().isEmpty
                          ? 'No barcode'
                          : 'Barcode: ${widget.barcode}',
                      style: const TextStyle(
                        color: Color(0xFF8C97A6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              // Handles the sized box logic used by this module.
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₱${widget.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF1559A6),
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: lowStock
                          ? const Color(0xFFEAF3FF)
                          : const Color(0xFFDCEBFF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Stock: ${widget.stock}',
                      style: TextStyle(
                        color: const Color(0xFF1559A6),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              // Handles the sized box logic used by this module.
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Edit',
                onPressed: widget.onEdit,
                icon: const Icon(Icons.edit_outlined, color: Color(0xFF1565C0)),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: widget.onDelete,
                icon: const Icon(
                  Icons.delete_outline,
                  color: const Color(0xFF1565C0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Screen widget for owner product and inventory management including product creation, editing, stock data, pricing, and expiration information.
class _ProductsCatalogScreen extends StatefulWidget {
  // Handles the products inventory screen logic used by this module.
  const _ProductsCatalogScreen({super.key});

  @override
  State<_ProductsCatalogScreen> createState() => _ProductsCatalogScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _ProductsCatalogScreenState extends State<_ProductsCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';

  static const int _productsPerPage = 25;
  int _currentPage = 0;
  int _lowStockThreshold = 10;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _thresholdSubscription;

  // ------------------------------------------------------------
  // SAFE FIRESTORE VALUE CONVERTERS
  // ------------------------------------------------------------

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value.trim()) ?? 0;
    }

    return 0;
  }

  // Reads and normalizes int from stored data.
  int _readInt(dynamic value) {
    if (value is num) return value.toInt();

    if (value is String) {
      return int.tryParse(value.trim()) ?? 0;
    }

    return 0;
  }

  // Normalizes supported Firestore/date values into a Dart DateTime for consistent comparisons.
  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Formats a date into a consistent display value for the interface.
  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  // ------------------------------------------------------------
  // CSV IMPORT
  // ------------------------------------------------------------

  Future<void> _importProductsFromCsv() async {
    bool importDialogOpen = false;

    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;

      if (bytes == null) {
        // Handles the exception logic used by this module.
        throw Exception('Unable to read the selected CSV file.');
      }

      final csvText = utf8.decode(bytes);
      final List<List<dynamic>> rows = csv.decode(csvText);

      if (rows.isEmpty) {
        // Handles the exception logic used by this module.
        throw Exception('The CSV file is empty.');
      }

      final headers = rows.first
          .map(
            (value) => value
                .toString()
                .replaceFirst('\uFEFF', '')
                .trim()
                .toLowerCase(),
          )
          .toList();

      const requiredHeaders = [
        'productname',
        'category',
        'buyingprice',
        'sellingprice',
        'stock',
      ];

      for (final header in requiredHeaders) {
        if (!headers.contains(header)) {
          // Handles the exception logic used by this module.
          throw Exception('Missing required column: $header');
        }
      }

      // Handles the value at logic used by this module.
      String valueAt(List<dynamic> row, String header) {
        final index = headers.indexOf(header);
        if (index < 0 || index >= row.length) return '';
        return row[index].toString().trim();
      }

      if (!mounted) return;

      importDialogOpen = true;
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) {
          // Handles the alert dialog logic used by this module.
          return const AlertDialog(
            content: SizedBox(
              width: 360,
              child: Row(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Expanded(
                    child: Text(
                      'Importing products...\nPlease wait and do not close this window.',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );

      final productsRef = FirebaseFirestore.instance.collection('products');

      // Load existing products once. This avoids doing one Firestore query
      // for every CSV row, which made large imports appear to freeze.
      final existingSnapshot = await productsRef.get();

      final existingBarcodes = <String>{
        for (final document in existingSnapshot.docs)
          if ((document.data()['barcode'] ?? '').toString().trim().isNotEmpty)
            (document.data()['barcode'] ?? '').toString().trim().toLowerCase(),
      };

      // Also track barcodes encountered inside this CSV so duplicate rows
      // in the same file are skipped safely.
      final csvBarcodes = <String>{};

      int imported = 0;
      int skipped = 0;
      final skippedReasons = <String>[];
      void skipRow(int row, String reason) {
        skipped++;
        if (skippedReasons.length < 20) {
          skippedReasons.add('Row $row: $reason');
        }
      }

      WriteBatch batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;

      // Handles the commit batch if needed logic used by this module.
      Future<void> commitBatchIfNeeded({bool force = false}) async {
        if (batchCount == 0) return;
        if (!force && batchCount < 350) return;

        await batch.commit();
        batch = FirebaseFirestore.instance.batch();
        batchCount = 0;
      }

      for (var index = 1; index < rows.length; index++) {
        final row = rows[index];

        if (row.every((value) => value.toString().trim().isEmpty)) {
          continue;
        }

        final productName = valueAt(row, 'productname');
        final category = valueAt(row, 'category');
        final buyingPrice = double.tryParse(valueAt(row, 'buyingprice'));
        final sellingPrice = double.tryParse(valueAt(row, 'sellingprice'));
        final stock = int.tryParse(valueAt(row, 'stock'));

        // Never silently import invalid money, inventory or empty identifiers.
        if (productName.isEmpty || category.isEmpty) {
          skipRow(index + 1, 'Product name and category are required.');
          continue;
        }
        if (buyingPrice == null ||
            !buyingPrice.isFinite ||
            buyingPrice < 0 ||
            sellingPrice == null ||
            !sellingPrice.isFinite ||
            sellingPrice <= 0) {
          skipRow(
            index + 1,
            'Buying price must be non-negative and selling price must be positive.',
          );
          continue;
        }
        if (stock == null || stock < 0) {
          skipRow(index + 1, 'Stock must be a non-negative whole number.');
          continue;
        }
        final expirationText = valueAt(row, 'expirationdate');
        final expirationDate = expirationText.isEmpty
            ? null
            : DateTime.tryParse(expirationText);
        if (expirationText.isNotEmpty) {
          // Require ISO YYYY-MM-DD to avoid accepting ambiguous dates or overflow.
          if (expirationDate == null ||
              !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(expirationText) ||
              expirationDate.toIso8601String().substring(0, 10) !=
                  expirationText) {
            skipRow(index + 1, 'Invalid expiration date. Use YYYY-MM-DD.');
            continue;
          }
        }

        final barcode = valueAt(row, 'barcode');

        if (barcode.isNotEmpty) {
          if (existingBarcodes.contains(barcode.toLowerCase()) ||
              csvBarcodes.contains(barcode.toLowerCase())) {
            skipRow(index + 1, 'Duplicate barcode: $barcode');
            continue;
          }

          csvBarcodes.add(barcode.toLowerCase());
        }

        final document = productsRef.doc();

        batch.set(document, {
          'productName': productName,
          'barcode': barcode,
          'category': category,
          'brand': valueAt(row, 'brand'),
          'buyingPrice': buyingPrice,
          'sellingPrice': sellingPrice,
          'stock': stock,
          'supplier': valueAt(row, 'supplier'),
          'unit': valueAt(row, 'unit'),
          'expirationDate': expirationDate == null
              ? null
              : Timestamp.fromDate(expirationDate),
          'imagePath': valueAt(row, 'imagepath'),
          'promoActive': false,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        imported++;
        batchCount++;

        // Stay below Firestore's batch-write ceiling and commit in chunks.
        await commitBatchIfNeeded();
      }

      // Handles the commit batch if needed logic used by this module.
      await commitBatchIfNeeded(force: true);

      if (imported > 0) {
        await AuditLogService.log(
          action: 'Import Products',
          module: 'Products',
          description:
              'Imported $imported product(s) from CSV. '
              '$skipped row(s) were skipped.',
          targetName: file.name,
          details: {
            'importedCount': imported,
            'skippedCount': skipped,
            'skippedExamples': skippedReasons,
            'fileName': file.name,
          },
        );
      }

      if (!mounted) return;

      if (importDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        importDialogOpen = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV import complete: $imported imported, '
                    '$skipped skipped. ' +
                (skippedReasons.isEmpty
                    ? ''
                    : skippedReasons.take(3).join(' | ')),
          ),
          backgroundColor: imported > 0
              ? const Color(0xFF1565C0)
              : const Color(0xFF1565C0),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      if (importDialogOpen) {
        Navigator.of(context, rootNavigator: true).pop();
        importDialogOpen = false;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to import CSV: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: const Color(0xFF1565C0),
        ),
      );
    }
  }

  // Suggestions come from existing products, so the owner can reuse values
  // without maintaining a separate Firestore categories/brands collection.
  List<String> _existingFieldValues(
    String field, {
    List<String> defaults = const [],
  }) {
    final unique = <String, String>{};
    for (final value in defaults) {
      final clean = value.trim();
      if (clean.isNotEmpty)
        unique.putIfAbsent(clean.toLowerCase(), () => clean);
    }
    for (final document in _allProducts) {
      final clean = (document.data()[field] ?? '').toString().trim();
      if (clean.isNotEmpty)
        unique.putIfAbsent(clean.toLowerCase(), () => clean);
    }
    return unique.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  // Searchable dropdown: choose an existing value OR type a new one.
  // The existing form controller remains the source of truth when saving.
  Widget _suggestionField({
    required TextEditingController controller,
    required String label,
    required List<String> options,
    required double width,
    String? Function(String?)? validator,
  }) {
    return SizedBox(
      width: width,
      child: Autocomplete<String>(
        initialValue: TextEditingValue(text: controller.text),
        optionsBuilder: (textEditingValue) {
          final typed = textEditingValue.text.trim().toLowerCase();
          return options
              .where(
                (value) => typed.isEmpty || value.toLowerCase().contains(typed),
              )
              .take(15);
        },
        onSelected: (selection) => controller.text = selection,
        fieldViewBuilder:
            (context, fieldController, focusNode, onFieldSubmitted) {
              return TextFormField(
                controller: fieldController,
                focusNode: focusNode,
                validator: validator,
                onChanged: (value) => controller.text = value,
                decoration: InputDecoration(
                  labelText: label,
                  helperText: 'Choose a suggestion or type a new value',
                  suffixIcon: IconButton(
                    tooltip: 'Show suggestions',
                    icon: const Icon(Icons.arrow_drop_down),
                    onPressed: () => focusNode.requestFocus(),
                  ),
                  border: const OutlineInputBorder(),
                ),
              );
            },
      ),
    );
  }

  // ------------------------------------------------------------
  // ADD / EDIT PRODUCT DIALOG
  // ------------------------------------------------------------

  Future<void> _showProductDialog({
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final data = document?.data() ?? <String, dynamic>{};

    final formKey = GlobalKey<FormState>();

    final productNameController = TextEditingController(
      text: (data['productName'] ?? '').toString(),
    );

    final barcodeController = TextEditingController(
      text: (data['barcode'] ?? '').toString(),
    );

    final categoryController = TextEditingController(
      text: (data['category'] ?? '').toString(),
    );

    final brandController = TextEditingController(
      text: (data['brand'] ?? '').toString(),
    );

    final buyingPriceController = TextEditingController(
      text: data['buyingPrice'] == null
          ? ''
          : _readDouble(data['buyingPrice']).toString(),
    );

    final sellingPriceController = TextEditingController(
      text: data['sellingPrice'] == null
          ? ''
          : _readDouble(data['sellingPrice']).toString(),
    );

    final stockController = TextEditingController(
      text: data['stock'] == null ? '' : _readInt(data['stock']).toString(),
    );

    final supplierController = TextEditingController(
      text: (data['supplier'] ?? '').toString(),
    );

    final unitController = TextEditingController(
      text: (data['unit'] ?? '').toString(),
    );

    DateTime? expirationDate = _readDate(data['expirationDate']);

    bool isActive = data['isActive'] != false;
    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Handles the stateful builder logic used by this module.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Validates and saves product data to the application data store.
            Future<void> saveProduct() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => saving = true);

              try {
                final enteredBarcode = barcodeController.text.trim();

                // ------------------------------------------------
                // BARCODE DUPLICATE CHECK
                // ------------------------------------------------

                if (enteredBarcode.isNotEmpty) {
                  final duplicateQuery = await FirebaseFirestore.instance
                      .collection('products')
                      .where('barcode', isEqualTo: enteredBarcode)
                      .limit(2)
                      .get();

                  final duplicateExists = duplicateQuery.docs.any(
                    (existingDocument) => existingDocument.id != document?.id,
                  );

                  if (duplicateExists) {
                    if (!dialogContext.mounted) return;

                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      // Handles the snack bar logic used by this module.
                      const SnackBar(
                        content: Text(
                          'This barcode is already assigned to another product.',
                        ),
                        backgroundColor: const Color(0xFF1565C0),
                      ),
                    );

                    setDialogState(() => saving = false);
                    return;
                  }
                }

                // ------------------------------------------------
                // PARSE NEW VALUES
                // ------------------------------------------------

                final newBuyingPrice = double.parse(
                  buyingPriceController.text.trim(),
                );

                final newSellingPrice = double.parse(
                  sellingPriceController.text.trim(),
                );

                final newStock = int.parse(stockController.text.trim());

                final productName = productNameController.text.trim();

                // ------------------------------------------------
                // PRODUCT DATA
                // ------------------------------------------------

                final productData = <String, dynamic>{
                  'productName': productName,
                  'barcode': enteredBarcode,
                  'category': categoryController.text.trim(),
                  'brand': brandController.text.trim(),
                  'buyingPrice': newBuyingPrice,
                  'sellingPrice': newSellingPrice,
                  'stock': newStock,
                  'supplier': supplierController.text.trim(),
                  'unit': unitController.text.trim(),
                  'expirationDate': expirationDate == null
                      ? null
                      : Timestamp.fromDate(expirationDate!),
                  'isActive': isActive,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                // =================================================
                // ADD NEW PRODUCT
                // =================================================

                if (document == null) {
                  productData['createdAt'] = FieldValue.serverTimestamp();

                  productData['imagePath'] = '';
                  productData['promoActive'] = false;
                  productData['isActive'] = isActive;

                  final createdDocument = await FirebaseFirestore.instance
                      .collection('products')
                      .add(productData);

                  await AuditLogService.productCreated(
                    productId: createdDocument.id,
                    productName: productName,
                  );
                }
                // =================================================
                // EDIT EXISTING PRODUCT
                // =================================================
                else {
                  final oldStock = _readInt(data['stock']);
                  final stockRequestedChange = newStock != oldStock;
                  final db = FirebaseFirestore.instance;
                  final reminderReference = db
                      .collection('price_update_reminders')
                      .doc();
                  final movementReference = db
                      .collection('stock_movements')
                      .doc();
                  final auditReference = db.collection('audit_logs').doc();

                  // Check latest inventory atomically to prevent an old edit
                  // form from overwriting a recent POS sale or stock movement.
                  await db.runTransaction<void>((transaction) async {
                    final latest = await transaction.get(document.reference);
                    if (!latest.exists) {
                      throw Exception('Product was deleted. Reload inventory.');
                    }
                    final latestData = latest.data() ?? <String, dynamic>{};
                    final latestStock = _readInt(latestData['stock']);
                    if (stockRequestedChange && latestStock != oldStock) {
                      throw Exception(
                        'Stock changed from $oldStock to $latestStock while editing. '
                        'Reload the product and re-enter the adjustment.',
                      );
                    }
                    // Do NOT write a stale stock value if the owner only edits
                    // a price, category, expiration date or other metadata.
                    final safeProductData = Map<String, dynamic>.from(
                      productData,
                    );
                    if (!stockRequestedChange) safeProductData.remove('stock');
                    transaction.update(document.reference, safeProductData);

                    final currentBuying = _readDouble(
                      latestData['buyingPrice'],
                    );
                    final currentSelling = _readDouble(
                      latestData['sellingPrice'],
                    );
                    if (currentBuying != newBuyingPrice ||
                        currentSelling != newSellingPrice) {
                      transaction.set(reminderReference, {
                        'productId': document.id,
                        'productName': productName,
                        'oldBuyingPrice': currentBuying,
                        'newBuyingPrice': newBuyingPrice,
                        'oldSellingPrice': currentSelling,
                        'newSellingPrice': newSellingPrice,
                        'currentSellingPrice': newSellingPrice,
                        'status': 'Pending Review',
                        'type': 'Price Update Reminder',
                        'source': 'Products',
                        'recipientRole': 'Owner',
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });
                    }
                    if (stockRequestedChange) {
                      final delta = newStock - latestStock;
                      transaction.set(movementReference, {
                        'productId': document.id,
                        'productName': productName,
                        'movementType': delta > 0
                            ? 'Stock Increase'
                            : 'Stock Decrease',
                        'quantity': delta.abs(),
                        'direction': delta > 0 ? 'increase' : 'decrease',
                        'previousStock': latestStock,
                        'newStock': newStock,
                        'supplierId': '',
                        'supplier': '',
                        'buyingCost': 0.0,
                        'reason':
                            'Stock edited directly in Products & Inventory',
                        'performedById':
                            FirebaseAuth.instance.currentUser?.uid ?? '',
                        'performedByEmail':
                            FirebaseAuth.instance.currentUser?.email ?? '',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                      transaction.set(auditReference, {
                        'action': 'Stock Movement',
                        'module': 'Inventory',
                        'description':
                            'Product stock edited: $productName, $latestStock to $newStock',
                        'performedById':
                            FirebaseAuth.instance.currentUser?.uid ?? '',
                        'performedByEmail':
                            FirebaseAuth.instance.currentUser?.email ?? '',
                        'createdAt': FieldValue.serverTimestamp(),
                      });
                    }
                  });

                  // ------------------------------------------------
                  // PRODUCT AUDIT LOG
                  // ------------------------------------------------

                  await AuditLogService.productUpdated(
                    productId: document.id,
                    productName: productName,
                  );

                  // The stock movement and stock audit record were committed
                  // atomically above; do not insert a duplicate audit event.
                }

                if (!dialogContext.mounted) return;

                Navigator.pop(dialogContext, true);
              } catch (error) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Unable to save product: $error'),
                    backgroundColor: const Color(0xFF1565C0),
                  ),
                );

                setDialogState(() => saving = false);
              }
            }

            // Handles the alert dialog logic used by this module.
            return AlertDialog(
              title: Text(
                document == null ? 'Add Actual Product' : 'Edit Product',
              ),
              content: SizedBox(
                width: 680,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _dialogField(
                          controller: productNameController,
                          label: 'Product Name',
                          width: 310,
                          validator: _requiredValidator,
                        ),
                        _dialogField(
                          controller: barcodeController,
                          label: 'Manufacturer Barcode (optional)',
                          width: 310,
                        ),
                        _suggestionField(
                          controller: categoryController,
                          label: 'Category',
                          width: 310,
                          options: _existingFieldValues('category'),
                          validator: _requiredValidator,
                        ),
                        _suggestionField(
                          controller: brandController,
                          label: 'Brand (optional)',
                          width: 310,
                          options: _existingFieldValues('brand'),
                        ),
                        _dialogField(
                          controller: buyingPriceController,
                          label: 'Buying Price',
                          width: 200,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _numberValidator,
                        ),
                        _dialogField(
                          controller: sellingPriceController,
                          label: 'Selling Price',
                          width: 200,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _positivePriceValidator,
                        ),
                        _dialogField(
                          controller: stockController,
                          label: 'Stock',
                          width: 200,
                          keyboardType: TextInputType.number,
                          validator: _integerValidator,
                        ),
                        _suggestionField(
                          controller: supplierController,
                          label: 'Supplier',
                          width: 310,
                          options: _existingFieldValues('supplier'),
                        ),
                        _suggestionField(
                          controller: unitController,
                          label: 'Unit (piece, kg, liter, pack)',
                          width: 310,
                          options: _existingFieldValues(
                            'unit',
                            defaults: const [
                              'piece',
                              'pack',
                              'box',
                              'bottle',
                              'sachet',
                              'kg',
                              'liter',
                              'can',
                              'set',
                            ],
                          ),
                          validator: _requiredValidator,
                        ),
                        SizedBox(
                          width: 310,
                          child: OutlinedButton.icon(
                            onPressed: saving
                                ? null
                                : () async {
                                    final selected = await showDatePicker(
                                      context: context,
                                      initialDate:
                                          expirationDate ?? DateTime.now(),
                                      firstDate: DateTime.now().subtract(
                                        // Handles the duration logic used by this module.
                                        const Duration(days: 365),
                                      ),
                                      lastDate: DateTime.now().add(
                                        // Handles the duration logic used by this module.
                                        const Duration(days: 3650),
                                      ),
                                    );

                                    if (selected != null) {
                                      setDialogState(() {
                                        expirationDate = selected;
                                      });
                                    }
                                  },
                            icon: const Icon(Icons.event),
                            label: Text(
                              expirationDate == null
                                  ? 'Set Expiration Date'
                                  : 'Expiration: ${_formatDate(expirationDate)}',
                            ),
                          ),
                        ),
                        if (expirationDate != null)
                          TextButton.icon(
                            onPressed: saving
                                ? null
                                : () {
                                    setDialogState(() {
                                      expirationDate = null;
                                    });
                                  },
                            icon: const Icon(Icons.clear),
                            label: const Text('Remove Expiration'),
                          ),
                        SizedBox(
                          width: 640,
                          child: SwitchListTile(
                            value: isActive,
                            contentPadding: EdgeInsets.zero,
                            activeThumbColor: const Color(0xFF1565C0),
                            title: const Text(
                              'Active Product',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              isActive
                                  ? 'Visible and available in POS.'
                                  : 'Hidden from POS but retained in inventory and transaction history.',
                            ),
                            onChanged: saving
                                ? null
                                : (value) {
                                    setDialogState(() {
                                      isActive = value;
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (document != null)
                  TextButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final deleted = await _confirmDelete(document);

                            if (deleted && dialogContext.mounted) {
                              Navigator.pop(dialogContext, false);
                            }
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1565C0),
                    ),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Delete Product'),
                  ),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 8),
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : saveProduct,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save),
                  label: Text(saving ? 'Saving...' : 'Save Product'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && mounted) {
      // Loads active product records into local caches used by fast POS search and barcode lookup.
      await _loadProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            document == null
                ? 'Product added successfully.'
                : 'Product updated successfully.',
          ),
          backgroundColor: const Color(0xFF1565C0),
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // DIALOG FIELD
  // ------------------------------------------------------------

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required double width,
    TextInputType? keyboardType,
    // Handles the function logic used by this module.
    String? Function(String?)? validator,
  }) {
    // Handles the sized box logic used by this module.
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // VALIDATORS
  // ------------------------------------------------------------

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  // Handles the number validator logic used by this module.
  String? _numberValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');

    if (parsed == null || !parsed.isFinite || parsed < 0) {
      return 'Enter a valid finite, non-negative number';
    }

    return null;
  }

  String? _positivePriceValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || !parsed.isFinite || parsed <= 0) {
      return 'Enter a positive selling price';
    }
    return null;
  }

  // Handles the integer validator logic used by this module.
  String? _integerValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');

    if (parsed == null || parsed < 0) {
      return 'Enter a valid whole number';
    }

    return null;
  }

  // ------------------------------------------------------------
  // DELETE
  // ------------------------------------------------------------

  Future<bool> _confirmDelete(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final productName = (document.data()?['productName'] ?? 'this product')
        .toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        // Handles the alert dialog logic used by this module.
        return AlertDialog(
          title: const Text('Delete Product'),
          content: Text(
            'Delete "$productName"? This should only be used when the actual product is no longer sold by EÜ MART.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.delete),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return false;

    try {
      final productId = document.id;

      await document.reference.delete();

      await AuditLogService.productDeleted(
        productId: productId,
        productName: productName,
      );

      // Loads active product records into local caches used by fast POS search and barcode lookup.
      await _loadProducts();

      if (!mounted) return true;

      ScaffoldMessenger.of(context).showSnackBar(
        // Handles the snack bar logic used by this module.
        const SnackBar(
          content: Text('Product deleted successfully.'),
          backgroundColor: const Color(0xFF1565C0),
        ),
      );

      return true;
    } catch (error) {
      if (!mounted) return false;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete product: $error'),
          backgroundColor: const Color(0xFF1565C0),
        ),
      );

      return false;
    }
  }

  // ------------------------------------------------------------
  // OPTIMIZED PRODUCT LOADING / SEARCH / PAGINATION
  // ------------------------------------------------------------

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _allProducts = [];
  bool _productsLoading = true;
  String? _productsError;

  int _activeCount = 0;
  int get _lowStockCount => _allProducts.where((document) {
    final stock = _readInt(document.data()['stock']);
    return stock > 0 && stock <= _lowStockThreshold;
  }).length;
  int _totalStock = 0;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _thresholdSubscription = FirebaseFirestore.instance
        .collection('settings')
        .doc('system')
        .snapshots()
        .listen((snapshot) {
          final raw = snapshot.data()?['lowStockThreshold'];
          final threshold = raw is num
              ? raw.toInt()
              : int.tryParse(raw?.toString() ?? '') ?? 10;
          if (mounted && threshold != _lowStockThreshold) {
            setState(() => _lowStockThreshold = threshold);
          }
        });
  }

  // Cache-first and stale-while-revalidate: avoid blocking the entire catalog
  // while waiting for a network round trip. The server remains authoritative.
  bool _isFetchingProducts = false;

  void _applyProductDocuments(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    if (!mounted) return;
    final activeCount = documents
        .where((document) => document.data()['isActive'] != false)
        .length;
    final totalStock = documents.fold<int>(
      0,
      (total, document) => total + _readInt(document.data()['stock']),
    );
    setState(() {
      _allProducts = documents;
      _activeCount = activeCount;
      _totalStock = totalStock;
      _productsLoading = false;
      _productsError = null;
      if (_selectedCategory != 'All' &&
          !documents.any(
            (doc) =>
                _productCategory(doc.data()).toLowerCase() ==
                _selectedCategory.toLowerCase(),
          )) {
        _selectedCategory = 'All';
      }
      final filteredCount = _filteredProducts.length;
      final pageCount = filteredCount == 0
          ? 1
          : (filteredCount + _productsPerPage - 1) ~/ _productsPerPage;
      if (_currentPage >= pageCount) _currentPage = pageCount - 1;
    });
  }

  // Load locally cached data immediately when available, then fetch the
  // authoritative server version. No duplicate full-collection requests.
  Future<void> _loadProducts() async {
    if (_isFetchingProducts) return;
    _isFetchingProducts = true;
    if (mounted) {
      setState(() {
        _productsLoading = _allProducts.isEmpty;
        _productsError = null;
      });
    }
    try {
      final query = FirebaseFirestore.instance
          .collection('products')
          .orderBy('productName');

      if (_allProducts.isEmpty) {
        try {
          final cached = await query.get(
            const GetOptions(source: Source.cache),
          );
          if (cached.docs.isNotEmpty) _applyProductDocuments(cached.docs);
        } catch (_) {
          // The browser may have no Firestore cache yet.
        }
      }

      // The full catalog is retained to preserve cross-product search,
      // category chips, overall stock totals, and existing pagination.
      final latest = await query.get(const GetOptions(source: Source.server));
      _applyProductDocuments(latest.docs);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _productsLoading = false;
        // Keep already rendered cached data rather than replacing it with
        // an error page if the connection temporarily fails.
        _productsError = _allProducts.isEmpty ? error.toString() : null;
      });
    } finally {
      _isFetchingProducts = false;
    }
  }

  // Checks whether the current value satisfies the matches search rule used by this module.
  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final combined = [
      data['productName'],
      data['barcode'],
      data['category'],
      data['brand'],
      data['supplier'],
      data['unit'],
    ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

    return combined.contains(_searchQuery);
  }

  String _productCategory(Map<String, dynamic> data) {
    final category = (data['category'] ?? '').toString().trim();
    return category.isEmpty ? 'Uncategorized' : category;
  }

  List<String> get _productCategories {
    final categories = <String, String>{};
    for (final product in _allProducts) {
      final category = _productCategory(product.data());
      categories.putIfAbsent(category.toLowerCase(), () => category);
    }
    final sorted = categories.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['All', ...sorted.where((name) => name.toLowerCase() != 'all')];
  }

  Widget _categoryChips() {
    final categories = _productCategories;
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = _selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() {
              _selectedCategory = category;
              _currentPage = 0;
            }),
            selectedColor: const Color(0xFFD9EAFE),
            labelStyle: TextStyle(
              color: selected
                  ? const Color(0xFF0D47A1)
                  : const Color(0xFF48566A),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
            side: BorderSide(
              color: selected
                  ? const Color(0xFF1565C0)
                  : const Color(0xFFDDE6F1),
            ),
            backgroundColor: Colors.white,
            showCheckmark: false,
          );
        },
      ),
    );
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> get _filteredProducts {
    return _allProducts.where((document) {
      final data = document.data();
      final matchesCategory =
          _selectedCategory == 'All' ||
          _productCategory(data).toLowerCase() ==
              _selectedCategory.toLowerCase();
      return matchesCategory && _matchesSearch(data);
    }).toList();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (_productsLoading) {
      // Handles the center logic used by this module.
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF1565C0)),
            SizedBox(height: 14),
            Text(
              'Loading inventory...',
              style: TextStyle(color: Color(0xFF52657B)),
            ),
          ],
        ),
      );
    }

    if (_productsError != null) {
      // Handles the center logic used by this module.
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Unable to load products.\n$_productsError',
              textAlign: TextAlign.center,
              style: const TextStyle(color: const Color(0xFF1565C0)),
            ),
            // Handles the sized box logic used by this module.
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loadProducts,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filtered = _filteredProducts;

    final totalPages = filtered.isEmpty
        ? 1
        : ((filtered.length + _productsPerPage - 1) ~/ _productsPerPage);

    final safeCurrentPage = _currentPage >= totalPages
        ? totalPages - 1
        : _currentPage;

    final pageStart = safeCurrentPage * _productsPerPage;
    final pageEnd = (pageStart + _productsPerPage < filtered.length)
        ? pageStart + _productsPerPage
        : filtered.length;

    final visibleProducts = filtered.isEmpty
        ? <QueryDocumentSnapshot<Map<String, dynamic>>>[]
        : filtered.sublist(pageStart, pageEnd);

    // Handles the container logic used by this module.
    return Container(
      color: const Color(0xFFF2F6FC),
      child: Padding(
        padding: const EdgeInsets.all(22),
        // Let the entire inventory page scroll on shorter laptop screens.
        // A bounded product-list area below prevents the table from collapsing
        // when the header, summary tiles, search, and categories take space.
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
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
                      blurRadius: 22,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 900;

                    final title = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Handles the row logic used by this module.
                        const Row(
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.white,
                              size: 26,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Products & Inventory',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        // Handles the sized box logic used by this module.
                        const SizedBox(height: 7),
                        Text(
                          'Manage products, stock, pricing, '
                          'barcodes, and expiration details.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    );

                    final actions = Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            // Handles the import products from csv logic used by this module.
                            await _importProductsFromCsv();
                            await _loadProducts();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.65),
                            ),
                            minimumSize: const Size(150, 48),
                          ),
                          icon: const Icon(Icons.upload_file_outlined),
                          label: const Text('IMPORT CSV'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            // Opens the product dialog interface using the current record or screen state.
                            await _showProductDialog();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1565C0),
                            minimumSize: const Size(180, 48),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text(
                            'ADD PRODUCT',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    );

                    if (compact) {
                      // Handles the column logic used by this module.
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [title, const SizedBox(height: 18), actions],
                      );
                    }

                    // Handles the row logic used by this module.
                    return Row(
                      children: [
                        Expanded(child: title),
                        actions,
                      ],
                    );
                  },
                ),
              ),
              // Handles the sized box logic used by this module.
              const SizedBox(height: 18),
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 900
                      ? 4
                      : constraints.maxWidth >= 650
                      ? 2
                      : 1;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: columns,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: columns == 4
                        ? 112
                        : columns == 2
                        ? 122
                        : 104,
                    children: [
                      _inventorySummaryCard(
                        label: 'Total Products',
                        value: '${_allProducts.length}',
                        icon: Icons.category_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                      _inventorySummaryCard(
                        label: 'Active Products',
                        value: '$_activeCount',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF1565C0),
                      ),
                      _inventorySummaryCard(
                        label: 'Low Stock',
                        value: '$_lowStockCount',
                        icon: Icons.warning_amber_rounded,
                        color: const Color(0xFFEAF3FF),
                      ),
                      _inventorySummaryCard(
                        label: 'Total Units',
                        value: '$_totalStock',
                        icon: Icons.stacked_bar_chart_rounded,
                        color: const Color(0xFF1565C0),
                      ),
                    ],
                  );
                },
              ),
              // Handles the sized box logic used by this module.
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE1E9F3)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0F16395C),
                      blurRadius: 12,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.trim().toLowerCase();
                      _currentPage = 0;
                    });
                  },
                  decoration: InputDecoration(
                    hintText:
                        'Search product, barcode, category, brand, or supplier',
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: Color(0xFF1565C0),
                    ),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                                _currentPage = 0;
                              });
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _categoryChips(),
              // Handles the sized box logic used by this module.
              const SizedBox(height: 16),
              SizedBox(
                height: 520,
                child: filtered.isEmpty
                    ? const _InventoryEmptyState()
                    : Column(
                        children: [
                          Expanded(
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                if (constraints.maxWidth >= 980) {
                                  // Builds the product table UI from the current data and screen state.
                                  return _buildProductTable(visibleProducts);
                                }

                                // Builds the product cards UI from the current data and screen state.
                                return _buildProductCards(visibleProducts);
                              },
                            ),
                          ),
                          // Handles the sized box logic used by this module.
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: const Color(0xFFE1E9F3),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  tooltip: 'Previous page',
                                  onPressed: safeCurrentPage > 0
                                      ? () {
                                          setState(() {
                                            _currentPage = safeCurrentPage - 1;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_left_rounded),
                                ),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 8),
                                Text(
                                  'Page ${safeCurrentPage + 1} of $totalPages'
                                  '  •  ${filtered.length} product(s)',
                                  style: const TextStyle(
                                    color: Color(0xFF4B5563),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Next page',
                                  onPressed: safeCurrentPage < totalPages - 1
                                      ? () {
                                          setState(() {
                                            _currentPage = safeCurrentPage + 1;
                                          });
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_right_rounded),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SUMMARY CARD
  // ------------------------------------------------------------

  Widget _inventorySummaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 520),
      tween: Tween(begin: 0.92, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withValues(alpha: 0.055)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.12)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1016385A),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 23),
            ),
            // Handles the sized box logic used by this module.
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF7A8494),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PRODUCT TABLE
  // ------------------------------------------------------------

  Widget _buildProductTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    // Handles the container logic used by this module.
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE1E9F3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1216385A),
            blurRadius: 16,
            offset: Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: DataTable(
              headingRowHeight: 54,
              dataRowMinHeight: 62,
              dataRowMaxHeight: 72,
              headingRowColor: WidgetStateProperty.all(const Color(0xFFEAF3FF)),
              dividerThickness: 0.6,
              showCheckboxColumn: false,
              columns: const [
                DataColumn(label: Text('Product')),
                DataColumn(label: Text('Barcode')),
                DataColumn(label: Text('Category')),
                DataColumn(label: Text('Price')),
                DataColumn(label: Text('Stock')),
                DataColumn(label: Text('Unit')),
                DataColumn(label: Text('Expiration')),
                DataColumn(label: Text('Actions')),
              ],
              rows: documents.map((document) {
                final data = document.data();

                final stock = _readInt(data['stock']);

                final sellingPrice = _readDouble(data['sellingPrice']);

                final expirationDate = _readDate(data['expirationDate']);

                final active = data['isActive'] != false;

                final name = (data['productName'] ?? 'Unknown Product')
                    .toString();

                // Handles the data row logic used by this module.
                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
                      // Handles the color logic used by this module.
                      return const Color(0xFFF5F9FF);
                    }

                    return null;
                  }),
                  cells: [
                    DataCell(
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEAF3FF),
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: const Icon(
                              Icons.inventory_2_outlined,
                              color: Color(0xFF1565C0),
                              size: 20,
                            ),
                          ),
                          // Handles the sized box logic used by this module.
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  active ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: active
                                        ? const Color(0xFF1565C0)
                                        : Colors.grey,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      onTap: () => _showProductDialog(document: document),
                    ),
                    DataCell(
                      Text(
                        (data['barcode'] ?? '').toString().trim().isEmpty
                            ? 'No barcode'
                            : data['barcode'].toString(),
                      ),
                    ),
                    DataCell(Text((data['category'] ?? '').toString())),
                    DataCell(
                      Text(
                        '₱${sellingPrice.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF1559A6),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: stock > 0 && stock <= _lowStockThreshold
                              ? const Color(0xFFEAF3FF)
                              : const Color(0xFFDCEBFF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$stock',
                          style: TextStyle(
                            color: const Color(0xFF1559A6),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text((data['unit'] ?? '').toString())),
                    DataCell(
                      Text(
                        expirationDate != null &&
                                DateTime(
                                  expirationDate.year,
                                  expirationDate.month,
                                  expirationDate.day,
                                ).isBefore(
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    DateTime.now().day,
                                  ),
                                )
                            ? 'EXPIRED • ${_formatDate(expirationDate)}'
                            : _formatDate(expirationDate),
                        style: TextStyle(
                          color:
                              expirationDate != null &&
                                  DateTime(
                                    expirationDate.year,
                                    expirationDate.month,
                                    expirationDate.day,
                                  ).isBefore(
                                    DateTime(
                                      DateTime.now().year,
                                      DateTime.now().month,
                                      DateTime.now().day,
                                    ),
                                  )
                              ? const Color(0xFFB91C1C)
                              : const Color(0xFF52657B),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'Edit',
                            onPressed: () =>
                                _showProductDialog(document: document),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Color(0xFF1565C0),
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => _confirmDelete(document),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PRODUCT CARDS
  // ------------------------------------------------------------

  Widget _buildProductCards(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return ListView.separated(
      itemCount: documents.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final document = documents[index];

        final data = document.data();

        final stock = _readInt(data['stock']);

        final sellingPrice = _readDouble(data['sellingPrice']);

        final active = data['isActive'] != false;

        // Handles the inventory product card logic used by this module.
        return _InventoryProductCard(
          productName: (data['productName'] ?? 'Unknown Product').toString(),
          category: (data['category'] ?? '').toString(),
          unit: (data['unit'] ?? '').toString(),
          barcode: (data['barcode'] ?? '').toString(),
          price: sellingPrice,
          stock: stock,
          lowStockThreshold: _lowStockThreshold,
          active: active,
          expired: () {
            final value = _readDate(data['expirationDate']);
            if (value == null) return false;
            final now = DateTime.now();
            return DateTime(
              value.year,
              value.month,
              value.day,
            ).isBefore(DateTime(now.year, now.month, now.day));
          }(),
          onTap: () => _showProductDialog(document: document),
          onEdit: () => _showProductDialog(document: document),
          onDelete: () => _confirmDelete(document),
        );
      },
    );
  }

  @override
  void dispose() {
    _thresholdSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }
}
