import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class _ServiceIssueHoverCard extends StatefulWidget {
  final Widget child;

  const _ServiceIssueHoverCard({required this.child});

  @override
  State<_ServiceIssueHoverCard> createState() => _ServiceIssueHoverCardState();
}

class _ServiceIssueHoverCardState extends State<_ServiceIssueHoverCard> {
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

class _ServiceIssueSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _ServiceIssueSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _ServiceIssueHoverCard(
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
}

class _ServiceIssueCard extends StatefulWidget {
  final String type;
  final String severity;
  final String description;
  final String status;
  final String reporter;
  final String resolution;
  final String createdAt;
  final Color severityColor;
  final bool ownerView;
  final bool isResolved;
  final VoidCallback? onResolve;

  const _ServiceIssueCard({
    required this.type,
    required this.severity,
    required this.description,
    required this.status,
    required this.reporter,
    required this.resolution,
    required this.createdAt,
    required this.severityColor,
    required this.ownerView,
    required this.isResolved,
    required this.onResolve,
  });

  @override
  State<_ServiceIssueCard> createState() => _ServiceIssueCardState();
}

class _ServiceIssueCardState extends State<_ServiceIssueCard> {
  bool _hovered = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final statusColor = widget.isResolved
        ? const Color(0xFF159447)
        : const Color(0xFFF59E0B);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white,
              widget.severityColor.withValues(alpha: 0.022),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? widget.severityColor.withValues(alpha: 0.30)
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: widget.severityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        Icons.report_problem_outlined,
                        color: widget.severityColor,
                        size: 26,
                      ),
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
                                  widget.type,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF172033),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.10),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.status.toUpperCase(),
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _ServiceIssuePill(
                                icon: Icons.priority_high_rounded,
                                label: widget.severity,
                                color: widget.severityColor,
                              ),
                              _ServiceIssuePill(
                                icon: Icons.person_outline,
                                label: widget.reporter,
                                color: const Color(0xFF1565C0),
                              ),
                              _ServiceIssuePill(
                                icon: Icons.schedule_outlined,
                                label: widget.createdAt,
                                color: const Color(0xFF7B1FA2),
                              ),
                            ],
                          ),
                          const SizedBox(height: 9),
                          Text(
                            widget.description,
                            maxLines: _expanded ? null : 2,
                            overflow: _expanded
                                ? TextOverflow.visible
                                : TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF607086),
                              height: 1.4,
                            ),
                          ),
                        ],
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
                    if (widget.resolution.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(13),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF8F0),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check_circle_outline,
                              color: Color(0xFF159447),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                'Resolution: '
                                '${widget.resolution}',
                                style: const TextStyle(
                                  color: Color(0xFF168653),
                                  fontWeight: FontWeight.w700,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.ownerView &&
                        !widget.isResolved &&
                        widget.onResolve != null) ...[
                      if (widget.resolution.isNotEmpty)
                        const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: widget.onResolve,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF159447),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text(
                            'RESOLVE ISSUE',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
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

class _ServiceIssuePill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ServiceIssuePill({
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
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceIssueEmptyState extends StatelessWidget {
  const _ServiceIssueEmptyState();

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
              Icons.support_agent_outlined,
              size: 64,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No service issues recorded',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Newly reported issues will appear here.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}

class ServiceIssueLoggingScreen extends StatefulWidget {
  final bool ownerView;

  const ServiceIssueLoggingScreen({super.key, this.ownerView = false});

  @override
  State<ServiceIssueLoggingScreen> createState() =>
      _ServiceIssueLoggingScreenState();
}

class _ServiceIssueLoggingScreenState extends State<ServiceIssueLoggingScreen> {
  final _descriptionController = TextEditingController();

  String _issueType = 'Barcode Not Recognized';
  String _severity = 'Minor';
  bool _saving = false;

  static const _issueTypes = [
    'Barcode Not Recognized',
    'Product Not Found',
    'Price Mismatch',
    'Scanner Unavailable',
    'Slow System',
    'Customer Delay',
    'Other',
  ];

  static const _severityLevels = ['Minor', 'Moderate', 'Major'];

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
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

  Future<void> _saveIssue() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _showMessage('No authenticated user.', Colors.red);
      return;
    }

    final description = _descriptionController.text.trim();

    if (description.isEmpty) {
      _showMessage('Enter a short description of the issue.', Colors.orange);
      return;
    }

    setState(() => _saving = true);

    try {
      await FirebaseFirestore.instance.collection('service_issues').add({
        'issueType': _issueType,
        'severity': _severity,
        'description': description,
        'status': 'open',
        'resolution': '',
        'reportedById': user.uid,
        'reportedByEmail': user.email ?? '',
        'reportedByName': user.displayName ?? user.email ?? 'User',
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
        'resolvedById': '',
        'resolvedByEmail': '',
      });

      _descriptionController.clear();

      if (!mounted) return;

      _showMessage('Service issue recorded.', Colors.green);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        error.code == 'permission-denied'
            ? 'Permission denied. Add the service_issues Firestore rule.'
            : 'Unable to save issue: '
                  '${error.message ?? error.code}',
        Colors.red,
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _resolveIssue(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final resolutionController = TextEditingController();

    final resolution = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Resolve Service Issue'),
          content: SizedBox(
            width: 480,
            child: TextField(
              controller: resolutionController,
              maxLines: 4,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Resolution or action taken',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, resolutionController.text.trim());
              },
              child: const Text('RESOLVE'),
            ),
          ],
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));
    resolutionController.dispose();

    if (resolution == null || resolution.isEmpty) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await document.reference.update({
        'status': 'resolved',
        'resolution': resolution,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolvedById': user.uid,
        'resolvedByEmail': user.email ?? '',
      });

      if (!mounted) return;

      _showMessage('Issue marked as resolved.', Colors.green);
    } on FirebaseException catch (error) {
      if (!mounted) return;

      _showMessage(
        'Unable to resolve issue: '
        '${error.message ?? error.code}',
        Colors.red,
      );
    }
  }

  void _showMessage(String text, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  Widget _buildIssueForm() {
    return _ServiceIssueHoverCard(
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, Color(0xFFFBFDFF)],
          ),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0xFFE1E9F3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.report_problem_outlined,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Log a Service Issue',
                        style: TextStyle(
                          color: Color(0xFF172033),
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Record issues that may delay customer service.',
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
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _issueType,
              decoration: _issueInputDecoration(
                label: 'Issue Type',
                icon: Icons.category_outlined,
              ),
              items: _issueTypes
                  .map(
                    (type) => DropdownMenuItem(value: type, child: Text(type)),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _issueType = value;
                      });
                    },
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: _issueInputDecoration(
                label: 'Severity',
                icon: Icons.priority_high_rounded,
              ),
              items: _severityLevels
                  .map(
                    (level) =>
                        DropdownMenuItem(value: level, child: Text(level)),
                  )
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _severity = value;
                      });
                    },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _descriptionController,
              enabled: !_saving,
              minLines: 3,
              maxLines: 4,
              decoration: _issueInputDecoration(
                label: 'Description',
                icon: Icons.notes_rounded,
                hint:
                    'Describe what happened and how it affected the transaction.',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _severityColor(_severity).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: _severityColor(_severity),
                    size: 19,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Current severity: $_severity',
                      style: TextStyle(
                        color: _severityColor(_severity),
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveIssue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF9DB7D4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.report_problem_outlined),
                label: Text(
                  _saving ? 'SAVING...' : 'LOG SERVICE ISSUE',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _issueInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      filled: true,
      fillColor: const Color(0xFFF7FAFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(
        child: Text(
          'No authenticated user.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    final query = widget.ownerView
        ? FirebaseFirestore.instance.collection('service_issues')
        : FirebaseFirestore.instance
              .collection('service_issues')
              .where('reportedById', isEqualTo: user.uid);

    return Container(
      color: const Color(0xFFF2F6FC),
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
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
            child: Row(
              children: [
                const Icon(
                  Icons.support_agent_outlined,
                  color: Colors.white,
                  size: 29,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.ownerView
                            ? 'Service Issue Monitoring'
                            : 'My Service Issues',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.ownerView
                            ? 'Review reported issues, monitor severity, and record resolutions.'
                            : 'Log service problems and review their resolution status.',
                        style: const TextStyle(
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
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load service issues.\n'
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
                    );

                issues.sort((a, b) {
                  final first = _readDate(a.data()['createdAt']);
                  final second = _readDate(b.data()['createdAt']);

                  if (first == null && second == null) {
                    return 0;
                  }
                  if (first == null) return 1;
                  if (second == null) return -1;

                  return second.compareTo(first);
                });

                final openCount = issues.where((issue) {
                  return (issue.data()['status'] ?? 'open').toString() ==
                      'open';
                }).length;

                final resolvedCount = issues.length - openCount;

                final majorCount = issues.where((issue) {
                  return (issue.data()['severity'] ?? '').toString() == 'Major';
                }).length;

                final moderateCount = issues.where((issue) {
                  return (issue.data()['severity'] ?? '').toString() ==
                      'Moderate';
                }).length;

                final content = Column(
                  children: [
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
                            _ServiceIssueSummaryCard(
                              title: 'Open Issues',
                              value: '$openCount',
                              icon: Icons.pending_actions_outlined,
                              color: const Color(0xFFF59E0B),
                            ),
                            _ServiceIssueSummaryCard(
                              title: 'Resolved Issues',
                              value: '$resolvedCount',
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF159447),
                            ),
                            _ServiceIssueSummaryCard(
                              title: 'Major',
                              value: '$majorCount',
                              icon: Icons.report_problem_outlined,
                              color: const Color(0xFFD32F2F),
                            ),
                            _ServiceIssueSummaryCard(
                              title: 'Moderate',
                              value: '$moderateCount',
                              icon: Icons.priority_high_rounded,
                              color: const Color(0xFF7B1FA2),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: issues.isEmpty
                          ? const _ServiceIssueEmptyState()
                          : ListView.separated(
                              itemCount: issues.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final document = issues[index];

                                final data = document.data();

                                final type =
                                    (data['issueType'] ?? 'Service Issue')
                                        .toString();

                                final severity = (data['severity'] ?? 'Minor')
                                    .toString();

                                final description = (data['description'] ?? '')
                                    .toString();

                                final status = (data['status'] ?? 'open')
                                    .toString();

                                final reporter =
                                    (data['reportedByName'] ??
                                            data['reportedByEmail'] ??
                                            'Unknown User')
                                        .toString();

                                final resolution = (data['resolution'] ?? '')
                                    .toString();

                                final createdAt = _readDate(data['createdAt']);

                                final isResolved = status == 'resolved';

                                return _ServiceIssueCard(
                                  type: type,
                                  severity: severity,
                                  description: description,
                                  status: status,
                                  reporter: reporter,
                                  resolution: resolution,
                                  createdAt: _formatDate(createdAt),
                                  severityColor: _severityColor(severity),
                                  ownerView: widget.ownerView,
                                  isResolved: isResolved,
                                  onResolve: widget.ownerView && !isResolved
                                      ? () => _resolveIssue(document)
                                      : null,
                                );
                              },
                            ),
                    ),
                  ],
                );

                if (widget.ownerView) {
                  return content;
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 930;

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: 390,
                            child: SingleChildScrollView(
                              physics: const ClampingScrollPhysics(),
                              padding: const EdgeInsets.only(
                                right: 2,
                                bottom: 12,
                              ),
                              child: _buildIssueForm(),
                            ),
                          ),
                          const SizedBox(width: 18),
                          Expanded(child: content),
                        ],
                      );
                    }

                    return SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          _buildIssueForm(),
                          const SizedBox(height: 16),
                          SizedBox(height: 520, child: content),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }
}
