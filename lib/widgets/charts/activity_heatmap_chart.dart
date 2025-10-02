import 'package:flutter/material.dart';
import '../../utils/translations.dart';
import '../../utils/bilingual_text_styles.dart';

class ActivityHeatmapChart extends StatefulWidget {
  final Map<int, int> hourlyData;
  final String currentLang;

  const ActivityHeatmapChart({
    super.key,
    required this.hourlyData,
    required this.currentLang,
  });

  @override
  State<ActivityHeatmapChart> createState() => _ActivityHeatmapChartState();
}

class _ActivityHeatmapChartState extends State<ActivityHeatmapChart> {
  int? hoveredHour;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    if (widget.hourlyData.isEmpty || widget.hourlyData.values.every((v) => v == 0)) {
      return _buildNoDataWidget(isDarkMode);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChartHeader(isDarkMode),
        const SizedBox(height: 16),
        _buildHeatmap(isDarkMode),
        if (hoveredHour != null)
          _buildHourInfo(isDarkMode),
      ],
    );
  }

  Widget _buildChartHeader(bool isDarkMode) {
    return Row(
      children: [
        Icon(
          Icons.access_time,
          color: isDarkMode ? const Color(0xFF7FC685) : const Color(0xFF0B5D3B),
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          Translations.get('peak_hours', widget.currentLang),
          style: BilingualTextStyles.getTextStyle(
            text: Translations.get('peak_hours', widget.currentLang),
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
              Icons.access_time_outlined,
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

  Widget _buildHeatmap(bool isDarkMode) {
    final maxValue = widget.hourlyData.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTimeLabels(isDarkMode),
          const SizedBox(height: 8),
          _buildHeatmapGrid(isDarkMode, maxValue),
          const SizedBox(height: 16),
          _buildColorScale(isDarkMode, maxValue),
        ],
      ),
    );
  }

  Widget _buildTimeLabels(bool isDarkMode) {
    return Row(
      children: [
        const SizedBox(width: 40),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(6, (index) {
              final hour = index * 4;
              return Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: BilingualTextStyles.getTextStyle(
                  text: '${hour.toString().padLeft(2, '0')}:00',
                  fontSize: 10,
                  color: isDarkMode ? Colors.white70 : Colors.grey[600],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapGrid(bool isDarkMode, int maxValue) {
    return SizedBox(
      height: 120,
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDayLabel(Translations.get('mon', widget.currentLang), isDarkMode),
              _buildDayLabel(Translations.get('tue', widget.currentLang), isDarkMode),
              _buildDayLabel(Translations.get('wed', widget.currentLang), isDarkMode),
              _buildDayLabel(Translations.get('thu', widget.currentLang), isDarkMode),
              _buildDayLabel(Translations.get('fri', widget.currentLang), isDarkMode),
              _buildDayLabel(Translations.get('sat', widget.currentLang), isDarkMode),
              _buildDayLabel(Translations.get('sun', widget.currentLang), isDarkMode),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 24,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 24 * 7, // 24 hours × 7 days
              itemBuilder: (context, index) {
                final hour = index % 24;
                final day = index ~/ 24;

                // For demo purposes, we'll simulate weekday data based on hourly data
                final simulatedValue = _getSimulatedValue(hour, day);
                final intensity = maxValue > 0 ? (simulatedValue / maxValue).clamp(0.0, 1.0) : 0.0;

                return MouseRegion(
                  onEnter: (_) => setState(() => hoveredHour = hour),
                  onExit: (_) => setState(() => hoveredHour = null),
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getHeatmapColor(intensity, isDarkMode),
                      borderRadius: BorderRadius.circular(2),
                      border: hoveredHour == hour
                          ? Border.all(color: Colors.white, width: 1)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayLabel(String day, bool isDarkMode) {
    return SizedBox(
      width: 32,
      child: Text(
        day,
        style: BilingualTextStyles.getTextStyle(
          text: day,
          fontSize: 10,
          color: isDarkMode ? Colors.white70 : Colors.grey[600],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildColorScale(bool isDarkMode, int maxValue) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          Translations.get('less', widget.currentLang),
          style: BilingualTextStyles.getTextStyle(
            text: Translations.get('less', widget.currentLang),
            fontSize: 10,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Row(
          children: List.generate(5, (index) {
            final intensity = index / 4;
            return Container(
              width: 12,
              height: 12,
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: _getHeatmapColor(intensity, isDarkMode),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          Translations.get('more', widget.currentLang),
          style: BilingualTextStyles.getTextStyle(
            text: Translations.get('more', widget.currentLang),
            fontSize: 10,
            color: isDarkMode ? Colors.white70 : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildHourInfo(bool isDarkMode) {
    final hourData = widget.hourlyData[hoveredHour!] ?? 0;
    final timeLabel = _formatHourLabel(hoveredHour!);

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
      child: Row(
        children: [
          const Icon(
            Icons.access_time,
            color: Color(0xFF4CAF50),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$timeLabel - ${_formatHourLabel(hoveredHour! + 1)}',
                  style: BilingualTextStyles.getTextStyle(
                    text: '$timeLabel - ${_formatHourLabel(hoveredHour! + 1)}',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  '$hourData ${Translations.get('entries_count', widget.currentLang).toLowerCase()}',
                  style: BilingualTextStyles.getTextStyle(
                    text: '$hourData entries',
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

  Color _getHeatmapColor(double intensity, bool isDarkMode) {
    if (intensity == 0) {
      return isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5);
    }

    final baseColor = const Color(0xFF4CAF50);
    return Color.lerp(
      isDarkMode ? const Color(0xFF2A2A2A) : const Color(0xFFE8F5E8),
      baseColor,
      intensity,
    )!;
  }

  int _getSimulatedValue(int hour, int day) {
    // Simulate activity based on actual hour data with some variation for weekdays
    final baseValue = widget.hourlyData[hour] ?? 0;

    // Add some weekday variation (less activity on weekends)
    if (day >= 5) { // Weekend (Saturday = 5, Sunday = 6)
      return (baseValue * 0.6).round();
    } else if (day >= 3) { // Thursday-Friday
      return (baseValue * 0.9).round();
    } else { // Monday-Wednesday
      return baseValue;
    }
  }

  String _formatHourLabel(int hour) {
    final adjustedHour = hour % 24;
    return '${adjustedHour.toString().padLeft(2, '0')}:00';
  }
}