import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/khata_provider.dart';
import '../providers/daily_silver_provider.dart';
import '../models/khata_entry.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../services/text_translation_service.dart';

class EditEntryForm extends StatefulWidget {
  final KhataEntry entry;
  final VoidCallback? onEntryUpdated;

  const EditEntryForm({
    super.key,
    required this.entry,
    this.onEntryUpdated,
  });

  @override
  State<EditEntryForm> createState() => _EditEntryFormState();
}

class _EditEntryFormState extends State<EditEntryForm> {
  final _formKey = GlobalKey<FormState>();
  final _translationService = TextTranslationService();
  
  // Controllers for form inputs
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _detailController;
  late final TextEditingController _numberController;
  late final TextEditingController _returnWeight1Controller;
  late final TextEditingController _firstWeightController;
  late final TextEditingController _silverController;
  late final TextEditingController _returnWeight2Controller;
  late final TextEditingController _nalkiController;
  late final TextEditingController _silverSoldController;
  late final TextEditingController _silverAmountController;

  // Brand palette (greens)
  static const Color background = Color(0xFFF0FFF0);
  static const Color deepGreen = Color(0xFF0B5D3B);
  static const Color lightGreenFill = Color(0xFFE8F5E9);
  static const Color borderGreen = Color(0xFF66BB6A);

