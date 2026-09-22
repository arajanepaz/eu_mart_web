import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class _PermitHoverCard extends StatefulWidget {
  final Widget child;

  const _PermitHoverCard({required this.child});

  @override
  State<_PermitHoverCard> createState() => _PermitHoverCardState();
}

class _PermitHoverCardState extends State<_PermitHoverCard> {
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

class _PermitSummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _PermitSummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return _PermitHoverCard(
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

class _PermitCard extends StatefulWidget {
  final String name;
  final String permitNumber;
  final String issuingOffice;
  final String notes;
  final String expirationDate;
  final String remainingText;
  final int reminderDays;
  final String status;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PermitCard({
    required this.name,
    required this.permitNumber,
    required this.issuingOffice,
    required this.notes,
    required this.expirationDate,
    required this.remainingText,
    required this.reminderDays,
    required this.status,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_PermitCard> createState() => _PermitCardState();
}

class _PermitCardState extends State<_PermitCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(18),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 760;

            final mainInfo = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    color: widget.color,
                    size: 27,
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
                              widget.status,
                              style: TextStyle(
                                color: widget.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 9,
                        runSpacing: 8,
                        children: [
                          if (widget.permitNumber.isNotEmpty)
                            _PermitInfoPill(
                              icon: Icons.confirmation_number_outlined,
                              label: widget.permitNumber,
                              color: const Color(0xFF1565C0),
                            ),
                          if (widget.issuingOffice.isNotEmpty)
                            _PermitInfoPill(
                              icon: Icons.account_balance_outlined,
                              label: widget.issuingOffice,
                              color: const Color(0xFF7B1FA2),
                            ),
                          _PermitInfoPill(
                            icon: Icons.notifications_active_outlined,
                            label: '${widget.reminderDays} day reminder',
                            color: const Color(0xFFF59E0B),
                          ),
                        ],
                      ),
                      if (widget.notes.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          widget.notes,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF607086),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final deadline = Container(
              constraints: const BoxConstraints(minWidth: 190),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: compact
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  const Text(
                    'EXPIRATION DATE',
                    style: TextStyle(
                      color: Color(0xFF8A95A4),
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.expirationDate,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.remainingText,
                    style: TextStyle(
                      color: widget.color,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            );

            final actions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Edit permit',
                  onPressed: widget.onEdit,
                  icon: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xFF1565C0),
                  ),
                ),
                IconButton(
                  tooltip: 'Delete permit',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  mainInfo,
                  const SizedBox(height: 14),
                  deadline,
                  const SizedBox(height: 8),
                  Align(alignment: Alignment.centerRight, child: actions),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mainInfo),
                const SizedBox(width: 16),
                deadline,
                const SizedBox(width: 8),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PermitInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _PermitInfoPill({
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
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermitEmptyState extends StatelessWidget {
  const _PermitEmptyState();

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
              Icons.description_outlined,
              size: 64,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No permit reminders added',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Add a permit to start tracking its renewal date.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}

class PermitRenewalReminderScreen extends StatefulWidget {
  const PermitRenewalReminderScreen({super.key});

  @override
  State<PermitRenewalReminderScreen> createState() =>
      _PermitRenewalReminderScreenState();
}

class _PermitRenewalReminderScreenState
    extends State<PermitRenewalReminderScreen> {
  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';

    final months = const [
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

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  int _daysUntil(DateTime? expirationDate) {
    if (expirationDate == null) return 999999;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(
      expirationDate.year,
      expirationDate.month,
      expirationDate.day,
    );

    return expiration.difference(today).inDays;
  }

  String _statusLabel({
    required DateTime? expirationDate,
    required int reminderDays,
    required bool renewed,
  }) {
    if (renewed) return 'RENEWED';

    final days = _daysUntil(expirationDate);

    if (days < 0) return 'EXPIRED';
    if (days == 0) return 'EXPIRES TODAY';
    if (days <= reminderDays) return 'DUE SOON';
    return 'ACTIVE';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'EXPIRED':
      case 'EXPIRES TODAY':
        return Colors.red;
      case 'DUE SOON':
        return Colors.orange;
      case 'RENEWED':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  Future<void> _showPermitDialog({
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final data = document?.data() ?? <String, dynamic>{};

    final formKey = GlobalKey<FormState>();

    final permitNameController = TextEditingController(
      text: (data['permitName'] ?? '').toString(),
    );

    final permitNumberController = TextEditingController(
      text: (data['permitNumber'] ?? '').toString(),
    );

    final issuingOfficeController = TextEditingController(
      text: (data['issuingOffice'] ?? '').toString(),
    );

    final reminderDaysController = TextEditingController(
      text: ((data['reminderDays'] as num?)?.toInt() ?? 30).toString(),
    );

    final notesController = TextEditingController(
      text: (data['notes'] ?? '').toString(),
    );

    DateTime? expirationDate = _readDate(data['expirationDate']);

    bool renewed = data['renewed'] == true;
    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> savePermit() async {
              if (!formKey.currentState!.validate()) return;

              if (expirationDate == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Select the permit expiration date.'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                final permitData = <String, dynamic>{
                  'permitName': permitNameController.text.trim(),
                  'permitNumber': permitNumberController.text.trim(),
                  'issuingOffice': issuingOfficeController.text.trim(),
                  'expirationDate': Timestamp.fromDate(expirationDate!),
                  'reminderDays': int.parse(reminderDaysController.text.trim()),
                  'notes': notesController.text.trim(),
                  'renewed': renewed,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                final permitName = permitNameController.text.trim();

                if (document == null) {
                  permitData['createdAt'] = FieldValue.serverTimestamp();

                  final createdDocument = await FirebaseFirestore.instance
                      .collection('permit_reminders')
                      .add(permitData);

                  await AuditLogService.permitChanged(
                    action: 'Create Permit Reminder',
                    permitId: createdDocument.id,
                    permitName: permitName,
                  );
                } else {
                  final wasRenewed = data['renewed'] == true;

                  await document.reference.update(permitData);

                  final action = !wasRenewed && renewed
                      ? 'Mark Permit Renewed'
                      : 'Update Permit Reminder';

                  await AuditLogService.permitChanged(
                    action: action,
                    permitId: document.id,
                    permitName: permitName,
                  );
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } on FirebaseException catch (error) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      error.code == 'permission-denied'
                          ? 'Permission denied. Add the permit_reminders Firestore rule.'
                          : 'Unable to save permit: ${error.message ?? error.code}',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );

                setDialogState(() => saving = false);
              }
            }

            return AlertDialog(
              title: Text(
                document == null
                    ? 'Add Permit Reminder'
                    : 'Edit Permit Reminder',
              ),
              content: SizedBox(
                width: 650,
                child: Form(
                  key: formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: permitNameController,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: 'Permit Name',
                            hintText: 'Example: Business Permit',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Permit name is required.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: permitNumberController,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: 'Permit Number (optional)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: issuingOfficeController,
                          enabled: !saving,
                          decoration: const InputDecoration(
                            labelText: 'Issuing Office (optional)',
                            hintText: 'Example: Municipal Hall',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: saving
                                    ? null
                                    : () async {
                                        final selected = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              expirationDate ??
                                              DateTime.now().add(
                                                const Duration(days: 30),
                                              ),
                                          firstDate: DateTime.now().subtract(
                                            const Duration(days: 3650),
                                          ),
                                          lastDate: DateTime.now().add(
                                            const Duration(days: 3650),
                                          ),
                                        );

                                        if (selected != null) {
                                          setDialogState(() {
                                            expirationDate = selected;
                                          });
                                        }
                                      },
                                icon: const Icon(Icons.event_outlined),
                                label: Text(
                                  expirationDate == null
                                      ? 'Select Expiration Date'
                                      : 'Expiration: ${_formatDate(expirationDate)}',
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            SizedBox(
                              width: 190,
                              child: TextFormField(
                                controller: reminderDaysController,
                                enabled: !saving,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Reminder Days',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  final parsed = int.tryParse(
                                    value?.trim() ?? '',
                                  );

                                  if (parsed == null || parsed < 1) {
                                    return 'Enter at least 1.';
                                  }

                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: notesController,
                          enabled: !saving,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes (optional)',
                            hintText: 'Renewal requirements or instructions',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SwitchListTile(
                          value: renewed,
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Marked as Renewed'),
                          subtitle: const Text(
                            'Turn this on after the permit has been renewed.',
                          ),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    renewed = value;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : savePermit,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'Saving...' : 'Save Permit'),
                ),
              ],
            );
          },
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 250));

    permitNameController.dispose();
    permitNumberController.dispose();
    issuingOfficeController.dispose();
    reminderDaysController.dispose();
    notesController.dispose();

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Permit reminder saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deletePermit(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();
    final name = (data['permitName'] ?? 'this permit').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Permit Reminder'),
          content: Text('Delete the reminder for "$name"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final permitId = document.id;

    await document.reference.delete();

    await AuditLogService.permitChanged(
      action: 'Delete Permit Reminder',
      permitId: permitId,
      permitName: name,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Permit reminder deleted.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('permit_reminders')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load permit reminders.\n'
              '${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final permits = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );

        permits.sort((a, b) {
          final first = _readDate(a.data()['expirationDate']);
          final second = _readDate(b.data()['expirationDate']);

          if (first == null && second == null) {
            return 0;
          }
          if (first == null) return 1;
          if (second == null) return -1;

          return first.compareTo(second);
        });

        int activeCount = 0;
        int dueSoonCount = 0;
        int expiredCount = 0;
        int renewedCount = 0;

        for (final document in permits) {
          final data = document.data();

          final status = _statusLabel(
            expirationDate: _readDate(data['expirationDate']),
            reminderDays: (data['reminderDays'] as num?)?.toInt() ?? 30,
            renewed: data['renewed'] == true,
          );

          switch (status) {
            case 'RENEWED':
              renewedCount++;
              break;
            case 'EXPIRED':
            case 'EXPIRES TODAY':
              expiredCount++;
              break;
            case 'DUE SOON':
              dueSoonCount++;
              break;
            default:
              activeCount++;
          }
        }

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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 680;

                    final title = const Row(
                      children: [
                        Icon(
                          Icons.description_outlined,
                          color: Colors.white,
                          size: 29,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Permit Renewal Reminders',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Monitor expiration dates and renew permits '
                                'before they affect store operations.',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );

                    final button = SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () => _showPermitDialog(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1565C0),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'ADD PERMIT',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [title, const SizedBox(height: 14), button],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: title),
                        const SizedBox(width: 16),
                        button,
                      ],
                    );
                  },
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
                      _PermitSummaryCard(
                        title: 'Active',
                        value: '$activeCount',
                        icon: Icons.verified_outlined,
                        color: const Color(0xFF159447),
                      ),
                      _PermitSummaryCard(
                        title: 'Due Soon',
                        value: '$dueSoonCount',
                        icon: Icons.schedule_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                      _PermitSummaryCard(
                        title: 'Expired',
                        value: '$expiredCount',
                        icon: Icons.warning_amber_outlined,
                        color: const Color(0xFFD32F2F),
                      ),
                      _PermitSummaryCard(
                        title: 'Renewed',
                        value: '$renewedCount',
                        icon: Icons.autorenew,
                        color: const Color(0xFF1565C0),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: permits.isEmpty
                    ? const _PermitEmptyState()
                    : ListView.separated(
                        itemCount: permits.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final document = permits[index];
                          final data = document.data();

                          final name = (data['permitName'] ?? 'Unnamed Permit')
                              .toString();

                          final permitNumber = (data['permitNumber'] ?? '')
                              .toString();

                          final issuingOffice = (data['issuingOffice'] ?? '')
                              .toString();

                          final expirationDate = _readDate(
                            data['expirationDate'],
                          );

                          final reminderDays =
                              (data['reminderDays'] as num?)?.toInt() ?? 30;

                          final notes = (data['notes'] ?? '').toString();

                          final renewed = data['renewed'] == true;

                          final days = _daysUntil(expirationDate);

                          final status = _statusLabel(
                            expirationDate: expirationDate,
                            reminderDays: reminderDays,
                            renewed: renewed,
                          );

                          final color = _statusColor(status);

                          return _PermitCard(
                            name: name,
                            permitNumber: permitNumber,
                            issuingOffice: issuingOffice,
                            notes: notes,
                            expirationDate: _formatDate(expirationDate),
                            remainingText: renewed
                                ? 'Renewed'
                                : days < 0
                                ? '${days.abs()} day(s) overdue'
                                : '$days day(s) remaining',
                            reminderDays: reminderDays,
                            status: status,
                            color: color,
                            onEdit: () => _showPermitDialog(document: document),
                            onDelete: () => _deletePermit(document),
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
