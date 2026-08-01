import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../services/audit_log_service.dart';

class _TransactionSummaryHoverCard extends StatefulWidget {
  final Widget child;

  const _TransactionSummaryHoverCard({required this.child});

  @override
  State<_TransactionSummaryHoverCard> createState() =>
      _TransactionSummaryHoverCardState();
}

class _TransactionSummaryHoverCardState
    extends State<_TransactionSummaryHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(19),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x2416385A)
                  : const Color(0x1116385A),
              blurRadius: _hovered ? 22 : 12,
              offset: Offset(0, _hovered ? 10 : 5),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _TransactionHistoryCard extends StatefulWidget {
  final bool isVoided;
  final Widget child;

  const _TransactionHistoryCard({required this.isVoided, required this.child});

  @override
  State<_TransactionHistoryCard> createState() =>
      _TransactionHistoryCardState();
}

class _TransactionHistoryCardState extends State<_TransactionHistoryCard> {
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
          gradient: LinearGradient(
            colors: widget.isVoided
                ? const [Color(0xFFFFF5F5), Color(0xFFFFEBEE)]
                : const [Colors.white, Color(0xFFFBFDFF)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.isVoided
                ? const Color(0xFFFFCDD2)
                : _hovered
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(color: Colors.transparent, child: widget.child),
        ),
      ),
    );
  }
}

class OwnerTransactionHistoryScreen extends StatefulWidget {
  const OwnerTransactionHistoryScreen({super.key});

  @override
  State<OwnerTransactionHistoryScreen> createState() =>
      _OwnerTransactionHistoryScreenState();
}

