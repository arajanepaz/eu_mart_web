import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../firebase_options.dart';
import '../../services/audit_log_service.dart';

class _CashierSummaryCard extends StatefulWidget {
  final Widget child;

  const _CashierSummaryCard({required this.child});

  @override
  State<_CashierSummaryCard> createState() => _CashierSummaryCardState();
}

class _CashierSummaryCardState extends State<_CashierSummaryCard> {
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

class _CashierAccountCard extends StatefulWidget {
  final String name;
  final String email;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onReset;
  final VoidCallback onStatus;

  const _CashierAccountCard({
    required this.name,
    required this.email,
    required this.isActive,
    required this.onEdit,
    required this.onReset,
    required this.onStatus,
  });

  @override
  State<_CashierAccountCard> createState() => _CashierAccountCardState();
}

class _CashierAccountCardState extends State<_CashierAccountCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.isActive
        ? const Color(0xFF1565C0)
        : const Color(0xFFD32F2F);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, accent.withValues(alpha: 0.025)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _hovered
                ? accent.withValues(alpha: 0.28)
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
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                widget.isActive
                    ? Icons.person_rounded
                    : Icons.person_off_rounded,
                color: accent,
                size: 27,
              ),
            ),
            const SizedBox(width: 14),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.email_outlined,
                        size: 15,
                        color: Color(0xFF8A95A4),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          widget.email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF7A8494),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                widget.isActive ? 'ACTIVE' : 'DISABLED',
                style: TextStyle(
                  color: accent,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              tooltip: 'Cashier actions',
              onSelected: (action) {
                if (action == 'edit') {
                  widget.onEdit();
                } else if (action == 'reset') {
                  widget.onReset();
                } else if (action == 'status') {
                  widget.onStatus();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Edit Name'),
                  ),
                ),
                const PopupMenuItem(
                  value: 'reset',
                  child: ListTile(
                    leading: Icon(Icons.password_outlined),
                    title: Text('Send Password Reset'),
                  ),
                ),
                PopupMenuItem(
                  value: 'status',
                  child: ListTile(
                    leading: Icon(
                      widget.isActive
                          ? Icons.person_off_outlined
                          : Icons.person_add_alt,
                    ),
                    title: Text(
                      widget.isActive ? 'Disable Account' : 'Enable Account',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CashierEmptyState extends StatelessWidget {
  const _CashierEmptyState();

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
              Icons.person_search_outlined,
              size: 62,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No cashier accounts found',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try another search or create a cashier.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}

class ManageCashiersScreen extends StatefulWidget {
  const ManageCashiersScreen({super.key});

  @override
  State<ManageCashiersScreen> createState() => _ManageCashiersScreenState();
}

class _ManageCashiersScreenState extends State<ManageCashiersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  Future<void> _showCreateCashierDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

    bool obscurePassword = true;
    bool creating = false;

    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> createCashier() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => creating = true);

              FirebaseApp? secondaryApp;

              try {
                final appName =
                    'cashierCreator-${DateTime.now().millisecondsSinceEpoch}';

                secondaryApp = await Firebase.initializeApp(
                  name: appName,
                  options: DefaultFirebaseOptions.currentPlatform,
                );

                final secondaryAuth = FirebaseAuth.instanceFor(
                  app: secondaryApp,
                );

                final credential = await secondaryAuth
                    .createUserWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text,
                    );

                final createdUser = credential.user;

                if (createdUser == null) {
                  throw Exception('Unable to create cashier account.');
                }

                await createdUser.updateDisplayName(nameController.text.trim());

                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(createdUser.uid)
                    .set({
                      'name': nameController.text.trim(),
                      'email': emailController.text.trim().toLowerCase(),
                      'role': 'cashier',
                      'isActive': true,
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                      'createdById':
                          FirebaseAuth.instance.currentUser?.uid ?? '',
                    });

                await AuditLogService.log(
                  action: 'CREATE CASHIER',
                  module: 'Cashier Management',
                  description:
                      'Created cashier account ${emailController.text.trim()}.',
                  targetId: createdUser.uid,
                  targetName: nameController.text.trim(),
                );

                await secondaryAuth.signOut();

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } on FirebaseAuthException catch (error) {
                if (!dialogContext.mounted) return;

                String message = error.message ?? 'Unable to create cashier.';

                if (error.code == 'email-already-in-use') {
                  message = 'This email is already registered.';
                } else if (error.code == 'invalid-email') {
                  message = 'Enter a valid email address.';
                } else if (error.code == 'weak-password') {
                  message = 'Password must contain at least 6 characters.';
                }

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(content: Text(message), backgroundColor: Colors.red),
                );

                setDialogState(() => creating = false);
              } catch (error) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text(
                      error.toString().replaceFirst('Exception: ', ''),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );

                setDialogState(() => creating = false);
              } finally {
                if (secondaryApp != null) {
                  try {
                    await secondaryApp.delete();
                  } catch (_) {
                    // Ignore cleanup errors after account creation.
                  }
                }
              }
            }

            return AlertDialog(
              title: const Text('Create Cashier Account'),
              content: SizedBox(
                width: 500,
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: nameController,
                        enabled: !creating,
                        decoration: const InputDecoration(
                          labelText: 'Cashier Name',
                          prefixIcon: Icon(Icons.person_outline),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Enter the cashier name.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        enabled: !creating,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty || !email.contains('@')) {
                            return 'Enter a valid email address.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: passwordController,
                        enabled: !creating,
                        obscureText: obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Temporary Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: creating
                                ? null
                                : () {
                                    setDialogState(() {
                                      obscurePassword = !obscurePassword;
                                    });
                                  },
                            icon: Icon(
                              obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                          ),
                          border: const OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if ((value ?? '').length < 6) {
                            return 'Use at least 6 characters.';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: creating
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: creating ? null : createCashier,
                  icon: creating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.person_add),
                  label: Text(creating ? 'CREATING...' : 'CREATE CASHIER'),
                ),
              ],
            );
          },
        );
      },
    );

    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cashier account created successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _setCashierStatus({
    required DocumentSnapshot<Map<String, dynamic>> document,
    required bool isActive,
  }) async {
    try {
      await document.reference.update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final data = document.data() ?? <String, dynamic>{};

      await AuditLogService.log(
        action: isActive ? 'ENABLE CASHIER' : 'DISABLE CASHIER',
        module: 'Cashier Management',
        description: isActive
            ? 'Enabled cashier account.'
            : 'Disabled cashier account.',
        targetId: document.id,
        targetName: (data['name'] ?? data['email'] ?? 'Cashier').toString(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isActive ? 'Cashier account enabled.' : 'Cashier account disabled.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to update cashier: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendPasswordReset(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.message ?? 'Unable to send reset email.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _editCashier(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data() ?? <String, dynamic>{};
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(
      text: (data['name'] ?? '').toString(),
    );

    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> save() async {
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => saving = true);

              try {
                await document.reference.update({
                  'name': nameController.text.trim(),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                await AuditLogService.log(
                  action: 'EDIT CASHIER',
                  module: 'Cashier Management',
                  description: 'Updated cashier display name.',
                  targetId: document.id,
                  targetName: nameController.text.trim(),
                );

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (error) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Unable to update cashier: $error'),
                    backgroundColor: Colors.red,
                  ),
                );

                setDialogState(() => saving = false);
              }
            }

            return AlertDialog(
              title: const Text('Edit Cashier'),
              content: SizedBox(
                width: 420,
                child: Form(
                  key: formKey,
                  child: TextFormField(
                    controller: nameController,
                    enabled: !saving,
                    decoration: const InputDecoration(
                      labelText: 'Cashier Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter the cashier name.';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving ? null : save,
                  child: Text(saving ? 'Saving...' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cashier information updated.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final name = (data['name'] ?? '').toString().toLowerCase();
    final email = (data['email'] ?? '').toString().toLowerCase();

    return name.contains(_searchQuery) || email.contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'cashier')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load cashier accounts.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final cashiers = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );

        cashiers.sort((a, b) {
          final first = (a.data()['name'] ?? '').toString().toLowerCase();
          final second = (b.data()['name'] ?? '').toString().toLowerCase();

          return first.compareTo(second);
        });

        final filtered = cashiers
            .where((document) => _matchesSearch(document.data()))
            .toList();

        final activeCount = cashiers
            .where((document) => document.data()['isActive'] == true)
            .length;

        final disabledCount = cashiers.length - activeCount;

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
                    final compact = constraints.maxWidth < 700;

                    final heading = const Row(
                      children: [
                        Icon(
                          Icons.groups_2_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Cashiers',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Create and manage authorized '
                                'cashier accounts.',
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

                    final action = ElevatedButton.icon(
                      onPressed: _showCreateCashierDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF1565C0),
                        elevation: 0,
                        minimumSize: const Size(170, 46),
                      ),
                      icon: const Icon(Icons.person_add_alt_1),
                      label: const Text(
                        'CREATE CASHIER',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    );

                    if (compact) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [heading, const SizedBox(height: 16), action],
                      );
                    }

                    return Row(
                      children: [
                        Expanded(child: heading),
                        const SizedBox(width: 16),
                        action,
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  int count = 3;

                  if (constraints.maxWidth < 850) {
                    count = 1;
                  }

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: count,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    childAspectRatio: count == 3 ? 2.3 : 4.1,
                    children: [
                      _summaryCard(
                        title: 'Total Cashiers',
                        value: '${cashiers.length}',
                        icon: Icons.groups_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                      _summaryCard(
                        title: 'Active Accounts',
                        value: '$activeCount',
                        icon: Icons.verified_user_outlined,
                        color: const Color(0xFF159447),
                      ),
                      _summaryCard(
                        title: 'Disabled Accounts',
                        value: '$disabledCount',
                        icon: Icons.person_off_outlined,
                        color: const Color(0xFFD32F2F),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.trim().toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search cashier name or email',
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
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const _CashierEmptyState()
                    : ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 11),
                        itemBuilder: (context, index) {
                          final document = filtered[index];
                          final data = document.data();

                          final name = (data['name'] ?? 'Unnamed Cashier')
                              .toString();
                          final email = (data['email'] ?? '').toString();
                          final isActive = data['isActive'] == true;

                          return _CashierAccountCard(
                            name: name,
                            email: email,
                            isActive: isActive,
                            onEdit: () => _editCashier(document),
                            onReset: () => _sendPasswordReset(email),
                            onStatus: () => _setCashierStatus(
                              document: document,
                              isActive: !isActive,
                            ),
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

  Widget _summaryCard({
    required String title,
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
      child: _CashierSummaryCard(
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
                        fontSize: 22,
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
