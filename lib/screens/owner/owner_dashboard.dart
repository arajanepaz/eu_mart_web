import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/login_screen.dart';
import '../pos/new_transaction_screen.dart';
import 'products_inventory_screen.dart';
import 'barcode_generator_screen.dart';
import 'owner_transaction_history_screen.dart';
import 'sales_reports_screen.dart';
import 'notifications_screen.dart';
import 'promotions_management_screen.dart';
import 'restock_suggestions_screen.dart';
import 'stock_movement_screen.dart';
import 'promo_sales_report_screen.dart';
import 'supplier_management_screen.dart';
import 'cashier_performance_report_screen.dart';
import 'estimated_profit_report_screen.dart';
import 'product_movement_report_screen.dart';
import '../shared/service_issue_logging_screen.dart';
import 'service_monitoring_report_screen.dart';
import 'permit_renewal_reminder_screen.dart';
import 'sales_comparison_screen.dart';
import 'service_issue_summary_screen.dart';
import 'daily_operations_summary_screen.dart';
import '../shared/change_password_screen.dart';
import 'login_activity_screen.dart';
import 'manage_cashiers_screen.dart';
import 'audit_trail_screen.dart';
import '../settings/settings_screen.dart';
import 'customer_feedback_screen.dart';
import 'backup_export_screen.dart';
import 'firestore_schema_export_screen.dart';

class OwnerDashboard extends StatefulWidget {
  const OwnerDashboard({super.key});

  @override
  State<OwnerDashboard> createState() => _OwnerDashboardState();
}

class _OwnerDashboardState extends State<OwnerDashboard> {
  int _selectedIndex = 0;

  final List<_MenuItem> _menuItems = const [
    _MenuItem('Dashboard', Icons.dashboard_outlined),
    _MenuItem('New Transaction', Icons.point_of_sale),
    _MenuItem('Products & Inventory', Icons.inventory_2_outlined),
    _MenuItem('Restock Suggestions', Icons.auto_graph_outlined),
    _MenuItem('Stock Movements', Icons.swap_vert_circle_outlined),
    _MenuItem('Suppliers', Icons.local_shipping_outlined),
    _MenuItem('Barcode Generator', Icons.qr_code_2),
    _MenuItem('Transactions', Icons.receipt_long_outlined),
    _MenuItem('Sales Reports', Icons.bar_chart_outlined),
    _MenuItem('Promotions', Icons.local_offer_outlined),
    _MenuItem('Notifications', Icons.notifications_none),
    _MenuItem('Manage Cashiers', Icons.groups_outlined),
    _MenuItem('Audit Trail', Icons.history),
    _MenuItem('Customer Feedback', Icons.reviews_outlined),
    _MenuItem('Backup & Export', Icons.backup_outlined),
    _MenuItem('Promo Sales Report', Icons.sell_outlined),
    _MenuItem('Cashier Performance', Icons.leaderboard_outlined),
    _MenuItem('Estimated Profit', Icons.trending_up_outlined),
    _MenuItem('Product Movement', Icons.multiline_chart_outlined),
    _MenuItem('Service Issues', Icons.report_problem_outlined),
    _MenuItem('Service Monitoring', Icons.speed_outlined),
    _MenuItem('Permit Reminders', Icons.description_outlined),
    _MenuItem('Sales Comparison', Icons.compare_arrows_outlined),
    _MenuItem('Issue Summary', Icons.assessment_outlined),
    _MenuItem('Daily Operations', Icons.dashboard_customize_outlined),
    _MenuItem('Change Password', Icons.password_outlined),
    _MenuItem('Login Activity', Icons.login_outlined),
    _MenuItem('Settings', Icons.settings_outlined),
  ];

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

