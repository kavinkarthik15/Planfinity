import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/theme/theme.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({
    super.key,
    required this.totalSpending,
  });

  final double totalSpending;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Insights'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(UIConstants.padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'total_spending',
              child: Material(
                color: Colors.transparent,
                child: Text(
                  'Rs ${totalSpending.toStringAsFixed(0)}',
                  style: AppTextStyles.headline.copyWith(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Spending Trend', style: AppTextStyles.title),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(UIConstants.padding),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(UIConstants.radius),
              ),
              child: SizedBox(
                height: 180,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInOut,
                  builder: (context, progress, _) {
                    return LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        titlesData: const FlTitlesData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: [
                              FlSpot(0, 2 * progress),
                              FlSpot(1, 3.5 * progress),
                              FlSpot(2, 2.8 * progress),
                              FlSpot(3, 4.2 * progress),
                              FlSpot(4, 3.4 * progress),
                            ],
                            isCurved: true,
                            barWidth: 3,
                            color: AppColors.secondary,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.secondary.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
