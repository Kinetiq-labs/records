import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/supabase_sync_service.dart';
import '../models/sync_models.dart';
import '../providers/language_provider.dart';
import '../utils/bilingual_text_styles.dart';

class SupabaseSyncDialog extends StatefulWidget {
  const SupabaseSyncDialog({super.key});

  @override
  State<SupabaseSyncDialog> createState() => _SupabaseSyncDialogState();
}

class _SupabaseSyncDialogState extends State<SupabaseSyncDialog> {
  bool _isConnecting = false;

  Future<void> _connectToSupabase() async {
    final syncService = context.read<SupabaseSyncService>();
    final languageProvider = context.read<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;

    setState(() {
      _isConnecting = true;
    });

    try {
      // Use the existing app credentials for authentication
      final success = await syncService.signInWithCredentials(
        email: 'demo@records.app',
        password: 'user1234',
      );

      if (success && mounted) {
        setState(() {
          _isConnecting = false;
        });
        _showSuccessNotification(
          currentLang == 'en'
              ? 'Connected to sync service successfully'
              : 'ہم وقت سازی سروس سے کامیابی سے جڑ گئے',
        );
      } else {
        setState(() {
          _isConnecting = false;
        });
        _showConnectionErrorDialog(currentLang);
      }
    } catch (e) {
      setState(() {
        _isConnecting = false;
      });
      _showConnectionErrorDialog(currentLang);
    }
  }

  Future<void> _disconnect() async {
    final syncService = context.read<SupabaseSyncService>();
    final languageProvider = context.read<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;

    try {
      await syncService.signOut();
      if (mounted) {
        setState(() {});
        _showSuccessNotification(
          currentLang == 'en'
              ? 'Disconnected from sync service'
              : 'ہم وقت سازی سروس سے منقطع ہو گئے',
        );
      }
    } catch (e) {
      _showErrorNotification(
        currentLang == 'en'
            ? 'Failed to disconnect'
            : 'منقطع ہونے میں ناکام',
      );
    }
  }

  Future<void> _performSync(SyncType type) async {
    final syncService = context.read<SupabaseSyncService>();
    final languageProvider = context.read<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;

    // TODO: Get actual tenant ID from user session
    const tenantId = 'default_tenant';

    try {
      final result = await syncService.syncData(
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
          _showSuccessNotification(message);
        } else {
          _showSyncErrorDialog(result.error ?? 'Sync failed', currentLang);
        }
      }
    } catch (e) {
      _showSyncErrorDialog(e.toString(), currentLang);
    }
  }

  void _showSuccessNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showConnectionErrorDialog(String currentLang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          currentLang == 'en' ? 'Connection Failed' : 'کنکشن ناکام',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentLang == 'en'
                  ? 'Cannot connect to sync service. Please:'
                  : 'ہم وقت سازی سروس سے رابطہ نہیں ہو سکا۔ برائے کرم:',
            ),
            const SizedBox(height: 12),
            Text(
              currentLang == 'en'
                  ? '1. Enable Anonymous Authentication in Supabase'
                  : '۱. Supabase میں Anonymous Authentication فعال کریں',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              currentLang == 'en'
                  ? '2. Check your internet connection'
                  : '۲. اپنا انٹرنیٹ کنکشن چیک کریں',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              currentLang == 'en'
                  ? 'Go to: Supabase Dashboard → Authentication → Settings'
                  : 'یہاں جائیں: Supabase Dashboard → Authentication → Settings',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              currentLang == 'en' ? 'OK' : 'ٹھیک ہے',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showSyncErrorDialog(String error, String currentLang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          currentLang == 'en' ? 'Sync Error' : 'ہم وقت سازی میں خرابی',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              currentLang == 'en'
                  ? 'The sync operation failed:'
                  : 'ہم وقت سازی کا عمل ناکام ہوا:',
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                error,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              currentLang == 'en'
                  ? 'Please check your connection and try again.'
                  : 'برائے کرم اپنا کنکشن چیک کریں اور دوبارہ کوشش کریں۔',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              currentLang == 'en' ? 'OK' : 'ٹھیک ہے',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Consumer<SupabaseSyncService>(
      builder: (context, syncService, child) {
        return AlertDialog(
          backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
          title: BilingualText.bilingual(
            currentLang == 'en' ? 'Sync Settings' : 'ہم وقت سازی کی ترتیبات',
            style: BilingualTextStyles.titleLarge(
              currentLang == 'en' ? 'Sync Settings' : 'ہم وقت سازی کی ترتیبات',
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Connection Status Card
                _buildConnectionStatusSection(syncService, currentLang, isDarkMode),

                const SizedBox(height: 16),

                // Sync Actions (only show if authenticated)
                if (syncService.isAuthenticated) ...[
                  _buildSyncActionsSection(currentLang, isDarkMode),
                  const SizedBox(height: 16),
                ],

                // Sync Progress (only show if active)
                if (syncService.currentProgress.status != SyncStatus.idle)
                  _buildSyncProgressSection(syncService.currentProgress, currentLang, isDarkMode),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: BilingualText.bilingual(
                currentLang == 'en' ? 'Close' : 'بند کریں',
                style: BilingualTextStyles.labelMedium(
                  currentLang == 'en' ? 'Close' : 'بند کریں',
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildConnectionStatusSection(SupabaseSyncService syncService, String currentLang, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              syncService.isAuthenticated ? Icons.cloud_done : Icons.cloud_off,
              color: syncService.isAuthenticated ? Colors.green : Colors.red,
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
        const SizedBox(height: 8),
        BilingualText.bilingual(
          syncService.isAuthenticated
              ? (currentLang == 'en' ? 'Connected to sync service' : 'ہم وقت سازی کی سروس سے جڑا ہوا')
              : (currentLang == 'en' ? 'Not connected' : 'جڑا نہیں'),
          style: BilingualTextStyles.bodyMedium(
            syncService.isAuthenticated
                ? (currentLang == 'en' ? 'Connected to sync service' : 'ہم وقت سازی کی سروس سے جڑا ہوا')
                : (currentLang == 'en' ? 'Not connected' : 'جڑا نہیں'),
            color: syncService.isAuthenticated ? Colors.green : Colors.red,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isConnecting
                ? null
                : (syncService.isAuthenticated ? _disconnect : _connectToSupabase),
            style: ElevatedButton.styleFrom(
              backgroundColor: syncService.isAuthenticated
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
                    syncService.isAuthenticated
                        ? (currentLang == 'en' ? 'Disconnect' : 'منقطع کریں')
                        : (currentLang == 'en' ? 'Connect to Sync Service' : 'ہم وقت سازی سے جڑیں'),
                    style: BilingualTextStyles.labelMedium(
                      syncService.isAuthenticated
                          ? (currentLang == 'en' ? 'Disconnect' : 'منقطع کریں')
                          : (currentLang == 'en' ? 'Connect to Sync Service' : 'ہم وقت سازی سے جڑیں'),
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncActionsSection(String currentLang, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BilingualText.bilingual(
          currentLang == 'en' ? 'Sync Actions' : 'ہم وقت سازی کے اعمال',
          style: BilingualTextStyles.titleMedium(
            currentLang == 'en' ? 'Sync Actions' : 'ہم وقت سازی کے اعمال',
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncProgressSection(SyncProgress progress, String currentLang, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BilingualText.bilingual(
          currentLang == 'en' ? 'Sync Progress' : 'ہم وقت سازی کی پیش قدمی',
          style: BilingualTextStyles.titleMedium(
            currentLang == 'en' ? 'Sync Progress' : 'ہم وقت سازی کی پیش قدمی',
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
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
    );
  }
}