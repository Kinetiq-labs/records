import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/analytics_service.dart';
import '../../utils/translations.dart';
import '../../utils/bilingual_text_styles.dart';
import '../../services/tehlil_price_service.dart';

class RevenueLineChart extends StatefulWidget {
  final List<AnalyticsData> data;
  final String currentLang;

  const RevenueLineChart({
    super.key,
    required this.data,
    required this.currentLang,
  });

  @override
  State<RevenueLineChart> createState() => _RevenueLineChartState();
}

class _RevenueLineChartState extends State<RevenueLineChart> {
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
          height: 200,
          padding: const EdgeInsets.all(16),
          child: LineChart(
            _buildLineChartData(isDarkMode),
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
          Icons.trending_up,
          color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          Translations.get('revenue_trend', widget.currentLang),
          style: BilingualTextStyles.getTextStyle(
            text: Translations.get('revenue_trend', widget.currentLang),
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

  Widget _buildTouchedDataInfo(bool isDarkMode) {
    final data = widget.data[touchedIndex];
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${data.label}: ${TehlilPriceService.instance.formatAmountCompact(data.value)}',
                  style: BilingualTextStyles.getTextStyle(
                    text: '${data.label}: ${TehlilPriceService.instance.formatAmountCompact(data.value)}',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                if (data.additionalInfo != null)
                  Text(
                    data.additionalInfo!,
                    style: BilingualTextStyles.getTextStyle(
                      text: data.additionalInfo!,
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

  LineChartData _buildLineChartData(bool isDarkMode) {
    final maxY = widget.data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final minY = widget.data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final padding = (maxY - minY) * 0.1;
    final range = maxY - minY;
    final horizontalInterval = range > 0 ? range / 4 : maxY > 0 ? maxY / 4 : 1.0;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: horizontalInterval,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: isDarkMode ? Colors.white.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.3),
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
            interval: widget.data.length > 10 ? (widget.data.length / 5).floor().toDouble() : 1,
            getTitlesWidget: (double value, TitleMeta meta) {
              final index = value.toInt();
              if (index >= 0 && index < widget.data.length) {
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    widget.data[index].label,
                    style: BilingualTextStyles.getTextStyle(
                      text: widget.data[index].label,
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
            interval: horizontalInterval,
            reservedSize: 50,
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
          color: isDarkMode ? Colors.white.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      minX: 0,
      maxX: (widget.data.length - 1).toDouble(),
      minY: minY - padding,
      maxY: maxY + padding,
      lineBarsData: [
        LineChartBarData(
          spots: widget.data.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.value);
          }).toList(),
          isCurved: true,
          gradient: const LinearGradient(
            colors: [
              Color(0xFF4CAF50),
              Color(0xFF66BB6A),
            ],
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: const Color(0xFF4CAF50),
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF4CAF50).withValues(alpha: 0.3),
                const Color(0xFF4CAF50).withValues(alpha: 0.1),
              ],
            ),
          ),
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
              final flSpot = barSpot;
              final index = flSpot.spotIndex;
              final data = widget.data[index];
              return LineTooltipItem(
                '${TehlilPriceService.instance.formatAmountCompact(data.value)}\n${data.label}',
                BilingualTextStyles.getTextStyle(
                  text: '${TehlilPriceService.instance.formatAmountCompact(data.value)}\n${data.label}',
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
}