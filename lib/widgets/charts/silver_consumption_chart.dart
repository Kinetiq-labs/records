import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
import '../../utils/translations.dart';
import '../../utils/bilingual_text_styles.dart';

class SilverConsumptionChart extends StatefulWidget {
  final List<SilverAnalyticsData> data;
  final String currentLang;

  const SilverConsumptionChart({
    super.key,
    required this.data,
    required this.currentLang,
  });

  @override
  State<SilverConsumptionChart> createState() => _SilverConsumptionChartState();
}

class _SilverConsumptionChartState extends State<SilverConsumptionChart> {
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
          height: 250,
          padding: const EdgeInsets.all(16),
          child: LineChart(
            _buildLineChartData(isDarkMode),
          ),
        ),
        _buildLegend(isDarkMode),
        if (touchedIndex >= 0 && touchedIndex < widget.data.length)
          _buildTouchedDataInfo(isDarkMode),
      ],
    );
  }

  Widget _buildChartHeader(bool isDarkMode) {
    return Row(
      children: [
        Icon(
          Icons.insights,
          color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          Translations.get('silver_consumption', widget.currentLang),
          style: BilingualTextStyles.getTextStyle(
            text: Translations.get('silver_consumption', widget.currentLang),
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
      height: 250,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
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
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildLegendItem(
            Translations.get('new_silver', widget.currentLang),
            const Color(0xFF4CAF50),
            isDarkMode,
          ),
          _buildLegendItem(
            Translations.get('used_silver', widget.currentLang),
            const Color(0xFFFF9800),
            isDarkMode,
          ),
          _buildLegendItem(
            Translations.get('remaining_silver', widget.currentLang),
            const Color(0xFF2196F3),
            isDarkMode,
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDarkMode) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: BilingualTextStyles.getTextStyle(
            text: label,
            fontSize: 12,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
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
          color: const Color(0xFF4CAF50).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_today,
                color: Color(0xFF4CAF50),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDate(data.date),
                style: BilingualTextStyles.getTextStyle(
                  text: _formatDate(data.date),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  Translations.get('new_silver', widget.currentLang),
                  '${data.newSilver.toStringAsFixed(2)} g',
                  const Color(0xFF4CAF50),
                  isDarkMode,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Translations.get('used_silver', widget.currentLang),
                  '${data.usedSilver.toStringAsFixed(2)} g',
                  const Color(0xFFFF9800),
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
                  Translations.get('remaining_silver', widget.currentLang),
                  '${data.remainingSilver.toStringAsFixed(2)} g',
                  const Color(0xFF2196F3),
                  isDarkMode,
                ),
              ),
              Expanded(
                child: _buildInfoItem(
                  Translations.get('efficiency', widget.currentLang),
                  '${data.efficiency.toStringAsFixed(1)}%',
                  data.efficiency > 80 ? const Color(0xFF4CAF50) : const Color(0xFFFF9800),
                  isDarkMode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, Color color, bool isDarkMode) {
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
        const SizedBox(height: 4),
        Text(
          value,
          style: BilingualTextStyles.getTextStyle(
            text: value,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(bool isDarkMode) {
    final allValues = [
      ...widget.data.map((e) => e.newSilver),
      ...widget.data.map((e) => e.usedSilver),
      ...widget.data.map((e) => e.remainingSilver),
    ];

    final maxY = allValues.isNotEmpty ? allValues.reduce((a, b) => a > b ? a : b) : 100.0;
    final minY = allValues.isNotEmpty ? allValues.reduce((a, b) => a < b ? a : b) : 0.0;
    final range = maxY - minY;
    final padding = range > 0 ? range * 0.1 : maxY * 0.1; // Use 10% of maxY if range is 0

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: (range + 2 * padding) > 0 ? (range + 2 * padding) / 5 : 20.0, // Default to 20 if still zero
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: widget.data.length > 10 ? ((widget.data.length / 5).floor().clamp(1, double.infinity).toDouble()) : 1.0,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index >= 0 && index < widget.data.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    _formatDateLabel(widget.data[index].date),
                    style: BilingualTextStyles.getTextStyle(
                      text: _formatDateLabel(widget.data[index].date),
                      fontSize: 10,
                      color: isDarkMode ? Colors.white70 : Colors.grey[600],
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
            interval: (range + 2 * padding) > 0 ? (range + 2 * padding) / 5 : 20.0,
            reservedSize: 50,
            getTitlesWidget: (double value, TitleMeta meta) {
              return SideTitleWidget(
                axisSide: meta.axisSide,
                child: Text(
                  '${value.toStringAsFixed(0)}g',
                  style: BilingualTextStyles.getTextStyle(
                    text: '${value.toStringAsFixed(0)}g',
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
      minX: 0,
      maxX: (widget.data.length - 1).toDouble(),
      minY: minY - padding,
      maxY: maxY + padding,
      lineBarsData: [
        _buildLineBarData(
          widget.data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.newSilver)).toList(),
          const Color(0xFF4CAF50),
          'new_silver',
        ),
        _buildLineBarData(
          widget.data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.usedSilver)).toList(),
          const Color(0xFFFF9800),
          'used_silver',
        ),
        _buildLineBarData(
          widget.data.asMap().entries.map((entry) => FlSpot(entry.key.toDouble(), entry.value.remainingSilver)).toList(),
          const Color(0xFF2196F3),
          'remaining_silver',
        ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchCallback: (FlTouchEvent event, LineTouchResponse? touchResponse) {
          setState(() {
            if (touchResponse?.lineBarSpots?.isNotEmpty == true) {
              touchedIndex = touchResponse!.lineBarSpots!.first.spotIndex;
            } else {
              touchedIndex = -1;
            }
          });
        },
        handleBuiltInTouches: true,
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => isDarkMode
              ? const Color(0xFF2A2A2A)
              : Colors.white,
          getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
            return touchedBarSpots.map((barSpot) {
              final index = barSpot.spotIndex;
              final data = widget.data[index];
              String label = '';
              String value = '';

              if (barSpot.barIndex == 0) {
                label = Translations.get('new_silver', widget.currentLang);
                value = '${data.newSilver.toStringAsFixed(2)}g';
              } else if (barSpot.barIndex == 1) {
                label = Translations.get('used_silver', widget.currentLang);
                value = '${data.usedSilver.toStringAsFixed(2)}g';
              } else {
                label = Translations.get('remaining_silver', widget.currentLang);
                value = '${data.remainingSilver.toStringAsFixed(2)}g';
              }

              return LineTooltipItem(
                '$value\n$label',
                BilingualTextStyles.getTextStyle(
                  text: '$value\n$label',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  LineChartBarData _buildLineBarData(List<FlSpot> spots, Color color, String type) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, barData, index) {
          return FlDotCirclePainter(
            radius: 3,
            color: color,
            strokeWidth: 2,
            strokeColor: Colors.white,
          );
        },
      ),
      belowBarData: BarAreaData(
        show: type == 'remaining_silver',
        color: color.withOpacity(0.1),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDateLabel(DateTime date) {
    return '${date.day}/${date.month}';
  }
}