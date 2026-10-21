// -----------------------------------------------------------------------------
// Module overview: Reusable service for writing structured audit-trail records to Firestore.
// Comments in this file document non-obvious behavior and maintenance intent.
// -----------------------------------------------------------------------------

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Defines a reusable component or data structure used by this module.
class AuditLogService {
  AuditLogService._();

  // Records log information for monitoring or traceability.
  static Future<void> log({
    required String action,
    required String module,
    required String description,
    String targetId = '',
    String targetName = '',
    Map<String, dynamic>? details,
  }) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('audit_logs').add({
        'action': action.trim(),
        'module': module.trim(),
        'description': description.trim(),
        'targetId': targetId.trim(),
        'targetName': targetName.trim(),
        'details': details ?? <String, dynamic>{},
        'performedById': user.uid,
        'performedByEmail': user.email ?? '',
        'performedByName': user.displayName ?? user.email ?? 'Unknown User',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Audit logging must not interrupt the main operation.
    }
  }

  // Handles the product created logic used by this module.
  static Future<void> productCreated({
    required String productId,
    required String productName,
  }) {
    // Records log information for monitoring or traceability.
    return log(
      action: 'Create Product',
      module: 'Products',
      description: 'Created a new product.',
      targetId: productId,
      targetName: productName,
    );
  }

  // Handles the product updated logic used by this module.
  static Future<void> productUpdated({
    required String productId,
    required String productName,
  }) {
    // Records log information for monitoring or traceability.
    return log(
      action: 'Update Product',
      module: 'Products',
      description: 'Updated product information.',
      targetId: productId,
      targetName: productName,
    );
  }

  // Handles the product deleted logic used by this module.
  static Future<void> productDeleted({
    required String productId,
    required String productName,
  }) {
    // Records log information for monitoring or traceability.
    return log(
      action: 'Delete Product',
      module: 'Products',
      description: 'Deleted a product record.',
      targetId: productId,
      targetName: productName,
    );
  }

  // Handles the stock adjusted logic used by this module.
  static Future<void> stockAdjusted({
    required String productId,
    required String productName,
    required int oldStock,
    required int newStock,
  }) {
    // Records log information for monitoring or traceability.
    return log(
      action: 'Update Stock',
      module: 'Inventory',
      description: 'Adjusted stock from $oldStock to $newStock.',
      targetId: productId,
      targetName: productName,
      details: {'oldStock': oldStock, 'newStock': newStock},
    );
  }

  // Handles the transaction voided logic used by this module.
  static Future<void> transactionVoided({
    required String transactionId,
    required String receiptNumber,
    String reason = '',
  }) {
    // Records log information for monitoring or traceability.
    return log(
      action: 'Void Transaction',
      module: 'Transactions',
      description: reason.isEmpty
          ? 'Voided a completed transaction.'
          : 'Voided transaction. Reason: $reason',
      targetId: transactionId,
      targetName: receiptNumber,
    );
  }

  // Handles the cashier status changed logic used by this module.
  static Future<void> cashierStatusChanged({
    required String cashierId,
    required String cashierName,
    required bool enabled,
  }) {
    // Records log information for monitoring or traceability.
    return log(
      action: enabled ? 'Enable Cashier' : 'Disable Cashier',
      module: 'Cashiers',
      description: enabled
          ? 'Enabled cashier account.'
          : 'Disabled cashier account.',
      targetId: cashierId,
      targetName: cashierName,
    );
  }

  // Handles the settings updated logic used by this module.
  static Future<void> settingsUpdated({required String description}) {
    // Records log information for monitoring or traceability.
    return log(
      action: 'Update Settings',
      module: 'Settings',
      description: description,
      targetName: 'System Settings',
    );
  }

  // Handles the permit changed logic used by this module.
  static Future<void> permitChanged({
    required String action,
    required String permitId,
    required String permitName,
  }) {
    // Records log information for monitoring or traceability.
    return log(
      action: action,
      module: 'Permit Reminders',
      description: '$action: $permitName',
      targetId: permitId,
      targetName: permitName,
    );
  }

  // Handles the backup restored logic used by this module.
  static Future<void> backupRestored({
    required int documentCount,
    required List<String> collections,
  }) {
    // Records log information for monitoring or traceability.
    return log(
      action: 'Restore Backup',
      module: 'Backup',
      description: 'Restored $documentCount document(s) from backup.',
      targetName: collections.join(', '),
      details: {'documentCount': documentCount, 'collections': collections},
    );
  }
}