  Future<void> _logout() async {
    await _closeLoginSession();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  DateTime? _notificationReadDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _notificationType(
    Map<String, dynamic> data, {
    required int lowStockThreshold,
    required int expirationAlertDays,
    required bool enableLowStockAlerts,
    required bool enableExpirationAlerts,
  }) {
    final stock = (data['stock'] as num?)?.toInt() ?? 0;
    final expirationDate = _notificationReadDate(data['expirationDate']);

    if (stock <= 0) return 'Out of Stock';

    if (enableExpirationAlerts && expirationDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final expiration = DateTime(
        expirationDate.year,
        expirationDate.month,
        expirationDate.day,
      );

      final daysRemaining = expiration.difference(today).inDays;

      if (daysRemaining < 0) return 'Expired';
      if (daysRemaining <= expirationAlertDays) {
        return 'Expiring Soon';
      }
    }

    if (enableLowStockAlerts && stock <= lowStockThreshold) {
      return 'Low Stock';
    }

    return 'Normal';
  }

  String _notificationReadId({
    required String userId,
    required String productId,
    required String type,
  }) {
    final normalizedType = type.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );

    return '${userId}_${productId}_$normalizedType';
  }

  Widget _buildNotificationBadge({
    required bool compact,
    required Widget child,
  }) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

