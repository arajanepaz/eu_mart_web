// -----------------------------------------------------------------------------
// Module overview: Maintains supplier information used by EÜ MART product and inventory operations.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Private UI/data helper used only inside this module.
class _SupplierHoverCard extends StatefulWidget {
  final Widget child;

  // Handles the supplier hover card logic used by this module.
  const _SupplierHoverCard({required this.child});

  @override
  State<_SupplierHoverCard> createState() => _SupplierHoverCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _SupplierHoverCardState extends State<_SupplierHoverCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    // Handles the mouse region logic used by this module.
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

// Private UI/data helper used only inside this module.
class _SupplierCard extends StatefulWidget {
  final String supplierName;
  final String contactPerson;
  final String phone;
  final String email;
  final String address;
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  // Handles the supplier card logic used by this module.
  const _SupplierCard({
    required this.supplierName,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.address,
    required this.isActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_SupplierCard> createState() => _SupplierCardState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _SupplierCardState extends State<_SupplierCard> {
  bool _hovered = false;

  // Handles the detail logic used by this module.
  Widget _detail(IconData icon, String value) {
    // Handles the padding logic used by this module.
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 17, color: const Color(0xFF7A8494)),
          // Handles the sized box logic used by this module.
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Color(0xFF607086), fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.isActive
        ? const Color(0xFF159447)
        : const Color(0xFF8A95A4);

    // Handles the mouse region logic used by this module.
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
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
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0D47A1), Color(0xFF1976D2)],
                    ),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: const Icon(
                    Icons.local_shipping_outlined,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                // Handles the spacer logic used by this module.
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
                    widget.isActive ? 'ACTIVE' : 'INACTIVE',
                    style: TextStyle(
                      color: accent,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            // Handles the sized box logic used by this module.
            const SizedBox(height: 14),
            Text(
              widget.supplierName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            // Handles the sized box logic used by this module.
            const SizedBox(height: 13),
            _detail(
              Icons.person_outline,
              widget.contactPerson.isEmpty
                  ? 'No contact person'
                  : widget.contactPerson,
            ),
            _detail(
              Icons.phone_outlined,
              widget.phone.isEmpty ? 'No phone number' : widget.phone,
            ),
            _detail(
              Icons.email_outlined,
              widget.email.isEmpty ? 'No email address' : widget.email,
            ),
            _detail(
              Icons.location_on_outlined,
              widget.address.isEmpty ? 'No address' : widget.address,
            ),
            // Handles the spacer logic used by this module.
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('EDIT'),
                  ),
                ),
                // Handles the sized box logic used by this module.
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Delete supplier',
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _SupplierEmptyState extends StatelessWidget {
  // Handles the supplier empty state logic used by this module.
  const _SupplierEmptyState();

  @override
  Widget build(BuildContext context) {
    // Handles the center logic used by this module.
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
              Icons.local_shipping_outlined,
              size: 62,
              color: Color(0xFFB8C5D5),
            ),
            SizedBox(height: 12),
            Text(
              'No supplier records found',
              style: TextStyle(
                color: Color(0xFF657386),
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Add a supplier or try another search.',
              style: TextStyle(color: Color(0xFF9AA5B3)),
            ),
          ],
        ),
      ),
    );
  }
}

// Screen widget for maintains supplier information used by EÜ MART product and inventory operations.
class SupplierManagementScreen extends StatefulWidget {
  // Handles the supplier management screen logic used by this module.
  const SupplierManagementScreen({super.key});

  @override
  State<SupplierManagementScreen> createState() =>
      _SupplierManagementScreenState();
}

