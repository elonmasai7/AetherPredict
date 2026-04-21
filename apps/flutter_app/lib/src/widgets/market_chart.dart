import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MarketChart extends StatelessWidget {
  const MarketChart({
    super.key,
    required this.points,
    this.lineColor = const Color(0xFF3ED6C5),
    this.bandColor = const Color(0xFF3ED6C5),
    this.markerIndexes = const [],
    this.showGrid = false,
  });

  final List<double> points;
  final Color lineColor;
  final Color bandColor;
  final List<int> markerIndexes;
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    final chartPoints = points.isEmpty ? const [0.5, 0.5] : points;
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        gridData: FlGridData(
          show: showGrid,
          drawVerticalLine: true,
          horizontalInterval: 0.2,
          verticalInterval: 2,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: Color(0x1FFFFFFF), strokeWidth: 1),
          getDrawingVerticalLine: (_) =>
              const FlLine(color: Color(0x12FFFFFF), strokeWidth: 1),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFF283245)),
        ),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: [
              for (var i = 0; i < chartPoints.length; i++)
                FlSpot(i.toDouble(), chartPoints[i]),
            ],
            color: lineColor,
            barWidth: 2.6,
            dotData: FlDotData(
              show: true,
              checkToShowDot: (spot, barData) =>
                  markerIndexes.contains(spot.x.toInt()),
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 3.2,
                color: lineColor,
                strokeWidth: 1.4,
                strokeColor: Colors.white,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: bandColor.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}
