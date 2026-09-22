import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class QuickProductEncodingScreen extends StatefulWidget {
  const QuickProductEncodingScreen({super.key});

  @override
  State<QuickProductEncodingScreen> createState() =>
      _QuickProductEncodingScreenState();
}

class _QuickProductEncodingScreenState
    extends State<QuickProductEncodingScreen> {
  final _formKey = GlobalKey<FormState>();

  final _barcodeController = TextEditingController();
  final _productNameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _brandController = TextEditingController();
  final _buyingPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _supplierController = TextEditingController();
  final _unitController = TextEditingController(text: 'piece');

  final _barcodeFocus = FocusNode();
  final _productNameFocus = FocusNode();

  DateTime? _expirationDate;
  bool _checkingBarcode = false;
  bool _saving = false;
  bool _barcodeReady = false;
  String? _barcodeMessage;
  int _sessionAdded = 0;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _productNameController.dispose();
    _categoryController.dispose();
    _brandController.dispose();
    _buyingPriceController.dispose();
    _sellingPriceController.dispose();
    _stockController.dispose();
    _supplierController.dispose();
    _unitController.dispose();
    _barcodeFocus.dispose();
    _productNameFocus.dispose();
    super.dispose();
  }

  String? _required(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }

  String? _positiveNumber(String? value) {
    final parsed = double.tryParse(value?.trim() ?? '');

    if (parsed == null || parsed < 0) {
      return 'Enter a valid amount';
    }

    return null;
  }

  String? _stockValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');

    if (parsed == null || parsed < 0) {
      return 'Enter a valid stock';
    }

    return null;
  }

  Future<void> _checkBarcode([String? submitted]) async {
    final barcode = (submitted ?? _barcodeController.text).trim();

    if (barcode.isEmpty || _checkingBarcode || _saving) return;

    setState(() {
      _checkingBarcode = true;
      _barcodeReady = false;
      _barcodeMessage = null;
    });

    try {
      final result = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (!mounted) return;

      if (result.docs.isNotEmpty) {
        final data = result.docs.first.data();
        final productName = (data['productName'] ?? 'Existing product')
            .toString();

        setState(() {
          _barcodeMessage = 'Barcode already belongs to $productName.';
          _barcodeReady = false;
        });

        _barcodeFocus.requestFocus();
        _barcodeController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _barcodeController.text.length,
        );
        return;
      }

      setState(() {
        _barcodeReady = true;
        _barcodeMessage = 'Barcode accepted. Complete the product details.';
      });

      _productNameFocus.requestFocus();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _barcodeMessage = 'Unable to check barcode: $error';
        _barcodeReady = false;
      });
    } finally {
      if (mounted) {
        setState(() => _checkingBarcode = false);
      }
    }
  }

  void _resetForNextProduct() {
    _formKey.currentState?.reset();

    _barcodeController.clear();
    _productNameController.clear();
    _categoryController.clear();
    _brandController.clear();
    _buyingPriceController.clear();
    _sellingPriceController.clear();
    _stockController.clear();
    _supplierController.clear();
    _unitController.text = 'piece';

    setState(() {
      _expirationDate = null;
      _barcodeReady = false;
      _barcodeMessage = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _barcodeFocus.requestFocus();
    });
  }

  Future<void> _saveAndScanNext() async {
    if (!_barcodeReady) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scan or confirm the barcode first.'),
          backgroundColor: Colors.orange,
        ),
      );
      _barcodeFocus.requestFocus();
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final barcode = _barcodeController.text.trim();

      final duplicate = await FirebaseFirestore.instance
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (duplicate.docs.isNotEmpty) {
        throw Exception('This barcode was already saved by another user.');
      }

      final productName = _productNameController.text.trim();

      final document = await FirebaseFirestore.instance
          .collection('products')
          .add({
            'productName': productName,
            'barcode': barcode,
            'category': _categoryController.text.trim(),
            'brand': _brandController.text.trim(),
            'buyingPrice': double.parse(_buyingPriceController.text.trim()),
            'sellingPrice': double.parse(_sellingPriceController.text.trim()),
            'stock': int.parse(_stockController.text.trim()),
            'supplier': _supplierController.text.trim(),
            'unit': _unitController.text.trim(),
            'expirationDate': _expirationDate == null
                ? null
                : Timestamp.fromDate(_expirationDate!),
            'imagePath': '',
            'promoActive': false,
            'isActive': true,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });

      await AuditLogService.productCreated(
        productId: document.id,
        productName: productName,
      );

      if (!mounted) return;

      setState(() => _sessionAdded++);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$productName saved. Scan the next product.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      _resetForNextProduct();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _selectExpirationDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _expirationDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );

    if (selected == null || !mounted) return;

    setState(() => _expirationDate = selected);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      keyboardType: keyboardType,
      validator: validator,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: enabled ? Colors.white : const Color(0xFFF1F4F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDCE5F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF1565C0), width: 1.8),
        ),
      ),
    );
  }

  Widget _stepCard({
    required String number,
    required String title,
    required String description,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFDDE6F1)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1016385A),
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
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Icon(icon, color: const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: const TextStyle(
                        color: Color(0xFF7A8494),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fieldsEnabled = _barcodeReady && !_checkingBarcode && !_saving;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      appBar: AppBar(
        title: const Text('Quick Product Encoding'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
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
                        blurRadius: 20,
                        offset: Offset(0, 9),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 650;

                      final title = const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fast Initial Product Encoding',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'Scan one barcode per product type, enter store details, '
                            'then save and continue to the next item.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      );

                      final counter = Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '$_sessionAdded',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'ADDED THIS SESSION',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            title,
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: counter,
                            ),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: title),
                          counter,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF3D69A)),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: Color(0xFFD78700)),
                      SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          'Best used with a USB barcode scanner. Click the barcode '
                          'field once, scan the product, and the scanner will submit '
                          'the code like a keyboard. Scan each product type only once.',
                          style: TextStyle(
                            color: Color(0xFF7A571A),
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _stepCard(
                  number: '1',
                  title: 'Scan Product Barcode',
                  description:
                      'The system checks that the barcode is not yet registered.',
                  icon: Icons.qr_code_scanner,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _barcodeController,
                        focusNode: _barcodeFocus,
                        enabled: !_checkingBarcode && !_saving,
                        autofocus: true,
                        onSubmitted: _checkBarcode,
                        decoration: InputDecoration(
                          labelText: 'Scan or enter barcode',
                          hintText:
                              'Keep this field focused, then use the scanner',
                          prefixIcon: const Icon(Icons.qr_code_2),
                          suffixIcon: _checkingBarcode
                              ? const Padding(
                                  padding: EdgeInsets.all(13),
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : IconButton(
                                  tooltip: 'Check barcode',
                                  onPressed: _checkBarcode,
                                  icon: const Icon(Icons.search),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      if (_barcodeMessage != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _barcodeReady
                                ? const Color(0xFFEAF8F0)
                                : const Color(0xFFFFECEC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _barcodeMessage!,
                            style: TextStyle(
                              color: _barcodeReady
                                  ? const Color(0xFF168653)
                                  : const Color(0xFFC62828),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _stepCard(
                  number: '2',
                  title: 'Enter Product Details',
                  description:
                      'Only the information specific to EÜ MART must be encoded.',
                  icon: Icons.edit_note_outlined,
                  child: Form(
                    key: _formKey,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final fieldWidth = width >= 760
                            ? (width - 16) / 2
                            : width;

                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: _field(
                                controller: _productNameController,
                                label: 'Product Name',
                                focusNode: _productNameFocus,
                                validator: _required,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(
                                controller: _categoryController,
                                label: 'Category',
                                validator: _required,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(
                                controller: _brandController,
                                label: 'Brand (optional)',
                                enabled: fieldsEnabled,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(
                                controller: _unitController,
                                label: 'Unit',
                                hint: 'piece, pack, bottle, kg',
                                validator: _required,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(
                                controller: _buyingPriceController,
                                label: 'Buying Price',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: _positiveNumber,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(
                                controller: _sellingPriceController,
                                label: 'Selling Price',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: _positiveNumber,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(
                                controller: _stockController,
                                label: 'Current Stock',
                                keyboardType: TextInputType.number,
                                validator: _stockValidator,
                                enabled: fieldsEnabled,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: _field(
                                controller: _supplierController,
                                label: 'Supplier (optional)',
                                enabled: fieldsEnabled,
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: OutlinedButton.icon(
                                onPressed: fieldsEnabled
                                    ? _selectExpirationDate
                                    : null,
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(56),
                                  alignment: Alignment.centerLeft,
                                ),
                                icon: const Icon(Icons.event_outlined),
                                label: Text(
                                  _expirationDate == null
                                      ? 'Expiration Date (optional)'
                                      : 'Expiration: ${_formatDate(_expirationDate!)}',
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _saving ? null : _resetForNextProduct,
                      icon: const Icon(Icons.refresh),
                      label: const Text('CLEAR'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: fieldsEnabled ? _saveAndScanNext : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(210, 52),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 19,
                              height: 19,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.save_as_outlined),
                      label: Text(
                        _saving ? 'SAVING...' : 'SAVE & SCAN NEXT',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
