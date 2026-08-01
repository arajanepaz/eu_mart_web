import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuditLogService {
  AuditLogService._();

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

  static Future<void> productCreated({
    required String productId,
    required String productName,
  }) {
    return log(
      action: 'Create Product',
      module: 'Products',
      description: 'Created a new product.',
      targetId: productId,
      targetName: productName,
    );
  }

  static Future<void> productUpdated({
    required String productId,
    required String productName,
  }) {
    return log(
      action: 'Update Product',
      module: 'Products',
      description: 'Updated product information.',
      targetId: productId,
      targetName: productName,
    );
  }

  static Future<void> productDeleted({
    required String productId,
    required String productName,
  }) {
    return log(
      action: 'Delete Product',
      module: 'Products',
      description: 'Deleted a product record.',
      targetId: productId,
      targetName: productName,
    );
  }

  static Future<void> stockAdjusted({
    required String productId,
    required String productName,
    required int oldStock,
    required int newStock,
  }) {
    return log(
      action: 'Update Stock',
      module: 'Inventory',
      description: 'Adjusted stock from $oldStock to $newStock.',
      targetId: productId,
      targetName: productName,
      details: {'oldStock': oldStock, 'newStock': newStock},
    );
  }

  static Future<void> transactionVoided({
    required String transactionId,
    required String receiptNumber,
    String reason = '',
  }) {
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

  static Future<void> cashierStatusChanged({
    required String cashierId,
    required String cashierName,
    required bool enabled,
  }) {
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

  static Future<void> settingsUpdated({required String description}) {
    return log(
      action: 'Update Settings',
      module: 'Settings',
      description: description,
      targetName: 'System Settings',
    );
  }

  static Future<void> permitChanged({
    required String action,
    required String permitId,
    required String permitName,
  }) {
    return log(
      action: action,
      module: 'Permit Reminders',
      description: '$action: $permitName',
      targetId: permitId,
      targetName: permitName,
    );
  }

  static Future<void> backupRestored({
    required int documentCount,
    required List<String> collections,
  }) {
    return log(
      action: 'Restore Backup',
      module: 'Backup',
      description: 'Restored $documentCount document(s) from backup.',
      targetName: collections.join(', '),
      details: {'documentCount': documentCount, 'collections': collections},
    );
  }
}
