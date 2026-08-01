import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class _ShiftHoverCard extends StatefulWidget {
  final Widget child;

  const _ShiftHoverCard({required this.child});

  @override
  State<_ShiftHoverCard> createState() => _ShiftHoverCardState();
}

class _ShiftHoverCardState extends State<_ShiftHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
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

class _ShiftMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _ShiftMetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Column(
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
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShiftTransactionCard extends StatefulWidget {
  final String receipt;
  final int itemCount;
  final double total;
  final double cash;
  final double change;
  final double savings;
  final String time;

  const _ShiftTransactionCard({
    required this.receipt,
    required this.itemCount,
    required this.total,
    required this.cash,
    required this.change,
    required this.savings,
    required this.time,
  });

  @override
  State<_ShiftTransactionCard> createState() => _ShiftTransactionCardState();
}

class _ShiftTransactionCardState extends State<_ShiftTransactionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF1565C0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8FBFF)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered ? const Color(0xFF9CC5EF) : const Color(0xFFE1E9F3),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 820;

            final transaction = Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.receipt_long_outlined,
                    color: accent,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receipt,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 15,
                            color: Color(0xFF8A95A4),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              widget.time,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF8A95A4),
                                fontSize: 11,
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

            final metrics = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ShiftSmallMetric(
                  label: 'Items',
                  value: '${widget.itemCount}',
                  color: const Color(0xFF7B1FA2),
                ),
                _ShiftSmallMetric(
                  label: 'Cash',
                  value: '₱${widget.cash.toStringAsFixed(2)}',
                  color: const Color(0xFF1565C0),
                ),
                _ShiftSmallMetric(
                  label: 'Change',
                  value: '₱${widget.change.toStringAsFixed(2)}',
                  color: const Color(0xFFF59E0B),
                ),
                if (widget.savings > 0)
                  _ShiftSmallMetric(
                    label: 'Savings',
                    value: '₱${widget.savings.toStringAsFixed(2)}',
                    color: const Color(0xFF159447),
                  ),
              ],
            );

            final total = Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'TOTAL',
                    style: TextStyle(
                      color: Color(0xFF6C9A7F),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '₱${widget.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF159447),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  transaction,
                  const SizedBox(height: 12),
                  metrics,
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: total),
                ],
              );
            }

            return Row(
              children: [
                Expanded(flex: 3, child: transaction),
                const SizedBox(width: 14),
                Expanded(flex: 4, child: metrics),
                const SizedBox(width: 14),
                total,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ShiftSmallMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ShiftSmallMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ShiftReportEmptyState extends StatelessWidget {
  const _ShiftReportEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 60,
            color: Color(0xFFB8C5D5),
          ),
          const SizedBox(height: 11),
          const Text(
            'No completed transactions today',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF657386),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Completed cashier transactions will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AA5B3)),
          ),
        ],
      ),
    );
  }
}

class CashierShiftReportScreen extends StatefulWidget {
  const CashierShiftReportScreen({super.key});

  @override
  State<CashierShiftReportScreen> createState() =>
      _CashierShiftReportScreenState();
}