class _OwnerTransactionHistoryScreenState
    extends State<OwnerTransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _matchesDateFilter(DateTime? date) {
    if (_selectedFilter == 'All') return true;
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);

    if (_selectedFilter == 'Today') {
      return transactionDate == today;
    }

    if (_selectedFilter == 'This Week') {
      final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 6));

      return !transactionDate.isBefore(startOfWeek) &&
          !transactionDate.isAfter(endOfWeek);
    }

    if (_selectedFilter == 'This Month') {
      return transactionDate.year == now.year &&
          transactionDate.month == now.month;
    }

    return true;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    final months = const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} ${date.day}, ${date.year} • '
        '$hour:$minute $period';
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Future<void> _voidTransaction(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();
    final receiptNumber =
        (data['receiptNumber'] ?? data['transactionNumber'] ?? document.id)
            .toString();

    final reasonController = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Void Transaction'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Void transaction "$receiptNumber"? '
                  'The deducted product stock will be restored.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Reason for voiding',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final value = reasonController.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(dialogContext, value);
              },
              icon: const Icon(Icons.block),
              label: const Text('Void Transaction'),
            ),
          ],
        );
      },
    );

    reasonController.dispose();

    if (reason == null || reason.isEmpty) return;

    try {
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final transactionReference = FirebaseFirestore.instance
            .collection('transactions')
            .doc(document.id);

        final transactionSnapshot = await transaction.get(transactionReference);

        if (!transactionSnapshot.exists) {
          throw Exception('Transaction no longer exists.');
        }

        final currentData = transactionSnapshot.data()!;
        final status = (currentData['status'] ?? 'completed')
            .toString()
            .toLowerCase();

        if (status == 'voided') {
          throw Exception('This transaction is already voided.');
        }

        final items = currentData['items'] as List<dynamic>? ?? <dynamic>[];

        for (final rawItem in items) {
          if (rawItem is! Map) continue;

          final item = Map<String, dynamic>.from(rawItem);
          final productId = (item['productId'] ?? '').toString();
          final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

          if (productId.isEmpty || quantity <= 0) continue;

          final productReference = FirebaseFirestore.instance
              .collection('products')
              .doc(productId);

          final productSnapshot = await transaction.get(productReference);

          if (!productSnapshot.exists) continue;

          final currentStock =
              (productSnapshot.data()?['stock'] as num?)?.toInt() ?? 0;

          transaction.update(productReference, {
            'stock': currentStock + quantity,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }

        transaction.update(transactionReference, {
          'status': 'voided',
          'voidReason': reason,
          'voidedAt': FieldValue.serverTimestamp(),
          'voidedById': user?.uid ?? '',
          'voidedByEmail': user?.email ?? '',
        });
      });

      await AuditLogService.transactionVoided(
        transactionId: document.id,
        receiptNumber: receiptNumber,
        reason: reason,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction voided and product stock restored.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _reprintReceipt(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();

    final receiptNumber =
        (data['receiptNumber'] ?? data['transactionNumber'] ?? document.id)
            .toString();

    final createdAt = _readDate(data['createdAt']);

    final cashier =
        (data['processedByName'] ?? data['processedByEmail'] ?? 'Cashier')
            .toString();

    final total = (data['total'] as num?)?.toDouble() ?? 0;

    final cash = (data['cash'] as num?)?.toDouble() ?? 0;

    final change = (data['change'] as num?)?.toDouble() ?? 0;

    final totalSavings = (data['totalSavings'] as num?)?.toDouble() ?? 0;

    final status = (data['status'] ?? 'completed').toString().toUpperCase();

    final items = data['items'] as List<dynamic>? ?? <dynamic>[];

    final settingsSnapshot = await FirebaseFirestore.instance
        .collection('settings')
        .doc('system')
        .get();

    final settings = settingsSnapshot.data() ?? <String, dynamic>{};

    final storeName = (settings['storeName'] ?? 'EÜ MART').toString();

    final storeAddress = (settings['storeAddress'] ?? '').toString();

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        margin: const pw.EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              pw.Text(
                storeName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 17,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (storeAddress.trim().isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 3),
                  child: pw.Text(
                    storeAddress,
                    textAlign: pw.TextAlign.center,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              pw.SizedBox(height: 10),
              pw.Text(
                'REPRINTED RECEIPT',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Divider(),
              _pdfInfoRow('Receipt', receiptNumber),
              _pdfInfoRow(
                'Date',
                createdAt == null ? 'Unavailable' : _formatDate(createdAt),
              ),
              _pdfInfoRow('Cashier', cashier),
              _pdfInfoRow('Status', status),
              pw.Divider(),
              ...items.map((rawItem) {
                if (rawItem is! Map) {
                  return pw.SizedBox();
                }

                final item = Map<String, dynamic>.from(rawItem);

                final name = (item['productName'] ?? 'Unknown Product')
                    .toString();

                final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

                final chargedQuantity =
                    (item['chargedQuantity'] as num?)?.toInt() ?? quantity;

                final price = (item['price'] as num?)?.toDouble() ?? 0;

                final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;

                final promoApplied = item['promoApplied'] == true;

                final promoLabel =
                    (item['promoLabel'] ?? item['promoType'] ?? '').toString();

                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        name,
                        style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            chargedQuantity == quantity
                                ? '$quantity x PHP ${price.toStringAsFixed(2)}'
                                : '$quantity item(s), pay $chargedQuantity x PHP ${price.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(
                            'PHP ${subtotal.toStringAsFixed(2)}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                      if (promoApplied && promoLabel.trim().isNotEmpty)
                        pw.Text(
                          promoLabel,
                          style: const pw.TextStyle(fontSize: 7),
                        ),
                    ],
                  ),
                );
              }),
              pw.Divider(),
              if (totalSavings > 0)
                _pdfMoneyRow('YOU SAVED', totalSavings, bold: true),
              _pdfMoneyRow('TOTAL', total, bold: true),
              _pdfMoneyRow('CASH', cash),
              _pdfMoneyRow('CHANGE', change),
              pw.SizedBox(height: 12),
              pw.Text(
                'Thank you for shopping at $storeName!',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 8),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Reprinted copy',
                textAlign: pw.TextAlign.center,
                style: const pw.TextStyle(fontSize: 7),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      name: '$receiptNumber-reprint.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  pw.Widget _pdfInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 52,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfMoneyRow(String label, double value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
          pw.Text(
            'PHP ${value.toStringAsFixed(2)}',
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load transactions.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final documents =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            );

        documents.sort((a, b) {
          final first = _readDate(a.data()['createdAt']);
          final second = _readDate(b.data()['createdAt']);

          if (first == null && second == null) return 0;
          if (first == null) return 1;
          if (second == null) return -1;

          return second.compareTo(first);
        });

        final filtered = documents.where((document) {
          final data = document.data();

          final receiptNumber =
              (data['receiptNumber'] ??
                      data['transactionNumber'] ??
                      document.id)
                  .toString()
                  .toLowerCase();

          final cashier =
              (data['processedByName'] ??
                      data['processedByEmail'] ??
                      'Unknown Cashier')
                  .toString()
                  .toLowerCase();

          final createdAt = _readDate(data['createdAt']);

          final matchesSearch =
              _searchQuery.isEmpty ||
              receiptNumber.contains(_searchQuery) ||
              cashier.contains(_searchQuery);

          return matchesSearch && _matchesDateFilter(createdAt);
        }).toList();

        double totalSales = 0;
        int completedCount = 0;

        for (final document in filtered) {
          final data = document.data();
          final status = (data['status'] ?? 'completed')
              .toString()
              .toLowerCase();

          if (status != 'voided') {
            completedCount++;
            totalSales += (data['total'] as num?)?.toDouble() ?? 0;
          }
        }

        return Container(
          color: const Color(0xFFF2F6FC),
          padding: const EdgeInsets.all(22),
          child: Column(
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
                      Icons.receipt_long_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Transaction History',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Review receipts, cashier activity, '
                            'payments, and voided transactions.',
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _summaryCard(
                      title: 'Completed Transactions',
                      value: '$completedCount',
                      icon: Icons.receipt_long,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _summaryCard(
                      title: 'Total Sales',
                      value: '₱${totalSales.toStringAsFixed(2)}',
                      icon: Icons.payments,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search receipt or cashier',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFDDE6F1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFFDDE6F1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(
                            color: Color(0xFF1565C0),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('All'),
                      _filterChip('Today'),
                      _filterChip('This Week'),
                      _filterChip('This Month'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions found.',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      )
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final document = filtered[index];
                          final data = document.data();

                          final receiptNumber =
                              (data['receiptNumber'] ??
                                      data['transactionNumber'] ??
                                      document.id)
                                  .toString();

                          final cashier =
                              (data['processedByName'] ??
                                      data['processedByEmail'] ??
                                      'Unknown Cashier')
                                  .toString();

                          final total =
                              (data['total'] as num?)?.toDouble() ?? 0;
                          final cash = (data['cash'] as num?)?.toDouble() ?? 0;
                          final change =
                              (data['change'] as num?)?.toDouble() ?? 0;
                          final createdAt = _readDate(data['createdAt']);
                          final status = (data['status'] ?? 'completed')
                              .toString()
                              .toLowerCase();
                          final isVoided = status == 'voided';

                          final items = data['items'] as List<dynamic>? ?? [];

                          return _TransactionHistoryCard(
                            isVoided: isVoided,
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: isVoided
                                    ? Colors.red.shade100
                                    : const Color(0xFFE3F2FD),
                                child: Icon(
                                  isVoided ? Icons.block : Icons.receipt_long,
                                  color: isVoided
                                      ? Colors.red
                                      : const Color(0xFF1565C0),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      receiptNumber,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    isVoided
                                        ? 'VOIDED'
                                        : '₱${total.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: isVoided
                                          ? Colors.red
                                          : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '$cashier\n${_formatDate(createdAt)}',
                              ),
                              childrenPadding: const EdgeInsets.fromLTRB(
                                18,
                                0,
                                18,
                                18,
                              ),
                              children: [
                                const Divider(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Cash: ₱${cash.toStringAsFixed(2)}',
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'Change: ₱${change.toStringAsFixed(2)}',
                                        textAlign: TextAlign.end,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ...items.map((rawItem) {
                                  if (rawItem is! Map) {
                                    return const SizedBox.shrink();
                                  }

                                  final item = Map<String, dynamic>.from(
                                    rawItem,
                                  );

                                  final productName =
                                      (item['productName'] ?? 'Unknown Product')
                                          .toString();

                                  final quantity =
                                      (item['quantity'] as num?)?.toInt() ?? 0;

                                  final subtotal =
                                      (item['subtotal'] as num?)?.toDouble() ??
                                      0;

                                  return ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(productName),
                                    subtitle: Text('Quantity: $quantity'),
                                    trailing: Text(
                                      '₱${subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () =>
                                          _reprintReceipt(document),
                                      icon: const Icon(Icons.print_outlined),
                                      label: const Text('Reprint Receipt'),
                                    ),
                                    if (!isVoided) ...[
                                      const SizedBox(width: 10),
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () =>
                                            _voidTransaction(document),
                                        icon: const Icon(Icons.block),
                                        label: const Text('Void Transaction'),
                                      ),
                                    ],
                                  ],
                                ),
                                if (!isVoided)
                                  ...[]
                                else if ((data['voidReason'] ?? '')
                                    .toString()
                                    .isNotEmpty) ...[
                                  const Divider(),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Void reason: ${data['voidReason']}',
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
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
      child: _TransactionSummaryHoverCard(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withValues(alpha: 0.055)],
            ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(color: color.withValues(alpha: 0.13)),
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.72)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 25),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF7A8494),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
