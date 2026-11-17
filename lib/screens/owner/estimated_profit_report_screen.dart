// -----------------------------------------------------------------------------
// Module overview: Estimates gross profit from transaction item values using recorded selling and buying prices.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Keep currency and unit totals readable across cards and summaries.
final NumberFormat _profitMoney = NumberFormat('#,##0.00', 'en_US');
final NumberFormat _profitCount = NumberFormat('#,##0', 'en_US');
String _peso(num amount) => '₱${_profitMoney.format(amount)}';

// Private UI/data helper used only inside this module.
class _ProfitHoverCard extends StatefulWidget {
  final Widget child;

  // Handles the profit hover card logic used by this module.
  const _ProfitHoverCard({required this.child});

  @override
  State<_ProfitHoverCard> createState() => _ProfitHoverCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _ProfitHoverCardState extends State<_ProfitHoverCard> {
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
class _ProfitProductCard extends StatefulWidget {
  final int rank;
  final String productName;
  final int quantitySold;
  final double sales;
  final double cost;
  final double profit;
  final double margin;
  final Color profitColor;

  // Handles the profit product card logic used by this module.
  const _ProfitProductCard({
    required this.rank,
    required this.productName,
    required this.quantitySold,
    required this.sales,
    required this.cost,
    required this.profit,
    required this.margin,
    required this.profitColor,
  });

  @override
  State<_ProfitProductCard> createState() => _ProfitProductCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _ProfitProductCardState extends State<_ProfitProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Handles the mouse region logic used by this module.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, widget.profitColor.withValues(alpha: 0.025)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.profitColor.withValues(alpha: 0.30)
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 820;

            final product = Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.rank}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    widget.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            );

            final metrics = Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                _ProfitMetricBox(
                  label: 'Sold',
                  value: _profitCount.format(widget.quantitySold),
                  color: const Color(0xFF1565C0),
                ),
                _ProfitMetricBox(
                  label: 'Sales',
                  value: _peso(widget.sales),
                  color: const Color(0xFF1565C0),
                ),
                _ProfitMetricBox(
                  label: 'Cost',
                  value: _peso(widget.cost),
                  color: const Color(0xFF1976D2),
                ),
                _ProfitMetricBox(
                  label: 'Profit',
                  value: _peso(widget.profit),
                  color: widget.profitColor,
                ),
                _ProfitMetricBox(
                  label: 'Margin',
                  value: '${widget.margin.toStringAsFixed(1)}%',
                  color: const Color(0xFF1565C0),
                ),
              ],
            );

            if (compact) {
              // Handles the column logic used by this module.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [product, const SizedBox(height: 14), metrics],
              );
            }

            // Handles the row logic used by this module.
            return Row(
              children: [
                Expanded(flex: 4, child: product),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 16),
                Expanded(
                  flex: 6,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: metrics,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Private UI/data helper used only inside this module.
class _ProfitMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  // Handles the profit metric box logic used by this module.
  const _ProfitMetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Handles the container logic used by this module.
    return Container(
      constraints: const BoxConstraints(minWidth: 108),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _ProfitEmptyState extends StatelessWidget {
  // Handles the profit empty state logic used by this module.
  const _ProfitEmptyState();

  @override
  Widget build(BuildContext context) {
    // Handles the center logic used by this module.
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_outlined,
            size: 60,
            color: Color(0xFFB8C5D5),
          ),
          SizedBox(height: 11),
          Text(
            'No completed sales found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF657386),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Choose another period or complete new transactions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AA5B3)),
          ),
        ],
      ),
    );
  }
}

// Screen widget for estimates gross profit from transaction item values using recorded selling and buying prices.
class EstimatedProfitReportScreen extends StatefulWidget {
  // Handles the estimated profit report screen logic used by this module.
  const EstimatedProfitReportScreen({super.key});

