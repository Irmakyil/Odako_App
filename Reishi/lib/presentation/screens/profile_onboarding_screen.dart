import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';

class ProfileOnboardingScreen extends StatefulWidget {
  const ProfileOnboardingScreen({super.key});

  @override
  State<ProfileOnboardingScreen> createState() => _ProfileOnboardingScreenState();
}

class _ProfileOnboardingScreenState extends State<ProfileOnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isLoading = false;

  String _username = '';
  int _age = 20;
  String? _gender;
  String? _adhdType;

  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email != null) {
      final emailPrefix = user!.email!.split('@').first;
      _username = emailPrefix;
      _usernameController.text = emailPrefix;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _setLoading(bool val) => setState(() => _isLoading = val);
  void _setCurrentPage(int i) => setState(() => _currentPage = i);
  void _setUsername(String val) => setState(() => _username = val);
  void _setGender(String val) => setState(() => _gender = val);
  void _setAdhdType(String val) => setState(() => _adhdType = val);
  void _setAge(double val) => setState(() => _age = val.round());

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.animateToPage(_currentPage + 1, duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }

  bool get _canGoNext {
    switch (_currentPage) {
      case 0: return _username.trim().isNotEmpty;
      case 1: return _gender != null;
      case 2: return _adhdType != null;
      default: return false;
    }
  }

  Future<void> _finishOnboarding() async {
    _setLoading(true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No user logged in');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('profile')
          .doc('data')
          .set({
        'username': _username.trim(),
        'age': _age,
        'gender': _gender,
        'adhdType': _adhdType,
      }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.moodSelection);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!')));
    } catch (e) {
      debugPrint('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e')));
      }
    } finally {
      if (mounted) _setLoading(false);
    }
  }

  Widget _buildProgressDots(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: _currentPage == i ? 16 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == i ? theme.colorScheme.primary : Colors.white70,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _currentPage == i ? [BoxShadow(color: Colors.black26, blurRadius: 4)] : [],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernamePage(ThemeData theme) {
    return _buildPagePadding(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Choose a Username',
              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 28),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          TextField(
            controller: _usernameController,
            style: const TextStyle(color: Colors.white),
            decoration: _inputDecoration(theme, ''),
            onChanged: _setUsername,
            textInputAction: TextInputAction.done,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAgeGenderPage(ThemeData theme) {
    return _buildPagePadding(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Tell us more about you.',
              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Text('Age: $_age',
              style: theme.textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          Slider(
            value: _age.toDouble(),
            min: 10,
            max: 60,
            divisions: 50,
            label: _age.toString(),
            onChanged: _setAge,
            activeColor: theme.colorScheme.primary,
            inactiveColor: Colors.white38,
          ),
          const SizedBox(height: 24),
          Text('Gender', style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Male', 'Female', 'Other']
                .map((label) => _buildGenderButton(label, _iconForGender(label), theme))
                .toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildGenderButton(String label, IconData icon, ThemeData theme) {
    final selected = _gender == label;
    final primary = theme.colorScheme.primary;
    final color = selected ? primary : const Color.fromRGBO(255, 255, 255, 0.12);
    final borderColor = selected ? primary : Colors.white54;
    return GestureDetector(
      onTap: () => _setGender(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: selected ? [BoxShadow(color: primary, blurRadius: 8)] : [],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  IconData _iconForGender(String label) {
    switch (label) {
      case 'Male': return Icons.male;
      case 'Female': return Icons.female;
      default: return Icons.transgender;
    }
  }

  Widget _buildAdhdTypePage(ThemeData theme) {
    const types = ['Inattentive', 'Hyperactive-Impulsive', 'Combined', 'Not Sure'];
    return _buildPagePadding(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Select your ADHD type',
              style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 26),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: types.map((type) => _buildAdhdTypeCard(type, theme)).toList(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAdhdTypeCard(String type, ThemeData theme) {
    final selected = _adhdType == type;
    final primary = theme.colorScheme.primary;
    final color = selected ? primary : const Color.fromRGBO(255, 255, 255, 0.12);
    final borderColor = selected ? primary : Colors.white54;

    return GestureDetector(
      onTap: () => _setAdhdType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: selected ? [BoxShadow(color: primary, blurRadius: 8)] : [],
        ),
        child: Text(type, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 18)),
      ),
    );
  }

  Widget _buildBottomButton(ThemeData theme) {
    final isLast = _currentPage == 2;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: !_canGoNext || _isLoading ? null : (isLast ? _finishOnboarding : _nextPage),
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          child: _isLoading
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(isLast ? 'Finish' : 'Next'),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, String hint) {
    return InputDecoration(
      filled: true,
      fillColor: const Color.fromRGBO(255, 255, 255, 0.15),
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Colors.white70)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: const BorderSide(color: Colors.white54)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide(color: theme.colorScheme.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Widget _buildPagePadding({required Widget child}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Stack(
                children: [
                  Image.asset('lib/presentation/assets/background.png', fit: BoxFit.cover, width: double.infinity, height: double.infinity),
                  Container(color: const Color.fromRGBO(0, 0, 0, 0.45)),
                ],
              ),
            ),
            Positioned.fill(
              child: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _setCurrentPage,
                      children: [
                        _buildUsernamePage(theme),
                        _buildAgeGenderPage(theme),
                        _buildAdhdTypePage(theme),
                      ],
                    ),
                  ),
                  _buildProgressDots(theme),
                  _buildBottomButton(theme),
                ],
              ),
            ),
            if (_isLoading)
              Container(
                color: const Color.fromRGBO(0, 0, 0, 0.2),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}