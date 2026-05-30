import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/network/api_client.dart';
import '../core/providers/auth_controller.dart';
import '../ui/checkmate_ui.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;
  String? errorMessage;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = '이메일과 비밀번호를 입력해 주세요.');
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      await ref.read(authControllerProvider).login(email: email, password: password);
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      final message = (e is DioException && e.response?.statusCode == 401)
          ? '이메일 또는 비밀번호를 확인해 주세요.'
          : ApiClient.messageFromError(e);
      setState(() {
        errorMessage = message;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CMColors.bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0B61FF), CMColors.blue2],
                ),
              ),
            ),
          ),
          Positioned(
            left: -80,
            top: 150,
            child: Container(
              width: 480,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(260),
              ),
            ),
          ),
          Positioned(
            right: 42,
            top: 82,
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white.withValues(alpha: 0.8), size: 28),
          ),
          Positioned(
            left: 44,
            top: 330,
            child: Icon(Icons.auto_awesome_rounded, color: Colors.white.withValues(alpha: 0.65), size: 22),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 52),
                _BrandHero(),
                const Spacer(),
                _LoginPanel(
                  emailController: emailController,
                  passwordController: passwordController,
                  obscurePassword: obscurePassword,
                  errorMessage: errorMessage,
                  isLoading: isLoading,
                  onToggleObscure: () => setState(() => obscurePassword = !obscurePassword),
                  onLogin: login,
                  onSignup: () => context.go('/signup'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.16),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: const Icon(Icons.check_rounded, color: CMColors.blue, size: 58),
        ),
        const SizedBox(height: 34),
        const Text(
          'Checkmate',
          style: TextStyle(
            color: Colors.white,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.1,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          '친구들과 함께 인증하고,\n끝까지 완주하기',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.94),
            fontSize: 18,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _LoginPanel extends StatelessWidget {
  const _LoginPanel({
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.errorMessage,
    required this.isLoading,
    required this.onToggleObscure,
    required this.onLogin,
    required this.onSignup,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final String? errorMessage;
  final bool isLoading;
  final VoidCallback onToggleObscure;
  final VoidCallback onLogin;
  final VoidCallback onSignup;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('다시 만나서 반가워요! 👋', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900, color: CMColors.text)),
          const SizedBox(height: 7),
          const Text('로그인하고 미션을 이어가세요.', style: TextStyle(fontSize: 12, color: CMColors.sub)),
          const SizedBox(height: 26),
          _AuthField(
            controller: emailController,
            hint: 'example@email.com',
            icon: Icons.mail_outline_rounded,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 14),
          _AuthField(
            controller: passwordController,
            hint: '비밀번호 입력',
            icon: Icons.lock_outline_rounded,
            obscureText: obscurePassword,
            suffix: IconButton(
              onPressed: onToggleObscure,
              icon: Icon(
                obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: CMColors.muted,
                size: 20,
              ),
            ),
          ),
          if (errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(errorMessage!, style: const TextStyle(color: CMColors.red, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
          const SizedBox(height: 26),
          CMPrimaryButton(label: '로그인', onPressed: onLogin, loading: isLoading),
          const SizedBox(height: 52),
          Center(
            child: GestureDetector(
              onTap: onSignup,
              child: RichText(
                text: const TextSpan(
                  style: TextStyle(fontSize: 13, color: CMColors.sub),
                  children: [
                    TextSpan(text: '계정이 없으신가요? '),
                    TextSpan(
                      text: '회원가입',
                      style: TextStyle(color: CMColors.blue, fontWeight: FontWeight.w900),
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

class _AuthField extends StatelessWidget {
  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffix;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: const TextStyle(fontSize: 14, color: CMColors.text, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: CMColors.muted, size: 20),
          suffixIcon: suffix,
          hintText: hint,
          hintStyle: const TextStyle(color: CMColors.sub, fontWeight: FontWeight.w500),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CMColors.line)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFD8DEE8))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CMColors.blue, width: 1.5)),
        ),
      ),
    );
  }
}
