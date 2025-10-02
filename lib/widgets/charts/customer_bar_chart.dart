import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
import '../../utils/translations.dart';
import '../../utils/bilingual_text_styles.dart';
import '../../services/tehlil_price_service.dart';

class CustomerBarChart extends StatefulWidget {
  final List<CustomerAnalyticsData> data;
  final String currentLang;

  const CustomerBarChart({
    super.key,
    required this.data,
    required this.currentLang,
  });

  @override
  State<CustomerBarChart> createState() => _CustomerBarChartState();
}

class _CustomerBarChartState extends State<CustomerBarChart> {
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
        Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          child: BarChart(
            _buildBarChartData(isDarkMode),
          ),
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
          Icons.people,
          color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          Translations.get('top_customers', widget.currentLang),
          style: BilingualTextStyles.getTextStyle(
            text: Translations.get('top_customers', widget.currentLang),
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
      height: 300,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
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

  Widget _buildTouchedDataInfo(bool isDarkMode) {
    final data = widget.data[touchedIndex];
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF2196F3).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.person,
                color: Color(0xFF2196F3),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data.customerName,
                  style: BilingualTextStyles.getTextStyle(
                    text: data.customerName,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Translations.get('total_amount', widget.currentLang),
                  TehlilPriceService.instance.formatAmountCompact(data.totalAmount),
                  isDarkMode,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Translations.get('total_entries', widget.currentLang),
                  data.totalEntries.toString(),
                  isDarkMode,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Translations.get('conversion_rate', widget.currentLang),
                  '${data.conversionRate.toStringAsFixed(1)}%',
                  isDarkMode,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Translations.get('paid_entries', widget.currentLang),
                  '${data.paidEntries}/${data.totalEntries}',
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: BilingualTextStyles.getTextStyle(
            text: label,
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: BilingualTextStyles.getTextStyle(
            text: value,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  BarChartData _buildBarChartData(bool isDarkMode) {
    // Handle empty data case
    if (widget.data.isEmpty) {
      return BarChartData(maxY: 100.0);
    }

    final amounts = widget.data.map((e) => e.totalAmount).toList();
    final maxY = amounts.reduce((a, b) => a > b ? a : b);
    final effectiveMaxY = maxY > 0 ? maxY : 100.0; // Minimum value to prevent zero interval
    final padding = effectiveMaxY * 0.1;


    return BarChartData(
      maxY: effectiveMaxY + padding,
      barTouchData: BarTouchData(
        touchCallback: (FlTouchEvent event, barTouchResponse) {
          setState(() {
            if (!event.isInterestedForInteractions ||
                barTouchResponse == null ||
                barTouchResponse.spot == null) {
              touchedIndex = -1;
              return;
            }
            touchedIndex = barTouchResponse.spot!.touchedBarGroupIndex;
          });
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 60,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index >= 0 && index < widget.data.length) {
                final customerName = widget.data[index].customerName;
                final displayName = customerName.length > 8
                    ? '${customerName.substring(0, 8)}...'
                    : customerName;
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Transform.rotate(
                      angle: -0.5,
                      child: Text(
                        displayName,
                        style: BilingualTextStyles.getTextStyle(
                          text: displayName,
                          fontSize: 10,
                          color: isDarkMode ? Colors.white70 : Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (effectiveMaxY + padding) / 5,
            reservedSize: 60,
            getTitlesWidget: (double value, TitleMeta meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  TehlilPriceService.instance.formatAmountCompact(value),
                  style: BilingualTextStyles.getTextStyle(
                    text: TehlilPriceService.instance.formatAmountCompact(value),
                    fontSize: 10,
                    color: isDarkMode ? Colors.white70 : Colors.grey[600],
                  ),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.3),
        ),
      ),
      barGroups: widget.data.asMap().entries.map((entry) {
        final index = entry.key;
        final data = entry.value;
        final isTouched = index == touchedIndex;

        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data.totalAmount,
              color: _getBarColor(index, isTouched),
              width: isTouched ? 25 : 20,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
              rodStackItems: [],
            ),
          ],
        );
      }).toList(),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (effectiveMaxY + padding) / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
    );
  }

  Color _getBarColor(int index, bool isTouched) {
    final colors = [
      const Color(0xFF2196F3),
      const Color(0xFF4CAF50),
      const Color(0xFFFF9800),
      const Color(0xFF9C27B0),
      const Color(0xFFF44336),
      const Color(0xFF00BCD4),
      const Color(0xFF795548),
      const Color(0xFF607D8B),
      const Color(0xFFE91E63),
      const Color(0xFF3F51B5),
    ];

    final baseColor = colors[index % colors.length];
    return isTouched ? baseColor : baseColor.withOpacity(0.8);
  }
}