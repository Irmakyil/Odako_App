import 'package:flutter/material.dart';
import 'custom_text_field.dart';

class RegisterForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onRegister;
  final VoidCallback onGoogleSignIn;
  final String googleButtonLabel;
  final Widget googleIcon;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onRegister,
    required this.onGoogleSignIn,
    this.googleButtonLabel = 'Sign Up with Google',
    required this.googleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: nameController,
            labelText: 'Name',
            validator: (value) => value == null || value.isEmpty ? 'Name is required' : null,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: emailController,
            labelText: 'Email',
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
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: InkWell(
              onTap: isLoading ? null : onRegister,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('lib/presentation/assets/signin&out_button_blue.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Create Account',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: const [
              Expanded(child: Divider()),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text('or', style: TextStyle(color: Colors.black87)),
              ),
              Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: InkWell(
              onTap: isLoading ? null : onGoogleSignIn,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage('lib/presentation/assets/signin&out_button_pink.png'),
                    fit: BoxFit.fill,
                  ),
                ),
                alignment: Alignment.center,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          googleIcon,
                          const SizedBox(width: 8),
                          Text(
                            googleButtonLabel,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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