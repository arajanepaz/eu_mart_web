import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FirestoreSchemaExportScreen extends StatefulWidget {
  const FirestoreSchemaExportScreen({super.key});

  @override
  State<FirestoreSchemaExportScreen> createState() =>
      _FirestoreSchemaExportScreenState();
}

class _FirestoreSchemaExportScreenState
    extends State<FirestoreSchemaExportScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isExporting = false;
  String _status = 'Ready.';
  Map<String, dynamic>? _schemaResult;

  // Current EÜ MART top-level collections.
  //
  // NOTE:
  // permit_reminders and stock_movements are included here because
  // they appeared in the previous exporter output.
  // The final manuscript should only include collections that are
  // confirmed to exist in the current deployed database.
  final List<String> _collections = const [
    'users',
    'products',
    'transactions',
    'service_issues',
    'permit_reminders',
    'audit_logs',
    'login_activity',
    'cash_sessions',
    'customer_feedback',
    'notification_reads',
    'notifications',
    'settings',
    'stock_movements',
    'suppliers',
    'held_transactions',
    'price_update_reminders',
  ];

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  Future<void> _checkCurrentUser() async {
    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        _status = 'No authenticated user found. Please log in first.';
      });
      return;
    }

    try {
      final userSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userSnapshot.exists) {
        setState(() {
          _status =
              'Authenticated, but no matching users/${user.uid} document was found.';
        });
        return;
      }

      final data = userSnapshot.data() ?? {};
      final role = data['role']?.toString().toLowerCase();

      if (role != 'owner') {
        setState(() {
          _status =
              'Access denied. The logged-in account is not an Owner account.';
        });
        return;
      }

      setState(() {
        _status =
            'Authenticated as Owner: ${user.email ?? user.uid}\nReady to export schema.';
      });
    } catch (e) {
      setState(() {
        _status = 'Unable to verify Owner account:\n$e';
      });
    }
  }

  String _detectType(dynamic value) {
    if (value == null) return 'null';

    if (value is String) return 'String';
    if (value is bool) return 'Boolean';

    if (value is int) return 'Integer';
    if (value is double) return 'Double';
    if (value is num) return 'Number';

    if (value is Timestamp) return 'Timestamp';
    if (value is DateTime) return 'DateTime';

    if (value is DocumentReference) return 'DocumentReference';
    if (value is GeoPoint) return 'GeoPoint';
    if (value is Blob) return 'Blob';

    if (value is List) {
      if (value.isEmpty) {
        return 'List';
      }

      final types = <String>{};

      for (final item in value.take(10)) {
        types.add(_detectType(item));
      }

      return 'List<${types.join(', ')}>';
    }

    if (value is Map) {
      return 'Map';
    }

    return value.runtimeType.toString();
  }

  Map<String, dynamic> _buildFieldSchema(Map<String, dynamic> data) {
    final fields = <String, dynamic>{};

    final sortedKeys = data.keys.toList()..sort();

    for (final key in sortedKeys) {
      final value = data[key];

      final fieldInfo = <String, dynamic>{'type': _detectType(value)};

      if (value is Map) {
        final nestedMap = <String, dynamic>{};

        for (final entry in value.entries) {
          nestedMap[entry.key.toString()] = {'type': _detectType(entry.value)};
        }

        fieldInfo['subFields'] = nestedMap;
      }

      if (value is List && value.isNotEmpty) {
        final firstItem = value.first;

        if (firstItem is Map) {
          final itemFields = <String, dynamic>{};

          for (final entry in firstItem.entries) {
            itemFields[entry.key.toString()] = {
              'type': _detectType(entry.value),
            };
          }

          fieldInfo['itemFields'] = itemFields;
        }
      }

      fields[key] = fieldInfo;
    }

    return fields;
  }

  Future<Map<String, dynamic>> _readCollectionSchema(
    String collectionName,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(collectionName)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) {
        return {
          'status': 'accessible_but_empty',
          'documentCountSampled': 0,
          'fields': {},
          'documents': [],
        };
      }

      final Map<String, Map<String, dynamic>> mergedFields = {};

      final List<Map<String, dynamic>> documents = [];

      for (final document in snapshot.docs) {
        final data = document.data();

        documents.add({
          'documentId': document.id,
          'fields': _buildFieldSchema(data),
        });

        for (final entry in data.entries) {
          final fieldName = entry.key;
          final fieldType = _detectType(entry.value);

          if (!mergedFields.containsKey(fieldName)) {
            mergedFields[fieldName] = {
              'typesObserved': <String>[fieldType],
            };
          } else {
            final currentTypes = List<String>.from(
              mergedFields[fieldName]!['typesObserved'] ?? [],
            );

            if (!currentTypes.contains(fieldType)) {
              currentTypes.add(fieldType);
            }

            mergedFields[fieldName]!['typesObserved'] = currentTypes;
          }
        }
      }

      return {
        'status': 'accessible',
        'documentCountSampled': snapshot.docs.length,
        'fields': mergedFields,
        'documents': documents,
      };
    } on FirebaseException catch (e) {
      return {
        'status': 'error',
        'errorCode': e.code,
        'errorMessage': e.message ?? 'Unknown Firebase error.',
      };
    } catch (e) {
      return {'status': 'error', 'errorMessage': e.toString()};
    }
  }

  Future<void> _exportSchema() async {
    if (_isExporting) return;

    final user = _auth.currentUser;

    if (user == null) {
      setState(() {
        _status = 'No authenticated user. Please log in first.';
      });
      return;
    }

    setState(() {
      _isExporting = true;
      _status = 'Checking Owner authorization...';
      _schemaResult = null;
    });

    try {
      // Verify Owner role using the actual logged-in Firebase UID.
      final userSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userSnapshot.exists) {
        throw Exception(
          'The authenticated Firebase user does not have a matching '
          'users/${user.uid} document.',
        );
      }

      final userData = userSnapshot.data() ?? {};
      final role = userData['role']?.toString().toLowerCase();

      if (role != 'owner') {
        throw Exception('Schema export is restricted to the Owner account.');
      }

      final result = <String, dynamic>{
        'system': 'EÜ MART Web-Based',
        'exportType': 'Firestore Schema',
        'generatedAt': DateTime.now().toIso8601String(),
        'authenticatedUser': {
          'uid': user.uid,
          'email': user.email ?? '',
          'role': role,
        },
        'sampleLimitPerCollection': 5,
        'collections': <String, dynamic>{},
      };

      final collectionResults = result['collections'] as Map<String, dynamic>;

      for (int i = 0; i < _collections.length; i++) {
        final collectionName = _collections[i];

        setState(() {
          _status =
              'Reading collection ${i + 1}/${_collections.length}: '
              '$collectionName';
        });

        final collectionSchema = await _readCollectionSchema(collectionName);

        collectionResults[collectionName] = collectionSchema;
      }

      setState(() {
        _schemaResult = result;
        _status = 'Schema extraction completed. Preparing download...';
      });

      final jsonText = const JsonEncoder.withIndent('  ').convert(result);

      final bytes = utf8.encode(jsonText);

      final blob = html.Blob([bytes], 'application/json');

      final url = html.Url.createObjectUrlFromBlob(blob);

      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'eumart_firestore_schema.json')
        ..style.display = 'none';

      html.document.body?.children.add(anchor);
      anchor.click();
      anchor.remove();

      html.Url.revokeObjectUrl(url);

      final accessibleCount = collectionResults.values
          .where((value) => value is Map && value['status'] == 'accessible')
          .length;

      final errorCount = collectionResults.values
          .where((value) => value is Map && value['status'] == 'error')
          .length;

      setState(() {
        _status =
            'DONE!\n'
            'Accessible collections: $accessibleCount\n'
            'Collections with errors: $errorCount\n\n'
            'The file eumart_firestore_schema.json was downloaded.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Firestore schema exported successfully.'),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _status = 'Schema export failed:\n$e';
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Schema export failed: $e')));
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Widget _buildResultPreview() {
    if (_schemaResult == null) {
      return const SizedBox.shrink();
    }

    final collections =
        _schemaResult!['collections'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Collection Results',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...collections.entries.map((entry) {
          final data = entry.value as Map<String, dynamic>;

          final status = data['status']?.toString() ?? '';

          return Card(
            child: ListTile(
              leading: Icon(
                status == 'accessible'
                    ? Icons.check_circle
                    : status == 'accessible_but_empty'
                    ? Icons.info
                    : Icons.error,
                color: status == 'accessible'
                    ? Colors.green
                    : status == 'accessible_but_empty'
                    ? Colors.orange
                    : Colors.red,
              ),
              title: Text(entry.key),
              subtitle: Text(
                status == 'accessible'
                    ? '${data['documentCountSampled']} sample document(s) read.'
                    : status == 'accessible_but_empty'
                    ? 'Collection is accessible but currently empty.'
                    : '${data['errorCode'] ?? 'Error'}: '
                          '${data['errorMessage'] ?? ''}',
              ),
            ),
          );
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('EÜ MART Firestore Schema Export')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Firestore Schema Exporter',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This tool reads Firestore using the currently '
                  'authenticated EÜ MART Owner account.',
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_status, style: const TextStyle(fontSize: 15)),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isExporting ? null : _exportSchema,
                    icon: _isExporting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(
                      _isExporting ? 'Exporting...' : 'Export Firestore Schema',
                    ),
                  ),
                ),
                _buildResultPreview(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
