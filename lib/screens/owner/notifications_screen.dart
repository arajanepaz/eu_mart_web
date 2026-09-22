import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  final VoidCallback? onOpenProducts;
  final VoidCallback? onOpenRestockSuggestions;
  final VoidCallback? onOpenStockMovements;
  final VoidCallback? onOpenPermitReminders;

  const NotificationsScreen({
    super.key,
    this.onOpenProducts,
    this.onOpenRestockSuggestions,
    this.onOpenStockMovements,
    this.onOpenPermitReminders,
  });

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedFilter = 'All';

  int _lowStockThreshold = 10;
  int _expirationAlertDays = 30;
  bool _enableLowStockAlerts = true;
  bool _enableExpirationAlerts = true;

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  double _readDouble(dynamic value) {
    if (value is num) return value.toDouble();

    if (value is String) {
      return double.tryParse(value) ?? 0;
    }

    return 0;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'No date';

    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }

  String _formatPrice(double value) {
    return '₱${value.toStringAsFixed(2)}';
  }

  int _daysUntil(DateTime? date) {
    if (date == null) return 999999;

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);

    final target = DateTime(date.year, date.month, date.day);

    return target.difference(today).inDays;
  }

  String _productType(Map<String, dynamic> data) {
    final stock = (data['stock'] as num?)?.toInt() ?? 0;

    final expirationDate = _readDate(data['expirationDate']);

    if (stock <= 0) {
      return 'Out of Stock';
    }

    if (_enableExpirationAlerts && expirationDate != null) {
      final days = _daysUntil(expirationDate);

      if (days < 0) {
        return 'Expired';
      }

      if (days <= _expirationAlertDays) {
        return 'Expiring Soon';
      }
    }

    if (_enableLowStockAlerts && stock <= _lowStockThreshold) {
      return 'Low Stock';
    }

    return 'Normal';
  }

  String _permitType(Map<String, dynamic> data) {
    if (data['renewed'] == true) {
      return 'Normal';
    }

    final expirationDate = _readDate(data['expirationDate']);

    final reminderDays = (data['reminderDays'] as num?)?.toInt() ?? 30;

    final days = _daysUntil(expirationDate);

    if (days < 0) {
      return 'Permit Expired';
    }

    if (days <= reminderDays) {
      return 'Permit Due Soon';
    }

    return 'Normal';
  }

  bool _matchesFilter(String type) {
    if (_selectedFilter == 'All') {
      return type != 'Normal';
    }

    return type == _selectedFilter;
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'Out of Stock':
      case 'Permit Expired':
        return Colors.red;

      case 'Expired':
        return Colors.deepOrange;

      case 'Expiring Soon':
      case 'Permit Due Soon':
        return Colors.orange;

      case 'Low Stock':
        return Colors.amber.shade800;

      case 'Price Update':
        return const Color(0xFF7B1FA2);

      default:
        return Colors.blueGrey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'Out of Stock':
        return Icons.remove_shopping_cart_outlined;

      case 'Low Stock':
        return Icons.inventory_2_outlined;

      case 'Expired':
        return Icons.event_busy_outlined;

      case 'Expiring Soon':
        return Icons.event_outlined;

      case 'Permit Expired':
        return Icons.assignment_late_outlined;

      case 'Permit Due Soon':
        return Icons.description_outlined;

      case 'Price Update':
        return Icons.price_change_outlined;

      default:
        return Icons.notifications_none;
    }
  }

  String _readDocumentId(_UnifiedAlert alert) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';

    final safeType = alert.type.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '_',
    );

    return '${userId}_${alert.source}_${alert.documentId}_$safeType';
  }

  Future<void> _markAsRead(_UnifiedAlert alert) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    await FirebaseFirestore.instance
        .collection('notification_reads')
        .doc(_readDocumentId(alert))
        .set({
          'userId': user.uid,
          'source': alert.source,
          'sourceId': alert.documentId,
          'notificationType': alert.type,
          'isRead': true,
          'readAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _markAllAsRead(List<_UnifiedAlert> alerts) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || alerts.isEmpty) {
      return;
    }

    final batch = FirebaseFirestore.instance.batch();

    for (final alert in alerts) {
      final reference = FirebaseFirestore.instance
          .collection('notification_reads')
          .doc(_readDocumentId(alert));

      batch.set(reference, {
        'userId': user.uid,
        'source': alert.source,
        'sourceId': alert.documentId,
        'notificationType': alert.type,
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    await batch.commit();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All current alerts marked as read.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _openAlert(_UnifiedAlert alert) async {
    await _markAsRead(alert);

    if (!mounted) return;

    if (alert.type == 'Price Update') {
      await _showPriceComparison(alert);
      return;
    }

    switch (alert.type) {
      case 'Out of Stock':
      case 'Low Stock':
        widget.onOpenRestockSuggestions?.call();
        break;

      case 'Expired':
        widget.onOpenStockMovements?.call();
        break;

      case 'Expiring Soon':
        widget.onOpenProducts?.call();
        break;

      case 'Permit Expired':
      case 'Permit Due Soon':
        widget.onOpenPermitReminders?.call();
        break;
    }
  }

  Future<void> _showPriceComparison(_UnifiedAlert alert) async {
    if (!mounted) return;

    final oldPrice = alert.oldBuyingPrice ?? 0;

    final newPrice = alert.newBuyingPrice ?? 0;

    final sellingPrice = alert.currentSellingPrice ?? 0;

    final difference = newPrice - oldPrice;

    final isIncrease = difference > 0;

    final isDecrease = difference < 0;

    final changeColor = isIncrease
        ? Colors.red
        : isDecrease
        ? Colors.green
        : Colors.blueGrey;

    final changeIcon = isIncrease
        ? Icons.arrow_upward_rounded
        : isDecrease
        ? Icons.arrow_downward_rounded
        : Icons.remove_rounded;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 700),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF7B1FA2,
                          ).withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: const Icon(
                          Icons.compare_arrows_rounded,
                          color: Color(0xFF7B1FA2),
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Price Update Comparison',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF172033),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Review the previous and updated buying price.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF7A8494),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF7F9FC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE1E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PRODUCT',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF8A94A3),
                            letterSpacing: 0.7,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          alert.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF172033),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: _PriceComparisonBox(
                          label: 'Previous Buying Price',
                          value: _formatPrice(oldPrice),
                          color: Colors.blueGrey,
                          icon: Icons.history_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PriceComparisonBox(
                          label: 'New Buying Price',
                          value: _formatPrice(newPrice),
                          color: const Color(0xFF7B1FA2),
                          icon: Icons.price_change_outlined,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 15,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: changeColor.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: changeColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(changeIcon, color: changeColor, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'PRICE CHANGE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF8A94A3),
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                difference == 0
                                    ? 'No change'
                                    : '${isIncrease ? '+' : ''}${_formatPrice(difference)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: changeColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          isIncrease
                              ? 'INCREASE'
                              : isDecrease
                              ? 'DECREASE'
                              : 'UNCHANGED',
                          style: TextStyle(
                            color: changeColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  _ComparisonDetailRow(
                    icon: Icons.sell_outlined,
                    label: 'Current Selling Price',
                    value: _formatPrice(sellingPrice),
                  ),

                  const SizedBox(height: 9),

                  _ComparisonDetailRow(
                    icon: Icons.info_outline_rounded,
                    label: 'Status',
                    value: alert.status ?? 'Pending Review',
                  ),

                  const SizedBox(height: 9),

                  _ComparisonDetailRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Updated',
                    value: _formatDate(alert.relevantDate),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
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
    required int value,
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
      child: _NotificationSummaryCard(
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withValues(alpha: 0.72)],
                  ),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.20),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 23),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A8494),
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$value',
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

  List<_UnifiedAlert> _buildAlerts({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> products,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> permits,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> priceUpdates,
  }) {
    final alerts = <_UnifiedAlert>[];

    // ============================================================
    // PRODUCT ALERTS
    // ============================================================

    for (final document in products) {
      final data = document.data();

      final type = _productType(data);

      if (type == 'Normal') {
        continue;
      }

      final productName = (data['productName'] ?? 'Unknown Product').toString();

      final stock = (data['stock'] as num?)?.toInt() ?? 0;

      final expirationDate = _readDate(data['expirationDate']);

      String description;

      switch (type) {
        case 'Out of Stock':
          description = '$productName has no available stock.';
          break;

        case 'Low Stock':
          description = '$productName has only $stock item(s) remaining.';
          break;

        case 'Expired':
          description =
              '$productName expired on '
              '${_formatDate(expirationDate)}.';
          break;

        default:
          description =
              '$productName will expire on '
              '${_formatDate(expirationDate)}.';
      }

      alerts.add(
        _UnifiedAlert(
          documentId: document.id,
          source: 'product',
          title: productName,
          subtitle: (data['category'] ?? 'Product Alert').toString(),
          type: type,
          description: description,
          relevantDate: expirationDate,
        ),
      );
    }

    // ============================================================
    // PERMIT ALERTS
    // ============================================================

    for (final document in permits) {
      final data = document.data();

      final type = _permitType(data);

      if (type == 'Normal') {
        continue;
      }

      final permitName = (data['permitName'] ?? 'Unnamed Permit').toString();

      final expirationDate = _readDate(data['expirationDate']);

      final days = _daysUntil(expirationDate);

      final description = type == 'Permit Expired'
          ? '$permitName expired on '
                '${_formatDate(expirationDate)} '
                'and is ${days.abs()} day(s) overdue.'
          : '$permitName expires on '
                '${_formatDate(expirationDate)} '
                'with $days day(s) remaining.';

      alerts.add(
        _UnifiedAlert(
          documentId: document.id,
          source: 'permit',
          title: permitName,
          subtitle: (data['issuingOffice'] ?? 'Business Permit').toString(),
          type: type,
          description: description,
          relevantDate: expirationDate,
        ),
      );
    }

    // ============================================================
    // PRICE UPDATE REMINDERS
    // ============================================================

    for (final document in priceUpdates) {
      final data = document.data();

      final productName = (data['productName'] ?? 'Unknown Product').toString();

      final oldBuyingPrice = _readDouble(data['oldBuyingPrice']);

      final newBuyingPrice = _readDouble(data['newBuyingPrice']);

      final currentSellingPrice = _readDouble(data['currentSellingPrice']);

      final status = (data['status'] ?? 'Pending Review').toString();

      final createdAt = _readDate(data['createdAt']);

      final difference = newBuyingPrice - oldBuyingPrice;

      String description;

      if (difference > 0) {
        description =
            '$productName buying price increased from '
            '${_formatPrice(oldBuyingPrice)} to '
            '${_formatPrice(newBuyingPrice)}.';
      } else if (difference < 0) {
        description =
            '$productName buying price decreased from '
            '${_formatPrice(oldBuyingPrice)} to '
            '${_formatPrice(newBuyingPrice)}.';
      } else {
        description =
            '$productName buying price was updated '
            'without a price difference.';
      }

      alerts.add(
        _UnifiedAlert(
          documentId: document.id,
          source: 'price_update_reminder',
          title: productName,
          subtitle: 'Price Update Reminder',
          type: 'Price Update',
          description: description,
          relevantDate: createdAt,
          oldBuyingPrice: oldBuyingPrice,
          newBuyingPrice: newBuyingPrice,
          currentSellingPrice: currentSellingPrice,
          status: status,
        ),
      );
    }

    // ============================================================
    // ALERT PRIORITY
    // ============================================================

    const priority = {
      'Price Update': 0,
      'Permit Expired': 1,
      'Expired': 2,
      'Out of Stock': 3,
      'Permit Due Soon': 4,
      'Expiring Soon': 5,
      'Low Stock': 6,
    };

    alerts.sort((a, b) {
      final typeComparison = (priority[a.type] ?? 99).compareTo(
        priority[b.type] ?? 99,
      );

      if (typeComparison != 0) {
        return typeComparison;
      }

      final aDate = a.relevantDate;

      final bDate = b.relevantDate;

      if (aDate != null && bDate != null) {
        final dateComparison = bDate.compareTo(aDate);

        if (dateComparison != 0) {
          return dateComparison;
        }
      }

      return a.title.toLowerCase().compareTo(b.title.toLowerCase());
    });

    return alerts;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('settings')
          .doc('system')
          .snapshots(),
      builder: (context, settingsSnapshot) {
        final settings = settingsSnapshot.data?.data() ?? <String, dynamic>{};

        _lowStockThreshold =
            (settings['lowStockThreshold'] as num?)?.toInt() ?? 10;

        _expirationAlertDays =
            (settings['expirationAlertDays'] as num?)?.toInt() ?? 30;

        _enableLowStockAlerts = settings['enableLowStockAlerts'] != false;

        _enableExpirationAlerts = settings['enableExpirationAlerts'] != false;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('products').snapshots(),
          builder: (context, productSnapshot) {
            if (productSnapshot.connectionState == ConnectionState.waiting &&
                !productSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productSnapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load product alerts.\n'
                  '${productSnapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('permit_reminders')
                  .snapshots(),
              builder: (context, permitSnapshot) {
                if (permitSnapshot.connectionState == ConnectionState.waiting &&
                    !permitSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (permitSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load permit alerts.\n'
                      '${permitSnapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('price_update_reminders')
                      .snapshots(),
                  builder: (context, priceUpdateSnapshot) {
                    if (priceUpdateSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !priceUpdateSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (priceUpdateSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'Unable to load price update reminders.\n'
                          '${priceUpdateSnapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final products =
                        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                          productSnapshot.data?.docs ??
                              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                        );

                    final permits =
                        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                          permitSnapshot.data?.docs ??
                              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                        );

                    final priceUpdates =
                        List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                          priceUpdateSnapshot.data?.docs ??
                              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                        );

                    final allAlerts = _buildAlerts(
                      products: products,
                      permits: permits,
                      priceUpdates: priceUpdates,
                    );

                    final filteredAlerts = allAlerts
                        .where((alert) => _matchesFilter(alert.type))
                        .toList();

                    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: userId.isEmpty
                          ? null
                          : FirebaseFirestore.instance
                                .collection('notification_reads')
                                .where('userId', isEqualTo: userId)
                                .snapshots(),
                      builder: (context, readSnapshot) {
                        final readIds = <String>{};

                        for (final document
                            in readSnapshot.data?.docs ??
                                <
                                  QueryDocumentSnapshot<Map<String, dynamic>>
                                >[]) {
                          if (document.data()['isRead'] == true) {
                            readIds.add(document.id);
                          }
                        }

                        final unreadCount = allAlerts
                            .where(
                              (alert) =>
                                  !readIds.contains(_readDocumentId(alert)),
                            )
                            .length;

                        // ====================================================
                        // FIX:
                        // The entire notification dashboard is scrollable.
                        // This prevents RenderFlex bottom overflow.
                        // ====================================================

                        return Container(
                          color: const Color(0xFFF2F6FC),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(22),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ==================================================
                                // HEADER
                                // ==================================================
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
                                      colors: [
                                        Color(0xFF0D47A1),
                                        Color(0xFF1976D2),
                                      ],
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
                                      final compact =
                                          constraints.maxWidth < 700;

                                      final heading = Row(
                                        children: [
                                          const Icon(
                                            Icons.notifications_active_outlined,
                                            color: Colors.white,
                                            size: 28,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text(
                                                  'Notification Dashboard',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 23,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '$unreadCount unread alert(s) requiring attention.',
                                                  style: const TextStyle(
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
                                        onPressed: allAlerts.isEmpty
                                            ? null
                                            : () => _markAllAsRead(allAlerts),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.white,
                                          foregroundColor: const Color(
                                            0xFF1565C0,
                                          ),
                                          disabledBackgroundColor:
                                              Colors.white54,
                                          elevation: 0,
                                          minimumSize: const Size(175, 46),
                                        ),
                                        icon: const Icon(Icons.done_all),
                                        label: const Text(
                                          'MARK ALL AS READ',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      );

                                      if (compact) {
                                        return Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            heading,
                                            const SizedBox(height: 16),
                                            action,
                                          ],
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

                                const SizedBox(height: 18),

                                // ==================================================
                                // SUMMARY CARDS
                                // ==================================================
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    int count = 5;

                                    if (constraints.maxWidth < 1150) {
                                      count = 2;
                                    }

                                    if (constraints.maxWidth < 620) {
                                      count = 1;
                                    }

                                    return GridView.count(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      crossAxisCount: count,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 14,
                                      childAspectRatio: count == 5
                                          ? 2.05
                                          : count == 2
                                          ? 3.2
                                          : 4.0,
                                      children: [
                                        _summaryCard(
                                          title: 'Product Alerts',
                                          value: allAlerts
                                              .where(
                                                (alert) =>
                                                    alert.source == 'product',
                                              )
                                              .length,
                                          icon: Icons.inventory_2_outlined,
                                          color: Colors.orange,
                                        ),
                                        _summaryCard(
                                          title: 'Permit Alerts',
                                          value: allAlerts
                                              .where(
                                                (alert) =>
                                                    alert.source == 'permit',
                                              )
                                              .length,
                                          icon: Icons.description_outlined,
                                          color: Colors.red,
                                        ),
                                        _summaryCard(
                                          title: 'Price Updates',
                                          value: allAlerts
                                              .where(
                                                (alert) =>
                                                    alert.type ==
                                                    'Price Update',
                                              )
                                              .length,
                                          icon: Icons.price_change_outlined,
                                          color: const Color(0xFF7B1FA2),
                                        ),
                                        _summaryCard(
                                          title: 'Unread',
                                          value: unreadCount,
                                          icon:
                                              Icons.mark_email_unread_outlined,
                                          color: const Color(0xFF1565C0),
                                        ),
                                        _summaryCard(
                                          title: 'Total Alerts',
                                          value: allAlerts.length,
                                          icon: Icons
                                              .notifications_active_outlined,
                                          color: Colors.purple,
                                        ),
                                      ],
                                    );
                                  },
                                ),

                                const SizedBox(height: 18),

                                // ==================================================
                                // FILTERS
                                // ==================================================
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _filterChip('All'),
                                      const SizedBox(width: 8),
                                      _filterChip('Price Update'),
                                      const SizedBox(width: 8),
                                      _filterChip('Out of Stock'),
                                      const SizedBox(width: 8),
                                      _filterChip('Low Stock'),
                                      const SizedBox(width: 8),
                                      _filterChip('Expired'),
                                      const SizedBox(width: 8),
                                      _filterChip('Expiring Soon'),
                                      const SizedBox(width: 8),
                                      _filterChip('Permit Expired'),
                                      const SizedBox(width: 8),
                                      _filterChip('Permit Due Soon'),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 18),

                                // ==================================================
                                // ALERT LIST
                                // ==================================================
                                if (filteredAlerts.isEmpty)
                                  const SizedBox(
                                    height: 300,
                                    child: _NotificationEmptyState(),
                                  )
                                else
                                  ListView.separated(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: filteredAlerts.length,
                                    separatorBuilder: (_, _) =>
                                        const SizedBox(height: 10),
                                    itemBuilder: (context, index) {
                                      final alert = filteredAlerts[index];

                                      final isRead = readIds.contains(
                                        _readDocumentId(alert),
                                      );

                                      final color = _typeColor(alert.type);

                                      final isPriceUpdate =
                                          alert.type == 'Price Update';

                                      return _NotificationAlertCard(
                                        color: color,
                                        unread: !isRead,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 5,
                                          ),
                                          child: ListTile(
                                            onTap: () => _openAlert(alert),
                                            leading: CircleAvatar(
                                              backgroundColor: color.withValues(
                                                alpha: 0.12,
                                              ),
                                              child: Icon(
                                                _typeIcon(alert.type),
                                                color: color,
                                              ),
                                            ),
                                            title: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    alert.title,
                                                    style: TextStyle(
                                                      fontWeight: isRead
                                                          ? FontWeight.w600
                                                          : FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 10,
                                                        vertical: 5,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: color.withValues(
                                                      alpha: 0.12,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    alert.type,
                                                    style: TextStyle(
                                                      color: color,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            subtitle: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 4,
                                              ),
                                              child: Text(
                                                '${alert.subtitle}\n'
                                                '${alert.description}',
                                              ),
                                            ),
                                            isThreeLine: true,
                                            trailing: isPriceUpdate
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      OutlinedButton.icon(
                                                        onPressed: () =>
                                                            _showPriceComparison(
                                                              alert,
                                                            ),
                                                        style: OutlinedButton.styleFrom(
                                                          foregroundColor:
                                                              const Color(
                                                                0xFF7B1FA2,
                                                              ),
                                                          side:
                                                              const BorderSide(
                                                                color: Color(
                                                                  0xFF7B1FA2,
                                                                ),
                                                              ),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                        icon: const Icon(
                                                          Icons
                                                              .compare_arrows_rounded,
                                                          size: 17,
                                                        ),
                                                        label: const Text(
                                                          'COMPARE',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      isRead
                                                          ? const Icon(
                                                              Icons.done_all,
                                                              color:
                                                                  Colors.green,
                                                            )
                                                          : const Icon(
                                                              Icons.circle,
                                                              size: 11,
                                                              color: Color(
                                                                0xFF1565C0,
                                                              ),
                                                            ),
                                                    ],
                                                  )
                                                : isRead
                                                ? const Icon(
                                                    Icons.done_all,
                                                    color: Colors.green,
                                                  )
                                                : const Icon(
                                                    Icons.circle,
                                                    size: 11,
                                                    color: Color(0xFF1565C0),
                                                  ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),

                                const SizedBox(height: 22),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}

// ================================================================
// PRICE COMPARISON BOX
// ================================================================

class _PriceComparisonBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _PriceComparisonBox({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(height: 9),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF7A8494),
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// COMPARISON DETAIL ROW
// ================================================================

class _ComparisonDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ComparisonDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Icon(icon, size: 19, color: const Color(0xFF6F7C8E)),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF687588),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================================================
// SUMMARY CARD
// ================================================================

class _NotificationSummaryCard extends StatefulWidget {
  final Widget child;

  const _NotificationSummaryCard({required this.child});

  @override
  State<_NotificationSummaryCard> createState() =>
      _NotificationSummaryCardState();
}

class _NotificationSummaryCardState extends State<_NotificationSummaryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
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

// ================================================================
// ALERT CARD
// ================================================================

class _NotificationAlertCard extends StatefulWidget {
  final Color color;
  final bool unread;
  final Widget child;

  const _NotificationAlertCard({
    required this.color,
    required this.unread,
    required this.child,
  });

  @override
  State<_NotificationAlertCard> createState() => _NotificationAlertCardState();
}

class _NotificationAlertCardState extends State<_NotificationAlertCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() {
          _hovered = true;
        });
      },
      onExit: (_) {
        setState(() {
          _hovered = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: widget.unread
                ? [
                    const Color(0xFFF4F9FF),
                    widget.color.withValues(alpha: 0.035),
                  ]
                : const [Colors.white, Color(0xFFFBFDFF)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: widget.unread
                ? widget.color.withValues(alpha: 0.30)
                : _hovered
                ? const Color(0xFFB9D6F8)
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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Material(color: Colors.transparent, child: widget.child),
        ),
      ),
    );
  }
}

// ================================================================
// EMPTY STATE
// ================================================================

class _NotificationEmptyState extends StatelessWidget {
  const _NotificationEmptyState();

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
              Icons.notifications_none_rounded,
              size: 62,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No alerts found',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'There are no alerts under this filter.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// UNIFIED ALERT MODEL
// ================================================================

class _UnifiedAlert {
  final String documentId;
  final String source;
  final String title;
  final String subtitle;
  final String type;
  final String description;
  final DateTime? relevantDate;

  final double? oldBuyingPrice;
  final double? newBuyingPrice;
  final double? currentSellingPrice;
  final String? status;

  const _UnifiedAlert({
    required this.documentId,
    required this.source,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.description,
    required this.relevantDate,
    this.oldBuyingPrice,
    this.newBuyingPrice,
    this.currentSellingPrice,
    this.status,
  });
}
