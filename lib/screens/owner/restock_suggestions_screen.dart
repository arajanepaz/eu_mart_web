import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _RestockHoverCard extends StatefulWidget {
  final Widget child;

  const _RestockHoverCard({required this.child});

  @override
  State<_RestockHoverCard> createState() => _RestockHoverCardState();
}

class _RestockHoverCardState extends State<_RestockHoverCard> {
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

class _RestockSuggestionCard extends StatefulWidget {
  final String productName;
  final String category;
  final String supplier;
  final int stock;
  final int soldLast30Days;
  final int suggestedQuantity;
  final String priority;
  final Color color;
  final IconData icon;

  const _RestockSuggestionCard({
    required this.productName,
    required this.category,
    required this.supplier,
    required this.stock,
    required this.soldLast30Days,
    required this.suggestedQuantity,
    required this.priority,
    required this.color,
    required this.icon,
  });

  @override
  State<_RestockSuggestionCard> createState() => _RestockSuggestionCardState();
}

class _RestockSuggestionCardState extends State<_RestockSuggestionCard> {
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
            final compact = constraints.maxWidth < 820;

            final productInfo = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: widget.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(widget.icon, color: widget.color, size: 27),
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
                              widget.productName,
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
                              widget.priority.toUpperCase(),
                              style: TextStyle(
                                color: widget.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.category.isNotEmpty ||
                          widget.supplier.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 7,
                          children: [
                            if (widget.category.isNotEmpty)
                              _RestockInfoPill(
                                icon: Icons.category_outlined,
                                label: widget.category,
                                color: const Color(0xFF1565C0),
                              ),
                            if (widget.supplier.isNotEmpty)
                              _RestockInfoPill(
                                icon: Icons.local_shipping_outlined,
                                label: widget.supplier,
                                color: const Color(0xFF7B1FA2),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );

            final metrics = Wrap(
              spacing: 9,
              runSpacing: 8,
              children: [
                _RestockMetricBox(
                  label: 'Current Stock',
                  value: '${widget.stock}',
                  color: widget.stock <= 0
                      ? const Color(0xFFD32F2F)
                      : const Color(0xFFF59E0B),
                ),
                _RestockMetricBox(
                  label: 'Sold in 30 Days',
                  value: '${widget.soldLast30Days}',
                  color: const Color(0xFF1565C0),
                ),
                _RestockMetricBox(
                  label: 'Suggested Restock',
                  value: '${widget.suggestedQuantity}',
                  color: const Color(0xFF159447),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [productInfo, const SizedBox(height: 14), metrics],
              );
            }

            return Row(
              children: [
                Expanded(flex: 4, child: productInfo),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: metrics,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RestockInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _RestockInfoPill({
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
            constraints: const BoxConstraints(maxWidth: 170),
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

class _RestockMetricBox extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _RestockMetricBox({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 118),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestockEmptyState extends StatelessWidget {
  const _RestockEmptyState();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 180;

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
                    Icons.inventory_outlined,
                    size: compact ? 42 : 60,
                    color: const Color(0xFFB8C5D5),
                  ),
                  SizedBox(height: compact ? 6 : 11),
                  Text(
                    'No restock suggestions found',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFF657386),
                      fontSize: compact ? 14 : 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    'Choose another priority filter or wait for new sales data.',
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

class RestockSuggestionsScreen extends StatefulWidget {
  const RestockSuggestionsScreen({super.key});

  @override
  State<RestockSuggestionsScreen> createState() =>
      _RestockSuggestionsScreenState();
}

class _RestockSuggestionsScreenState extends State<RestockSuggestionsScreen> {
  String _selectedFilter = 'All';

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _priority({
    required int stock,
    required int threshold,
    required int soldLast30Days,
  }) {
    if (stock <= 0) return 'Critical';
    if (stock <= threshold && soldLast30Days >= 10) return 'High';
    if (stock <= threshold) return 'Medium';
    if (soldLast30Days >= 20) return 'Monitor';
    return 'Normal';
  }

  int _suggestedQuantity({
    required int stock,
    required int threshold,
    required int soldLast30Days,
  }) {
    final targetStock = soldLast30Days > 0
        ? soldLast30Days + threshold
        : threshold * 2;

    final suggestion = targetStock - stock;

    return suggestion > 0 ? suggestion : 0;
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.deepOrange;
      case 'Medium':
        return Colors.orange;
      case 'Monitor':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  IconData _priorityIcon(String priority) {
    switch (priority) {
      case 'Critical':
        return Icons.error_outline;
      case 'High':
        return Icons.priority_high;
      case 'Medium':
        return Icons.warning_amber_rounded;
      case 'Monitor':
        return Icons.visibility_outlined;
      default:
        return Icons.check_circle_outline;
    }
  }

  bool _matchesFilter(String priority) {
    if (_selectedFilter == 'All') {
      return priority != 'Normal';
    }

    return priority == _selectedFilter;
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

  @override
  Widget build(BuildContext context) {
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
            if (productSnapshot.connectionState == ConnectionState.waiting &&
                !productSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productSnapshot.hasError) {
              return Center(
                child: Text(
                  'Unable to load products.\n'
                  '${productSnapshot.error}',
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

            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .snapshots(),
              builder: (context, transactionSnapshot) {
                if (transactionSnapshot.connectionState ==
                        ConnectionState.waiting &&
                    !transactionSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final transactions =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      transactionSnapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                    );

                final now = DateTime.now();
                final cutoff = now.subtract(const Duration(days: 30));

                final Map<String, int> salesByProductId = {};
                final Map<String, int> salesByProductName = {};

                for (final document in transactions) {
                  final data = document.data();

                  final status = (data['status'] ?? 'completed')
                      .toString()
                      .toLowerCase();

                  if (status == 'voided') continue;

                  final createdAt = _readDate(data['createdAt']);

                  if (createdAt == null || createdAt.isBefore(cutoff)) {
                    continue;
                  }

                  final items = data['items'] as List<dynamic>? ?? <dynamic>[];

                  for (final rawItem in items) {
                    if (rawItem is! Map) continue;

                    final item = Map<String, dynamic>.from(rawItem);

                    final productId = (item['productId'] ?? '').toString();

                    final productName = (item['productName'] ?? '')
                        .toString()
                        .toLowerCase();

                    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;

                    if (productId.isNotEmpty) {
                      salesByProductId[productId] =
                          (salesByProductId[productId] ?? 0) + quantity;
                    }

                    if (productName.isNotEmpty) {
                      salesByProductName[productName] =
                          (salesByProductName[productName] ?? 0) + quantity;
                    }
                  }
                }

                final suggestions = products
                    .map((document) {
                      final data = document.data();

                      final name = (data['productName'] ?? 'Unknown Product')
                          .toString();

                      final stock = (data['stock'] as num?)?.toInt() ?? 0;

                      final soldLast30Days =
                          salesByProductId[document.id] ??
                          salesByProductName[name.toLowerCase()] ??
                          0;

                      final priority = _priority(
                        stock: stock,
                        threshold: lowStockThreshold,
                        soldLast30Days: soldLast30Days,
                      );

                      return _RestockSuggestion(
                        documentId: document.id,
                        productName: name,
                        category: (data['category'] ?? '').toString(),
                        supplier: (data['supplier'] ?? '').toString(),
                        stock: stock,
                        soldLast30Days: soldLast30Days,
                        suggestedQuantity: _suggestedQuantity(
                          stock: stock,
                          threshold: lowStockThreshold,
                          soldLast30Days: soldLast30Days,
                        ),
                        priority: priority,
                      );
                    })
                    .where((suggestion) {
                      return _matchesFilter(suggestion.priority);
                    })
                    .toList();

                const priorityOrder = {
                  'Critical': 0,
                  'High': 1,
                  'Medium': 2,
                  'Monitor': 3,
                  'Normal': 4,
                };

                suggestions.sort((a, b) {
                  final priorityComparison = (priorityOrder[a.priority] ?? 99)
                      .compareTo(priorityOrder[b.priority] ?? 99);

                  if (priorityComparison != 0) {
                    return priorityComparison;
                  }

                  return b.soldLast30Days.compareTo(a.soldLast30Days);
                });

                final criticalCount = suggestions
                    .where((item) => item.priority == 'Critical')
                    .length;

                final highCount = suggestions
                    .where((item) => item.priority == 'High')
                    .length;

                final mediumCount = suggestions
                    .where((item) => item.priority == 'Medium')
                    .length;

                final monitorCount = suggestions
                    .where((item) => item.priority == 'Monitor')
                    .length;

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
                                  Icons.inventory_outlined,
                                  color: Colors.white,
                                  size: 29,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Restock Suggestions',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 23,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Review products that need restocking based '
                                        'on current stock and recent sales activity.',
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
                                    title: 'Critical',
                                    value: '$criticalCount',
                                    icon: Icons.error_outline,
                                    color: const Color(0xFFD32F2F),
                                  ),
                                  _summaryCard(
                                    title: 'High Priority',
                                    value: '$highCount',
                                    icon: Icons.priority_high,
                                    color: const Color(0xFFF57C00),
                                  ),
                                  _summaryCard(
                                    title: 'Medium Priority',
                                    value: '$mediumCount',
                                    icon: Icons.warning_amber_rounded,
                                    color: const Color(0xFFF59E0B),
                                  ),
                                  _summaryCard(
                                    title: 'Monitor',
                                    value: '$monitorCount',
                                    icon: Icons.visibility_outlined,
                                    color: const Color(0xFF1565C0),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          _RestockHoverCard(
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFEAF3FF),
                                    Color(0xFFF8FBFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(17),
                                border: Border.all(
                                  color: const Color(0xFFD7E7FA),
                                ),
                              ),
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  final compact = constraints.maxWidth < 700;

                                  final information = Row(
                                    children: [
                                      const CircleAvatar(
                                        radius: 22,
                                        backgroundColor: Color(0x1F1565C0),
                                        child: Icon(
                                          Icons.analytics_outlined,
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Suggestions use completed transactions '
                                          'from the last 30 days and the current '
                                          'low-stock threshold of '
                                          '$lowStockThreshold unit(s).',
                                          style: const TextStyle(
                                            color: Color(0xFF53657C),
                                            fontWeight: FontWeight.w700,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ],
                                  );

                                  final badge = Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 11,
                                      vertical: 7,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF8F0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.auto_awesome_outlined,
                                          size: 17,
                                          color: Color(0xFF168653),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'AUTO-CALCULATED',
                                          style: TextStyle(
                                            color: Color(0xFF168653),
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );

                                  if (compact) {
                                    return Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        information,
                                        const SizedBox(height: 12),
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: badge,
                                        ),
                                      ],
                                    );
                                  }

                                  return Row(
                                    children: [
                                      Expanded(child: information),
                                      const SizedBox(width: 14),
                                      badge,
                                    ],
                                  );
                                },
                              ),
                            ),
                          ),
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
                              border: Border.all(
                                color: const Color(0xFFDDE6F1),
                              ),
                            ),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _filterChip('All'),
                                  const SizedBox(width: 8),
                                  _filterChip('Critical'),
                                  const SizedBox(width: 8),
                                  _filterChip('High'),
                                  const SizedBox(width: 8),
                                  _filterChip('Medium'),
                                  const SizedBox(width: 8),
                                  _filterChip('Monitor'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Recommended Restocks',
                                      style: TextStyle(
                                        color: Color(0xFF172033),
                                        fontSize: 21,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Products are ordered by urgency and recent demand.',
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
                          const SizedBox(height: 12),
                          if (suggestions.isEmpty)
                            const SizedBox(
                              height: 240,
                              child: _RestockEmptyState(),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: suggestions.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final suggestion = suggestions[index];

                                return ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 128,
                                  ),
                                  child: _RestockSuggestionCard(
                                    productName: suggestion.productName,
                                    category: suggestion.category,
                                    supplier: suggestion.supplier,
                                    stock: suggestion.stock,
                                    soldLast30Days: suggestion.soldLast30Days,
                                    suggestedQuantity:
                                        suggestion.suggestedQuantity,
                                    priority: suggestion.priority,
                                    color: _priorityColor(suggestion.priority),
                                    icon: _priorityIcon(suggestion.priority),
                                  ),
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
          },
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
    return _RestockHoverCard(
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

class _RestockSuggestion {
  final String documentId;
  final String productName;
  final String category;
  final String supplier;
  final int stock;
  final int soldLast30Days;
  final int suggestedQuantity;
  final String priority;

  const _RestockSuggestion({
    required this.documentId,
    required this.productName,
    required this.category,
    required this.supplier,
    required this.stock,
    required this.soldLast30Days,
    required this.suggestedQuantity,
    required this.priority,
  });
}