    if (userId.isEmpty) return child;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('system')
          .snapshots(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data?.data() ?? <String, dynamic>{};

        final lowStockThreshold =
            (settings['lowStockThreshold'] as num?)?.toInt() ?? 10;

        final expirationAlertDays =
            (settings['expirationAlertDays'] as num?)?.toInt() ?? 30;

        final enableLowStockAlerts = settings['enableLowStockAlerts'] != false;

        final enableExpirationAlerts =
            settings['enableExpirationAlerts'] != false;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productsSnapshot) {
            final products =
                productsSnapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[];

            final alertIds = <String>{};

            for (final document in products) {
              final type = _notificationType(
                document.data(),
                lowStockThreshold: lowStockThreshold,
                expirationAlertDays: expirationAlertDays,
                enableLowStockAlerts: enableLowStockAlerts,
                enableExpirationAlerts: enableExpirationAlerts,
              );

              if (type == 'Normal') continue;

              alertIds.add(
                _notificationReadId(
                  userId: userId,
                  productId: document.id,
                  type: type,
                ),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('notification_reads')
                  .where('userId', isEqualTo: userId)
                  .snapshots(),
              builder: (context, readsSnapshot) {
                final readIds = <String>{
                  for (final document
                      in readsSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    document.id,
                };

                final unreadCount = alertIds
                    .where((id) => !readIds.contains(id))
                    .length;

                if (unreadCount == 0) return child;

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    child,
                    Positioned(
                      top: compact ? -6 : 4,
                      right: compact ? -6 : 8,
                      child: Container(
                        constraints: const BoxConstraints(
                          minWidth: 22,
                          minHeight: 22,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF0D47A1),
                            width: 2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          unreadCount > 99 ? '99+' : '$unreadCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSidebar({required bool compact}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOutCubic,
      width: compact ? 88 : 260,
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
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'EÜ MART',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              'Owner Portal',
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

                  if (item.label == 'Notifications') {
                    return _buildNotificationBadge(
                      compact: compact,
                      child: tile,
                    );
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
                        const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 21,
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 12),
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

  Widget _buildTopBar() {
    final user = FirebaseAuth.instance.currentUser;
    final pageTitle = _menuItems[_selectedIndex].label;

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
                        ? 'Monitor and manage store operations.'
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
                const CircleAvatar(
                  radius: 17,
                  backgroundColor: Color(0xFF1565C0),
                  child: Icon(
                    Icons.person_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Owner',
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

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        hoverColor: color.withValues(alpha: 0.06),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
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
              const SizedBox(width: 16),
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
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.black38,
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

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

  Widget _dashboardPanel({
    required String title,
    required Widget child,
    VoidCallback? onViewAll,
  }) {
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _buildPromoCarousel(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final activePromos = products.where((document) {
      final data = document.data();

      if (data['promoActive'] != true) return false;

      final startDate = _readDate(data['promoStartDate']);
      final endDate = _readDate(data['promoEndDate']);

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

    if (activePromos.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDD5),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.local_offer_outlined,
                color: Colors.orange,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No Active Promotions',
                    style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Create a discount, Buy 1 Take 1, or near-expiry promo.',
                    style: TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 10;
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('CREATE PROMO'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Featured Promotions',
                style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold),
              ),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndex = 10;
                });
              },
              icon: const Icon(Icons.local_offer_outlined),
              label: const Text('Manage Promotions'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 235,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: activePromos.length,
            separatorBuilder: (_, _) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final data = activePromos[index].data();

              final productName = (data['productName'] ?? 'Product').toString();

              final promoType = (data['promoType'] ?? 'Promo').toString();

              final promoLabel = (data['promoLabel'] ?? promoType).toString();

              final regularPrice =
                  (data['sellingPrice'] as num?)?.toDouble() ?? 0;

              final promoPrice = (data['promoPrice'] as num?)?.toDouble();

              final stock = (data['stock'] as num?)?.toInt() ?? 0;

              final endDate = _readDate(data['promoEndDate']);

              String priceText;

              if (promoType == 'Buy 1 Take 1') {
                priceText = 'BUY 1 TAKE 1';
              } else if (promoPrice != null) {
                priceText = '₱${promoPrice.toStringAsFixed(2)}';
              } else {
                priceText = promoType.toUpperCase();
              }

              return Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndex = 10;
                    });
                  },
                  borderRadius: BorderRadius.circular(22),
                  child: Container(
                    width: 330,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: index.isEven
                            ? const [Color(0xFFFF6B35), Color(0xFFFF9F1C)]
                            : const [Color(0xFF1565C0), Color(0xFF42A5F5)],
                      ),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 14,
                          offset: Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -18,
                          top: -28,
                          child: Icon(
                            Icons.local_offer,
                            size: 130,
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        Column(
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
                            const SizedBox(height: 15),
                            Text(
                              productName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 21,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            if (promoType != 'Buy 1 Take 1' &&
                                promoPrice != null)
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
                                fontSize: 25,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    endDate == null
                                        ? 'Limited-time offer'
                                        : 'Until ${_formatDashboardDate(endDate).split(' • ').first}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$stock in stock',
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

  Widget _buildDashboardOverview() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('system')
          .snapshots(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data?.data() ?? <String, dynamic>{};

        final lowStockThreshold =
            (settings['lowStockThreshold'] as num?)?.toInt() ?? 10;

        final expirationAlertDays =
            (settings['expirationAlertDays'] as num?)?.toInt() ?? 30;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            final productDocs =
                List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                  productSnapshot.data?.docs ??
                      <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                );

            final productCount = productDocs.length;

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

            final outOfStockCount = productDocs.where((document) {
              final stock = (document.data()['stock'] as num?)?.toInt() ?? 0;
              return stock <= 0;
            }).length;

            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);

            final expiringProducts =
                productDocs.where((document) {
                  final expiration = _readDate(
                    document.data()['expirationDate'],
                  );

                  if (expiration == null) return false;

                  final normalized = DateTime(
                    expiration.year,
                    expiration.month,
                    expiration.day,
                  );

                  final daysRemaining = normalized.difference(today).inDays;

                  return daysRemaining >= 0 &&
                      daysRemaining <= expirationAlertDays;
                }).toList()..sort((a, b) {
                  final first = _readDate(a.data()['expirationDate']);
                  final second = _readDate(b.data()['expirationDate']);

                  if (first == null && second == null) return 0;
                  if (first == null) return 1;
                  if (second == null) return -1;

                  return first.compareTo(second);
                });

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
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

                double totalSales = 0;
                double todaySales = 0;
                final Map<String, int> productQuantities = {};

                for (final document in completedTransactions) {
                  final data = document.data();
                  final total = (data['total'] as num?)?.toDouble() ?? 0;

                  totalSales += total;

                  final transactionDate = _readDate(data['createdAt']);

                  if (transactionDate != null &&
                      transactionDate.year == now.year &&
                      transactionDate.month == now.month &&
                      transactionDate.day == now.day) {
                    todaySales += total;
                  }

                  final items = data['items'] as List<dynamic>? ?? <dynamic>[];

                  for (final rawItem in items) {
                    if (rawItem is! Map) continue;

                    final item = Map<String, dynamic>.from(rawItem);

                    final name = (item['productName'] ?? 'Unknown Product')
                        .toString();

                    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

                    productQuantities[name] =
                        (productQuantities[name] ?? 0) + quantity;
                  }
                }

                final topProducts = productQuantities.entries.toList()
                  ..sort((a, b) => b.value.compareTo(a.value));

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Welcome back, Owner!',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Here is the latest overview of EÜ MART operations.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      _buildPromoCarousel(productDocs),
                      const SizedBox(height: 26),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 4;

                          if (constraints.maxWidth < 1150) {
                            crossAxisCount = 2;
                          }

                          if (constraints.maxWidth < 650) {
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
                                title: 'Total Products',
                                value: '$productCount',
                                icon: Icons.inventory_2,
                                color: const Color(0xFF1565C0),
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = 2;
                                  });
                                },
                              ),
                              _summaryCard(
                                title: 'Stock Alerts',
                                value:
                                    '${lowStockProducts.length + outOfStockCount}',
                                icon: Icons.warning_amber_rounded,
                                color: Colors.orange,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = 10;
                                  });
                                },
                              ),
                              _summaryCard(
                                title: "Today's Sales",
                                value: '₱${todaySales.toStringAsFixed(2)}',
                                icon: Icons.today_outlined,
                                color: Colors.purple,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = 10;
                                  });
                                },
                              ),
                              _summaryCard(
                                title: 'Total Sales',
                                value: '₱${totalSales.toStringAsFixed(2)}',
                                icon: Icons.payments,
                                color: Colors.green,
                                onTap: () {
                                  setState(() {
                                    _selectedIndex = 10;
                                  });
                                },
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 980;

                          final recentTransactions = _dashboardPanel(
                            title: 'Recent Transactions',
                            onViewAll: () {
                              setState(() {
                                _selectedIndex = 10;
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
                                    children: completedTransactions.take(5).map((
                                      document,
                                    ) {
                                      final data = document.data();

                                      final receipt =
                                          (data['receiptNumber'] ??
                                                  data['transactionNumber'] ??
                                                  document.id)
                                              .toString();

                                      final cashier =
                                          (data['processedByName'] ??
                                                  data['processedByEmail'] ??
                                                  'Unknown Cashier')
                                              .toString();

                                      final total =
                                          (data['total'] as num?)?.toDouble() ??
                                          0;

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
                                          '$cashier\n${_formatDashboardDate(_readDate(data['createdAt']))}',
                                        ),
                                        isThreeLine: true,
                                        trailing: Text(
                                          '₱${total.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          );

                          final alerts = _dashboardPanel(
                            title: 'Inventory Alerts',
                            onViewAll: () {
                              setState(() {
                                _selectedIndex = 10;
                              });
                            },
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.red.shade50,
                                    child: const Icon(
                                      Icons.remove_shopping_cart_outlined,
                                      color: Colors.red,
                                    ),
                                  ),
                                  title: const Text(
                                    'Out of Stock',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Text(
                                    '$outOfStockCount',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.orange.shade50,
                                    child: const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  title: Text(
                                    'Low Stock (≤ $lowStockThreshold)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Text(
                                    '${lowStockProducts.length}',
                                    style: const TextStyle(
                                      color: Colors.orange,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.amber.shade50,
                                    child: Icon(
                                      Icons.schedule_outlined,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                  title: Text(
                                    'Expiring in $expirationAlertDays day(s)',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: Text(
                                    '${expiringProducts.length}',
                                    style: TextStyle(
                                      color: Colors.amber.shade800,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (isWide) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: recentTransactions),
                                const SizedBox(width: 20),
                                Expanded(flex: 2, child: alerts),
                              ],
                            );
                          }

                          return Column(
                            children: [
                              recentTransactions,
                              const SizedBox(height: 20),
                              alerts,
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _dashboardPanel(
                        title: 'Top-Selling Products',
                        onViewAll: () {
                          setState(() {
                            _selectedIndex = 10;
                          });
                        },
                        child: topProducts.isEmpty
                            ? const SizedBox(
                                height: 150,
                                child: Center(
                                  child: Text(
                                    'No product sales data yet.',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final displayed = topProducts
                                      .take(5)
                                      .toList();

                                  return Wrap(
                                    spacing: 14,
                                    runSpacing: 14,
                                    children: displayed.asMap().entries.map((
                                      entry,
                                    ) {
                                      final width = constraints.maxWidth >= 900
                                          ? (constraints.maxWidth - 56) / 5
                                          : constraints.maxWidth >= 560
                                          ? (constraints.maxWidth - 14) / 2
                                          : constraints.maxWidth;

                                      return SizedBox(
                                        width: width,
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFF7F9FC),
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '#${entry.key + 1}',
                                                style: const TextStyle(
                                                  color: Color(0xFF1565C0),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                entry.value.key,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '${entry.value.value} item(s) sold',
                                                style: const TextStyle(
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  );
                                },
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

  Widget _buildPlaceholderPage() {
    final item = _menuItems[_selectedIndex];

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
            const SizedBox(height: 18),
            Text(
              item.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 27, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F6FC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compactSidebar = constraints.maxWidth < 1100;

          return Row(
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
                          child: KeyedSubtree(
                            key: ValueKey<int>(_selectedIndex),
                            child: switch (_selectedIndex) {
                              0 => _buildDashboardOverview(),
                              1 => const NewTransactionScreen(),
                              2 => const ProductsInventoryScreen(),
                              3 => const RestockSuggestionsScreen(),
                              4 => const StockMovementScreen(),
                              5 => const SupplierManagementScreen(),
                              6 => const BarcodeGeneratorScreen(),
                              7 => const OwnerTransactionHistoryScreen(),
                              8 => const SalesReportsScreen(),
                              9 => const PromotionsManagementScreen(),
                              10 => NotificationsScreen(
                                onOpenProducts: () {
                                  setState(() {
                                    _selectedIndex = 2;
                                  });
                                },
                                onOpenRestockSuggestions: () {
                                  setState(() {
                                    _selectedIndex = 3;
                                  });
                                },
                                onOpenStockMovements: () {
                                  setState(() {
                                    _selectedIndex = 4;
                                  });
                                },
                                onOpenPermitReminders: () {
                                  setState(() {
                                    _selectedIndex = 21;
                                  });
                                },
                              ),
                              11 => const ManageCashiersScreen(),
                              12 => const AuditTrailScreen(),
                              13 => const CustomerFeedbackScreen(),
                              14 => const BackupExportScreen(),
                              15 => const PromoSalesReportScreen(),
                              16 => const CashierPerformanceReportScreen(),
                              17 => const EstimatedProfitReportScreen(),
                              18 => const ProductMovementReportScreen(),
                              19 => const ServiceIssueLoggingScreen(
                                ownerView: true,
                              ),
                              20 => const ServiceMonitoringReportScreen(),
                              21 => const PermitRenewalReminderScreen(),
                              22 => const SalesComparisonScreen(),
                              23 => const ServiceIssueSummaryScreen(),
                              24 => const DailyOperationsSummaryScreen(),
                              25 => const ChangePasswordScreen(),
                              26 => const LoginActivityScreen(),
                              27 => const SettingsScreen(),
                              _ => _buildPlaceholderPage(),
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MenuItem {
  final String label;
  final IconData icon;

  const _MenuItem(this.label, this.icon);
}
