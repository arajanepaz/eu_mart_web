// -----------------------------------------------------------------------------
// Module overview: Shows authentication-session history such as login, logout, and session duration information.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Private UI/data helper used only inside this module.
class _LoginActivityHoverCard extends StatefulWidget {
  final Widget child;

  // Records login activity hover card information for monitoring or traceability.
  const _LoginActivityHoverCard({required this.child});

  @override
  State<_LoginActivityHoverCard> createState() =>
      _LoginActivityHoverCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _LoginActivityHoverCardState extends State<_LoginActivityHoverCard> {
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
class _LoginActivityPill extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;

  // Records login activity pill information for monitoring or traceability.
  const _LoginActivityPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Handles the container logic used by this module.
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
          // Handles the sized box logic used by this module.
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

// Private UI/data helper used only inside this module.
class _LoginSessionCard extends StatefulWidget {
  final String name;
  final String email;
  final String role;
  final String loginMethod;
  final bool remembered;
  final String sessionStatus;
  final String loginTime;
  final String logoutTime;
  final String? duration;

  // Records login session card information for monitoring or traceability.
  const _LoginSessionCard({
    required this.name,
    required this.email,
    required this.role,
    required this.loginMethod,
    required this.remembered,
    required this.sessionStatus,
    required this.loginTime,
    required this.logoutTime,
    required this.duration,
  });

  @override
  State<_LoginSessionCard> createState() => _LoginSessionCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _LoginSessionCardState extends State<_LoginSessionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isOwner = widget.role == 'owner';
    final roleColor = isOwner
        ? const Color(0xFF1565C0)
        : const Color(0xFFF59E0B);
    final isClosed = widget.sessionStatus == 'closed';
    final sessionColor = isClosed
        ? const Color(0xFF159447)
        : const Color(0xFF7B1FA2);

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
            colors: [Colors.white, roleColor.withValues(alpha: 0.025)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? roleColor.withValues(alpha: 0.30)
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

            final account = Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: roleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    isOwner
                        ? Icons.admin_panel_settings_outlined
                        : Icons.point_of_sale_outlined,
                    color: roleColor,
                    size: 26,
                  ),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 16.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                  ),
                ),
              ],
            );

            final badges = Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _LoginDetailPill(
                  icon: isOwner
                      ? Icons.admin_panel_settings_outlined
                      : Icons.point_of_sale_outlined,
                  label: widget.role.toUpperCase(),
                  color: roleColor,
                ),
                _LoginDetailPill(
                  icon: widget.loginMethod == 'Saved Session'
                      ? Icons.restore_outlined
                      : Icons.password_outlined,
                  label: widget.loginMethod,
                  color: const Color(0xFF7B1FA2),
                ),
                _LoginDetailPill(
                  icon: widget.remembered
                      ? Icons.devices_outlined
                      : Icons.timer_off_outlined,
                  label: widget.remembered
                      ? 'Remembered Device'
                      : 'Session Only',
                  color: const Color(0xFF00897B),
                ),
              ],
            );

            final times = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                _LoginTimeLine(
                  icon: Icons.login_outlined,
                  label: 'Login',
                  value: widget.loginTime,
                  color: const Color(0xFF1565C0),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(height: 7),
                _LoginTimeLine(
                  icon: isClosed ? Icons.logout_outlined : Icons.circle,
                  label: isClosed ? 'Logout' : 'Status',
                  value: isClosed ? widget.logoutTime : 'Session still active',
                  color: sessionColor,
                ),
                if (widget.duration != null) ...[
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 7),
                  _LoginTimeLine(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: widget.duration!,
                    color: const Color(0xFFF59E0B),
                  ),
                ],
              ],
            );

            if (compact) {
              // Handles the column logic used by this module.
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  account,
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 12),
                  badges,
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: sessionColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: times,
                  ),
                ],
              );
            }

            // Handles the row logic used by this module.
            return Row(
              children: [
                Expanded(flex: 3, child: account),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 14),
                Expanded(flex: 4, child: badges),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 14),
                Expanded(flex: 3, child: times),
              ],
            );
          },
        ),
      ),
    );
  }
}

