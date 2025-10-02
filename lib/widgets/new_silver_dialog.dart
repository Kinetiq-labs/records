import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/daily_silver_provider.dart';
import '../providers/language_provider.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';

class NewSilverDialog extends StatefulWidget {
  const NewSilverDialog({super.key});

  @override
  State<NewSilverDialog> createState() => _NewSilverDialogState();
}

class _NewSilverDialogState extends State<NewSilverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with current new silver amount
    final silverProvider = context.read<DailySilverProvider>();
    _amountController.text = silverProvider.newSilver.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _updateNewSilver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final amount = double.parse(_amountController.text.trim());
      final silverProvider = context.read<DailySilverProvider>();
      final languageProvider = context.read<LanguageProvider>();
      final currentLang = languageProvider.currentLanguage;

      final success = await silverProvider.updateNewSilver(amount);

      if (mounted) {
        if (success) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      Translations.get('silver_updated_successfully', currentLang),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF0B5D3B),
              duration: const Duration(seconds: 3),
            ),
          );
          Navigator.of(context).pop();
        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(silverProvider.error ?? 'Failed to update silver'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0B5D3B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.fiber_new,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: BilingualText.bilingual(
              Translations.get('update_new_silver', currentLang),
              style: BilingualTextStyles.headlineMedium(
                Translations.get('update_new_silver', currentLang),
                color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
              ),
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            BilingualText.bilingual(
              Translations.get('enter_new_silver_amount', currentLang),
              style: BilingualTextStyles.bodyMedium(
                Translations.get('enter_new_silver_amount', currentLang),
                color: isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1B1B1B),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                TextInputFormatter.withFunction((oldValue, newValue) {
                  // Allow empty string
                  if (newValue.text.isEmpty) return newValue;

                  // Check if the new value has a valid decimal format
                  final text = newValue.text;
                  if (RegExp(r'^\d*\.?\d{0,4}$').hasMatch(text)) {
                    // Check for multiple decimal points
                    if (text.split('.').length <= 2) {
                      return newValue;
                    }
                  }
                  // If invalid, keep the old value
                  return oldValue;
                }),
              ],
              decoration: InputDecoration(
                labelText: Translations.get('silver', currentLang),
                labelStyle: BilingualTextStyles.labelMedium(
                  Translations.get('silver', currentLang),
                  color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                ),
                hintText: '0.0000',
                hintStyle: BilingualTextStyles.bodyMedium(
                  '0.0000',
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
                prefixIcon: const Icon(
                  Icons.input,
                  color: Color(0xFF0B5D3B),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: isDarkMode ? const Color(0xFF4A4A4A) : const Color(0xFFBDBDBD),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Color(0xFF0B5D3B),
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: Colors.red,
                    width: 2,
                  ),
                ),
                filled: true,
                fillColor: isDarkMode ? const Color(0xFF2D2D2D) : const Color(0xFFF5F5F5),
              ),
              style: BilingualTextStyles.number(
                fontSize: 16,
                color: isDarkMode ? const Color(0xFFE6E1E5) : const Color(0xFF1B1B1B),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return Translations.get('is_required', currentLang);
                }
                if (double.tryParse(value.trim()) == null) {
                  return Translations.get('invalid_amount', currentLang);
                }
                return null;
              },
              enabled: !_isUpdating,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUpdating ? null : () => Navigator.of(context).pop(),
          child: BilingualText.bilingual(
            Translations.get('cancel', currentLang),
            style: BilingualTextStyles.labelMedium(
              Translations.get('cancel', currentLang),
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isUpdating ? null : _updateNewSilver,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0B5D3B),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: _isUpdating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : BilingualText.bilingual(
                  Translations.get('update_entry', currentLang),
                  style: BilingualTextStyles.labelMedium(
                    Translations.get('update_entry', currentLang),
                    color: Colors.white,
                  ),
                ),
        ),
      ],
    );
  }
}