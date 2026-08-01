import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class SalesReportsScreen extends StatefulWidget {
  const SalesReportsScreen({super.key});

  @override
  State<SalesReportsScreen> createState() => _SalesReportsScreenState();
}

class _SalesReportsScreenState extends State<SalesReportsScreen> {
  String _selectedFilter = 'This Month';

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _matchesFilter(DateTime? date) {
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
      child: _SalesHoverCard(
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, color.withValues(alpha: 0.055)],
            ),
            borderRadius: BorderRadius.circular(20),
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
                child: Icon(icon, color: Colors.white, size: 26),
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

  String _fileTimestamp() {
    final now = DateTime.now();

    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
  }

  String _csvEscape(dynamic value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

  void _downloadCsv({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions,
  }) {
    final rows = <String>[
      [
        _csvEscape('Receipt Number'),
        _csvEscape('Date'),
        _csvEscape('Cashier'),
        _csvEscape('Total'),
        _csvEscape('Cash'),
        _csvEscape('Change'),
        _csvEscape('Status'),
      ].join(','),
    ];

    for (final document in transactions) {
      final data = document.data();
      final date = _readDate(data['createdAt']);

      rows.add(
        [
          _csvEscape(
            data['receiptNumber'] ?? data['transactionNumber'] ?? document.id,
          ),
          _csvEscape(date?.toIso8601String() ?? ''),
          _csvEscape(
            data['processedByName'] ??
                data['processedByEmail'] ??
                'Unknown Cashier',
          ),
          _csvEscape(
            ((data['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
          ),
          _csvEscape(
            ((data['cash'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
          ),
          _csvEscape(
            ((data['change'] as num?)?.toDouble() ?? 0).toStringAsFixed(2),
          ),
          _csvEscape(data['status'] ?? 'completed'),
        ].join(','),
      );
    }

    final bytes = utf8.encode(rows.join('\n'));
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute(
        'download',
        'eumart_sales_${_selectedFilter.toLowerCase().replaceAll(' ', '_')}_${_fileTimestamp()}.csv',
      )
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sales CSV downloaded successfully.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _printSalesReport({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions,
    required double totalSales,
    required int totalItemsSold,
    required double averageTransaction,
    required List<_ProductSales> topProducts,
  }) async {
    final settingsSnapshot = await FirebaseFirestore.instance
        .collection('settings')
        .doc('system')
        .get();

    final settings = settingsSnapshot.data() ?? <String, dynamic>{};

    final storeName = (settings['storeName'] ?? 'EÜ MART').toString();
    final storeAddress = (settings['storeAddress'] ?? '').toString();

    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            pw.Text(
              storeName,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            if (storeAddress.isNotEmpty)
              pw.Padding(
                padding: const pw.EdgeInsets.only(top: 4),
                child: pw.Text(storeAddress),
              ),
            pw.SizedBox(height: 8),
            pw.Text(
              'Sales Report — $_selectedFilter',
              style: pw.TextStyle(fontSize: 17, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 16),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400),
              children: [
                pw.TableRow(
                  children: [
                    _pdfSummaryCell(
                      'Total Sales',
                      'PHP ${totalSales.toStringAsFixed(2)}',
                    ),
                    _pdfSummaryCell('Transactions', '${transactions.length}'),
                  ],
                ),
                pw.TableRow(
                  children: [
                    _pdfSummaryCell('Items Sold', '$totalItemsSold'),
                    _pdfSummaryCell(
                      'Average Transaction',
                      'PHP ${averageTransaction.toStringAsFixed(2)}',
                    ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 22),
            pw.Text(
              'Top-Selling Products',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Rank', 'Product', 'Quantity', 'Sales'],
              data: topProducts.take(10).toList().asMap().entries.map((entry) {
                final product = entry.value;

                return [
                  '${entry.key + 1}',
                  product.productName,
                  '${product.quantity}',
                  'PHP ${product.sales.toStringAsFixed(2)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 22),
            pw.Text(
              'Transactions',
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: const ['Receipt', 'Date', 'Cashier', 'Total'],
              data: transactions.map((document) {
                final data = document.data();
                final date = _readDate(data['createdAt']);

                return [
                  (data['receiptNumber'] ??
                          data['transactionNumber'] ??
                          document.id)
                      .toString(),
                  date == null
                      ? ''
                      : '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                  (data['processedByName'] ??
                          data['processedByEmail'] ??
                          'Unknown Cashier')
                      .toString(),
                  'PHP ${((data['total'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                ];
              }).toList(),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              cellStyle: const pw.TextStyle(fontSize: 8),
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      name: 'EUMART_Sales_${_selectedFilter.replaceAll(' ', '_')}.pdf',
      onLayout: (_) async => document.save(),
    );
  }

  pw.Widget _pdfSummaryCell(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
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
              'Unable to load sales reports.\n${snapshot.error}',
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

        final filtered = documents.where((document) {
          final data = document.data();
          final status = (data['status'] ?? 'completed')
              .toString()
              .toLowerCase();

          if (status == 'voided') return false;

          return _matchesFilter(_readDate(data['createdAt']));
        }).toList();

        double totalSales = 0;
        double totalCash = 0;
        int totalItemsSold = 0;

        final Map<String, _ProductSales> productSales = {};
        final Map<String, double> dailySales = {};

        for (final document in filtered) {
          final data = document.data();

          totalSales += (data['total'] as num?)?.toDouble() ?? 0;
          totalCash += (data['cash'] as num?)?.toDouble() ?? 0;

          final date = _readDate(data['createdAt']);

          if (date != null) {
            final key =
                '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            dailySales[key] =
                (dailySales[key] ?? 0) +
                ((data['total'] as num?)?.toDouble() ?? 0);
          }

          final items = data['items'] as List<dynamic>? ?? <dynamic>[];

          for (final rawItem in items) {
            if (rawItem is! Map) continue;

            final item = Map<String, dynamic>.from(rawItem);
            final productName = (item['productName'] ?? 'Unknown Product')
                .toString();
            final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
            final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;

            totalItemsSold += quantity;

            final existing = productSales[productName];

            if (existing == null) {
              productSales[productName] = _ProductSales(
                productName: productName,
                quantity: quantity,
                sales: subtotal,
              );
            } else {
              existing.quantity += quantity;
              existing.sales += subtotal;
            }
          }
        }

        final topProducts = productSales.values.toList()
          ..sort((a, b) => b.quantity.compareTo(a.quantity));

        final double averageTransaction = filtered.isEmpty
            ? 0.0
            : totalSales / filtered.length;

        final sortedDailySales = dailySales.entries.toList()
          ..sort((a, b) => a.key.compareTo(b.key));

        double maxDailySales = 0;
        for (final entry in sortedDailySales) {
          if (entry.value > maxDailySales) {
            maxDailySales = entry.value;
          }
        }

        return Container(
          color: const Color(0xFFF2F6FC),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                                Icons.analytics_outlined,
                                color: Colors.white,
                                size: 27,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Sales Reports',
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
                            'Review sales performance, '
                            'transactions, and top-selling products.',
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
                            onPressed: filtered.isEmpty
                                ? null
                                : () => _downloadCsv(transactions: filtered),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              disabledForegroundColor: Colors.white54,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.65),
                              ),
                              minimumSize: const Size(145, 46),
                            ),
                            icon: const Icon(Icons.table_view_outlined),
                            label: const Text('EXPORT CSV'),
                          ),
                          ElevatedButton.icon(
                            onPressed: filtered.isEmpty
                                ? null
                                : () => _printSalesReport(
                                    transactions: filtered,
                                    totalSales: totalSales,
                                    totalItemsSold: totalItemsSold,
                                    averageTransaction: averageTransaction,
                                    topProducts: topProducts,
                                  ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF1565C0),
                              disabledBackgroundColor: Colors.white54,
                              minimumSize: const Size(175, 46),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.print_outlined),
                            label: const Text(
                              'PRINT / SAVE PDF',
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
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0xFFE1E9F3)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0F16395C),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _filterChip('Today'),
                      _filterChip('This Week'),
                      _filterChip('This Month'),
                      _filterChip('All'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    int count = 4;
                    if (constraints.maxWidth < 1100) {
                      count = 2;
                    }
                    if (constraints.maxWidth < 620) {
                      count = 1;
                    }

                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: count,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                      childAspectRatio: count == 4 ? 2.2 : 2.8,
                      children: [
                        _summaryCard(
                          title: 'Total Sales',
                          value: '₱${totalSales.toStringAsFixed(2)}',
                          icon: Icons.payments_rounded,
                          color: const Color(0xFF159447),
                        ),
                        _summaryCard(
                          title: 'Transactions',
                          value: '${filtered.length}',
                          icon: Icons.receipt_long_outlined,
                          color: const Color(0xFF1565C0),
                        ),
                        _summaryCard(
                          title: 'Items Sold',
                          value: '$totalItemsSold',
                          icon: Icons.shopping_bag_outlined,
                          color: const Color(0xFFF59E0B),
                        ),
                        _summaryCard(
                          title: 'Average Transaction',
                          value: '₱${averageTransaction.toStringAsFixed(2)}',
                          icon: Icons.trending_up_rounded,
                          color: const Color(0xFF7B1FA2),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 950;

                    final chartCard = _SalesSectionCard(
                      title: 'Sales by Date',
                      subtitle:
                          'Daily sales performance for the selected period',
                      icon: Icons.bar_chart_rounded,
                      child: sortedDailySales.isEmpty
                          ? const SizedBox(
                              height: 250,
                              child: Center(
                                child: Text(
                                  'No sales data for this period.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : SizedBox(
                              height: 280,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: sortedDailySales.map((entry) {
                                    final ratio = maxDailySales == 0
                                        ? 0.0
                                        : entry.value / maxDailySales;

                                    return Container(
                                      width: 82,
                                      margin: const EdgeInsets.only(right: 14),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          Text(
                                            '₱${entry.value.toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          TweenAnimationBuilder<double>(
                                            duration: const Duration(
                                              milliseconds: 650,
                                            ),
                                            curve: Curves.easeOutCubic,
                                            tween: Tween(begin: 0, end: ratio),
                                            builder: (context, value, child) {
                                              return Container(
                                                height: 180 * value,
                                                width: 42,
                                                decoration: BoxDecoration(
                                                  gradient:
                                                      const LinearGradient(
                                                        begin:
                                                            Alignment.topCenter,
                                                        end: Alignment
                                                            .bottomCenter,
                                                        colors: [
                                                          Color(0xFF42A5F5),
                                                          Color(0xFF1565C0),
                                                        ],
                                                      ),
                                                  borderRadius:
                                                      BorderRadius.circular(9),
                                                  boxShadow: const [
                                                    BoxShadow(
                                                      color: Color(0x2A1565C0),
                                                      blurRadius: 10,
                                                      offset: Offset(0, 5),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            entry.key.substring(5),
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                    );

                    final topProductsCard = _SalesSectionCard(
                      title: 'Top-Selling Products',
                      subtitle: 'Products with the highest quantity sold',
                      icon: Icons.emoji_events_outlined,
                      child: topProducts.isEmpty
                          ? const SizedBox(
                              height: 250,
                              child: Center(
                                child: Text(
                                  'No product sales for this period.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          : Column(
                              children: topProducts
                                  .take(10)
                                  .toList()
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                    final rank = entry.key + 1;
                                    final product = entry.value;

                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 9),
                                      padding: const EdgeInsets.all(11),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF8FBFF),
                                        borderRadius: BorderRadius.circular(13),
                                        border: Border.all(
                                          color: const Color(0xFFE6EDF6),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 18,
                                            backgroundColor: rank == 1
                                                ? const Color(0xFFFFE8A3)
                                                : const Color(0xFFE3F2FD),
                                            child: Text(
                                              '$rank',
                                              style: const TextStyle(
                                                color: Color(0xFF1565C0),
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 11),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  product.productName,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                                Text(
                                                  '${product.quantity} item(s) sold',
                                                  style: const TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            '₱${product.sales.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Color(0xFF0F8A4B),
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  })
                                  .toList(),
                            ),
                    );

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: chartCard),
                          const SizedBox(width: 18),
                          Expanded(flex: 2, child: topProductsCard),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        chartCard,
                        const SizedBox(height: 18),
                        topProductsCard,
                      ],
                    );
                  },
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 15,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEAF3FF), Color(0xFFF6FAFF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFD7E7FA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: Color(0xFF1565C0),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'TOTAL CASH RECEIVED',
                          style: TextStyle(
                            color: Color(0xFF53657C),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Text(
                        '₱${totalCash.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFF1565C0),
                          fontSize: 18,
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
      },
    );
  }
}

class _SalesHoverCard extends StatefulWidget {
  final Widget child;

  const _SalesHoverCard({required this.child});

  @override
  State<_SalesHoverCard> createState() => _SalesHoverCardState();
}

class _SalesHoverCardState extends State<_SalesHoverCard> {
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
          borderRadius: BorderRadius.circular(20),
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

class _SalesSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;

  const _SalesSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFFBFDFF)],
        ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF3FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: const Color(0xFF1565C0), size: 22),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Color(0xFF8A95A4),
                        fontSize: 11,
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
}

class _ProductSales {
  final String productName;
  int quantity;
  double sales;

  _ProductSales({
    required this.productName,
    required this.quantity,
    required this.sales,
  });
}
