import 'dart:math' as math;

import 'package:animations/animations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:planfinity/core/theme/theme.dart';
import 'package:planfinity/core/services/api_service.dart';

enum AlertLevel { high, medium, low }

class AlertMeta {
  const AlertMeta({
    required this.icon,
    required this.level,
    required this.background,
    required this.foreground,
    required this.label,
  });

  final IconData icon;
  final AlertLevel level;
  final Color background;
  final Color foreground;
  final String label;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;
  bool _isLoading = true;
  bool _isAdding = false;
  bool _fabPressed = false;

  List<dynamic> _transactions = [];
  List<dynamic> _insights = [];
  List<dynamic> _budgetItems = [];
  List<String> _alerts = [];

  Map<String, dynamic> _analytics = {};
  Map<String, dynamic> _aiResults = {};

  static const Map<String, String> _categoryIcons = {
    'food': '🍔',
    'travel': '✈️',
    'shopping': '🛍️',
    'bills': '🧾',
    'transport': '🚕',
    'health': '💊',
    'entertainment': '🎬',
    'other': '📦',
  };

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = await ApiService.getUserEmail();
      final results = await Future.wait([
        ApiService.getTransactions(),
        ApiService.getAnalytics(),
        ApiService.getInsights(),
        ApiService.getBudgets(),
        userId == null
            ? Future.value(<String, dynamic>{})
            : ApiService.getAiAnalysis(userId),
      ]);

      if (!mounted) {
        return;
      }

      final budgetData = results[3] as Map<String, dynamic>;
      final aiData = results[4] as Map<String, dynamic>;

