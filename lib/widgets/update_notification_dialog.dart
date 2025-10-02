import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class UpdateNotificationDialog extends StatefulWidget {
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final VoidCallback onUpdate;
  final VoidCallback onLater;

  const UpdateNotificationDialog({
    super.key,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    required this.onUpdate,
    required this.onLater,
  });

  @override
  State<UpdateNotificationDialog> createState() => _UpdateNotificationDialogState();
}

class _UpdateNotificationDialogState extends State<UpdateNotificationDialog> {
  bool _isUpdating = false;

  Map<String, Map<String, String>> get _translations => {
    'en': {
      'title': 'Update Available',
      'subtitle': 'A new version of the app is available',
      'currentVersion': 'Current Version',
      'latestVersion': 'Latest Version',
      'releaseNotes': 'What\'s New',
      'updateButton': 'Update Now',
      'laterButton': 'Later',
      'updating': 'Updating...',
      'updateError': 'Update failed. Please try again.',
    },
    'ur': {
      'title': 'اپڈیٹ دستیاب ہے',
      'subtitle': 'ایپ کا نیا ورژن دستیاب ہے',
      'currentVersion': 'موجودہ ورژن',
      'latestVersion': 'تازہ ترین ورژن',
      'releaseNotes': 'نیا کیا ہے',
      'updateButton': 'ابھی اپڈیٹ کریں',
      'laterButton': 'بعد میں',
      'updating': 'اپڈیٹ ہو رہا ہے...',
      'updateError': 'اپڈیٹ ناکام. دوبارہ کوشش کریں.',
    },
    'ar': {
      'title': 'تحديث متاح',
      'subtitle': 'إصدار جديد من التطبيق متاح',
      'currentVersion': 'الإصدار الحالي',
      'latestVersion': 'أحدث إصدار',
      'releaseNotes': 'ما الجديد',
      'updateButton': 'تحديث الآن',
      'laterButton': 'لاحقاً',
      'updating': 'جاري التحديث...',
      'updateError': 'فشل التحديث. حاول مرة أخرى.',
    },
  };

  String _getText(String key, String languageCode) {
    return _translations[languageCode]?[key] ?? _translations['en']![key]!;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final lang = languageProvider.currentLanguage;

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.system_update,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getText('title', lang),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _getText('subtitle', lang),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getText('currentVersion', lang),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.currentVersion,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.arrow_forward, size: 20),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getText('latestVersion', lang),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.latestVersion,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.releaseNotes.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    _getText('releaseNotes', lang),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).dividerColor,
                      ),
                    ),
                    child: Text(
                      widget.releaseNotes,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isUpdating ? null : () {
                Navigator.of(context).pop();
                widget.onLater();
              },
              child: Text(_getText('laterButton', lang)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isUpdating ? null : () async {
                setState(() {
                  _isUpdating = true;
                });

                try {
                  widget.onUpdate();
                  Navigator.of(context).pop();
                } catch (e) {
                  setState(() {
                    _isUpdating = false;
                  });

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_getText('updateError', lang)),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: _isUpdating
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(_getText('updating', lang)),
                    ],
                  )
                : Text(_getText('updateButton', lang)),
            ),
          ],
        );
      },
    );
  }
}

void showUpdateDialog(
  BuildContext context, {
  required String currentVersion,
  required String latestVersion,
  required String releaseNotes,
  required VoidCallback onUpdate,
  required VoidCallback onLater,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => UpdateNotificationDialog(
      currentVersion: currentVersion,
      latestVersion: latestVersion,
      releaseNotes: releaseNotes,
      onUpdate: onUpdate,
      onLater: onLater,
    ),
  );
}