import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _ServiceMonitorHoverCard extends StatefulWidget {
  final Widget child;

  const _ServiceMonitorHoverCard({required this.child});

  @override
  State<_ServiceMonitorHoverCard> createState() =>
      _ServiceMonitorHoverCardState();
}

class _ServiceMonitorHoverCardState extends State<_ServiceMonitorHoverCard> {
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
          borderRadius: BorderRadius.circular(18),
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

class _ServiceStatusPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _ServiceStatusPill({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 7),
          Text(
            '$label: $value',
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

class _ServiceHourCard extends StatefulWidget {
  final String hourLabel;
  final int transactionCount;
  final String averageTime;
  final int normalCount;
  final int minorDelayCount;
  final int longDelayCount;
  final double progress;
  final bool peak;

  const _ServiceHourCard({
    required this.hourLabel,
    required this.transactionCount,
    required this.averageTime,
    required this.normalCount,
    required this.minorDelayCount,
    required this.longDelayCount,
    required this.progress,
    required this.peak,
  });

  @override
  State<_ServiceHourCard> createState() => _ServiceHourCardState();
}

class _ServiceHourCardState extends State<_ServiceHourCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.peak
        ? const Color(0xFF7B1FA2)
        : const Color(0xFF1565C0);

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
            final compact = constraints.maxWidth < 820;

            final title = Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    widget.peak
                        ? Icons.emoji_events_outlined
                        : Icons.schedule_outlined,
                    color: accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.hourLabel,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (widget.peak) ...[
                        const SizedBox(height: 3),
                        Text(
                          'Peak transaction hour',
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
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
                _HourMetricPill(
                  label: 'Transactions',
                  value: '${widget.transactionCount}',
                  color: const Color(0xFF1565C0),
                ),
                _HourMetricPill(
                  label: 'Average Time',
                  value: widget.averageTime,
                  color: const Color(0xFF7B1FA2),
                ),
                _HourMetricPill(
                  label: 'Normal',
                  value: '${widget.normalCount}',
                  color: const Color(0xFF159447),
                ),
                _HourMetricPill(
                  label: 'Minor Delay',
                  value: '${widget.minorDelayCount}',
                  color: const Color(0xFFF59E0B),
                ),
                _HourMetricPill(
                  label: 'Long Delay',
                  value: '${widget.longDelayCount}',
                  color: const Color(0xFFD32F2F),
                ),
              ],
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (compact) ...[
                  title,
                  const SizedBox(height: 12),
                  metrics,
                ] else
                  Row(
                    children: [
                      Expanded(child: title),
                      const SizedBox(width: 14),
                      Flexible(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: metrics,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: widget.progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
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

class _HourMetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HourMetricPill({
    required this.label,
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
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.78),
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

class _ServiceMonitoringEmptyState extends StatelessWidget {
  const _ServiceMonitoringEmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 180;

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
              child: TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 420),
                tween: Tween(begin: 0.92, end: 1),
                curve: Curves.easeOutBack,
                builder: (context, value, child) {
                  return Transform.scale(scale: value, child: child);
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.speed_outlined,
                      size: compact ? 42 : 58,
                      color: const Color(0xFFB8C5D5),
                    ),
                    SizedBox(height: compact ? 6 : 10),
                    Text(
                      'No service monitoring data found',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color(0xFF657386),
                        fontSize: compact ? 14 : 16,
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
          ),
        );
      },
    );
  }
}

class ServiceMonitoringReportScreen extends StatefulWidget {
  const ServiceMonitoringReportScreen({super.key});

  @override
  State<ServiceMonitoringReportScreen> createState() =>
      _ServiceMonitoringReportScreenState();
}

class _ServiceMonitoringReportScreenState
    extends State<ServiceMonitoringReportScreen> {
  String _selectedFilter = 'Today';

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

    switch (_selectedFilter) {
      case 'Today':
        return transactionDate == today;
      case 'Yesterday':
        final yesterday = today.subtract(const Duration(days: 1));
        return transactionDate == yesterday;
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

  String _hourLabel(int hour) {
    final startHour = hour == 0
        ? 12
        : hour > 12
        ? hour - 12
        : hour;

    final end = (hour + 1) % 24;
    final endHour = end == 0
        ? 12
        : end > 12
        ? end - 12
        : end;

    final startPeriod = hour >= 12 ? 'PM' : 'AM';
    final endPeriod = end >= 12 ? 'PM' : 'AM';

    return '$startHour:00 $startPeriod – '
        '$endHour:00 $endPeriod';
  }

  String _formatDuration(double seconds) {
    if (seconds <= 0) return '0s';

    final rounded = seconds.round();
    final minutes = rounded ~/ 60;
    final remaining = rounded % 60;

    if (minutes == 0) {
      return '${remaining}s';
    }

    return '${minutes}m ${remaining}s';
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
    return _ServiceMonitorHoverCard(
      child: Container(
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, color.withValues(alpha: 0.055)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.13)),
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
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
      stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load service monitoring data.\n'
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

              return status != 'voided' &&
                  _matchesFilter(
                    _readDate(
                      data['transactionCompletedAt'] ?? data['createdAt'],
                    ),
                  );
            }).toList();

        final Map<int, _HourPerformance> hourly = {
          for (int hour = 0; hour < 24; hour++)
            hour: _HourPerformance(hour: hour),
        };

        int normalCount = 0;
        int minorDelayCount = 0;
        int longDelayCount = 0;
        int missingDurationCount = 0;
        int totalDurationSeconds = 0;
        int durationRecordCount = 0;

        for (final document in transactions) {
          final data = document.data();

          final completedAt = _readDate(
            data['transactionCompletedAt'] ?? data['createdAt'],
          );

          if (completedAt == null) continue;

          final durationSeconds = (data['transactionDurationSeconds'] as num?)
              ?.toInt();

          final serviceSpeed = (data['serviceSpeed'] ?? '').toString();

          final performance = hourly[completedAt.hour]!;

          performance.transactionCount++;

          if (durationSeconds != null && durationSeconds >= 0) {
            performance.totalDurationSeconds += durationSeconds;
            performance.durationRecordCount++;

            totalDurationSeconds += durationSeconds;
            durationRecordCount++;

            final classification = serviceSpeed.isNotEmpty
                ? serviceSpeed
                : durationSeconds <= 120
                ? 'Normal Service'
                : durationSeconds <= 300
                ? 'Minor Delay'
                : 'Long Delay';

            switch (classification) {
              case 'Minor Delay':
                minorDelayCount++;
                performance.minorDelayCount++;
                break;
              case 'Long Delay':
                longDelayCount++;
                performance.longDelayCount++;
                break;
              default:
                normalCount++;
                performance.normalCount++;
            }
          } else {
            missingDurationCount++;
          }
        }

        final activeHours =
            hourly.values.where((hour) => hour.transactionCount > 0).toList()
              ..sort(
                (a, b) => b.transactionCount.compareTo(a.transactionCount),
              );

        final peakHour = activeHours.isEmpty ? null : activeHours.first;

        final averageDuration = durationRecordCount == 0
            ? 0.0
            : totalDurationSeconds / durationRecordCount;

        return Container(
          color: const Color(0xFFF2F6FC),
          padding: const EdgeInsets.all(22),
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
                    Icon(Icons.speed_outlined, color: Colors.white, size: 29),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Monitoring',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Monitor transaction volume, service time, '
                            'peak hours, and checkout delays.',
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
                      _filterChip('Yesterday'),
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
                        title: 'Transactions',
                        value: '${transactions.length}',
                        icon: Icons.receipt_long_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                      _summaryCard(
                        title: 'Peak Hour',
                        value: peakHour == null
                            ? 'No data'
                            : _hourLabel(peakHour.hour),
                        icon: Icons.schedule_outlined,
                        color: const Color(0xFF7B1FA2),
                      ),
                      _summaryCard(
                        title: 'Average Service Time',
                        value: _formatDuration(averageDuration),
                        icon: Icons.timer_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                      _summaryCard(
                        title: 'Long Delays',
                        value: '$longDelayCount',
                        icon: Icons.warning_amber_outlined,
                        color: const Color(0xFFD32F2F),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _ServiceMonitorHoverCard(
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
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      _ServiceStatusPill(
                        label: 'Normal Service',
                        value: normalCount,
                        color: const Color(0xFF159447),
                        icon: Icons.check_circle_outline,
                      ),
                      _ServiceStatusPill(
                        label: 'Minor Delay',
                        value: minorDelayCount,
                        color: const Color(0xFFF59E0B),
                        icon: Icons.schedule_outlined,
                      ),
                      _ServiceStatusPill(
                        label: 'Long Delay',
                        value: longDelayCount,
                        color: const Color(0xFFD32F2F),
                        icon: Icons.warning_amber_outlined,
                      ),
                      if (missingDurationCount > 0)
                        _ServiceStatusPill(
                          label: 'No Duration Data',
                          value: missingDurationCount,
                          color: const Color(0xFF7A8494),
                          icon: Icons.help_outline,
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Transactions by Hour',
                          style: TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Compare transaction volume and service delays per hour.',
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
              Expanded(
                child: activeHours.isEmpty
                    ? const _ServiceMonitoringEmptyState()
                    : ListView.separated(
                        itemCount: activeHours.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final hour = activeHours[index];

                          final averageHourDuration =
                              hour.durationRecordCount == 0
                              ? 0.0
                              : hour.totalDurationSeconds /
                                    hour.durationRecordCount;

                          final maxTransactions =
                              activeHours.first.transactionCount;

                          final progress = maxTransactions <= 0
                              ? 0.0
                              : hour.transactionCount / maxTransactions;

                          return _ServiceHourCard(
                            hourLabel: _hourLabel(hour.hour),
                            transactionCount: hour.transactionCount,
                            averageTime: _formatDuration(averageHourDuration),
                            normalCount: hour.normalCount,
                            minorDelayCount: hour.minorDelayCount,
                            longDelayCount: hour.longDelayCount,
                            progress: progress,
                            peak: index == 0,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _metric(String label, String value, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _HourPerformance {
  final int hour;

  int transactionCount = 0;
  int normalCount = 0;
  int minorDelayCount = 0;
  int longDelayCount = 0;
  int totalDurationSeconds = 0;
  int durationRecordCount = 0;

  _HourPerformance({required this.hour});

  void addDuration(int seconds) {
    totalDurationSeconds += seconds;
    durationRecordCount++;
  }
}
