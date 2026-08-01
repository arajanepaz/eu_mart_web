import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class _PromoHoverCard extends StatefulWidget {
  final Widget child;

  const _PromoHoverCard({required this.child});

  @override
  State<_PromoHoverCard> createState() => _PromoHoverCardState();
}

class _PromoHoverCardState extends State<_PromoHoverCard> {
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

class _PromoProductCard extends StatefulWidget {
  final String productName;
  final double regularPrice;
  final double? promoPrice;
  final String promoType;
  final String promoLabel;
  final bool active;
  final String startDate;
  final String endDate;
  final VoidCallback onEdit;
  final VoidCallback? onDisable;

  const _PromoProductCard({
    required this.productName,
    required this.regularPrice,
    required this.promoPrice,
    required this.promoType,
    required this.promoLabel,
    required this.active,
    required this.startDate,
    required this.endDate,
    required this.onEdit,
    required this.onDisable,
  });

  @override
  State<_PromoProductCard> createState() => _PromoProductCardState();
}

class _PromoProductCardState extends State<_PromoProductCard> {
  bool _hovered = false;

  Color get _accent {
    if (!widget.active) {
      return const Color(0xFF8A95A4);
    }

    return switch (widget.promoType) {
      'Buy 1 Take 1' => const Color(0xFF7B1FA2),
      'Near-Expiry' => const Color(0xFFF59E0B),
      _ => const Color(0xFF159447),
    };
  }

  IconData get _icon {
    return switch (widget.promoType) {
      'Buy 1 Take 1' => Icons.redeem_outlined,
      'Near-Expiry' => Icons.schedule_outlined,
      _ => Icons.percent_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, accent.withValues(alpha: 0.035)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered
                ? accent.withValues(alpha: 0.35)
                : accent.withValues(alpha: 0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? const Color(0x2016385A)
                  : const Color(0x0F16385A),
              blurRadius: _hovered ? 20 : 11,
              offset: Offset(0, _hovered ? 9 : 5),
            ),
          ],
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
                    color: accent.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(_icon, color: accent, size: 25),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.active ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: accent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              widget.productName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 17,
                fontWeight: FontWeight.w900,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.active ? widget.promoLabel : 'No active promotion',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: widget.active ? accent : const Color(0xFF8A95A4),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.active &&
                widget.promoType != 'Buy 1 Take 1' &&
                widget.promoPrice != null)
              Row(
                children: [
                  Text(
                    '₱${widget.regularPrice.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Color(0xFF9AA5B3),
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '₱${widget.promoPrice!.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: accent,
                      fontSize: 21,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              )
            else if (widget.active)
              Text(
                widget.promoType,
                style: TextStyle(
                  color: accent,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              )
            else
              Text(
                'Regular: ₱${widget.regularPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Color(0xFF607086),
                  fontWeight: FontWeight.w700,
                ),
              ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.date_range_outlined,
                    size: 16,
                    color: Color(0xFF7A8494),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '${widget.startDate} to ${widget.endDate}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF7A8494),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(widget.active ? 'EDIT PROMO' : 'SET PROMO'),
                  ),
                ),
                if (widget.onDisable != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Disable promo',
                    onPressed: widget.onDisable,
                    icon: const Icon(Icons.block_rounded, color: Colors.red),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PromoEmptyState extends StatelessWidget {
  const _PromoEmptyState();

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
              Icons.local_offer_outlined,
              size: 62,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No promotions found',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Try another search or promotion filter.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}

class PromotionsManagementScreen extends StatefulWidget {
  const PromotionsManagementScreen({super.key});

  @override
  State<PromotionsManagementScreen> createState() =>
      _PromotionsManagementScreenState();
}

class _PromotionsManagementScreenState
    extends State<PromotionsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';

    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  bool _isPromoActive(Map<String, dynamic> data) {
    if (data['promoActive'] != true) return false;

    final endDate = _readDate(data['promoEndDate']);

    if (endDate == null) return true;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    return !normalizedEnd.isBefore(today);
  }

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final searchable = [
      data['productName'],
      data['category'],
      data['brand'],
      data['promoType'],
      data['promoLabel'],
    ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

    return searchable.contains(_searchQuery);
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    if (_selectedFilter == 'All') return true;

    final active = _isPromoActive(data);

    if (_selectedFilter == 'Active') return active;
    if (_selectedFilter == 'Inactive') return !active;

    return (data['promoType'] ?? '').toString() == _selectedFilter;
  }

  Future<void> _showPromoDialog(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data() ?? <String, dynamic>{};

    String promoType = (data['promoType'] ?? 'Discount').toString();

    if (!['Discount', 'Buy 1 Take 1', 'Near-Expiry'].contains(promoType)) {
      promoType = 'Discount';
    }

    final promoPriceController = TextEditingController(
      text: (data['promoPrice'] as num?)?.toString() ?? '',
    );

    final promoLabelController = TextEditingController(
      text: (data['promoLabel'] ?? '').toString(),
    );

    DateTime? startDate = _readDate(data['promoStartDate']);
    DateTime? endDate = _readDate(data['promoEndDate']);
    bool saving = false;

    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> pickStartDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate: startDate ?? DateTime.now(),
                firstDate: DateTime(2024),
                lastDate: DateTime(2035),
              );

              if (picked != null) {
                setDialogState(() => startDate = picked);
              }
            }

            Future<void> pickEndDate() async {
              final picked = await showDatePicker(
                context: dialogContext,
                initialDate:
                    endDate ??
                    startDate ??
                    DateTime.now().add(const Duration(days: 7)),
                firstDate: startDate ?? DateTime.now(),
                lastDate: DateTime(2035),
              );

              if (picked != null) {
                setDialogState(() => endDate = picked);
              }
            }

            Future<void> savePromo() async {
              double? promoPrice;

              if (promoType == 'Discount' || promoType == 'Near-Expiry') {
                promoPrice = double.tryParse(promoPriceController.text.trim());

                final regularPrice =
                    (data['sellingPrice'] as num?)?.toDouble() ?? 0;

                if (promoPrice == null ||
                    promoPrice <= 0 ||
                    promoPrice >= regularPrice) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Promo price must be greater than zero '
                        'and lower than the regular price.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
              }

              if (startDate != null &&
                  endDate != null &&
                  endDate!.isBefore(startDate!)) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Promo end date cannot be earlier '
                      'than the start date.',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                await document.reference.update({
                  'promoActive': true,
                  'promoType': promoType,
                  'promoPrice': promoType == 'Buy 1 Take 1' ? null : promoPrice,
                  'promoLabel': promoLabelController.text.trim().isEmpty
                      ? promoType
                      : promoLabelController.text.trim(),
                  'promoStartDate': startDate == null
                      ? null
                      : Timestamp.fromDate(startDate!),
                  'promoEndDate': endDate == null
                      ? null
                      : Timestamp.fromDate(endDate!),
                  'updatedAt': FieldValue.serverTimestamp(),
                });

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext, true);
              } catch (error) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Unable to save promo: $error'),
                    backgroundColor: Colors.red,
                  ),
                );

