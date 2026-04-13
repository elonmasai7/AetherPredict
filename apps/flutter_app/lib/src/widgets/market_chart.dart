import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MarketChart extends StatelessWidget {
  const MarketChart({super.key, required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: 1,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            isCurved: true,
            spots: [
              for (var i = 0; i < points.length; i++)
                FlSpot(i.toDouble(), points[i]),
            ],
            color: const Color(0xFF3ED6C5),
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF3ED6C5).withOpacity(0.18),
            ),
          ),
        ],
      ),
    );
  }
}
