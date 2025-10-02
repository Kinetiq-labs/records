import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/khata_provider.dart';
import '../providers/user_provider.dart';
import '../services/tehlil_price_service.dart';
import '../utils/translations.dart';
import '../utils/bilingual_text_styles.dart';
import '../screens/status_entries_screen.dart';

class StatusSummaryPanel extends StatelessWidget {
  const StatusSummaryPanel({super.key});

  // Brand palette (greens)
  static const Color deepGreen = Color(0xFF0B5D3B);
  static const Color lightGreenFill = Color(0xFFE8F5E9);
  static const Color borderGreen = Color(0xFF66BB6A);

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final khataProvider = context.watch<KhataProvider>();
    final userProvider = context.watch<UserProvider>();
    final currentLang = languageProvider.currentLanguage;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    final todayStats = khataProvider.getTodayStatusCounts();
    final monthStats = khataProvider.getMonthlyStatusCounts();

    // Calculate pending amounts (using status-matching logic)
    final todayPendingAmount = khataProvider.getTodayPendingAmountForStatus(userProvider.currentUser);
    final monthlyPendingAmount = khataProvider.getMonthlyPendingAmountForStatus(userProvider.currentUser);

    // Calculate earned amounts (using status-matching logic)
    final todayEarnedAmount = khataProvider.getTodayEarnedAmountForStatus(userProvider.currentUser);
    final monthlyEarnedAmount = khataProvider.getMonthlyEarnedAmountForStatus(userProvider.currentUser);

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: (isDarkMode ? const Color(0xFF4A7C59) : borderGreen).withOpacity(0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: deepGreen.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A3325) : lightGreenFill,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.analytics,
                    color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Translations.get('status', currentLang),
                        style: BilingualTextStyles.headlineMedium(
                          Translations.get('status', currentLang),
                          color: Colors.white,
                        ).copyWith(decoration: TextDecoration.none),
                      ),
                      Text(
                        '${Translations.get('today', currentLang)} & ${Translations.get('this_month', currentLang)}',
                        style: BilingualTextStyles.bodyMedium(
                          '${Translations.get('today', currentLang)} & ${Translations.get('this_month', currentLang)}',
                          color: Colors.white70,
                        ).copyWith(decoration: TextDecoration.none),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Status Content
          Flexible(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Today Section
                    _buildStatusSection(
                      context,
                      Translations.get('today', currentLang),
                      todayStats,
                      currentLang,
                      Icons.today,
                      const Color(0xFF2196F3),
                      todayPendingAmount,
                      todayEarnedAmount,
                    ),

                    const SizedBox(height: 16),

                    // This Month Section
                    _buildStatusSection(
                      context,
                      Translations.get('this_month', currentLang),
                      monthStats,
                      currentLang,
                      Icons.calendar_month,
                      const Color(0xFF9C27B0),
                      monthlyPendingAmount,
                      monthlyEarnedAmount,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(
    BuildContext context,
    String title,
    Map<String, int> stats,
    String currentLang,
    IconData icon,
    Color accentColor,
    double pendingAmount,
    double earnedAmount,
  ) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2D2D2D) : lightGreenFill.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (isDarkMode ? const Color(0xFF4A7C59) : borderGreen).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: BilingualTextStyles.titleMedium(
                  title,
                  color: isDarkMode ? const Color(0xFF7FC685) : deepGreen,
                ).copyWith(decoration: TextDecoration.none),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Status Cards Row 1
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  context,
                  'Paid', // Always English
                  stats['paid'] ?? 0,
                  const Color(0xFF4CAF50),
                  Icons.check_circle,
                  title == Translations.get('today', currentLang), // isToday
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusCard(
                  context,
                  'Pending', // Always English
                  stats['pending'] ?? 0,
                  const Color(0xFFFF9800),
                  Icons.schedule,
                  title == Translations.get('today', currentLang), // isToday
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusCard(
                  context,
                  'Gold', // Always English
                  stats['gold'] ?? 0,
                  const Color(0xFFFFD700),
                  Icons.star,
                  title == Translations.get('today', currentLang), // isToday
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Status Cards Row 2
          Row(
            children: [
              Expanded(
                child: _buildStatusCard(
                  context,
                  'Recheck', // Always English
                  stats['recheck'] ?? 0,
                  const Color(0xFF9C27B0),
                  Icons.refresh,
                  title == Translations.get('today', currentLang), // isToday
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatusCard(
                  context,
                  'Card', // Always English
                  stats['card'] ?? 0,
                  const Color(0xFF2196F3),
                  Icons.credit_card,
                  title == Translations.get('today', currentLang), // isToday
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(), // Empty space to maintain alignment
              ),
            ],
          ),

          // Pending Amount Section
          if ((stats['pending'] ?? 0) > 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFFF9800).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFFFF9800),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.get('pending_amount', currentLang),
                          style: BilingualTextStyles.getTextStyle(
                            text: Translations.get('pending_amount', currentLang),
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Text(
                          TehlilPriceService.instance.formatAmountCompact(pendingAmount),
                          style: BilingualTextStyles.getTextStyle(
                            text: TehlilPriceService.instance.formatAmountCompact(pendingAmount),
                            fontSize: 16,
                            color: const Color(0xFFFF9800),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Earned Amount Section
          if ((stats['paid'] ?? 0) > 0) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF4CAF50).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.monetization_on,
                      color: Color(0xFF4CAF50),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          Translations.get('earned_amount', currentLang),
                          style: BilingualTextStyles.getTextStyle(
                            text: Translations.get('earned_amount', currentLang),
                            fontSize: 12,
                            color: isDarkMode ? Colors.white70 : Colors.grey[600],
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        Text(
                          TehlilPriceService.instance.formatAmountCompact(earnedAmount),
                          style: BilingualTextStyles.getTextStyle(
                            text: TehlilPriceService.instance.formatAmountCompact(earnedAmount),
                            fontSize: 16,
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, String label, int count, Color color, IconData icon, bool isToday) {
    return Builder(
      builder: (context) {
        final isDarkMode = Theme.of(context).brightness == Brightness.dark;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => StatusEntriesScreen(
                    status: label,
                    selectedDate: DateTime.now(),
                    isMonthlyView: !isToday,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: color,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  decoration: TextDecoration.none,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
          ),
        );
      },
    );
  }
}