      setState(() {
        _transactions = results[0] as List<dynamic>;
        _analytics = results[1] as Map<String, dynamic>;
        _insights = results[2] as List<dynamic>;
        _budgetItems = budgetData['budgets'] is List
            ? budgetData['budgets'] as List<dynamic>
            : [];
        _aiResults = aiData;
        _alerts = List<String>.from(aiData['alerts'] ?? const []);
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _transactions = [];
        _analytics = {};
        _insights = [];
        _budgetItems = [];
        _aiResults = {};
        _alerts = [];
        _isLoading = false;
      });
    }
  }

  double get _totalSpending => ((_analytics['total_spent'] ?? 0) as num).toDouble();

  Map<String, double> get _categorySpending {
    final raw = _analytics['category_data'];
    if (raw is! Map) {
      return {};
    }
    return raw.map(
      (key, value) => MapEntry(key.toString(), (value as num).toDouble()),
    );
  }

  double get _weeklyChangePercent {
    if (_transactions.isEmpty) {
      return 0;
    }

    final now = DateTime.now();
    final weekStart = now.subtract(const Duration(days: 7));
    final prevWeekStart = now.subtract(const Duration(days: 14));

    double thisWeek = 0;
    double previousWeek = 0;

    for (final item in _transactions) {
      if (item is! Map) {
        continue;
      }
      final amount = ((item['amount'] ?? 0) as num).toDouble();
      final rawDate =
          (item['created_at'] ?? item['date'] ?? item['timestamp'])?.toString();
      final dt = DateTime.tryParse(rawDate ?? '');
      if (dt == null) {
        continue;
      }

      if (dt.isAfter(weekStart)) {
        thisWeek += amount;
      } else if (dt.isAfter(prevWeekStart)) {
        previousWeek += amount;
      }
    }

    if (previousWeek <= 0) {
      return thisWeek > 0 ? 100 : 0;
    }

    return ((thisWeek - previousWeek) / previousWeek) * 100;
  }

  List<FlSpot> get _monthlyTrend {
    if (_transactions.isEmpty) {
      return const [];
    }

    final byMonth = <int, double>{};
    for (final item in _transactions) {
      if (item is! Map) {
        continue;
      }
      final amount = ((item['amount'] ?? 0) as num).toDouble();
      final rawDate =
          (item['created_at'] ?? item['date'] ?? item['timestamp'])?.toString();
      final dt = DateTime.tryParse(rawDate ?? '');
      final month = dt?.month ?? DateTime.now().month;
      byMonth[month] = (byMonth[month] ?? 0) + amount;
    }

    final sortedMonths = byMonth.keys.toList()..sort();
    return sortedMonths
        .map((month) => FlSpot(month.toDouble(), byMonth[month] ?? 0))
        .toList();
  }

  Future<void> _addTransactionFromDialog({
    required String amountText,
    required String category,
    required String note,
  }) async {
    final amount = double.tryParse(amountText.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid amount')),
      );
      return;
    }

    setState(() {
      _isAdding = true;
    });

    final success = await ApiService.addTransaction(amount, category, note.trim());

    if (!mounted) {
      return;
    }

    setState(() {
      _isAdding = false;
    });

    if (success) {
      Navigator.pop(context);
      await _loadAllData();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction added successfully')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to add transaction')),
      );
    }
  }

  Future<void> _showAddTransactionDialog() async {
    final amountController = TextEditingController();
    final noteController = TextEditingController();
    String selectedCategory = 'Food';

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Transaction'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: const [
                      DropdownMenuItem(value: 'Food', child: Text('Food')),
                      DropdownMenuItem(
                        value: 'Transport',
                        child: Text('Transport'),
                      ),
                      DropdownMenuItem(
                        value: 'Shopping',
                        child: Text('Shopping'),
                      ),
                      DropdownMenuItem(value: 'Travel', child: Text('Travel')),
                      DropdownMenuItem(
                        value: 'Entertainment',
                        child: Text('Entertainment'),
                      ),
                      DropdownMenuItem(value: 'Health', child: Text('Health')),
                      DropdownMenuItem(value: 'Other', child: Text('Other')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setDialogState(() {
                          selectedCategory = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: noteController,
                    decoration:
                        const InputDecoration(labelText: 'Note (optional)'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _isAdding ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: _isAdding
                      ? null
                      : () => _addTransactionFromDialog(
                            amountText: amountController.text,
                            category: selectedCategory,
                            note: noteController.text,
                          ),
                  child: _isAdding
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _emojiForCategory(String category) {
    final key = category.toLowerCase();
    for (final entry in _categoryIcons.entries) {
      if (key.contains(entry.key)) {
        return entry.value;
      }
    }
    return '📊';
  }

  AlertMeta _alertMeta(String message) {
    final text = message.toLowerCase();

    if (text.contains('overspending') || text.contains('exceed')) {
      return const AlertMeta(
        icon: Icons.crisis_alert,
        level: AlertLevel.high,
        label: 'High Priority',
        background: Color(0x33EF4444),
        foreground: AppColors.danger,
      );
    }
    if (text.contains('unusual') || text.contains('spike')) {
      return const AlertMeta(
        icon: Icons.warning_amber_rounded,
        level: AlertLevel.medium,
        label: 'Medium Priority',
        background: Color(0x33F59E0B),
        foreground: AppColors.warning,
      );
    }
    return const AlertMeta(
      icon: Icons.analytics_outlined,
      level: AlertLevel.low,
      label: 'Info',
      background: Color(0x3338BDF8),
      foreground: AppColors.info,
    );
  }

  String _currency(double value) {
    return 'Rs ${value.toStringAsFixed(0)}';
  }

  String _aiSummaryText() {
    final predictions = _aiResults['predictions'];
    if (predictions is! Map || predictions.isEmpty) {
      return 'AI is learning your pattern. Add a few more transactions for sharper projections.';
    }

    final projected = predictions.values.fold<double>(
      0,
      (sum, value) => sum + ((value as num?)?.toDouble() ?? 0),
    );

    final delta = projected - _totalSpending;
    if (delta > 0) {
      return 'You are likely to overspend this month by Rs ${delta.toStringAsFixed(0)} unless your pace drops.';
    }

    return 'You are projected to stay under budget by Rs ${delta.abs().toStringAsFixed(0)} this month.';
  }

  List<String> _budgetSuggestions() {
    final suggestions = <String>[];
    final predictions = _aiResults['predictions'];

    if (predictions is Map) {
      for (final entry in predictions.entries.take(3)) {
        final category = entry.key.toString();
        final predicted = (entry.value as num?)?.toDouble() ?? 0;
        final spent = _categorySpending[category] ?? 0;

        if (predicted > spent + 300) {
          suggestions.add(
            'Reduce ${category.toLowerCase()} spending by Rs 500 to stay within plan.',
          );
        }
      }
    }

    if (suggestions.isEmpty) {
      suggestions.add('Maintain current spending pace. You are tracking close to plan.');
    }

    return suggestions;
  }

  Widget _animatedReveal({
    required int index,
    required Widget child,
    double yOffset = 20,
  }) {
    final begin = 0.0 + (index * 0.08);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 420 + (index * 90)),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: begin, end: 1),
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, yOffset * (1 - value)),
            child: builtChild,
          ),
        );
      },
      child: child,
    );
  }

  Widget _surfaceCard({
    required Widget child,
    Gradient? gradient,
    Color? color,
    EdgeInsetsGeometry? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? (color ?? AppColors.card) : null,
        borderRadius: AppRadius.xl,
        border: Border.all(color: Colors.white10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _heroCard() {
    return _surfaceCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF4338CA), Color(0xFF0EA5A3)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Spending',
            style: AppTextStyles.body.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: _totalSpending),
            duration: const Duration(milliseconds: 700),
            builder: (context, value, _) {
              return Text(
                _currency(value),
                style: AppTextStyles.headline.copyWith(fontSize: 34),
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                _weeklyChangePercent >= 0
                    ? Icons.trending_up
                    : Icons.trending_down,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                '${_weeklyChangePercent >= 0 ? '+' : ''}${_weeklyChangePercent.toStringAsFixed(1)}% vs last week',
                style: AppTextStyles.body.copyWith(
                  color: Colors.white.withValues(alpha: 0.96),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _aiInsightCard() {
    final summary = _aiSummaryText();
    final number = RegExp(r'\d+').firstMatch(summary)?.group(0) ?? '';

    return _surfaceCard(
      gradient: const LinearGradient(
        colors: [Color(0xFF4C1D95), Color(0xFF1D4ED8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundColor: Color(0x33000000),
            child: Text('🧠', style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.body.copyWith(color: Colors.white),
                children: [
                  const TextSpan(
                    text: 'AI Insight\n',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: summary.replaceAll(number, ''),
                  ),
                  if (number.isNotEmpty)
                    TextSpan(
                      text: number,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFDE68A),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryCard(MapEntry<String, double> entry) {
    final category = entry.key;
    final amount = entry.value;
    final predictionMap = _aiResults['predictions'];
    final predicted = predictionMap is Map
        ? ((predictionMap[category] as num?)?.toDouble() ?? amount)
        : amount;
    final base = amount <= 0 ? 1 : amount;
    final change = ((predicted - amount) / base) * 100;
    final isRise = change >= 0;

    return _surfaceCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.secondary.withValues(alpha: 0.2),
            child: Text(
              _emojiForCategory(category),
              style: const TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category, style: AppTextStyles.title),
                Text(
                  _currency(amount),
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: (isRise ? AppColors.danger : AppColors.success)
                  .withValues(alpha: 0.18),
              borderRadius: const BorderRadius.all(Radius.circular(999)),
            ),
            child: Text(
              '${isRise ? '+' : ''}${change.toStringAsFixed(1)}%',
              style: TextStyle(
                color: isRise ? AppColors.danger : AppColors.success,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(String message, int index) {
    final meta = _alertMeta(message);

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 360 + (index * 80)),
      curve: Curves.easeOut,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset((1 - value) * 24, 0),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: meta.background,
          borderRadius: AppRadius.lg,
          border: Border.all(color: meta.foreground.withValues(alpha: 0.85)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(meta.icon, color: meta.foreground),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    meta.label,
                    style: TextStyle(
                      color: meta.foreground,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: AppTextStyles.body.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _homeTab() {
    final categories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          _animatedReveal(index: 0, child: _heroCard()),
          const SizedBox(height: AppSpacing.sm),
          _animatedReveal(index: 1, child: _aiInsightCard()),
          const SizedBox(height: AppSpacing.md),
          Text('Categories', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          if (categories.isEmpty)
            _surfaceCard(
              child: Text(
                'No category data yet.',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
            ),
          ...categories.take(5).toList().asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _animatedReveal(
                index: 2 + entry.key,
                child: _categoryCard(entry.value),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Alert Center', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          if (_alerts.isEmpty)
            _surfaceCard(
              color: const Color(0x3322C55E),
              child: Text(
                'No active alert. Spending pattern is healthy.',
                style: AppTextStyles.body.copyWith(color: Colors.white),
              ),
            ),
          ..._alerts.take(3).toList().asMap().entries.map(
            (entry) => _alertCard(entry.value, entry.key),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Widget _trendChart() {
    final trend = _monthlyTrend;
    final maxY = trend.isEmpty
        ? 100.0
        : trend.map((point) => point.y).reduce(math.max).clamp(100.0, double.infinity);

    return _surfaceCard(
      child: SizedBox(
        height: 210,
        child: trend.isEmpty
            ? Center(
                child: Text(
                  'No trend data available yet.',
                  style: AppTextStyles.body.copyWith(color: Colors.white70),
                ),
              )
            : TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 900),
                curve: Curves.easeOutCubic,
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, progress, _) {
                  final animatedSpots = trend
                      .map((spot) => FlSpot(spot.x, spot.y * progress))
                      .toList();

                  return LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: maxY * 1.15,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: maxY / 4,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: Color(0x2264748B),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: animatedSpots,
                          isCurved: true,
                          barWidth: 3,
                          color: AppColors.secondary,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.secondary.withValues(alpha: 0.18),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _insightsTab() {
    final predictionMap = _aiResults['predictions'];
    final feed = _insights
        .map((entry) => entry.toString().trim())
        .where((entry) => entry.isNotEmpty)
        .toList();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Spending Trend', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          _animatedReveal(index: 0, child: _trendChart()),
          const SizedBox(height: AppSpacing.md),
          _animatedReveal(index: 1, child: _aiInsightCard()),
          const SizedBox(height: AppSpacing.md),
          Text('Category Breakdown', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          if (predictionMap is Map && predictionMap.isNotEmpty)
            ...predictionMap.entries.toList().asMap().entries.map((entry) {
              final mapEntry = MapEntry<String, double>(
                entry.value.key.toString(),
                (entry.value.value as num?)?.toDouble() ?? 0,
              );
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _animatedReveal(
                  index: 2 + entry.key,
                  child: _categoryCard(mapEntry),
                ),
              );
            }),
          if (predictionMap is! Map || predictionMap.isEmpty)
            _surfaceCard(
              child: Text(
                'Category predictions will appear once AI has enough data.',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
            ),
          if (feed.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text('AI Feed', style: AppTextStyles.title),
            const SizedBox(height: AppSpacing.sm),
            ...feed.take(4).toList().asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _animatedReveal(
                  index: 5 + entry.key,
                  child: _surfaceCard(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.psychology, color: AppColors.info),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            entry.value,
                            style: AppTextStyles.body.copyWith(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Color _budgetColor(double progress) {
    if (progress >= 1) {
      return AppColors.danger;
    }
    if (progress >= 0.75) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  String _budgetState(double progress) {
    if (progress >= 1) {
      return 'Exceeded';
    }
    if (progress >= 0.75) {
      return 'Near Limit';
    }
    return 'Safe';
  }

  Widget _budgetTab() {
    final suggestions = _budgetSuggestions();

    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Text('Budget Health', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          if (_budgetItems.isEmpty)
            _surfaceCard(
              child: Text(
                'No budget categories configured yet.',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
            ),
          ..._budgetItems.toList().asMap().entries.map((entry) {
            final item = entry.value;
            if (item is! Map) {
              return const SizedBox.shrink();
            }

            final category = item['category'].toString();
            final spent = ((item['spent'] ?? 0) as num).toDouble();
            final limit = ((item['limit'] ?? 0) as num).toDouble();
            final progress = limit > 0 ? (spent / limit).clamp(0.0, 1.4) : 0.0;
            final color = _budgetColor(progress);

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _animatedReveal(
                index: entry.key,
                child: _surfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            _emojiForCategory(category),
                            style: const TextStyle(fontSize: 18),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(category, style: AppTextStyles.title),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.16),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(999)),
                            ),
                            child: Text(
                              _budgetState(progress),
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      LinearProgressIndicator(
                        value: progress.clamp(0.0, 1.0),
                        minHeight: 10,
                        borderRadius: const BorderRadius.all(Radius.circular(999)),
                        backgroundColor: Colors.white10,
                        color: color,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currency(spent)} / ${_currency(limit)} • ${(progress * 100).toStringAsFixed(0)}%',
                        style: AppTextStyles.body.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: AppSpacing.md),
          Text('AI Budget Suggestions', style: AppTextStyles.title),
          const SizedBox(height: AppSpacing.sm),
          ...suggestions.toList().asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _animatedReveal(
                index: entry.key + 4,
                child: _surfaceCard(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B0764), Color(0xFF1E3A8A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.tips_and_updates, color: Color(0xFFFDE68A)),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: AppTextStyles.body.copyWith(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  Widget _profileTab() {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _surfaceCard(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 30, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text('Planfinity User', style: AppTextStyles.title),
              Text(
                'Premium AI-driven spending assistant',
                style: AppTextStyles.body.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fab() {
    return Listener(
      onPointerDown: (_) {
        setState(() {
          _fabPressed = true;
        });
      },
      onPointerCancel: (_) {
        setState(() {
          _fabPressed = false;
        });
      },
      onPointerUp: (_) {
        setState(() {
          _fabPressed = false;
        });
      },
      child: AnimatedScale(
        duration: const Duration(milliseconds: 120),
        scale: _fabPressed ? 0.94 : 1,
        child: FloatingActionButton(
          onPressed: _showAddTransactionDialog,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const titles = ['Home', 'Insights', 'Budget', 'Profile'];
    final pages = [_homeTab(), _insightsTab(), _budgetTab(), _profileTab()];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titles[_currentTab],
          style: AppTextStyles.title.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            onPressed: _loadAllData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: _fab(),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : PageTransitionSwitcher(
              duration: const Duration(milliseconds: 320),
              transitionBuilder: (child, animation, secondaryAnimation) {
                return SharedAxisTransition(
                  transitionType: SharedAxisTransitionType.horizontal,
                  animation: animation,
                  secondaryAnimation: secondaryAnimation,
                  fillColor: AppColors.background,
                  child: child,
                );
              },
              child: KeyedSubtree(
                key: ValueKey<int>(_currentTab),
                child: pages[_currentTab],
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentTab,
        onDestinationSelected: (index) {
          setState(() {
            _currentTab = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            label: 'Insights',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            label: 'Budget',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
