import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/math_background.dart';
import 'admin_dashboard_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final inputEmail = _emailController.text.trim().toLowerCase();
      final inputPassword = _passwordController.text.trim();

      try {
        final account = await AuthService.signIn(inputEmail, inputPassword);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_user_email', account.email);
        await prefs.setString('current_user_name', account.name);
        await prefs.setString('current_user_role', account.role);
        await prefs.setString('current_user_lrn', account.lrn);
        await prefs.setString('current_user_address', account.address);

        if (mounted) {
          if (account.isAdmin) {
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen()));
          } else {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomeScreen()));
          }
        }
      } catch (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_loginErrorMessage(error)),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _loginErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'invalid-credential' ||
        'user-not-found' ||
        'wrong-password' =>
          'Email or password is incorrect.',
        'user-disabled' => 'This account is disabled. Please contact support.',
        'too-many-requests' =>
          'Too many attempts. Please wait a moment and try again.',
        'network-request-failed' =>
          'Unable to connect. Check your internet connection and try again.',
        _ => 'Unable to sign in right now. Please try again.',
      };
    }
    if (error is StateError &&
        error.message == 'Account pending admin approval.') {
      return 'Your account is waiting for admin approval.';
    }
    return 'Unable to sign in right now. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MathBackground(
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(30),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        minHeight: MediaQuery.of(context).size.height - 60),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/Icon/Icon.png',
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 50),
                          Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'LOGIN',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 30),
                                CustomTextField(
                                  hint: 'Email',
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 20),
                                CustomTextField(
                                  hint: 'Password',
                                  controller: _passwordController,
                                  obscure: true,
                                ),
                                const SizedBox(height: 30),
                                SizedBox(
                                  width: 250,
                                  child: CustomButton(
                                    text:
                                        _isLoading ? 'Logging in...' : 'LOG IN',
                                    onPressed: _isLoading ? null : _login,
                                  ),
                                ),
                                const SizedBox(height: 30),
                                const Text(
                                  'NEW USER?',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 14, color: Colors.white70),
                                ),
                                const SizedBox(height: 10),
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen()),
                                    ),
                                    child: const Text(
                                      'Create Account',
                                      style: TextStyle(
                                          fontSize: 18,
                                          color: Colors.blueAccent,
                                          decoration: TextDecoration.underline),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