// Private UI/data helper used only inside this module.
class _LoginDetailPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  // Records login detail pill information for monitoring or traceability.
  const _LoginDetailPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Handles the container logic used by this module.
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
          // Handles the sized box logic used by this module.
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// Private UI/data helper used only inside this module.
class _LoginTimeLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  // Records login time line information for monitoring or traceability.
  const _LoginTimeLine({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Handles the row logic used by this module.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        // Handles the sized box logic used by this module.
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            '$label: $value',
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _LoginActivityEmptyState extends StatelessWidget {
  // Records login activity empty state information for monitoring or traceability.
  const _LoginActivityEmptyState();

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
                    Icons.login_outlined,
                    size: compact ? 42 : 60,
                    color: const Color(0xFFB8C5D5),
                  ),
                  SizedBox(height: compact ? 6 : 11),
                  Text(
                    'No login activity found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF657386),
                      fontSize: compact ? 14 : 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    'Choose another period to review account sessions.',
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

// Screen widget for shows authentication-session history such as login, logout, and session duration information.
class LoginActivityScreen extends StatefulWidget {
  // Records login activity screen information for monitoring or traceability.
  const LoginActivityScreen({super.key});

  @override
  State<LoginActivityScreen> createState() => _LoginActivityScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _LoginActivityScreenState extends State<LoginActivityScreen> {
  String _selectedFilter = 'Today';

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
    final recordDate = DateTime(date.year, date.month, date.day);

    switch (_selectedFilter) {
      case 'Today':
        return recordDate == today;
      case 'This Week':
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6));

        return !recordDate.isBefore(startOfWeek) &&
            !recordDate.isAfter(endOfWeek);
      case 'This Month':
        return recordDate.year == now.year && recordDate.month == now.month;
      case 'All Time':
        return true;
      default:
        return true;
    }
  }

  // Formats a date into a consistent display value for the interface.
  String _formatDate(DateTime? date) {
    if (date == null) return 'Unavailable';

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.month}/${date.day}/${date.year} '
        '$hour:$minute:$second $period';
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
    // Records login activity hover card information for monitoring or traceability.
    return _LoginActivityHoverCard(
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
      stream: FirebaseFirestore.instance
          .collection('login_activity')
          .snapshots(),
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
              'Unable to load login activity.\n'
              '${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final records =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            ).where((document) {
              // Checks whether the current value satisfies the matches filter rule used by this module.
              return _matchesFilter(_readDate(document.data()['createdAt']));
            }).toList();

        records.sort((a, b) {
          final first = _readDate(a.data()['createdAt']);
          final second = _readDate(b.data()['createdAt']);

          if (first == null && second == null) return 0;
          if (first == null) return 1;
          if (second == null) return -1;

          return second.compareTo(first);
        });

        int ownerCount = 0;
        int cashierCount = 0;
        int rememberedCount = 0;
        int closedSessionCount = 0;
        int totalSessionDuration = 0;
        int durationRecordCount = 0;
        final users = <String>{};

        for (final document in records) {
          final data = document.data();

          final role = (data['role'] ?? '').toString();

          final userId = (data['userId'] ?? '').toString();

          final method = (data['loginMethod'] ?? '').toString();

          if (role == 'owner') ownerCount++;
          if (role == 'cashier') cashierCount++;
          if (method == 'saved_session') {
            rememberedCount++;
          }

          final sessionStatus = (data['sessionStatus'] ?? 'active').toString();

          final durationSeconds = (data['sessionDurationSeconds'] as num?)
              ?.toInt();

          if (sessionStatus == 'closed') {
            closedSessionCount++;
          }

          if (durationSeconds != null && durationSeconds >= 0) {
            totalSessionDuration += durationSeconds;
            durationRecordCount++;
          }

          if (userId.isNotEmpty) users.add(userId);
        }

        final averageSessionDuration = durationRecordCount == 0
            ? 0
            : totalSessionDuration ~/ durationRecordCount;

        // Formats session duration into a user-friendly display value.
        String formatSessionDuration(int seconds) {
          final hours = seconds ~/ 3600;
          final minutes = (seconds % 3600) ~/ 60;
          final remaining = seconds % 60;

          if (hours > 0) {
            return '${hours}h ${minutes}m';
          }

          if (minutes > 0) {
            return '${minutes}m ${remaining}s';
          }

          return '${remaining}s';
        }

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
                          Icons.login_outlined,
                          color: Colors.white,
                          size: 29,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Login Activity',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Review account sign-ins, remembered devices, '
                                'and session duration.',
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
                      int count = 5;

                      if (constraints.maxWidth < 1180) {
                        count = 3;
                      }
                      if (constraints.maxWidth < 900) {
                        count = 2;
                      }
                      if (constraints.maxWidth < 520) {
                        count = 1;
                      }

                      const spacing = 13.0;
                      final itemWidth = count == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - (spacing * (count - 1))) /
                                count;

                      // Handles the wrap logic used by this module.
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            height: 104,
                            child: _summaryCard(
                              title: 'Login Records',
                              value: '${records.length}',
                              icon: Icons.login_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            height: 104,
                            child: _summaryCard(
                              title: 'Unique Accounts',
                              value: '${users.length}',
                              icon: Icons.groups_outlined,
                              color: const Color(0xFF7B1FA2),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            height: 104,
                            child: _summaryCard(
                              title: 'Cashier Logins',
                              value: '$cashierCount',
                              icon: Icons.point_of_sale_outlined,
                              color: const Color(0xFFF59E0B),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            height: 104,
                            child: _summaryCard(
                              title: 'Closed Sessions',
                              value: '$closedSessionCount',
                              icon: Icons.logout_outlined,
                              color: const Color(0xFF159447),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            height: 104,
                            child: _summaryCard(
                              title: 'Average Session',
                              value: formatSessionDuration(
                                averageSessionDuration,
                              ),
                              icon: Icons.timer_outlined,
                              color: const Color(0xFF00897B),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  // Handles the sized box logic used by this module.
                  const SizedBox(height: 16),
                  _LoginActivityHoverCard(
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
                          _LoginActivityPill(
                            label: 'Owner Logins',
                            value: ownerCount,
                            icon: Icons.admin_panel_settings_outlined,
                            color: const Color(0xFF1565C0),
                          ),
                          _LoginActivityPill(
                            label: 'Cashier Logins',
                            value: cashierCount,
                            icon: Icons.point_of_sale_outlined,
                            color: const Color(0xFFF59E0B),
                          ),
                          _LoginActivityPill(
                            label: 'Saved Sessions',
                            value: rememberedCount,
                            icon: Icons.devices_outlined,
                            color: const Color(0xFF7B1FA2),
                          ),
                          _LoginActivityPill(
                            label: 'Closed Sessions',
                            value: closedSessionCount,
                            icon: Icons.logout_outlined,
                            color: const Color(0xFF159447),
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
                              'Account Sessions',
                              style: TextStyle(
                                color: Color(0xFF172033),
                                fontSize: 21,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Login method, device memory, and session timestamps.',
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
                  if (records.isEmpty)
                    // Handles the sized box logic used by this module.
                    const SizedBox(
                      height: 220,
                      child: _LoginActivityEmptyState(),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: records.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final data = records[index].data();

                        final email = (data['email'] ?? 'Unknown account')
                            .toString();

                        final name = (data['name'] ?? email).toString();

                        final role = (data['role'] ?? 'unknown').toString();

                        final method = (data['loginMethod'] ?? 'password')
                            .toString();

                        final remembered = data['rememberMe'] == true;

                        final createdAt = _readDate(data['createdAt']);

                        final logoutAt = _readDate(data['logoutAt']);

                        final sessionStatus =
                            (data['sessionStatus'] ?? 'active').toString();

                        final durationSeconds =
                            (data['sessionDurationSeconds'] as num?)?.toInt();

                        // Records login session card information for monitoring or traceability.
                        return _LoginSessionCard(
                          name: name,
                          email: email,
                          role: role,
                          loginMethod: method == 'saved_session'
                              ? 'Saved Session'
                              : 'Email & Password',
                          remembered: remembered,
                          sessionStatus: sessionStatus,
                          loginTime: _formatDate(createdAt),
                          logoutTime: _formatDate(logoutAt),
                          duration: durationSeconds == null
                              ? null
                              : formatSessionDuration(durationSeconds),
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
}
