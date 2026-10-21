// -----------------------------------------------------------------------------
// Module overview: Reports transaction results associated with promotional products and promotional pricing.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Private UI/data helper used only inside this module.
class _PromoHoverCard extends StatefulWidget {
  final Widget child;

  // Handles the promo hover card logic used by this module.
  const _PromoHoverCard({required this.child});

  @override
  State<_PromoHoverCard> createState() => _PromoHoverCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _PromoHoverCardState extends State<_PromoHoverCard> {
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
class _PromoProductCard extends StatefulWidget {
  final int rank;
  final String productName;
  final String promoLabel;
  final int quantitySold;
  final double revenue;
  final double savings;

  // Handles the promo product card logic used by this module.
  const _PromoProductCard({
    required this.rank,
    required this.productName,
    required this.promoLabel,
    required this.quantitySold,
    required this.revenue,
    required this.savings,
  });

  @override
  State<_PromoProductCard> createState() => _PromoProductCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _PromoProductCardState extends State<_PromoProductCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF7B1FA2);

    // Handles the mouse region logic used by this module.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFFCF8FF)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered ? const Color(0xFFC7A7DE) : const Color(0xFFE1E9F3),
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

            final promoInfo = Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
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
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.09),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.promoLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: accent,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
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
                _PromoMetricBox(
                  label: 'Sold',
                  value: '${widget.quantitySold}',
                  color: const Color(0xFF1565C0),
                ),
                _PromoMetricBox(
                  label: 'Revenue',
                  value: '₱${widget.revenue.toStringAsFixed(2)}',
                  color: const Color(0xFF159447),
                ),
                _PromoMetricBox(
                  label: 'Savings',
                  value: '₱${widget.savings.toStringAsFixed(2)}',
                  color: const Color(0xFFF59E0B),
                ),
              ],
            );

            if (compact) {
              // Handles the column logic used by this module.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [promoInfo, const SizedBox(height: 14), metrics],
              );
            }

            // Handles the row logic used by this module.
            return Row(
              children: [
                Expanded(flex: 4, child: promoInfo),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
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
class _PromoMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  // Handles the promo metric box logic used by this module.
  const _PromoMetricBox({
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
class _PromoSalesEmptyState extends StatelessWidget {
  // Handles the promo sales empty state logic used by this module.
  const _PromoSalesEmptyState();

  @override
  Widget build(BuildContext context) {
    // Handles the center logic used by this module.
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_offer_outlined, size: 60, color: Color(0xFFB8C5D5)),
          SizedBox(height: 11),
          Text(
            'No promo sales found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF657386),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Choose another period or complete transactions with active promos.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AA5B3)),
          ),
        ],
      ),
    );
  }
}

// Screen widget for reports transaction results associated with promotional products and promotional pricing.
class PromoSalesReportScreen extends StatefulWidget {
  // Handles the promo sales report screen logic used by this module.
  const PromoSalesReportScreen({super.key});