// Owns the mutable UI state and business interactions for the corresponding screen widget.
class _SupplierManagementScreenState extends State<SupplierManagementScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';

  // Opens the supplier dialog interface using the current record or screen state.
  Future<void> _showSupplierDialog({
    DocumentSnapshot<Map<String, dynamic>>? document,
  }) async {
    final data = document?.data() ?? <String, dynamic>{};

    final nameController = TextEditingController(
      text: (data['supplierName'] ?? '').toString(),
    );
    final contactPersonController = TextEditingController(
      text: (data['contactPerson'] ?? '').toString(),
    );
    final phoneController = TextEditingController(
      text: (data['phone'] ?? '').toString(),
    );
    final emailController = TextEditingController(
      text: (data['email'] ?? '').toString(),
    );
    final addressController = TextEditingController(
      text: (data['address'] ?? '').toString(),
    );
    final notesController = TextEditingController(
      text: (data['notes'] ?? '').toString(),
    );

    bool isActive = data['isActive'] != false;
    bool saving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        // Handles the stateful builder logic used by this module.
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // Validates and saves supplier data to the application data store.
            Future<void> saveSupplier() async {
              final supplierName = nameController.text.trim();

              if (supplierName.isEmpty) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  // Handles the snack bar logic used by this module.
                  const SnackBar(
                    content: Text('Supplier name is required.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setDialogState(() => saving = true);

              try {
                final duplicateQuery = await FirebaseFirestore.instance
                    .collection('suppliers')
                    .where(
                      'supplierNameLower',
                      isEqualTo: supplierName.toLowerCase(),
                    )
                    .limit(2)
                    .get();

                final duplicateExists = duplicateQuery.docs.any(
                  (existingDocument) => existingDocument.id != document?.id,
                );

                if (duplicateExists) {
                  if (!dialogContext.mounted) return;

                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    // Handles the snack bar logic used by this module.
                    const SnackBar(
                      content: Text(
                        'A supplier with this name already exists.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );

                  setDialogState(() => saving = false);
                  return;
                }

                final supplierData = <String, dynamic>{
                  'supplierName': supplierName,
                  'supplierNameLower': supplierName.toLowerCase(),
                  'contactPerson': contactPersonController.text.trim(),
                  'phone': phoneController.text.trim(),
                  'email': emailController.text.trim(),
                  'address': addressController.text.trim(),
                  'notes': notesController.text.trim(),
                  'isActive': isActive,
                  'updatedAt': FieldValue.serverTimestamp(),
                };

                if (document == null) {
                  supplierData['createdAt'] = FieldValue.serverTimestamp();

                  await FirebaseFirestore.instance
                      .collection('suppliers')
                      .add(supplierData);
                } else {
                  await document.reference.update(supplierData);
                }

                if (!dialogContext.mounted) return;
                Navigator.pop(dialogContext);

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      document == null
                          ? 'Supplier added successfully.'
                          : 'Supplier updated successfully.',
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (error) {
                if (!dialogContext.mounted) return;

                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  SnackBar(
                    content: Text('Unable to save supplier: $error'),
                    backgroundColor: Colors.red,
                  ),
                );

                setDialogState(() => saving = false);
              }
            }

            // Handles the alert dialog logic used by this module.
            return AlertDialog(
              title: Text(document == null ? 'Add Supplier' : 'Edit Supplier'),
              content: SizedBox(
                width: 580,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: nameController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Supplier Name *',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 16),
                      TextField(
                        controller: contactPersonController,
                        enabled: !saving,
                        decoration: const InputDecoration(
                          labelText: 'Contact Person',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: phoneController,
                              enabled: !saving,
                              decoration: const InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          // Handles the sized box logic used by this module.
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: emailController,
                              enabled: !saving,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        enabled: !saving,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Address',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 16),
                      TextField(
                        controller: notesController,
                        enabled: !saving,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      // Handles the sized box logic used by this module.
                      const SizedBox(height: 8),
                      SwitchListTile(
                        value: isActive,
                        onChanged: saving
                            ? null
                            : (value) {
                                setDialogState(() {
                                  isActive = value;
                                });
                              },
                        title: const Text('Active Supplier'),
                        subtitle: const Text(
                          'Inactive suppliers remain in history '
                          'but should not be used for new restocks.',
                        ),
                        contentPadding: EdgeInsets.zero,
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
                  onPressed: saving ? null : saveSupplier,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(saving ? 'SAVING...' : 'SAVE SUPPLIER'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Deletes the selected supplier record after the required checks.
  Future<void> _deleteSupplier(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data() ?? <String, dynamic>{};
    final supplierName = (data['supplierName'] ?? 'Supplier').toString();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        // Handles the alert dialog logic used by this module.
        return AlertDialog(
          title: const Text('Delete Supplier'),
          content: Text(
            'Delete $supplierName? '
            'Existing stock movement records will not be deleted.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await document.reference.delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        // Handles the snack bar logic used by this module.
        const SnackBar(
          content: Text('Supplier deleted.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to delete supplier: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Checks whether the current value satisfies the matches search rule used by this module.
  bool _matchesSearch(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    final searchable = [
      data['supplierName'],
      data['contactPerson'],
      data['phone'],
      data['email'],
      data['address'],
    ].map((value) => (value ?? '').toString().toLowerCase()).join(' ');

    return searchable.contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    // Handles the container logic used by this module.
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
            child: const Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: Colors.white,
                  size: 29,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Supplier Management',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage supplier contacts and keep '
                        'restocking records organized.',
                        style: TextStyle(color: Colors.white70, fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Handles the sized box logic used by this module.
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('suppliers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  // Handles the center logic used by this module.
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  // Handles the center logic used by this module.
                  return Center(
                    child: Text(
                      'Unable to load suppliers.\n'
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                final allSuppliers =
                    List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
                      snapshot.data?.docs ??
                          <QueryDocumentSnapshot<Map<String, dynamic>>>[],
                    );

                final activeCount = allSuppliers.where((document) {
                  return document.data()['isActive'] != false;
                }).length;

                final inactiveCount = allSuppliers.length - activeCount;

                final suppliers = allSuppliers.where((document) {
                  // Checks whether the current value satisfies the matches search rule used by this module.
                  return _matchesSearch(document.data());
                }).toList();

                suppliers.sort((a, b) {
                  final first = (a.data()['supplierName'] ?? '')
                      .toString()
                      .toLowerCase();
                  final second = (b.data()['supplierName'] ?? '')
                      .toString()
                      .toLowerCase();
                  return first.compareTo(second);
                });

                // Handles the column logic used by this module.
                return Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        int count = 3;
                        if (constraints.maxWidth < 900) {
                          count = 2;
                        }
                        if (constraints.maxWidth < 580) {
                          count = 1;
                        }

                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: count,
                          crossAxisSpacing: 13,
                          mainAxisSpacing: 13,
                          childAspectRatio: count == 3 ? 2.55 : 3.1,
                          children: [
                            _supplierSummaryCard(
                              title: 'Total Suppliers',
                              value: '${allSuppliers.length}',
                              icon: Icons.business_outlined,
                              color: const Color(0xFF1565C0),
                            ),
                            _supplierSummaryCard(
                              title: 'Active Suppliers',
                              value: '$activeCount',
                              icon: Icons.check_circle_outline,
                              color: const Color(0xFF159447),
                            ),
                            _supplierSummaryCard(
                              title: 'Inactive Suppliers',
                              value: '$inactiveCount',
                              icon: Icons.pause_circle_outline,
                              color: const Color(0xFFF59E0B),
                            ),
                          ],
                        );
                      },
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 900;

                        final search = TextField(
                          controller: _searchController,
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value.trim().toLowerCase();
                            });
                          },
                          decoration: InputDecoration(
                            hintText:
                                'Search supplier, contact, phone, email, or address',
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
                              borderSide: const BorderSide(
                                color: Color(0xFFDDE6F1),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: const BorderSide(
                                color: Color(0xFFDDE6F1),
                              ),
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

                        final addButton = SizedBox(
                          height: 50,
                          child: ElevatedButton.icon(
                            onPressed: () => _showSupplierDialog(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.add_rounded),
                            label: const Text(
                              'ADD SUPPLIER',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        );

                        if (compact) {
                          // Handles the column logic used by this module.
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              search,
                              // Handles the sized box logic used by this module.
                              const SizedBox(height: 12),
                              addButton,
                            ],
                          );
                        }

                        // Handles the row logic used by this module.
                        return Row(
                          children: [
                            Expanded(child: search),
                            // Handles the sized box logic used by this module.
                            const SizedBox(width: 14),
                            addButton,
                          ],
                        );
                      },
                    ),
                    // Handles the sized box logic used by this module.
                    const SizedBox(height: 16),
                    Expanded(
                      child: suppliers.isEmpty
                          ? const _SupplierEmptyState()
                          : GridView.builder(
                              itemCount: suppliers.length,
                              gridDelegate:
                                  // Handles the sliver grid delegate with max cross axis extent logic used by this module.
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 410,
                                    mainAxisExtent: 310,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemBuilder: (context, index) {
                                final document = suppliers[index];
                                final data = document.data();

                                // Handles the supplier card logic used by this module.
                                return _SupplierCard(
                                  supplierName:
                                      (data['supplierName'] ??
                                              'Unnamed Supplier')
                                          .toString(),
                                  contactPerson: (data['contactPerson'] ?? '')
                                      .toString(),
                                  phone: (data['phone'] ?? '').toString(),
                                  email: (data['email'] ?? '').toString(),
                                  address: (data['address'] ?? '').toString(),
                                  isActive: data['isActive'] != false,
                                  onEdit: () =>
                                      _showSupplierDialog(document: document),
                                  onDelete: () => _deleteSupplier(document),
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

  // Handles the supplier summary card logic used by this module.
  Widget _supplierSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Handles the supplier hover card logic used by this module.
    return _SupplierHoverCard(
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
            // Handles the sized box logic used by this module.
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
                  // Handles the sized box logic used by this module.
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

  // Handles the detail logic used by this module.
  Widget _detail(IconData icon, String value) {
    // Handles the padding logic used by this module.
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(icon, size: 17, color: Colors.grey),
          // Handles the sized box logic used by this module.
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
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
