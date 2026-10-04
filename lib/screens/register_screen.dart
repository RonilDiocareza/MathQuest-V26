                                    import 'package:flutter/material.dart';
import '../game/player.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/math_background.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _lrnController;
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  bool _isLoading = false;
  String? _selectedCharacter = 'boy';

  @override
  void initState() {
    super.initState();
    _lrnController = TextEditingController();
    _nameController = TextEditingController();
    _addressController = TextEditingController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _lrnController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_selectedCharacter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please choose a character before registering.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      // Check password match
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('❌ Passwords do not match!'),
              backgroundColor: Colors.red),
        );
        return;
      }

      setState(() => _isLoading = true);

      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();

      try {
        await AuthService.register(
          email: email,
          password: password,
          name: _nameController.text.trim(),
          address: _addressController.text.trim(),
          lrn: _lrnController.text.trim(),
          character: _selectedCharacter!,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('✅ Account created. Wait for admin approval.'),
                backgroundColor: Colors.green),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
          );
        }
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MathBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.person_add,
                        size: 100, color: Colors.white),
                    const SizedBox(height: 30),
                    const Text(
                      'MathQuest',
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 40),
                    const Text(
                      'CREATE ACCOUNT',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Choose Your Character',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildCharacterOption(
                            id: 'boy',
                            label: 'BOY',
                            asset: Player.boySpriteAssetPath,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildCharacterOption(
                            id: 'girl',
                            label: 'GIRL',
                            asset: Player.girlSpriteAssetPath,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    CustomTextField(
                      hint: 'LRN (12 digits)',
                      controller: _lrnController,
                      keyboardType: TextInputType.number,
                      validator: (value) =>
                          value!.length != 12 ? 'LRN must be 12 digits' : null,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hint: 'Full Name',
                      controller: _nameController,
                      validator: (value) =>
                          value!.isEmpty ? 'Name is required' : null,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hint: 'Address',
                      controller: _addressController,
                      validator: (value) =>
                          value!.isEmpty ? 'Address is required' : null,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hint: 'Email',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) =>
                          value!.isEmpty ? 'Email is required' : null,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hint: 'Password',
                      controller: _passwordController,
                      obscure: true,
                      validator: (value) => value!.length < 6
                          ? 'Password must be 6+ characters'
                          : null,
                    ),
                    const SizedBox(height: 15),
                    CustomTextField(
                      hint: 'Confirm Password',
                      controller: _confirmPasswordController,
                      obscure: true,
                      validator: (value) =>
                          value!.isEmpty ? 'Please confirm password' : null,
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 300,
                      child: CustomButton(
                        text: _isLoading
                            ? 'Creating Account...'
                            : 'CREATE ACCOUNT',
                        onPressed: _isLoading ? null : _register,
                      ),
                    ),
                    const SizedBox(height: 25),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Already have account? Login',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.blueAccent,
                            decoration: TextDecoration.underline),
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

  Widget _buildCharacterOption({
    required String id,
    required String label,
    required String asset,
  }) {
    final isSelected = _selectedCharacter == id;

    return Semantics(
      button: true,
      selected: isSelected,
      label: '$label character${isSelected ? ', selected' : ''}',
      child: Material(
        color: isSelected
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => setState(() => _selectedCharacter = id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.amberAccent : Colors.white54,
                width: isSelected ? 3 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 96,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final frameAspectRatio = id == 'boy' ? 2 / 3 : 1.0;
                      final imageHeight = constraints.maxHeight.clamp(
                        0.0,
                        constraints.maxWidth / frameAspectRatio,
                      );
                      final imageWidth = imageHeight * frameAspectRatio;
                      return Center(
                        child: SizedBox(
                          width: imageWidth,
                          height: imageHeight,
                          child: ClipRect(
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              minWidth: 0,
                              maxWidth: imageWidth * 6,
                              minHeight: 0,
                              maxHeight: imageHeight * 4,
                              child: Image.asset(
                                asset,
                                width: imageWidth * 6,
                                height: imageHeight * 4,
                                fit: BoxFit.fill,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.check_circle,
                        color: Colors.amberAccent,
                        size: 18,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
