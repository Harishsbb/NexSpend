import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'package:file_picker/file_picker.dart' as fp;

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  late TextEditingController _nameController;
  final _auth = FirebaseAuth.instance;
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isPhotoLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _auth.currentUser?.displayName ?? '');
  }

  Future<void> _pickImage() async {
    final result = await fp.FilePicker.pickFiles(
      type: fp.FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final bytes = file.bytes;
      
      if (bytes != null) {
        setState(() => _isPhotoLoading = true);
        try {
          await ref.read(authServiceProvider).updatePhoto(bytes, file.name);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated!')),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Upload failed: $e')),
            );
          }
        } finally {
          if (mounted) setState(() => _isPhotoLoading = false);
        }
      }
    }
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).updateProfile(_nameController.text.trim());
      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(authStateProvider);

    return userAsync.when(
      data: (user) => Scaffold(
        appBar: AppBar(
          title: const Text('My Profile'),
          actions: [
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => setState(() => _isEditing = true),
              )
            else
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _isEditing = false;
                  _nameController.text = user?.displayName ?? '';
                }),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      backgroundImage: user?.photoURL != null 
                        ? NetworkImage(user!.photoURL!) 
                        : null,
                      child: (user?.photoURL == null && !_isPhotoLoading)
                        ? Text(
                            (user?.displayName ?? 'U').isNotEmpty 
                              ? user!.displayName![0].toUpperCase() 
                              : 'U',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                          )
                        : _isPhotoLoading 
                          ? const CircularProgressIndicator() 
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              _buildInfoCard(
                'Full Name',
                _isEditing 
                  ? TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Enter your name'),
                    )
                  : Text(user?.displayName ?? 'Not set', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'Email Address',
                Text(user?.email ?? 'Not set', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              _buildInfoCard(
                'User ID (UID)',
                SelectableText(user?.uid ?? 'Not available', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                Icons.fingerprint,
              ),
              const SizedBox(height: 48),
              if (_isEditing)
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleUpdate,
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Changes'),
                ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                  }
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Colors.red),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }

  Widget _buildInfoCard(String label, Widget content, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                content,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