class _CashierShiftReportScreenState extends State<CashierShiftReportScreen> {
  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _isToday(DateTime? date) {
    if (date == null) return false;

    final now = DateTime.now();

    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDateTime(DateTime date) {
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.month}/${date.day}/${date.year} '
        '$hour:$minute $period';
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _ShiftHoverCard(
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

  Future<void> _printShiftReport({
    required String cashierName,
    required String cashierEmail,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions,
    required double totalSales,
    required double totalCash,
    required double totalChange,
    required double totalSavings,
    required int totalItems,
  }) async {
    final now = DateTime.now();
    final completedCount = transactions.length;
    final averageTransaction = completedCount == 0
        ? 0.0
        : totalSales / completedCount;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text(
              'EÜ MART',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            pw.Text(
              'Cashier End-of-Shift Report',
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text('Generated: ${_formatDateTime(now)}'),
            pw.Text('Cashier: $cashierName'),
            if (cashierEmail.isNotEmpty) pw.Text('Email: $cashierEmail'),
            pw.SizedBox(height: 18),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                _pdfSummaryRow('Completed Transactions', '$completedCount'),
                _pdfSummaryRow(
                  'Total Sales',
                  'PHP ${totalSales.toStringAsFixed(2)}',
                ),
                _pdfSummaryRow(
                  'Cash Received',
                  'PHP ${totalCash.toStringAsFixed(2)}',
                ),
                _pdfSummaryRow(
                  'Change Issued',
                  'PHP ${totalChange.toStringAsFixed(2)}',
                ),
                _pdfSummaryRow('Items Sold', '$totalItems'),
                _pdfSummaryRow(
                  'Customer Savings',
                  'PHP ${totalSavings.toStringAsFixed(2)}',
                ),
                _pdfSummaryRow(
                  'Average Transaction',
                  'PHP ${averageTransaction.toStringAsFixed(2)}',
                ),
              ],
            ),
            pw.SizedBox(height: 22),
            pw.Text(
              'Transaction Breakdown',
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              columnWidths: const {
                0: pw.FlexColumnWidth(2),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(1),
                3: pw.FlexColumnWidth(1.3),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _pdfCell('Receipt', bold: true),
                    _pdfCell('Time', bold: true),
                    _pdfCell('Items', bold: true),
                    _pdfCell('Total', bold: true),
                  ],
                ),
                ...transactions.map((document) {
                  final data = document.data();
                  final receipt =
                      (data['receiptNumber'] ??
                              data['transactionNumber'] ??
                              document.id)
                          .toString();

                  final createdAt = _readDate(data['createdAt']);

                  final items = data['items'] as List<dynamic>? ?? <dynamic>[];

                  int itemCount = 0;

                  for (final rawItem in items) {
                    if (rawItem is! Map) continue;

                    final item = Map<String, dynamic>.from(rawItem);

                    itemCount += (item['quantity'] as num?)?.toInt() ?? 0;
                  }

                  final total = (data['total'] as num?)?.toDouble() ?? 0;

                  return pw.TableRow(
                    children: [
                      _pdfCell(receipt),
                      _pdfCell(
                        createdAt == null
                            ? 'Unavailable'
                            : _formatDateTime(createdAt),
                      ),
                      _pdfCell('$itemCount'),
                      _pdfCell('PHP ${total.toStringAsFixed(2)}'),
                    ],
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 28),
            pw.Text('Cashier Signature: __________________________'),
            pw.SizedBox(height: 18),
            pw.Text('Owner/Manager Verification: __________________________'),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'cashier-shift-${now.year}-${now.month}-${now.day}.pdf',
      onLayout: (_) async => pdf.save(),
    );
  }

  pw.TableRow _pdfSummaryRow(String label, String value) {
    return pw.TableRow(
      children: [_pdfCell(label, bold: true), _pdfCell(value)],
    );
  }

  pw.Widget _pdfCell(String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(7),
      child: pw.Text(
        value,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'No logged-in cashier.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (context, userSnapshot) {
        final userData = userSnapshot.data?.data() ?? <String, dynamic>{};

        final cashierName =
            (userData['name'] ??
                    userData['fullName'] ??
                    user.displayName ??
                    user.email ??
                    'Cashier')
                .toString();

        final cashierEmail = (user.email ?? '').toString();

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .where('processedById', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load shift report.\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final transactions =
                List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                  snapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                ).where((document) {
                  final data = document.data();

                  final status = (data['status'] ?? 'completed')
                      .toString()
                      .toLowerCase();

                  return status == 'completed' &&
                      _isToday(_readDate(data['createdAt']));
                }).toList();

            transactions.sort((a, b) {
              final first = _readDate(a.data()['createdAt']);
              final second = _readDate(b.data()['createdAt']);

              if (first == null && second == null) return 0;
              if (first == null) return 1;
              if (second == null) return -1;

              return second.compareTo(first);
            });

            double totalSales = 0;
            double totalCash = 0;
            double totalChange = 0;
            double totalSavings = 0;
            int totalItems = 0;

            for (final document in transactions) {
              final data = document.data();

              totalSales += (data['total'] as num?)?.toDouble() ?? 0;

              totalCash += (data['cash'] as num?)?.toDouble() ?? 0;

              totalChange += (data['change'] as num?)?.toDouble() ?? 0;

              totalSavings += (data['totalSavings'] as num?)?.toDouble() ?? 0;

              final items = data['items'] as List<dynamic>? ?? <dynamic>[];

              for (final rawItem in items) {
                if (rawItem is! Map) continue;

                final item = Map<String, dynamic>.from(rawItem);

                totalItems += (item['quantity'] as num?)?.toInt() ?? 0;
              }
            }

            final averageTransaction = transactions.isEmpty
                ? 0.0
                : totalSales / transactions.length;

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
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final compact = constraints.maxWidth < 680;

                              final title = Row(
                                children: [
                                  const Icon(
                                    Icons.summarize_outlined,
                                    color: Colors.white,
                                    size: 29,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Cashier Shift Report',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 23,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '$cashierName • '
                                          '${_formatDateTime(DateTime.now())}',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );

                              final printButton = SizedBox(
                                height: 48,
                                child: ElevatedButton.icon(
                                  onPressed: transactions.isEmpty
                                      ? null
                                      : () => _printShiftReport(
                                          cashierName: cashierName,
                                          cashierEmail: cashierEmail,
                                          transactions: transactions,
                                          totalSales: totalSales,
                                          totalCash: totalCash,
                                          totalChange: totalChange,
                                          totalSavings: totalSavings,
                                          totalItems: totalItems,
                                        ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1565C0),
                                    disabledBackgroundColor: Colors.white60,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.print_outlined),
                                  label: const Text(
                                    'PRINT SHIFT REPORT',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              );

                              if (compact) {
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    title,
                                    const SizedBox(height: 14),
                                    printButton,
                                  ],
                                );
                              }

                              return Row(
                                children: [
                                  Expanded(child: title),
                                  const SizedBox(width: 16),
                                  printButton,
                                ],
                              );
                            },
                          ),
                        ),
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
                                _summaryCard(
                                  title: 'Completed Transactions',
                                  value: '${transactions.length}',
                                  icon: Icons.receipt_long_outlined,
                                  color: const Color(0xFF1565C0),
                                ),
                                _summaryCard(
                                  title: 'Total Sales',
                                  value: '₱${totalSales.toStringAsFixed(2)}',
                                  icon: Icons.payments_outlined,
                                  color: const Color(0xFF159447),
                                ),
                                _summaryCard(
                                  title: 'Items Sold',
                                  value: '$totalItems',
                                  icon: Icons.shopping_bag_outlined,
                                  color: const Color(0xFF7B1FA2),
                                ),
                                _summaryCard(
                                  title: 'Average Transaction',
                                  value:
                                      '₱${averageTransaction.toStringAsFixed(2)}',
                                  icon: Icons.analytics_outlined,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        _ShiftHoverCard(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
                              ),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: const Color(0xFFD7E7FA),
                              ),
                            ),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 10,
                              children: [
                                _ShiftMetricPill(
                                  label: 'Cash Received',
                                  value: '₱${totalCash.toStringAsFixed(2)}',
                                  icon: Icons.money_outlined,
                                  color: const Color(0xFF1565C0),
                                ),
                                _ShiftMetricPill(
                                  label: 'Change Issued',
                                  value: '₱${totalChange.toStringAsFixed(2)}',
                                  icon: Icons.currency_exchange_outlined,
                                  color: const Color(0xFF7B1FA2),
                                ),
                                _ShiftMetricPill(
                                  label: 'Customer Savings',
                                  value: '₱${totalSavings.toStringAsFixed(2)}',
                                  icon: Icons.savings_outlined,
                                  color: const Color(0xFF159447),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Today’s Transactions',
                                    style: TextStyle(
                                      color: Color(0xFF172033),
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Completed transactions processed during the current shift.',
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
                                '${transactions.length} RECORD(S)',
                                style: const TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (transactions.isEmpty)
                          const SizedBox(
                            height: 230,
                            child: _ShiftReportEmptyState(),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: transactions.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final document = transactions[index];

                              final data = document.data();

                              final receipt =
                                  (data['receiptNumber'] ??
                                          data['transactionNumber'] ??
                                          document.id)
                                      .toString();

                              final total =
                                  (data['total'] as num?)?.toDouble() ?? 0;

                              final cash =
                                  (data['cash'] as num?)?.toDouble() ?? 0;

                              final change =
                                  (data['change'] as num?)?.toDouble() ?? 0;

                              final savings =
                                  (data['totalSavings'] as num?)?.toDouble() ??
                                  0;

                              final items =
                                  data['items'] as List<dynamic>? ??
                                  <dynamic>[];

                              int itemCount = 0;

                              for (final rawItem in items) {
                                if (rawItem is! Map) {
                                  continue;
                                }

                                final item = Map<String, dynamic>.from(rawItem);

                                itemCount +=
                                    (item['quantity'] as num?)?.toInt() ?? 0;
                              }

                              final createdAt = _readDate(data['createdAt']);

                              return _ShiftTransactionCard(
                                receipt: receipt,
                                itemCount: itemCount,
                                total: total,
                                cash: cash,
                                change: change,
                                savings: savings,
                                time: createdAt == null
                                    ? 'Unavailable'
                                    : _formatDateTime(createdAt),
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
      },
    );
  }
}
