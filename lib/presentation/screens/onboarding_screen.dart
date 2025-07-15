import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/register_form.dart';
import '../widgets/login_form.dart';
import '../../routes/app_routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _registerEmailController = TextEditingController();
  final TextEditingController _registerPasswordController = TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _registerEmailController.dispose();
    _registerPasswordController.dispose();
    _loginEmailController.dispose();
    _loginPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_registerFormKey.currentState!.validate()) {
      debugPrint('Register form not valid');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      debugPrint('Attempting to register user...');
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _registerEmailController.text.trim(),
        password: _registerPasswordController.text.trim(),
      );
      debugPrint('User registered: ${credential.user?.uid}');
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'name': _nameController.text.trim(),
        'email': _registerEmailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      if (mounted) {
        debugPrint('Navigating to mood selection...');
        Navigator.pushReplacementNamed(context, AppRoutes.moodSelection);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Register error: ${e.code} - ${e.message}');
      setState(() { _errorMessage = e.message; });
    } catch (e) {
      debugPrint('Register unknown error: ${e.toString()}');
      setState(() { _errorMessage = 'An error occurred. Please try again.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      // Navigate to mood selection
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.moodSelection);
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      // 1. Trigger Google Sign-In
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() { _isLoading = false; });
        return;
      }
      // 2. Retrieve tokens
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;
      if (accessToken == null || idToken == null) {
        setState(() { _errorMessage = 'Signing in with Google failed.'; _isLoading = false; });
        return;
      }
      // 3. Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      // 4. Sign in to Firebase
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;
      if (user == null) {
        setState(() { _errorMessage = 'Login with Firebase failed.'; });
        return;
      }
      // 5. Firestore user doc
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnap = await userDoc.get();
      if (!docSnap.exists) {
        await userDoc.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      // 6. Save onboarding flag
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_complete', true);
      // 7. Navigate
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.moodSelection);
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message; });
    } catch (e) {
      setState(() { _errorMessage = 'There was an error logging in with Google.'; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  void _forgotPassword() async {
    if (_loginEmailController.text.isEmpty) {
      setState(() { _errorMessage = 'Please enter your email address.'; });
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _loginEmailController.text.trim());
      setState(() { _errorMessage = 'Password reset email has been sent.'; });
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message; });
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7B5AFF), Color(0xFF5C258D)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Placeholder for phone image
                    Container(
                      width: 220,
                      height: 400,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(32),
                      ),
                      child: const Icon(Icons.phone_android, size: 120, color: Colors.white54),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'xxx',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        labelColor: Colors.deepPurple,
                        unselectedLabelColor: Colors.white,
                        tabs: const [
                          Tab(text: 'Sign Up'),
                          Tab(text: 'Login'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.6,
                      ),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            RegisterForm(
                              formKey: _registerFormKey,
                              nameController: _nameController,
                              emailController: _registerEmailController,
                              passwordController: _registerPasswordController,
                              isLoading: _isLoading,
                              onRegister: _register,
                              onGoogleSignIn: _signInWithGoogle,
                              googleButtonLabel: 'Sign in with Google',
                              googleIcon: const SizedBox.shrink(),
                            ),
                            LoginForm(
                              formKey: _loginFormKey,
                              emailController: _loginEmailController,
                              passwordController: _loginPasswordController,
                              isLoading: _isLoading,
                              onLogin: _login,
                              onGoogleSignIn: _signInWithGoogle,
                              onForgotPassword: _forgotPassword,
                              googleIcon: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(color: Colors.white),
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