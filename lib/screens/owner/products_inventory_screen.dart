import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class _InventoryEmptyState extends StatelessWidget {
  const _InventoryEmptyState();

  @override
  Widget build(BuildContext context) {
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

class _InventoryProductCard extends StatefulWidget {
  final String productName;
  final String category;
  final String unit;
  final String barcode;
  final double price;
  final int stock;
  final bool active;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _InventoryProductCard({
    required this.productName,
    required this.category,
    required this.unit,
    required this.barcode,
    required this.price,
    required this.stock,
    required this.active,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_InventoryProductCard> createState() => _InventoryProductCardState();
}

class _InventoryProductCardState extends State<_InventoryProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final lowStock = widget.stock <= 10;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
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
            color: _hovered ? const Color(0xFFB9D6F8) : const Color(0xFFE1E9F3),
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
                              ? const Color(0xFFEAF8F0)
                              : const Color(0xFFF1F3F5),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.active ? 'ACTIVE' : 'INACTIVE',
                          style: TextStyle(
                            color: widget.active
                                ? const Color(0xFF168653)
                                : Colors.grey,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '${widget.category} • ${widget.unit}',
                    style: const TextStyle(
                      color: Color(0xFF7A8494),
                      fontSize: 12,
                    ),
                  ),
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
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₱${widget.price.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF0F8A4B),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: lowStock
                        ? const Color(0xFFFFF1E6)
                        : const Color(0xFFEAF8F0),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Stock: ${widget.stock}',
                    style: TextStyle(
                      color: lowStock
                          ? const Color(0xFFD97706)
                          : const Color(0xFF168653),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Edit',
              onPressed: widget.onEdit,
              icon: const Icon(Icons.edit_outlined, color: Color(0xFF1565C0)),
            ),
            IconButton(
              tooltip: 'Delete',
              onPressed: widget.onDelete,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}

class ProductsInventoryScreen extends StatefulWidget {
  const ProductsInventoryScreen({super.key});

  @override
  State<ProductsInventoryScreen> createState() =>
      _ProductsInventoryScreenState();
}

class _ProductsInventoryScreenState extends State<ProductsInventoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Future<void> _importProductsFromCsv() async {
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
        throw Exception('Unable to read the selected CSV file.');
      }

      final csvText = utf8.decode(bytes, allowMalformed: true);
      final List<List<dynamic>> rows = csv.decode(csvText);

      if (rows.isEmpty) {
        throw Exception('The CSV file is empty.');
      }

      final headers = rows.first
          .map((value) => value.toString().trim().toLowerCase())
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
          throw Exception('Missing required column: $header');
        }
      }

      String valueAt(List<dynamic> row, String header) {
        final index = headers.indexOf(header);

        if (index < 0 || index >= row.length) return '';

        return row[index].toString().trim();
      }

      final productsRef = FirebaseFirestore.instance.collection('products');

      int imported = 0;
      int skipped = 0;
      WriteBatch batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;

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

        if (productName.isEmpty ||
            category.isEmpty ||
            buyingPrice == null ||
            sellingPrice == null ||
            stock == null ||
            stock < 0) {
          skipped++;
          continue;
        }

        final barcode = valueAt(row, 'barcode');

        if (barcode.isNotEmpty) {
          final duplicate = await productsRef
              .where('barcode', isEqualTo: barcode)
              .limit(1)
              .get();

          if (duplicate.docs.isNotEmpty) {
            skipped++;
            continue;
          }
        }

        final expirationText = valueAt(row, 'expirationdate');
        final expirationDate = expirationText.isEmpty
            ? null
            : DateTime.tryParse(expirationText);

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

        if (batchCount == 400) {
          await batch.commit();
          batch = FirebaseFirestore.instance.batch();
          batchCount = 0;
        }
      }

      if (batchCount > 0) {
        await batch.commit();
      }

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
            'fileName': file.name,
          },
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'CSV import complete: $imported imported, '
            '$skipped skipped.',
          ),
          backgroundColor: imported > 0 ? Colors.green : Colors.orange,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to import CSV: '
            '${error.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
          : (data['buyingPrice'] as num).toString(),
    );
    final sellingPriceController = TextEditingController(
      text: data['sellingPrice'] == null
          ? ''
          : (data['sellingPrice'] as num).toString(),
    );
    final stockController = TextEditingController(
      text: data['stock'] == null ? '' : (data['stock'] as num).toString(),
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveProduct() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => saving = true);

              try {
                final enteredBarcode = barcodeController.text.trim();

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
                      const SnackBar(
                        content: Text(
                          'This barcode is already assigned to another product.',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );

                    setDialogState(() => saving = false);
                    return;
                  }
                }

                final productData = <String, dynamic>{
                  'productName': productNameController.text.trim(),
                  'barcode': enteredBarcode,
                  'category': categoryController.text.trim(),
                  'brand': brandController.text.trim(),
                  'buyingPrice': double.parse(
                    buyingPriceController.text.trim(),
                  ),
                  'sellingPrice': double.parse(
                    sellingPriceController.text.trim(),
                  ),
                  'stock': int.parse(stockController.text.trim()),
                  'supplier': supplierController.text.trim(),
                  'unit': unitController.text.trim(),
                  'expirationDate': expirationDate == null
                      ? null
                      : Timestamp.fromDate(expirationDate!),
                  'isActive': isActive,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                final productName = productNameController.text.trim();

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
                } else {
                  final oldStock = (data['stock'] as num?)?.toInt() ?? 0;

                  final newStock = int.parse(stockController.text.trim());

                  await document.reference.update(productData);

                  await AuditLogService.productUpdated(
                    productId: document.id,
                    productName: productName,
                  );

                  if (oldStock != newStock) {
                    await AuditLogService.stockAdjusted(
                      productId: document.id,
                      productName: productName,
                      oldStock: oldStock,
                      newStock: newStock,
                    );
                  }
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (error) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Unable to save product: $error'),
                    backgroundColor: Colors.red,
                  ),
                );

                setDialogState(() => saving = false);
              }
            }

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
                        _dialogField(
                          controller: categoryController,
                          label: 'Category',
                          width: 310,
                          validator: _requiredValidator,
                        ),
                        _dialogField(
                          controller: brandController,
                          label: 'Brand (optional)',
                          width: 310,
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
                          validator: _numberValidator,
                        ),
                        _dialogField(
                          controller: stockController,
                          label: 'Stock',
                          width: 200,
                          keyboardType: TextInputType.number,
                          validator: _integerValidator,
                        ),
                        _dialogField(
                          controller: supplierController,
                          label: 'Supplier',
                          width: 310,
                        ),
                        _dialogField(
                          controller: unitController,
                          label: 'Unit (piece, kg, liter, pack)',
                          width: 310,
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
                                        const Duration(days: 365),
                                      ),
                                      lastDate: DateTime.now().add(
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            document == null
                ? 'Product added successfully.'
                : 'Product updated successfully.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required double width,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
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

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) {
      return 'Enter a valid number';
    }
    return null;
  }

  String? _integerValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');
    if (parsed == null || parsed < 0) {
      return 'Enter a valid whole number';
    }
    return null;
  }

  Future<void> _confirmDelete(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final productName = (document.data()?['productName'] ?? 'this product')
        .toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
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
                backgroundColor: Colors.red,
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

    if (confirmed != true) return;

    try {
      final productId = document.id;

      await document.reference.delete();

      await AuditLogService.productDeleted(
        productId: productId,
        productName: productName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product deleted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete product: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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

        final documents =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            )..sort((a, b) {
              final first = (a.data()['productName'] ?? '')
                  .toString()
                  .toLowerCase();
              final second = (b.data()['productName'] ?? '')
                  .toString()
                  .toLowerCase();
              return first.compareTo(second);
            });

        final filtered = documents
            .where((document) => _matchesSearch(document.data()))
            .toList();

        final activeCount = documents
            .where((document) => document.data()['isActive'] != false)
            .length;

        final lowStockCount = documents.where((document) {
          final stock = (document.data()['stock'] as num?)?.toInt() ?? 0;
          return stock <= 10;
        }).length;

        final totalStock = documents.fold<int>(
          0,
          (sum, document) =>
              sum + ((document.data()['stock'] as num?)?.toInt() ?? 0),
        );

        return Container(
          color: const Color(0xFFF2F6FC),
          child: Padding(
            padding: const EdgeInsets.all(22),
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
                      final compact = constraints.maxWidth < 760;

                      final title = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                            onPressed: _importProductsFromCsv,
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
                            onPressed: () => _showProductDialog(),
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
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            const SizedBox(height: 18),
                            actions,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: title),
                          actions,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth >= 900 ? 4 : 2;

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: columns,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: columns == 4 ? 2.45 : 2.8,
                      children: [
                        _inventorySummaryCard(
                          label: 'Total Products',
                          value: '${documents.length}',
                          icon: Icons.category_outlined,
                          color: const Color(0xFF1565C0),
                        ),
                        _inventorySummaryCard(
                          label: 'Active Products',
                          value: '$activeCount',
                          icon: Icons.check_circle_outline,
                          color: const Color(0xFF159447),
                        ),
                        _inventorySummaryCard(
                          label: 'Low Stock',
                          value: '$lowStockCount',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFF59E0B),
                        ),
                        _inventorySummaryCard(
                          label: 'Total Units',
                          value: '$totalStock',
                          icon: Icons.stacked_bar_chart_rounded,
                          color: const Color(0xFF7B1FA2),
                        ),
                      ],
                    );
                  },
                ),
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
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: filtered.isEmpty
                      ? const _InventoryEmptyState()
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth >= 980) {
                              return _buildProductTable(filtered);
                            }

                            return _buildProductCards(filtered);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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

  Widget _buildProductTable(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
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
                final stock = (data['stock'] as num?)?.toInt() ?? 0;
                final sellingPrice =
                    (data['sellingPrice'] as num?)?.toDouble() ?? 0;
                final expirationDate = _readDate(data['expirationDate']);
                final active = data['isActive'] != false;
                final name = (data['productName'] ?? 'Unknown Product')
                    .toString();

                return DataRow(
                  color: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.hovered)) {
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
                                        ? const Color(0xFF159447)
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
                          color: Color(0xFF0F8A4B),
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
                          color: stock <= 10
                              ? const Color(0xFFFFF1E6)
                              : const Color(0xFFEAF8F0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$stock',
                          style: TextStyle(
                            color: stock <= 10
                                ? const Color(0xFFD97706)
                                : const Color(0xFF168653),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text((data['unit'] ?? '').toString())),
                    DataCell(Text(_formatDate(expirationDate))),
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
                              color: Colors.red,
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

  Widget _buildProductCards(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> documents,
  ) {
    return ListView.separated(
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final document = documents[index];
        final data = document.data();
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        final sellingPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
        final active = data['isActive'] != false;

        return _InventoryProductCard(
          productName: (data['productName'] ?? 'Unknown Product').toString(),
          category: (data['category'] ?? '').toString(),
          unit: (data['unit'] ?? '').toString(),
          barcode: (data['barcode'] ?? '').toString(),
          price: sellingPrice,
          stock: stock,
          active: active,
          onEdit: () => _showProductDialog(document: document),
          onDelete: () => _confirmDelete(document),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
