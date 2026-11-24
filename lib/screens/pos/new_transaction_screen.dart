// -----------------------------------------------------------------------------
// Module overview: Core POS workflow: product search, AI assistance, barcode scanning, cart handling, payment, stock deduction, receipt generation, held transactions, and service timing.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Screen widget for core POS workflow: product search, AI assistance, barcode scanning, cart handling, payment, stock deduction, receipt generation, held transactions, and service timing.
class NewTransactionScreen extends StatefulWidget {
  // Handles the new transaction screen logic used by this module.
  const NewTransactionScreen({super.key});

  @override
  State<NewTransactionScreen> createState() => _NewTransactionScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _NewTransactionScreenState extends State<NewTransactionScreen> {
  static const String _feedbackUrl =
      'https://eu-mart-mobile.web.app/#/feedback';

  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  // Hardware scanners usually type into the focused field like a keyboard.
  // Wait briefly for the complete barcode, including scanners without ENTER.
  Timer? _hardwareScanTimer;
  // Delay expensive fuzzy matching until the cashier pauses typing.
  Timer? _textSearchTimer;
  // Invalidates any in-progress chunked search when input changes.
  int _searchGeneration = 0;
  static const Duration _textSearchDelay = Duration(milliseconds: 240);
  String? _lastHardwareBarcode;
  DateTime? _lastHardwareScanAt;
  static const Duration _scanQuietPeriod = Duration(milliseconds: 140);
  static const Duration _scanDuplicateWindow = Duration(milliseconds: 450);
  // Keep the last receipt width during this POS session (58mm or 80mm).
  int _receiptPaperWidthMm = 58;
  final _cashController = TextEditingController();
  final Map<String, _CartItem> _cart = {};

  DateTime? _transactionStartedAt;
  Timer? _durationTimer;

  String _query = '';
  String _selectedCategory = 'All';
  bool _processing = false;
  bool _aiSearching = false;
  final Set<String> _aiMatchedProductIds = <String>{};
  String _aiSearchMessage = '';
  int? _aiResponseTimeMs;

  // Cache validated AI results only for the current POS product snapshot.
  // Cache entries are cleared whenever the catalog is reloaded.
  final Map<String, List<String>> _aiSearchCache = <String, List<String>>{};
  static const int _maxAiCandidates = 24;
  static const int _maxAiCachedQueries = 30;

  // Recently scanned products stay visible below the search bar.
  final List<String> _recentScannedProductIds = <String>[];
  String? _scannedBarcodeProductId;

  // Product data is loaded once instead of keeping a live listener on the
  // complete catalog. Search results are cached so the 1-second transaction
  // timer does not repeatedly rescan thousands of products.
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _activeProducts = [];
  List<QueryDocumentSnapshot<Map<String, dynamic>>> _visibleProducts = [];
  final Map<String, QueryDocumentSnapshot<Map<String, dynamic>>> _productsById =
      {};
  final Map<String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>
  _productsByBarcode = {};
  bool _productsLoading = true;
  String? _productsError;
  static const int _maxVisibleProducts = 80;

  double get _total =>
      _cart.values.fold(0, (total, item) => total + item.subtotal);

  double get _totalSavings =>
      _cart.values.fold(0, (total, item) => total + item.savings);

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

  // Converts transaction duration into the system service-speed classification used for monitoring.
  String _serviceSpeedLabel(int durationSeconds) {
    if (durationSeconds <= 120) return 'Normal Service';
    if (durationSeconds <= 300) return 'Minor Delay';
    return 'Long Delay';
  }

  // Starts service-time tracking the first time the cashier begins an active transaction.
  void _ensureTransactionStarted() {
    if (_transactionStartedAt != null) return;

    _transactionStartedAt = DateTime.now();
    _startDurationTimer();
  }

  // Handles the start duration timer logic used by this module.
  void _startDurationTimer() {
    _durationTimer?.cancel();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _transactionStartedAt == null) {
        return;
      }

      setState(() {});
    });
  }

  // Resets transaction tracking state after the current workflow is completed or cancelled.
  void _resetTransactionTracking() {
    _durationTimer?.cancel();
    _durationTimer = null;
    _transactionStartedAt = null;
  }

  // Checks whether a promotion is enabled and currently inside its configured start/end dates.
  bool _isPromoCurrentlyActive(Map<String, dynamic> data) {
    if (data['promoActive'] != true) return false;

    // Reads and normalizes date from stored data.
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

  // Expiration dates are inclusive: an item expires after its stated day.
  // Missing date means non-expiring; malformed configured dates are blocked.
  DateTime? _productExpirationDate(Map<String, dynamic> data) {
    final value = data['expirationDate'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value.trim());
    return null;
  }

  String? _productSaleBlockReason(Map<String, dynamic> data) {
    final name = (data['productName'] ?? 'This product').toString();
    if (data['isActive'] == false) {
      return '$name is inactive and cannot be sold.';
    }
    final rawExpiration = data['expirationDate'];
    if (rawExpiration == null ||
        (rawExpiration is String && rawExpiration.trim().isEmpty)) {
      return null;
    }
    final expiry = _productExpirationDate(data);
    if (expiry == null) {
      return '$name has an invalid expiration date. Please correct it before selling.';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiryDay = DateTime(expiry.year, expiry.month, expiry.day);
    if (expiryDay.isBefore(today)) {
      return '$name expired on ${expiry.month}/${expiry.day}/${expiry.year} and cannot be sold.';
    }
    return null;
  }

  // Adds a validated active product to the cart while enforcing available-stock and promo rules.
  void _addProduct(QueryDocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data();

    final saleBlockReason = _productSaleBlockReason(data);
    if (saleBlockReason != null) {
      _message(saleBlockReason, Colors.blue);
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

  // Adjusts increase while enforcing the current business limits.
  void _increase(_CartItem item) {
    final product = _productsById[item.productId];
    if (product != null) {
      final reason = _productSaleBlockReason(product.data());
      if (reason != null) {
        _message(reason, Colors.blue);
        return;
      }
    }
    if (item.quantity >= item.availableStock) {
      _message('Only ${item.availableStock} stock available.', Colors.orange);
      return;
    }

    setState(() => item.quantity++);
  }

  // Adjusts decrease while enforcing the current business limits.
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

  // Updates a cart item's typed quantity without bypassing stock rules.
  void _setCartQuantity(_CartItem item, int quantity) {
    if (!_cart.containsKey(item.productId)) return;
    final product = _productsById[item.productId];
    if (product != null) {
      final reason = _productSaleBlockReason(product.data());
      if (reason != null) {
        _message(reason, Colors.blue);
        return;
      }
    }
    if (quantity < 1 || quantity > item.availableStock) return;
    if (item.quantity == quantity) return;
    setState(() => item.quantity = quantity);
  }

  // Processes cashier search input, prioritizing exact barcode matches before local text-search scoring.
  Future<void> _handleSearchInput(
    String value,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) async {
    final normalized = value.trim();
    final generation = _searchGeneration;

    if (normalized.isEmpty) {
      if (!mounted) return;
      setState(() {
        _query = '';
        _scannedBarcodeProductId = null;
        _aiMatchedProductIds.clear();
        _aiSearchMessage = '';
        _aiResponseTimeMs = null;
        _visibleProducts = _activeProducts.take(_maxVisibleProducts).toList();
      });
      return;
    }

    final barcodeKey = normalized.toLowerCase();
    final exactBarcodeMatches = _productsByBarcode[barcodeKey] ?? const [];

    if (exactBarcodeMatches.length == 1) {
      final product = exactBarcodeMatches.first;

      if (mounted) {
        setState(() {
          _query = barcodeKey;
          _scannedBarcodeProductId = product.id;
          _aiMatchedProductIds.clear();
          _aiSearchMessage = 'Scanned barcode: $normalized';
          _visibleProducts = [product];
        });
      }

      // Only display the match here. The unified hardware-scan handler
      // performs the add once, after ENTER/TAB or the short quiet period.
      return;
    }

    if (exactBarcodeMatches.length > 1) {
      _message(
        'Barcode $normalized is assigned to multiple products. Please fix the duplicate barcode.',
        Colors.red,
      );
      return;
    }

    _query = barcodeKey;
    _scannedBarcodeProductId = null;
    _aiMatchedProductIds.clear();
    _aiSearchMessage = '';
    _aiResponseTimeMs = null;

    // A partial numeric barcode should not trigger a full product-name search
    // on every scanner keystroke (which causes visible lag on large catalogs).
    if (RegExp(r'^\d+$').hasMatch(normalized)) {
      if (mounted) setState(() => _visibleProducts = []);
      return;
    }

    // Strict exact-match stage for ALL product names and brands.
    // A recognized brand (e.g. Coca-Cola, Ariel, Nescafe) must not pull in
    // similarly spelled items from another brand/category via fuzzy matching.
    // This in-memory pass is cheap and adds no Firestore reads.
    final searchText = _normalizeSearchText(normalized);
    final exactBrands = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final exactNames = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final phraseNames = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
    final isCokeAlias = searchText == 'coke' || searchText == 'cocacola';
    for (final product in _activeProducts) {
      final data = product.data();
      final brand = _normalizeSearchText(data['brand']);
      final name = _normalizeSearchText(data['productName']);
      final compactBrand = brand.replaceAll(' ', '');
      final compactName = name.replaceAll(' ', '');
      final compactSearch = searchText.replaceAll(' ', '');
      final brandMatches =
          brand.isNotEmpty &&
          (brand == searchText ||
              (compactSearch.length >= 5 && compactBrand == compactSearch) ||
              (isCokeAlias &&
                  (brand == 'coca cola' || compactBrand == 'cocacola')));
      final nameMatches =
          name == searchText ||
          (compactSearch.length >= 5 && compactName == compactSearch);
      final cokeNameMatches =
          isCokeAlias &&
          (_containsSearchPhrase(name, 'coke') ||
              _containsSearchPhrase(name, 'coca cola') ||
              compactName.startsWith('cocacola'));

      if (brandMatches || cokeNameMatches) exactBrands.add(product);
      if (nameMatches) exactNames.add(product);
      // Whole-phrase match only, not an arbitrary substring (e.g. 'cola'
      // in 'chocolate'). Do not use this for broad category queries.
      if (searchText.length >= 3 && _containsSearchPhrase(name, searchText)) {
        phraseNames.add(product);
      }
    }

    // When the query exactly names a catalog brand, show only that brand.
    // Otherwise prefer exact full product names over fuzzy matches. Coke is
    // an existing store alias for Coca-Cola, not the entire soda category.
    final strictMatches = exactBrands.isNotEmpty ? exactBrands : exactNames;
    if (strictMatches.isNotEmpty) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _visibleProducts = strictMatches.take(_maxVisibleProducts).toList();
      });
      return;
    }

    // A specific multi-word product query must outrank category intent.
    // "coke mismo" is a product phrase, whereas "softdrinks" remains broad.
    // Generic category phrases and descriptive size requests stay broad.
    const broadQueries = <String>{
      'softdrinks',
      'softdrink',
      'soft drinks',
      'soda',
      'cola',
      'inumin',
      'drink',
      'drinks',
      'beverage',
      'beverages',
      'tubig',
      'water',
      'juice',
      'kape',
      'coffee',
      'gatas',
      'milk',
      'bigas',
      'rice',
      'asin',
      'salt',
      'mantika',
      'cooking oil',
      'asukal',
      'sugar',
      'harina',
      'flour',
      'noodles',
      'instant noodles',
      'pancit',
      'canned goods',
      'de lata',
      'delata',
      'snacks',
      'chichirya',
      'tinapay',
      'bread',
      'sabon panligo',
      'panlaba',
      'laundry',
      'detergent',
      'panghugas',
      'dishwashing',
      'shampoo',
      'toothpaste',
      'panglinis',
      'cleaner',
      'condiments',
      'sawsawan',
      'itlog',
      'eggs',
      'diapers',
      'diaper',
    };
    final hasSizeDescription = RegExp(
      r'(^| )(malaki|malaking|maliit|small|large|big|family size|litro)( |$)',
    ).hasMatch(searchText);
    final specificNameQuery =
        searchText.split(' ').length > 1 &&
        !broadQueries.contains(searchText) &&
        !hasSizeDescription;
    if (phraseNames.isNotEmpty &&
        (_requestedCategory(searchText) == null || specificNameQuery)) {
      if (!mounted || generation != _searchGeneration) return;
      setState(() {
        _visibleProducts = phraseNames.take(_maxVisibleProducts).toList();
      });
      return;
    }

    final scored = <(int, QueryDocumentSnapshot<Map<String, dynamic>>)>[];
    // Fuzzy matching is CPU-heavy. Process small batches so keyboard events
    // and browser frames are serviced between batches instead of freezing UI.
    const batchSize = 20;
    for (var index = 0; index < _activeProducts.length; index++) {
      if (!mounted || generation != _searchGeneration) return;
      final product = _activeProducts[index];
      final score = _localProductSearchScore(
        product,
        strictProductWords: specificNameQuery,
      );
      if (score >= 20) scored.add((score, product));
      if ((index + 1) % batchSize == 0) {
        await Future<void>.delayed(const Duration(milliseconds: 1));
      }
    }
    if (!mounted || generation != _searchGeneration) return;
    scored.sort((a, b) => b.$1.compareTo(a.$1));

    if (!mounted || generation != _searchGeneration) return;
    setState(() {
      _visibleProducts = scored
          .take(_maxVisibleProducts)
          .map((entry) => entry.$2)
          .toList();
    });
  }

  // Single entry point for keyboard-wedge USB/Bluetooth barcode scans.
  // Covers ENTER, TAB and no-suffix scanners without double-adding.
  void _commitHardwareBarcode(String value) {
    _hardwareScanTimer?.cancel();
    _textSearchTimer?.cancel();
    _searchGeneration++;
    final barcode = value.trim();
    if (!mounted || barcode.isEmpty) return;

    final matches = _productsByBarcode[barcode.toLowerCase()] ?? const [];
    if (matches.length != 1) return;

    final now = DateTime.now();
    if (_lastHardwareBarcode == barcode.toLowerCase() &&
        _lastHardwareScanAt != null &&
        now.difference(_lastHardwareScanAt!) < _scanDuplicateWindow) {
      return;
    }

    _lastHardwareBarcode = barcode.toLowerCase();
    _lastHardwareScanAt = now;
    final product = matches.single;

    // The lookup uses the in-memory product map; no network round trip.
    setState(() {
      _query = barcode.toLowerCase();
      _scannedBarcodeProductId = product.id;
      _aiMatchedProductIds.clear();
      _aiSearchMessage = 'Scanned barcode: $barcode';
      _visibleProducts = [product];
    });
    _addProduct(product);
    _rememberScannedProduct(product);
    _refocusSearchBar(delay: Duration.zero);
  }

  // A scanner with no ENTER/TAB still adds automatically after its last key.
  void _onHardwareSearchChanged(
    String value,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) {
    _hardwareScanTimer?.cancel();
    _textSearchTimer?.cancel();
    _searchGeneration++;

    final barcode = value.trim().toLowerCase();
    // Exact hardware barcode matches must stay immediate. Text searches are
    // debounced so the keyboard remains responsive even with a large catalog.
    if (barcode.isEmpty ||
        RegExp(r'^\d+$').hasMatch(barcode) ||
        (_productsByBarcode[barcode]?.isNotEmpty ?? false)) {
      _handleSearchInput(value, products);
    } else {
      // Do not leave unrelated old/default cards visible while the debounced
      // text search is pending. This also makes no-match results unambiguous.
      setState(() {
        _query = barcode;
        _scannedBarcodeProductId = null;
        _aiMatchedProductIds.clear();
        _aiSearchMessage = '';
        _aiResponseTimeMs = null;
        _visibleProducts = [];
      });
      _textSearchTimer = Timer(_textSearchDelay, () {
        if (!mounted || _searchController.text != value) return;
        _handleSearchInput(value, products);
      });
    }

    // Require a complete, unique catalog barcode before auto-processing.
    if (barcode.length < 6 || (_productsByBarcode[barcode]?.length ?? 0) != 1) {
      return;
    }

    _hardwareScanTimer = Timer(_scanQuietPeriod, () {
      if (!mounted || _searchController.text.trim().toLowerCase() != barcode) {
        return;
      }
      _commitHardwareBarcode(barcode);
    });
  }

  // Shows a short color-coded status message to the current user.
  void _message(String text, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  // Writes automatically detected POS/service problems to the service_issues collection for owner monitoring.
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

  // Search intent for broad categories and ambiguous Filipino descriptions.
  // Only real catalog entries can be returned; this never invents products.
  // Semantic category dictionary for cashier Filipino / English requests.
  // Match whole phrases rather than substrings ("cola" must not match
  // "chocolate"). A product must actually belong to the requested group.
  static const Map<String, List<String>> _categoryWords = {
    'softdrinks': [
      'softdrinks',
      'softdrink',
      'soft drinks',
      'soda',
      'cola',
      'coca cola',
      'coke',
      'sprite',
      'pepsi',
      'royal',
      '7up',
      '7 up',
      'rc cola',
      'mountain dew',
    ],
    'beverages': [
      'beverage',
      'beverages',
      'drink',
      'drinks',
      'inumin',
      'softdrinks',
      'softdrink',
      'soft drinks',
      'soda',
      'juice',
      'water',
      'tubig',
      'milk tea',
      'iced tea',
      'energy drink',
      'coffee',
      'kape',
      'gatas',
      'milk',
    ],
    'water': [
      'water',
      'tubig',
      'mineral water',
      'purified water',
      'drinking water',
    ],
    'juice': ['juice', 'fruit juice', 'katas', 'tetrapack'],
    'coffee': ['coffee', 'kape', 'nescafe', 'kopiko', 'cappuccino', '3 in 1'],
    'milk': [
      'milk',
      'gatas',
      'powdered milk',
      'evaporated',
      'condensed',
      'condensada',
      'fresh milk',
      'bear brand',
      'birch tree',
    ],
    'rice': ['rice', 'bigas', 'kanin', 'sinandomeng', 'dinorado', 'jasponica'],
    'salt': ['salt', 'asin', 'iodized salt', 'rock salt'],
    'oil': [
      'oil',
      'mantika',
      'cooking oil',
      'vegetable oil',
      'canola',
      'palm oil',
    ],
    'sugar': ['sugar', 'asukal', 'brown sugar', 'white sugar'],
    'flour': ['flour', 'harina', 'all purpose flour'],
    'noodles': [
      'noodles',
      'pancit canton',
      'pancit',
      'instant noodles',
      'mami',
      'sotanghon',
      'bihon',
    ],
    'canned': [
      'canned goods',
      'canned',
      'de lata',
      'delata',
      'sardines',
      'sardinas',
      'corned beef',
      'tuna',
      'meat loaf',
    ],
    'snacks': [
      'snack',
      'snacks',
      'chichirya',
      'chips',
      'cracker',
      'biscuit',
      'biskwit',
      'cookies',
      'junk food',
    ],
    'bread': ['bread', 'tinapay', 'loaf bread', 'pandesal'],
    'bathsoap': [
      'bath soap',
      'bathsoap',
      'sabon panligo',
      'body wash',
      'body soap',
      'bar soap',
      'safeguard',
      'dove soap',
    ],
    'laundry': [
      'laundry',
      'panlaba',
      'detergent',
      'washing powder',
      'laundry soap',
      'fabric conditioner',
      'fabcon',
      'downy',
      'surf',
      'ariel',
      'tide',
    ],
    'dishwashing': [
      'dishwashing',
      'dishwashing liquid',
      'dish soap',
      'panghugas',
      'panghugas ng plato',
      'joy dishwashing',
    ],
    'shampoo': [
      'shampoo',
      'shampo',
      'hair shampoo',
      'sunsilk',
      'head and shoulders',
    ],
    'toothpaste': ['toothpaste', 'pasta ng ngipin', 'colgate', 'closeup'],
    'cleaning': [
      'cleaner',
      'cleaning',
      'panglinis',
      'disinfectant',
      'bleach',
      'zonrox',
      'floor cleaner',
      'bathroom cleaner',
    ],
    'condiments': [
      'condiment',
      'condiments',
      'sawsawan',
      'toyo',
      'soy sauce',
      'suka',
      'vinegar',
      'patis',
      'fish sauce',
      'ketchup',
    ],
    'eggs': ['egg', 'eggs', 'itlog'],
    'diapers': ['diaper', 'diapers', 'lampin', 'pampers'],
  };

  static const Map<String, List<String>> _intentPhrases = {
    'softdrinks': [
      'softdrinks',
      'soft drinks',
      'softdrink',
      'soda',
      'cola',
      'coke',
      'coca cola',
      'cocacola',
      'sprite',
      'pepsi',
    ],
    'beverages': ['inumin', 'drink', 'drinks', 'beverage', 'beverages'],
    'water': ['tubig', 'water', 'mineral water'],
    'juice': ['juice', 'fruit juice', 'katas'],
    'coffee': ['kape', 'coffee', '3 in 1'],
    'milk': ['gatas', 'milk', 'condensada', 'evaporada'],
    'rice': ['bigas', 'rice'],
    'salt': ['asin', 'salt'],
    'oil': ['mantika', 'cooking oil', 'vegetable oil'],
    'sugar': ['asukal', 'sugar'],
    'flour': ['harina', 'flour'],
    'noodles': ['noodles', 'pancit canton', 'instant noodles', 'pancit'],
    'canned': [
      'canned goods',
      'canned',
      'de lata',
      'delata',
      'sardinas',
      'sardines',
      'corned beef',
    ],
    'snacks': ['chichirya', 'snacks', 'snack', 'biskwit', 'biscuits', 'chips'],
    'bread': ['tinapay', 'bread'],
    'bathsoap': [
      'sabon panligo',
      'sabon pangligo',
      'bath soap',
      'body wash',
      'panligo',
    ],
    'laundry': [
      'panlaba',
      'panglaba',
      'laundry',
      'detergent',
      'fabcon',
      'fabric conditioner',
    ],
    'dishwashing': [
      'panghugas',
      'dishwashing',
      'dish soap',
      'panghugas ng plato',
    ],
    'shampoo': ['shampoo', 'shampo'],
    'toothpaste': ['toothpaste', 'pasta ng ngipin'],
    'cleaning': ['panglinis', 'cleaner', 'disinfectant', 'bleach'],
    'condiments': ['sawsawan', 'condiments', 'toyo', 'suka', 'patis'],
    'eggs': ['itlog', 'eggs', 'egg'],
    'diapers': ['diapers', 'diaper', 'lampin'],
  };

  bool _containsSearchPhrase(String text, String phrase) {
    final p = _normalizeSearchText(phrase);
    return p.isNotEmpty && (' $text ').contains(' $p ');
  }

  // Meaningful request categories: choose the most specific group to avoid
  // "sabon panligo" accidentally showing detergent as "sabon".
  String? _requestedCategory(String query) {
    final q = _normalizeSearchText(query);
    if (q.isEmpty) return null;
    // Specific request first; otherwise generic beverage is appropriate.
    for (final entry in _intentPhrases.entries) {
      if (entry.value.any((word) => _containsSearchPhrase(q, word))) {
        return entry.key;
      }
    }
    return null;
  }

  // Volumes are taken only from explicit product name/unit fields. Unknown
  // sizes are shown as possible options, never falsely claimed to be large.
  double? _productVolumeMl(Map<String, dynamic> data) {
    final text = '${data['productName'] ?? ''} ${data['unit'] ?? ''}'
        .toLowerCase();
    final matches = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(ml|milliliter|millilitre|l|liter|litre|liters|litres)\b',
    ).allMatches(text);
    double? largest;
    for (final match in matches) {
      final number = double.tryParse(
        (match.group(1) ?? '').replaceAll(',', '.'),
      );
      if (number == null) continue;
      final unit = match.group(2)!;
      final ml = (unit == 'ml' || unit.startsWith('milli'))
          ? number
          : number * 1000;
      if (largest == null || ml > largest) largest = ml;
    }
    return largest;
  }

  // EÜ MART's local matching complements Gemini; the cashier chooses the
  // final product. Returns 0 when category/size contradict the request.
  int _intentSearchScore(Map<String, dynamic> data, String rawQuery) {
    final query = _normalizeSearchText(rawQuery);
    final group = _requestedCategory(query);
    if (group == null) return 0;

    final searchable = _normalizeSearchText(
      '${data['productName'] ?? ''} ${data['category'] ?? ''} '
      '${data['brand'] ?? ''} ${data['unit'] ?? ''} '
      '${data['aliases'] ?? data['searchAliases'] ?? ''}',
    );
    final terms = _categoryWords[group] ?? const <String>[];
    if (!terms.any((term) => _containsSearchPhrase(searchable, term))) {
      return 0;
    }

    // Additional brand constraint: "malaking coke" must not show Pepsi.
    final asksForCoke =
        _containsSearchPhrase(query, 'coke') ||
        _containsSearchPhrase(query, 'coca cola') ||
        _containsSearchPhrase(query, 'cocacola');
    if (asksForCoke &&
        !_containsSearchPhrase(searchable, 'coke') &&
        !_containsSearchPhrase(searchable, 'coca cola') &&
        !_containsSearchPhrase(searchable, 'cocacola')) {
      return 0;
    }

    final asksLarge = <String>[
      'malaki',
      'malaking',
      'large',
      'big',
      'family size',
      'litro',
    ].any((phrase) => _containsSearchPhrase(query, phrase));
    final asksSmall = <String>[
      'maliit',
      'maliiting',
      'small',
      'mini',
      'sachet',
    ].any((phrase) => _containsSearchPhrase(query, phrase));
    final volume = _productVolumeMl(data);
    if (asksLarge && volume != null && volume < 750) return 0;
    if (asksSmall && volume != null && volume > 500) return 0;

    // Exact size requests are restrictive, not just a soft ranking hint.
    final sizeQuery = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(ml|l|liter|litre|liters|litres)\b',
    ).firstMatch(query);
    if (sizeQuery != null) {
      final amount = double.tryParse(
        (sizeQuery.group(1) ?? '').replaceAll(',', '.'),
      );
      final unit = sizeQuery.group(2)!;
      final wantedMl = amount == null
          ? null
          : (unit == 'ml' ? amount : amount * 1000);
      if (wantedMl != null &&
          (volume == null || (volume - wantedMl).abs() > 1)) {
        return 0;
      }
    }
    return (asksLarge || asksSmall || sizeQuery != null)
        ? (volume == null ? 45 : 125)
        : 100;
  }

  // Scores local product relevance using exact matches, aliases, incomplete words, and conservative typo tolerance.
  int _localProductSearchScore(
    QueryDocumentSnapshot<Map<String, dynamic>> document, {
    bool strictProductWords = false,
  }) {
    final data = document.data();
    final query = _normalizeSearchText(_query);
    if (query.isEmpty) return 0;

    if (!strictProductWords) {
      final intentScore = _intentSearchScore(data, query);
      if (intentScore > 0) return intentScore;
      // Broad category queries retain the existing intent behavior.
      if (_requestedCategory(query) != null) return 0;
    }

    final productName = _normalizeSearchText(data['productName']);
    final brand = _normalizeSearchText(data['brand']);
    final category = _normalizeSearchText(data['category']);
    final unit = _normalizeSearchText(data['unit']);
    final barcode = _normalizeSearchText(data['barcode']);

    final queryCompact = query.replaceAll(' ', '');
    final nameCompact = productName.replaceAll(' ', '');

    // Exact barcode search remains exact and high priority.
    if (barcode.isNotEmpty && barcode == query) return 120;

    // Common cashier shortcut: coke means Coca-Cola, not every product
    // whose text happens to contain the letters "coke" or "cola".
    if (_isCokeQuery(query)) {
      if (nameCompact.contains('cocacola') ||
          nameCompact == 'coke' ||
          nameCompact.contains('coke')) {
        return 110;
      }
      return 0;
    }

    // Exact product-name or compact-name match gets the strongest score.
    if (productName == query ||
        (queryCompact.length >= 5 && nameCompact == queryCompact)) {
      return 110;
    }

    final queryWords = query
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    final nameWords = productName
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    // For a specific product query, every query word must match a product
    // name word, an approved alias, or a close typo. This avoids the old
    // substring bug where "cola" matched "chocolate".
    if (queryWords.isNotEmpty) {
      final allNameWordsMatch = queryWords.every((word) {
        final aliases = _searchAliases(word);
        return aliases.any((term) {
          final cleanTerm = _normalizeSearchText(term);
          if (cleanTerm.isEmpty) return false;

          if (nameWords.contains(cleanTerm)) return true;
          if (_hasCloseWord(productName, cleanTerm)) return true;

          // For multi-word aliases such as "coca cola", compare the compact
          // form only when it is sufficiently specific.
          final compactTerm = cleanTerm.replaceAll(' ', '');
          return compactTerm.length >= 5 && nameCompact.contains(compactTerm);
        });
      });

      if (allNameWordsMatch) return 90;
    }

    // For specific queries, never fall back to the whole brand/category.
    // A typo must still match *all* product-name words to be suggested.
    if (strictProductWords) return 0;

    // Brand/category/unit remain searchable, but only by whole-word or
    // close-word matching so broad substrings do not create false positives.
    for (final field in [brand, category, unit]) {
      final fieldWords = field
          .split(RegExp(r'\s+'))
          .where((word) => word.isNotEmpty)
          .toList();

      if (queryWords.isNotEmpty &&
          queryWords.every(
            (queryWord) => fieldWords.any(
              (fieldWord) =>
                  fieldWord == queryWord || _hasCloseWord(fieldWord, queryWord),
            ),
          )) {
        return 35;
      }
    }

    return 0;
  }

  // Checks whether the current value satisfies the is coke query rule used by this module.
  bool _isCokeQuery(String query) {
    final normalized = _normalizeSearchText(query).replaceAll(' ', '');
    return normalized == 'coke' || normalized == 'cocacola';
  }

  // Handles the normalize search text logic used by this module.
  String _normalizeSearchText(dynamic value) {
    return (value ?? '')
        .toString()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  // Expands approved cashier aliases while keeping matching controlled and product-specific.
  List<String> _searchAliases(String value) {
    final normalized = _normalizeSearchText(value);
    if (normalized.isEmpty) return <String>[];

    const aliases = <String, List<String>>{
      'coke': <String>['coca cola', 'cocacola', 'coke'],
      'coca': <String>['coca'],
      'cola': <String>['cola'],
      'cocacola': <String>['coca cola', 'cocacola', 'coke'],
    };

    final result = <String>[normalized];
    final direct = aliases[normalized];

    if (direct != null) {
      for (final alias in direct) {
        final cleanAlias = _normalizeSearchText(alias);
        if (cleanAlias.isNotEmpty && !result.contains(cleanAlias)) {
          result.add(cleanAlias);
        }
      }
    }

    // Resolve incomplete AND slightly misspelled forms for every configured
    // alias. Example: "cok" and "cokee" can resolve to the "coke" alias.
    // This is alias-based, so "cokee" will not accidentally become "coffee".
    if (normalized.length >= 3) {
      for (final entry in aliases.entries) {
        final aliasKey = _normalizeSearchText(entry.key);
        if (aliasKey.isEmpty) continue;

        final maxLength = aliasKey.length > normalized.length
            ? aliasKey.length
            : normalized.length;
        final distance = _levenshteinDistance(aliasKey, normalized);
        final similarity = 1 - (distance / maxLength);

        final prefixMatch =
            aliasKey.startsWith(normalized) || normalized.startsWith(aliasKey);
        final typoMatch =
            distance <= (maxLength <= 6 ? 1 : 2) && similarity >= 0.75;

        if (!prefixMatch && !typoMatch) continue;

        for (final alias in entry.value) {
          final cleanAlias = _normalizeSearchText(alias);
          if (cleanAlias.isNotEmpty && !result.contains(cleanAlias)) {
            result.add(cleanAlias);
          }
        }
      }
    }

    return result;
  }

  // Checks whether a typed word is sufficiently close to a product word without allowing overly broad matches.
  bool _hasCloseWord(String searchable, String queryWord) {
    final normalizedQuery = _normalizeSearchText(queryWord);
    if (normalizedQuery.length < 3) return false;

    final words = _normalizeSearchText(
      searchable,
    ).split(' ').where((word) => word.isNotEmpty);

    for (final word in words) {
      if (word == normalizedQuery) return true;

      // Allow incomplete product words, e.g. "nescaf" -> "nescafe".
      // Require at least 3 typed characters so very short searches do not
      // become overly broad.
      if (normalizedQuery.length >= 3 &&
          (word.startsWith(normalizedQuery) ||
              normalizedQuery.startsWith(word))) {
        return true;
      }

      final maxLength = word.length > normalizedQuery.length
          ? word.length
          : normalizedQuery.length;
      final lengthDifference = (word.length - normalizedQuery.length).abs();

      // Typo tolerance is intentionally conservative so a query such as
      // "cokee" does not incorrectly match "coffee".
      final allowedDistance = maxLength <= 4
          ? 1
          : maxLength <= 7
          ? 2
          : 3;

      if (lengthDifference > allowedDistance) continue;

      final distance = _levenshteinDistance(word, normalizedQuery);
      final similarity = 1 - (distance / maxLength);

      // Short/medium words need stronger similarity because two edits can
      // completely change the intended product. Longer words can safely
      // tolerate a little more variation.
      final minimumSimilarity = maxLength <= 6
          ? 0.72
          : maxLength <= 9
          ? 0.68
          : 0.65;

      if (distance <= allowedDistance && similarity >= minimumSimilarity) {
        return true;
      }
    }

    return false;
  }

  // Calculates edit distance used by typo-tolerant product matching.
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

  // AI-only constraints: catalog facts are checked before/after Gemini.
  // Standard product search, scanner and checkout are not affected.
  bool _aiProductFitsClues(Map<String, dynamic> data, String rawQuery) {
    final query = _normalizeSearchText(rawQuery);
    final price = (data['sellingPrice'] as num?)?.toDouble();
    final maxPrice = RegExp(
      r'(?:below|under|less than|maximum|max|hanggang|budget|di lalagpas sa|hindi lalagpas sa)\s*(?:ng|na|sa)?\s*(?:p|php|peso|pesos)?\s*(\d+(?:\.\d+)?)',
    ).firstMatch(query);
    final priceAtMost =
        maxPrice ??
        RegExp(
          r'(?:p|php|peso|pesos)\s*(\d+(?:\.\d+)?)\s*(?:pababa|or less)',
        ).firstMatch(query);
    final exactPrice = priceAtMost == null
        ? RegExp(
            r'(?:p|php|peso|pesos)\s*(\d+(?:\.\d+)?)\b|\b(\d+(?:\.\d+)?)\s*(?:pesos|peso)\b',
          ).firstMatch(query)
        : null;
    if (priceAtMost != null || exactPrice != null) {
      final requested = double.tryParse(
        (priceAtMost ?? exactPrice)!.group(1) ?? exactPrice?.group(2) ?? '',
      );
      if (requested != null &&
          (price == null ||
              (priceAtMost != null
                  ? price > requested
                  : (price - requested).abs() > 0.01))) {
        return false;
      }
    }

    // Restrict explicit volume requests; do not guess missing package sizes.
    final size = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(ml|milliliter|millilitre|l|liter|litre|liters|litres)\b',
    ).firstMatch(query);
    if (size != null) {
      final amount = double.tryParse(
        (size.group(1) ?? '').replaceAll(',', '.'),
      );
      final unit = size.group(2) ?? '';
      final wantedMl = amount == null
          ? null
          : (unit == 'ml' || unit.startsWith('milli') ? amount : amount * 1000);
      final actualMl = _productVolumeMl(data);
      if (wantedMl != null &&
          (actualMl == null || (actualMl - wantedMl).abs() > 1)) {
        return false;
      }
    }

    final volume = _productVolumeMl(data);
    final asksLarge = [
      'malaki',
      'malaking',
      'large',
      'big',
      'litro',
    ].any((word) => _containsSearchPhrase(query, word));
    final asksSmall = [
      'maliit',
      'small',
      'mini',
    ].any((word) => _containsSearchPhrase(query, word));
    if (asksLarge && volume != null && volume < 750) return false;
    if (asksSmall && volume != null && volume > 500) return false;

    // Negative requests must not return the explicitly excluded type.
    final nameAndCategory = _normalizeSearchText(
      '${data['productName'] ?? ''} ${data['category'] ?? ''}',
    );
    if ((query.contains('hindi panlaba') || query.contains('not detergent')) &&
        (nameAndCategory.contains('detergent') ||
            nameAndCategory.contains('laundry') ||
            nameAndCategory.contains('panlaba'))) {
      return false;
    }
    return true;
  }

  // Rank descriptions by concrete product-name clues, not just a broad category.
  int _aiClueWordScore(Map<String, dynamic> data, String rawQuery) {
    final nameAndBrand = _normalizeSearchText(
      '${data['productName'] ?? ''} ${data['brand'] ?? ''} ${data['unit'] ?? ''}',
    );
    const ignore = <String>{
      'yung',
      'ang',
      'na',
      'ng',
      'sa',
      'may',
      'ako',
      'hanap',
      'hanapin',
      'maliit',
      'malaki',
      'malaking',
      'large',
      'small',
      'big',
      'below',
      'under',
      'less',
      'than',
      'pesos',
      'peso',
      'php',
      'pababa',
      'hindi',
      'not',
      'para',
      'pang',
      'isang',
      'the',
      'stock',
      'available',
      'lang',
      'at',
      'or',
      'and',
    };
    var score = 0;
    for (final word in _normalizeSearchText(rawQuery).split(' ')) {
      if (word.length < 3 ||
          ignore.contains(word) ||
          RegExp(r'^\d+$').hasMatch(word))
        continue;
      if (_containsSearchPhrase(nameAndBrand, word)) {
        score += 35;
      } else if (_hasCloseWord(nameAndBrand, word)) {
        score += 14;
      }
    }
    return score;
  }

  // Scores products locally before the AI request so only relevant candidates are sent to Gemini.
  int _aiCandidateScore(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
    String rawQuery,
  ) {
    final data = document.data();
    if (!_aiProductFitsClues(data, rawQuery)) return 0;
    final clueScore = _aiClueWordScore(data, rawQuery);
    final intentScore = _intentSearchScore(data, rawQuery);
    if (intentScore > 0) return 1500 + intentScore + clueScore;
    if (_requestedCategory(rawQuery) != null) return 0;
    final localScore = _localProductSearchScore(document);
    if (localScore > 0) return 1000 + localScore + clueScore;

    final query = _normalizeSearchText(rawQuery);
    if (query.isEmpty) return 0;

    final searchable = _normalizeSearchText(
      '${data['productName'] ?? ''} ${data['brand'] ?? ''} ${data['category'] ?? ''}',
    );
    if (searchable.isEmpty) return 0;

    final queryWords = query.split(' ').where((w) => w.length >= 2).toList();
    final targetWords = searchable
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();
    if (queryWords.isEmpty || targetWords.isEmpty) return 0;

    var total = 0;
    for (final q in queryWords) {
      var best = 0.0;
      for (final word in targetWords) {
        if (word.startsWith(q) || q.startsWith(word)) {
          best = 1.0;
          break;
        }
        final maxLength = word.length > q.length ? word.length : q.length;
        if (maxLength == 0) continue;
        final distance = _levenshteinDistance(word, q);
        final similarity = 1 - (distance / maxLength);
        if (similarity > best) best = similarity;
      }
      if (best < 0.45) return 0;
      total += (best * 100).round();
    }
    return total + clueScore;
  }

  // Local exact matches and repeat queries return immediately. More difficult
  // searches still use Gemini with a compact, locally ranked candidate list.
  // No Firestore query or model change is introduced by this optimization.
  Future<void> _runAiSearch(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) async {
    if (_aiSearching) return;

    final query = _searchController.text.trim();
    final normalizedQuery = _normalizeSearchText(query);

    if (normalizedQuery.isEmpty) {
      _message('Enter a product description first.', Colors.orange);
      return;
    }

    // A network reply must not replace the results of a newer typed query.
    bool isCurrentQuery() =>
        mounted &&
        _normalizeSearchText(_searchController.text) == normalizedQuery;

    void showMatches(
      Iterable<String> productIds,
      String message, {
      int? aiResponseTimeMs,
    }) {
      if (!isCurrentQuery()) return;

      final ids = productIds.where(_productsById.containsKey).toList();
      setState(() {
        _aiMatchedProductIds
          ..clear()
          ..addAll(ids);
        _aiSearchMessage = message;
        // Null means Gemini was not called (instant local or cached result).
        _aiResponseTimeMs = aiResponseTimeMs;
        _visibleProducts = ids
            .map((id) => _productsById[id])
            .whereType<QueryDocumentSnapshot<Map<String, dynamic>>>()
            .take(_maxVisibleProducts)
            .toList();
      });
    }

    setState(() {
      _query = query.toLowerCase();
      _aiSearching = true;
      _aiMatchedProductIds.clear();
      _aiSearchMessage = '';
      _aiResponseTimeMs = null;
    });

    try {
      // Exact product names/barcodes don't need an AI request. Only bypass
      // Gemini when exactly one active product matches, to avoid ambiguity.
      final exactMatches = products.where((document) {
        final data = document.data();
        return _normalizeSearchText(data['productName']) == normalizedQuery ||
            (data['barcode'] ?? '').toString().trim().toLowerCase() ==
                query.toLowerCase();
      }).toList();

      if (exactMatches.length == 1) {
        showMatches(<String>[
          exactMatches.first.id,
        ], 'Exact product match found instantly (local search).');
        return;
      }

      // Full/whole-phrase product names (e.g. "coke mismo") are already
      // unambiguous catalog searches. Do not spend seconds or quota on Gemini.
      // Descriptions/constraints still go through AI identification.
      final asksDescription = RegExp(
        r'\b(yung|na|may|below|under|pesos|peso|php|malaki|malaking|maliit|large|small|hindi|not|pababa|sachet)\b',
      ).hasMatch(normalizedQuery);
      if (!asksDescription && normalizedQuery.split(' ').length >= 2) {
        final phraseMatches = products
            .where(
              (document) => _containsSearchPhrase(
                _normalizeSearchText(document.data()['productName']),
                normalizedQuery,
              ),
            )
            .toList();
        if (phraseMatches.isNotEmpty) {
          showMatches(
            phraseMatches.map((document) => document.id),
            'Exact product phrase found instantly (local catalog).',
          );
          return;
        }
      }

      // Only reuse matches from this page's loaded product catalog.
      final cachedIds = _aiSearchCache[normalizedQuery];
      if (cachedIds != null && cachedIds.isNotEmpty) {
        showMatches(
          cachedIds,
          'Showing ${cachedIds.length} saved AI suggestion(s) (no new request).',
        );
        return;
      }

      // Rank the locally cached catalog first. This does not query Firestore.
      final rankedCandidates =
          products
              .map(
                (document) => (
                  score: _aiCandidateScore(document, query),
                  document: document,
                ),
              )
              .where((entry) => entry.score > 0)
              .toList()
            ..sort((a, b) => b.score.compareTo(a.score));

      // Lower input size without changing the AI model or App Check tokens.
      // The highest-ranked candidates are retained for AI disambiguation.
      final aiCandidates = rankedCandidates
          .take(_maxAiCandidates)
          .map((entry) => entry.document)
          .toList();

      if (aiCandidates.isEmpty) {
        showMatches(const <String>[], 'AI found no relevant product.');
        return;
      }

      // Keep all existing matching attributes, but use short field labels and
      // skip empty values to reduce input tokens for each Gemini request.
      final productLines = aiCandidates
          .map((document) {
            final data = document.data();
            final fields = <String>[
              'ID:${document.id}',
              'N:${(data['productName'] ?? '').toString()}',
            ];
            void addIfPresent(String label, dynamic value) {
              final text = (value ?? '').toString().trim();
              if (text.isNotEmpty) fields.add('$label:$text');
            }

            addIfPresent('B', data['brand']);
            addIfPresent('C', data['category']);
            addIfPresent('U', data['unit']);
            addIfPresent('P', data['sellingPrice']);
            addIfPresent('S', data['stock']);
            addIfPresent('A', data['aliases'] ?? data['searchAliases']);
            return fields.join('|');
          })
          .join('\n');

      // Preserve the existing provider/model/App Check setup. Upgrading the
      // model is a separate, explicitly tested change.
      final ai = FirebaseAI.googleAI(useLimitedUseAppCheckTokens: true);
      final model = ai.generativeModel(model: 'gemini-3.6-flash');

      final prompt =
          '''
You identify matching store products for a cashier. The list below uses:
ID=Firestore ID; N=name; B=brand; C=category; U=unit; P=price; S=stock; A=aliases.
Identify the actual intended grocery product using Filipino/Taglish clues,
name misspellings, brand, product variant, packaging, and requested size.
Distinguish products with similar names; respect explicit exclusions.
Do not infer packaging color, price, size or stock absent from the data.
When a description fits multiple products, return only relevant IDs.
NEVER invent products. Return ONLY listed IDs separated by commas, or NONE.
Query: $query
Products:
$productLines
''';

      final stopwatch = Stopwatch()..start();
      final response = await model.generateContent(<Content>[
        Content.text(prompt),
      ]);
      stopwatch.stop();
      final aiResponseTimeMs = stopwatch.elapsedMilliseconds;
      debugPrint(
        'AI model response: ${aiResponseTimeMs}ms; '
        'candidates: ${aiCandidates.length}',
      );

      if (!isCurrentQuery()) return;

      final responseText = (response.text ?? '').trim();
      if (responseText.isEmpty || responseText.toUpperCase() == 'NONE') {
        final categoryFallback = aiCandidates
            .where(
              (product) =>
                  _aiProductFitsClues(product.data(), query) &&
                  _intentSearchScore(product.data(), query) > 0,
            )
            .map((product) => product.id)
            .take(_maxVisibleProducts)
            .toList();
        showMatches(
          categoryFallback,
          categoryFallback.isNotEmpty
              ? 'Showing local category matches (AI returned no IDs). Choose the exact product and size.'
              : 'AI found no relevant product.',
          aiResponseTimeMs: aiResponseTimeMs,
        );
        return;
      }

      final candidatesById =
          <String, QueryDocumentSnapshot<Map<String, dynamic>>>{
            for (final document in aiCandidates) document.id: document,
          };
      final ids = responseText
          .split(RegExp(r'[,\s]+'))
          .map((value) => value.trim())
          .where(candidatesById.containsKey)
          .where((id) {
            final product = candidatesById[id]!;
            if (!_aiProductFitsClues(product.data(), query)) return false;
            final intentScore = _intentSearchScore(product.data(), query);
            if (intentScore > 0) return true;
            final localScore = _localProductSearchScore(product);
            if (localScore >= 20) return true;

            // Retain the existing relevance gate for AI-suggested IDs.
            final productName = _normalizeSearchText(
              product.data()['productName'],
            );
            final queryWords = normalizedQuery
                .split(RegExp(r'\s+'))
                .where((word) => word.length >= 3)
                .toList();
            return queryWords.isNotEmpty &&
                queryWords.every((word) => _hasCloseWord(productName, word));
          })
          .toSet()
          .toList();

      // Semantic category queries may be broader than the model's response.
      // If the model returns NONE, keep locally validated real candidates.
      if (ids.isEmpty &&
          aiCandidates.any(
            (p) =>
                _aiProductFitsClues(p.data(), query) &&
                _intentSearchScore(p.data(), query) > 0,
          )) {
        final fallback = aiCandidates
            .where(
              (p) =>
                  _aiProductFitsClues(p.data(), query) &&
                  _intentSearchScore(p.data(), query) > 0,
            )
            .map((p) => p.id)
            .take(_maxVisibleProducts)
            .toList();
        showMatches(
          fallback,
          'Showing local category matches. Please choose the exact product and size.',
          aiResponseTimeMs: aiResponseTimeMs,
        );
        return;
      }

      if (ids.isNotEmpty) {
        if (_aiSearchCache.length >= _maxAiCachedQueries) {
          _aiSearchCache.remove(_aiSearchCache.keys.first);
        }
        _aiSearchCache[normalizedQuery] = ids;
      }

      showMatches(
        ids,
        ids.isEmpty
            ? 'AI found no relevant product.'
            : 'AI suggested ${ids.length} product(s).',
        aiResponseTimeMs: aiResponseTimeMs,
      );
    } catch (error, stackTrace) {
      debugPrint('AI search request failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (!isCurrentQuery()) return;

      final errorText = error.toString().toLowerCase();
      final isTemporaryAiIssue =
          errorText.contains('500') ||
          errorText.contains('high demand') ||
          errorText.contains('internal') ||
          errorText.contains('unavailable') ||
          errorText.contains('temporarily');

      // Keep the existing standard-search fallback, with scores computed
      // only once rather than repeatedly during sorting and filtering.
      final scored =
          products
              .map(
                (product) => (
                  score: _aiCandidateScore(product, query),
                  product: product,
                ),
              )
              .where((entry) => entry.score > 0)
              .toList()
            ..sort((a, b) => b.score.compareTo(a.score));
      final localMatches = scored
          .take(_maxVisibleProducts)
          .map((entry) => entry.product)
          .toList();

      if (!isCurrentQuery()) return;
      setState(() {
        _aiMatchedProductIds.clear();
        if (localMatches.isNotEmpty) {
          _visibleProducts = localMatches;
          _aiSearchMessage = isTemporaryAiIssue
              ? 'AI Search is temporarily unavailable. '
                    'Showing possible matches using standard search.'
              : 'AI Search is unavailable. '
                    'Showing possible matches using standard search.';
        } else {
          _aiSearchMessage = isTemporaryAiIssue
              ? 'AI Search is temporarily unavailable due to high demand. '
                    'Please try again later or use standard product search.'
              : 'AI Search is currently unavailable. '
                    'Please use standard product search and try again later.';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _aiSearching = false);
      }
    }
  }

  // Validates current stock, prepares transaction items, deducts stock, and writes the completed POS transaction.
  // A Firestore batch keeps transaction and inventory updates grouped as one operation.
  Future<String> _saveTransaction({
    required DateTime startedAt,
    required DateTime completedAt,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No logged-in cashier.');
    if (_cart.isEmpty) throw Exception('The cart is empty.');
    if (!_cash.isFinite || _cash < _total || _total <= 0) {
      throw Exception('Invalid payment amount or insufficient cash.');
    }

    final firestore = FirebaseFirestore.instance;
    final reference = firestore.collection('transactions').doc();
    final now = DateTime.now();
    final receiptNumber =
        'EU-${now.millisecondsSinceEpoch}-${reference.id.substring(0, 6).toUpperCase()}';
    final durationSeconds = completedAt
        .difference(startedAt)
        .inSeconds
        .clamp(0, 86400)
        .toInt();
    final serviceSpeed = _serviceSpeedLabel(durationSeconds);
    final cartItems = _cart.values.map((item) => item.copy()).toList();
    final cashPaid = _cash;

    // Read *all* product snapshots within one Firestore transaction before
    // writing any stock updates. Concurrent checkouts retry against new stock.
    await firestore.runTransaction<void>((transaction) async {
      final references = [
        for (final item in cartItems)
          firestore.collection('products').doc(item.productId),
      ];
      final snapshots = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final productReference in references) {
        snapshots.add(await transaction.get(productReference));
      }

      final purchasedItems = <Map<String, dynamic>>[];
      double verifiedTotal = 0;
      double verifiedSavings = 0;
      for (var index = 0; index < cartItems.length; index++) {
        final item = cartItems[index];
        final snapshot = snapshots[index];
        if (!snapshot.exists) {
          throw Exception('${item.productName} no longer exists.');
        }
        final data = snapshot.data() ?? <String, dynamic>{};
        final reason = _productSaleBlockReason(data);
        if (reason != null) throw Exception(reason);
        final stock = (data['stock'] as num?)?.toInt() ?? 0;
        if (item.quantity < 1 || stock < item.quantity) {
          throw Exception(
            'Not enough stock for ${item.productName}. Available: $stock.',
          );
        }

        // A held/stale cart must not charge an outdated price or promotion.
        final regularPrice = (data['sellingPrice'] as num?)?.toDouble() ?? 0;
        final promoActive = _isPromoCurrentlyActive(data);
        final promoType = promoActive
            ? (data['promoType'] ?? '').toString()
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
        if (regularPrice <= 0 ||
            !regularPrice.isFinite ||
            (item.price - effectivePrice).abs() > 0.001 ||
            item.promoActive != promoActive ||
            (promoActive && item.promoType != promoType)) {
          throw Exception(
            'Price or promotion changed for ${item.productName}. '
            'Please remove and re-add the product before payment.',
          );
        }
        verifiedTotal += item.subtotal;
        verifiedSavings += item.savings;
        purchasedItems.add({
          'productId': item.productId,
          'productName': item.productName,
          'barcode': item.barcode,
          'unit': item.unit,
          'price': item.price,
          'regularPrice': item.regularPrice,
          'buyingPrice': (data['buyingPrice'] as num?)?.toDouble() ?? 0,
          'quantity': item.quantity,
          'chargedQuantity': item.chargedQuantity,
          'subtotal': item.subtotal,
          'promoApplied': item.promoActive,
          'promoType': item.promoType,
          'promoLabel': item.promoLabel,
        });
      }
      if (verifiedTotal <= 0 || cashPaid < verifiedTotal) {
        throw Exception('Insufficient cash or invalid total.');
      }
      // All reads have completed; writes are now atomic.
      for (var index = 0; index < cartItems.length; index++) {
        final item = cartItems[index];
        final stock = (snapshots[index].data()?['stock'] as num?)?.toInt() ?? 0;
        transaction.update(references[index], {
          'stock': stock - item.quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      transaction.set(reference, {
        'receiptNumber': receiptNumber,
        'transactionNumber': receiptNumber,
        'items': purchasedItems,
        'total': verifiedTotal,
        'totalSavings': verifiedSavings,
        'cash': cashPaid,
        'change': cashPaid - verifiedTotal,
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
    });
    return receiptNumber;
  }

  // Handles the remember scanned product logic used by this module.
  void _rememberScannedProduct(
    QueryDocumentSnapshot<Map<String, dynamic>> product,
  ) {
    if (!mounted) return;

    setState(() {
      _recentScannedProductIds.remove(product.id);
      _recentScannedProductIds.insert(0, product.id);
      if (_recentScannedProductIds.length > 5) {
        _recentScannedProductIds.removeLast();
      }
    });
  }

  // Opens a price-lookup scanner. Scanning shows product details first;
  // the product is added to the cart only after explicit confirmation.
  // Hardware barcode scanning in the main search field is unchanged.
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
    String? lookupMessage;
    QueryDocumentSnapshot<Map<String, dynamic>>? lookedUpProduct;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Resolve a scan using the already loaded catalog. Do not edit the
            // cart, start the transaction timer, or deduct any stock here.
            Future<void> lookUpBarcode(String value) async {
              final barcode = value.trim();
              if (processing || barcode.isEmpty) return;

              setDialogState(() {
                processing = true;
                detected = true;
                lookupMessage = null;
                lookedUpProduct = null;
              });

              final matches =
                  _productsByBarcode[barcode.toLowerCase()] ?? const [];
              if (!dialogContext.mounted) return;

              if (matches.length == 1) {
                // Stop camera detection so the displayed product stays stable
                // while the customer decides whether to buy it.
                setDialogState(() {
                  lookedUpProduct = matches.single;
                  manualController.text = barcode;
                  processing = false;
                });
                unawaited(scannerController.stop().catchError((_) {}));
              } else {
                final isDuplicate = matches.length > 1;
                setDialogState(() {
                  lookupMessage = isDuplicate
                      ? 'This barcode belongs to multiple products. '
                            'Please correct the duplicate barcode first.'
                      : 'No product found for barcode $barcode.';
                  processing = false;
                  detected = false;
                });
                // Preserve the existing automatic service-issue reporting for
                // duplicate and unrecognized barcodes.
                unawaited(
                  _logAutomaticServiceIssue(
                    issueType: isDuplicate
                        ? 'Duplicate Barcode'
                        : 'Barcode Not Recognized',
                    severity: 'Moderate',
                    description: isDuplicate
                        ? 'The POS found multiple active products using the same barcode $barcode.'
                        : 'The POS could not find a product for barcode $barcode.',
                    details: {
                      'barcode': barcode,
                      'searchMethod': 'barcode price lookup',
                      if (isDuplicate)
                        'matchingProductIds': matches
                            .map((product) => product.id)
                            .toList(),
                    },
                  ).catchError((_) {}),
                );
              }
            }

            Future<void> scanAnother() async {
              if (processing) return;
              setDialogState(() {
                lookedUpProduct = null;
                lookupMessage = null;
                detected = false;
                manualController.clear();
              });
              try {
                await scannerController.start();
              } catch (_) {
                // Manual lookup stays available when the camera is unavailable.
              }
            }

            Future<void> closeDialog() async {
              if (processing) return;
              try {
                await scannerController.stop();
              } catch (_) {
                // Camera may already be stopped after a successful lookup.
              }
              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
            }

            final product = lookedUpProduct;
            final productData = product?.data();
            final productName =
                (productData?['productName'] ?? 'Unknown Product').toString();
            final sellingPrice =
                (productData?['sellingPrice'] as num?)?.toDouble() ?? 0;
            final stock = (productData?['stock'] as num?)?.toInt() ?? 0;
            final isActive = productData?['isActive'] != false;
            final saleBlockReason = productData == null
                ? null
                : _productSaleBlockReason(productData);
            final canAdd =
                product != null && saleBlockReason == null && stock > 0;
            final promoActive = productData == null
                ? false
                : _isPromoCurrentlyActive(productData);
            final promoType = promoActive
                ? (productData['promoType'] ?? '').toString()
                : '';
            final promoPrice = promoActive
                ? (productData['promoPrice'] as num?)?.toDouble()
                : null;
            final displayPrice =
                promoActive &&
                    promoType != 'Buy 1 Take 1' &&
                    promoPrice != null &&
                    promoPrice > 0 &&
                    promoPrice < sellingPrice
                ? promoPrice
                : sellingPrice;

            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: Color(0xFF1565C0)),
                  SizedBox(width: 10),
                  Expanded(child: Text('Barcode Price Lookup')),
                ],
              ),
              content: SizedBox(
                width: 620,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Scan a barcode to check the product price. '
                        'Nothing will be added to the cart unless you choose Add to Cart.',
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 12),
                      if (product == null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            height: (MediaQuery.sizeOf(context).height * 0.40)
                                .clamp(180.0, 360.0)
                                .toDouble(),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                MobileScanner(
                                  controller: scannerController,
                                  onDetect: (capture) {
                                    if (detected || processing) return;
                                    for (final detectedBarcode
                                        in capture.barcodes) {
                                      final value = detectedBarcode.rawValue;
                                      if (value != null &&
                                          value.trim().isNotEmpty) {
                                        lookUpBarcode(value);
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
                                              'The POS barcode scanner camera was unavailable or already in use.',
                                          details: {
                                            'scannerError': error.toString(),
                                          },
                                        ).catchError((_) {}),
                                      );
                                    }
                                    return Container(
                                      color: Colors.black87,
                                      padding: const EdgeInsets.all(24),
                                      alignment: Alignment.center,
                                      child: const Text(
                                        'Camera unavailable or already in use.\n'
                                        'You can enter the barcode manually below.',
                                        style: TextStyle(color: Colors.white),
                                        textAlign: TextAlign.center,
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
                      if (product != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F7FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCADCF2)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PRODUCT FOUND',
                                style: TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                productName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text('Barcode: ${productData?['barcode'] ?? ''}'),
                              Text('Stock available: $stock'),
                              if (saleBlockReason != null)
                                Text(
                                  saleBlockReason,
                                  style: const TextStyle(
                                    color: Color(0xFF1565C0),
                                  ),
                                )
                              else if (!isActive)
                                const Text(
                                  'This product is inactive.',
                                  style: TextStyle(color: Colors.red),
                                )
                              else if (stock <= 0)
                                const Text(
                                  'Out of stock',
                                  style: TextStyle(color: Colors.red),
                                ),
                              const SizedBox(height: 10),
                              Text(
                                'Selling Price: PHP ${displayPrice.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF167D46),
                                ),
                              ),
                              if (displayPrice != sellingPrice)
                                Text(
                                  'Regular Price: PHP ${sellingPrice.toStringAsFixed(2)}',
                                ),
                              if (promoActive && promoType == 'Buy 1 Take 1')
                                const Text('Active promotion: Buy 1 Take 1'),
                            ],
                          ),
                        ),
                      if (lookupMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          lookupMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                      const SizedBox(height: 14),
                      if (product == null)
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: manualController,
                                enabled: !processing,
                                onSubmitted: lookUpBarcode,
                                decoration: const InputDecoration(
                                  labelText: 'Manual Barcode Entry',
                                  hintText: 'Enter or paste barcode',
                                  prefixIcon: Icon(Icons.numbers),
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton.icon(
                              onPressed: processing
                                  ? null
                                  : () => lookUpBarcode(manualController.text),
                              icon: const Icon(Icons.search),
                              label: const Text('LOOK UP'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (product != null)
                  TextButton.icon(
                    onPressed: processing ? null : scanAnother,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan Another'),
                  ),
                TextButton(
                  onPressed: processing ? null : closeDialog,
                  child: const Text('Close'),
                ),
                if (product != null)
                  ElevatedButton.icon(
                    onPressed: canAdd && !processing
                        ? () {
                            // This is the only path that adds a camera/manual
                            // lookup result to the cart.
                            _addProduct(product);
                            _rememberScannedProduct(product);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          }
                        : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Cart'),
                  ),
              ],
            );
          },
        );
      },
    );

    manualController.dispose();
    unawaited(scannerController.dispose().catchError((_) {}));
    _refocusSearchBar(delay: const Duration(milliseconds: 20));
  }

  // Builds the printable POS receipt, including store information, purchased items, totals, and customer-feedback QR code.
  Future<void> _printReceipt({
    required String receiptNumber,
    required List<_CartItem> items,
    required double total,
    required double cash,
    required double change,
    required int paperWidthMm,
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

    final isNarrow = paperWidthMm == 58;
    // Receipt width is in millimetres. Height follows the roll content.
    final receiptFormat = PdfPageFormat(
      paperWidthMm * PdfPageFormat.mm,
      double.infinity,
    );
    final document = pw.Document();

    document.addPage(
      pw.Page(
        pageFormat: receiptFormat,
        margin: pw.EdgeInsets.symmetric(
          horizontal: isNarrow ? 9 : 13,
          vertical: 10,
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                storeName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: isNarrow ? 14 : 18,
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
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              item.promoType == 'Buy 1 Take 1'
                                  ? '${item.quantity} item(s), pay ${item.chargedQuantity} x PHP ${item.price.toStringAsFixed(2)}'
                                  : '${item.quantity} x PHP ${item.price.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: isNarrow ? 7 : 8),
                            ),
                          ),
                          pw.SizedBox(width: 4),
                          pw.Text(
                            'PHP ${item.subtotal.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontSize: isNarrow ? 7 : 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              pw.Divider(),
              if (_totalSavings > 0)
                _pdfMoneyRow(
                  'YOU SAVED',
                  _totalSavings,
                  bold: true,
                  isNarrow: isNarrow,
                ),
              _pdfMoneyRow('TOTAL', total, bold: true, isNarrow: isNarrow),
              _pdfMoneyRow('CASH', cash, isNarrow: isNarrow),
              _pdfMoneyRow('CHANGE', change, bold: true, isNarrow: isNarrow),
              pw.SizedBox(height: 12),
              pw.Text(
                receiptFooter,
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 9),
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.BarcodeWidget(
                  barcode: pw.Barcode.qrCode(),
                  data: _feedbackUrl,
                  width: isNarrow ? 72 : 82,
                  height: isNarrow ? 72 : 82,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'SCAN TO RATE YOUR EXPERIENCE',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                'Your feedback helps EÜ MART improve its service.',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7),
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

  // Handles the pdf money row logic used by this module.
  pw.Widget _pdfMoneyRow(
    String label,
    double value, {
    bool bold = false,
    bool isNarrow = false,
  }) {
    final style = pw.TextStyle(
      fontSize: isNarrow ? 9 : 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );

    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.Expanded(child: pw.Text(label, style: style)),
          pw.SizedBox(width: 4),
          pw.Text('PHP ${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }

  // Persists the current cart as a held transaction so it can be resumed later.
  Future<void> _holdTransaction() async {
    if (_cart.isEmpty) {
      _message('The cart is empty.', Colors.orange);
      return;
    }

    final labelController = TextEditingController();

    final label = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        // Handles the alert dialog logic used by this module.
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

  // Opens the held transactions interface using the current record or screen state.
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
        // Handles the alert dialog logic used by this module.
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
                  // Handles the center logic used by this module.
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // Handles the center logic used by this module.
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
                  // Handles the center logic used by this module.
                  return const Center(
                    child: Text(
                      'No held transactions.',
                      style: TextStyle(color: Colors.grey, fontSize: 17),
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: held.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final document = held[index];
                    final data = document.data();

                    final items =
                        data['items'] as List<dynamic>? ?? <dynamic>[];

                    final label = (data['label'] ?? 'Held Cart').toString();

                    final total =
                        (data['estimatedTotal'] as num?)?.toDouble() ?? 0;

                    final createdAt = _readTimestamp(data['createdAt']);

                    // Handles the card logic used by this module.
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

  // Normalizes Firestore timestamps or date strings into DateTime values.
  DateTime? _readTimestamp(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Formats held date into a user-friendly display value.
  String _formatHeldDate(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.month}/${date.day}/${date.year} '
        '$hour:$minute $period';
  }

  // Restores a held cart after rechecking current product availability and stock.
  Future<bool> _resumeHeldTransaction(
    QueryDocumentSnapshot<Map<String, dynamic>> heldDocument,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) async {
    if (_cart.isNotEmpty) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          // Handles the alert dialog logic used by this module.
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
      final reason = _productSaleBlockReason(currentData);
      if (reason != null) {
        unavailable.add(reason);
        continue;
      }
      final currentStock = (currentData['stock'] as num?)?.toInt() ?? 0;

      final requestedQuantity = (item['quantity'] as num?)?.toInt() ?? 1;

      if (currentStock < requestedQuantity) {
        unavailable.add(
          '${(item['productName'] ?? 'Unknown Product')} '
          '(needs $requestedQuantity, stock $currentStock)',
        );
        continue;
      }

      final regularPrice =
          (currentData['sellingPrice'] as num?)?.toDouble() ?? 0;
      final promoActive = _isPromoCurrentlyActive(currentData);
      final promoType = promoActive
          ? (currentData['promoType'] ?? '').toString()
          : '';
      final promoPrice = promoActive
          ? (currentData['promoPrice'] as num?)?.toDouble()
          : null;
      final currentPrice =
          promoActive &&
              promoType != 'Buy 1 Take 1' &&
              promoPrice != null &&
              promoPrice > 0 &&
              promoPrice < regularPrice
          ? promoPrice
          : regularPrice;
      final savedPrice = (item['price'] as num?)?.toDouble() ?? 0;
      if (regularPrice <= 0 ||
          (currentPrice - savedPrice).abs() > 0.001 ||
          (item['promoActive'] == true) != promoActive ||
          (promoActive && (item['promoType'] ?? '').toString() != promoType)) {
        unavailable.add(
          '${(item['productName'] ?? 'Product')} (price/promo changed; add again)',
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

  // Deletes the selected held transaction record after the required checks.
  Future<void> _deleteHeldTransaction(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        // Handles the alert dialog logic used by this module.
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

  // Coordinates payment validation, transaction saving, receipt handling, and transaction-state reset.
  Future<void> _payNow() async {
    if (_processing) return;
    if (_cart.isEmpty) {
      _message('The cart is empty.', Colors.orange);
      return;
    }

    if (!_cash.isFinite || _total <= 0 || _cash < _total) {
      _message('Invalid payment or insufficient cash.', Colors.red);
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

      // Refresh only purchased products, not the entire catalog after every sale.
      // The transaction has already committed; a refresh failure must never
      // cause the cashier to retry an already-successful payment.
      try {
        await _refreshPurchasedProducts(
          items.map((item) => item.productId).toSet(),
        );
      } catch (error) {
        debugPrint(
          'Targeted product refresh failed; reloading catalog: $error',
        );
        await _loadProducts();
      }

      if (!mounted) return;

      // Use the Receipt Footer Message saved in Settings for the
      // on-screen transaction receipt as well.
      final settingsSnapshot = await FirebaseFirestore.instance
          .collection('settings')
          .doc('system')
          .get();
      final settings = settingsSnapshot.data() ?? <String, dynamic>{};
      final receiptFooter =
          (settings['receiptFooter'] ?? 'Thank you for shopping at EÜ MART!')
              .toString();

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

          // Handles the dialog logic used by this module.
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
                                  // Handles the icon logic used by this module.
                                  return const Icon(
                                    Icons.storefront_rounded,
                                    size: 45,
                                    color: Color(0xFF1565C0),
                                  );
                                },
                              ),
                            ),
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 10),
                            // Handles the text logic used by this module.
                            const Text(
                              'EÜ MART',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 4),
                            // Handles the text logic used by this module.
                            const Text(
                              'SALES RECEIPT',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.4,
                              ),
                            ),
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.16),
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
                                      // Handles the expanded logic used by this module.
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
                                  // Handles the sized box logic used by this module.
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      // Handles the expanded logic used by this module.
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
                                  // Handles the sized box logic used by this module.
                                  const SizedBox(height: 7),
                                  Row(
                                    children: [
                                      // Handles the expanded logic used by this module.
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
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 18),
                            // Handles the row logic used by this module.
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
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 8),
                            // Handles the divider logic used by this module.
                            const Divider(height: 1),
                            // Handles the sized box logic used by this module.
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
                            // Handles the divider logic used by this module.
                            const Divider(height: 1),
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 13),
                            if (_totalSavings > 0) ...[
                              _receiptRow('You Saved', _totalSavings),
                              // Handles the sized box logic used by this module.
                              const SizedBox(height: 7),
                            ],
                            _receiptRow('Total', total),
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 7),
                            _receiptRow('Cash', cash),
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 7),
                            _receiptRow('Change', change),
                            // Handles the sized box logic used by this module.
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
                                  // Handles the expanded logic used by this module.
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
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 20),
                            Text(
                              receiptFooter,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF172033),
                              ),
                            ),
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 16),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFE),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFDDE6F1),
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Handles the text logic used by this module.
                                  const Text(
                                    'How was your experience?',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF172033),
                                    ),
                                  ),
                                  // Handles the sized box logic used by this module.
                                  const SizedBox(height: 9),
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    color: Colors.white,
                                    child: QrImageView(
                                      data: _feedbackUrl,
                                      version: QrVersions.auto,
                                      size: 112,
                                      backgroundColor: Colors.white,
                                    ),
                                  ),
                                  // Handles the sized box logic used by this module.
                                  const SizedBox(height: 7),
                                  // Handles the text logic used by this module.
                                  const Text(
                                    'Scan to rate your experience',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF1565C0),
                                    ),
                                  ),
                                  // Handles the sized box logic used by this module.
                                  const SizedBox(height: 3),
                                  // Handles the text logic used by this module.
                                  const Text(
                                    'Use your phone camera to open the EÜ MART feedback page.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Handles the sized box logic used by this module.
                            const SizedBox(height: 18),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () async {
                                      // Builds the printable POS receipt, including store information, purchased items, totals, and customer-feedback QR code.
                                      // Ask before printing, so cashiers can match
                                      // the PDF to the store's actual receipt roll.
                                      final chosenWidth = await showDialog<int>(
                                        context: context,
                                        builder: (sizeDialogContext) => SimpleDialog(
                                          title: const Text(
                                            'Receipt paper size',
                                          ),
                                          children: [
                                            for (final width in const [58, 80])
                                              SimpleDialogOption(
                                                onPressed: () => Navigator.of(
                                                  sizeDialogContext,
                                                ).pop(width),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 7,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      Icon(
                                                        _receiptPaperWidthMm ==
                                                                width
                                                            ? Icons
                                                                  .radio_button_checked
                                                            : Icons
                                                                  .radio_button_unchecked,
                                                        color: const Color(
                                                          0xFF1565C0,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Text(
                                                        '$width mm receipt paper',
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                      if (chosenWidth == null || !mounted) {
                                        return;
                                      }
                                      _receiptPaperWidthMm = chosenWidth;
                                      await _printReceipt(
                                        receiptNumber: receiptNumber,
                                        items: items,
                                        total: total,
                                        cash: cash,
                                        change: change,
                                        paperWidthMm: chosenWidth,
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
                                // Handles the sized box logic used by this module.
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

  // Handles the receipt row logic used by this module.
  Widget _receiptRow(String label, double value) {
    // Handles the padding logic used by this module.
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

  // Dynamic category filters are derived from existing product records.
  // No additional Firestore collection or schema change is required.
  String _productCategory(Map<String, dynamic> data) {
    final category = (data['category'] ?? '').toString().trim();
    return category.isEmpty ? 'Uncategorized' : category;
  }

  List<String> get _productCategories {
    final categories = <String, String>{};
    for (final product in _activeProducts) {
      final category = _productCategory(product.data());
      categories.putIfAbsent(category.toLowerCase(), () => category);
    }
    final sorted = categories.values.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return ['All', ...sorted.where((name) => name.toLowerCase() != 'all')];
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _categoryFilteredProducts(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> searchResults,
  ) {
    // An exact scanned barcode remains visible regardless of category.
    if (_scannedBarcodeProductId != null) return searchResults;

    // For category browsing, filter the whole active catalog BEFORE the
    // display limit; otherwise products beyond the first 80 are hidden.
    final source = _query.trim().isEmpty ? _activeProducts : searchResults;
    final filtered = _selectedCategory == 'All'
        ? source
        : source.where(
            (document) =>
                _productCategory(document.data()).toLowerCase() ==
                _selectedCategory.toLowerCase(),
          );
    return filtered.take(_maxVisibleProducts).toList();
  }

  Widget _categoryChips(List<String> categories) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final selected = _selectedCategory == category;
          return ChoiceChip(
            label: Text(category),
            selected: selected,
            onSelected: (_) => setState(() => _selectedCategory = category),
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

  // Handles the product panel logic used by this module.
  Widget _productPanel(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> allProducts,
  ) {
    final displayedProducts = _categoryFilteredProducts(products);
    // Handles the column logic used by this module.
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, toolbarConstraints) {
            final isMobile = toolbarConstraints.maxWidth < 900;

            final searchField = TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) =>
                  _onHardwareSearchChanged(value, allProducts),
              onSubmitted: (value) async {
                _textSearchTimer?.cancel();
                _searchGeneration++;
                final normalized = value.trim();
                if (normalized.isEmpty) return;

                final exactBarcodeMatches =
                    _productsByBarcode[normalized.toLowerCase()] ?? const [];

                if (exactBarcodeMatches.length == 1) {
                  _commitHardwareBarcode(normalized);
                  return;
                }

                if (exactBarcodeMatches.length > 1) {
                  _message(
                    'Barcode $normalized is assigned to multiple products. Please fix the duplicate barcode.',
                    Colors.red,
                  );
                  return;
                }

                // Runs AI-assisted product retrieval after local candidate ranking.
                // Only validated Firestore product IDs are accepted so AI cannot create products outside the store catalog.
                await _runAiSearch(allProducts);
                _focusSearchBar();
              },
              decoration: InputDecoration(
                hintText: isMobile
                    ? 'Search product or scan barcode'
                    : 'Search product name or description, or scan a barcode',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _hardwareScanTimer?.cancel();
                          _textSearchTimer?.cancel();
                          _searchGeneration++;
                          _searchController.clear();
                          setState(() {
                            _query = '';
                            _scannedBarcodeProductId = null;
                            _aiMatchedProductIds.clear();
                            _aiSearchMessage = '';
                            _aiResponseTimeMs = null;
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
            );

            final scanButton = SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => _openPosBarcodeScanner(allProducts),
                icon: const Icon(Icons.qr_code_scanner),
                label: const FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('SCAN BARCODE', maxLines: 1, softWrap: false),
                ),
              ),
            );

            final aiButton = SizedBox(
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
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _aiSearching ? 'SEARCHING...' : 'AI SEARCH',
                    maxLines: 1,
                    softWrap: false,
                  ),
                ),
              ),
            );

            if (isMobile) {
              // Handles the column logic used by this module.
              return Column(
                children: [
                  searchField,
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: scanButton),
                      // Handles the sized box logic used by this module.
                      const SizedBox(width: 8),
                      Expanded(child: aiButton),
                    ],
                  ),
                ],
              );
            }

            // Handles the row logic used by this module.
            return Row(
              children: [
                Expanded(child: searchField),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 10),
                scanButton,
                // Handles the sized box logic used by this module.
                const SizedBox(width: 10),
                aiButton,
              ],
            );
          },
        ),
        if (_aiSearchMessage.isNotEmpty) ...[
          // Handles the sized box logic used by this module.
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
          if (_aiResponseTimeMs != null) ...[
            // Handles the sized box logic used by this module.
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'AI Response Time: '
                '${(_aiResponseTimeMs! / 1000).toStringAsFixed(2)} seconds',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ],
        const SizedBox(height: 10),
        _categoryChips(_productCategories),
        // Handles the sized box logic used by this module.
        const SizedBox(height: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_query.isEmpty && _recentScannedProductIds.isNotEmpty) ...[
                // Handles the text logic used by this module.
                const Text(
                  'Recently scanned',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF263238),
                  ),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(height: 10),
                SizedBox(
                  height: 180,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentScannedProductIds.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 14),
                    itemBuilder: (context, index) {
                      final id = _recentScannedProductIds[index];
                      final document = _productsById[id];

                      if (document == null) {
                        return const SizedBox.shrink();
                      }

                      final data = document.data();
                      final name = (data['productName'] ?? 'Unknown Product')
                          .toString();
                      final price =
                          (data['sellingPrice'] as num?)?.toDouble() ?? 0;
                      final stock = (data['stock'] as num?)?.toInt() ?? 0;

                      // Handles the sized box logic used by this module.
                      return SizedBox(
                        width: 260,
                        child: _PosProductCard(
                          name: name,
                          price: price,
                          stock: stock,
                          highlighted: true,
                          onTap: stock > 0 ? () => _addProduct(document) : null,
                        ),
                      );
                    },
                  ),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(height: 16),
              ],
              Expanded(
                child: displayedProducts.isEmpty
                    ? const Center(child: Text('No matching products found.'))
                    : GridView.builder(
                        itemCount: displayedProducts.length,
                        gridDelegate:
                            // Handles the sliver grid delegate with max cross axis extent logic used by this module.
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 280,
                              mainAxisExtent: 180,
                              crossAxisSpacing: 14,
                              mainAxisSpacing: 14,
                            ),
                        itemBuilder: (context, index) {
                          final document = displayedProducts[index];
                          final data = document.data();
                          final name =
                              (data['productName'] ?? 'Unknown Product')
                                  .toString();
                          final price =
                              (data['sellingPrice'] as num?)?.toDouble() ?? 0;
                          final stock = (data['stock'] as num?)?.toInt() ?? 0;

                          // Handles the pos product card logic used by this module.
                          return _PosProductCard(
                            name: name,
                            price: price,
                            stock: stock,
                            highlighted: _aiMatchedProductIds.contains(
                              document.id,
                            ),
                            onTap: stock > 0
                                ? () => _addProduct(document)
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Handles the cart panel logic used by this module.
  Widget _cartPanel(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) {
    // Handles the container logic used by this module.
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
          LayoutBuilder(
            builder: (context, headerConstraints) {
              final compact = headerConstraints.maxWidth < 360;

              final title = Row(
                mainAxisSize: MainAxisSize.min,
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
                  // Handles the sized box logic used by this module.
                  const SizedBox(width: 12),
                  // Handles the flexible logic used by this module.
                  const Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Shopping Cart',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF172033),
                          ),
                        ),
                        Text(
                          'Review items before payment',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Color(0xFF7D8796),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );

              final timer = _transactionStartedAt == null
                  ? const SizedBox.shrink()
                  : Container(
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
                          // Handles the icon logic used by this module.
                          const Icon(
                            Icons.timer_outlined,
                            size: 17,
                            color: Color(0xFF1565C0),
                          ),
                          // Handles the sized box logic used by this module.
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
                    );

              if (compact) {
                // Handles the column logic used by this module.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    title,
                    if (_transactionStartedAt != null) ...[
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 10),
                      timer,
                    ],
                  ],
                );
              }

              // Handles the row logic used by this module.
              return Row(
                children: [
                  Expanded(child: title),
                  if (_transactionStartedAt != null) timer,
                ],
              );
            },
          ),
          // Handles the sized box logic used by this module.
          const SizedBox(height: 16),
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
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
                    ),
                  )
                : ListView.separated(
                    itemCount: _cart.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final item = _cart.values.elementAt(index);

                      // Handles the container logic used by this module.
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
                            _EditableCartQuantity(
                              key: ValueKey(item.productId),
                              quantity: item.quantity,
                              availableStock: item.availableStock,
                              onChanged: (quantity) =>
                                  _setCartQuantity(item, quantity),
                              onInvalid: (message) =>
                                  _message(message, Colors.orange),
                            ),
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
          // Handles the divider logic used by this module.
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
                  // Handles the icon logic used by this module.
                  const Icon(
                    Icons.savings_outlined,
                    color: Colors.green,
                    size: 20,
                  ),
                  // Handles the sized box logic used by this module.
                  const SizedBox(width: 8),
                  // Handles the expanded logic used by this module.
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
                // Handles the expanded logic used by this module.
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
          // Handles the sized box logic used by this module.
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
          // Handles the sized box logic used by this module.
          const SizedBox(height: 14),
          Row(
            children: [
              // Handles the expanded logic used by this module.
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
          // Handles the sized box logic used by this module.
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, actionConstraints) {
              final stackButtons = actionConstraints.maxWidth < 340;

              final holdButton = SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _processing ? null : _holdTransaction,
                  icon: const Icon(Icons.pause_circle_outline, size: 19),
                  label: const Text('HOLD', maxLines: 1, softWrap: false),
                ),
              );

              final resumeButton = SizedBox(
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: _processing
                      ? null
                      : () => _showHeldTransactions(products),
                  icon: const Icon(Icons.restore_outlined, size: 19),
                  label: const Text('RESUME', maxLines: 1, softWrap: false),
                ),
              );

              if (stackButtons) {
                // Handles the column logic used by this module.
                return Column(
                  children: [
                    SizedBox(width: double.infinity, child: holdButton),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 8),
                    SizedBox(width: double.infinity, child: resumeButton),
                  ],
                );
              }

              // Handles the row logic used by this module.
              return Row(
                children: [
                  Expanded(child: holdButton),
                  // Handles the sized box logic used by this module.
                  const SizedBox(width: 10),
                  Expanded(child: resumeButton),
                ],
              );
            },
          ),
          // Handles the sized box logic used by this module.
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
    if (_productsLoading) {
      // Handles the center logic used by this module.
      return const Center(child: CircularProgressIndicator());
    }

    if (_productsError != null) {
      // Handles the center logic used by this module.
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Unable to load products.\n$_productsError',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
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
        ),
      );
    }

    // Handles the layout builder logic used by this module.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = constraints.maxWidth < 1000;
        final isTablet =
            constraints.maxWidth >= 700 && constraints.maxWidth < 980;

        final horizontalPadding = isPhone ? 10.0 : 22.0;
        final verticalPadding = isPhone ? 10.0 : 22.0;

        if (constraints.maxWidth >= 980) {
          // Handles the container logic used by this module.
          return Container(
            color: const Color(0xFFF2F6FC),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _productPanel(_visibleProducts, _activeProducts),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 22),
                SizedBox(width: 420, child: _cartPanel(_activeProducts)),
              ],
            ),
          );
        }

        if (isTablet) {
          // Handles the container logic used by this module.
          return Container(
            color: const Color(0xFFF2F6FC),
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              children: [
                Expanded(
                  child: _productPanel(_visibleProducts, _activeProducts),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(height: 18),
                SizedBox(height: 520, child: _cartPanel(_activeProducts)),
              ],
            ),
          );
        }

        // Phone layout: the whole POS becomes vertically scrollable instead of
        // forcing the product panel and cart into a cramped fixed-height column.
        return Container(
          color: const Color(0xFFF2F6FC),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 570,
                  child: _productPanel(_visibleProducts, _activeProducts),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(height: 14),
                SizedBox(height: 720, child: _cartPanel(_activeProducts)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Refresh changed products after checkout without charging one read per
  // product in the complete catalog. Query snapshots preserve existing POS
  // types used by search results, barcode lookup, and product cards.
  Future<void> _refreshPurchasedProducts(Set<String> productIds) async {
    if (productIds.isEmpty) return;

    final updated = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
    final ids = productIds.toList();
    // Conservative batch size for Firestore document-ID IN queries.
    for (var start = 0; start < ids.length; start += 10) {
      final end = (start + 10 < ids.length) ? start + 10 : ids.length;
      final batchIds = ids.sublist(start, end);
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get(const GetOptions(source: Source.server));
      for (final doc in snapshot.docs) {
        updated[doc.id] = doc;
      }
    }

    if (!mounted) return;
    setState(() {
      // Preserve catalog order and all unaffected products.
      _activeProducts = [
        for (final existing in _activeProducts)
          if (!productIds.contains(existing.id))
            existing
          else if (updated.containsKey(existing.id) &&
              updated[existing.id]!.data()['isActive'] != false)
            updated[existing.id]!,
      ];

      // Rebuild the in-memory indexes without additional Firestore queries.
      _productsById.clear();
      _productsByBarcode.clear();
      for (final product in _activeProducts) {
        _productsById[product.id] = product;
        final barcode = (product.data()['barcode'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (barcode.isNotEmpty) {
          (_productsByBarcode[barcode] ??= []).add(product);
        }
      }

      // Keep currently displayed product IDs but refresh their snapshots.
      // For an empty search, show the normal initial product list.
      if (_query.trim().isEmpty) {
        _visibleProducts = _activeProducts.take(_maxVisibleProducts).toList();
      } else {
        _visibleProducts = [
          for (final product in _visibleProducts)
            if (_productsById.containsKey(product.id))
              _productsById[product.id]!,
        ];
      }
      _recentScannedProductIds.removeWhere(
        (id) => !_productsById.containsKey(id),
      );
      _aiSearchCache.clear();
    });
  }

  // Loads active product records into local caches used by fast POS search and barcode lookup.
  Future<void> _loadProducts() async {
    if (mounted) {
      setState(() {
        _productsLoading = true;
        _productsError = null;
      });
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('productName')
          .get();

      final active = snapshot.docs
          .where((document) => document.data()['isActive'] != false)
          .toList();

      final byId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      final byBarcode =
          <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};

      for (final product in active) {
        byId[product.id] = product;
        final barcode = (product.data()['barcode'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
        if (barcode.isNotEmpty) {
          (byBarcode[barcode] ??= []).add(product);
        }
      }

      if (!mounted) return;
      setState(() {
        _activeProducts = active;
        if (_selectedCategory != 'All' &&
            !active.any(
              (doc) =>
                  _productCategory(doc.data()).toLowerCase() ==
                  _selectedCategory.toLowerCase(),
            )) {
          _selectedCategory = 'All';
        }
        _productsById
          ..clear()
          ..addAll(byId);
        _productsByBarcode
          ..clear()
          ..addAll(byBarcode);
        _visibleProducts = active.take(_maxVisibleProducts).toList();
        _aiSearchCache.clear();
        _productsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _productsLoading = false;
        _productsError = error.toString();
      });
    }
  }

  // Handles the focus search bar logic used by this module.
  void _focusSearchBar() {
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _searchFocusNode.requestFocus();
      if (_scannedBarcodeProductId != null &&
          _searchController.text.isNotEmpty) {
        // Select the previous scanned barcode so the next hardware scan
        // replaces it instead of appending to the old barcode.
        _searchController.selection = TextSelection(
          baseOffset: 0,
          extentOffset: _searchController.text.length,
        );
      } else {
        _searchController.selection = TextSelection.fromPosition(
          TextPosition(offset: _searchController.text.length),
        );
      }
    });
  }

  // Handles the refocus search bar logic used by this module.
  void _refocusSearchBar({Duration delay = const Duration(milliseconds: 80)}) {
    if (!mounted) return;

    Future<void>.delayed(delay, () {
      if (!mounted) return;
      _focusSearchBar();
    });
  }

  // Handles the search key event user or system event and updates state as required.
  KeyEventResult _handleSearchKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.tab) {
      // TAB-suffix scanners submit the barcode instead of moving focus away.
      _commitHardwareBarcode(_searchController.text);
      _refocusSearchBar(delay: Duration.zero);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  void initState() {
    super.initState();
    _searchFocusNode.onKeyEvent = _handleSearchKeyEvent;
    _loadProducts();
    _focusSearchBar();
  }

  @override
  void dispose() {
    _hardwareScanTimer?.cancel();
    _textSearchTimer?.cancel();
    _durationTimer?.cancel();
    _searchFocusNode.dispose();
    _searchController.dispose();
    _cashController.dispose();
    super.dispose();
  }
}

// Private UI/data helper used only inside this module.
class _PosProductCard extends StatefulWidget {
  final String name;
  final double price;
  final int stock;
  final bool highlighted;
  final VoidCallback? onTap;

  // Handles the pos product card logic used by this module.
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

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _PosProductCardState extends State<_PosProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final available = widget.stock > 0;
    final accent = widget.highlighted
        ? const Color(0xFF7B1FA2)
        : const Color(0xFF1565C0);

    // Handles the mouse region logic used by this module.
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
                      // Handles the spacer logic used by this module.
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
                  // Handles the sized box logic used by this module.
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
                  // Handles the spacer logic used by this module.
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

// Editable quantity for a single cart item. It retains text-input focus while
// the POS timer, subtotal, and stock controls rebuild the cart.
class _EditableCartQuantity extends StatefulWidget {
  final int quantity;
  final int availableStock;
  final ValueChanged<int> onChanged;
  final ValueChanged<String> onInvalid;

  const _EditableCartQuantity({
    super.key,
    required this.quantity,
    required this.availableStock,
    required this.onChanged,
    required this.onInvalid,
  });

  @override
  State<_EditableCartQuantity> createState() => _EditableCartQuantityState();
}

class _EditableCartQuantityState extends State<_EditableCartQuantity> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.quantity}');
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) _finishEditing();
    });
  }

  @override
  void didUpdateWidget(covariant _EditableCartQuantity oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the typed value stable during timer rebuilds, but reflect changes
    // made with +/- and restored held-cart quantities.
    if (widget.quantity != oldWidget.quantity &&
        _controller.text != '${widget.quantity}') {
      final text = '${widget.quantity}';
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  void _onChanged(String raw) {
    // Allow temporarily clearing the field while entering a new number.
    // An invalid quantity is never passed to the cart calculation.
    if (raw.isEmpty) return;

    final parsed = int.tryParse(raw);
    if (parsed == null || parsed < 1) return;

    if (parsed > widget.availableStock) {
      // Warn IMMEDIATELY, instead of waiting for focus loss or PAY NOW.
      // Restore the last accepted quantity so the displayed cart and total
      // can never disagree with the number shown in this field.
      widget.onInvalid(
        'Only ${widget.availableStock} stock available. '
        'You cannot enter $parsed.',
      );
      final valid = '${widget.quantity}';
      _controller.value = TextEditingValue(
        text: valid,
        selection: TextSelection.collapsed(offset: valid.length),
      );
      return;
    }

    widget.onChanged(parsed);
  }

  void _finishEditing() {
    if (!mounted) return;
    final typed = int.tryParse(_controller.text);
    if (typed == null || typed < 1) {
      widget.onInvalid('Quantity must be at least 1.');
    } else if (typed > widget.availableStock) {
      widget.onInvalid('Only ${widget.availableStock} stock available.');
    } else {
      widget.onChanged(typed);
    }
    final corrected = '${widget.quantity}';
    _controller.value = TextEditingValue(
      text: corrected,
      selection: TextSelection.collapsed(offset: corrected.length),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Grow with the quantity length. On narrow screens, the input itself
    // scrolls horizontally and keeps the caret visible while editing.
    final digits = _controller.text.length > '${widget.availableStock}'.length
        ? _controller.text.length
        : '${widget.availableStock}'.length;
    final maxWidth = MediaQuery.sizeOf(context).width < 650 ? 110.0 : 200.0;
    final fieldWidth = (digits * 12.0 + 34.0).clamp(76.0, maxWidth);
    return SizedBox(
      width: fieldWidth,
      height: 39,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        scrollPhysics: const ClampingScrollPhysics(),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (value) {
          _onChanged(value);
          if (mounted) setState(() {});
        },
        onSubmitted: (_) {
          _finishEditing();
          _focusNode.unfocus();
        },
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 10,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

// Private UI/data helper used only inside this module.
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
    // Handles the cart item logic used by this module.
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
