// -----------------------------------------------------------------------------
// Module overview: Displays transactions processed by the cashier and supports reviewing transaction details.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Private UI/data helper used only inside this module.
class _CashierHistoryHoverCard extends StatefulWidget {
  final Widget child;

  // Handles the cashier history hover card logic used by this module.
  const _CashierHistoryHoverCard({required this.child});

  @override
  State<_CashierHistoryHoverCard> createState() =>
      _CashierHistoryHoverCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierHistoryHoverCardState extends State<_CashierHistoryHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Handles the mouse region logic used by this module.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x2216385A)
                  : const Color(0x1016385A),
              blurRadius: _hovered ? 20 : 11,
              offset: Offset(0, _hovered ? 9 : 5),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

// Private UI/data helper used only inside this module.
class _CashierHistorySummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  // Handles the cashier history summary card logic used by this module.
  const _CashierHistorySummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Handles the cashier history hover card logic used by this module.
    return _CashierHistoryHoverCard(
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withValues(alpha: 0.055)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.72)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.20),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            // Handles the sized box logic used by this module.
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF7A8494),
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
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
}

// Private UI/data helper used only inside this module.
class _CashierTransactionCard extends StatefulWidget {
  final String receiptNumber;
  final String date;
  final double total;
  final double cash;
  final double change;
  final double savings;
  final bool isVoided;
  final List<dynamic> items;
  final VoidCallback onReprint;

  // Handles the cashier transaction card logic used by this module.
  const _CashierTransactionCard({
    required this.receiptNumber,
    required this.date,
    required this.total,
    required this.cash,
    required this.change,
    required this.savings,
    required this.isVoided,
    required this.items,
    required this.onReprint,
  });

  @override
  State<_CashierTransactionCard> createState() =>
      _CashierTransactionCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierTransactionCardState extends State<_CashierTransactionCard> {
  bool _hovered = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isVoided
        ? const Color(0xFFD32F2F)
        : const Color(0xFF1565C0);

    // Handles the mouse region logic used by this module.
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
            color: _hovered
                ? accent.withValues(alpha: 0.35)
                : widget.isVoided
                ? const Color(0xFFFFCDD2)
                : const Color(0xFFE1E9F3),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x2016385A)
                  : const Color(0x0F16385A),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () {
                setState(() {
                  _expanded = !_expanded;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 900;

                    final receipt = Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            widget.isVoided
                                ? Icons.block_outlined
                                : Icons.receipt_long_outlined,
                            color: accent,
                            size: 26,
                          ),
                        ),
                        // Handles the sized box logic used by this module.
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.receiptNumber,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF172033),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              // Handles the sized box logic used by this module.
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  // Handles the icon logic used by this module.
                                  const Icon(
                                    Icons.schedule_outlined,
                                    size: 15,
                                    color: Color(0xFF8A95A4),
                                  ),
                                  // Handles the sized box logic used by this module.
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      widget.date,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Color(0xFF8A95A4),
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final status = Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.isVoided
                            ? 'VOIDED'
                            : '₱${widget.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    );

