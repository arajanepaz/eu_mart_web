import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AuditTrailScreen extends StatefulWidget {
  const AuditTrailScreen({super.key});

  @override
  State<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends State<AuditTrailScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedModule = 'All';

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value);
    }
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year} • '
        '$hour:$minute $period';
  }

  IconData _iconForAction(String action) {
    final normalized = action.toLowerCase();

    if (normalized.contains('create') ||
        normalized.contains('add') ||
        normalized.contains('import')) {
      return Icons.add_circle_outline_rounded;
    }

    if (normalized.contains('update') ||
        normalized.contains('edit') ||
        normalized.contains('renew')) {
      return Icons.edit_outlined;
    }

    if (normalized.contains('disable')) {
      return Icons.person_off_outlined;
    }

    if (normalized.contains('enable')) {
      return Icons.person_add_alt_1_outlined;
    }

    if (normalized.contains('void') || normalized.contains('delete')) {
      return Icons.block_rounded;
    }

    if (normalized.contains('restore') || normalized.contains('backup')) {
      return Icons.restore_rounded;
    }

    if (normalized.contains('login')) {
      return Icons.login_rounded;
    }

    return Icons.history_rounded;
  }

  Color _colorForAction(String action) {
    final normalized = action.toLowerCase();

    if (normalized.contains('create') ||
        normalized.contains('add') ||
        normalized.contains('enable') ||
        normalized.contains('import')) {
      return const Color(0xFF159447);
    }

    if (normalized.contains('disable') ||
        normalized.contains('void') ||
        normalized.contains('delete')) {
      return const Color(0xFFD32F2F);
    }

    if (normalized.contains('update') ||
        normalized.contains('edit') ||
        normalized.contains('renew')) {
      return const Color(0xFFF59E0B);
    }

    if (normalized.contains('restore') || normalized.contains('backup')) {
      return const Color(0xFF7B1FA2);
    }

    return const Color(0xFF1565C0);
  }

  Widget _summaryCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 480),
      tween: Tween(begin: 0.92, end: 1),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: _AuditHoverCard(
        child: Container(
          padding: const EdgeInsets.all(16),
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
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: color, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Color(0xFF7A8494),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('audit_logs')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load audit logs.\n'
              '${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final documents =
            List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              snapshot.data?.docs ??
                  <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            );

        final modules = <String>{'All'};

        for (final document in documents) {
          final module = (document.data()['module'] ?? '').toString().trim();

          if (module.isNotEmpty) {
            modules.add(module);
          }
        }

        final filtered = documents.where((document) {
          final data = document.data();

          final action = (data['action'] ?? '').toString().toLowerCase();
          final module = (data['module'] ?? '').toString().toLowerCase();
          final description = (data['description'] ?? '')
              .toString()
              .toLowerCase();
          final email = (data['performedByEmail'] ?? '')
              .toString()
              .toLowerCase();
          final target = (data['targetName'] ?? '').toString().toLowerCase();

          final matchesSearch =
              _searchQuery.isEmpty ||
              action.contains(_searchQuery) ||
              module.contains(_searchQuery) ||
              description.contains(_searchQuery) ||
              email.contains(_searchQuery) ||
              target.contains(_searchQuery);

          final matchesModule =
              _selectedModule == 'All' ||
              (data['module'] ?? '').toString() == _selectedModule;

          return matchesSearch && matchesModule;
        }).toList();

        final today = DateTime.now();
        final todayCount = documents.where((document) {
          final date = _readDate(document.data()['createdAt']);

          if (date == null) return false;

          return date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
        }).length;

        final uniqueUsers = documents
            .map(
              (document) =>
                  (document.data()['performedByEmail'] ?? '').toString().trim(),
            )
            .where((email) => email.isNotEmpty)
            .toSet()
            .length;

        final moduleCount = modules.where((module) => module != 'All').length;

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
                      Icons.admin_panel_settings_outlined,
                      color: Colors.white,
                      size: 28,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audit Trail',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track important system actions, '
                            'users, modules, and activity dates.',
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final count = constraints.maxWidth >= 900 ? 4 : 2;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: count,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: count == 4 ? 2.45 : 2.8,
                    children: [
                      _summaryCard(
                        label: 'Total Logs',
                        value: '${documents.length}',
                        icon: Icons.history_rounded,
                        color: const Color(0xFF1565C0),
                      ),
                      _summaryCard(
                        label: 'Today',
                        value: '$todayCount',
                        icon: Icons.today_outlined,
                        color: const Color(0xFF159447),
                      ),
                      _summaryCard(
                        label: 'Active Users',
                        value: '$uniqueUsers',
                        icon: Icons.group_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                      _summaryCard(
                        label: 'Modules',
                        value: '$moduleCount',
                        icon: Icons.dashboard_customize_outlined,
                        color: const Color(0xFF7B1FA2),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;

                  final searchField = TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search action, user, target, or description',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF1565C0),
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
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
                        borderSide: const BorderSide(
                          color: Color(0xFF1565C0),
                          width: 2,
                        ),
                      ),
                    ),
                  );

                  final moduleFilter = DropdownButtonFormField<String>(
                    value: _selectedModule,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Module',
                      prefixIcon: const Icon(
                        Icons.filter_alt_outlined,
                        color: Color(0xFF1565C0),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    items: modules
                        .map(
                          (module) => DropdownMenuItem<String>(
                            value: module,
                            child: Text(
                              module,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setState(() {
                        _selectedModule = value;
                      });
                    },
                  );

                  if (compact) {
                    return Column(
                      children: [
                        searchField,
                        const SizedBox(height: 12),
                        moduleFilter,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: searchField),
                      const SizedBox(width: 14),
                      SizedBox(width: 230, child: moduleFilter),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const _AuditEmptyState()
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 11),
                        itemBuilder: (context, index) {
                          final data = filtered[index].data();

                          final action = (data['action'] ?? 'Unknown Action')
                              .toString();
                          final module = (data['module'] ?? 'General')
                              .toString();
                          final description = (data['description'] ?? '')
                              .toString();
                          final email =
                              (data['performedByEmail'] ?? 'Unknown User')
                                  .toString();
                          final target = (data['targetName'] ?? '').toString();
                          final date = _readDate(data['createdAt']);

                          final color = _colorForAction(action);

                          return _AuditLogCard(
                            color: color,
                            icon: _iconForAction(action),
                            action: action,
                            module: module,
                            description: description,
                            email: email,
                            target: target,
                            formattedDate: _formatDate(date),
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class _AuditHoverCard extends StatefulWidget {
  final Widget child;

  const _AuditHoverCard({required this.child});

  @override
  State<_AuditHoverCard> createState() => _AuditHoverCardState();
}

class _AuditHoverCardState extends State<_AuditHoverCard> {
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

class _AuditLogCard extends StatefulWidget {
  final Color color;
  final IconData icon;
  final String action;
  final String module;
  final String description;
  final String email;
  final String target;
  final String formattedDate;

  const _AuditLogCard({
    required this.color,
    required this.icon,
    required this.action,
    required this.module,
    required this.description,
    required this.email,
    required this.target,
    required this.formattedDate,
  });

  @override
  State<_AuditLogCard> createState() => _AuditLogCardState();
}

class _AuditLogCardState extends State<_AuditLogCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(17),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: widget.color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.action,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: widget.color.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.module,
                          style: TextStyle(
                            color: widget.color,
                            fontWeight: FontWeight.w800,
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.description.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      widget.description,
                      style: const TextStyle(
                        color: Color(0xFF536274),
                        height: 1.35,
                      ),
                    ),
                  ],
                  if (widget.target.isNotEmpty) ...[
                    const SizedBox(height: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F6FA),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Text(
                        'Target: ${widget.target}',
                        style: const TextStyle(
                          color: Color(0xFF677486),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 12,
                    runSpacing: 5,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.account_circle_outlined,
                            size: 15,
                            color: Color(0xFF8A95A4),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.email,
                            style: const TextStyle(
                              color: Color(0xFF8A95A4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 15,
                            color: Color(0xFF8A95A4),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.formattedDate,
                            style: const TextStyle(
                              color: Color(0xFF8A95A4),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuditEmptyState extends StatelessWidget {
  const _AuditEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 500),
        tween: Tween(begin: 0.88, end: 1),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          return Transform.scale(scale: value, child: child);
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_toggle_off_rounded,
              size: 62,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No audit logs found',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try another search or module filter.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}
