// -----------------------------------------------------------------------------
// Module overview: Estimates gross profit from transaction item values using recorded selling and buying prices.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
                  value: '${widget.quantitySold}',
                  color: const Color(0xFF1565C0),
                ),
                _ProfitMetricBox(
                  label: 'Sales',
                  value: '₱${widget.sales.toStringAsFixed(2)}',
                  color: const Color(0xFF159447),
                ),
                _ProfitMetricBox(
                  label: 'Cost',
                  value: '₱${widget.cost.toStringAsFixed(2)}',
                  color: const Color(0xFFF59E0B),
                ),
                _ProfitMetricBox(
                  label: 'Profit',
                  value: '₱${widget.profit.toStringAsFixed(2)}',
                  color: widget.profitColor,
                ),
                _ProfitMetricBox(
                  label: 'Margin',
                  value: '${widget.margin.toStringAsFixed(1)}%',
                  color: const Color(0xFF7B1FA2),
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
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, productSnapshot) {
        if (productSnapshot.connectionState == ConnectionState.waiting &&
            !productSnapshot.hasData) {
          // Handles the center logic used by this module.
          return const Center(child: CircularProgressIndicator());
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
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .snapshots(),
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
                  style: const TextStyle(color: Colors.red),
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
            int totalItemsSold = 0;
            int unmatchedItemCount = 0;

            final Map<String, _ProfitProduct> productProfit = {};

            for (final transaction in transactions) {
              final data = transaction.data();

              totalSales += (data['total'] as num?)?.toDouble() ?? 0;

              final items = data['items'] as List<dynamic>? ?? <dynamic>[];

              for (final rawItem in items) {
                if (rawItem is! Map) continue;

                final item = Map<String, dynamic>.from(rawItem);

                final productId = (item['productId'] ?? '').toString();

                final productName = (item['productName'] ?? 'Unknown Product')
                    .toString();

                final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

                final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;

                final matchedProduct =
                    productsById[productId] ??
                    productsByName[productName.toLowerCase()];

                final itemBuyingPrice = (item['buyingPrice'] as num?)
                    ?.toDouble();

                final currentBuyingPrice =
                    (matchedProduct?['buyingPrice'] as num?)?.toDouble();

                final buyingPrice = itemBuyingPrice ?? currentBuyingPrice ?? 0;

                if (buyingPrice <= 0) {
                  unmatchedItemCount += quantity;
                }

                final cost = buyingPrice * quantity;
                final profit = subtotal - cost;

                totalItemsSold += quantity;
                estimatedCost += cost;

                final existing = productProfit[productName];

                if (existing == null) {
                  productProfit[productName] = _ProfitProduct(
                    productName: productName,
                    quantitySold: quantity,
                    sales: subtotal,
                    estimatedCost: cost,
                    estimatedProfit: profit,
                  );
                } else {
                  existing.quantitySold += quantity;
                  existing.sales += subtotal;
                  existing.estimatedCost += cost;
                  existing.estimatedProfit += profit;
                }
              }
            }

            final estimatedGrossProfit = totalSales - estimatedCost;

            final profitMargin = totalSales <= 0
                ? 0.0
                : (estimatedGrossProfit / totalSales) * 100;

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
                                  value: '₱${totalSales.toStringAsFixed(2)}',
                                  icon: Icons.payments_outlined,
                                  color: const Color(0xFF159447),
                                ),
                                _summaryCard(
                                  title: 'Estimated Cost',
                                  value: '₱${estimatedCost.toStringAsFixed(2)}',
                                  icon: Icons.shopping_cart_outlined,
                                  color: const Color(0xFFF59E0B),
                                ),
                                _summaryCard(
                                  title: 'Estimated Gross Profit',
                                  value:
                                      '₱${estimatedGrossProfit.toStringAsFixed(2)}',
                                  icon: Icons.trending_up,
                                  color: const Color(0xFF1565C0),
                                ),
                                _summaryCard(
                                  title: 'Profit Margin',
                                  value: '${profitMargin.toStringAsFixed(1)}%',
                                  icon: Icons.percent,
                                  color: const Color(0xFF7B1FA2),
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
                                colors: unmatchedItemCount > 0
                                    ? const [
                                        Color(0xFFFFF3E0),
                                        Color(0xFFFFFBF5),
                                      ]
                                    : const [
                                        Color(0xFFEAF3FF),
                                        Color(0xFFF8FBFF),
                                      ],
                              ),
                              borderRadius: BorderRadius.circular(17),
                              border: Border.all(
                                color: unmatchedItemCount > 0
                                    ? const Color(0xFFF4D3A0)
                                    : const Color(0xFFD7E7FA),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: unmatchedItemCount > 0
                                      ? const Color(0x1FF59E0B)
                                      : const Color(0x1F1565C0),
                                  child: Icon(
                                    unmatchedItemCount > 0
                                        ? Icons.warning_amber_outlined
                                        : Icons.info_outline,
                                    color: unmatchedItemCount > 0
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF1565C0),
                                  ),
                                ),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    unmatchedItemCount > 0
                                        ? 'Estimated profit uses current product buying prices. '
                                              '$unmatchedItemCount sold item(s) have no buying price, '
                                              'so their estimated cost is ₱0.00.'
                                        : 'Estimated profit uses the buying price saved in each '
                                              'transaction item when available; otherwise, it uses '
                                              'the product’s current buying price.',
                                    style: TextStyle(
                                      color: unmatchedItemCount > 0
                                          ? const Color(0xFF8A5A12)
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
                                '$totalItemsSold ITEM(S) SOLD',
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
                            itemCount: productRows.length,
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
                                  ? const Color(0xFFD32F2F)
                                  : const Color(0xFF159447);

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
