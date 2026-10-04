import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/profile_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onClose;
  final bool isDialog;

  const ProfileScreen({super.key, this.onClose, this.isDialog = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late ProfileService _profileService;

  String _userName = '';
  String _userEmail = '';
  String _userLRN = '';
  String _userAddress = '';
  String _userRole = '';
  Uint8List? _profilePhoto;
  bool _isEditing = false;
  bool _isDialogOpen = false;

  late TextEditingController _nameController;
  late TextEditingController _lrnController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _profileService = ProfileService();
    _nameController = TextEditingController();
    _lrnController = TextEditingController();
    _addressController = TextEditingController();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profile = await _profileService.loadProfile();
    final photoFile = await _profileService.getProfilePhoto();

    if (!mounted) return;

    setState(() {
      _userName = profile['name'] ?? '';
      _userEmail = profile['email'] ?? '';
      _userRole = profile['role'] ?? '';
      _userLRN = profile['lrn'] ?? '';
      _userAddress = profile['address'] ?? '';
      _profilePhoto = photoFile;

      _nameController.text = _userName;
      _lrnController.text = _userLRN;
      _addressController.text = _userAddress;
    });
  }

  Future<void> _pickProfilePhoto() async {
    final imagePicker = ImagePicker();
    final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      final photoBytes = await pickedFile.readAsBytes();
      final saved = await _profileService.saveProfilePhoto(photoBytes);
      if (saved && mounted) {
        setState(() {
          _profilePhoto = photoBytes;
        });
        // Photo is automatically saved to SharedPreferences via saveProfilePhoto()
        // No need to click Save Changes for the photo
      }
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter your name'),
            backgroundColor: Colors.red),
      );
      return;
    }

    await _profileService.saveProfile(
      name: _nameController.text,
      email: _userEmail,
      role: _userRole,
      lrn: _lrnController.text,
      address: _addressController.text,
    );

    if (!mounted) return;
    setState(() {
      _userName = _nameController.text;
      _userLRN = _lrnController.text;
      _userAddress = _addressController.text;
      _isEditing = false;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green),
    );
  }

  void _logout() {
    if (_isDialogOpen) return; // Prevent multiple dialogs

    _isDialogOpen = true;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _isDialogOpen = false;
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _profileService.clearProfile();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileContent = Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            decoration: BoxDecoration(
              color: const Color(0xFFF3D5AA),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 26),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      if (_isEditing)
                        TextButton(
                          onPressed: () {
                            setState(() => _isEditing = false);
                            _nameController.text = _userName;
                            _lrnController.text = _userLRN;
                            _addressController.text = _userAddress;
                          },
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                                color: Colors.red, fontWeight: FontWeight.bold),
                          ),
                        )
                      else
                        const SizedBox(width: 24),
                      GestureDetector(
                        onTap:
                            widget.onClose ?? () => Navigator.maybePop(context),
                        child: const Icon(Icons.close,
                            size: 24, color: Color(0xFF2B3B5A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Profile Photo
                  GestureDetector(
                    onTap: _isEditing ? _pickProfilePhoto : null,
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: const Color(0xFFECB56E),
                          backgroundImage: _profilePhoto != null
                              ? MemoryImage(_profilePhoto!)
                              : null,
                          child: _profilePhoto == null
                              ? Text(
                                  _userName.isEmpty
                                      ? 'S'
                                      : _userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        if (_isEditing)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF2E7D32),
                                shape: BoxShape.circle,
                                border:
                                    Border.all(color: Colors.white, width: 2),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 18),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Display name or edit field
                  if (_isEditing)
                    TextField(
                      controller: _nameController,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B3B5A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter your name',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    )
                  else
                    Text(
                      _userName.isEmpty ? 'Your Profile' : _userName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2B3B5A),
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Info fields
                  _buildInfoRow('Email', _userEmail, readOnly: true),
                  const SizedBox(height: 12),
                  _buildInfoRow('Grade',
                      _userRole.isEmpty ? 'N/A' : _userRole.toUpperCase(),
                      readOnly: true),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    _buildEditableField('LRN', _lrnController)
                  else
                    _buildInfoRow('LRN', _userLRN),
                  const SizedBox(height: 12),
                  if (_isEditing)
                    _buildEditableField('Address', _addressController)
                  else
                    _buildInfoRow('Address', _userAddress),
                  const SizedBox(height: 26),
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _saveProfile,
                        child: const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => setState(() => _isEditing = true),
                            child: const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _logout,
                            child: const Text(
                              'Logout',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: widget.onClose ??
                                () => Navigator.maybePop(context),
                            child: const Text(
                              'Close',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    if (widget.isDialog) {
      return profileContent;
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F2847),
      body: SafeArea(
        child: profileContent,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool readOnly = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isEmpty ? 'N/A' : value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBBBBB), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
            ),
          ),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              isDense: true,
              hintText: 'Enter $label',
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lrnController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