  @override
  void initState() {
    super.initState();
    final languageProvider = context.read<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    
    // Initialize controllers with current entry data
    _nameController = TextEditingController(
      text: _translationService.getDisplayText(widget.entry.name, currentLang)
    );
    _weightController = TextEditingController(
      text: widget.entry.weight?.toString() ?? ''
    );
    _detailController = TextEditingController(
      text: widget.entry.detail != null 
          ? _translationService.getDisplayText(widget.entry.detail!, currentLang)
          : ''
    );
    _numberController = TextEditingController(text: widget.entry.number.toString());
    _returnWeight1Controller = TextEditingController(text: widget.entry.returnWeight1Display ?? widget.entry.returnWeight1?.toString() ?? '');
    _firstWeightController = TextEditingController(text: widget.entry.firstWeight?.toString() ?? '');
    _silverController = TextEditingController(text: widget.entry.silver?.toString() ?? '');
    _returnWeight2Controller = TextEditingController(text: widget.entry.returnWeight2?.toString() ?? '');
    _nalkiController = TextEditingController(text: widget.entry.nalki?.toString() ?? '');
    _silverSoldController = TextEditingController(text: widget.entry.silverSold?.toString() ?? '');
    _silverAmountController = TextEditingController(text: widget.entry.silverAmount?.toString() ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _detailController.dispose();
    _numberController.dispose();
    _returnWeight1Controller.dispose();
    _firstWeightController.dispose();
    _silverController.dispose();
    _returnWeight2Controller.dispose();
    _nalkiController.dispose();
    _silverSoldController.dispose();
    _silverAmountController.dispose();
    super.dispose();
  }

  List<TextInputFormatter> _getInputFormatters(bool onlyNumbers, bool allowFloat, {String fieldType = ''}) {
    if (!onlyNumbers) {
      return []; // No restrictions for text fields (Name, Detail)
    }

    if (fieldType == 'weight') {
      // Allow decimal numbers: digits, one decimal point, more digits
      return [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
        // Prevent multiple decimal points and ensure proper decimal format
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;

          // Allow empty string
          if (text.isEmpty) return newValue;

          // Check for valid decimal format
          if (RegExp(r'^\d*\.?\d*$').hasMatch(text)) {
            // Count decimal points to ensure only one
            final dotCount = text.split('.').length - 1;
            if (dotCount <= 1) {
              return newValue;
            }
          }
          return oldValue;
        }),
      ];
    } else if (fieldType == 'return_weight_1') {
      // Allow numbers, decimal point, space, digits, and P/p
      return [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.\s PpPp]')),
        // Custom validation for proper format
        TextInputFormatter.withFunction((oldValue, newValue) {
          final text = newValue.text;
          // Allow empty or partial typing
          if (text.isEmpty) return newValue;

          // Basic pattern: allow decimal numbers followed by optional space and P suffix
          final pattern = RegExp(r'^\.?\d*\.?\d*(\s+\d*[Pp]?)?$');
          if (pattern.hasMatch(text)) {
            return newValue;
          }
          return oldValue;
        }),
      ];
    } else if (allowFloat) {
      // Allow digits and one decimal point for other float numbers
      return [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ];
    } else {
      // Only allow digits for integer fields
      return [
        FilteringTextInputFormatter.digitsOnly,
      ];
    }
  }

  /// Extract numeric value from return_weight_1 field that might contain "3P" suffix
  String? _extractNumericValue(String input) {
    if (input.isEmpty) return null;

    // Remove everything after the first space (removes " 3P" part), then trim
    String cleaned = input.split(' ')[0].trim();

    // Handle cases like ".330" by adding leading zero
    if (cleaned.startsWith('.')) {
      cleaned = '0$cleaned';
    }

    return cleaned.isEmpty ? null : cleaned;
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final languageProvider = context.read<LanguageProvider>();
        final khataProvider = context.read<KhataProvider>();
        final currentLang = languageProvider.currentLanguage;
        
        // Translate input text from Urdu to English for database storage
        final translatedName = _translationService.processFieldInput(
          _nameController.text.trim(), 
          'name', 
          currentLang
        );
        
        final translatedDetail = _detailController.text.isEmpty 
            ? null 
            : _translationService.processFieldInput(
                _detailController.text.trim(), 
                'detail', 
                currentLang
              );

        // Process numeric fields (convert Urdu numerals to English)
        final processedNumber = _translationService.processFieldInput(
          _numberController.text, 
          'number', 
          currentLang
        );
        
        final processedWeight = _weightController.text.isEmpty 
            ? null 
            : _translationService.processFieldInput(
                _weightController.text, 
                'weight', 
                currentLang
              );

        // Create updates map
        final updates = <String, dynamic>{
          'name': translatedName,
          'number': int.parse(processedNumber),
          'weight': processedWeight == null ? null : double.parse(processedWeight),
          'detail': translatedDetail,
          'return_weight_1': () {
            final numericValue = _extractNumericValue(_returnWeight1Controller.text);
            if (numericValue == null) return null;

            final normalizedValue = _translationService.normalizeNumbers(numericValue);
            // Check if it's a decimal number, if so parse as double then convert to int
            if (normalizedValue.contains('.')) {
              return double.parse(normalizedValue).round();
            } else {
              return int.parse(normalizedValue);
            }
          }(),
          'first_weight': _firstWeightController.text.isEmpty ? null : int.parse(_translationService.normalizeNumbers(_firstWeightController.text)),
          'silver': _silverController.text.isEmpty ? null : int.parse(_translationService.normalizeNumbers(_silverController.text)),
          'return_weight_2': _returnWeight2Controller.text.isEmpty ? null : int.parse(_translationService.normalizeNumbers(_returnWeight2Controller.text)),
          'nalki': _nalkiController.text.isEmpty ? null : int.parse(_translationService.normalizeNumbers(_nalkiController.text)),
          'silver_sold': _silverSoldController.text.isEmpty ? null : double.parse(_translationService.normalizeNumbers(_silverSoldController.text)),
          'silver_amount': _silverAmountController.text.isEmpty ? null : double.parse(_translationService.normalizeNumbers(_silverAmountController.text)),
          'updated_at': DateTime.now().toIso8601String(),
        };

        // Update entry in database
        await khataProvider.updateEntry(widget.entry.entryId, updates);

        // Refresh daily silver calculations after updating entry
        if (mounted) {
          final silverProvider = context.read<DailySilverProvider>();
          final scaffoldMessenger = ScaffoldMessenger.of(context);
          final navigator = Navigator.of(context);

          await silverProvider.refreshCalculations(forDate: widget.entry.createdAt);

          // Notify parent about the update
          widget.onEntryUpdated?.call();

          if (mounted) {
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: BilingualText.bilingual(Translations.get('entry_updated_successfully', currentLang), style: BilingualTextStyles.bodyMedium(Translations.get('entry_updated_successfully', currentLang), color: Colors.white)),
                backgroundColor: deepGreen,
                duration: const Duration(seconds: 3),
              ),
            );

            // Close the form
            navigator.pop();
          }
        }
        
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String currentLang,
    bool isRequired = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool allowFloat = false,
    bool onlyNumbers = false,
    String fieldType = '',
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // Create a ValueNotifier to track text changes for dynamic font switching
    final textNotifier = ValueNotifier<String>(controller.text);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
            children: [
              BilingualText.bilingual(
                Translations.get(label, currentLang),
                style: BilingualTextStyles.labelLarge(
                  Translations.get(label, currentLang),
                  color: isDarkMode ? const Color(0xFFE6E1E5) : deepGreen,
                ).copyWith(fontWeight: FontWeight.w600),
              ),
              if (isRequired)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<String>(
            valueListenable: textNotifier,
            builder: (context, currentText, child) {
              return TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                maxLines: maxLines,
                textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                textAlign: currentLang == 'ur' ? TextAlign.right : TextAlign.left,
                inputFormatters: _getInputFormatters(onlyNumbers, allowFloat, fieldType: fieldType),
                onChanged: (value) {
                  textNotifier.value = value;
                },
                validator: isRequired
                    ? (value) {
                        if (value == null || value.isEmpty) {
                          final errorText = '${Translations.get(label, currentLang)} ${Translations.get('is_required', currentLang)}';
                          return errorText;
                        }
                        return null;
                      }
                    : null,
                decoration: InputDecoration(
                  hintText: '${Translations.get('enter', currentLang)} ${Translations.get(label, currentLang)}',
                  hintStyle: BilingualTextStyles.getTextStyle(
                    text: '${Translations.get('enter', currentLang)} ${Translations.get(label, currentLang)}',
                    color: isDarkMode ? const Color(0xFF8A8A8A) : deepGreen.withOpacity(0.5),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: isDarkMode ? const Color(0xFF2A2A2A) : lightGreenFill,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: (isDarkMode ? const Color(0xFF4A7C59) : borderGreen).withOpacity(0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: (isDarkMode ? const Color(0xFF4A7C59) : borderGreen).withOpacity(0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDarkMode ? const Color(0xFF7FC685) : deepGreen, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                style: BilingualTextStyles.getTextStyle(
                  text: currentText.isEmpty ? 'sample' : currentText,
                  color: isDarkMode ? const Color(0xFFFFFFFF) : const Color(0xFF1C1C1C),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              );
            },
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: (isDarkMode ? const Color(0xFF4A7C59) : borderGreen).withOpacity(0.3), width: 2),
          boxShadow: [
            BoxShadow(
              color: deepGreen.withOpacity(0.2),
              offset: const Offset(0, 10),
              blurRadius: 30,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                    ? [const Color(0xFF2D2D2D), const Color(0xFF4A4A4A)]
                    : [deepGreen, deepGreen.withOpacity(0.8)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1A3325) : lightGreenFill,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit,
                      color: deepGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: currentLang == 'ur' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        BilingualText.bilingual(
                          '${Translations.get('edit', currentLang)} ${Translations.get('entry', currentLang)} #${widget.entry.entryIndex}',
                          style: BilingualTextStyles.headlineMedium(
                            '${Translations.get('edit', currentLang)} ${Translations.get('entry', currentLang)}',
                            color: Colors.white,
                          ).copyWith(fontWeight: FontWeight.w700),
                        ),
                        BilingualText.bilingual(
                          Translations.get('update_entry_details', currentLang),
                          style: BilingualTextStyles.bodySmall(
                            Translations.get('update_entry_details', currentLang),
                            color: Colors.white70,
                          ).copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            
            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Form fields
                      _buildTextField(
                        label: 'name',
                        controller: _nameController,
                        currentLang: currentLang,
                        isRequired: true,
                      ),
                      
                      Row(
                        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'weight',
                              controller: _weightController,
                              currentLang: currentLang,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onlyNumbers: true,
                              allowFloat: true,
                              fieldType: 'weight',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'number',
                              controller: _numberController,
                              currentLang: currentLang,
                              isRequired: true,
                              keyboardType: TextInputType.number,
                              onlyNumbers: true,
                              allowFloat: false,
                            ),
                          ),
                        ],
                      ),
                      
                      _buildTextField(
                        label: 'detail',
                        controller: _detailController,
                        currentLang: currentLang,
                        maxLines: 3,
                      ),
                      
                      Row(
                        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'return_weight_1',
                              controller: _returnWeight1Controller,
                              currentLang: currentLang,
                              keyboardType: TextInputType.text,
                              onlyNumbers: true,
                              allowFloat: false,
                              fieldType: 'return_weight_1',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'first_weight',
                              controller: _firstWeightController,
                              currentLang: currentLang,
                              keyboardType: TextInputType.number,
                              onlyNumbers: true,
                              allowFloat: false,
                            ),
                          ),
                        ],
                      ),
                      
                      Row(
                        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'silver',
                              controller: _silverController,
                              currentLang: currentLang,
                              keyboardType: TextInputType.number,
                              onlyNumbers: true,
                              allowFloat: false,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'return_weight_2',
                              controller: _returnWeight2Controller,
                              currentLang: currentLang,
                              keyboardType: TextInputType.number,
                              onlyNumbers: true,
                              allowFloat: false,
                            ),
                          ),
                        ],
                      ),
                      
                      _buildTextField(
                        label: 'nalki',
                        controller: _nalkiController,
                        currentLang: currentLang,
                        keyboardType: TextInputType.number,
                        onlyNumbers: true,
                        allowFloat: false,
                      ),

                      // New Silver Fields
                      Row(
                        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Expanded(
                            child: _buildTextField(
                              label: 'silver_sold',
                              controller: _silverSoldController,
                              currentLang: currentLang,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onlyNumbers: true,
                              allowFloat: true, // Allow decimal values
                              fieldType: 'weight', // Use same validation as weight field
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              label: 'silver_amount',
                              controller: _silverAmountController,
                              currentLang: currentLang,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onlyNumbers: true,
                              allowFloat: true, // Allow decimal values
                              fieldType: 'weight', // Use same validation as weight field
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      
                      // Submit Button
                      Row(
                        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: deepGreen),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: BilingualText.bilingual(
                                Translations.get('cancel', currentLang),
                                style: BilingualTextStyles.titleMedium(
                                  Translations.get('cancel', currentLang),
                                  color: deepGreen,
                                ).copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: deepGreen,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                shadowColor: deepGreen.withOpacity(0.3),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.update,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  BilingualText.bilingual(
                                    Translations.get('update_entry', currentLang),
                                    style: BilingualTextStyles.titleMedium(
                                      Translations.get('update_entry', currentLang),
                                      color: Colors.white,
                                    ).copyWith(fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}