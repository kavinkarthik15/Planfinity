import 'package:flutter/material.dart';
import 'package:planfinity/core/theme/theme.dart';
import 'package:planfinity/core/services/api_service.dart';
import 'package:planfinity/services/notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool _isLoggingIn = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  void loginUser() async {
    if (_isLoggingIn) {
      return;
    }
    setState(() {
      _isLoggingIn = true;
    });

    final bool success = await ApiService.login(
      email.text.trim(),
      password.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      final String? token = await NotificationService().getToken();
      if (token != null && token.isNotEmpty) {
        await ApiService.registerFcmToken(
          userId: email.text.trim(),
          fcmToken: token,
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login failed')));
    }

    if (mounted) {
      setState(() {
        _isLoggingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.xl,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF16203A), AppColors.background],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: AppColors.card,
                          child: Icon(Icons.account_balance_wallet, color: AppColors.secondary),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Planfinity',
                          style: AppTextStyles.title,
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Welcome Back',
                      style: AppTextStyles.headline,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Track spending, smart alerts, and AI insights in one place.',
                      style: AppTextStyles.body,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Row(
                children: [
                  _FeaturePill(icon: Icons.psychology_alt, text: 'AI Insights'),
                  SizedBox(width: 8),
                  _FeaturePill(icon: Icons.notifications_active, text: 'Smart Alerts'),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: AppRadius.xl,
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: const TextStyle(color: Colors.white70),
                        hintText: 'you@example.com',
                        hintStyle: const TextStyle(color: Colors.white30),
                        prefixIcon: const Icon(Icons.mail_outline, color: AppColors.info),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: password,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) {
                        if (!_isLoggingIn) {
                          loginUser();
                        }
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.info),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoggingIn ? null : loginUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          foregroundColor: Colors.black,
                          disabledBackgroundColor: const Color(0xFF334155),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.lg,
                          ),
                        ),
                        child: _isLoggingIn
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Sign In',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/signup');
                      },
                      child: const Text(
                        'New here? Create account',
                        style: TextStyle(color: AppColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeaturePill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.success, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
