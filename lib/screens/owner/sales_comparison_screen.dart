import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _SalesCompareHoverCard extends StatefulWidget {
  final Widget child;

  const _SalesCompareHoverCard({required this.child});

  @override
  State<_SalesCompareHoverCard> createState() => _SalesCompareHoverCardState();
}

class _SalesCompareHoverCardState extends State<_SalesCompareHoverCard> {
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

class _SalesMetricPill extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const _SalesMetricPill({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
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
            title,
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
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesSectionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _SalesSectionIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class SalesComparisonScreen extends StatelessWidget {
  const SalesComparisonScreen({super.key});

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  bool _isSameDay(DateTime date, DateTime target) {
    return date.year == target.year &&
        date.month == target.month &&
        date.day == target.day;
  }

  double _percentChange(double current, double previous) {
    if (previous == 0) {
      return current == 0 ? 0 : 100;
    }

    return ((current - previous) / previous) * 100;
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return _SalesCompareHoverCard(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, color.withValues(alpha: 0.055)],
          ),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(color: color.withValues(alpha: 0.14)),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withValues(alpha: 0.72)],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.22),
                    blurRadius: 11,
                    offset: const Offset(0, 6),
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
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
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

  Widget _comparisonRow({
    required String label,
    required String today,
    required String yesterday,
    required String difference,
    required Color differenceColor,
  }) {
    return _SalesCompareHoverCard(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, differenceColor.withValues(alpha: 0.025)],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: const Color(0xFFE1E9F3)),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 700;

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 9,
                    runSpacing: 8,
                    children: [
                      _SalesMetricPill(
                        title: 'Today',
                        value: today,
                        color: const Color(0xFF1565C0),
                      ),
                      _SalesMetricPill(
                        title: 'Yesterday',
                        value: yesterday,
                        color: const Color(0xFF7B1FA2),
                      ),
                      _SalesMetricPill(
                        title: 'Difference',
                        value: difference,
                        color: differenceColor,
                      ),
                    ],
                  ),
                ],
              );
            }

            return Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    today,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    yesterday,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF7B1FA2),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    difference,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: differenceColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

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
              'Unable to load sales comparison.\n'
              '${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        double todaySales = 0;
        double yesterdaySales = 0;
        int todayTransactions = 0;
        int yesterdayTransactions = 0;
        int todayItems = 0;
        int yesterdayItems = 0;
        int todayDurationTotal = 0;
        int yesterdayDurationTotal = 0;
        int todayDurationCount = 0;
        int yesterdayDurationCount = 0;

        for (final document
            in snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
          final data = document.data();

          final status = (data['status'] ?? 'completed')
              .toString()
              .toLowerCase();

          if (status == 'voided') continue;

          final date = _readDate(
            data['transactionCompletedAt'] ?? data['createdAt'],
          );

          if (date == null) continue;

          final total = (data['total'] as num?)?.toDouble() ?? 0;

          final duration = (data['transactionDurationSeconds'] as num?)
              ?.toInt();

          final items = data['items'] as List<dynamic>? ?? <dynamic>[];

          int itemCount = 0;

          for (final rawItem in items) {
            if (rawItem is! Map) continue;

            final item = Map<String, dynamic>.from(rawItem);

            itemCount += (item['quantity'] as num?)?.toInt() ?? 0;
          }

          if (_isSameDay(date, today)) {
            todaySales += total;
            todayTransactions++;
            todayItems += itemCount;

            if (duration != null && duration >= 0) {
              todayDurationTotal += duration;
              todayDurationCount++;
            }
          } else if (_isSameDay(date, yesterday)) {
            yesterdaySales += total;
            yesterdayTransactions++;
            yesterdayItems += itemCount;

            if (duration != null && duration >= 0) {
              yesterdayDurationTotal += duration;
              yesterdayDurationCount++;
            }
          }
        }

        final salesChange = _percentChange(todaySales, yesterdaySales);

        final transactionChange = _percentChange(
          todayTransactions.toDouble(),
          yesterdayTransactions.toDouble(),
        );

        final itemChange = _percentChange(
          todayItems.toDouble(),
          yesterdayItems.toDouble(),
        );

        final todayAverage = todayTransactions == 0
            ? 0.0
            : todaySales / todayTransactions;

        final yesterdayAverage = yesterdayTransactions == 0
            ? 0.0
            : yesterdaySales / yesterdayTransactions;

        final averageChange = _percentChange(todayAverage, yesterdayAverage);

        final todayAverageDuration = todayDurationCount == 0
            ? 0.0
            : todayDurationTotal / todayDurationCount;

        final yesterdayAverageDuration = yesterdayDurationCount == 0
            ? 0.0
            : yesterdayDurationTotal / yesterdayDurationCount;

        final durationDifference =
            todayAverageDuration - yesterdayAverageDuration;

        Color changeColor(double value) {
          if (value > 0) return Colors.green;
          if (value < 0) return Colors.red;
          return Colors.grey;
        }

        String changeLabel(double value) {
          final sign = value > 0
              ? '+'
              : value < 0
              ? ''
              : '';

          return '$sign${value.toStringAsFixed(1)}%';
        }

        String durationLabel(double seconds) {
          if (seconds == 0) return 'No change';

          final sign = seconds > 0 ? '+' : '-';
          final absolute = seconds.abs().round();
          final minutes = absolute ~/ 60;
          final remaining = absolute % 60;

          return '$sign${minutes}m ${remaining}s';
        }

        final trendColor = changeColor(salesChange);
        final trendIcon = salesChange > 0
            ? Icons.trending_up_rounded
            : salesChange < 0
            ? Icons.trending_down_rounded
            : Icons.trending_flat_rounded;

        final trendTitle = salesChange > 0
            ? 'Sales Increased'
            : salesChange < 0
            ? 'Sales Decreased'
            : 'Sales Unchanged';

        final trendMessage = salesChange > 0
            ? 'Today’s sales are higher than yesterday by '
                  '${salesChange.toStringAsFixed(1)}%.'
            : salesChange < 0
            ? 'Today’s sales are lower than yesterday by '
                  '${salesChange.abs().toStringAsFixed(1)}%.'
            : 'Today’s sales are equal to yesterday.';

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
                            Icons.compare_arrows_rounded,
                            color: Colors.white,
                            size: 29,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sales Comparison',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Compare today’s sales and service '
                                  'performance with yesterday.',
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
                    _SalesCompareHoverCard(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              trendColor.withValues(alpha: 0.13),
                              trendColor.withValues(alpha: 0.035),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: trendColor.withValues(alpha: 0.24),
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final compact = constraints.maxWidth < 650;

                            final info = Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    color: trendColor.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    trendIcon,
                                    color: trendColor,
                                    size: 29,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        trendTitle,
                                        style: TextStyle(
                                          color: trendColor,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        trendMessage,
                                        style: const TextStyle(
                                          color: Color(0xFF607086),
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );

                            final badge = Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: trendColor.withValues(alpha: 0.11),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                changeLabel(salesChange),
                                style: TextStyle(
                                  color: trendColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  info,
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: badge,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: info),
                                const SizedBox(width: 14),
                                badge,
                              ],
                            );
                          },
                        ),
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
                          childAspectRatio: count == 4 ? 2.2 : 3.0,
                          children: [
                            _summaryCard(
                              title: 'Today’s Sales',
                              value: '₱${todaySales.toStringAsFixed(2)}',
                              subtitle:
                                  '${changeLabel(salesChange)} vs yesterday',
                              icon: Icons.payments_outlined,
                              color: changeColor(salesChange),
                            ),
                            _summaryCard(
                              title: 'Today’s Transactions',
                              value: '$todayTransactions',
                              subtitle:
                                  '${changeLabel(transactionChange)} vs yesterday',
                              icon: Icons.receipt_long_outlined,
                              color: changeColor(transactionChange),
                            ),
                            _summaryCard(
                              title: 'Items Sold Today',
                              value: '$todayItems',
                              subtitle:
                                  '${changeLabel(itemChange)} vs yesterday',
                              icon: Icons.shopping_bag_outlined,
                              color: changeColor(itemChange),
                            ),
                            _summaryCard(
                              title: 'Average Transaction',
                              value: '₱${todayAverage.toStringAsFixed(2)}',
                              subtitle:
                                  '${changeLabel(averageChange)} vs yesterday',
                              icon: Icons.analytics_outlined,
                              color: changeColor(averageChange),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    _SalesCompareHoverCard(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFFBFDFF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE1E9F3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                _SalesSectionIcon(
                                  icon: Icons.table_chart_outlined,
                                  color: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Detailed Comparison',
                                        style: TextStyle(
                                          color: Color(0xFF172033),
                                          fontSize: 19,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Review the difference between today and yesterday.',
                                        style: TextStyle(
                                          color: Color(0xFF8A95A4),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (MediaQuery.sizeOf(context).width >= 760) ...[
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'METRIC',
                                        style: TextStyle(
                                          color: Color(0xFF8A95A4),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'TODAY',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Color(0xFF1565C0),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'YESTERDAY',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Color(0xFF7B1FA2),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'DIFFERENCE',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: Color(0xFF7A8494),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10),
                            ],
                            _comparisonRow(
                              label: 'Sales',
                              today: '₱${todaySales.toStringAsFixed(2)}',
                              yesterday:
                                  '₱${yesterdaySales.toStringAsFixed(2)}',
                              difference: changeLabel(salesChange),
                              differenceColor: changeColor(salesChange),
                            ),
                            const SizedBox(height: 10),
                            _comparisonRow(
                              label: 'Transactions',
                              today: '$todayTransactions',
                              yesterday: '$yesterdayTransactions',
                              difference: changeLabel(transactionChange),
                              differenceColor: changeColor(transactionChange),
                            ),
                            const SizedBox(height: 10),
                            _comparisonRow(
                              label: 'Items Sold',
                              today: '$todayItems',
                              yesterday: '$yesterdayItems',
                              difference: changeLabel(itemChange),
                              differenceColor: changeColor(itemChange),
                            ),
                            const SizedBox(height: 10),
                            _comparisonRow(
                              label: 'Average Transaction',
                              today: '₱${todayAverage.toStringAsFixed(2)}',
                              yesterday:
                                  '₱${yesterdayAverage.toStringAsFixed(2)}',
                              difference: changeLabel(averageChange),
                              differenceColor: changeColor(averageChange),
                            ),
                            const SizedBox(height: 10),
                            _comparisonRow(
                              label: 'Average Service Time',
                              today: '${todayAverageDuration.round()} sec',
                              yesterday:
                                  '${yesterdayAverageDuration.round()} sec',
                              difference: durationLabel(durationDifference),
                              differenceColor: durationDifference > 0
                                  ? const Color(0xFFD32F2F)
                                  : durationDifference < 0
                                  ? const Color(0xFF159447)
                                  : const Color(0xFF7A8494),
                            ),
                          ],
                        ),
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
  }
}
