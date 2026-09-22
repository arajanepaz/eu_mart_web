import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class _MovementHoverCard extends StatefulWidget {
  final Widget child;

  const _MovementHoverCard({required this.child});

  @override
  State<_MovementHoverCard> createState() => _MovementHoverCardState();
}

class _MovementHoverCardState extends State<_MovementHoverCard> {
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

class _StockMovementCard extends StatefulWidget {
  final String productName;
  final String type;
  final Color color;
  final IconData icon;
  final String direction;
  final int quantity;
  final int previousStock;
  final int newStock;
  final String supplier;
  final String reason;
  final double buyingCost;
  final String date;
  final String performedBy;

  const _StockMovementCard({
    required this.productName,
    required this.type,
    required this.color,
    required this.icon,
    required this.direction,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    required this.supplier,
    required this.reason,
    required this.buyingCost,
    required this.date,
    required this.performedBy,
  });

  @override
  State<_StockMovementCard> createState() => _StockMovementCardState();
}

class _StockMovementCardState extends State<_StockMovementCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final sign = widget.direction == 'increase' ? '+' : '-';

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
            final compact = constraints.maxWidth < 700;

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
                              widget.type,
                              style: TextStyle(
                                color: widget.color,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 9,
                        runSpacing: 8,
                        children: [
                          _MovementInfoPill(
                            icon: Icons.inventory_2_outlined,
                            label: '$sign${widget.quantity}',
                            color: widget.color,
                          ),
                          _MovementInfoPill(
                            icon: Icons.compare_arrows_rounded,
                            label:
                                '${widget.previousStock} → ${widget.newStock}',
                            color: const Color(0xFF1565C0),
                          ),
                          if (widget.supplier.isNotEmpty)
                            _MovementInfoPill(
                              icon: Icons.local_shipping_outlined,
                              label: widget.supplier,
                              color: const Color(0xFF7B1FA2),
                            ),
                          if (widget.buyingCost > 0)
                            _MovementInfoPill(
                              icon: Icons.payments_outlined,
                              label: '₱${widget.buyingCost.toStringAsFixed(2)}',
                              color: const Color(0xFF159447),
                            ),
                        ],
                      ),
                      if (widget.reason.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          widget.reason,
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

            final meta = Column(
              crossAxisAlignment: compact
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.schedule_outlined,
                      size: 15,
                      color: Color(0xFF8A95A4),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.date,
                      style: const TextStyle(
                        color: Color(0xFF8A95A4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                if (widget.performedBy.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 15,
                        color: Color(0xFF8A95A4),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        widget.performedBy,
                        style: const TextStyle(
                          color: Color(0xFF8A95A4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [mainInfo, const SizedBox(height: 14), meta],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: mainInfo),
                const SizedBox(width: 16),
                meta,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _MovementInfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MovementInfoPill({
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

class _StockMovementEmptyState extends StatelessWidget {
  const _StockMovementEmptyState();

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
              Icons.swap_vert_circle_outlined,
              size: 64,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No stock movement records found',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Record a new movement or choose another filter.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}

class StockMovementScreen extends StatefulWidget {
  const StockMovementScreen({super.key});

  @override
  State<StockMovementScreen> createState() => _StockMovementScreenState();
}

class _StockMovementScreenState extends State<StockMovementScreen> {
  String _selectedFilter = 'All';

  DateTime? _readDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pending';

    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '${date.year}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '$hour:$minute $period';
  }

  bool _matchesFilter(String type) {
    if (_selectedFilter == 'All') return true;
    return type == _selectedFilter;
  }

  Color _movementColor(String type) {
    switch (type) {
      case 'Restock':
        return Colors.green;
      case 'Stock Increase':
        return Colors.blue;
      case 'Damaged':
        return Colors.orange;
      case 'Expired':
        return Colors.red;
      case 'Stock Decrease':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _movementIcon(String type) {
    switch (type) {
      case 'Restock':
        return Icons.add_shopping_cart;
      case 'Stock Increase':
        return Icons.add_circle_outline;
      case 'Damaged':
        return Icons.warning_amber_rounded;
      case 'Expired':
        return Icons.event_busy_outlined;
      case 'Stock Decrease':
        return Icons.remove_circle_outline;
      default:
        return Icons.swap_vert;
    }
  }

  Future<void> _showStockMovementDialog() async {
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('products').get(),
      FirebaseFirestore.instance
          .collection('suppliers')
          .where('isActive', isEqualTo: true)
          .get(),
    ]);

    if (!mounted) return;

    final productsSnapshot = results[0];
    final suppliersSnapshot = results[1];

    if (productsSnapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No products available. Add a product first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final products = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      productsSnapshot.docs,
    );

    final suppliers = List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
      suppliersSnapshot.docs,
    );

    suppliers.sort((a, b) {
      final first = (a.data()['supplierName'] ?? '').toString().toLowerCase();
      final second = (b.data()['supplierName'] ?? '').toString().toLowerCase();

      return first.compareTo(second);
    });

    products.sort((a, b) {
      final first = (a.data()['productName'] ?? '').toString().toLowerCase();
      final second = (b.data()['productName'] ?? '').toString().toLowerCase();
      return first.compareTo(second);
    });

    String? selectedProductId;
    String? selectedSupplierId;
    String movementType = 'Restock';
    bool saving = false;

    final quantityController = TextEditingController();
    final costController = TextEditingController();
    final reasonController = TextEditingController();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> saveMovement() async {
              if (selectedProductId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Select a product.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final quantity = int.tryParse(quantityController.text.trim());

              if (quantity == null || quantity <= 0) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Quantity must be greater than zero.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (movementType == 'Restock' && selectedSupplierId == null) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Select an active supplier for restocking.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              final productDocument = products.firstWhere(
                (document) => document.id == selectedProductId,
              );

              final productData = productDocument.data();
              final productName =
                  (productData['productName'] ?? 'Unknown Product').toString();

              final isIncrease =
                  movementType == 'Restock' || movementType == 'Stock Increase';

              setDialogState(() => saving = true);

              try {
                final user = FirebaseAuth.instance.currentUser;

                await FirebaseFirestore.instance.runTransaction((
                  transaction,
                ) async {
                  final freshProduct = await transaction.get(
                    productDocument.reference,
                  );

                  final freshData = freshProduct.data() ?? <String, dynamic>{};

                  final previousStock =
                      (freshData['stock'] as num?)?.toInt() ?? 0;

                  final newStock = isIncrease
                      ? previousStock + quantity
                      : previousStock - quantity;

                  if (newStock < 0) {
                    throw Exception(
                      'Not enough stock. Current stock: $previousStock.',
                    );
                  }

                  transaction.update(productDocument.reference, {
                    'stock': newStock,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  final movementReference = FirebaseFirestore.instance
                      .collection('stock_movements')
                      .doc();

                  transaction.set(movementReference, {
                    'productId': productDocument.id,
                    'productName': productName,
                    'movementType': movementType,
                    'quantity': quantity,
                    'direction': isIncrease ? 'increase' : 'decrease',
                    'previousStock': previousStock,
                    'newStock': newStock,
                    'supplierId': selectedSupplierId ?? '',
                    'supplier': selectedSupplierId == null
                        ? ''
                        : (suppliers
                                      .firstWhere(
                                        (supplier) =>
                                            supplier.id == selectedSupplierId,
                                      )
                                      .data()['supplierName'] ??
                                  '')
                              .toString(),
                    'buyingCost':
                        double.tryParse(costController.text.trim()) ?? 0,
                    'reason': reasonController.text.trim(),
                    'performedById': user?.uid ?? '',
                    'performedByEmail': user?.email ?? '',
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  final auditReference = FirebaseFirestore.instance
                      .collection('audit_logs')
                      .doc();

                  transaction.set(auditReference, {
                    'action': 'Stock Movement',
                    'description':
                        '$movementType: $productName, quantity $quantity, '
                        '$previousStock to $newStock',
                    'module': 'Inventory',
                    'performedById': user?.uid ?? '',
                    'performedByEmail': user?.email ?? '',
                    'createdAt': FieldValue.serverTimestamp(),
                  });
                });

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$movementType recorded successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Unable to record stock movement: $error'),
                    backgroundColor: Colors.red,
                  ),
                );

                setDialogState(() => saving = false);
              }
            }

            final selectedProduct = selectedProductId == null
                ? null
                : products.firstWhere(
                    (document) => document.id == selectedProductId,
                  );

            final selectedStock = selectedProduct == null
                ? 0
                : (selectedProduct.data()['stock'] as num?)?.toInt() ?? 0;

            return AlertDialog(
              title: const Text('Record Stock Movement'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedProductId,
                        decoration: const InputDecoration(
                          labelText: 'Product',
                          border: OutlineInputBorder(),
                        ),
                        isExpanded: true,
                        items: products.map((document) {
                          final data = document.data();
                          final name =
                              (data['productName'] ?? 'Unknown Product')
                                  .toString();
                          final stock = (data['stock'] as num?)?.toInt() ?? 0;

                          return DropdownMenuItem(
                            value: document.id,
                            child: Text(
                              '$name — Stock: $stock',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: saving
                            ? null
                            : (value) {
                                setDialogState(() {
                                  selectedProductId = value;
                                });
                              },
                      ),
                      if (selectedProductId != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Current stock: $selectedStock',
                            style: const TextStyle(
                              color: Color(0xFF1565C0),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: movementType,
                        decoration: const InputDecoration(
                          labelText: 'Movement Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Restock',
                            child: Text('Restock'),
                          ),
                          DropdownMenuItem(
                            value: 'Stock Increase',
                            child: Text('Manual Stock Increase'),
                          ),
                          DropdownMenuItem(
                            value: 'Stock Decrease',
                            child: Text('Manual Stock Decrease'),
                          ),
                          DropdownMenuItem(
                            value: 'Damaged',
                            child: Text('Damaged Product'),
                          ),
                          DropdownMenuItem(
                            value: 'Expired',
                            child: Text('Expired Product'),
                          ),
                        ],
                        onChanged: saving
                            ? null
                            : (value) {
                                if (value == null) return;
                                setDialogState(() {
                                  movementType = value;
                                });
                              },
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: quantityController,
                        enabled: !saving,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (movementType == 'Restock') ...[
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          initialValue: selectedSupplierId,
                          decoration: const InputDecoration(
                            labelText: 'Supplier',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: suppliers.map((supplier) {
                            final data = supplier.data();
                            final name =
                                (data['supplierName'] ?? 'Unnamed Supplier')
                                    .toString();
                            final contact = (data['contactPerson'] ?? '')
                                .toString();

                            return DropdownMenuItem(
                              value: supplier.id,
                              child: Text(
                                contact.isEmpty ? name : '$name — $contact',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: saving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    selectedSupplierId = value;
                                  });
                                },
                        ),
                        if (suppliers.isEmpty) ...[
                          const SizedBox(height: 8),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'No active suppliers found. '
                              'Add one in Supplier Management.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        TextField(
                          controller: costController,
                          enabled: !saving,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Total Buying Cost',
                            prefixText: '₱ ',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      TextField(
                        controller: reasonController,
                        enabled: !saving,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: movementType == 'Restock'
                              ? 'Notes'
                              : 'Reason',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: saving ? null : saveMovement,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'SAVING...' : 'SAVE MOVEMENT'),
                ),
              ],
            );
          },
        );
      },
    );

    quantityController.dispose();
    costController.dispose();
    reasonController.dispose();
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 650;

                final title = const Row(
                  children: [
                    Icon(
                      Icons.swap_vert_circle_outlined,
                      color: Colors.white,
                      size: 29,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Stock Movement & Restocking',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track every stock increase, decrease, '
                            'restock, damaged item, and expired product.',
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
                    onPressed: _showStockMovementDialog,
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
                      'NEW MOVEMENT',
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
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('stock_movements')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Unable to load stock movements.\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final allMovements =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                    );

                int restockCount = 0;
                int increaseCount = 0;
                int decreaseCount = 0;
                int issueCount = 0;

                for (final document in allMovements) {
                  final type = (document.data()['movementType'] ?? '')
                      .toString();

                  if (type == 'Restock') {
                    restockCount++;
                  } else if (type == 'Stock Increase') {
                    increaseCount++;
                  } else if (type == 'Stock Decrease') {
                    decreaseCount++;
                  } else if (type == 'Damaged' || type == 'Expired') {
                    issueCount++;
                  }
                }

                final movements = allMovements.where((document) {
                  final type = (document.data()['movementType'] ?? '')
                      .toString();
                  return _matchesFilter(type);
                }).toList();

                return Column(
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
                            _movementSummaryCard(
                              title: 'Restocks',
                              value: '$restockCount',
                              icon: Icons.add_shopping_cart,
                              color: const Color(0xFF159447),
                            ),
                            _movementSummaryCard(
                              title: 'Stock Increases',
                              value: '$increaseCount',
                              icon: Icons.add_circle_outline,
                              color: const Color(0xFF1565C0),
                            ),
                            _movementSummaryCard(
                              title: 'Stock Decreases',
                              value: '$decreaseCount',
                              icon: Icons.remove_circle_outline,
                              color: const Color(0xFF7B1FA2),
                            ),
                            _movementSummaryCard(
                              title: 'Damaged / Expired',
                              value: '$issueCount',
                              icon: Icons.warning_amber_rounded,
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        );
                      },
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
                        border: Border.all(color: const Color(0xFFDDE6F1)),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _filterChip('All'),
                            const SizedBox(width: 8),
                            _filterChip('Restock'),
                            const SizedBox(width: 8),
                            _filterChip('Stock Increase'),
                            const SizedBox(width: 8),
                            _filterChip('Stock Decrease'),
                            const SizedBox(width: 8),
                            _filterChip('Damaged'),
                            const SizedBox(width: 8),
                            _filterChip('Expired'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: movements.isEmpty
                          ? const _StockMovementEmptyState()
                          : ListView.separated(
                              itemCount: movements.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final data = movements[index].data();
                                final type =
                                    (data['movementType'] ?? 'Adjustment')
                                        .toString();
                                final color = _movementColor(type);
                                final direction = (data['direction'] ?? '')
                                    .toString();
                                final quantity =
                                    (data['quantity'] as num?)?.toInt() ?? 0;
                                final previousStock =
                                    (data['previousStock'] as num?)?.toInt() ??
                                    0;
                                final newStock =
                                    (data['newStock'] as num?)?.toInt() ?? 0;
                                final supplier = (data['supplier'] ?? '')
                                    .toString();
                                final reason = (data['reason'] ?? '')
                                    .toString();
                                final buyingCost =
                                    (data['buyingCost'] as num?)?.toDouble() ??
                                    0;

                                return _StockMovementCard(
                                  productName:
                                      (data['productName'] ?? 'Unknown Product')
                                          .toString(),
                                  type: type,
                                  color: color,
                                  icon: _movementIcon(type),
                                  direction: direction,
                                  quantity: quantity,
                                  previousStock: previousStock,
                                  newStock: newStock,
                                  supplier: supplier,
                                  reason: reason,
                                  buyingCost: buyingCost,
                                  date: _formatDate(
                                    _readDate(data['createdAt']),
                                  ),
                                  performedBy: (data['performedByEmail'] ?? '')
                                      .toString(),
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _movementSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return _MovementHoverCard(
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
