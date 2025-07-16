import 'package:flutter/material.dart';
import 'custom_text_field.dart';
import 'gradient_button.dart';

class LoginForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onLogin;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onForgotPassword;
  final Widget googleIcon;

  const LoginForm({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onLogin,
    required this.onGoogleSignIn,
    required this.onForgotPassword,
    required this.googleIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        children: [
          CustomTextField(
            controller: emailController,
            labelText: 'E-posta',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email is required';
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
              if (!emailRegex.hasMatch(value)) return 'Please enter a valid email address';
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: passwordController,
            labelText: 'Password',
            obscureText: true,
            validator: (value) => value == null || value.length < 6 ? 'At least 6 characters' : null,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : onForgotPassword,
              style: TextButton.styleFrom(foregroundColor: Colors.white),
              child: const Text('Forgot my password?'),
            ),
          ),
          const SizedBox(height: 16),
          GradientButton(
            text: 'Login',
            onPressed: isLoading ? null : onLogin,
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('or', style: TextStyle(color: Colors.white70)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide.none,
                textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: isLoading ? null : onGoogleSignIn,
              child: const Text('Sign in with Google'),
            ),
          ),
        ],
      ),
    );
  }
} 