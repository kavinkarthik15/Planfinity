import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:planfinity/core/services/api_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  double totalSpent = 0;
  Map categoryData = {};
  List insights = [];
  List<String> alerts = [];

  @override
  void initState() {
    super.initState();
    loadAnalytics();
    loadInsights();
    loadAlerts();
  }

  void loadAnalytics() async {
    final data = await ApiService.getAnalytics();
    if (!mounted) {
      return;
    }

    setState(() {
      totalSpent = (data['total_spent'] ?? 0).toDouble();
      categoryData = data['category_data'] ?? {};
    });
  }

  void loadInsights() async {
    final data = await ApiService.getInsights();
    if (!mounted) {
      return;
    }

    setState(() {
      insights = data;
    });
  }

  void loadAlerts() async {
    final userEmail = await ApiService.getUserEmail();
    if (userEmail == null) {
      return;
    }

    final aiData = await ApiService.getAiAnalysis(userEmail);
    if (!mounted) {
      return;
    }

    setState(() {
      alerts = List<String>.from(aiData['alerts'] ?? []);
    });
  }

  Color getAlertColor(String alert) {
    if (alert.contains('Unusual spike') || alert.contains('Overspending')) {
      return Colors.red.shade50;
    } else if (alert.contains('exceeded') || alert.contains('Exceeded')) {
      return Colors.red.shade50;
    } else if (alert.contains('used') || alert.contains('Great job')) {
      return Colors.green.shade50;
    } else if (alert.contains('No transactions') || alert.contains('recently')) {
      return Colors.orange.shade50;
    }
    return Colors.blue.shade50;
  }

  IconData getAlertIcon(String alert) {
    if (alert.contains('Great job')) {
      return Icons.check_circle;
    } else if (alert.contains('spike') || alert.contains('Spike')) {
      return Icons.trending_up;
    } else if (alert.contains('budget') || alert.contains('Budget')) {
      return Icons.warning;
    } else if (alert.contains('No transactions')) {
      return Icons.timer_off;
    }
    return Icons.info;
  }

  Widget buildAlertsSection() {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Smart Alerts',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...alerts.map<Widget>((alert) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: getAlertColor(alert),
                border: Border.all(
                  color: alert.contains('Great job')
                      ? Colors.green
                      : alert.contains('spike') || alert.contains('exceeded')
                          ? Colors.red
                          : Colors.orange,
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    getAlertIcon(alert),
                    size: 20,
                    color: alert.contains('Great job')
                        ? Colors.green
                        : alert.contains('spike') || alert.contains('exceeded')
                            ? Colors.red
                            : Colors.orange,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      alert,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget buildPieChart() {
    if (categoryData.isEmpty) {
      return const Text('No data');
    }

    final double total = categoryData.values
        .fold<double>(0, (a, b) => a + (b as num).toDouble());

    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: categoryData.entries.map((entry) {
            final double value = (entry.value as num).toDouble();
            final double percentage = total == 0 ? 0 : (value / total) * 100;

            return PieChartSectionData(
              value: value,
              title: '${percentage.toStringAsFixed(1)}%',
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget buildLineChart() {
    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: const [
                FlSpot(1, 200),
                FlSpot(2, 500),
                FlSpot(3, 300),
                FlSpot(4, 700),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Spent: Rs $totalSpent',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            buildAlertsSection(),
            const SizedBox(height: 20),
            const Text('Category Breakdown'),
            buildPieChart(),
            const SizedBox(height: 20),
            const Text('Spending Trend'),
            buildLineChart(),
            const SizedBox(height: 20),
            const Text('Insights'),
            ...insights.map<Widget>((i) {
              return ListTile(
                leading: const Icon(Icons.lightbulb),
                title: Text(i.toString()),
              );
            }),
          ],
        ),
      ),
    );
  }
}