  @override
  State<PromoSalesReportScreen> createState() => _PromoSalesReportScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _PromoSalesReportScreenState extends State<PromoSalesReportScreen> {
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
    // Handles the promo hover card logic used by this module.
    return _PromoHoverCard(
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
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
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
              'Unable to load promo sales.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final transactions =
            snapshot.data?.docs.where((document) {
              final data = document.data();
              final status = (data['status'] ?? 'completed')
                  .toString()
                  .toLowerCase();

              return status != 'voided' &&
                  _matchesFilter(_readDate(data['createdAt']));
            }).toList() ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];

        int promoTransactionCount = 0;
        int promoItemsSold = 0;
        double promoRevenue = 0;
        double customerSavings = 0;

        final Map<String, _PromoProductSales> productSales = {};

        for (final document in transactions) {
          final data = document.data();
          final items = data['items'] as List<dynamic>? ?? <dynamic>[];

          bool transactionHasPromo = false;

          for (final rawItem in items) {
            if (rawItem is! Map) continue;

            final item = Map<String, dynamic>.from(rawItem);

            final promoApplied = item['promoApplied'] == true;

            if (!promoApplied) continue;

            transactionHasPromo = true;

            final productName = (item['productName'] ?? 'Unknown Product')
                .toString();

            final promoType = (item['promoType'] ?? 'Promotion').toString();

            final promoLabel = (item['promoLabel'] ?? promoType).toString();

            final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

            final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;

            final regularPrice =
                (item['regularPrice'] as num?)?.toDouble() ??
                (item['price'] as num?)?.toDouble() ??
                0;

            final itemSavings = (regularPrice * quantity) - subtotal;

            promoItemsSold += quantity;
            promoRevenue += subtotal;

            if (itemSavings > 0) {
              customerSavings += itemSavings;
            }

            final key = '$productName|$promoType';

            final existing = productSales[key];

            if (existing == null) {
              productSales[key] = _PromoProductSales(
                productName: productName,
                promoType: promoType,
                promoLabel: promoLabel,
                quantitySold: quantity,
                revenue: subtotal,
                savings: itemSavings > 0 ? itemSavings : 0,
              );
            } else {
              existing.quantitySold += quantity;
              existing.revenue += subtotal;

              if (itemSavings > 0) {
                existing.savings += itemSavings;
              }
            }
          }

          final storedSavings = (data['totalSavings'] as num?)?.toDouble();

          if (storedSavings != null &&
              storedSavings > 0 &&
              transactionHasPromo) {
            final calculatedTransactionSavings = items.fold<double>(0, (
              sum,
              rawItem,
            ) {
              if (rawItem is! Map) return sum;

              final item = Map<String, dynamic>.from(rawItem);

              if (item['promoApplied'] != true) {
                return sum;
              }

              final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

              final subtotal = (item['subtotal'] as num?)?.toDouble() ?? 0;

              final regularPrice =
                  (item['regularPrice'] as num?)?.toDouble() ??
                  (item['price'] as num?)?.toDouble() ??
                  0;

              final savings = (regularPrice * quantity) - subtotal;

              return sum + (savings > 0 ? savings : 0);
            });

            customerSavings += storedSavings - calculatedTransactionSavings;
          }

          if (transactionHasPromo) {
            promoTransactionCount++;
          }
        }

        final topPromos = productSales.values.toList()
          ..sort((a, b) => b.quantitySold.compareTo(a.quantitySold));

        final averagePromoSale = promoTransactionCount == 0
            ? 0.0
            : promoRevenue / promoTransactionCount;

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
                            Icons.local_offer_outlined,
                            color: Colors.white,
                            size: 29,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Promo Sales Report',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Review promotion performance, promo revenue, '
                                  'items sold, and customer savings.',
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
                              title: 'Promo Transactions',
                              value: '$promoTransactionCount',
                              icon: Icons.receipt_long_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            _summaryCard(
                              title: 'Promo Items Sold',
                              value: '$promoItemsSold',
                              icon: Icons.shopping_bag_outlined,
                              color: const Color(0xFF7B1FA2),
                            ),
                            _summaryCard(
                              title: 'Promo Revenue',
                              value: '₱${promoRevenue.toStringAsFixed(2)}',
                              icon: Icons.payments_outlined,
                              color: const Color(0xFF159447),
                            ),
                            _summaryCard(
                              title: 'Customer Savings',
                              value: '₱${customerSavings.toStringAsFixed(2)}',
                              icon: Icons.savings_outlined,
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        );
                      },
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 16),
                    _PromoHoverCard(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
                          ),
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(color: const Color(0xFFD7E7FA)),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 680;

                            final info = Row(
                              children: [
                                // Handles the circle avatar logic used by this module.
                                const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0x1F1565C0),
                                  child: Icon(
                                    Icons.analytics_outlined,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Handles the text logic used by this module.
                                      const Text(
                                        'AVERAGE PROMO TRANSACTION',
                                        style: TextStyle(
                                          color: Color(0xFF7A8494),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      // Handles the sized box logic used by this module.
                                      const SizedBox(height: 3),
                                      Text(
                                        '₱${averagePromoSale.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Color(0xFF1565C0),
                                          fontSize: 21,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            final badge = Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 11,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF8F0),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '${topPromos.length} PROMO PRODUCT(S)',
                                style: const TextStyle(
                                  color: Color(0xFF168653),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );

                            if (compact) {
                              // Handles the column logic used by this module.
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  info,
                                  // Handles the sized box logic used by this module.
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: badge,
                                  ),
                                ],
                              );
                            }

                            // Handles the row logic used by this module.
                            return Row(
                              children: [
                                Expanded(child: info),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 14),
                                badge,
                              ],
                            );
                          },
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
                                'Top Performing Promotions',
                                style: TextStyle(
                                  color: Color(0xFF172033),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Promotions are ranked by quantity sold.',
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
                            _selectedFilter.toUpperCase(),
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
                    if (topPromos.isEmpty)
                      // Handles the sized box logic used by this module.
                      const SizedBox(
                        height: 230,
                        child: _PromoSalesEmptyState(),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topPromos.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final promo = topPromos[index];

                          // Handles the promo product card logic used by this module.
                          return _PromoProductCard(
                            rank: index + 1,
                            productName: promo.productName,
                            promoLabel: promo.promoLabel.isEmpty
                                ? promo.promoType
                                : promo.promoLabel,
                            quantitySold: promo.quantitySold,
                            revenue: promo.revenue,
                            savings: promo.savings,
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
}

// Private UI/data helper used only inside this module.
class _PromoProductSales {
  final String productName;
  final String promoType;
  final String promoLabel;

  int quantitySold;
  double revenue;
  double savings;

  _PromoProductSales({
    required this.productName,
    required this.promoType,
    required this.promoLabel,
    required this.quantitySold,
    required this.revenue,
    required this.savings,
  });
}
