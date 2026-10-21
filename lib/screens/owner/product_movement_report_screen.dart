// -----------------------------------------------------------------------------
// Module overview: Analyzes transaction item quantities to identify product movement and sales activity.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Private UI/data helper used only inside this module.
class _ProductMovementHoverCard extends StatefulWidget {
  final Widget child;

  // Handles the product movement hover card logic used by this module.
  const _ProductMovementHoverCard({required this.child});

  @override
  State<_ProductMovementHoverCard> createState() =>
      _ProductMovementHoverCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _ProductMovementHoverCardState extends State<_ProductMovementHoverCard> {
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
class _ProductMovementCard extends StatefulWidget {
  final int rank;
  final String productName;
  final String category;
  final int quantitySold;
  final double revenue;
  final int stock;
  final String classification;
  final Color color;
  final IconData icon;

  // Handles the product movement card logic used by this module.
  const _ProductMovementCard({
    required this.rank,
    required this.productName,
    required this.category,
    required this.quantitySold,
    required this.revenue,
    required this.stock,
    required this.classification,
    required this.color,
    required this.icon,
  });

  @override
  State<_ProductMovementCard> createState() => _ProductMovementCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _ProductMovementCardState extends State<_ProductMovementCard> {
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
            colors: [Colors.white, widget.color.withValues(alpha: 0.025)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.color.withValues(alpha: 0.30)
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
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(widget.icon, color: widget.color, size: 27),
                      ),
                      Positioned(
                        right: 4,
                        top: 4,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: widget.color,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${widget.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.productName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 17,
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
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF607086),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );

            final metrics = Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                _MovementMetricBox(
                  label: 'Units Sold',
                  value: '${widget.quantitySold}',
                  color: const Color(0xFF1565C0),
                ),
                _MovementMetricBox(
                  label: 'Revenue',
                  value: '₱${widget.revenue.toStringAsFixed(2)}',
                  color: const Color(0xFF159447),
                ),
                _MovementMetricBox(
                  label: 'Current Stock',
                  value: '${widget.stock}',
                  color: const Color(0xFF7B1FA2),
                ),
              ],
            );

            final badge = Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.classification,
                style: TextStyle(
                  color: widget.color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            );

            if (compact) {
              // Handles the column logic used by this module.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  product,
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 14),
                  metrics,
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 12),
                  Align(alignment: Alignment.centerRight, child: badge),
                ],
              );
            }

            // Handles the row logic used by this module.
            return Row(
              children: [
                Expanded(flex: 4, child: product),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 16),
                Expanded(
                  flex: 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: metrics,
                  ),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 14),
                badge,
              ],
            );
          },
        ),
      ),
    );
  }
}

// Private UI/data helper used only inside this module.
class _MovementMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  // Handles the movement metric box logic used by this module.
  const _MovementMetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Handles the container logic used by this module.
    return Container(
      constraints: const BoxConstraints(minWidth: 110),
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
class _ProductMovementEmptyState extends StatelessWidget {
  // Handles the product movement empty state logic used by this module.
  const _ProductMovementEmptyState();

  @override
  Widget build(BuildContext context) {
    // Handles the center logic used by this module.
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_outlined, size: 60, color: Color(0xFFB8C5D5)),
          SizedBox(height: 11),
          Text(
            'No products found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF657386),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Choose another sales period or product category.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AA5B3)),
          ),
        ],
      ),
    );
  }
}

// Screen widget for analyzes transaction item quantities to identify product movement and sales activity.
class ProductMovementReportScreen extends StatefulWidget {
  // Handles the product movement report screen logic used by this module.
  const ProductMovementReportScreen({super.key});

