import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/audit_log_service.dart';

class _BackupHoverCard extends StatefulWidget {
  final Widget child;

  const _BackupHoverCard({required this.child});

  @override
  State<_BackupHoverCard> createState() => _BackupHoverCardState();
}

class _BackupHoverCardState extends State<_BackupHoverCard> {
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

class _BackupVisualIcon extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _BackupVisualIcon({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.72)],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.22),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _BackupInfoLine extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _BackupInfoLine({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            color: const Color(0xFFEAF3FF),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF1565C0), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF172033),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF7D8998),
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BackupCollectionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String recordCount;
  final bool loading;
  final VoidCallback? onPressed;

  const _BackupCollectionCard({
    required this.title,
    required this.icon,
    required this.recordCount,
    required this.loading,
    required this.onPressed,
  });

  @override
  State<_BackupCollectionCard> createState() => _BackupCollectionCardState();
}

class _BackupCollectionCardState extends State<_BackupCollectionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    const color = Color(0xFF1565C0);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Colors.white, Color(0xFFF8FBFF)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _hovered ? const Color(0xFF9CC5EF) : const Color(0xFFDDE6F1),
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
                _BackupVisualIcon(icon: widget.icon, color: color),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'CSV',
                    style: TextStyle(
                      color: color,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF172033),
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.recordCount,
              style: const TextStyle(color: Color(0xFF7D8998), fontSize: 11.5),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: OutlinedButton.icon(
                onPressed: widget.onPressed,
                style: OutlinedButton.styleFrom(
                  foregroundColor: color,
                  side: const BorderSide(color: Color(0xFFB8D4F0)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                ),
                icon: widget.loading
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: color,
                        ),
                      )
                    : const Icon(Icons.download_outlined),
                label: Text(
                  widget.loading ? 'EXPORTING...' : 'EXPORT CSV',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BackupExportScreen extends StatefulWidget {
  const BackupExportScreen({super.key});

  @override
  State<BackupExportScreen> createState() => _BackupExportScreenState();
}

class _BackupExportScreenState extends State<BackupExportScreen> {
  bool _exporting = false;
  bool _restoring = false;
  String _statusMessage = '';

  Map<String, dynamic>? _restoreBackup;
  String _restoreFileName = '';
  final Set<String> _selectedRestoreCollections = <String>{};

  final List<_BackupCollection> _collections = const [
    _BackupCollection(
      name: 'products',
      title: 'Products',
      icon: Icons.inventory_2_outlined,
    ),
    _BackupCollection(
      name: 'transactions',
      title: 'Transactions',
      icon: Icons.receipt_long_outlined,
    ),
    _BackupCollection(
      name: 'users',
      title: 'Users',
      icon: Icons.groups_outlined,
    ),
    _BackupCollection(
      name: 'customer_feedback',
      title: 'Customer Feedback',
      icon: Icons.reviews_outlined,
    ),
    _BackupCollection(
      name: 'audit_logs',
      title: 'Audit Logs',
      icon: Icons.history,
    ),
    _BackupCollection(
      name: 'settings',
      title: 'Settings',
      icon: Icons.settings_outlined,
    ),
    _BackupCollection(
      name: 'suppliers',
      title: 'Suppliers',
      icon: Icons.local_shipping_outlined,
    ),
    _BackupCollection(
      name: 'promotions',
      title: 'Promotions',
      icon: Icons.local_offer_outlined,
    ),
    _BackupCollection(
      name: 'permit_reminders',
      title: 'Permit Reminders',
      icon: Icons.description_outlined,
    ),
    _BackupCollection(
      name: 'service_issues',
      title: 'Service Issues',
      icon: Icons.report_problem_outlined,
    ),
    _BackupCollection(
      name: 'stock_movements',
      title: 'Stock Movements',
      icon: Icons.swap_vert_circle_outlined,
    ),
    _BackupCollection(
      name: 'cash_sessions',
      title: 'Cash Sessions',
      icon: Icons.account_balance_wallet_outlined,
    ),
  ];

  Map<String, dynamic> _serializeValue(dynamic value) {
    if (value is Timestamp) {
      return <String, dynamic>{
        '__type': 'timestamp',
        'value': value.toDate().toIso8601String(),
      };
    }

    if (value is DocumentReference) {
      return <String, dynamic>{
        '__type': 'documentReference',
        'value': value.path,
      };
    }

    if (value is GeoPoint) {
      return <String, dynamic>{
        '__type': 'geoPoint',
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }

    if (value is List) {
      return <String, dynamic>{
        '__type': 'list',
        'value': value.map(_serializeAny).toList(),
      };
    }

    if (value is Map) {
      return <String, dynamic>{
        '__type': 'map',
        'value': value.map(
          (key, item) => MapEntry(key.toString(), _serializeAny(item)),
        ),
      };
    }

    return <String, dynamic>{'__type': 'value', 'value': value};
  }

  dynamic _serializeAny(dynamic value) {
    if (value is Timestamp) {
      return value.toDate().toIso8601String();
    }

    if (value is DocumentReference) {
      return value.path;
    }

    if (value is GeoPoint) {
      return <String, dynamic>{
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }

    if (value is List) {
      return value.map(_serializeAny).toList();
    }

    if (value is Map) {
      return value.map(
        (key, item) => MapEntry(key.toString(), _serializeAny(item)),
      );
    }

    return value;
  }

  Future<Map<String, dynamic>> _readCollection(String collectionName) async {
    final snapshot = await FirebaseFirestore.instance
        .collection(collectionName)
        .get();

    final documents = <Map<String, dynamic>>[];

    for (final document in snapshot.docs) {
      documents.add({
        'id': document.id,
        'data': document.data().map(
          (key, value) => MapEntry(key, _serializeAny(value)),
        ),
      });
    }

    return {
      'collection': collectionName,
      'documentCount': documents.length,
      'documents': documents,
    };
  }

  String _timestampForFileName() {
    final now = DateTime.now();

    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
  }

  void _downloadTextFile({
    required String fileName,
    required String content,
    required String mimeType,
  }) {
    final bytes = utf8.encode(content);
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();

    html.Url.revokeObjectUrl(url);
  }

  Future<void> _exportFullBackup() async {
    setState(() {
      _exporting = true;
      _statusMessage = 'Preparing full backup...';
    });

    try {
      final data = <String, dynamic>{
        'system': 'EÜ MART Web',
        'backupVersion': 1,
        'generatedAt': DateTime.now().toIso8601String(),
        'collections': <String, dynamic>{},
      };

      for (final collection in _collections) {
        setState(() {
          _statusMessage = 'Reading ${collection.title}...';
        });

        data['collections'][collection.name] = await _readCollection(
          collection.name,
        );
      }

      final fileName = 'eumart_backup_${_timestampForFileName()}.json';

      _downloadTextFile(
        fileName: fileName,
        content: const JsonEncoder.withIndent('  ').convert(data),
        mimeType: 'application/json;charset=utf-8',
      );

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Full backup downloaded successfully.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full JSON backup downloaded.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Backup failed.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to create backup: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  String _csvEscape(dynamic value) {
    if (value == null) return '';

    final text = value is List || value is Map
        ? jsonEncode(_serializeAny(value))
        : value.toString();

    final escaped = text.replaceAll('"', '""');

    return '"$escaped"';
  }

  Future<void> _exportCollectionCsv(_BackupCollection collection) async {
    setState(() {
      _exporting = true;
      _statusMessage = 'Exporting ${collection.title}...';
    });

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(collection.name)
          .get();

      final allKeys = <String>{};

      for (final document in snapshot.docs) {
        allKeys.addAll(document.data().keys);
      }

      final sortedKeys = allKeys.toList()..sort();
      final rows = <String>[];

      rows.add(
        [_csvEscape('documentId'), ...sortedKeys.map(_csvEscape)].join(','),
      );

      for (final document in snapshot.docs) {
        final data = document.data();

        rows.add(
          [
            _csvEscape(document.id),
            ...sortedKeys.map((key) => _csvEscape(data[key])),
          ].join(','),
        );
      }

      final fileName = '${collection.name}_${_timestampForFileName()}.csv';

      _downloadTextFile(
        fileName: fileName,
        content: rows.join('\n'),
        mimeType: 'text/csv;charset=utf-8',
      );

      if (!mounted) return;

      setState(() {
        _statusMessage = '${collection.title} CSV downloaded.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${collection.title} exported successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Export failed.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to export ${collection.title}: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _exporting = false);
      }
    }
  }

  Widget _collectionCard(_BackupCollection collection) {
    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection(collection.name).get(),
      builder: (context, snapshot) {
        final count = snapshot.data?.docs.length;

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F2FD),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      collection.icon,
                      color: const Color(0xFF1565C0),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    count == null ? '...' : '$count records',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                collection.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _exporting
                      ? null
                      : () => _exportCollectionCsv(collection),
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('EXPORT CSV'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static const Set<String> _restorableCollections = {
    'products',
    'suppliers',
    'promotions',
    'settings',
    'permit_reminders',
  };

  dynamic _restoreValue(dynamic value) {
    if (value is List) {
      return value.map(_restoreValue).toList();
    }

    if (value is Map) {
      final converted = Map<String, dynamic>.from(value);

      if (converted.length == 2 &&
          converted['__type'] == 'timestamp' &&
          converted['value'] is String) {
        final parsed = DateTime.tryParse(converted['value'] as String);

        return parsed == null ? converted['value'] : Timestamp.fromDate(parsed);
      }

      if (converted['__type'] == 'geoPoint') {
        final latitude = (converted['latitude'] as num?)?.toDouble();
        final longitude = (converted['longitude'] as num?)?.toDouble();

        if (latitude != null && longitude != null) {
          return GeoPoint(latitude, longitude);
        }
      }

      return converted.map((key, item) => MapEntry(key, _restoreValue(item)));
    }

    if (value is String) {
      final parsed = DateTime.tryParse(value);

      if (parsed != null &&
          value.contains('T') &&
          (value.endsWith('Z') ||
              value.contains('+') ||
              RegExp(r'T\d{2}:\d{2}:\d{2}').hasMatch(value))) {
        return Timestamp.fromDate(parsed);
      }
    }

    return value;
  }

  Future<void> _selectBackupFile() async {
    final input = html.FileUploadInputElement()
      ..accept = '.json,application/json';

    input.click();

    await input.onChange.first;

    final file = input.files?.isEmpty ?? true ? null : input.files!.first;

    if (file == null) return;

    setState(() {
      _restoring = true;
      _statusMessage = 'Reading backup file...';
    });

    try {
      final reader = html.FileReader();
      reader.readAsText(file);
      await reader.onLoad.first;

      final rawText = reader.result?.toString() ?? '';
      final decoded = jsonDecode(rawText);

      if (decoded is! Map) {
        throw const FormatException('Invalid backup structure.');
      }

      final backup = Map<String, dynamic>.from(decoded);

      if (backup['system'] != 'EÜ MART Web' || backup['collections'] is! Map) {
        throw const FormatException('This is not a valid EÜ MART backup file.');
      }

      final collections = Map<String, dynamic>.from(
        backup['collections'] as Map,
      );

      final available = collections.keys
          .where(_restorableCollections.contains)
          .toSet();

      if (available.isEmpty) {
        throw const FormatException(
          'The backup contains no restorable collections.',
        );
      }

      if (!mounted) return;

      setState(() {
        _restoreBackup = backup;
        _restoreFileName = file.name;
        _selectedRestoreCollections
          ..clear()
          ..addAll(available);
        _statusMessage = 'Backup preview ready.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _restoreBackup = null;
        _restoreFileName = '';
        _selectedRestoreCollections.clear();
        _statusMessage = 'Unable to read backup file.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid backup file: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  int _restoreDocumentCount(String collectionName) {
    final backup = _restoreBackup;

    if (backup == null) return 0;

    final collections = backup['collections'];

    if (collections is! Map) return 0;

    final collectionData = collections[collectionName];

    if (collectionData is! Map) return 0;

    final documents = collectionData['documents'];

    return documents is List ? documents.length : 0;
  }

  Future<void> _restoreSelectedCollections() async {
    final backup = _restoreBackup;

    if (backup == null || _selectedRestoreCollections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one collection to restore.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Backup Restore'),
          content: SizedBox(
            width: 520,
            child: Text(
              'The selected backup records will be merged '
              'into the live Firestore database. Existing '
              'documents with the same IDs will be replaced.\n\n'
              'Selected collections: '
              '${_selectedRestoreCollections.join(', ')}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.restore),
              label: const Text('RESTORE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _restoring = true;
      _statusMessage = 'Restoring selected collections...';
    });

    try {
      final collections = Map<String, dynamic>.from(
        backup['collections'] as Map,
      );

      int restoredDocuments = 0;

      for (final collectionName in _selectedRestoreCollections) {
        final collectionRaw = collections[collectionName];

        if (collectionRaw is! Map) continue;

        final collectionData = Map<String, dynamic>.from(collectionRaw);

        final documents = collectionData['documents'];

        if (documents is! List) continue;

        var batch = FirebaseFirestore.instance.batch();
        int batchCount = 0;

        for (final rawDocument in documents) {
          if (rawDocument is! Map) continue;

          final document = Map<String, dynamic>.from(rawDocument);

          final id = (document['id'] ?? '').toString();

          final rawData = document['data'];

          if (id.isEmpty || rawData is! Map) {
            continue;
          }

          final restoredData = Map<String, dynamic>.from(
            _restoreValue(rawData) as Map,
          );

          final reference = FirebaseFirestore.instance
              .collection(collectionName)
              .doc(id);

          batch.set(reference, restoredData, SetOptions(merge: false));

          batchCount++;
          restoredDocuments++;

          if (batchCount == 400) {
            await batch.commit();
            batch = FirebaseFirestore.instance.batch();
            batchCount = 0;
          }
        }

        if (batchCount > 0) {
          await batch.commit();
        }
      }

      await AuditLogService.backupRestored(
        documentCount: restoredDocuments,
        collections: _selectedRestoreCollections.toList(),
      );

      if (!mounted) return;

      setState(() {
        _statusMessage = 'Restore completed successfully.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$restoredDocuments document(s) restored.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseException catch (error) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Restore failed.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'permission-denied'
                ? 'Permission denied while restoring. '
                      'Check the Firestore rules.'
                : 'Restore failed: '
                      '${error.message ?? error.code}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _statusMessage = 'Restore failed.';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to restore backup: $error'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  Widget _restoreSection() {
    final backup = _restoreBackup;

    final collections = backup == null || backup['collections'] is! Map
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(backup['collections'] as Map);

    final availableCollections =
        collections.keys.where(_restorableCollections.contains).toList()
          ..sort();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Backup Recovery',
                      style: TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Select a JSON backup, preview its '
                      'records, then restore only the '
                      'approved operational collections.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _restoring ? null : _selectBackupFile,
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('SELECT BACKUP FILE'),
              ),
            ],
          ),
          if (backup != null) ...[
            const SizedBox(height: 18),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'File: $_restoreFileName\n'
                'Generated: '
                '${backup['generatedAt'] ?? 'Unavailable'}',
                style: const TextStyle(
                  color: Color(0xFF1565C0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ...availableCollections.map((collectionName) {
              final selected = _selectedRestoreCollections.contains(
                collectionName,
              );

              return CheckboxListTile(
                value: selected,
                contentPadding: EdgeInsets.zero,
                title: Text(collectionName),
                subtitle: Text(
                  '${_restoreDocumentCount(collectionName)} '
                  'document(s)',
                ),
                onChanged: _restoring
                    ? null
                    : (value) {
                        setState(() {
                          if (value == true) {
                            _selectedRestoreCollections.add(collectionName);
                          } else {
                            _selectedRestoreCollections.remove(collectionName);
                          }
                        });
                      },
              );
            }),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _restoring ? null : _restoreSelectedCollections,
                icon: _restoring
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restore),
                label: Text(_restoring ? 'RESTORING...' : 'RESTORE SELECTED'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF2F6FC),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1180),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
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
                      final compact = constraints.maxWidth < 720;

                      final information = Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0x2AFFFFFF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.backup_outlined,
                              color: Colors.white,
                              size: 29,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Backup & Export',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Download a complete JSON backup or export '
                                  'individual Firestore collections as CSV.',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    height: 1.35,
                                  ),
                                ),
                                if (_statusMessage.isNotEmpty) ...[
                                  const SizedBox(height: 9),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0x24FFFFFF),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _statusMessage,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      );

                      final button = SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _exporting ? null : _exportFullBackup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1565C0),
                            disabledBackgroundColor: Colors.white60,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: _exporting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Color(0xFF1565C0),
                                  ),
                                )
                              : const Icon(Icons.cloud_download_outlined),
                          label: Text(
                            _exporting
                                ? 'PREPARING...'
                                : 'DOWNLOAD FULL BACKUP',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                        ),
                      );

                      if (compact) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            information,
                            const SizedBox(height: 16),
                            button,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: information),
                          const SizedBox(width: 18),
                          button,
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 18),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 760;

                    final securityCard = _BackupHoverCard(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.white, Color(0xFFFBFDFF)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE1E9F3)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _BackupVisualIcon(
                                  icon: Icons.shield_outlined,
                                  color: Color(0xFF1565C0),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Secure Store Backup',
                                        style: TextStyle(
                                          color: Color(0xFF172033),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      SizedBox(height: 3),
                                      Text(
                                        'Exports do not modify or remove live records.',
                                        style: TextStyle(
                                          color: Color(0xFF8A95A4),
                                          fontSize: 11.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            _BackupInfoLine(
                              icon: Icons.check_circle_outline,
                              title: 'Read-only download',
                              subtitle:
                                  'Data is copied from Firestore into downloadable files.',
                            ),
                            SizedBox(height: 11),
                            _BackupInfoLine(
                              icon: Icons.history_outlined,
                              title: 'Audit-ready',
                              subtitle:
                                  'Backup and restore actions remain traceable.',
                            ),
                            SizedBox(height: 11),
                            _BackupInfoLine(
                              icon: Icons.folder_zip_outlined,
                              title: 'Organized formats',
                              subtitle:
                                  'Use JSON for full backup and CSV for collection reports.',
                            ),
                          ],
                        ),
                      ),
                    );

                    final reminderCard = _BackupHoverCard(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF7E6), Color(0xFFFFFBF3)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFF5D9A8)),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.lightbulb_outline_rounded,
                              color: Color(0xFFF59E0B),
                              size: 31,
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Backup Reminder',
                              style: TextStyle(
                                color: Color(0xFF172033),
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Create a backup weekly and before major '
                              'inventory or account changes. Keep files '
                              'in a secure folder.',
                              style: TextStyle(
                                color: Color(0xFF6B5A36),
                                height: 1.45,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );

                    if (compact) {
                      return Column(
                        children: [
                          securityCard,
                          const SizedBox(height: 14),
                          reminderCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 3, child: securityCard),
                        const SizedBox(width: 14),
                        Expanded(flex: 2, child: reminderCard),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 22),
                const Text(
                  'Collection Exports',
                  style: TextStyle(
                    color: Color(0xFF172033),
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Export individual collections as CSV for reports, '
                  'review, or spreadsheet analysis.',
                  style: TextStyle(color: Color(0xFF7D8998), fontSize: 12),
                ),
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _collections.length,
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 360,
                    mainAxisExtent: 228,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemBuilder: (context, index) {
                    final collection = _collections[index];

                    return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      future: FirebaseFirestore.instance
                          .collection(collection.name)
                          .get(),
                      builder: (context, snapshot) {
                        final count = snapshot.data?.docs.length;

                        return _BackupCollectionCard(
                          title: collection.title,
                          icon: collection.icon,
                          recordCount: count == null
                              ? 'Loading...'
                              : '$count record(s)',
                          loading: _exporting,
                          onPressed: _exporting
                              ? null
                              : () => _exportCollectionCsv(collection),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 22),
                _BackupHoverCard(child: _restoreSection()),
                const SizedBox(height: 18),
                _BackupHoverCard(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFF3E0), Color(0xFFFFFBF5)],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFF4D3A0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 21,
                          backgroundColor: Color(0x1AF59E0B),
                          child: Icon(
                            Icons.info_outline,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'The exported files contain real store records. '
                            'Do not share files containing cashier emails, '
                            'transactions, or customer feedback publicly.',
                            style: TextStyle(
                              color: Color(0xFF6B5A36),
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BackupCollection {
  final String name;
  final String title;
  final IconData icon;

  const _BackupCollection({
    required this.name,
    required this.title,
    required this.icon,
  });
}
