import 'dart:ui';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/auth_wrapper.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter both email address and password')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential = await _authService.loginWithEmail(email, password);

      if (!mounted) return;

      // Check if user is a doctor pending admin approval
      if (credential.user != null) {
        final userData = await _authService.getUserData(credential.user!.uid);
        if (userData != null &&
            userData.role == 'doctor' &&
            !userData.isApproved) {
          await _authService.signOut();
          if (!mounted) return;

          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              icon: Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEF3C7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.hourglass_top_rounded,
                    size: 40, color: Color(0xFFD97706)),
              ),
              title: const Text(
                'Account Pending Approval',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: const Text(
                'Your doctor account has been registered successfully, but the hospital admin has not approved your account yet.\n\n'
                'Please wait for the admin to review and approve your registration before logging in.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, height: 1.5),
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('OK, I Understand'),
                  ),
                ),
              ],
            ),
          );

          setState(() => _isLoading = false);
          return;
        }
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AuthWrapper()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.height < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // 1. Soft light background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFEFF6FF),
                  Color(0xFFF8FAFC),
                  Color(0xFFFFFFFF),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // 2. Subtle blue glows (very light)
          Positioned(
            top: -140,
            left: -120,
            child: _glow(
                color: const Color(0xFF93C5FD).withOpacity(0.45), radius: 260),
          ),
          Positioned(
            top: 100,
            right: -160,
            child: _glow(
                color: const Color(0xFFBFDBFE).withOpacity(0.55), radius: 240),
          ),
          Positioned(
            bottom: -180,
            left: -100,
            child: _glow(
                color: const Color(0xFFDBEAFE).withOpacity(0.7), radius: 280),
          ),

          // 3. Content
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: isSmallScreen ? 24 : 44),

                        // Brand badge
                        Center(
                          child: _buildBrandBadge(),
                        ),
                        const SizedBox(height: 20),

                        const Text(
                          'OPD Connect',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                            letterSpacing: 0.4,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Government Hospital Booking & Queue Tracker',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5,
                            color: Colors.blueGrey.shade500,
                            height: 1.4,
                            letterSpacing: 0.2,
                          ),
                        ),

                        SizedBox(height: isSmallScreen ? 32 : 48),

                        // Form card
                        _buildFormCard(isSmallScreen),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────

  Widget _glow({required Color color, required double radius}) {
    return Container(
      width: radius,
      height: radius,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  Widget _buildBrandBadge() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2563EB),
            Color(0xFF3B82F6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.35),
            blurRadius: 28,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.18),
              border: Border.all(
                color: Colors.white.withOpacity(0.35),
                width: 1.2,
              ),
            ),
            child: const Icon(
              Icons.local_hospital_rounded,
              size: 42,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          22, isSmallScreen ? 22 : 28, 22, isSmallScreen ? 22 : 26),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Heading with gradient accent
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF2563EB)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(rect),
            child: const Text(
              'Welcome Back',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sign in to continue to your account',
            style: TextStyle(
              fontSize: 13.5,
              color: Colors.blueGrey.shade400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),

          // Email
          _buildField(
            controller: _emailController,
            label: 'Email Address',
            hint: 'e.g. user@gmail.com',
            icon: Icons.email_outlined,
            isFocused: _isEmailFocused,
            onFocusChange: (v) => setState(() => _isEmailFocused = v),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 16),

          // Password
          _buildField(
            controller: _passwordController,
            label: 'Password',
            icon: Icons.lock_outline_rounded,
            isFocused: _isPasswordFocused,
            onFocusChange: (v) => setState(() => _isPasswordFocused = v),
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _login(),
            suffix: IconButton(
              splashRadius: 20,
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.blueGrey.shade400,
                size: 22,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
          const SizedBox(height: 26),

          // Login button with glow
          _isLoading
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: Color(0xFF2563EB)),
                  ),
                )
              : _buildGlowButton(
                  label: 'Login',
                  onTap: _login,
                  icon: Icons.arrow_forward_rounded,
                ),
          const SizedBox(height: 22),

          // Divider accent
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: const Color(0xFFE2E8F0),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'or',
                  style: TextStyle(
                    color: Colors.blueGrey.shade400,
                    fontSize: 12,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: const Color(0xFFE2E8F0),
                  thickness: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Register pill
          Center(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFFDBEAFE),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const RegisterScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  foregroundColor: const Color(0xFF2563EB),
                ),
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 13.5,
                      color: Colors.blueGrey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                    children: const [
                      TextSpan(text: "New to OPD Connect?  "),
                      TextSpan(
                        text: 'Register Here',
                        style: TextStyle(
                          color: Color(0xFF2563EB),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isFocused,
    required ValueChanged<bool> onFocusChange,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
  }) {
    return Focus(
      onFocusChange: onFocusChange,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: isFocused
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          autocorrect: false,
          enableSuggestions: false,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: Color(0xFF0F172A),
          ),
          cursorColor: const Color(0xFF2563EB),
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            hintStyle: TextStyle(
                color: Colors.blueGrey.shade300, fontSize: 13.5),
            labelStyle: TextStyle(
              color: isFocused
                  ? const Color(0xFF2563EB)
                  : Colors.blueGrey.shade500,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: const TextStyle(
              color: Color(0xFF2563EB),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
            prefixIcon: Icon(
              icon,
              color: isFocused
                  ? const Color(0xFF2563EB)
                  : Colors.blueGrey.shade400,
              size: 21,
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: Color(0xFFE2E8F0), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                  color: Color(0xFF2563EB), width: 1.6),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlowButton({
    required String label,
    required VoidCallback onTap,
    IconData? icon,
  }) {
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient glow under the button
          Container(
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2563EB).withOpacity(0.45),
                  blurRadius: 28,
                  spreadRadius: 1,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              disabledBackgroundColor:
                  const Color(0xFF2563EB).withOpacity(0.6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
              shadowColor: Colors.transparent,
            ),
            onPressed: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
                if (icon != null) ...[
                  const SizedBox(width: 8),
                  Icon(icon, size: 20),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}