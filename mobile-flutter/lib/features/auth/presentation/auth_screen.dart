import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/glass_card.dart';
import '../../../core/widgets/gold_button.dart';
import '../providers/auth_provider.dart';

class AuthScreen extends ConsumerStatefulWidget {
  final bool initialSignUp;

  const AuthScreen({
    super.key,
    this.initialSignUp = false,
  });

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  late bool _isSignUp;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
  }

  @override
  void didUpdateWidget(covariant AuthScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialSignUp != widget.initialSignUp) {
      setState(() {
        _isSignUp = widget.initialSignUp;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    final notifier = ref.read(authProvider.notifier);
    bool success;
    if (_isSignUp) {
      success = await notifier.register(email, password);
    } else {
      success = await notifier.login(email, password);
    }

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user?.firstName.isEmpty ?? true) {
        context.go('/onboarding');
      } else {
        context.go('/discovery');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      backgroundColor: AppColors.obsidianBlack,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branded Logo
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'KNOT',
                      style: AppTypography.displayLarge.copyWith(letterSpacing: 4.0),
                    ),
                    Text(
                      '.',
                      style: AppTypography.displayLarge.copyWith(color: AppColors.champagneGold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'True Relationship Leads to Vow',
                  style: AppTypography.headingMedium.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                    color: AppColors.champagneGold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Auth Form Glass Card
                GlassCard(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Toggle Tab
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSignUp = false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: !_isSignUp ? AppColors.champagneGold : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'SIGN IN',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: !_isSignUp ? AppColors.champagneGold : AppColors.textSubtle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _isSignUp = true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: _isSignUp ? AppColors.champagneGold : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    'JOIN REGISTRY',
                                    style: AppTypography.labelLarge.copyWith(
                                      color: _isSignUp ? AppColors.champagneGold : AppColors.textSubtle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.roseGlow.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.roseGlow, width: 0.8),
                          ),
                          child: Text(
                            authState.errorMessage!,
                            style: AppTypography.bodySmall.copyWith(color: AppColors.roseGlow),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Email Field
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                        decoration: const InputDecoration(
                          hintText: 'Email address',
                          prefixIcon: Icon(Icons.mail_outline, color: AppColors.champagneGold),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPure),
                        decoration: InputDecoration(
                          hintText: 'Master Password',
                          prefixIcon: const Icon(Icons.lock_outline, color: AppColors.champagneGold),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: AppColors.textSubtle,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      GoldButton(
                        text: _isSignUp ? 'Create Marriage Account' : 'Authenticate',
                        isLoading: isLoading,
                        onPressed: _handleSubmit,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Link to revisit the Welcome / Landing Experience anytime
                TextButton.icon(
                  onPressed: () => context.go('/welcome?preview=true'),
                  icon: const Icon(
                    Icons.auto_awesome_outlined,
                    size: 15,
                    color: AppColors.champagneGold,
                  ),
                  label: Text(
                    'Explore KNOT • How It Works & Trust Architecture',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.champagneGold,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Protected by Didit Sovereign KYC & Biometric Identity Verification.',
                  style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textSubtle),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
