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

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _registerFormKey = GlobalKey<FormState>();
  final _loginFormKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _registerEmailController =
      TextEditingController();
  final TextEditingController _registerPasswordController =
      TextEditingController();
  final TextEditingController _loginEmailController = TextEditingController();
  final TextEditingController _loginPasswordController =
      TextEditingController();
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      debugPrint('Attempting to register user...');
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _registerEmailController.text.trim(),
            password: _registerPasswordController.text.trim(),
          );
      debugPrint('User registered: ${credential.user?.uid}');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(credential.user!.uid)
          .set({
            'name': _nameController.text.trim(),
            'email': _registerEmailController.text.trim(),
            'createdAt': FieldValue.serverTimestamp(),
          });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      if (mounted) {
        debugPrint('Navigating to mood selection...');
        Navigator.pushReplacementNamed(context, AppRoutes.moodSelection);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Register error: ${e.code} - ${e.message}');
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      debugPrint('Register unknown error: ${e.toString()}');
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _login() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _loginEmailController.text.trim(),
        password: _loginPasswordController.text.trim(),
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.moodSelection);
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? accessToken = googleAuth.accessToken;
      final String? idToken = googleAuth.idToken;
      if (accessToken == null || idToken == null) {
        setState(() {
          _errorMessage = 'Signing in with Google failed.';
          _isLoading = false;
        });
        return;
      }
      final credential = GoogleAuthProvider.credential(
        accessToken: accessToken,
        idToken: idToken,
      );
      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );
      final user = userCredential.user;
      if (user == null) {
        setState(() {
          _errorMessage = 'Login with Firebase failed.';
        });
        return;
      }
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      final docSnap = await userDoc.get();
      if (!docSnap.exists) {
        await userDoc.set({
          'name': user.displayName ?? '',
          'email': user.email ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.moodSelection);
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'There was an error logging in with Google.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _forgotPassword() async {
    if (_loginEmailController.text.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter your email address.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _loginEmailController.text.trim(),
      );
      setState(() {
        _errorMessage = 'Password reset email has been sent.';
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/presentation/assets/na_background_1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 24.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Center(
                  child: Image.asset(
                    'lib/presentation/assets/logo.png',
                    height: 120,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('lib/presentation/assets/Button.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Text(
                    'Your personalized AI helper for ADHD.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Color.fromARGB(255, 0, 0, 0),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                DefaultTabController(
                  length: 2,
                  initialIndex: _tabController.index,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withAlpha(30),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            color: theme.colorScheme.primary.withAlpha(30),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: theme.colorScheme.primary,
                          unselectedLabelColor:
                              theme.textTheme.bodyMedium?.color,
                          tabs: const [
                            Tab(text: 'Sign Up'),
                            Tab(text: 'Sign In'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withAlpha(40),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.shadowColor.withAlpha(10),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 24,
                          horizontal: 16,
                        ),
                        child: SizedBox(
                          height: 400,
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
                                googleButtonLabel: 'Sign up with Google',
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
                    ],
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                if (_isLoading)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
