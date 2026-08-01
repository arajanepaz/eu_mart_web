import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class DailyOperationsSummaryScreen extends StatelessWidget {
  const DailyOperationsSummaryScreen({super.key});

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

  int _daysUntil(DateTime? date) {
    if (date == null) return 999999;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    return target.difference(today).inDays;
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '0s';

    final rounded = seconds.round();
    final minutes = rounded ~/ 60;
    final remaining = rounded % 60;

    if (minutes == 0) return '${remaining}s';

    return '${minutes}m ${remaining}s';
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? subtitle,
  }) {
    return _DailyOpsHoverCard(
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
                      maxLines: 1,
                      style: const TextStyle(
                        color: Color(0xFF172033),
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (subtitle != null) ...[
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertRow({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _DailyOpsHoverCard(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.08),
              color.withValues(alpha: 0.025),
            ],
          ),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withValues(alpha: 0.20)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF344255),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(minWidth: 38),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> transactions,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> issues,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> permits,
  }) {
    double todaySales = 0;
    int todayTransactions = 0;
    int totalDuration = 0;
    int durationCount = 0;
    int normalCount = 0;
    int minorDelayCount = 0;
    int longDelayCount = 0;

    for (final document in transactions) {
      final data = document.data();

      final status = (data['status'] ?? 'completed').toString().toLowerCase();

      if (status == 'voided') continue;

      final date = _readDate(
        data['transactionCompletedAt'] ?? data['createdAt'],
      );

      if (!_isToday(date)) continue;

      todaySales += (data['total'] as num?)?.toDouble() ?? 0;

      todayTransactions++;

      final duration = (data['transactionDurationSeconds'] as num?)?.toInt();

      if (duration != null && duration >= 0) {
        totalDuration += duration;
        durationCount++;

        final speed = (data['serviceSpeed'] ?? '').toString();

        if (speed == 'Long Delay' || duration > 300) {
          longDelayCount++;
        } else if (speed == 'Minor Delay' || duration > 120) {
          minorDelayCount++;
        } else {
          normalCount++;
        }
      }
    }

    int lowStockCount = 0;
    int outOfStockCount = 0;
    int expiringProductCount = 0;
    int expiredProductCount = 0;

    for (final document in products) {
      final data = document.data();

      if (data['isActive'] == false) continue;

      final stock = (data['stock'] as num?)?.toInt() ?? 0;

      if (stock <= 0) {
        outOfStockCount++;
      } else if (stock <= 10) {
        lowStockCount++;
      }

      final expiration = _readDate(data['expirationDate']);

      final days = _daysUntil(expiration);

      if (expiration != null) {
        if (days < 0) {
          expiredProductCount++;
        } else if (days <= 30) {
          expiringProductCount++;
        }
      }
    }

    final todayIssues = issues.where((document) {
      return _isToday(_readDate(document.data()['createdAt']));
    }).toList();

    final openIssues = issues.where((document) {
      return (document.data()['status'] ?? 'open').toString() != 'resolved';
    }).length;

    final majorOpenIssues = issues.where((document) {
      final data = document.data();

      return (data['status'] ?? 'open').toString() != 'resolved' &&
          (data['severity'] ?? 'Minor').toString() == 'Major';
    }).length;

    int permitDueSoon = 0;
    int permitExpired = 0;

    for (final document in permits) {
      final data = document.data();

      if (data['renewed'] == true) continue;

      final expiration = _readDate(data['expirationDate']);

      final reminderDays = (data['reminderDays'] as num?)?.toInt() ?? 30;

      final days = _daysUntil(expiration);

      if (days < 0) {
        permitExpired++;
      } else if (days <= reminderDays) {
        permitDueSoon++;
      }
    }

    final averageServiceTime = durationCount == 0
        ? 0.0
        : totalDuration / durationCount;

    final delayedTransactions = minorDelayCount + longDelayCount;

    final totalOperationalAlerts =
        lowStockCount +
        outOfStockCount +
        expiringProductCount +
        expiredProductCount +
        openIssues +
        permitDueSoon +
        permitExpired;

    String overallStatus;
    Color overallColor;

    if (majorOpenIssues > 0 ||
        longDelayCount > 0 ||
        permitExpired > 0 ||
        expiredProductCount > 0) {
      overallStatus = 'Needs Immediate Attention';
      overallColor = Colors.red;
    } else if (totalOperationalAlerts > 0) {
      overallStatus = 'Review Required';
      overallColor = Colors.orange;
    } else {
      overallStatus = 'Operations Normal';
      overallColor = Colors.green;
    }

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
                        Icons.dashboard_customize_outlined,
                        color: Colors.white,
                        size: 29,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Operations Summary',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Review today’s sales, service performance, '
                              'inventory alerts, and permit concerns.',
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
                _DailyOpsHoverCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          overallColor.withValues(alpha: 0.13),
                          overallColor.withValues(alpha: 0.035),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: overallColor.withValues(alpha: 0.25),
                      ),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 650;

                        final statusInfo = Row(
                          children: [
                            Container(
                              width: 54,
                              height: 54,
                              decoration: BoxDecoration(
                                color: overallColor.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                overallStatus == 'Operations Normal'
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_outlined,
                                color: overallColor,
                                size: 29,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'TODAY’S OPERATIONAL STATUS',
                                    style: TextStyle(
                                      color: Color(0xFF7A8494),
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    overallStatus,
                                    style: TextStyle(
                                      color: overallColor,
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );

                        final alertBadge = Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: overallColor.withValues(alpha: 0.11),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$totalOperationalAlerts ALERT(S)',
                            style: TextStyle(
                              color: overallColor,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        );

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              statusInfo,
                              const SizedBox(height: 12),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: alertBadge,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(child: statusInfo),
                            const SizedBox(width: 14),
                            alertBadge,
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
                          subtitle: '$todayTransactions transaction(s)',
                          icon: Icons.payments_outlined,
                          color: const Color(0xFF1565C0),
                        ),
                        _summaryCard(
                          title: 'Average Service Time',
                          value: _formatDuration(averageServiceTime),
                          subtitle:
                              '$delayedTransactions delayed transaction(s)',
                          icon: Icons.timer_outlined,
                          color: delayedTransactions > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF159447),
                        ),
                        _summaryCard(
                          title: 'Issues Reported Today',
                          value: '${todayIssues.length}',
                          subtitle: '$openIssues currently open',
                          icon: Icons.report_problem_outlined,
                          color: openIssues > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF159447),
                        ),
                        _summaryCard(
                          title: 'Operational Alerts',
                          value: '$totalOperationalAlerts',
                          subtitle: '$permitExpired expired permit(s)',
                          icon: Icons.notifications_active_outlined,
                          color: totalOperationalAlerts > 0
                              ? const Color(0xFFD32F2F)
                              : const Color(0xFF159447),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 20),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 900;

                    final servicePanel = _OperationsPanel(
                      title: 'Service Performance',
                      subtitle:
                          'Today’s transaction speed and reported concerns.',
                      icon: Icons.speed_outlined,
                      accent: const Color(0xFF1565C0),
                      child: Column(
                        children: [
                          _alertRow(
                            title: 'Normal Service',
                            value: '$normalCount',
                            icon: Icons.check_circle_outline,
                            color: const Color(0xFF159447),
                          ),
                          const SizedBox(height: 10),
                          _alertRow(
                            title: 'Minor Delay',
                            value: '$minorDelayCount',
                            icon: Icons.schedule_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 10),
                          _alertRow(
                            title: 'Long Delay',
                            value: '$longDelayCount',
                            icon: Icons.warning_amber_outlined,
                            color: const Color(0xFFD32F2F),
                          ),
                          const SizedBox(height: 10),
                          _alertRow(
                            title: 'Major Open Issues',
                            value: '$majorOpenIssues',
                            icon: Icons.report_problem_outlined,
                            color: const Color(0xFFD32F2F),
                          ),
                        ],
                      ),
                    );

                    final inventoryPanel = _OperationsPanel(
                      title: 'Inventory & Compliance',
                      subtitle: 'Stock, expiration, and permit status.',
                      icon: Icons.inventory_2_outlined,
                      accent: const Color(0xFF7B1FA2),
                      child: Column(
                        children: [
                          _alertRow(
                            title: 'Out of Stock',
                            value: '$outOfStockCount',
                            icon: Icons.remove_shopping_cart_outlined,
                            color: const Color(0xFFD32F2F),
                          ),
                          const SizedBox(height: 10),
                          _alertRow(
                            title: 'Low Stock',
                            value: '$lowStockCount',
                            icon: Icons.inventory_2_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 10),
                          _alertRow(
                            title: 'Expired Products',
                            value: '$expiredProductCount',
                            icon: Icons.event_busy_outlined,
                            color: const Color(0xFFD32F2F),
                          ),
                          const SizedBox(height: 10),
                          _alertRow(
                            title: 'Expiring Products',
                            value: '$expiringProductCount',
                            icon: Icons.event_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                          const SizedBox(height: 10),
                          _alertRow(
                            title: 'Expired Permits',
                            value: '$permitExpired',
                            icon: Icons.assignment_late_outlined,
                            color: const Color(0xFFD32F2F),
                          ),
                          const SizedBox(height: 10),
                          _alertRow(
                            title: 'Permits Due Soon',
                            value: '$permitDueSoon',
                            icon: Icons.description_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                    );

                    if (compact) {
                      return Column(
                        children: [
                          servicePanel,
                          const SizedBox(height: 16),
                          inventoryPanel,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: servicePanel),
                        const SizedBox(width: 16),
                        Expanded(child: inventoryPanel),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, transactionSnapshot) {
        if (transactionSnapshot.connectionState == ConnectionState.waiting &&
            !transactionSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (transactionSnapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load transaction data.\n'
              '${transactionSnapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            if (productSnapshot.connectionState == ConnectionState.waiting &&
                !productSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productSnapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load product data.\n'
                  '${productSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('service_issues')
                  .snapshots(),
              builder: (context, issueSnapshot) {
                if (issueSnapshot.connectionState == ConnectionState.waiting &&
                    !issueSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (issueSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load service issues.\n'
                      '${issueSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('permit_reminders')
                      .snapshots(),
                  builder: (context, permitSnapshot) {
                    if (permitSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !permitSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (permitSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load permit data.\n'
                          '${permitSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    return _buildContent(
                      transactions:
                          transactionSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                      products:
                          productSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                      issues:
                          issueSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                      permits:
                          permitSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

class _DailyOpsHoverCard extends StatefulWidget {
  final Widget child;

  const _DailyOpsHoverCard({required this.child});

  @override
  State<_DailyOpsHoverCard> createState() => _DailyOpsHoverCardState();
}

class _DailyOpsHoverCardState extends State<_DailyOpsHoverCard> {
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

class _OperationsPanel extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  const _OperationsPanel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _DailyOpsHoverCard(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, accent.withValues(alpha: 0.03)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.14)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.72)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
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
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF8A95A4),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
