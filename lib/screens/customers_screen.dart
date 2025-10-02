import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../providers/language_provider.dart';
import '../models/customer.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import 'customer_data_screen.dart';
import 'overall_weekly_report_screen.dart';

class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final customerProvider = context.read<CustomerProvider>();
      customerProvider.loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showAddCustomerDialog() {
    _nameController.clear();
    _phoneController.clear();
    _emailController.clear();
    _addressController.clear();
    _notesController.clear();
    _discountController.clear();

    showDialog(
      context: context,
      builder: (context) => _buildCustomerDialog(isEdit: false),
    );
  }

  void _showEditCustomerDialog(Customer customer) {
    _nameController.text = customer.name;
    _phoneController.text = customer.phone ?? '';
    _emailController.text = customer.email ?? '';
    _addressController.text = customer.address ?? '';
    _notesController.text = customer.notes ?? '';
    _discountController.text = customer.discountPercent?.toString() ?? '';

    showDialog(
      context: context,
      builder: (context) => _buildCustomerDialog(isEdit: true, customer: customer),
    );
  }

  Widget _buildCustomerDialog({required bool isEdit, Customer? customer}) {
    final languageProvider = context.watch<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      title: Row(
        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
        children: [
          Icon(
            isEdit ? Icons.edit : Icons.person_add,
            color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          ),
          const SizedBox(width: 8),
          BilingualText.bilingual(
            isEdit
              ? Translations.get('edit_customer', currentLang)
              : Translations.get('add_customer', currentLang),
            style: BilingualTextStyles.titleMedium(
              isEdit
                ? Translations.get('edit_customer', currentLang)
                : Translations.get('add_customer', currentLang),
              color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name field (required)
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: '${Translations.get('name', currentLang)} *',
                  prefixIcon: const Icon(Icons.person),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Phone field
              TextField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: Translations.get('phone', currentLang),
                  prefixIcon: const Icon(Icons.phone),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              // Email field
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: Translations.get('email', currentLang),
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              // Address field
              TextField(
                controller: _addressController,
                decoration: InputDecoration(
                  labelText: Translations.get('address', currentLang),
                  prefixIcon: const Icon(Icons.location_on),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Notes field
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: Translations.get('notes', currentLang),
                  prefixIcon: const Icon(Icons.note),
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Discount field
              TextField(
                controller: _discountController,
                decoration: InputDecoration(
                  labelText: Translations.get('discount_percent', currentLang),
                  prefixIcon: const Icon(Icons.percent),
                  border: const OutlineInputBorder(),
                  suffixText: '%',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: BilingualText.bilingual(
            Translations.get('cancel', currentLang),
            style: BilingualTextStyles.labelMedium(
              Translations.get('cancel', currentLang),
              color: Colors.grey[600],
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => _saveCustomer(isEdit: isEdit, customer: customer),
          style: ElevatedButton.styleFrom(
            backgroundColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
            foregroundColor: Colors.white,
          ),
          child: BilingualText.bilingual(
            isEdit
              ? Translations.get('update', currentLang)
              : Translations.get('save', currentLang),
            style: BilingualTextStyles.labelMedium(
              isEdit
                ? Translations.get('update', currentLang)
                : Translations.get('save', currentLang),
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  void _saveCustomer({required bool isEdit, Customer? customer}) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: BilingualText.bilingual(
            Translations.get('name_required', context.read<LanguageProvider>().currentLanguage),
            style: BilingualTextStyles.bodyMedium(
              Translations.get('name_required', context.read<LanguageProvider>().currentLanguage),
              color: Colors.white,
            ),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      final customerProvider = context.read<CustomerProvider>();
      final languageProvider = context.read<LanguageProvider>();
      final currentLang = languageProvider.currentLanguage;

      if (isEdit && customer != null) {
        await customerProvider.updateCustomer(customer.customerId, {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'email': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'address': _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          'notes': _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          'discount_percent': _discountController.text.trim().isEmpty ? null : double.parse(_discountController.text.trim()),
        });
      } else {
        await customerProvider.createCustomer(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          discountPercent: _discountController.text.trim().isEmpty ? null : double.parse(_discountController.text.trim()),
        );
      }

      if (mounted) {
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: BilingualText.bilingual(
              isEdit
                ? Translations.get('customer_updated', currentLang)
                : Translations.get('customer_added', currentLang),
              style: BilingualTextStyles.bodyMedium(
                isEdit
                  ? Translations.get('customer_updated', currentLang)
                  : Translations.get('customer_added', currentLang),
                color: Colors.white,
              ),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteCustomer(Customer customer) {
    final languageProvider = context.read<LanguageProvider>();
    final currentLang = languageProvider.currentLanguage;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            BilingualText.bilingual(
              Translations.get('confirm_delete', currentLang),
              style: BilingualTextStyles.titleMedium(
                Translations.get('confirm_delete', currentLang),
              ),
            ),
          ],
        ),
        content: BilingualText.bilingual(
          '${Translations.get('delete_customer_confirm', currentLang)} "${customer.name}"?',
          style: BilingualTextStyles.bodyMedium(
            '${Translations.get('delete_customer_confirm', currentLang)} "${customer.name}"?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: BilingualText.bilingual(
              Translations.get('cancel', currentLang),
              style: BilingualTextStyles.labelMedium(
                Translations.get('cancel', currentLang),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final customerProvider = context.read<CustomerProvider>();

              navigator.pop();
              try {
                await customerProvider.deleteCustomer(customer.customerId);
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: BilingualText.bilingual(
                      Translations.get('customer_deleted', currentLang),
                      style: BilingualTextStyles.bodyMedium(
                        Translations.get('customer_deleted', currentLang),
                        color: Colors.white,
                      ),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Error: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: BilingualText.bilingual(
              Translations.get('delete', currentLang),
              style: BilingualTextStyles.labelMedium(
                Translations.get('delete', currentLang),
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCustomerData(Customer customer) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CustomerDataScreen(customer: customer),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, String currentLang) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      child: InkWell(
        onDoubleTap: () => _navigateToCustomerData(customer),
        onTap: () => _navigateToCustomerData(customer),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
            children: [
              // Avatar
              CircleAvatar(
                radius: 30,
                backgroundColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : 'C',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Customer Info
              Expanded(
                child: Column(
                  crossAxisAlignment: currentLang == 'ur' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    BilingualText.bilingual(
                      customer.name,
                      style: BilingualTextStyles.titleLarge(
                        customer.name,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (customer.phone != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Icon(
                            Icons.phone,
                            size: 16,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          BilingualText.bilingual(
                            customer.phone!,
                            style: BilingualTextStyles.bodyMedium(
                              customer.phone!,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (customer.email != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                        children: [
                          Icon(
                            Icons.email,
                            size: 16,
                            color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          BilingualText.bilingual(
                            customer.email!,
                            style: BilingualTextStyles.bodyMedium(
                              customer.email!,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      _showEditCustomerDialog(customer);
                      break;
                    case 'delete':
                      _deleteCustomer(customer);
                      break;
                    case 'view_data':
                      _navigateToCustomerData(customer);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'view_data',
                    child: Row(
                      textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        const Icon(Icons.analytics),
                        const SizedBox(width: 8),
                        BilingualText.bilingual(
                          Translations.get('view_data', currentLang),
                          style: BilingualTextStyles.bodyMedium(
                            Translations.get('view_data', currentLang),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        const Icon(Icons.edit),
                        const SizedBox(width: 8),
                        BilingualText.bilingual(
                          Translations.get('edit', currentLang),
                          style: BilingualTextStyles.bodyMedium(
                            Translations.get('edit', currentLang),
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                      children: [
                        const Icon(Icons.delete, color: Colors.red),
                        const SizedBox(width: 8),
                        BilingualText.bilingual(
                          Translations.get('delete', currentLang),
                          style: BilingualTextStyles.bodyMedium(
                            Translations.get('delete', currentLang),
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final customerProvider = context.watch<CustomerProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: BilingualText.bilingual(
          Translations.get('customers', currentLang),
          style: BilingualTextStyles.headlineMedium(
            Translations.get('customers', currentLang),
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF0B5D3B),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: Translations.get('overall_weekly_report', currentLang),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const OverallWeeklyReportScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Add section
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textDirection: currentLang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
                    textAlign: currentLang == 'ur' ? TextAlign.right : TextAlign.left,
                    decoration: InputDecoration(
                      hintText: Translations.get('search_customers', currentLang),
                      hintStyle: BilingualTextStyles.bodyMedium(
                        Translations.get('search_customers', currentLang),
                        color: Colors.grey[500],
                      ),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (value) {
                      if (value.trim().isEmpty) {
                        customerProvider.loadCustomers();
                      } else {
                        customerProvider.searchCustomers(value.trim());
                      }
                    },
                  ),
                ),
                const SizedBox(width: 16),

                // Add customer button
                ElevatedButton.icon(
                  onPressed: _showAddCustomerDialog,
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  label: BilingualText.bilingual(
                    Translations.get('add_customer', currentLang),
                    style: BilingualTextStyles.labelMedium(
                      Translations.get('add_customer', currentLang),
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Customers list
          Expanded(
            child: customerProvider.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
                    ),
                  )
                : customerProvider.customers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            BilingualText.bilingual(
                              Translations.get('no_customers_found', currentLang),
                              style: BilingualTextStyles.titleMedium(
                                Translations.get('no_customers_found', currentLang),
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            BilingualText.bilingual(
                              Translations.get('tap_add_first_customer', currentLang),
                              style: BilingualTextStyles.bodyMedium(
                                Translations.get('tap_add_first_customer', currentLang),
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: customerProvider.customers.length,
                        itemBuilder: (context, index) {
                          final customer = customerProvider.customers[index];
                          return _buildCustomerCard(customer, currentLang);
                        },
                      ),
          ),
        ],
      ),
    );
  }
}