                setDialogState(() => saving = false);
              }
            }

            return AlertDialog(
              title: Text(
                'Set Promo — '
                '${(data['productName'] ?? 'Product')}',
              ),
              content: SizedBox(
                width: 520,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: promoType,
                      decoration: const InputDecoration(
                        labelText: 'Promo Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Discount',
                          child: Text('Discount'),
                        ),
                        DropdownMenuItem(
                          value: 'Buy 1 Take 1',
                          child: Text('Buy 1 Take 1'),
                        ),
                        DropdownMenuItem(
                          value: 'Near-Expiry',
                          child: Text('Near-Expiry Promo'),
                        ),
                      ],
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value == null) return;

                              setDialogState(() {
                                promoType = value;
                              });
                            },
                    ),
                    const SizedBox(height: 16),
                    if (promoType != 'Buy 1 Take 1')
                      TextField(
                        controller: promoPriceController,
                        enabled: !saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Promo Price',
                          prefixText: '₱ ',
                          helperText:
                              'Regular price: ₱${((data['sellingPrice'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    if (promoType != 'Buy 1 Take 1') const SizedBox(height: 16),
                    TextField(
                      controller: promoLabelController,
                      enabled: !saving,
                      decoration: const InputDecoration(
                        labelText: 'Promo Label',
                        hintText: 'Example: Weekend Sale or Save ₱10',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: saving ? null : pickStartDate,
                            icon: const Icon(Icons.calendar_today_outlined),
                            label: Text('Start: ${_formatDate(startDate)}'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: saving ? null : pickEndDate,
                            icon: const Icon(Icons.event_outlined),
                            label: Text('End: ${_formatDate(endDate)}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : savePromo,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.local_offer_outlined),
                  label: Text(saving ? 'SAVING...' : 'SAVE PROMO'),
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
          content: Text('Product promotion saved.'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _disablePromo(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    try {
      await document.reference.update({
        'promoActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product promotion disabled.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to disable promo: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
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
        setState(() => _selectedFilter = label);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Unable to load promotions.\n${snapshot.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final products = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
          snapshot.data?.docs ??
              <QueryDocumentSnapshot<Map<String, dynamic>>>[],
        );

        products.sort((a, b) {
          final first = (a.data()['productName'] ?? '')
              .toString()
              .toLowerCase();
          final second = (b.data()['productName'] ?? '')
              .toString()
              .toLowerCase();

          return first.compareTo(second);
        });

        final activeCount = products.where((document) {
          return _isPromoActive(document.data());
        }).length;

        final discountCount = products.where((document) {
          final data = document.data();
          return _isPromoActive(data) &&
              (data['promoType'] ?? '').toString() == 'Discount';
        }).length;

        final b1t1Count = products.where((document) {
          final data = document.data();
          return _isPromoActive(data) &&
              (data['promoType'] ?? '').toString() == 'Buy 1 Take 1';
        }).length;

        final nearExpiryCount = products.where((document) {
          final data = document.data();
          return _isPromoActive(data) &&
              (data['promoType'] ?? '').toString() == 'Near-Expiry';
        }).length;

        final filtered = products.where((document) {
          final data = document.data();
          return _matchesSearch(data) && _matchesFilter(data);
        }).toList();

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
                      Icons.local_offer_outlined,
                      color: Colors.white,
                      size: 29,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Promotions Management',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Create and manage discounts, '
                            'Buy 1 Take 1, and near-expiry promotions.',
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
                  if (constraints.maxWidth < 1050) count = 2;
                  if (constraints.maxWidth < 620) count = 1;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: count,
                    crossAxisSpacing: 13,
                    mainAxisSpacing: 13,
                    childAspectRatio: count == 4 ? 2.25 : 3.1,
                    children: [
                      _promoSummaryCard(
                        title: 'Active Promos',
                        value: '$activeCount',
                        icon: Icons.campaign_outlined,
                        color: const Color(0xFF159447),
                      ),
                      _promoSummaryCard(
                        title: 'Discounts',
                        value: '$discountCount',
                        icon: Icons.percent_rounded,
                        color: const Color(0xFF1565C0),
                      ),
                      _promoSummaryCard(
                        title: 'Buy 1 Take 1',
                        value: '$b1t1Count',
                        icon: Icons.redeem_outlined,
                        color: const Color(0xFF7B1FA2),
                      ),
                      _promoSummaryCard(
                        title: 'Near-Expiry',
                        value: '$nearExpiryCount',
                        icon: Icons.schedule_outlined,
                        color: const Color(0xFFF59E0B),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 760;

                  final search = TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search product, category, brand, or promo',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF1565C0),
                      ),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _searchController.clear();
                                setState(() {
                                  _searchQuery = '';
                                });
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

                  final filters = SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip('All'),
                        const SizedBox(width: 8),
                        _filterChip('Active'),
                        const SizedBox(width: 8),
                        _filterChip('Inactive'),
                        const SizedBox(width: 8),
                        _filterChip('Discount'),
                        const SizedBox(width: 8),
                        _filterChip('Buy 1 Take 1'),
                        const SizedBox(width: 8),
                        _filterChip('Near-Expiry'),
                      ],
                    ),
                  );

                  if (compact) {
                    return Column(
                      children: [search, const SizedBox(height: 12), filters],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: search),
                      const SizedBox(width: 14),
                      filters,
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: filtered.isEmpty
                    ? const _PromoEmptyState()
                    : GridView.builder(
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 380,
                              mainAxisExtent: 300,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemBuilder: (context, index) {
                          final document = filtered[index];
                          final data = document.data();

                          final name =
                              (data['productName'] ?? 'Unknown Product')
                                  .toString();

                          final regularPrice =
                              (data['sellingPrice'] as num?)?.toDouble() ?? 0;

                          final promoPrice = (data['promoPrice'] as num?)
                              ?.toDouble();

                          final type = (data['promoType'] ?? '').toString();

                          final label = (data['promoLabel'] ?? type).toString();

                          final active = _isPromoActive(data);

                          return _PromoProductCard(
                            productName: name,
                            regularPrice: regularPrice,
                            promoPrice: promoPrice,
                            promoType: type,
                            promoLabel: label,
                            active: active,
                            startDate: _formatDate(
                              _readDate(data['promoStartDate']),
                            ),
                            endDate: _formatDate(
                              _readDate(data['promoEndDate']),
                            ),
                            onEdit: () => _showPromoDialog(document),
                            onDisable: active
                                ? () => _disablePromo(document)
                                : null,
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

  Widget _promoSummaryCard({
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
      child: _PromoHoverCard(
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
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
