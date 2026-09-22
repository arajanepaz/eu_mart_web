import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ServiceIssueSummaryScreen extends StatefulWidget {
  const ServiceIssueSummaryScreen({super.key});

  @override
  State<ServiceIssueSummaryScreen> createState() =>
      _ServiceIssueSummaryScreenState();
}

class _ServiceIssueSummaryScreenState extends State<ServiceIssueSummaryScreen> {
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
    final issueDate = DateTime(date.year, date.month, date.day);

    switch (_selectedFilter) {
      case 'Today':
        return issueDate == today;
      case 'This Week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        return !issueDate.isBefore(startOfWeek) &&
            !issueDate.isAfter(endOfWeek);
      case 'This Month':
        return issueDate.year == now.year && issueDate.month == now.month;
      case 'All Time':
        return true;
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

  Color _severityColor(String severity) {
    switch (severity) {
      case 'Major':
        return Colors.red;
      case 'Moderate':
        return Colors.orange;
      default:
        return Colors.blue;
    }
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
    return _IssueSummaryHoverCard(
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
          .collection('service_issues')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load service issue summary.\n'
              '${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final issues =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            ).where((document) {
              return _matchesFilter(_readDate(document.data()['createdAt']));
            }).toList();

        issues.sort((a, b) {
          final first = _readDate(a.data()['createdAt']);
          final second = _readDate(b.data()['createdAt']);

          if (first == null && second == null) return 0;
          if (first == null) return 1;
          if (second == null) return -1;

          return second.compareTo(first);
        });

        int openCount = 0;
        int resolvedCount = 0;
        int majorCount = 0;
        int moderateCount = 0;
        int minorCount = 0;

        final Map<String, int> issueTypeCounts = {};
        final Map<String, int> reporterCounts = {};

        for (final document in issues) {
          final data = document.data();

          final status = (data['status'] ?? 'open').toString();

          final severity = (data['severity'] ?? 'Minor').toString();

          final type = (data['issueType'] ?? 'Other').toString();

          final reporter =
              (data['reportedByName'] ??
                      data['reportedByEmail'] ??
                      'Unknown User')
                  .toString();

          if (status == 'resolved') {
            resolvedCount++;
          } else {
            openCount++;
          }

          switch (severity) {
            case 'Major':
              majorCount++;
              break;
            case 'Moderate':
              moderateCount++;
              break;
            default:
              minorCount++;
          }

          issueTypeCounts[type] = (issueTypeCounts[type] ?? 0) + 1;

          reporterCounts[reporter] = (reporterCounts[reporter] ?? 0) + 1;
        }

        final sortedIssueTypes = issueTypeCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final sortedReporters = reporterCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        final topIssue = sortedIssueTypes.isEmpty
            ? 'No data'
            : sortedIssueTypes.first.key;

        final resolutionRate = issues.isEmpty
            ? 0.0
            : (resolvedCount / issues.length) * 100;

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
                    Icon(
                      Icons.assessment_outlined,
                      color: Colors.white,
                      size: 29,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Issue Summary',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Review recurring issues, severity levels, '
                            'reporters, and resolution performance.',
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
                        title: 'Total Issues',
                        value: '${issues.length}',
                        icon: Icons.report_problem_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                      _summaryCard(
                        title: 'Open Issues',
                        value: '$openCount',
                        icon: Icons.pending_actions_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                      _summaryCard(
                        title: 'Resolution Rate',
                        value: '${resolutionRate.toStringAsFixed(1)}%',
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF159447),
                      ),
                      _summaryCard(
                        title: 'Top Recurring Issue',
                        value: topIssue,
                        icon: Icons.repeat_outlined,
                        color: const Color(0xFF7B1FA2),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              _IssueSummaryHoverCard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
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
                      _IssueCountPill(
                        label: 'Major',
                        value: majorCount,
                        icon: Icons.report_problem_outlined,
                        color: const Color(0xFFD32F2F),
                      ),
                      _IssueCountPill(
                        label: 'Moderate',
                        value: moderateCount,
                        icon: Icons.priority_high_rounded,
                        color: const Color(0xFFF59E0B),
                      ),
                      _IssueCountPill(
                        label: 'Minor',
                        value: minorCount,
                        icon: Icons.info_outline,
                        color: const Color(0xFF1565C0),
                      ),
                      _IssueCountPill(
                        label: 'Resolved',
                        value: resolvedCount,
                        icon: Icons.check_circle_outline,
                        color: const Color(0xFF159447),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 900) {
                      return ListView(
                        padding: const EdgeInsets.only(bottom: 8),
                        children: [
                          SizedBox(
                            height: 300,
                            child: _IssueTypePanel(entries: sortedIssueTypes),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 280,
                            child: _ReporterPanel(entries: sortedReporters),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 390,
                            child: _RecentIssuesPanel(
                              issues: issues.take(10).toList(),
                              formatDate: _formatDate,
                              severityColor: _severityColor,
                            ),
                          ),
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 3,
                          child: _IssueTypePanel(entries: sortedIssueTypes),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: _ReporterPanel(entries: sortedReporters),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 4,
                          child: _RecentIssuesPanel(
                            issues: issues.take(10).toList(),
                            formatDate: _formatDate,
                            severityColor: _severityColor,
                          ),
                        ),
                      ],
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
}

class _IssueSummaryHoverCard extends StatefulWidget {
  final Widget child;

  const _IssueSummaryHoverCard({required this.child});

  @override
  State<_IssueSummaryHoverCard> createState() => _IssueSummaryHoverCardState();
}

class _IssueSummaryHoverCardState extends State<_IssueSummaryHoverCard> {
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

class _IssueCountPill extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  const _IssueCountPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
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

class _IssueTypePanel extends StatelessWidget {
  final List<MapEntry<String, int>> entries;

  const _IssueTypePanel({required this.entries});

  @override
  Widget build(BuildContext context) {
    final maximum = entries.isEmpty ? 1 : entries.first.value;

    return _IssuePanelContainer(
      title: 'Issues by Type',
      subtitle: 'Recurring service concerns in the selected period.',
      icon: Icons.category_outlined,
      accent: const Color(0xFF1565C0),
      child: entries.isEmpty
          ? const _IssuePanelEmpty(message: 'No issue data.')
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final entry = entries[index];
                final progress = entry.value / maximum;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key,
                            style: const TextStyle(
                              color: Color(0xFF344255),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEAF3FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF1565C0),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }
}

class _ReporterPanel extends StatelessWidget {
  final List<MapEntry<String, int>> entries;

  const _ReporterPanel({required this.entries});

  @override
  Widget build(BuildContext context) {
    return _IssuePanelContainer(
      title: 'Reported by Cashier',
      subtitle: 'Cashiers who logged service issues.',
      icon: Icons.people_outline,
      accent: const Color(0xFF7B1FA2),
      child: entries.isEmpty
          ? const _IssuePanelEmpty(message: 'No reporter data.')
          : ListView.separated(
              itemCount: entries.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final entry = entries[index];

                return Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 19,
                        backgroundColor: Color(0xFFEDE7F6),
                        child: Icon(
                          Icons.person_outline,
                          size: 20,
                          color: Color(0xFF7B1FA2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.key,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF344255),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDE7F6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${entry.value}',
                          style: const TextStyle(
                            color: Color(0xFF7B1FA2),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _RecentIssuesPanel extends StatelessWidget {
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> issues;
  final String Function(DateTime?) formatDate;
  final Color Function(String) severityColor;

  const _RecentIssuesPanel({
    required this.issues,
    required this.formatDate,
    required this.severityColor,
  });

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return _IssuePanelContainer(
      title: 'Recent Service Issues',
      subtitle: 'Latest issues recorded in the selected period.',
      icon: Icons.history_outlined,
      accent: const Color(0xFFF59E0B),
      child: issues.isEmpty
          ? const _IssuePanelEmpty(message: 'No recent issues.')
          : ListView.separated(
              itemCount: issues.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final data = issues[index].data();

                final type = (data['issueType'] ?? 'Other').toString();

                final severity = (data['severity'] ?? 'Minor').toString();

                final status = (data['status'] ?? 'open').toString();

                final reporter =
                    (data['reportedByName'] ??
                            data['reportedByEmail'] ??
                            'Unknown User')
                        .toString();

                final severityAccent = severityColor(severity);

                final statusColor = status == 'resolved'
                    ? const Color(0xFF159447)
                    : const Color(0xFFF59E0B);

                return _IssueSummaryHoverCard(
                  child: Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white,
                          severityAccent.withValues(alpha: 0.025),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE1E9F3)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 43,
                          height: 43,
                          decoration: BoxDecoration(
                            color: severityAccent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.report_problem_outlined,
                            color: severityAccent,
                            size: 21,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                type,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF172033),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$reporter • '
                                '${formatDate(_readDate(data['createdAt']))}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF8A95A4),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _IssuePanelContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  const _IssuePanelContainer({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return _IssueSummaryHoverCard(
      child: Container(
        constraints: const BoxConstraints(minHeight: 210),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, accent.withValues(alpha: 0.025)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: accent.withValues(alpha: 0.13)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [accent, accent.withValues(alpha: 0.72)],
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 17,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8A95A4),
                          fontSize: 10.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(child: ClipRect(child: child)),
          ],
        ),
      ),
    );
  }
}

class _IssuePanelEmpty extends StatelessWidget {
  final String message;

  const _IssuePanelEmpty({required this.message});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 120;

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            vertical: compact ? 2 : 8,
            horizontal: 8,
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
                    Icons.inbox_outlined,
                    size: compact ? 30 : 42,
                    color: const Color(0xFFB8C5D5),
                  ),
                  SizedBox(height: compact ? 4 : 7),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF7D8998),
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w700,
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
