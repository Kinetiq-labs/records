import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/supabase_sync_service.dart';
import '../models/sync_models.dart';
import '../providers/language_provider.dart';
import '../utils/bilingual_text_styles.dart';
import '../utils/translations.dart';

class SyncSettingsScreen extends StatefulWidget {
  const SyncSettingsScreen({super.key});

  @override
  State<SyncSettingsScreen> createState() => _SyncSettingsScreenState();
}

class _SyncSettingsScreenState extends State<SyncSettingsScreen> {
  final SupabaseSyncService _syncService = SupabaseSyncService();
  bool _isConnecting = false;
  String? _connectionError;

  @override
  void initState() {
    super.initState();
    _initializeSync();
  }

  Future<void> _initializeSync() async {
    try {
      await _syncService.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connectionError = e.toString();
        });
      }
    }
  }

  Future<void> _connectToSupabase() async {
    setState(() {
      _isConnecting = true;
      _connectionError = null;
    });

    try {
      final success = await _syncService.signInAnonymously();
      if (success && mounted) {
        setState(() {
          _isConnecting = false;
        });
        _showSuccessMessage('Connected to sync service successfully');
      } else {
        setState(() {
          _isConnecting = false;
          _connectionError = 'Authentication failed. Please enable anonymous authentication in Supabase or check your internet connection.';
        });
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
        _connectionError = 'Connection failed: Enable anonymous authentication in Supabase Dashboard > Authentication > Settings';
      });
    }
  }

  Future<void> _disconnect() async {
    try {
      await _syncService.signOut();
      if (mounted) {
        setState(() {});
        _showSuccessMessage('Disconnected from sync service');
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  Future<void> _performSync(SyncType type) async {
    final languageProvider = context.read<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;

    // TODO: Get actual tenant ID from user session
    const tenantId = 'default_tenant';

    try {
      final result = await _syncService.syncData(
        tenantId: tenantId,
        type: type,
      );

      if (mounted) {
        if (result.success) {
          String message = '';
          switch (type) {
            case SyncType.backup:
              message = currentLang == 'en'
                  ? 'Backup completed successfully. ${result.uploadedRecords} records uploaded.'
                  : 'بیک اپ کامیابی سے مکمل ہوا۔ ${result.uploadedRecords} ریکارڈز اپ لوڈ ہوئے۔';
              break;
            case SyncType.restore:
              message = currentLang == 'en'
                  ? 'Restore completed successfully. ${result.downloadedRecords} records downloaded.'
                  : 'بحالی کامیابی سے مکمل ہوئی۔ ${result.downloadedRecords} ریکارڈز ڈاؤن لوڈ ہوئے۔';
              break;
            case SyncType.full:
              message = currentLang == 'en'
                  ? 'Full sync completed. ${result.uploadedRecords} uploaded, ${result.downloadedRecords} downloaded.'
                  : 'مکمل ہم وقت سازی مکمل۔ ${result.uploadedRecords} اپ لوڈ، ${result.downloadedRecords} ڈاؤن لوڈ۔';
              break;
          }
          _showSuccessMessage(message);
        } else {
          _showErrorMessage(result.error ?? 'Sync failed');
        }
      }
    } catch (e) {
      _showErrorMessage(e.toString());
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: _syncService,
      child: Scaffold(
        appBar: AppBar(
          title: BilingualText.bilingual(
            Translations.get('sync_settings', currentLang),
            style: BilingualTextStyles.headlineSmall(
              Translations.get('sync_settings', currentLang),
              color: Colors.white,
            ),
          ),
          backgroundColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Consumer<SupabaseSyncService>(
          builder: (context, syncService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connection Status Card
                  _buildConnectionStatusCard(currentLang, isDarkMode),

                  const SizedBox(height: 16),

                  // Sync Actions Card
                  if (syncService.isAuthenticated) ...[
                    _buildSyncActionsCard(currentLang, isDarkMode),
                    const SizedBox(height: 16),
                  ],

                  // Sync Progress Card
                  if (syncService.currentProgress.status != SyncStatus.idle)
                    _buildSyncProgressCard(syncService.currentProgress, currentLang, isDarkMode),

                  const SizedBox(height: 16),

                  // Last Sync Stats Card
                  if (syncService.lastSyncStats != null)
                    _buildLastSyncStatsCard(syncService.lastSyncStats!, currentLang, isDarkMode),

                  const SizedBox(height: 16),

                  // Help & Information Card
                  _buildHelpCard(currentLang, isDarkMode),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildConnectionStatusCard(String currentLang, bool isDarkMode) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _syncService.isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
                  color: _syncService.isAuthenticated ? Colors.green : Colors.red,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BilingualText.bilingual(
                    currentLang == 'en' ? 'Connection Status' : 'کنکشن کی صورتحال',
                    style: BilingualTextStyles.titleMedium(
                      currentLang == 'en' ? 'Connection Status' : 'کنکشن کی صورتحال',
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            BilingualText.bilingual(
              _syncService.isAuthenticated
                  ? (currentLang == 'en' ? 'Connected to sync service' : 'ہم وقت سازی کی سروس سے جڑا ہوا')
                  : (currentLang == 'en' ? 'Not connected' : 'جڑا نہیں'),
              style: BilingualTextStyles.bodyMedium(
                _syncService.isAuthenticated
                    ? (currentLang == 'en' ? 'Connected to sync service' : 'ہم وقت سازی کی سروس سے جڑا ہوا')
                    : (currentLang == 'en' ? 'Not connected' : 'جڑا نہیں'),
                color: _syncService.isAuthenticated ? Colors.green : Colors.red,
              ),
            ),
            if (_connectionError != null) ...[
              const SizedBox(height: 8),
              Text(
                _connectionError!,
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnecting
                    ? null
                    : (_syncService.isAuthenticated ? _disconnect : _connectToSupabase),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _syncService.isAuthenticated
                      ? Colors.red
                      : (isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B)),
                  foregroundColor: Colors.white,
                ),
                child: _isConnecting
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                          const SizedBox(width: 8),
                          BilingualText.bilingual(
                            currentLang == 'en' ? 'Connecting...' : 'جڑ رہا ہے...',
                            style: BilingualTextStyles.labelMedium(
                              currentLang == 'en' ? 'Connecting...' : 'جڑ رہا ہے...',
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : BilingualText.bilingual(
                        _syncService.isAuthenticated
                            ? (currentLang == 'en' ? 'Disconnect' : 'منقطع کریں')
                            : (currentLang == 'en' ? 'Connect to Sync Service' : 'ہم وقت سازی سے جڑیں'),
                        style: BilingualTextStyles.labelMedium(
                          _syncService.isAuthenticated
                              ? (currentLang == 'en' ? 'Disconnect' : 'منقطع کریں')
                              : (currentLang == 'en' ? 'Connect to Sync Service' : 'ہم وقت سازی سے جڑیں'),
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncActionsCard(String currentLang, bool isDarkMode) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText.bilingual(
              currentLang == 'en' ? 'Sync Actions' : 'ہم وقت سازی کے اعمال',
              style: BilingualTextStyles.titleMedium(
                currentLang == 'en' ? 'Sync Actions' : 'ہم وقت سازی کے اعمال',
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Backup Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _performSync(SyncType.backup),
                icon: const Icon(Icons.backup, color: Colors.white),
                label: BilingualText.bilingual(
                  currentLang == 'en' ? 'Backup Data' : 'ڈیٹا کا بیک اپ',
                  style: BilingualTextStyles.labelMedium(
                    currentLang == 'en' ? 'Backup Data' : 'ڈیٹا کا بیک اپ',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Restore Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _performSync(SyncType.restore),
                icon: const Icon(Icons.restore, color: Colors.white),
                label: BilingualText.bilingual(
                  currentLang == 'en' ? 'Restore Data' : 'ڈیٹا کی بحالی',
                  style: BilingualTextStyles.labelMedium(
                    currentLang == 'en' ? 'Restore Data' : 'ڈیٹا کی بحالی',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Full Sync Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _performSync(SyncType.full),
                icon: const Icon(Icons.sync, color: Colors.white),
                label: BilingualText.bilingual(
                  currentLang == 'en' ? 'Full Sync' : 'مکمل ہم وقت سازی',
                  style: BilingualTextStyles.labelMedium(
                    currentLang == 'en' ? 'Full Sync' : 'مکمل ہم وقت سازی',
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncProgressCard(SyncProgress progress, String currentLang, bool isDarkMode) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText.bilingual(
              currentLang == 'en' ? 'Sync Progress' : 'ہم وقت سازی کی پیش قدمی',
              style: BilingualTextStyles.titleMedium(
                currentLang == 'en' ? 'Sync Progress' : 'ہم وقت سازی کی پیش قدمی',
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress.progress * 100).toInt()}%',
              style: TextStyle(
                color: isDarkMode ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (progress.currentOperation != null) ...[
              const SizedBox(height: 8),
              Text(
                progress.currentOperation!,
                style: TextStyle(
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLastSyncStatsCard(SyncStatistics stats, String currentLang, bool isDarkMode) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText.bilingual(
              currentLang == 'en' ? 'Last Sync Statistics' : 'آخری ہم وقت سازی کے اعداد و شمار',
              style: BilingualTextStyles.titleMedium(
                currentLang == 'en' ? 'Last Sync Statistics' : 'آخری ہم وقت سازی کے اعداد و شمار',
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            _buildStatRow(
              currentLang == 'en' ? 'Duration:' : 'مدت:',
              '${stats.duration.inMinutes}m ${stats.duration.inSeconds % 60}s',
              isDarkMode,
            ),
            _buildStatRow(
              currentLang == 'en' ? 'Uploaded:' : 'اپ لوڈ:',
              '${stats.uploadedRecords} records',
              isDarkMode,
            ),
            _buildStatRow(
              currentLang == 'en' ? 'Downloaded:' : 'ڈاؤن لوڈ:',
              '${stats.downloadedRecords} records',
              isDarkMode,
            ),
            if (stats.errors.isNotEmpty)
              _buildStatRow(
                currentLang == 'en' ? 'Errors:' : 'خرابیاں:',
                '${stats.errors.length}',
                isDarkMode,
                textColor: Colors.red,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDarkMode, {Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: textColor ?? (isDarkMode ? Colors.white : Colors.black87),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpCard(String currentLang, bool isDarkMode) {
    return Card(
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BilingualText.bilingual(
              currentLang == 'en' ? 'How Sync Works' : 'ہم وقت سازی کیسے کام کرتی ہے',
              style: BilingualTextStyles.titleMedium(
                currentLang == 'en' ? 'How Sync Works' : 'ہم وقت سازی کیسے کام کرتی ہے',
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            BilingualText.bilingual(
              currentLang == 'en'
                  ? '• Backup: Upload your local data to the cloud\n• Restore: Download data from the cloud to your device\n• Full Sync: Upload and download to keep everything in sync\n\nYour data is encrypted and secure.'
                  : '• بیک اپ: اپنا مقامی ڈیٹا کلاؤڈ میں اپ لوڈ کریں\n• بحالی: کلاؤڈ سے اپنے ڈیوائس میں ڈیٹا ڈاؤن لوڈ کریں\n• مکمل ہم وقت سازی: سب کچھ ہم وقت رکھنے کے لیے اپ لوڈ اور ڈاؤن لوڈ\n\nآپ کا ڈیٹا محفوظ اور خفیہ ہے۔',
              style: BilingualTextStyles.bodySmall(
                currentLang == 'en'
                    ? '• Backup: Upload your local data to the cloud\n• Restore: Download data from the cloud to your device\n• Full Sync: Upload and download to keep everything in sync\n\nYour data is encrypted and secure.'
                    : '• بیک اپ: اپنا مقامی ڈیٹا کلاؤڈ میں اپ لوڈ کریں\n• بحالی: کلاؤڈ سے اپنے ڈیوائس میں ڈیٹا ڈاؤن لوڈ کریں\n• مکمل ہم وقت سازی: سب کچھ ہم وقت رکھنے کے لیے اپ لوڈ اور ڈاؤن لوڈ\n\nآپ کا ڈیٹا محفوظ اور خفیہ ہے۔',
                color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}