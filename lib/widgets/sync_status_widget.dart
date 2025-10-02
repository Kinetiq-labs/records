import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/supabase_sync_service.dart';
import '../models/sync_models.dart';
import '../providers/language_provider.dart';
import '../utils/bilingual_text_styles.dart';
import 'supabase_sync_dialog.dart';

class SyncStatusWidget extends StatelessWidget {
  final bool showLabel;
  final bool showProgress;
  final VoidCallback? onConfigurePressed;

  const SyncStatusWidget({
    super.key,
    this.showLabel = true,
    this.showProgress = false,
    this.onConfigurePressed,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Try to get existing sync service from provider tree
    try {
      return Consumer<SupabaseSyncService>(
        builder: (context, syncService, child) {
          return GestureDetector(
            onTap: onConfigurePressed ?? () {
              showDialog(
                context: context,
                builder: (context) => const SupabaseSyncDialog(),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getBackgroundColor(syncService, isDarkMode),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _getBorderColor(syncService, isDarkMode),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getStatusIcon(syncService),
                    size: 16,
                    color: _getIconColor(syncService, isDarkMode),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: 6),
                    BilingualText.bilingual(
                      _getStatusText(syncService, currentLang),
                      style: BilingualTextStyles.labelSmall(
                        _getStatusText(syncService, currentLang),
                        color: _getTextColor(syncService, isDarkMode),
                      ),
                    ),
                  ],
                  if (showProgress && syncService.currentProgress.status != SyncStatus.idle) ...[
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        value: syncService.currentProgress.progress,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getIconColor(syncService, isDarkMode),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Fallback UI when Supabase is not initialized
      return GestureDetector(
        onTap: onConfigurePressed ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                currentLang == 'en'
                    ? 'Sync service is initializing...'
                    : 'ہم وقت سازی سروس شروع ہو رہی ہے...',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off,
                size: 16,
                color: Colors.grey,
              ),
              if (showLabel) ...[
                const SizedBox(width: 6),
                BilingualText.bilingual(
                  currentLang == 'en' ? 'Initializing...' : 'شروع ہو رہا ہے...',
                  style: BilingualTextStyles.labelSmall(
                    currentLang == 'en' ? 'Initializing...' : 'شروع ہو رہا ہے...',
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }
  }

  IconData _getStatusIcon(SupabaseSyncService syncService) {
    if (!syncService.isAuthenticated) {
      return Icons.cloud_off;
    }

    switch (syncService.currentProgress.status) {
      case SyncStatus.uploading:
        return Icons.cloud_upload;
      case SyncStatus.downloading:
        return Icons.cloud_download;
      case SyncStatus.completed:
        return Icons.cloud_done;
      case SyncStatus.failed:
        return Icons.error;
      case SyncStatus.idle:
        return Icons.cloud;
    }
  }

  Color _getIconColor(SupabaseSyncService syncService, bool isDarkMode) {
    if (!syncService.isAuthenticated) {
      return Colors.grey;
    }

    switch (syncService.currentProgress.status) {
      case SyncStatus.uploading:
      case SyncStatus.downloading:
        return isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B);
      case SyncStatus.completed:
        return Colors.green;
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.idle:
        return isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B);
    }
  }

  Color _getBackgroundColor(SupabaseSyncService syncService, bool isDarkMode) {
    if (!syncService.isAuthenticated) {
      return isDarkMode ? Colors.grey[800]! : Colors.grey[100]!;
    }

    switch (syncService.currentProgress.status) {
      case SyncStatus.failed:
        return isDarkMode ? Colors.red[900]! : Colors.red[50]!;
      case SyncStatus.completed:
        return isDarkMode ? Colors.green[900]! : Colors.green[50]!;
      default:
        return isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    }
  }

  Color _getBorderColor(SupabaseSyncService syncService, bool isDarkMode) {
    if (!syncService.isAuthenticated) {
      return Colors.grey;
    }

    switch (syncService.currentProgress.status) {
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.completed:
        return Colors.green;
      default:
        return isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B);
    }
  }

  Color _getTextColor(SupabaseSyncService syncService, bool isDarkMode) {
    if (!syncService.isAuthenticated) {
      return isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    }

    switch (syncService.currentProgress.status) {
      case SyncStatus.failed:
        return Colors.red;
      case SyncStatus.completed:
        return Colors.green;
      default:
        return isDarkMode ? Colors.white : Colors.black87;
    }
  }

  String _getStatusText(SupabaseSyncService syncService, String currentLang) {
    if (!syncService.isAuthenticated) {
      return currentLang == 'en' ? 'Offline' : 'آف لائن';
    }

    switch (syncService.currentProgress.status) {
      case SyncStatus.uploading:
        return currentLang == 'en' ? 'Uploading...' : 'اپ لوڈ ہو رہا ہے...';
      case SyncStatus.downloading:
        return currentLang == 'en' ? 'Downloading...' : 'ڈاؤن لوڈ ہو رہا ہے...';
      case SyncStatus.completed:
        return currentLang == 'en' ? 'Synced' : 'ہم وقت';
      case SyncStatus.failed:
        return currentLang == 'en' ? 'Failed' : 'ناکام';
      case SyncStatus.idle:
        return currentLang == 'en' ? 'Online' : 'آن لائن';
    }
  }
}

class QuickSyncButton extends StatelessWidget {
  final String tenantId;

  const QuickSyncButton({
    super.key,
    required this.tenantId,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ChangeNotifierProvider.value(
      value: SupabaseSyncService(),
      child: Consumer<SupabaseSyncService>(
        builder: (context, syncService, child) {
          final isLoading = syncService.currentProgress.status == SyncStatus.uploading ||
                           syncService.currentProgress.status == SyncStatus.downloading;

          return PopupMenuButton<SyncType>(
            enabled: syncService.isAuthenticated && !isLoading,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.sync,
                    color: syncService.isAuthenticated
                        ? (isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B))
                        : Colors.grey,
                  ),
            tooltip: currentLang == 'en' ? 'Quick Sync' : 'فوری ہم وقت سازی',
            onSelected: (SyncType type) => _performQuickSync(context, syncService, type),
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<SyncType>(
                value: SyncType.backup,
                child: Row(
                  children: [
                    const Icon(Icons.backup, size: 18),
                    const SizedBox(width: 8),
                    BilingualText.bilingual(
                      currentLang == 'en' ? 'Backup' : 'بیک اپ',
                      style: BilingualTextStyles.bodyMedium(
                        currentLang == 'en' ? 'Backup' : 'بیک اپ',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<SyncType>(
                value: SyncType.restore,
                child: Row(
                  children: [
                    const Icon(Icons.restore, size: 18),
                    const SizedBox(width: 8),
                    BilingualText.bilingual(
                      currentLang == 'en' ? 'Restore' : 'بحالی',
                      style: BilingualTextStyles.bodyMedium(
                        currentLang == 'en' ? 'Restore' : 'بحالی',
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuItem<SyncType>(
                value: SyncType.full,
                child: Row(
                  children: [
                    const Icon(Icons.sync, size: 18),
                    const SizedBox(width: 8),
                    BilingualText.bilingual(
                      currentLang == 'en' ? 'Full Sync' : 'مکمل ہم وقت سازی',
                      style: BilingualTextStyles.bodyMedium(
                        currentLang == 'en' ? 'Full Sync' : 'مکمل ہم وقت سازی',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _performQuickSync(
    BuildContext context,
    SupabaseSyncService syncService,
    SyncType type,
  ) async {
    try {
      final result = await syncService.syncData(
        tenantId: tenantId,
        type: type,
      );

      if (context.mounted) {
        final languageProvider = context.read<LanguageProvider>();
        final currentLang = languageProvider.currentLanguage;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.success
                  ? (currentLang == 'en' ? 'Sync completed successfully' : 'ہم وقت سازی کامیابی سے مکمل')
                  : (result.error ?? 'Sync failed'),
            ),
            backgroundColor: result.success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sync error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}