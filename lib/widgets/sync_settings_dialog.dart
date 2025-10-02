import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sync_provider.dart';
import '../providers/language_provider.dart';
import '../providers/user_provider.dart';
import '../models/sync_models.dart';
import '../utils/responsive_utils.dart';
import '../utils/bilingual_text_styles.dart';

class SyncSettingsDialog extends StatefulWidget {
  const SyncSettingsDialog({super.key});

  @override
  State<SyncSettingsDialog> createState() => _SyncSettingsDialogState();
}

class _SyncSettingsDialogState extends State<SyncSettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serverUrlController = TextEditingController();
  final _apiKeyController = TextEditingController();

  bool _autoSync = false;
  int _syncIntervalHours = 24;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final syncProvider = context.read<SyncProvider>();
    final config = syncProvider.config;

    if (config != null) {
      _serverUrlController.text = config.serverUrl;
      _apiKeyController.text = config.apiKey;
      _autoSync = config.autoSync;
      _syncIntervalHours = config.syncInterval.inHours;
    }
  }

  @override
  void dispose() {
    _serverUrlController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final currentLang = languageProvider.currentLanguage;

        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.sync_alt,
                size: ResponsiveUtils.getResponsiveSpacing(context, 24),
              ),
              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 8)),
              Text(
                currentLang == 'ur' ? 'ہم آہنگی کی ترتیبات' : 'Sync Settings',
                style: BilingualTextStyles.titleLarge(
                  currentLang == 'ur' ? 'ہم آہنگی کی ترتیبات' : 'Sync Settings',
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          content: SizedBox(
            width: ResponsiveUtils.getResponsiveContainerWidth(context),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Server URL Field
                    TextFormField(
                      controller: _serverUrlController,
                      style: BilingualTextStyles.bodyLarge(
                        _serverUrlController.text.isEmpty ? 'sample' : _serverUrlController.text,
                      ),
                      decoration: InputDecoration(
                        labelText: currentLang == 'ur' ? 'سرور URL' : 'Server URL',
                        labelStyle: BilingualTextStyles.labelLarge(
                          currentLang == 'ur' ? 'سرور URL' : 'Server URL',
                        ),
                        hintText: currentLang == 'ur'
                            ? 'https://your-server.com'
                            : 'https://your-server.com',
                        hintStyle: BilingualTextStyles.bodyMedium(
                          'https://your-server.com',
                          color: Colors.grey[500],
                        ),
                        prefixIcon: const Icon(Icons.cloud),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return currentLang == 'ur'
                              ? 'سرور URL درکار ہے'
                              : 'Server URL is required';
                        }
                        if (!value.startsWith('http://') && !value.startsWith('https://')) {
                          return currentLang == 'ur'
                              ? 'درست URL درج کریں'
                              : 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),

                    // API Key Field
                    TextFormField(
                      controller: _apiKeyController,
                      style: BilingualTextStyles.bodyLarge(
                        _apiKeyController.text.isEmpty ? 'sample' : _apiKeyController.text,
                      ),
                      decoration: InputDecoration(
                        labelText: currentLang == 'ur' ? 'API کلید' : 'API Key',
                        labelStyle: BilingualTextStyles.labelLarge(
                          currentLang == 'ur' ? 'API کلید' : 'API Key',
                        ),
                        hintText: currentLang == 'ur'
                            ? 'آپ کی API کلید'
                            : 'Your API key',
                        hintStyle: BilingualTextStyles.bodyMedium(
                          currentLang == 'ur' ? 'آپ کی API کلید' : 'Your API key',
                          color: Colors.grey[500],
                        ),
                        prefixIcon: const Icon(Icons.key),
                        border: const OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return currentLang == 'ur'
                              ? 'API کلید درکار ہے'
                              : 'API key is required';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),

                    // Auto Sync Toggle
                    Row(
                      children: [
                        Switch(
                          value: _autoSync,
                          onChanged: (value) {
                            setState(() {
                              _autoSync = value;
                            });
                          },
                        ),
                        SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                        Expanded(
                          child: Text(
                            currentLang == 'ur'
                                ? 'خودکار ہم آہنگی'
                                : 'Auto Sync',
                            style: BilingualTextStyles.bodyLarge(
                              currentLang == 'ur' ? 'خودکار ہم آہنگی' : 'Auto Sync',
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_autoSync) ...[
                      SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 16)),

                      // Sync Interval
                      Row(
                        children: [
                          Text(
                            currentLang == 'ur'
                                ? 'ہم آہنگی کا وقفہ:'
                                : 'Sync Interval:',
                            style: BilingualTextStyles.bodyMedium(
                              currentLang == 'ur' ? 'ہم آہنگی کا وقفہ:' : 'Sync Interval:',
                            ),
                          ),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _syncIntervalHours,
                            items: [
                              DropdownMenuItem(
                                value: 1,
                                child: Text(
                                  currentLang == 'ur' ? '۱ گھنٹہ' : '1 Hour',
                                  style: BilingualTextStyles.bodyMedium(
                                    currentLang == 'ur' ? '۱ گھنٹہ' : '1 Hour',
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 6,
                                child: Text(
                                  currentLang == 'ur' ? '۶ گھنٹے' : '6 Hours',
                                  style: BilingualTextStyles.bodyMedium(
                                    currentLang == 'ur' ? '۶ گھنٹے' : '6 Hours',
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 12,
                                child: Text(
                                  currentLang == 'ur' ? '۱۲ گھنٹے' : '12 Hours',
                                  style: BilingualTextStyles.bodyMedium(
                                    currentLang == 'ur' ? '۱۲ گھنٹے' : '12 Hours',
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 24,
                                child: Text(
                                  currentLang == 'ur' ? '۲۴ گھنٹے' : '24 Hours',
                                  style: BilingualTextStyles.bodyMedium(
                                    currentLang == 'ur' ? '۲۴ گھنٹے' : '24 Hours',
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _syncIntervalHours = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],

                    SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 24)),

                    // Information Card
                    Container(
                      padding: ResponsiveUtils.getResponsivePadding(context),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info,
                                color: Colors.blue,
                                size: ResponsiveUtils.getResponsiveSpacing(context, 16),
                              ),
                              SizedBox(width: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                              Text(
                                currentLang == 'ur' ? 'معلومات' : 'Information',
                                style: BilingualTextStyles.bodyLarge(
                                  currentLang == 'ur' ? 'معلومات' : 'Information',
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context, 8)),
                          Text(
                            currentLang == 'ur'
                                ? '• آپ کا ڈیٹا محفوظ طریقے سے سرور پر محفوظ ہوگا\n• API کلید آپ کی شناخت کے لیے استعمال ہوتی ہے\n• خودکار ہم آہنگی صرف انٹرنیٹ دستیاب ہونے پر کام کرتی ہے'
                                : '• Your data will be securely stored on the server\n• API key is used for authentication\n• Auto sync only works when internet is available',
                            style: BilingualTextStyles.bodySmall(
                              currentLang == 'ur'
                                  ? '• آپ کا ڈیٹا محفوظ طریقے سے سرور پر محفوظ ہوگا\n• API کلید آپ کی شناخت کے لیے استعمال ہوتی ہے\n• خودکار ہم آہنگی صرف انٹرنیٹ دستیاب ہونے پر کام کرتی ہے'
                                  : '• Your data will be securely stored on the server\n• API key is used for authentication\n• Auto sync only works when internet is available',
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: Text(
                currentLang == 'ur' ? 'منسوخ' : 'Cancel',
                style: BilingualTextStyles.bodyMedium(
                  currentLang == 'ur' ? 'منسوخ' : 'Cancel',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: _isLoading ? null : _saveSettings,
              child: _isLoading
                  ? SizedBox(
                      width: ResponsiveUtils.getResponsiveSpacing(context, 16),
                      height: ResponsiveUtils.getResponsiveSpacing(context, 16),
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      currentLang == 'ur' ? 'محفوظ کریں' : 'Save',
                      style: BilingualTextStyles.bodyMedium(
                        currentLang == 'ur' ? 'محفوظ کریں' : 'Save',
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  void _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = context.read<UserProvider>();
      final syncProvider = context.read<SyncProvider>();
      final currentUser = userProvider.currentUser;

      if (currentUser == null) {
        throw Exception('No user logged in');
      }

      final config = SyncConfig(
        userId: currentUser.id.toString(),
        serverUrl: _serverUrlController.text.trim(),
        apiKey: _apiKeyController.text.trim(),
        autoSync: _autoSync,
        syncInterval: Duration(hours: _syncIntervalHours),
      );

      await syncProvider.configure(config);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sync settings saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}