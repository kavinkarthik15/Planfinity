import 'package:flutter/material.dart';

import 'package:planfinity/core/services/api_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  List budgets = [];
  List alerts = [];

  @override
  void initState() {
    super.initState();
    loadBudgets();
  }

  void loadBudgets() async {
    final data = await ApiService.getBudgets();
    if (!mounted) {
      return;
    }
    setState(() {
      budgets = data['budgets'] ?? [];
      alerts = data['alerts'] ?? [];
    });
  }

  Color getColor(double percentage) {
    if (percentage > 90) {
      return Colors.red;
    }
    if (percentage > 70) {
      return Colors.orange;
    }
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budgets')),
      body: Column(
        children: [
          ...alerts.map((a) {
            return Container(
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.all(5),
              color: Colors.red.shade100,
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red),
                  const SizedBox(width: 10),
                  Expanded(child: Text(a.toString())),
                ],
              ),
            );
          }),
          Expanded(
            child: ListView.builder(
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final b = budgets[index];

                final double percentage =
                    (b['percentage'] as num?)?.toDouble() ?? 0;

                return Card(
                  child: ListTile(
                    title: Text(b['category'].toString()),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinearProgressIndicator(
                          value: (percentage / 100).clamp(0.0, 1.0),
                          color: getColor(percentage),
                        ),
                        const SizedBox(height: 5),
                        Text('Rs ${b['spent']} / Rs ${b['limit']}'),
                      ],
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
}
