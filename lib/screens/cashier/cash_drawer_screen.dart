import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class _CashDrawerHoverCard extends StatefulWidget {
  final Widget child;

  const _CashDrawerHoverCard({required this.child});

  @override
  State<_CashDrawerHoverCard> createState() => _CashDrawerHoverCardState();
}

class _CashDrawerHoverCardState extends State<_CashDrawerHoverCard> {
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
          borderRadius: BorderRadius.circular(22),
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

class _CashDrawerIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _CashDrawerIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _CashDrawerTip extends StatelessWidget {
  final String text;

  const _CashDrawerTip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.check_circle_outline,
          size: 19,
          color: Color(0xFF159447),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF607086),
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class CashDrawerScreen extends StatefulWidget {
  const CashDrawerScreen({super.key});

  @override
  State<CashDrawerScreen> createState() => _CashDrawerScreenState();
}

class _CashDrawerScreenState extends State<CashDrawerScreen> {
  final _openingController = TextEditingController();
  final _countedController = TextEditingController();
  final _notesController = TextEditingController();

  bool _processing = false;

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDateTime(DateTime? date) {
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

  Future<void> _openDrawer() async {
    final user = FirebaseAuth.instance.currentUser;
    final openingCash = double.tryParse(_openingController.text.trim());

    if (user == null) {
      _message('No authenticated cashier.', Colors.red);
      return;
    }

    if (openingCash == null || openingCash < 0) {
      _message('Enter a valid opening cash amount.', Colors.red);
      return;
    }

    setState(() => _processing = true);

    try {
      final activeSession = await FirebaseFirestore.instance
          .collection('cash_sessions')
          .where('cashierId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (activeSession.docs.isNotEmpty) {
        _message(
          'You already have an open cash drawer session.',
          Colors.orange,
        );
        return;
      }

      await FirebaseFirestore.instance.collection('cash_sessions').add({
        'cashierId': user.uid,
        'cashierEmail': user.email ?? '',
        'openingCash': openingCash,
        'status': 'open',
        'openedAt': FieldValue.serverTimestamp(),
        'closedAt': null,
        'totalSales': 0.0,
        'expectedCash': openingCash,
        'countedCash': null,
        'variance': null,
        'notes': '',
      });

      _openingController.clear();

      _message('Cash drawer opened successfully.', Colors.green);
    } catch (error) {
      _message('Unable to open cash drawer: $error', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Future<void> _closeDrawer(
    QueryDocumentSnapshot<Map<String, dynamic>> session,
    double totalSales,
  ) async {
    final countedCash = double.tryParse(_countedController.text.trim());

    if (countedCash == null || countedCash < 0) {
      _message('Enter a valid counted cash amount.', Colors.red);
      return;
    }

    final data = session.data();
    final openingCash = (data['openingCash'] as num?)?.toDouble() ?? 0;

    final expectedCash = openingCash + totalSales;
    final variance = countedCash - expectedCash;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Close Cash Drawer'),
          content: SizedBox(
            width: 460,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dialogRow(
                  'Opening Cash',
                  '₱${openingCash.toStringAsFixed(2)}',
                ),
                _dialogRow('Net Sales', '₱${totalSales.toStringAsFixed(2)}'),
                _dialogRow(
                  'Expected Cash',
                  '₱${expectedCash.toStringAsFixed(2)}',
                ),
                _dialogRow(
                  'Counted Cash',
                  '₱${countedCash.toStringAsFixed(2)}',
                ),
                const Divider(),
                _dialogRow(
                  variance == 0
                      ? 'Variance'
                      : variance > 0
                      ? 'Overage'
                      : 'Shortage',
                  '₱${variance.abs().toStringAsFixed(2)}',
                  color: variance == 0
                      ? Colors.green
                      : variance > 0
                      ? Colors.orange
                      : Colors.red,
                ),
                const SizedBox(height: 14),
                const Text('Closing the drawer ends the current cash session.'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('CLOSE DRAWER'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _processing = true);

    try {
      await session.reference.update({
        'status': 'closed',
        'closedAt': FieldValue.serverTimestamp(),
        'totalSales': totalSales,
        'expectedCash': expectedCash,
        'countedCash': countedCash,
        'variance': variance,
        'notes': _notesController.text.trim(),
      });

      _countedController.clear();
      _notesController.clear();

      _message(
        variance == 0
            ? 'Drawer closed. Cash is balanced.'
            : variance > 0
            ? 'Drawer closed with ₱${variance.toStringAsFixed(2)} overage.'
            : 'Drawer closed with ₱${variance.abs().toStringAsFixed(2)} shortage.',
        variance == 0 ? Colors.green : Colors.orange,
      );
    } catch (error) {
      _message('Unable to close cash drawer: $error', Colors.red);
    } finally {
      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  Widget _dialogRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
        ],
      ),
    );
  }

  void _message(String text, Color color) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(text), backgroundColor: color));
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _CashDrawerHoverCard(
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

  InputDecoration _drawerInputDecoration({
    required String label,
    required IconData icon,
    String? hint,
    String? prefixText,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefixText,
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
          'No authenticated cashier.',
          style: TextStyle(color: Colors.red),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('cash_sessions')
          .where('cashierId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, sessionSnapshot) {
        if (sessionSnapshot.connectionState == ConnectionState.waiting &&
            !sessionSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final sessions = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          sessionSnapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );

        QueryDocumentSnapshot<Map<String, dynamic>>? activeSession;

        for (final session in sessions) {
          if ((session.data()['status'] ?? '').toString() == 'open') {
            activeSession = session;
            break;
          }
        }

        if (activeSession == null) {
          return _buildOpenDrawerView();
        }

        final sessionData = activeSession.data();
        final openedAt = _readDate(sessionData['openedAt']);
        final openingCash =
            (sessionData['openingCash'] as num?)?.toDouble() ?? 0;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('transactions')
              .where('processedById', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, transactionSnapshot) {
            double totalSales = 0;
            int transactions = 0;

            for (final document
                in transactionSnapshot.data?.docs ??
                    <QueryDocumentSnapshot<Map<String, dynamic>>>[]) {
              final data = document.data();

              final status = (data['status'] ?? 'completed')
                  .toString()
                  .toLowerCase();

              final createdAt = _readDate(data['createdAt']);

              if (status != 'completed' ||
                  openedAt == null ||
                  createdAt == null ||
                  createdAt.isBefore(openedAt)) {
                continue;
              }

              totalSales += (data['total'] as num?)?.toDouble() ?? 0;
              transactions++;
            }

            final expectedCash = openingCash + totalSales;

            return Container(
              color: const Color(0xFFF2F6FC),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
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
                          child: Row(
                            children: [
                              const Icon(
                                Icons.account_balance_wallet_outlined,
                                color: Colors.white,
                                size: 29,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Cash Drawer Reconciliation',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 23,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Drawer opened '
                                      '${_formatDateTime(openedAt)}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 11,
                                  vertical: 7,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0x2AFFFFFF),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 10,
                                      color: Color(0xFF8CF0B6),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'DRAWER OPEN',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
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
                                  title: 'Opening Cash',
                                  value: '₱${openingCash.toStringAsFixed(2)}',
                                  icon: Icons.lock_open_outlined,
                                  color: const Color(0xFF1565C0),
                                ),
                                _summaryCard(
                                  title: 'Net Sales',
                                  value: '₱${totalSales.toStringAsFixed(2)}',
                                  icon: Icons.payments_outlined,
                                  color: const Color(0xFF159447),
                                ),
                                _summaryCard(
                                  title: 'Transactions',
                                  value: '$transactions',
                                  icon: Icons.receipt_long_outlined,
                                  color: const Color(0xFF7B1FA2),
                                ),
                                _summaryCard(
                                  title: 'Expected Cash',
                                  value: '₱${expectedCash.toStringAsFixed(2)}',
                                  icon: Icons.account_balance_wallet_outlined,
                                  color: const Color(0xFFF59E0B),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final wide = constraints.maxWidth >= 820;

                            final guide = _CashDrawerHoverCard(
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFEAF3FF),
                                      Color(0xFFF8FBFF),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFD7E7FA),
                                  ),
                                ),
                                child: const Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _CashDrawerIconBox(
                                      icon: Icons.info_outline,
                                      color: Color(0xFF1565C0),
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      'Before Closing',
                                      style: TextStyle(
                                        color: Color(0xFF172033),
                                        fontSize: 19,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    _CashDrawerTip(
                                      text:
                                          'Count all cash currently inside the drawer.',
                                    ),
                                    SizedBox(height: 10),
                                    _CashDrawerTip(
                                      text:
                                          'Enter the actual amount, including the opening cash.',
                                    ),
                                    SizedBox(height: 10),
                                    _CashDrawerTip(
                                      text:
                                          'Add a note when there is an overage or shortage.',
                                    ),
                                  ],
                                ),
                              ),
                            );

                            final closeForm = _CashDrawerHoverCard(
                              child: Container(
                                padding: const EdgeInsets.all(22),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Colors.white, Color(0xFFFBFDFF)],
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: const Color(0xFFE1E9F3),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    const Row(
                                      children: [
                                        _CashDrawerIconBox(
                                          icon: Icons.lock_outline,
                                          color: Color(0xFFD32F2F),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Close Drawer',
                                                style: TextStyle(
                                                  color: Color(0xFF172033),
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              SizedBox(height: 3),
                                              Text(
                                                'Enter the actual cash count to calculate variance.',
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
                                    TextField(
                                      controller: _countedController,
                                      enabled: !_processing,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: _drawerInputDecoration(
                                        label: 'Actual Counted Cash',
                                        icon: Icons.payments_outlined,
                                        prefixText: '₱ ',
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    TextField(
                                      controller: _notesController,
                                      enabled: !_processing,
                                      minLines: 2,
                                      maxLines: 3,
                                      decoration: _drawerInputDecoration(
                                        label: 'Notes (optional)',
                                        icon: Icons.notes_outlined,
                                        hint: 'Reason for shortage or overage',
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                      height: 50,
                                      child: ElevatedButton.icon(
                                        onPressed: _processing
                                            ? null
                                            : () => _closeDrawer(
                                                activeSession!,
                                                totalSales,
                                              ),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFFD32F2F,
                                          ),
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor: const Color(
                                            0xFFE59A9A,
                                          ),
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                        ),
                                        icon: _processing
                                            ? const SizedBox(
                                                width: 18,
                                                height: 18,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                      color: Colors.white,
                                                    ),
                                              )
                                            : const Icon(Icons.lock_outline),
                                        label: Text(
                                          _processing
                                              ? 'PROCESSING...'
                                              : 'CLOSE DRAWER',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            if (wide) {
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(flex: 2, child: guide),
                                  const SizedBox(width: 16),
                                  Expanded(flex: 3, child: closeForm),
                                ],
                              );
                            }

                            return Column(
                              children: [
                                guide,
                                const SizedBox(height: 16),
                                closeForm,
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
          },
        );
      },
    );
  }

  Widget _buildOpenDrawerView() {
    return Container(
      color: const Color(0xFFF2F6FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
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
                              'Cash Drawer',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 23,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Open the cashier drawer before processing transactions.',
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
                LayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.maxWidth >= 760;

                    final guidance = _CashDrawerHoverCard(
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFEAF3FF), Color(0xFFF8FBFF)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFD7E7FA)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _CashDrawerIconBox(
                              icon: Icons.shield_outlined,
                              color: Color(0xFF1565C0),
                            ),
                            SizedBox(height: 15),
                            Text(
                              'Starting a Cash Session',
                              style: TextStyle(
                                color: Color(0xFF172033),
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 10),
                            _CashDrawerTip(
                              text:
                                  'Count the starting cash before the first transaction.',
                            ),
                            SizedBox(height: 10),
                            _CashDrawerTip(
                              text:
                                  'The opening amount is included in expected cash.',
                            ),
                            SizedBox(height: 10),
                            _CashDrawerTip(
                              text:
                                  'Only one open drawer session is allowed per cashier.',
                            ),
                          ],
                        ),
                      ),
                    );

                    final openForm = _CashDrawerHoverCard(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFFBFDFF)],
                          ),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFFE1E9F3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Row(
                              children: [
                                _CashDrawerIconBox(
                                  icon: Icons.lock_open_outlined,
                                  color: Color(0xFF159447),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Open Cash Drawer',
                                        style: TextStyle(
                                          color: Color(0xFF172033),
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Enter the amount currently inside the drawer.',
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
                            const SizedBox(height: 22),
                            TextField(
                              controller: _openingController,
                              enabled: !_processing,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onSubmitted: (_) {
                                if (!_processing) {
                                  _openDrawer();
                                }
                              },
                              decoration: _drawerInputDecoration(
                                label: 'Opening Cash',
                                icon: Icons.payments_outlined,
                                prefixText: '₱ ',
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              height: 51,
                              child: ElevatedButton.icon(
                                onPressed: _processing ? null : _openDrawer,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF159447),
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: const Color(
                                    0xFF91C5A7,
                                  ),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                ),
                                icon: _processing
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.lock_open_outlined),
                                label: Text(
                                  _processing ? 'OPENING...' : 'OPEN DRAWER',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (wide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: guidance),
                          const SizedBox(width: 16),
                          Expanded(flex: 3, child: openForm),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        guidance,
                        const SizedBox(height: 16),
                        openForm,
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
  void dispose() {
    _openingController.dispose();
    _countedController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
