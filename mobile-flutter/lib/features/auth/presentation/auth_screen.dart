import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_typography.dart';
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
  bool _rememberMe = true;

  // Exact Web & Welcome Screen Palette
  static const Color _webGold = Color(0xFFD4AF37);
  static const Color _webRose = Color(0xFFE27D8D);
  static const Color _webDeepPurple = Color(0xFF2D1B4E);
  static const Color _webObsidian = Color(0xFF0A0E14);
  static const Color _webOffWhite = Color(0xFFF5F5F1);
  static const Color _webSlateMuted = Color(0xFF94A3B8);
  static const Color _webInputFill = Color(0xFF0F141E);

  static const LinearGradient _webRoseGlowGradient = LinearGradient(
    colors: [_webRose, _webDeepPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialSignUp;
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final storage = ref.read(secureStorageProvider);
    final results = await Future.wait([
      storage.getRememberMe(),
      storage.getSavedEmail(),
      storage.getSavedPassword(),
    ]);
    final remember = results[0] as bool;
    final savedEmail = results[1] as String?;
    final savedPassword = results[2] as String?;

    if (!mounted) return;
    setState(() {
      _rememberMe = remember;
      if (remember) {
        if (savedEmail != null && savedEmail.isNotEmpty && _emailController.text.isEmpty) {
          _emailController.text = savedEmail;
        }
        if (savedPassword != null && savedPassword.isNotEmpty && _passwordController.text.isEmpty) {
          _passwordController.text = savedPassword;
        }
      }
    });
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
      // Trigger native Android Google Password Manager / iOS Keychain prompt
      TextInput.finishAutofillContext(shouldSave: _rememberMe);

      // Persist or clear encrypted local credentials asynchronously in background
      final storage = ref.read(secureStorageProvider);
      if (_rememberMe) {
        storage.saveCredentials(email, password);
      } else {
        storage.setRememberMe(false);
      }

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
      backgroundColor: _webObsidian,
      body: Stack(
        children: [
          // Ambient background glow (Matches Welcome Screen & Web .brand-bg-glow)
          Positioned(
            top: -120,
            left: -80,
            right: -80,
            child: IgnorePointer(
              child: Container(
                height: 420,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _webDeepPurple.withValues(alpha: 0.45),
                      _webGold.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                    radius: 0.85,
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Branded Logo KNOT.
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'KNOT',
                          style: AppTypography.displayLarge.copyWith(
                            letterSpacing: 4.0,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: _webOffWhite,
                          ),
                        ),
                        Text(
                          '.',
                          style: AppTypography.displayLarge.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: _webGold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Pill Badge Tagline (Matches Welcome Screen)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.04),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: _webGold,
                            size: 12.5,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            'WHERE TRUE RELATIONSHIP LEADS TO VOW',
                            style: AppTypography.labelSmall.copyWith(
                              color: _webGold,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Auth Form Card (Clean, Sharp Glass Aesthetic)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xB3121721),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.55),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card Title & Subtitle
                            Text(
                              _isSignUp ? 'Join the Registry' : 'Welcome Back',
                              style: AppTypography.headingLarge.copyWith(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSignUp
                                  ? 'Enter your email and a secure password to begin your matrimonial journey.'
                                  : 'Sign in to access your curated matches and AI coach.',
                              style: AppTypography.bodySmall.copyWith(
                                color: _webSlateMuted,
                                fontSize: 12.5,
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Segmented Tab Switcher (Sharp Pill Style)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.04),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isSignUp = false),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 9.5),
                                        decoration: BoxDecoration(
                                          color: !_isSignUp
                                              ? _webDeepPurple.withValues(alpha: 0.5)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: !_isSignUp
                                                ? _webGold.withValues(alpha: 0.40)
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'SIGN IN',
                                            style: AppTypography.labelLarge.copyWith(
                                              color: !_isSignUp ? _webGold : const Color(0xFF6B7280),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(() => _isSignUp = true),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        padding: const EdgeInsets.symmetric(vertical: 9.5),
                                        decoration: BoxDecoration(
                                          color: _isSignUp
                                              ? _webDeepPurple.withValues(alpha: 0.5)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _isSignUp
                                                ? _webGold.withValues(alpha: 0.40)
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'JOIN REGISTRY',
                                            style: AppTypography.labelLarge.copyWith(
                                              color: _isSignUp ? _webGold : const Color(0xFF6B7280),
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 0.8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Error Banner
                            if (authState.errorMessage != null) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Color(0xFFF87171),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        authState.errorMessage!,
                                        style: AppTypography.bodySmall.copyWith(
                                          color: const Color(0xFFF87171),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            // Email Label & Field
                            Text(
                              'EMAIL ADDRESS',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFF94A3B8),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: _webInputFill,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: TextField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email, AutofillHints.username],
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'name@email.com',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13.5,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.mail_outline,
                                    color: _webGold,
                                    size: 18,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Password Label & Field
                            Text(
                              'PASSWORD',
                              style: AppTypography.labelSmall.copyWith(
                                color: const Color(0xFF94A3B8),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              decoration: BoxDecoration(
                                color: _webInputFill,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                autofillHints: _isSignUp
                                    ? const [AutofillHints.newPassword]
                                    : const [AutofillHints.password],
                                onSubmitted: (_) => _handleSubmit(),
                                style: AppTypography.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Enter your password',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF64748B),
                                    fontSize: 13.5,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.lock_outline,
                                    color: _webGold,
                                    size: 18,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: const Color(0xFF94A3B8),
                                      size: 18,
                                    ),
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Remember Me Checkbox
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () async {
                                final nextVal = !_rememberMe;
                                setState(() => _rememberMe = nextVal);
                                await ref.read(secureStorageProvider).setRememberMe(nextVal);
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 2),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(6),
                                        color: _rememberMe ? _webGold : _webInputFill,
                                        border: Border.all(
                                          color: _rememberMe
                                              ? _webGold
                                              : Colors.white.withValues(alpha: 0.20),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _rememberMe
                                          ? const Icon(
                                              Icons.check,
                                              size: 14,
                                              color: _webObsidian,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Remember my Email & Password on this device',
                                          maxLines: 1,
                                          softWrap: false,
                                          style: AppTypography.bodySmall.copyWith(
                                            color: _rememberMe ? Colors.white : _webSlateMuted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Primary CTA Button (Matches Web rose-glow-btn)
                            GestureDetector(
                              onTap: isLoading ? null : _handleSubmit,
                              child: Container(
                                width: double.infinity,
                                height: 50,
                                decoration: BoxDecoration(
                                  gradient: _webRoseGlowGradient,
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _webRose.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              _isSignUp ? 'Apply & Join Registry' : 'Access Registry',
                                              style: AppTypography.labelLarge.copyWith(
                                                color: Colors.white,
                                                fontSize: 13.5,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Quick Switch Link
                    GestureDetector(
                      onTap: () => setState(() => _isSignUp = !_isSignUp),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: RichText(
                          text: TextSpan(
                            style: AppTypography.bodySmall.copyWith(
                              color: _webSlateMuted,
                              fontSize: 12,
                            ),
                            children: [
                              TextSpan(
                                text: _isSignUp ? 'Already a member? ' : 'Not on the registry yet? ',
                              ),
                              TextSpan(
                                text: _isSignUp ? 'Sign In' : 'Apply here',
                                style: const TextStyle(
                                  color: _webGold,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Return to Welcome Page Link
                    TextButton.icon(
                      onPressed: () => context.go('/welcome?preview=true'),
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        size: 14,
                        color: _webGold,
                      ),
                      label: Text(
                        'Return to Welcome Page • Read All About KNOT',
                        style: AppTypography.bodySmall.copyWith(
                          color: _webGold,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Trust & KYC Security Note
                    Text(
                      'Protected by Didit Sovereign KYC & Biometric Identity Verification.',
                      style: AppTypography.bodySmall.copyWith(
                        fontSize: 10.5,
                        color: const Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
