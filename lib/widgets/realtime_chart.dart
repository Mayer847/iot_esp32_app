import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class RealtimeChart extends StatelessWidget {
  final List<double> data;

  RealtimeChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150, // Adjust this value as needed
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList()
                  .sublist(data.length > 20
                      ? data.length - 20
                      : 0), // Only take the last 20 data points or less if data has less than 20 points
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
