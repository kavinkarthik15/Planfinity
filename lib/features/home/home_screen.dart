import 'package:flutter/material.dart';

import '../../core/constants/ui_constants.dart';
import '../../core/services/api_service.dart';
import '../../core/theme/theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/error_widget.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../insights/insights_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic>? dashboardData;
  bool isLoading = true;
  bool hasError = false;
  bool _isLoaded = false;
  double _fabTurns = 0;
  bool _showAlerts = false;
  int _categoriesVersion = 0;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final token = await ApiService.getStoredToken();
      if (token == null || token.isEmpty) {
        throw Exception('Missing auth token. Please log in again.');
      }

      final data = await ApiService.getDashboardData(token);

      if (!mounted) {
        return;
      }

      setState(() {
        dashboardData = data;
        isLoading = false;
        hasError = false;
        _isLoaded = true;
        _showAlerts = false;
        _categoriesVersion++;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() {
          _showAlerts = true;
        });
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        isLoading = false;
        hasError = true;
        _isLoaded = false;
      });
    }
  }

  String getEmoji(String category) {
    final lower = category.toLowerCase();
    if (lower == 'food') {
      return '🍔';
    }
    if (lower == 'travel') {
      return '✈️';
    }
    if (lower == 'shopping') {
      return '🛍️';
    }
    return '💰';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeInOut,
      switchOutCurve: Curves.easeInOut,
      child: isLoading
          ? _buildLoadingUI()
          : hasError
              ? _buildErrorUI()
              : AnimatedOpacity(
                  opacity: _isLoaded ? 1 : 0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                  child: _buildMainUI(),
                ),
    );
  }

  Widget _buildLoadingUI() {
    return Scaffold(
      key: const ValueKey('loading'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UIConstants.padding),
          child: const SkeletonLoader(),
        ),
      ),
    );
  }

  Widget _buildErrorUI() {
    return Scaffold(
      key: const ValueKey('error'),
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomErrorWidget(onRetry: fetchDashboard),
      ),
    );
  }

  Widget _buildMainUI() {
    return Scaffold(
      key: const ValueKey('main'),
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _fabTurns += 0.12;
          });
          Future.delayed(const Duration(milliseconds: 280), () {
            if (!mounted) {
              return;
            }
            setState(() {
              _fabTurns = _fabTurns - 0.12;
            });
          });
        },
        child: AnimatedRotation(
          turns: _fabTurns,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: const Icon(Icons.add),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: fetchDashboard,
          child: Padding(
            padding: const EdgeInsets.all(UIConstants.padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 20),
                _buildHeroCard(),
                const SizedBox(height: 16),
                _buildAIInsight(),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    children: [
                      ..._buildAnimatedCategoryCards(),
                      const SizedBox(height: 16),
                      if (_alertsFromData.isEmpty)
                        _buildAlertCard('No active alerts right now')
                      else
                        ..._alertsFromData.take(3).toList().asMap().entries.map(
                          (entry) => _buildAnimatedAlertCard(
                            entry.value,
                            entry.key,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final total = (dashboardData?['total_spending'] as num?)?.toDouble() ?? 0;

    return Row(
      children: [
        Text('Planfinity', style: AppTextStyles.headline),
        const Spacer(),
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                transitionDuration: const Duration(milliseconds: 400),
                pageBuilder: (context, animation, secondaryAnimation) => InsightsScreen(
                  totalSpending: total,
                ),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
              ),
            );
          },
          icon: const Icon(Icons.insights_outlined, color: Colors.white70),
        ),
        IconButton(
          onPressed: fetchDashboard,
          icon: const Icon(Icons.refresh, color: Colors.white70),
        ),
      ],
    );
  }

  List<dynamic> get _categoriesFromData {
    final raw = dashboardData?['categories'];
    if (raw is List) {
      return raw;
    }
    return const [];
  }

  List<String> get _alertsFromData {
    final raw = dashboardData?['alerts'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  List<Widget> _buildCategoryCards() {
    if (_categoriesFromData.isEmpty) {
      return [_buildCategoryCard('No data', 'Rs 0', '+0%', '💰')];
    }

    return _categoriesFromData.map<Widget>((cat) {
      final name = cat['name']?.toString() ?? 'Other';
      final amount = (cat['amount'] as num?)?.toDouble() ?? 0;
      final change = (cat['change'] as num?)?.toDouble() ?? 0;
      final sign = change >= 0 ? '+' : '';

      return _buildCategoryCard(
        name,
        'Rs ${amount.toStringAsFixed(0)}',
        '$sign${change.toStringAsFixed(1)}%',
        getEmoji(name),
      );
    }).toList();
  }

  List<Widget> _buildAnimatedCategoryCards() {
    final categories = _buildCategoryCards();

    return [
      AnimatedList(
        key: ValueKey('category_list_$_categoriesVersion'),
        initialItemCount: categories.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeInOut));

          return SizeTransition(
            sizeFactor: animation,
            child: SlideTransition(
              position: slide,
              child: categories[index],
            ),
          );
        },
      ),
    ];
  }

  Widget _buildAnimatedAlertCard(String alert, int index) {
    return TweenAnimationBuilder<Offset>(
      tween: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: _showAlerts ? Offset.zero : const Offset(0, 0.5),
      ),
      duration: Duration(milliseconds: 280 + (index * 80)),
      curve: Curves.easeInOut,
      child: _buildAlertCard(alert),
      builder: (context, offset, child) {
        return Transform.translate(
          offset: Offset(0, offset.dy * 30),
          child: child,
        );
      },
    );
  }

  Widget _buildHeroCard() {
    final total = (dashboardData?['total_spending'] as num?)?.toDouble() ?? 0;
    final change = (dashboardData?['change'] as num?)?.toDouble() ?? 0;
    final weeklyText =
        '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}% from last week';

    return Container(
      padding: const EdgeInsets.all(UIConstants.padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
        ),
        borderRadius: BorderRadius.circular(UIConstants.radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Spending', style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          Hero(
            tag: 'total_spending',
            child: Material(
              color: Colors.transparent,
              child: Text(
                'Rs ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(weeklyText, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildAIInsight() {
    return Container(
      padding: const EdgeInsets.all(UIConstants.padding),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Colors.purple, Colors.blue]),
        borderRadius: BorderRadius.circular(UIConstants.radius),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              dashboardData?['insight']?.toString() ??
                  'You may exceed your monthly budget by Rs 2000',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(
    String title,
    String amount,
    String change,
    String badge,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.secondary,
              child: Text(
                badge,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.title),
                Text(amount, style: AppTextStyles.body),
              ],
            ),
            const Spacer(),
            Text(
              change,
              style: TextStyle(
                color:
                    change.contains('+') ? AppColors.danger : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(String message) {
    return Container(
      padding: const EdgeInsets.all(UIConstants.padding),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(UIConstants.radius),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning, color: AppColors.danger),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: AppTextStyles.body)),
        ],
      ),
    );
  }
}
