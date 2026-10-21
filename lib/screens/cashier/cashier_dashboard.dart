// -----------------------------------------------------------------------------
// Module overview: Main cashier navigation shell that exposes POS, products, transactions, shift reporting, and account actions.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/responsive_device.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';
import '../pos/new_transaction_screen.dart';
import 'cashier_transaction_history_screen.dart';
import 'cashier_products_screen.dart';
import 'cashier_barcode_scanner_screen.dart';
import 'cashier_shift_report_screen.dart';
import '../shared/service_issue_logging_screen.dart';
import '../shared/change_password_screen.dart';

// Defines a reusable component or data structure used by this module.
class CashierDashboard extends StatefulWidget {
  // Handles the cashier dashboard logic used by this module.
  const CashierDashboard({super.key});

  @override
  State<CashierDashboard> createState() => _CashierDashboardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _CashierDashboardState extends State<CashierDashboard> {
  int _selectedIndex = 0;

  final List<_MenuItem> _menuItems = const [
    _MenuItem('Dashboard', Icons.dashboard_outlined),
    _MenuItem('New Transaction', Icons.point_of_sale),
    _MenuItem('Products', Icons.inventory_2_outlined),
    _MenuItem('Barcode Scanner', Icons.qr_code_scanner),
    _MenuItem('Transaction History', Icons.receipt_long_outlined),
    _MenuItem('End-of-Shift Report', Icons.summarize_outlined),
    _MenuItem('Service Issues', Icons.report_problem_outlined),
    _MenuItem('Change Password', Icons.password_outlined),
  ];

  // Finalizes the current login-activity record with logout time and session duration.
  Future<void> _closeLoginSession() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      final preferences = await SharedPreferences.getInstance();

      final activityId = preferences.getString('activeLoginActivityId');

      final startedAtMilliseconds = preferences.getInt('activeLoginStartedAt');

      if (activityId == null || startedAtMilliseconds == null) {
        return;
      }

      final logoutAt = DateTime.now();

      final startedAt = DateTime.fromMillisecondsSinceEpoch(
        startedAtMilliseconds,
      );

      final durationSeconds = logoutAt
          .difference(startedAt)
          .inSeconds
          .clamp(0, 86400 * 30)
          .toInt();

      await FirebaseFirestore.instance
          .collection('login_activity')
          .doc(activityId)
          .update({
            'logoutAt': FieldValue.serverTimestamp(),
            'sessionDurationSeconds': durationSeconds,
            'sessionStatus': 'closed',
            'logoutReason': 'manual_logout',
          });

      await preferences.remove('activeLoginActivityId');

      await preferences.remove('activeLoginStartedAt');
    } catch (error) {
      debugPrint('Unable to close login session: $error');
    }
  }

  // Closes the active login session, signs the user out, and returns to the login screen.
  Future<void> _logout() async {
    // Finalizes the current login-activity record with logout time and session duration.
    await _closeLoginSession();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // Builds the sidebar UI from the current data and screen state.
  Widget _buildSidebar({required bool compact, bool drawerMode = false}) {
    // Handles the animated container logic used by this module.
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      width: compact ? 88 : 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0D47A1), Color(0xFF1565C0), Color(0xFF0B4C9C)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 16,
            offset: Offset(5, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                compact ? 12 : 18,
                16,
                compact ? 12 : 18,
                12,
              ),
              child: Container(
                height: 68,
                padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: compact
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/images/eu_mart_logo.png',
                      width: compact ? 46 : 50,
                      height: compact ? 46 : 50,
                      fit: BoxFit.contain,
                    ),
                    if (!compact) ...[
                      // Handles the sized box logic used by this module.
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EÜ MART',
                              style: GoogleFonts.baloo2(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            // Handles the text logic used by this module.
                            const Text(
                              'Cashier Portal',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  final selected = _selectedIndex == index;

                  Widget tile = Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 210),
                      decoration: BoxDecoration(
                        color: selected ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: selected
                            ? const [
                                BoxShadow(
                                  color: Color(0x20000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : const [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(13),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          hoverColor: Colors.white.withValues(alpha: 0.12),
                          onTap: () {
                            setState(() {
                              _selectedIndex = index;
                            });
                            if (drawerMode && Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          child: SizedBox(
                            height: 48,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: compact ? 10 : 13,
                              ),
                              child: Row(
                                mainAxisAlignment: compact
                                    ? MainAxisAlignment.center
                                    : MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    item.icon,
                                    size: 21,
                                    color: selected
                                        ? const Color(0xFF1565C0)
                                        : Colors.white,
                                  ),
                                  if (!compact) ...[
                                    // Handles the sized box logic used by this module.
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        item.label,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: selected
                                              ? const Color(0xFF18324F)
                                              : Colors.white,
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );

                  if (compact) {
                    tile = Tooltip(message: item.label, child: tile);
                  }

                  return tile;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(9, 6, 9, 12),
              child: Material(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(13),
                  hoverColor: Colors.redAccent.withValues(alpha: 0.18),
                  child: SizedBox(
                    height: 48,
                    child: Row(
                      mainAxisAlignment: compact
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        SizedBox(width: compact ? 0 : 14),
                        // Handles the icon logic used by this module.
                        const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                        if (!compact) ...[
                          // Handles the sized box logic used by this module.
                          const SizedBox(width: 12),
                          // Handles the text logic used by this module.
                          const Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Builds the top bar UI from the current data and screen state.
  Widget _buildTopBar({bool mobile = false, VoidCallback? onMenuPressed}) {
    final user = FirebaseAuth.instance.currentUser;
    final pageTitle = _menuItems[_selectedIndex].label;

    // Handles the container logic used by this module.
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 22),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE7EDF5))),
        boxShadow: [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (mobile) ...[
            Material(
              color: const Color(0xFFF0F5FC),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onMenuPressed,
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.menu_rounded,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ),
            // Handles the sized box logic used by this module.
            const SizedBox(width: 10),
          ],
          if (_selectedIndex != 0) ...[
            Material(
              color: const Color(0xFFF0F5FC),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: const SizedBox(
                  width: 42,
                  height: 42,
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
            ),
            // Handles the sized box logic used by this module.
            const SizedBox(width: 14),
          ],
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Column(
                key: ValueKey<String>(pageTitle),
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pageTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF172033),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    _selectedIndex == 0
                        ? 'Process transactions and assist customers.'
                        : 'Manage and review $pageTitle.',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF7D8796),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (mobile)
            // Handles the circle avatar logic used by this module.
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF1565C0),
              child: Icon(Icons.person_rounded, color: Colors.white, size: 19),
            )
          else
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFD2E4FA)),
            ),
            child: Row(
              children: [
                // Handles the circle avatar logic used by this module.
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFF1565C0),
                  child: Icon(
                    Icons.point_of_sale_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 9),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handles the text logic used by this module.
                    const Text(
                      'Cashier',
                      style: TextStyle(
                        color: Color(0xFF17345A),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: Color(0xFF6D798B),
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Handles the summary card logic used by this module.
  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Handles the container logic used by this module.
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
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
            child: Icon(icon, color: color, size: 28),
          ),
          // Handles the sized box logic used by this module.
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 25,
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

  // Normalizes supported Firestore/date values into a Dart DateTime for consistent comparisons.
  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  // Formats date/time values used in the owner dashboard overview.
  String _formatDashboardDate(DateTime? date) {
    if (date == null) return 'Date unavailable';

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.year}-$month-$day • $hour:$minute $period';
  }

  // Handles the dashboard panel logic used by this module.
  Widget _dashboardPanel({
    required String title,
    required Widget child,
    VoidCallback? onViewAll,
  }) {
    // Handles the container logic used by this module.
    return Container(
      padding: const EdgeInsets.all(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (onViewAll != null)
                TextButton(onPressed: onViewAll, child: const Text('View All')),
            ],
          ),
          // Handles the sized box logic used by this module.
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  // Builds the cashier promo carousel UI from the current data and screen state.
  Widget _buildCashierPromoCarousel(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Reads and normalizes date from stored data.
    DateTime? readDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      return null;
    }

    final promos = products.where((document) {
      final data = document.data();

      if (data['promoActive'] != true) return false;

      final stock = (data['stock'] as num?)?.toInt() ?? 0;
      if (stock <= 0) return false;

      final startDate = readDate(data['promoStartDate']);
      final endDate = readDate(data['promoEndDate']);

      if (startDate != null) {
        final normalizedStart = DateTime(
          startDate.year,
          startDate.month,
          startDate.day,
        );

        if (normalizedStart.isAfter(today)) return false;
      }

      if (endDate != null) {
        final normalizedEnd = DateTime(
          endDate.year,
          endDate.month,
          endDate.day,
        );

        if (normalizedEnd.isBefore(today)) return false;
      }

      return true;
    }).toList();

    if (promos.isEmpty) {
      return const SizedBox.shrink();
    }

    // Handles the column logic used by this module.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Handles the expanded logic used by this module.
            const Expanded(
              child: Text(
                'Available Store Promos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 1;
                });
              },
              icon: const Icon(Icons.point_of_sale),
              label: const Text('START TRANSACTION'),
            ),
          ],
        ),
        // Handles the sized box logic used by this module.
        const SizedBox(height: 12),
        SizedBox(
          height: 205,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: promos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final data = promos[index].data();

              final productName = (data['productName'] ?? 'Product').toString();

              final promoType = (data['promoType'] ?? 'Promo').toString();

              final promoLabel = (data['promoLabel'] ?? promoType).toString();

              final regularPrice =
                  (data['sellingPrice'] as num?)?.toDouble() ?? 0;

              final promoPrice = (data['promoPrice'] as num?)?.toDouble();

              final stock = (data['stock'] as num?)?.toInt() ?? 0;

              final endDate = readDate(data['promoEndDate']);

              final priceText = promoType == 'Buy 1 Take 1'
                  ? 'BUY 1 TAKE 1'
                  : promoPrice != null
                  ? '₱${promoPrice.toStringAsFixed(2)}'
                  : promoType.toUpperCase();

              // Handles the material logic used by this module.
              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 1;
                    });
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 305,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: index.isEven
                            ? const [Color(0xFF1565C0), Color(0xFF42A5F5)]
                            : const [Color(0xFFFF6B35), Color(0xFFFF9F1C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 12,
                          offset: Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            promoLabel.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Handles the sized box logic used by this module.
                        const SizedBox(height: 12),
                        Text(
                          productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        // Handles the spacer logic used by this module.
                        const Spacer(),
                        if (promoType != 'Buy 1 Take 1' && promoPrice != null)
                          Text(
                            'Regular ₱${regularPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        Text(
                          priceText,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        // Handles the sized box logic used by this module.
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                endDate == null
                                    ? 'Limited-time offer'
                                    : 'Valid until '
                                          '${endDate.year}-'
                                          '${endDate.month.toString().padLeft(2, '0')}-'
                                          '${endDate.day.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Text(
                              '$stock left',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Builds the dashboard overview UI from the current data and screen state.
  Widget _buildDashboardOverview() {
    final currentUser = FirebaseAuth.instance.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('system')
          .snapshots(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data?.data() ?? <String, dynamic>{};

        final lowStockThreshold =
            (settings['lowStockThreshold'] as num?)?.toInt() ?? 10;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            final productDocs =
                List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                  productSnapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                );

            final availableProducts = productDocs.where((document) {
              final stock = (document.data()['stock'] as num?)?.toInt() ?? 0;
              return stock > 0;
            }).length;

            final lowStockProducts =
                productDocs.where((document) {
                  final stock =
                      (document.data()['stock'] as num?)?.toInt() ?? 0;
                  return stock > 0 && stock <= lowStockThreshold;
                }).toList()..sort((a, b) {
                  final first = (a.data()['stock'] as num?)?.toInt() ?? 0;
                  final second = (b.data()['stock'] as num?)?.toInt() ?? 0;
                  return first.compareTo(second);
                });

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('processedById', isEqualTo: currentUser?.uid ?? '')
                  .snapshots(),
              builder: (context, transactionSnapshot) {
                final transactionDocs =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      transactionSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                    );

                final completedTransactions =
                    transactionDocs.where((document) {
                      final status = (document.data()['status'] ?? 'completed')
                          .toString()
                          .toLowerCase();

                      return status != 'voided';
                    }).toList()..sort((a, b) {
                      final first = _readDate(a.data()['createdAt']);
                      final second = _readDate(b.data()['createdAt']);

                      if (first == null && second == null) return 0;
                      if (first == null) return 1;
                      if (second == null) return -1;

                      return second.compareTo(first);
                    });

                final now = DateTime.now();
                double todaySales = 0;
                int todayTransactionCount = 0;
                int todayItemsSold = 0;

                for (final document in completedTransactions) {
                  final data = document.data();
                  final date = _readDate(data['createdAt']);

                  if (date == null ||
                      date.year != now.year ||
                      date.month != now.month ||
                      date.day != now.day) {
                    continue;
                  }

                  todayTransactionCount++;
                  todaySales += (data['total'] as num?)?.toDouble() ?? 0;

                  final items = data['items'] as List<dynamic>? ?? <dynamic>[];

                  for (final rawItem in items) {
                    if (rawItem is! Map) continue;

                    final item = Map<String, dynamic>.from(rawItem);

                    todayItemsSold += (item['quantity'] as num?)?.toInt() ?? 0;
                  }
                }

                // Handles the single child scroll view logic used by this module.
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome, ${currentUser?.displayName ?? 'Cashier'}!',
                        style: GoogleFonts.baloo2(
                          fontSize: 30,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1F2937),
                        ),
                      ),
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 8),
                      // Handles the text logic used by this module.
                      const Text(
                        'Here is your current cashier activity and store status.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 24),
                      _buildCashierPromoCarousel(productDocs),
                      if (productDocs.any(
                        (document) => document.data()['promoActive'] == true,
                      ))
                        // Handles the sized box logic used by this module.
                        const SizedBox(height: 26),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 4;

                          if (constraints.maxWidth < 1100) {
                            crossAxisCount = 2;
                          }

                          if (constraints.maxWidth < 620) {
                            crossAxisCount = 1;
                          }

                          return GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 18,
                            mainAxisSpacing: 18,
                            childAspectRatio: 2.15,
                            children: [
                              _summaryCard(
                                title: "Today's Sales",
                                value: '₱${todaySales.toStringAsFixed(2)}',
                                icon: Icons.payments_outlined,
                                color: Colors.green,
                              ),
                              _summaryCard(
                                title: "Today's Transactions",
                                value: '$todayTransactionCount',
                                icon: Icons.receipt_long_outlined,
                                color: const Color(0xFF1565C0),
                              ),
                              _summaryCard(
                                title: "Today's Items Sold",
                                value: '$todayItemsSold',
                                icon: Icons.shopping_bag_outlined,
                                color: Colors.purple,
                              ),
                              _summaryCard(
                                title: 'Available Products',
                                value: '$availableProducts',
                                icon: Icons.inventory_2_outlined,
                                color: Colors.orange,
                              ),
                            ],
                          );
                        },
                      ),
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 26),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 920;

                          final recentTransactions = _dashboardPanel(
                            title: 'My Recent Transactions',
                            onViewAll: () {
                              setState(() {
                                _selectedIndex = 4;
                              });
                            },
                            child: completedTransactions.isEmpty
                                ? const SizedBox(
                                    height: 210,
                                    child: Center(
                                      child: Text(
                                        'No transactions yet.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: completedTransactions.take(5).map(
                                      (document) {
                                        final data = document.data();

                                        final receipt =
                                            (data['receiptNumber'] ??
                                                    data['transactionNumber'] ??
                                                    document.id)
                                                .toString();

                                        final total =
                                            (data['total'] as num?)
                                                ?.toDouble() ??
                                            0;

                                        // Handles the list tile logic used by this module.
                                        return ListTile(
                                          contentPadding: EdgeInsets.zero,
                                          leading: const CircleAvatar(
                                            backgroundColor: Color(0xFFE3F2FD),
                                            child: Icon(
                                              Icons.receipt_long,
                                              color: Color(0xFF1565C0),
                                            ),
                                          ),
                                          title: Text(
                                            receipt,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          subtitle: Text(
                                            _formatDashboardDate(
                                              _readDate(data['createdAt']),
                                            ),
                                          ),
                                          trailing: Text(
                                            '₱${total.toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        );
                                      },
                                    ).toList(),
                                  ),
                          );

                          final stockPanel = _dashboardPanel(
                            title: 'Low-Stock Products',
                            onViewAll: () {
                              setState(() {
                                _selectedIndex = 2;
                              });
                            },
                            child: lowStockProducts.isEmpty
                                ? const SizedBox(
                                    height: 210,
                                    child: Center(
                                      child: Text(
                                        'No low-stock products.',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  )
                                : Column(
                                    children: lowStockProducts.take(5).map((
                                      document,
                                    ) {
                                      final data = document.data();
                                      final name =
                                          (data['productName'] ??
                                                  'Unknown Product')
                                              .toString();
                                      final stock =
                                          (data['stock'] as num?)?.toInt() ?? 0;

                                      // Handles the list tile logic used by this module.
                                      return ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: CircleAvatar(
                                          backgroundColor:
                                              Colors.orange.shade50,
                                          child: const Icon(
                                            Icons.warning_amber_rounded,
                                            color: Colors.orange,
                                          ),
                                        ),
                                        title: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        trailing: Text(
                                          '$stock left',
                                          style: const TextStyle(
                                            color: Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          );

                          if (isWide) {
                            // Handles the row logic used by this module.
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: recentTransactions),
                                // Handles the sized box logic used by this module.
                                const SizedBox(width: 20),
                                Expanded(flex: 2, child: stockPanel),
                              ],
                            );
                          }

                          // Handles the column logic used by this module.
                          return Column(
                            children: [
                              recentTransactions,
                              // Handles the sized box logic used by this module.
                              const SizedBox(height: 20),
                              stockPanel,
                            ],
                          );
                        },
                      ),
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 20),
                      _dashboardPanel(
                        title: 'Quick Actions',
                        child: Wrap(
                          spacing: 14,
                          runSpacing: 14,
                          children: [
                            _quickActionButton(
                              label: 'New Transaction',
                              icon: Icons.point_of_sale,
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 1;
                                });
                              },
                            ),
                            _quickActionButton(
                              label: 'View Products',
                              icon: Icons.inventory_2_outlined,
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 2;
                                });
                              },
                            ),
                            _quickActionButton(
                              label: 'Scan Barcode',
                              icon: Icons.qr_code_scanner,
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 3;
                                });
                              },
                            ),
                            _quickActionButton(
                              label: 'Transaction History',
                              icon: Icons.history,
                              onPressed: () {
                                setState(() {
                                  _selectedIndex = 4;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // Handles the quick action button logic used by this module.
  Widget _quickActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    // Handles the sized box logic used by this module.
    return SizedBox(
      width: 210,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }

  // Builds the placeholder page UI from the current data and screen state.
  Widget _buildPlaceholderPage() {
    final item = _menuItems[_selectedIndex];

    // Handles the center logic used by this module.
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        margin: const EdgeInsets.all(30),
        padding: const EdgeInsets.all(34),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, size: 72, color: const Color(0xFF1565C0)),
            // Handles the sized box logic used by this module.
            const SizedBox(height: 18),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            // Handles the sized box logic used by this module.
            const SizedBox(height: 10),
            // Handles the text logic used by this module.
            const Text(
              'This module will be developed next.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // Handles the selected page logic used by this module.
  Widget _selectedPage() {
    // Handles the keyed subtree logic used by this module.
    return KeyedSubtree(
      key: ValueKey<int>(_selectedIndex),
      child: switch (_selectedIndex) {
                              0 => _buildDashboardOverview(),
                              1 => const NewTransactionScreen(),
                              2 => const CashierProductsScreen(),
                              3 => const CashierBarcodeScannerScreen(),
                              4 => const CashierTransactionHistoryScreen(),
                              5 => const CashierShiftReportScreen(),
                              6 => const ServiceIssueLoggingScreen(),
                              7 => const ChangePasswordScreen(),
                              _ => _buildPlaceholderPage(),
                            }
    );
  }

  @override
  Widget build(BuildContext context) {
    // Handles the layout builder logic used by this module.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isPhone = ResponsiveDevice.useMobileLayout(
          constraints.maxWidth,
          breakpoint: 1000,
        );

        if (isPhone) {
          // Handles the scaffold logic used by this module.
          return Scaffold(
            backgroundColor: const Color(0xFFF2F6FC),
            drawer: Drawer(
              width: 280,
              child: _buildSidebar(compact: false, drawerMode: true),
            ),
            body: SafeArea(
              child: Builder(
                builder: (scaffoldContext) {
                  // Handles the column logic used by this module.
                  return Column(
                    children: [
                      _buildTopBar(
                        mobile: true,
                        onMenuPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                      ),
                      Expanded(
                        child: ClipRect(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            switchInCurve: Curves.easeOut,
                            switchOutCurve: Curves.easeIn,
                            child: _selectedPage(),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }

        final compactSidebar = constraints.maxWidth < 1050;

        // Handles the scaffold logic used by this module.
        return Scaffold(
          backgroundColor: const Color(0xFFF2F6FC),
          body: Row(
            children: [
              _buildSidebar(compact: compactSidebar),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(),
                    Expanded(
                      child: ClipRect(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: _selectedPage(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// Private UI/data helper used only inside this module.
class _MenuItem {
  final String label;
  final IconData icon;

  // Handles the menu item logic used by this module.
  const _MenuItem(this.label, this.icon);
}
