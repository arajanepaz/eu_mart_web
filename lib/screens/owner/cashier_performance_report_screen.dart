// -----------------------------------------------------------------------------
// Module overview: Analyzes cashier transaction and service data to present basic cashier performance indicators.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Private UI/data helper used only inside this module.
class _CashierPerformanceHoverCard extends StatefulWidget {
  final Widget child;

  // Handles the cashier performance hover card logic used by this module.
  const _CashierPerformanceHoverCard({required this.child});

  @override
  State<_CashierPerformanceHoverCard> createState() =>
      _CashierPerformanceHoverCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierPerformanceHoverCardState
    extends State<_CashierPerformanceHoverCard> {
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
class _CashierRankingCard extends StatefulWidget {
  final int rank;
  final String name;
  final String email;
  final int transactionCount;
  final int itemsSold;
  final double averageTransaction;
  final double totalSales;
  final bool topPerformer;

  // Handles the cashier ranking card logic used by this module.
  const _CashierRankingCard({
    required this.rank,
    required this.name,
    required this.email,
    required this.transactionCount,
    required this.itemsSold,
    required this.averageTransaction,
    required this.totalSales,
    required this.topPerformer,
  });

  @override
  State<_CashierRankingCard> createState() => _CashierRankingCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierRankingCardState extends State<_CashierRankingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.topPerformer
        ? const Color(0xFFF59E0B)
        : const Color(0xFF1565C0);

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
            colors: [Colors.white, accent.withValues(alpha: 0.03)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? accent.withValues(alpha: 0.30)
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
            final compact = constraints.maxWidth < 850;

            final account = Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: widget.topPerformer
                      ? Icon(
                          Icons.emoji_events_outlined,
                          color: accent,
                          size: 27,
                        )
                      : Center(
                          child: Text(
                            '${widget.rank}',
                            style: TextStyle(
                              color: accent,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF172033),
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (widget.topPerformer) ...[
                            // Handles the sized box logic used by this module.
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3D8),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'TOP',
                                style: TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (widget.email.isNotEmpty) ...[
                        // Handles the sized box logic used by this module.
                        const SizedBox(height: 3),
                        Text(
                          widget.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF8A95A4),
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final metrics = Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                _CashierMetricPill(
                  label: 'Transactions',
                  value: '${widget.transactionCount}',
                  color: const Color(0xFF1565C0),
                ),
                _CashierMetricPill(
                  label: 'Items Sold',
                  value: '${widget.itemsSold}',
                  color: const Color(0xFF7B1FA2),
                ),
                _CashierMetricPill(
                  label: 'Average',
                  value: '₱${widget.averageTransaction.toStringAsFixed(2)}',
                  color: const Color(0xFFF59E0B),
                ),
                _CashierMetricPill(
                  label: 'Sales',
                  value: '₱${widget.totalSales.toStringAsFixed(2)}',
                  color: const Color(0xFF159447),
                ),
              ],
            );

            if (compact) {
              // Handles the column logic used by this module.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [account, const SizedBox(height: 14), metrics],
              );
            }

            // Handles the row logic used by this module.
            return Row(
              children: [
                Expanded(flex: 3, child: account),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
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
class _CashierMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  // Handles the cashier metric pill logic used by this module.
  const _CashierMetricPill({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Handles the container logic used by this module.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
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
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierPerformanceEmptyState extends StatelessWidget {
  // Handles the cashier performance empty state logic used by this module.
  const _CashierPerformanceEmptyState();

  @override
  Widget build(BuildContext context) {
    // Handles the layout builder logic used by this module.
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 180;

        // Handles the single child scroll view logic used by this module.
        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: compact ? 8 : 20,
            horizontal: 16,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight > 0 ? constraints.maxHeight : 0,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: compact ? 42 : 60,
                    color: const Color(0xFFB8C5D5),
                  ),
                  SizedBox(height: compact ? 6 : 11),
                  Text(
                    'No cashier performance records found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF657386),
                      fontSize: compact ? 14 : 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    'Choose another period or complete new transactions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF9AA5B3),
                      fontSize: compact ? 11 : 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Screen widget for analyzes cashier transaction and service data to present basic cashier performance indicators.
class CashierPerformanceReportScreen extends StatefulWidget {
  // Handles the cashier performance report screen logic used by this module.
  const CashierPerformanceReportScreen({super.key});

  @override
  State<CashierPerformanceReportScreen> createState() =>
      _CashierPerformanceReportScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierPerformanceReportScreenState
    extends State<CashierPerformanceReportScreen> {
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
    // Handles the cashier performance hover card logic used by this module.
    return _CashierPerformanceHoverCard(
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
              'Unable to load cashier performance.\n'
              '${snapshot.error}',
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

        final Map<String, _CashierPerformance> performance = {};

        double overallSales = 0;
        int overallTransactions = 0;
        int overallItemsSold = 0;

        for (final document in transactions) {
          final data = document.data();

          final cashierId = (data['processedById'] ?? '').toString();

          final cashierName =
              (data['processedByName'] ??
                      data['processedByEmail'] ??
                      'Unknown User')
                  .toString();

          final cashierEmail = (data['processedByEmail'] ?? '').toString();

          final total = (data['total'] as num?)?.toDouble() ?? 0;

          final items = data['items'] as List<dynamic>? ?? <dynamic>[];

          int itemsSold = 0;

          for (final rawItem in items) {
            if (rawItem is! Map) continue;

            final item = Map<String, dynamic>.from(rawItem);

            itemsSold += (item['quantity'] as num?)?.toInt() ?? 0;
          }

          final key = cashierId.isNotEmpty
              ? cashierId
              : cashierEmail.isNotEmpty
              ? cashierEmail
              : cashierName;

          final current = performance[key];

          if (current == null) {
            performance[key] = _CashierPerformance(
              cashierName: cashierName,
              cashierEmail: cashierEmail,
              transactionCount: 1,
              totalSales: total,
              itemsSold: itemsSold,
            );
          } else {
            current.transactionCount++;
            current.totalSales += total;
            current.itemsSold += itemsSold;
          }

          overallSales += total;
          overallTransactions++;
          overallItemsSold += itemsSold;
        }

        final cashiers = performance.values.toList()
          ..sort((a, b) => b.totalSales.compareTo(a.totalSales));

        final averageTransaction = overallTransactions == 0
            ? 0.0
            : overallSales / overallTransactions;

        final topCashier = cashiers.isEmpty ? null : cashiers.first;

        // Handles the container logic used by this module.
        return Container(
          color: const Color(0xFFF2F6FC),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.sizeOf(context).height - 150,
              ),
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
                          Icons.workspace_premium_outlined,
                          color: Colors.white,
                          size: 29,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cashier Performance',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Compare cashier sales, transactions, items sold, '
                                'and average transaction value.',
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
                      if (constraints.maxWidth < 1050) count = 2;
                      if (constraints.maxWidth < 620) count = 1;

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
                            value: '₱${overallSales.toStringAsFixed(2)}',
                            icon: Icons.payments_outlined,
                            color: const Color(0xFF159447),
                          ),
                          _summaryCard(
                            title: 'Transactions',
                            value: '$overallTransactions',
                            icon: Icons.receipt_long_outlined,
                            color: const Color(0xFF1565C0),
                          ),
                          _summaryCard(
                            title: 'Items Sold',
                            value: '$overallItemsSold',
                            icon: Icons.shopping_bag_outlined,
                            color: const Color(0xFF7B1FA2),
                          ),
                          _summaryCard(
                            title: 'Average Transaction',
                            value: '₱${averageTransaction.toStringAsFixed(2)}',
                            icon: Icons.analytics_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      );
                    },
                  ),
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 16),
                  _CashierPerformanceHoverCard(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: topCashier == null
                              ? const [Color(0xFFF1F5F9), Color(0xFFF8FAFC)]
                              : const [Color(0xFFFFF7E6), Color(0xFFFFFBF3)],
                        ),
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(
                          color: topCashier == null
                              ? const Color(0xFFDDE6F1)
                              : const Color(0xFFF5D9A8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: topCashier == null
                                  ? const Color(0xFFE5E7EB)
                                  : const Color(0x1FF59E0B),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              topCashier == null
                                  ? Icons.info_outline
                                  : Icons.emoji_events_outlined,
                              color: topCashier == null
                                  ? const Color(0xFF7A8494)
                                  : const Color(0xFFF59E0B),
                            ),
                          ),
                          // Handles the sized box logic used by this module.
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              topCashier == null
                                  ? 'No completed transactions found for this period.'
                                  : 'Top performer: ${topCashier.cashierName} '
                                        'with ₱${topCashier.totalSales.toStringAsFixed(2)} in sales.',
                              style: TextStyle(
                                color: topCashier == null
                                    ? const Color(0xFF607086)
                                    : const Color(0xFF6B5A36),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                              'Cashier Ranking',
                              style: TextStyle(
                                color: Color(0xFF172033),
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Ranked by total sales for the selected period.',
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
                  if (cashiers.isEmpty)
                    // Handles the sized box logic used by this module.
                    const SizedBox(
                      height: 230,
                      child: _CashierPerformanceEmptyState(),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cashiers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final cashier = cashiers[index];

                        // Handles the constrained box logic used by this module.
                        return ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 124),
                          child: _CashierRankingCard(
                            rank: index + 1,
                            name: cashier.cashierName,
                            email: cashier.cashierEmail,
                            transactionCount: cashier.transactionCount,
                            itemsSold: cashier.itemsSold,
                            averageTransaction: cashier.averageTransaction,
                            totalSales: cashier.totalSales,
                            topPerformer: index == 0,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Handles the metric logic used by this module.
  Widget _metric(String label, String value) {
    // Handles the column logic used by this module.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        // Handles the sized box logic used by this module.
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// Private UI/data helper used only inside this module.
class _CashierPerformance {
  final String cashierName;
  final String cashierEmail;

  int transactionCount;
  double totalSales;
  int itemsSold;

  _CashierPerformance({
    required this.cashierName,
    required this.cashierEmail,
    required this.transactionCount,
    required this.totalSales,
    required this.itemsSold,
  });

  double get averageTransaction =>
      transactionCount == 0 ? 0 : totalSales / transactionCount;
}
