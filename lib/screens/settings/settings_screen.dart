import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class _SettingsHoverCard extends StatefulWidget {
  final Widget child;

  const _SettingsHoverCard({required this.child});

  @override
  State<_SettingsHoverCard> createState() => _SettingsHoverCardState();
}

class _SettingsHoverCardState extends State<_SettingsHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x2016385A)
                  : const Color(0x1016385A),
              blurRadius: _hovered ? 18 : 10,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: widget.child,
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SettingsToggleTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final accent = value ? const Color(0xFF1565C0) : const Color(0xFF8A95A4);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: value
              ? const [Color(0xFFEAF3FF), Color(0xFFF7FBFF)]
              : const [Color(0xFFF7F9FC), Color(0xFFFBFCFD)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? const Color(0xFFC9DFF7) : const Color(0xFFE4EAF1),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.11),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: accent, size: 21),
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
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF7D8998),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: value ? const Color(0xFFEAF8F0) : const Color(0xFFF1F3F5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value ? 'ON' : 'OFF',
              style: TextStyle(
                color: value
                    ? const Color(0xFF168653)
                    : const Color(0xFF7A8494),
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _storeNameController = TextEditingController();
  final _storeAddressController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _lowStockThresholdController = TextEditingController();
  final _expirationAlertDaysController = TextEditingController();
  final _receiptFooterController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _enableLowStockAlerts = true;
  bool _enableExpirationAlerts = true;

  Map<String, dynamic> _originalSettings = <String, dynamic>{};

  DocumentReference<Map<String, dynamic>> get _settingsRef =>
      FirebaseFirestore.instance.collection('settings').doc('system');

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final snapshot = await _settingsRef.get();
      final data = snapshot.data() ?? <String, dynamic>{};

      _originalSettings = Map<String, dynamic>.from(data);

      _storeNameController.text = (data['storeName'] ?? 'EÜ MART').toString();

      _storeAddressController.text = (data['storeAddress'] ?? '').toString();

      _contactNumberController.text = (data['contactNumber'] ?? '').toString();

      _lowStockThresholdController.text =
          ((data['lowStockThreshold'] as num?)?.toInt() ?? 10).toString();

      _expirationAlertDaysController.text =
          ((data['expirationAlertDays'] as num?)?.toInt() ?? 30).toString();

      _receiptFooterController.text =
          (data['receiptFooter'] ?? 'Thank you for shopping at EÜ MART!')
              .toString();

      _enableLowStockAlerts = data['enableLowStockAlerts'] != false;

      _enableExpirationAlerts = data['enableExpirationAlerts'] != false;
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to load settings: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Map<String, dynamic> _currentSettings() {
    return {
      'storeName': _storeNameController.text.trim(),
      'storeAddress': _storeAddressController.text.trim(),
      'contactNumber': _contactNumberController.text.trim(),
      'lowStockThreshold': int.parse(_lowStockThresholdController.text.trim()),
      'expirationAlertDays': int.parse(
        _expirationAlertDaysController.text.trim(),
      ),
      'receiptFooter': _receiptFooterController.text.trim(),
      'enableLowStockAlerts': _enableLowStockAlerts,
      'enableExpirationAlerts': _enableExpirationAlerts,
    };
  }

  Map<String, dynamic> _changedValues(Map<String, dynamic> updated) {
    final changes = <String, dynamic>{};

    for (final entry in updated.entries) {
      final oldValue = _originalSettings[entry.key];

      if (oldValue != entry.value) {
        changes[entry.key] = {'oldValue': oldValue, 'newValue': entry.value};
      }
    }

    return changes;
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final updated = _currentSettings();
      final changes = _changedValues(updated);

      if (changes.isEmpty) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No settings changes detected.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      await _settingsRef.set({
        ...updated,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await AuditLogService.log(
        action: 'Update Settings',
        module: 'Settings',
        description: 'Updated ${changes.length} system setting(s).',
        targetId: 'system',
        targetName: 'System Settings',
        details: changes,
      );

      _originalSettings = {..._originalSettings, ...updated};

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to save settings: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required.';
    }

    return null;
  }

  String? _positiveIntegerValidator(String? value) {
    final parsed = int.tryParse(value?.trim() ?? '');

    if (parsed == null || parsed < 0) {
      return 'Enter a valid whole number.';
    }

    return null;
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        color: Color(0xFF718096),
        fontWeight: FontWeight.w700,
      ),
      filled: true,
      fillColor: const Color(0xFFF7FAFE),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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

  Widget _section({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    final accent = switch (title) {
      'Store Information' => const Color(0xFF1565C0),
      'Inventory Alerts' => const Color(0xFFF59E0B),
      'Receipt Settings' => const Color(0xFF7B1FA2),
      _ => const Color(0xFF1565C0),
    };

    return _SettingsHoverCard(
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: accent.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    accent.withValues(alpha: 0.14),
                    accent.withValues(alpha: 0.035),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(21),
                  topRight: Radius.circular(21),
                ),
                border: Border(left: BorderSide(color: accent, width: 6)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [accent, accent.withValues(alpha: 0.72)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.24),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Color(0xFF172033),
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: Color(0xFF7D8998),
                            fontSize: 12,
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
                      color: accent.withValues(alpha: 0.11),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'SETTINGS',
                      style: TextStyle(
                        color: accent,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Container(
      color: const Color(0xFFF2F6FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1050),
            child: Form(
              key: _formKey,
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
                          Icons.settings_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'System Settings',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Configure store details, '
                                'inventory alerts, and receipt settings.',
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
                  const SizedBox(height: 18),
                  _section(
                    title: 'Store Information',
                    subtitle:
                        'Basic store details used in reports and receipts.',
                    icon: Icons.store_outlined,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 700;

                          final nameField = TextFormField(
                            controller: _storeNameController,
                            enabled: !_saving,
                            validator: _requiredValidator,
                            decoration: _decoration(
                              label: 'Store Name',
                              icon: Icons.store,
                            ),
                          );

                          final contactField = TextFormField(
                            controller: _contactNumberController,
                            enabled: !_saving,
                            decoration: _decoration(
                              label: 'Contact Number',
                              icon: Icons.phone_outlined,
                            ),
                          );

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: nameField),
                                const SizedBox(width: 16),
                                Expanded(child: contactField),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              nameField,
                              const SizedBox(height: 16),
                              contactField,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _storeAddressController,
                        enabled: !_saving,
                        maxLines: 2,
                        decoration: _decoration(
                          label: 'Store Address',
                          icon: Icons.location_on_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _section(
                    title: 'Inventory Alerts',
                    subtitle:
                        'Configure low-stock and expiration notifications.',
                    icon: Icons.notifications_active_outlined,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 700;

                          final lowStock = TextFormField(
                            controller: _lowStockThresholdController,
                            enabled: !_saving,
                            keyboardType: TextInputType.number,
                            validator: _positiveIntegerValidator,
                            decoration: _decoration(
                              label: 'Low-Stock Threshold',
                              icon: Icons.inventory_2_outlined,
                              suffixText: 'units',
                            ),
                          );

                          final expiration = TextFormField(
                            controller: _expirationAlertDaysController,
                            enabled: !_saving,
                            keyboardType: TextInputType.number,
                            validator: _positiveIntegerValidator,
                            decoration: _decoration(
                              label: 'Expiration Alert Period',
                              icon: Icons.event_outlined,
                              suffixText: 'days',
                            ),
                          );

                          if (isWide) {
                            return Row(
                              children: [
                                Expanded(child: lowStock),
                                const SizedBox(width: 16),
                                Expanded(child: expiration),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              lowStock,
                              const SizedBox(height: 16),
                              expiration,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 14),
                      _SettingsToggleTile(
                        title: 'Enable low-stock alerts',
                        subtitle:
                            'Show alerts when a product reaches the threshold.',
                        icon: Icons.warning_amber_rounded,
                        value: _enableLowStockAlerts,
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  _enableLowStockAlerts = value;
                                });
                              },
                      ),
                      const SizedBox(height: 10),
                      _SettingsToggleTile(
                        title: 'Enable expiration alerts',
                        subtitle:
                            'Show alerts for products nearing expiration.',
                        icon: Icons.event_busy_outlined,
                        value: _enableExpirationAlerts,
                        onChanged: _saving
                            ? null
                            : (value) {
                                setState(() {
                                  _enableExpirationAlerts = value;
                                });
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  _section(
                    title: 'Receipt Settings',
                    subtitle: 'Customize the message shown on receipts.',
                    icon: Icons.receipt_long_outlined,
                    children: [
                      TextFormField(
                        controller: _receiptFooterController,
                        enabled: !_saving,
                        maxLines: 3,
                        validator: _requiredValidator,
                        decoration: _decoration(
                          label: 'Receipt Footer Message',
                          icon: Icons.message_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF3FF), Color(0xFFF7FAFF)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFD7E7FA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: Color(0xFF1565C0),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Changes are saved to Firestore '
                            'and recorded in the Audit Trail.',
                            style: TextStyle(
                              color: Color(0xFF53657C),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: _saving ? null : _saveSettings,
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
                                    width: 19,
                                    height: 19,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.save_rounded),
                            label: Text(
                              _saving ? 'SAVING...' : 'SAVE SETTINGS',
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _storeAddressController.dispose();
    _contactNumberController.dispose();
    _lowStockThresholdController.dispose();
    _expirationAlertDaysController.dispose();
    _receiptFooterController.dispose();
    super.dispose();
  }
}