                    if (compact) {
                      // Handles the column logic used by this module.
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          receipt,
                          // Handles the sized box logic used by this module.
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              status,
                              // Handles the spacer logic used by this module.
                              const Spacer(),
                              Icon(
                                _expanded
                                    ? Icons.keyboard_arrow_up_rounded
                                    : Icons.keyboard_arrow_down_rounded,
                                color: const Color(0xFF8A95A4),
                              ),
                            ],
                          ),
                        ],
                      );
                    }

                    // Handles the row logic used by this module.
                    return Row(
                      children: [
                        Expanded(child: receipt),
                        // Handles the sized box logic used by this module.
                        const SizedBox(width: 14),
                        status,
                        // Handles the sized box logic used by this module.
                        const SizedBox(width: 8),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: const Color(0xFF8A95A4),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            if (_expanded) ...[
              // Handles the divider logic used by this module.
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        _CashierHistoryMetric(
                          label: 'Cash',
                          value: '₱${widget.cash.toStringAsFixed(2)}',
                          color: const Color(0xFF1565C0),
                        ),
                        _CashierHistoryMetric(
                          label: 'Change',
                          value: '₱${widget.change.toStringAsFixed(2)}',
                          color: const Color(0xFFF59E0B),
                        ),
                        _CashierHistoryMetric(
                          label: 'Savings',
                          value: '₱${widget.savings.toStringAsFixed(2)}',
                          color: const Color(0xFF159447),
                        ),
                        _CashierHistoryMetric(
                          label: 'Items',
                          value: '${widget.items.length}',
                          color: const Color(0xFF7B1FA2),
                        ),
                      ],
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 14),
                    if (widget.items.isEmpty)
                      // Handles the padding logic used by this module.
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Text(
                          'No item details available.',
                          style: TextStyle(color: Color(0xFF8A95A4)),
                        ),
                      )
                    else
                      ...widget.items.map((rawItem) {
                        if (rawItem is! Map) {
                          return const SizedBox.shrink();
                        }

                        final item = Map<String, dynamic>.from(rawItem);

                        final productName =
                            (item['productName'] ?? 'Unknown Product')
                                .toString();

                        final quantity =
                            (item['quantity'] as num?)?.toInt() ?? 0;

                        final subtotal =
                            (item['subtotal'] as num?)?.toDouble() ?? 0;

                        // Handles the container logic used by this module.
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F9FC),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      productName,
                                      style: const TextStyle(
                                        color: Color(0xFF344255),
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    // Handles the sized box logic used by this module.
                                    const SizedBox(height: 2),
                                    Text(
                                      'Quantity: $quantity',
                                      style: const TextStyle(
                                        color: Color(0xFF8A95A4),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '₱${subtotal.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFF159447),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: widget.onReprint,
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('REPRINT RECEIPT'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Private UI/data helper used only inside this module.
class _CashierHistoryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  // Handles the cashier history metric logic used by this module.
  const _CashierHistoryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Handles the container logic used by this module.
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          // Handles the sized box logic used by this module.
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierHistoryEmptyState extends StatelessWidget {
  // Handles the cashier history empty state logic used by this module.
  const _CashierHistoryEmptyState();

  @override
  Widget build(BuildContext context) {
    // Handles the center logic used by this module.
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 60, color: Color(0xFFB8C5D5)),
          SizedBox(height: 11),
          Text(
            'No transactions found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF657386),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Try another date filter or receipt search.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AA5B3)),
          ),
        ],
      ),
    );
  }
}

// Screen widget for displays transactions processed by the cashier and supports reviewing transaction details.
class CashierTransactionHistoryScreen extends StatefulWidget {
  // Handles the cashier transaction history screen logic used by this module.
  const CashierTransactionHistoryScreen({super.key});

  @override
  State<CashierTransactionHistoryScreen> createState() =>
      _CashierTransactionHistoryScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierTransactionHistoryScreenState
    extends State<CashierTransactionHistoryScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  // Normalizes supported Firestore/date values into a Dart DateTime for consistent comparisons.
  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Checks whether the current value satisfies the matches date filter rule used by this module.
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

  // Formats a date into a consistent display value for the interface.
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

  // Filters chip according to the current user selection or business rule.
  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

    // Handles the choice chip logic used by this module.
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

  // Handles the reprint receipt logic used by this module.
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

  // Handles the pdf info row logic used by this module.
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

  // Handles the pdf money row logic used by this module.
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
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Handles the center logic used by this module.
      return const Center(
        child: Text(
          'No logged-in cashier.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('processedById', isEqualTo: user.uid)
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
              'Unable to load transaction history.\n'
              '${snapshot.error}',
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

          if (first == null && second == null) {
            return 0;
          }
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

          final createdAt = _readDate(data['createdAt']);

          final matchesSearch =
              _searchQuery.isEmpty || receiptNumber.contains(_searchQuery);

          return matchesSearch && _matchesDateFilter(createdAt);
        }).toList();

        double totalSales = 0;
        double totalSavings = 0;
        int completedCount = 0;
        int voidedCount = 0;

        for (final document in filtered) {
          final data = document.data();

          final status = (data['status'] ?? 'completed')
              .toString()
              .toLowerCase();

          if (status == 'voided') {
            voidedCount++;
            continue;
          }

          completedCount++;
          totalSales += (data['total'] as num?)?.toDouble() ?? 0;

          totalSavings += (data['totalSavings'] as num?)?.toDouble() ?? 0;
        }

        // Handles the container logic used by this module.
        return Container(
          color: const Color(0xFFF2F6FC),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
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
                            Icons.receipt_long_outlined,
                            color: Colors.white,
                            size: 29,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Transaction History',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Review your completed receipts, '
                                  'payments, savings, and voided records.',
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
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int count = 4;

                        if (constraints.maxWidth < 1050) {
                          count = 2;
                        }

                        if (constraints.maxWidth < 620) {
                          count = 1;
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: count,
                          crossAxisSpacing: 13,
                          mainAxisSpacing: 13,
                          childAspectRatio: count == 4 ? 2.25 : 3.1,
                          children: [
                            _CashierHistorySummaryCard(
                              title: 'Completed Transactions',
                              value: '$completedCount',
                              icon: Icons.receipt_long_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            _CashierHistorySummaryCard(
                              title: 'Total Sales',
                              value: '₱${totalSales.toStringAsFixed(2)}',
                              icon: Icons.payments_outlined,
                              color: const Color(0xFF159447),
                            ),
                            _CashierHistorySummaryCard(
                              title: 'Customer Savings',
                              value: '₱${totalSavings.toStringAsFixed(2)}',
                              icon: Icons.savings_outlined,
                              color: const Color(0xFF7B1FA2),
                            ),
                            _CashierHistorySummaryCard(
                              title: 'Voided Transactions',
                              value: '$voidedCount',
                              icon: Icons.block_outlined,
                              color: const Color(0xFFD32F2F),
                            ),
                          ],
                        );
                      },
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 900;

                        final search = TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.trim().toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search receipt number',
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
                                      });
                                    },
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                            filled: true,
                            fillColor: Colors.white,
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
                        );

                        final filters = SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _filterChip('All'),
                              // Handles the sized box logic used by this module.
                              const SizedBox(width: 8),
                              _filterChip('Today'),
                              // Handles the sized box logic used by this module.
                              const SizedBox(width: 8),
                              _filterChip('This Week'),
                              // Handles the sized box logic used by this module.
                              const SizedBox(width: 8),
                              _filterChip('This Month'),
                            ],
                          ),
                        );

                        if (compact) {
                          // Handles the column logic used by this module.
                          return Column(
                            children: [
                              search,
                              // Handles the sized box logic used by this module.
                              const SizedBox(height: 12),
                              filters,
                            ],
                          );
                        }

                        // Handles the row logic used by this module.
                        return Row(
                          children: [
                            Expanded(child: search),
                            // Handles the sized box logic used by this module.
                            const SizedBox(width: 14),
                            filters,
                          ],
                        );
                      },
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        // Handles the expanded logic used by this module.
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receipt Records',
                                style: TextStyle(
                                  color: Color(0xFF172033),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Select a receipt to view payment and item details.',
                                style: TextStyle(
                                  color: Color(0xFF7D8998),
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
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${filtered.length} RECORD(S)',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 12),
                    if (filtered.isEmpty)
                      // Handles the sized box logic used by this module.
                      const SizedBox(
                        height: 230,
                        child: _CashierHistoryEmptyState(),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final document = filtered[index];

                          final data = document.data();

                          final receiptNumber =
                              (data['receiptNumber'] ??
                                      data['transactionNumber'] ??
                                      document.id)
                                  .toString();

                          final total =
                              (data['total'] as num?)?.toDouble() ?? 0;

                          final cash = (data['cash'] as num?)?.toDouble() ?? 0;

                          final change =
                              (data['change'] as num?)?.toDouble() ?? 0;

                          final savings =
                              (data['totalSavings'] as num?)?.toDouble() ?? 0;

                          final createdAt = _readDate(data['createdAt']);

                          final status = (data['status'] ?? 'completed')
                              .toString()
                              .toLowerCase();

                          final isVoided = status == 'voided';

                          final items =
                              data['items'] as List<dynamic>? ?? <dynamic>[];

                          // Handles the cashier transaction card logic used by this module.
                          return _CashierTransactionCard(
                            receiptNumber: receiptNumber,
                            date: _formatDate(createdAt),
                            total: total,
                            cash: cash,
                            change: change,
                            savings: savings,
                            isVoided: isVoided,
                            items: items,
                            onReprint: () => _reprintReceipt(document),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
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
