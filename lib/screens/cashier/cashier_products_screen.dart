import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CashierProductsScreen extends StatefulWidget {
  const CashierProductsScreen({super.key});

  @override
  State<CashierProductsScreen> createState() => _CashierProductsScreenState();
}

class _CashierProductsScreenState extends State<CashierProductsScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedFilter = 'All';

  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final searchable = [
      data['productName'],
      data['barcode'],
      data['category'],
      data['brand'],
      data['unit'],
      data['supplier'],
    ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

    return searchable.contains(_searchQuery);
  }

  bool _matchesFilter(Map<String, dynamic> data) {
    final stock = (data['stock'] as num?)?.toInt() ?? 0;

    switch (_selectedFilter) {
      case 'Available':
        return stock > 10;
      case 'Low Stock':
        return stock > 0 && stock <= 10;
      case 'Out of Stock':
        return stock <= 0;
      default:
        return true;
    }
  }

  Widget _filterChip(String label) {
    final selected = _selectedFilter == label;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedFilter = label;
        });
      },
      selectedColor: const Color(0xFF1565C0),
      labelStyle: TextStyle(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Color _stockColor(int stock) {
    if (stock <= 0) return Colors.red;
    if (stock <= 10) return Colors.orange;
    return Colors.green;
  }

  String _stockLabel(int stock) {
    if (stock <= 0) return 'Out of Stock';
    if (stock <= 10) return 'Low Stock';
    return 'Available';
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
              'Unable to load products.\n${snapshot.error}',
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

        final filtered = products.where((document) {
          final data = document.data();
          return _matchesSearch(data) && _matchesFilter(data);
        }).toList();

        int availableCount = 0;
        int lowStockCount = 0;
        int outOfStockCount = 0;

        for (final document in products) {
          final stock = (document.data()['stock'] as num?)?.toInt() ?? 0;

          if (stock <= 0) {
            outOfStockCount++;
          } else if (stock <= 10) {
            lowStockCount++;
          } else {
            availableCount++;
          }
        }

        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  int count = 4;
                  if (constraints.maxWidth < 1000) count = 2;
                  if (constraints.maxWidth < 620) count = 1;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: count,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 2.15,
                    children: [
                      _summaryCard(
                        title: 'Total Products',
                        value: '${products.length}',
                        icon: Icons.inventory_2_outlined,
                        color: const Color(0xFF1565C0),
                      ),
                      _summaryCard(
                        title: 'Available',
                        value: '$availableCount',
                        icon: Icons.check_circle_outline,
                        color: Colors.green,
                      ),
                      _summaryCard(
                        title: 'Low Stock',
                        value: '$lowStockCount',
                        icon: Icons.warning_amber_rounded,
                        color: Colors.orange,
                      ),
                      _summaryCard(
                        title: 'Out of Stock',
                        value: '$outOfStockCount',
                        icon: Icons.remove_shopping_cart_outlined,
                        color: Colors.red,
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.trim().toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText:
                            'Search product, barcode, category, brand, or unit',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchQuery.isEmpty
                            ? null
                            : IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                                icon: const Icon(Icons.clear),
                              ),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      _filterChip('All'),
                      _filterChip('Available'),
                      _filterChip('Low Stock'),
                      _filterChip('Out of Stock'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No products found.',
                          style: TextStyle(color: Colors.grey, fontSize: 18),
                        ),
                      )
                    : GridView.builder(
                        itemCount: filtered.length,
                        gridDelegate:
                            const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 330,
                              mainAxisExtent: 220,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                        itemBuilder: (context, index) {
                          final data = filtered[index].data();

                          final name =
                              (data['productName'] ?? 'Unknown Product')
                                  .toString();
                          final barcode = (data['barcode'] ?? '').toString();
                          final category = (data['category'] ?? '').toString();
                          final brand = (data['brand'] ?? '').toString();
                          final unit = (data['unit'] ?? '').toString();
                          final stock = (data['stock'] as num?)?.toInt() ?? 0;
                          final price =
                              (data['sellingPrice'] as num?)?.toDouble() ?? 0;

                          final stockColor = _stockColor(stock);

                          return Container(
                            padding: const EdgeInsets.all(18),
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
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F2FD),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        color: Color(0xFF1565C0),
                                      ),
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: stockColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _stockLabel(stock),
                                        style: TextStyle(
                                          color: stockColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  [
                                    if (brand.isNotEmpty) brand,
                                    if (category.isNotEmpty) category,
                                    if (unit.isNotEmpty) unit,
                                  ].join(' • '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  barcode.isEmpty
                                      ? 'No barcode assigned'
                                      : 'Barcode: $barcode',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                const Spacer(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '₱${price.toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          color: Colors.green,
                                          fontSize: 19,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'Stock: $stock',
                                      style: TextStyle(
                                        color: stockColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
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
                    fontSize: 24,
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