  @override
  State<ProductMovementReportScreen> createState() =>
      _ProductMovementReportScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _ProductMovementReportScreenState
    extends State<ProductMovementReportScreen> {
  String _selectedPeriod = 'Last 30 Days';
  String _selectedCategory = 'All';

  // Normalizes supported Firestore/date values into a Dart DateTime for consistent comparisons.
  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Handles the cutoff date logic used by this module.
  DateTime _cutoffDate() {
    final now = DateTime.now();

    switch (_selectedPeriod) {
      case 'Last 7 Days':
        return now.subtract(const Duration(days: 7));
      case 'Last 90 Days':
        return now.subtract(const Duration(days: 90));
      case 'All Time':
        // Handles the date time logic used by this module.
        return DateTime(2000);
      default:
        return now.subtract(const Duration(days: 30));
    }
  }

  // Handles the classification logic used by this module.
  String _classification(int quantitySold) {
    if (quantitySold >= 20) return 'Fast-Moving';
    if (quantitySold >= 5) return 'Regular';
    if (quantitySold > 0) return 'Slow-Moving';
    return 'No Sales';
  }

  // Handles the classification color logic used by this module.
  Color _classificationColor(String classification) {
    switch (classification) {
      case 'Fast-Moving':
        return Colors.green;
      case 'Regular':
        // Handles the color logic used by this module.
        return const Color(0xFF1565C0);
      case 'Slow-Moving':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  // Handles the classification icon logic used by this module.
  IconData _classificationIcon(String classification) {
    switch (classification) {
      case 'Fast-Moving':
        return Icons.trending_up;
      case 'Regular':
        return Icons.show_chart;
      case 'Slow-Moving':
        return Icons.trending_flat;
      default:
        return Icons.trending_down;
    }
  }

  // Handles the summary card logic used by this module.
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Handles the product movement hover card logic used by this module.
    return _ProductMovementHoverCard(
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

        if (productSnapshot.hasError) {
          // Handles the center logic used by this module.
          return Center(
            child: Text(
              'Unable to load products.\n${productSnapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final products =
            productSnapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        final categories = <String>{
          for (final document in products)
            if ((document.data()['category'] ?? '')
                .toString()
                .trim()
                .isNotEmpty)
              (document.data()['category'] ?? '').toString(),
        }.toList()..sort();

        final cutoff = _cutoffDate();

        Query<Map<String, dynamic>> transactionQuery = FirebaseFirestore
            .instance
            .collection('transactions');

        if (_selectedPeriod != 'All Time') {
          transactionQuery = transactionQuery.where(
            'createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(cutoff),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: transactionQuery.snapshots(),
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
                  'Unable to load transactions.\n${transactionSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            final Map<String, int> soldByProductId = {};
            final Map<String, int> soldByProductName = {};
            final Map<String, double> revenueByProductId = {};
            final Map<String, double> revenueByProductName = {};

            for (final transaction
                in transactionSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
              final data = transaction.data();

              final status = (data['status'] ?? 'completed')
                  .toString()
                  .toLowerCase();

              if (status == 'voided') continue;

              final createdAt = _readDate(data['createdAt']);
              if (createdAt == null || createdAt.isBefore(cutoff)) {
                continue;
              }

              final items = data['items'] as List<dynamic>? ?? <dynamic>[];

              for (final rawItem in items) {
                if (rawItem is! Map) continue;

                final item = Map<String, dynamic>.from(rawItem);

                final productId = (item['productId'] ?? '').toString();

                final productName = (item['productName'] ?? '')
                    .toString()
                    .toLowerCase();

                final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

                final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;

                if (productId.isNotEmpty) {
                  soldByProductId[productId] =
                      (soldByProductId[productId] ?? 0) + quantity;

                  revenueByProductId[productId] =
                      (revenueByProductId[productId] ?? 0) + subtotal;
                }

                if (productName.isNotEmpty) {
                  soldByProductName[productName] =
                      (soldByProductName[productName] ?? 0) + quantity;

                  revenueByProductName[productName] =
                      (revenueByProductName[productName] ?? 0) + subtotal;
                }
              }
            }

            final allRows = products
                .map((document) {
                  final data = document.data();

                  final productName = (data['productName'] ?? 'Unknown Product')
                      .toString();

                  final category = (data['category'] ?? 'Uncategorized')
                      .toString();

                  final quantitySold =
                      soldByProductId[document.id] ??
                      soldByProductName[productName.toLowerCase()] ??
                      0;

                  final revenue =
                      revenueByProductId[document.id] ??
                      revenueByProductName[productName.toLowerCase()] ??
                      0;

                  final stock = (data['stock'] as num?)?.toInt() ?? 0;

                  // Handles the product movement logic used by this module.
                  return _ProductMovement(
                    productName: productName,
                    category: category,
                    quantitySold: quantitySold,
                    revenue: revenue,
                    stock: stock,
                    classification: _classification(quantitySold),
                  );
                })
                .where((row) {
                  return _selectedCategory == 'All' ||
                      row.category == _selectedCategory;
                })
                .toList();

            // Keep the summary counts based on all products in the selected
            // category, but only render products with actual sales movement.
            // This prevents thousands of "No Sales" cards from being built.
            final rows = allRows.where((row) => row.quantitySold > 0).toList();

            rows.sort((a, b) {
              final quantityComparison = b.quantitySold.compareTo(
                a.quantitySold,
              );

              if (quantityComparison != 0) {
                return quantityComparison;
              }

              return a.productName.compareTo(b.productName);
            });

            final fastCount = allRows
                .where((row) => row.classification == 'Fast-Moving')
                .length;

            final regularCount = allRows
                .where((row) => row.classification == 'Regular')
                .length;

            final slowCount = allRows
                .where((row) => row.classification == 'Slow-Moving')
                .length;

            final noSalesCount = allRows
                .where((row) => row.classification == 'No Sales')
                .length;

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
                                Icons.trending_up_outlined,
                                color: Colors.white,
                                size: 29,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Product Movement',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Rank products by units sold, revenue, '
                                      'stock level, and sales movement.',
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
                            final compact = constraints.maxWidth < 900;

                            final periodFilter =
                                DropdownButtonFormField<String>(
                                  initialValue: _selectedPeriod,
                                  decoration: _movementInputDecoration(
                                    label: 'Sales Period',
                                    icon: Icons.date_range_outlined,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Last 7 Days',
                                      child: Text('Last 7 Days'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Last 30 Days',
                                      child: Text('Last 30 Days'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Last 90 Days',
                                      child: Text('Last 90 Days'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'All Time',
                                      child: Text('All Time'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedPeriod = value;
                                    });
                                  },
                                );

                            final categoryFilter =
                                DropdownButtonFormField<String>(
                                  initialValue:
                                      categories.contains(_selectedCategory)
                                      ? _selectedCategory
                                      : 'All',
                                  decoration: _movementInputDecoration(
                                    label: 'Category',
                                    icon: Icons.category_outlined,
                                  ),
                                  items: [
                                    // Handles the dropdown menu item logic used by this module.
                                    const DropdownMenuItem(
                                      value: 'All',
                                      child: Text('All Categories'),
                                    ),
                                    ...categories.map(
                                      (category) => DropdownMenuItem(
                                        value: category,
                                        child: Text(category),
                                      ),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _selectedCategory = value;
                                    });
                                  },
                                );

                            if (compact) {
                              // Handles the column logic used by this module.
                              return Column(
                                children: [
                                  periodFilter,
                                  // Handles the sized box logic used by this module.
                                  const SizedBox(height: 12),
                                  categoryFilter,
                                ],
                              );
                            }

                            // Handles the row logic used by this module.
                            return Row(
                              children: [
                                Expanded(child: periodFilter),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 14),
                                Expanded(child: categoryFilter),
                              ],
                            );
                          },
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
                                  title: 'Fast-Moving',
                                  value: '$fastCount',
                                  icon: Icons.trending_up,
                                  color: const Color(0xFF159447),
                                ),
                                _summaryCard(
                                  title: 'Regular',
                                  value: '$regularCount',
                                  icon: Icons.show_chart,
                                  color: const Color(0xFF1565C0),
                                ),
                                _summaryCard(
                                  title: 'Slow-Moving',
                                  value: '$slowCount',
                                  icon: Icons.trending_flat,
                                  color: const Color(0xFFF59E0B),
                                ),
                                _summaryCard(
                                  title: 'No Sales',
                                  value: '$noSalesCount',
                                  icon: Icons.trending_down,
                                  color: const Color(0xFFD32F2F),
                                ),
                              ],
                            );
                          },
                        ),
                        // Handles the sized box logic used by this module.
                        const SizedBox(height: 16),
                        _ProductMovementHoverCard(
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
                            child: const Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0x1F1565C0),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Fast-Moving = 20 or more units, '
                                    'Regular = 5–19 units, '
                                    'Slow-Moving = 1–4 units, '
                                    'No Sales = 0 units.',
                                    style: TextStyle(
                                      color: Color(0xFF53657C),
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
                                    'Product Movement Ranking',
                                    style: TextStyle(
                                      color: Color(0xFF172033),
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Products are ranked by units sold for the selected period.',
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
                                '${rows.length} PRODUCT(S)',
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
                        if (rows.isEmpty)
                          // Handles the sized box logic used by this module.
                          const SizedBox(
                            height: 230,
                            child: _ProductMovementEmptyState(),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rows.length,
                            separatorBuilder: (_, _) =>
                                // Handles the sized box logic used by this module.
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              final color = _classificationColor(
                                row.classification,
                              );

                              // Handles the product movement card logic used by this module.
                              return _ProductMovementCard(
                                rank: index + 1,
                                productName: row.productName,
                                category: row.category,
                                quantitySold: row.quantitySold,
                                revenue: row.revenue,
                                stock: row.stock,
                                classification: row.classification,
                                color: color,
                                icon: _classificationIcon(row.classification),
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

  // Handles the movement input decoration logic used by this module.
  InputDecoration _movementInputDecoration({
    required String label,
    required IconData icon,
  }) {
    // Handles the input decoration logic used by this module.
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFDDE6F1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFDDE6F1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
    );
  }
}

// Private UI/data helper used only inside this module.
class _ProductMovement {
  final String productName;
  final String category;
  final int quantitySold;
  final double revenue;
  final int stock;
  final String classification;

  // Handles the product movement logic used by this module.
  const _ProductMovement({
    required this.productName,
    required this.category,
    required this.quantitySold,
    required this.revenue,
    required this.stock,
    required this.classification,
  });
}
