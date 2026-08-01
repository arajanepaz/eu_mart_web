import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _DrawerReportHoverCard extends StatefulWidget {
  final Widget child;

  const _DrawerReportHoverCard({required this.child});

  @override
  State<_DrawerReportHoverCard> createState() => _DrawerReportHoverCardState();
}

class _DrawerReportHoverCardState extends State<_DrawerReportHoverCard> {
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

class _DrawerSessionCard extends StatefulWidget {
  final String cashier;
  final String status;
  final bool isOpen;
  final double openingCash;
  final double sales;
  final double expectedCash;
  final double? countedCash;
  final double? variance;
  final Color varianceColor;
  final String varianceLabel;
  final String openedAt;
  final String closedAt;
  final String notes;

  const _DrawerSessionCard({
    required this.cashier,
    required this.status,
    required this.isOpen,
    required this.openingCash,
    required this.sales,
    required this.expectedCash,
    required this.countedCash,
    required this.variance,
    required this.varianceColor,
    required this.varianceLabel,
    required this.openedAt,
    required this.closedAt,
    required this.notes,
  });

  @override
  State<_DrawerSessionCard> createState() => _DrawerSessionCardState();
}

class _DrawerSessionCardState extends State<_DrawerSessionCard> {
  bool _hovered = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isOpen
        ? const Color(0xFF1565C0)
        : const Color(0xFF159447);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, statusColor.withValues(alpha: 0.025)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? statusColor.withValues(alpha: 0.30)
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
                    final compact = constraints.maxWidth < 760;

                    final cashierInfo = Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(
                            widget.isOpen
                                ? Icons.lock_open_outlined
                                : Icons.lock_outline,
                            color: statusColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.cashier,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF172033),
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Opened: ${widget.openedAt}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8A95A4),
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final badges = Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _DrawerStatusPill(
                          icon: widget.isOpen
                              ? Icons.lock_open_outlined
                              : Icons.lock_outline,
                          label: widget.status.toUpperCase(),
                          color: statusColor,
                        ),
                        _DrawerStatusPill(
                          icon: widget.variance == null
                              ? Icons.hourglass_empty_outlined
                              : widget.variance == 0
                              ? Icons.check_circle_outline
                              : widget.variance! > 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          label: widget.varianceLabel,
                          color: widget.varianceColor,
                        ),
                      ],
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          cashierInfo,
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: badges),
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

                    return Row(
                      children: [
                        Expanded(flex: 4, child: cashierInfo),
                        const SizedBox(width: 14),
                        Expanded(
                          flex: 3,
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: badges,
                          ),
                        ),
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
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _DrawerMetricBox(
                          label: 'Opening Cash',
                          value: '₱${widget.openingCash.toStringAsFixed(2)}',
                          color: const Color(0xFF1565C0),
                        ),
                        _DrawerMetricBox(
                          label: 'Net Sales',
                          value: '₱${widget.sales.toStringAsFixed(2)}',
                          color: const Color(0xFF159447),
                        ),
                        _DrawerMetricBox(
                          label: 'Expected Cash',
                          value: '₱${widget.expectedCash.toStringAsFixed(2)}',
                          color: const Color(0xFF7B1FA2),
                        ),
                        _DrawerMetricBox(
                          label: 'Counted Cash',
                          value: widget.countedCash == null
                              ? 'Pending'
                              : '₱${widget.countedCash!.toStringAsFixed(2)}',
                          color: const Color(0xFFF59E0B),
                        ),
                        _DrawerMetricBox(
                          label: widget.varianceLabel,
                          value: widget.variance == null
                              ? 'Pending'
                              : '₱${widget.variance!.abs().toStringAsFixed(2)}',
                          color: widget.varianceColor,
                        ),
                        _DrawerMetricBox(
                          label: 'Closed',
                          value: widget.closedAt,
                          color: const Color(0xFF607086),
                        ),
                      ],
                    ),
                    if (widget.notes.trim().isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7F9FC),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.notes_outlined,
                              color: Color(0xFF7A8494),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                widget.notes,
                                style: const TextStyle(
                                  color: Color(0xFF607086),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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

class _DrawerStatusPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DrawerStatusPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DrawerMetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 145),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
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
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _DrawerReportEmptyState extends StatelessWidget {
  const _DrawerReportEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 60,
            color: Color(0xFFB8C5D5),
          ),
          SizedBox(height: 11),
          Text(
            'No cash drawer sessions found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF657386),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Choose another period or wait for cashier drawer activity.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF9AA5B3)),
          ),
        ],
      ),
    );
  }
}

class OwnerCashDrawerReportScreen extends StatefulWidget {
  const OwnerCashDrawerReportScreen({super.key});

  @override
  State<OwnerCashDrawerReportScreen> createState() =>
      _OwnerCashDrawerReportScreenState();
}

