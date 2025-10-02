import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
import '../../utils/translations.dart';
import '../../utils/bilingual_text_styles.dart';

class PaymentStatusPieChart extends StatefulWidget {
  final List<PaymentStatusData> data;
  final String currentLang;

  const PaymentStatusPieChart({
    super.key,
    required this.data,
    required this.currentLang,
  });

  @override
  State<PaymentStatusPieChart> createState() => _PaymentStatusPieChartState();
}

class _PaymentStatusPieChartState extends State<PaymentStatusPieChart> {
  int touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (widget.data.isEmpty) {
      return _buildNoDataWidget(isDarkMode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartHeader(isDarkMode),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                height: 200,
                child: PieChart(
                  _buildPieChartData(isDarkMode),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildLegend(isDarkMode),
            ),
          ],
        ),
        if (touchedIndex >= 0 && touchedIndex < widget.data.length)
          _buildTouchedDataInfo(isDarkMode),
      ],
    );
  }

  Widget _buildChartHeader(bool isDarkMode) {
    return Row(
      children: [
        Icon(
          Icons.pie_chart,
          color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          Translations.get('payment_distribution', widget.currentLang),
          style: BilingualTextStyles.getTextStyle(
            text: Translations.get('payment_distribution', widget.currentLang),
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNoDataWidget(bool isDarkMode) {
    return Container(
      height: 200,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              Translations.get('no_data_available', widget.currentLang),
              style: BilingualTextStyles.getTextStyle(
                text: Translations.get('no_data_available', widget.currentLang),
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(bool isDarkMode) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: widget.data.map((data) {
        final color = _getStatusColor(data.status);

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
                    width: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getStatusDisplayName(data.status),
                      style: BilingualTextStyles.getTextStyle(
                        text: _getStatusDisplayName(data.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      '${data.count} (${data.percentage.toStringAsFixed(1)}%)',
                      style: BilingualTextStyles.getTextStyle(
                        text: '${data.count} (${data.percentage.toStringAsFixed(1)}%)',
                        fontSize: 10,
                        color: isDarkMode ? Colors.white70 : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTouchedDataInfo(bool isDarkMode) {
    final data = widget.data[touchedIndex];
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getStatusColor(data.status).withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: _getStatusColor(data.status),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getStatusDisplayName(data.status),
                  style: BilingualTextStyles.getTextStyle(
                    text: _getStatusDisplayName(data.status),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '${data.count} ${Translations.get('entries_count', widget.currentLang).toLowerCase()} (${data.percentage.toStringAsFixed(1)}%)',
                  style: BilingualTextStyles.getTextStyle(
                    text: '${data.count} entries (${data.percentage.toStringAsFixed(1)}%)',
                    fontSize: 12,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  PieChartData _buildPieChartData(bool isDarkMode) {
    return PieChartData(
      pieTouchData: PieTouchData(
        touchCallback: (FlTouchEvent event, pieTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                pieTouchResponse == null ||
                pieTouchResponse.touchedSection == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
          });
        },
      ),
      borderData: FlBorderData(show: false),
      sectionsSpace: 2,
      centerSpaceRadius: 40,
      sections: widget.data.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isTouched = index == touchedIndex;
        final radius = isTouched ? 70.0 : 60.0;
        final fontSize = isTouched ? 14.0 : 12.0;

        return PieChartSectionData(
          color: _getStatusColor(data.status),
          value: data.percentage,
          title: isTouched
              ? '${data.percentage.toStringAsFixed(1)}%\n${data.count}'
              : '${data.percentage.toStringAsFixed(0)}%',
          radius: radius,
          titleStyle: BilingualTextStyles.getTextStyle(
            text: '${data.percentage.toStringAsFixed(1)}%',
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          badgeWidget: isTouched ? _buildBadge(data.status) : null,
          badgePositionPercentageOffset: 1.3,
        );
      }).toList(),
    );
  }

  Widget _buildBadge(String status) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Icon(
        _getStatusIcon(status),
        color: Colors.white,
        size: 16,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF4CAF50);
      case 'pending':
        return const Color(0xFFFF9800);
      case 'gold':
        return const Color(0xFFFFD700);
      case 'recheck':
        return const Color(0xFF9C27B0);
      case 'card':
        return const Color(0xFF2196F3);
      default:
        return const Color(0xFF757575);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'pending':
        return Icons.schedule;
      case 'gold':
        return Icons.star;
      case 'recheck':
        return Icons.refresh;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusDisplayName(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Paid';
      case 'pending':
        return 'Pending';
      case 'gold':
        return 'Gold';
      case 'recheck':
        return 'Recheck';
      case 'card':
        return 'Card';
      default:
        return status;
    }
  }
}