import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/admin_providers.dart';

String _extractErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.isNotEmpty) {
        return message;
      }
      if (data['data'] is Map) {
        final nestedMessage = data['data']['message'] ?? data['data']['error'];
        if (nestedMessage is String && nestedMessage.isNotEmpty) {
          return nestedMessage;
        }
      }
    }
    if (error.response?.statusCode != null) {
      return 'The server returned ${error.response!.statusCode}. Please try again.';
    }
    if (error.message != null && error.message!.isNotEmpty) {
      return error.message!;
    }
  }
  return error.toString();
}

const _reportTypeLabels = <String, String>{
  'users': 'Users Report',
  'subscriptions': 'Subscriptions Report',
  'payments': 'Payments Report',
  'revenue': 'Revenue Report',
  'ai_usage': 'AI Usage Report',
  'wardrobe': 'Wardrobe Report',
  'outfits': 'Outfits Report',
  'laundry': 'Laundry Report',
  'trips': 'Trips Report',
};

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() =>
      _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  List<String>? _reportTypes;
  String? _typesError;
  String _selectedType = 'users';
  DateTimeRange? _dateRange;
  final _statusController = TextEditingController();
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadReportTypes();
  }

  @override
  void dispose() {
    _statusController.dispose();
    super.dispose();
  }

  Future<void> _loadReportTypes() async {
    try {
      final types = await ref.read(adminRepositoryProvider).getReportTypes();
      if (!mounted) return;
      setState(() {
        _reportTypes = types.isNotEmpty ? types : _reportTypeLabels.keys.toList();
        if (!_reportTypes!.contains(_selectedType)) {
          _selectedType = _reportTypes!.first;
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _reportTypes = _reportTypeLabels.keys.toList();
        _typesError = _extractErrorMessage(error);
      });
    }
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _dateRange,
    );
    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  Future<void> _export() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await ref.read(adminRepositoryProvider).exportReport(
            type: _selectedType,
            format: 'csv',
            from: _dateRange?.start.toIso8601String(),
            to: _dateRange?.end.toIso8601String(),
            status: _statusController.text.trim().isEmpty
                ? null
                : _statusController.text.trim(),
          );

      final fileName = '$_selectedType-report.csv';
      final file = XFile.fromData(
        Uint8List.fromList(bytes),
        name: fileName,
        mimeType: 'text/csv',
      );

      await Share.shareXFiles([file], fileNameOverrides: [fileName]);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Exported $fileName.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: ${_extractErrorMessage(error)}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final types = _reportTypes ?? _reportTypeLabels.keys.toList();
    final dateFormat = DateFormat('MMM d, yyyy');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Reports', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          'Export CSV reports for offline analysis or record keeping.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (_typesError != null) ...[
          const SizedBox(height: 8),
          Text(
            'Could not load report types from server, showing defaults: $_typesError',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report type',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final type in types)
                      ChoiceChip(
                        label: Text(_reportTypeLabels[type] ?? type),
                        selected: _selectedType == type,
                        onSelected: (_) =>
                            setState(() => _selectedType = type),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Date range (optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon: const Icon(Icons.date_range_outlined),
                        label: Text(
                          _dateRange == null
                              ? 'Select date range'
                              : '${dateFormat.format(_dateRange!.start)} '
                                  '- ${dateFormat.format(_dateRange!.end)}',
                        ),
                      ),
                    ),
                    if (_dateRange != null)
                      IconButton(
                        tooltip: 'Clear date range',
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _dateRange = null),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Status filter (optional)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _statusController,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    hintText: 'e.g. active, success, cancelled',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: _isExporting ? null : _export,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.download_outlined),
                  label: Text(_isExporting ? 'Exporting...' : 'Export CSV'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