  @override
  State<EstimatedProfitReportScreen> createState() =>
      _EstimatedProfitReportScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _EstimatedProfitReportScreenState
    extends State<EstimatedProfitReportScreen> {
  String _selectedFilter = 'This Month';
  // Stable Firestore subscriptions avoid unnecessary re-listening after UI changes.
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _productsStream;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _transactionsStream;
  int _visibleProducts = 24;

  @override
  void initState() {
    super.initState();
    _productsStream = FirebaseFirestore.instance
        .collection('products')
        .snapshots();
    _transactionsStream = _transactionStreamForFilter();
  }

  // Query only the relevant date range for normal reports. All Time remains
  // available on demand; changing the date filter replaces the stream.
  Stream<QuerySnapshot<Map<String, dynamic>>> _transactionStreamForFilter() {
    final today = DateTime.now();
    late final DateTime start;
    late final DateTime end;
    if (_selectedFilter == 'Today') {
      start = DateTime(today.year, today.month, today.day);
      end = start.add(const Duration(days: 1));
    } else if (_selectedFilter == 'This Week') {
      start = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: today.weekday - 1));
      end = start.add(const Duration(days: 7));
    } else if (_selectedFilter == 'This Month') {
      start = DateTime(today.year, today.month);
      end = DateTime(today.year, today.month + 1);
    } else {
      return FirebaseFirestore.instance.collection('transactions').snapshots();
    }
    return FirebaseFirestore.instance
        .collection('transactions')
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .snapshots();
  }

  double _safeAmount(dynamic value) {
    if (value is num) return value.toDouble().isFinite ? value.toDouble() : 0;
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  double? _optionalNonnegativeAmount(dynamic value) {
    if (value == null) return null;
    final amount = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().trim());
    if (amount == null || !amount.isFinite || amount < 0) return null;
    return amount;
  }

  int _safeQuantity(dynamic value) {
    final parsed = value is num
        ? value.toInt()
        : int.tryParse(value?.toString() ?? '') ?? 0;
    return parsed > 0 ? parsed : 0;
  }

  // Normalizes supported Firestore/date values into a Dart DateTime for consistent comparisons.
  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Checks whether the current value satisfies the matches filter rule used by this module.
  bool _matchesFilter(DateTime? date) {
    if (date == null) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final transactionDate = DateTime(date.year, date.month, date.day);

    switch (_selectedFilter) {
      case 'Today':
        return transactionDate == today;
      case 'This Week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        return !transactionDate.isBefore(startOfWeek) &&
            !transactionDate.isAfter(endOfWeek);
      case 'This Month':
        return transactionDate.year == now.year &&
            transactionDate.month == now.month;
      default:
        return true;
    }
  }

  // Filters chip according to the current user selection or business rule.
  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

    // Handles the choice chip logic used by this module.
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
          _transactionsStream = _transactionStreamForFilter();
          _visibleProducts = 24;
        });
      },
    );
  }

  // Handles the summary card logic used by this module.
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Handles the profit hover card logic used by this module.
    return _ProfitHoverCard(
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _productsStream,
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting &&
            !productSnapshot.hasData) {
          // Handles the center logic used by this module.
          return const Center(child: CircularProgressIndicator());
        }

        if (productSnapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load product costs: ${productSnapshot.error}',
            ),
          );
        }

        final productsById = <String, Map<String, dynamic>>{
          for (final document
              in productSnapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[])
            document.id: document.data(),
        };

        final productsByName = <String, Map<String, dynamic>>{
          for (final document
              in productSnapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[])
            (document.data()['productName'] ?? '').toString().toLowerCase():
                document.data(),
        };

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _transactionsStream,
          builder: (context, transactionSnapshot) {
            if (transactionSnapshot.connectionState ==
                    ConnectionState.waiting &&
                !transactionSnapshot.hasData) {
              // Handles the center logic used by this module.
              return const Center(child: CircularProgressIndicator());
            }

            if (transactionSnapshot.hasError) {
              // Handles the center logic used by this module.
              return Center(
                child: Text(
                  'Unable to load estimated profit report.\n'
                  '${transactionSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.blue),
                ),
              );
            }

            final transactions =
                transactionSnapshot.data?.docs.where((document) {
                  final data = document.data();

                  final status = (data['status'] ?? 'completed')
                      .toString()
                      .toLowerCase();

                  return status != 'voided' &&
                      _matchesFilter(_readDate(data['createdAt']));
                }).toList() ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            double totalSales = 0;
            double estimatedCost = 0;
            double knownCostSales = 0;
            int totalItemsSold = 0;
            int unmatchedItemCount = 0;
            int missingItemsCount = 0;
            int unreconciledTransactionCount = 0;
            int fallbackCostCount = 0;
            int adjustedTransactionCount = 0;

            final Map<String, _ProfitProduct> productProfit = {};

            for (final sale in transactions) {
              final data = sale.data();
              final rawTotal = _safeAmount(data['total']);
              final transactionTotal = rawTotal < 0 ? 0.0 : rawTotal;
              totalSales += transactionTotal;

              final items = data['items'] as List<dynamic>? ?? <dynamic>[];
              final normalizedItems = <Map<String, dynamic>>[];
              for (final rawItem in items) {
                if (rawItem is Map) {
                  normalizedItems.add(Map<String, dynamic>.from(rawItem));
                }
              }
              if (normalizedItems.isEmpty && transactionTotal > 0) {
                missingItemsCount++;
                continue;
              }

              // Item subtotals can be pre-discount. Scale down their revenue
              // proportionally so summed item sales never exceed the amount
              // actually charged on a discounted transaction.
              final itemSubtotalSum = normalizedItems.fold<double>(0, (
                sum,
                item,
              ) {
                final subtotal = _safeAmount(item['subtotal']);
                return sum + (subtotal > 0 ? subtotal : 0);
              });
              final allocationFactor =
                  itemSubtotalSum > 0 && transactionTotal < itemSubtotalSum
                  ? transactionTotal / itemSubtotalSum
                  : 1.0;
              if (allocationFactor < 1.0) adjustedTransactionCount++;
              if (itemSubtotalSum <= 0 && transactionTotal > 0) {
                unreconciledTransactionCount++;
              } else if (itemSubtotalSum > 0 &&
                  transactionTotal > itemSubtotalSum + 0.01) {
                unreconciledTransactionCount++;
              }

              for (final item in normalizedItems) {
                final productId = (item['productId'] ?? '').toString().trim();
                final productName = (item['productName'] ?? 'Unknown Product')
                    .toString();
                final quantity = _safeQuantity(item['quantity']);
                if (quantity <= 0) continue;

                final lineSubtotal = _safeAmount(item['subtotal']);
                final revenue =
                    (lineSubtotal < 0 ? 0.0 : lineSubtotal) * allocationFactor;
                final matchedProduct =
                    productsById[productId] ??
                    (productId.isEmpty
                        ? productsByName[productName.toLowerCase()]
                        : null);
                final itemBuyingPrice = _optionalNonnegativeAmount(
                  item['buyingPrice'],
                );
                final currentBuyingPrice = _optionalNonnegativeAmount(
                  matchedProduct?['buyingPrice'],
                );
                final costPerUnit = itemBuyingPrice ?? currentBuyingPrice;
                if (itemBuyingPrice == null && currentBuyingPrice != null) {
                  fallbackCostCount += quantity;
                }
                if (costPerUnit == null) unmatchedItemCount += quantity;

                final cost = (costPerUnit ?? 0) * quantity;
                // Unknown-cost revenue is not counted toward gross profit.
                final knownRevenue = costPerUnit == null ? 0.0 : revenue;
                final profit = knownRevenue - cost;
                totalItemsSold += quantity;
                estimatedCost += cost;
                knownCostSales += knownRevenue;

                final productKey = productId.isNotEmpty
                    ? 'id:$productId'
                    : 'name:${productName.trim().toLowerCase()}';
                final existing = productProfit[productKey];
                if (existing == null) {
                  productProfit[productKey] = _ProfitProduct(
                    productName: productName,
                    quantitySold: quantity,
                    sales: knownRevenue,
                    estimatedCost: cost,
                    estimatedProfit: profit,
                  );
                } else {
                  existing.quantitySold += quantity;
                  existing.sales += knownRevenue;
                  existing.estimatedCost += cost;
                  existing.estimatedProfit += profit;
                }
              }
            }

            // This is a gross-profit estimate only for sales with known costs.
            // Unknown costs cannot safely be treated as a zero-cost purchase.
            final estimatedGrossProfit = knownCostSales - estimatedCost;
            final profitMargin = knownCostSales <= 0
                ? 0.0
                : (estimatedGrossProfit / knownCostSales) * 100;
            final incomplete =
                unmatchedItemCount > 0 ||
                missingItemsCount > 0 ||
                unreconciledTransactionCount > 0;

            final productRows = productProfit.values.toList()
              ..sort((a, b) => b.estimatedProfit.compareTo(a.estimatedProfit));

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
                                Icons.account_balance_outlined,
                                color: Colors.white,
                                size: 29,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Estimated Profit',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Estimate gross profit using transaction sales '
                                      'and available product buying prices.',
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
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFDDE6F1)),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _filterChip('Today'),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 8),
                                _filterChip('This Week'),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 8),
                                _filterChip('This Month'),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 8),
                                _filterChip('All Time'),
                              ],
                            ),
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
                                _summaryCard(
                                  title: 'Total Sales',
                                  value: _peso(totalSales),
                                  icon: Icons.payments_outlined,
                                  color: const Color(0xFF1565C0),
                                ),
                                _summaryCard(
                                  title: incomplete
                                      ? 'Known Buying Costs (Partial)'
                                      : 'Estimated Cost',
                                  value: _peso(estimatedCost),
                                  icon: Icons.shopping_cart_outlined,
                                  color: const Color(0xFF1976D2),
                                ),
                                _summaryCard(
                                  title: incomplete
                                      ? 'Known-Cost Gross Profit (Partial)'
                                      : 'Estimated Gross Profit',
                                  value: _peso(estimatedGrossProfit),
                                  icon: Icons.trending_up,
                                  color: const Color(0xFF1565C0),
                                ),
                                _summaryCard(
                                  title: incomplete
                                      ? 'Known-Cost Margin (Partial)'
                                      : 'Profit Margin',
                                  value:
                                      '${_profitMoney.format(profitMargin)}%',
                                  icon: Icons.percent,
                                  color: const Color(0xFF1565C0),
                                ),
                              ],
                            );
                          },
                        ),
                        // Handles the sized box logic used by this module.
                        const SizedBox(height: 16),
                        _ProfitHoverCard(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: incomplete
                                    ? const [
                                        Color(0xFFF3F8FF),
                                        Color(0xFFF8FBFF),
                                      ]
                                    : const [
                                        Color(0xFFEAF3FF),
                                        Color(0xFFF8FBFF),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: incomplete
                                    ? const Color(0xFFE8F2FF)
                                    : const Color(0xFFD7E7FA),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: incomplete
                                      ? const Color(0x1F1976D2)
                                      : const Color(0x1F1565C0),
                                  child: Icon(
                                    incomplete
                                        ? Icons.warning_amber_outlined
                                        : Icons.info_outline,
                                    color: incomplete
                                        ? const Color(0xFF1976D2)
                                        : const Color(0xFF1565C0),
                                  ),
                                ),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    incomplete
                                        ? 'Partial estimate: ${_profitCount.format(unmatchedItemCount)} item(s) '
                                              'have no recorded buying cost and $missingItemsCount transaction(s) '
                                              'have no item details; $unreconciledTransactionCount transaction(s) have '
                                              'unreconciled item subtotals. Unknown-cost sales are excluded from '
                                              'estimated gross profit and margin. '
                                              'Please review the source transactions.'
                                        : 'Estimated gross profit uses buying prices saved in each '
                                              'transaction item where available; otherwise, current '
                                              'product buying prices are used for ${_profitCount.format(fallbackCostCount)} item(s). '
                                              '${_profitCount.format(adjustedTransactionCount)} discounted transaction(s) '
                                              'had line revenue adjusted to match the final transaction total. '
                                              'This is gross profit before other business expenses.',
                                    style: TextStyle(
                                      color: incomplete
                                          ? const Color(0xFF1565C0)
                                          : const Color(0xFF53657C),
                                      fontWeight: FontWeight.w700,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Handles the sized box logic used by this module.
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            // Handles the expanded logic used by this module.
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Estimated Profit by Product',
                                    style: TextStyle(
                                      color: Color(0xFF172033),
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Products are ranked by estimated gross profit.',
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
                                '${_profitCount.format(totalItemsSold)} ITEM(S) SOLD',
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
                        if (productRows.isEmpty)
                          // Handles the sized box logic used by this module.
                          const SizedBox(
                            height: 230,
                            child: _ProfitEmptyState(),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: productRows.length < _visibleProducts
                                ? productRows.length
                                : _visibleProducts,
                            separatorBuilder: (_, _) =>
                                // Handles the sized box logic used by this module.
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final product = productRows[index];

                              final margin = product.sales <= 0
                                  ? 0.0
                                  : (product.estimatedProfit / product.sales) *
                                        100;

                              final profitColor = product.estimatedProfit < 0
                                  ? const Color(0xFF1976D2)
                                  : const Color(0xFF1565C0);

                              // Handles the profit product card logic used by this module.
                              return _ProfitProductCard(
                                rank: index + 1,
                                productName: product.productName,
                                quantitySold: product.quantitySold,
                                sales: product.sales,
                                cost: product.estimatedCost,
                                profit: product.estimatedProfit,
                                margin: margin,
                                profitColor: profitColor,
                              );
                            },
                          ),
                        if (productRows.length > _visibleProducts) ...[
                          const SizedBox(height: 14),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  setState(() => _visibleProducts += 24),
                              icon: const Icon(Icons.expand_more),
                              label: Text(
                                'Show more (${productRows.length - _visibleProducts} remaining)',
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
      },
    );
  }
}

// Private UI/data helper used only inside this module.
class _ProfitProduct {
  final String productName;

  int quantitySold;
  double sales;
  double estimatedCost;
  double estimatedProfit;

  _ProfitProduct({
    required this.productName,
    required this.quantitySold,
    required this.sales,
    required this.estimatedCost,
    required this.estimatedProfit,
  });
}
