import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ArchivedDataChart extends StatelessWidget {
  final List<double> data;

  ArchivedDataChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: data
                  .asMap()
                  .entries
                  .map((e) => FlSpot(e.key.toDouble(), e.value))
                  .toList(),
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}