class _OwnerCashDrawerReportScreenState
    extends State<OwnerCashDrawerReportScreen> {
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
    final sessionDate = DateTime(date.year, date.month, date.day);

    switch (_selectedFilter) {
      case 'Today':
        return sessionDate == today;
      case 'This Week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        return !sessionDate.isBefore(startOfWeek) &&
            !sessionDate.isAfter(endOfWeek);
      case 'This Month':
        return sessionDate.year == now.year && sessionDate.month == now.month;
      default:
        return true;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Unavailable';

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

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

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

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _DrawerReportHoverCard(
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('cash_sessions')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load cash drawer sessions.\n'
              '${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final sessions =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            ).where((document) {
              final data = document.data();
              final date = _readDate(data['closedAt'] ?? data['openedAt']);
              return _matchesFilter(date);
            }).toList();

        sessions.sort((a, b) {
          final first = _readDate(a.data()['closedAt'] ?? a.data()['openedAt']);
          final second = _readDate(
            b.data()['closedAt'] ?? b.data()['openedAt'],
          );

          if (first == null && second == null) return 0;
          if (first == null) return 1;
          if (second == null) return -1;

          return second.compareTo(first);
        });

        int openSessions = 0;
        int closedSessions = 0;
        double totalSales = 0;
        double totalShortage = 0;
        double totalOverage = 0;

        for (final document in sessions) {
          final data = document.data();
          final status = (data['status'] ?? '').toString();

          if (status == 'open') {
            openSessions++;
          } else {
            closedSessions++;
          }

          totalSales += (data['totalSales'] as num?)?.toDouble() ?? 0;

          final variance = (data['variance'] as num?)?.toDouble() ?? 0;

          if (variance < 0) {
            totalShortage += variance.abs();
          } else if (variance > 0) {
            totalOverage += variance;
          }
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
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 29,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Cash Drawer Report',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Review cashier drawer sessions, expected cash, '
                                  'shortages, overages, and closing details.',
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
                            const SizedBox(width: 8),
                            _filterChip('This Week'),
                            const SizedBox(width: 8),
                            _filterChip('This Month'),
                            const SizedBox(width: 8),
                            _filterChip('All Time'),
                          ],
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
                          childAspectRatio: count == 4 ? 2.25 : 3.1,
                          children: [
                            _summaryCard(
                              title: 'Open Drawers',
                              value: '$openSessions',
                              icon: Icons.lock_open_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            _summaryCard(
                              title: 'Closed Sessions',
                              value: '$closedSessions',
                              icon: Icons.lock_outline,
                              color: const Color(0xFF159447),
                            ),
                            _summaryCard(
                              title: 'Total Shortage',
                              value: '₱${totalShortage.toStringAsFixed(2)}',
                              icon: Icons.trending_down,
                              color: const Color(0xFFD32F2F),
                            ),
                            _summaryCard(
                              title: 'Total Overage',
                              value: '₱${totalOverage.toStringAsFixed(2)}',
                              icon: Icons.trending_up,
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    _DrawerReportHoverCard(
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
                            final compact = constraints.maxWidth < 650;

                            final salesInfo = Row(
                              children: [
                                const CircleAvatar(
                                  radius: 22,
                                  backgroundColor: Color(0x1F1565C0),
                                  child: Icon(
                                    Icons.payments_outlined,
                                    color: Color(0xFF1565C0),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'RECORDED NET SALES',
                                        style: TextStyle(
                                          color: Color(0xFF7A8494),
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '₱${totalSales.toStringAsFixed(2)}',
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
                                '${sessions.length} SESSION(S)',
                                style: const TextStyle(
                                  color: Color(0xFF168653),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            );

                            if (compact) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  salesInfo,
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
                                Expanded(child: salesInfo),
                                const SizedBox(width: 14),
                                badge,
                              ],
                            );
                          },
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
                                'Cash Drawer Sessions',
                                style: TextStyle(
                                  color: Color(0xFF172033),
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Select a cashier session to view its reconciliation details.',
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
                    const SizedBox(height: 12),
                    if (sessions.isEmpty)
                      const SizedBox(
                        height: 230,
                        child: _DrawerReportEmptyState(),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final document = sessions[index];
                          final data = document.data();

                          final cashier =
                              (data['cashierName'] ??
                                      data['cashierEmail'] ??
                                      'Unknown Cashier')
                                  .toString();

                          final status = (data['status'] ?? 'open').toString();

                          final openingCash =
                              (data['openingCash'] as num?)?.toDouble() ?? 0;

                          final sales =
                              (data['totalSales'] as num?)?.toDouble() ?? 0;

                          final expectedCash =
                              (data['expectedCash'] as num?)?.toDouble() ??
                              openingCash + sales;

                          final countedCash = (data['countedCash'] as num?)
                              ?.toDouble();

                          final variance = (data['variance'] as num?)
                              ?.toDouble();

                          final openedAt = _readDate(data['openedAt']);

                          final closedAt = _readDate(data['closedAt']);

                          final notes = (data['notes'] ?? '').toString();

                          final isOpen = status == 'open';

                          final varianceColor =
                              variance == null || variance == 0
                              ? const Color(0xFF159447)
                              : variance > 0
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFFD32F2F);

                          final varianceLabel = variance == null
                              ? 'Pending'
                              : variance == 0
                              ? 'Balanced'
                              : variance > 0
                              ? 'Overage'
                              : 'Shortage';

                          return _DrawerSessionCard(
                            cashier: cashier,
                            status: status,
                            isOpen: isOpen,
                            openingCash: openingCash,
                            sales: sales,
                            expectedCash: expectedCash,
                            countedCash: countedCash,
                            variance: variance,
                            varianceColor: varianceColor,
                            varianceLabel: varianceLabel,
                            openedAt: _formatDate(openedAt),
                            closedAt: closedAt == null
                                ? 'Still open'
                                : _formatDate(closedAt),
                            notes: notes,
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
