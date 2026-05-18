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
      data: (user) {
        final displayName = user?.displayName;
        final initials = (displayName != null && displayName.isNotEmpty)
            ? displayName[0].toUpperCase()
            : 'U';
        return Scaffold(
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
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(60),
                        child: Stack(
                          children: [
                            // Base profile/initials or image
                            if (user?.photoURL != null)
                              Image.network(
                                user!.photoURL!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    color: AppColors.primary.withValues(alpha: 0.05),
                                    child: const Center(
                                      child: CircularProgressIndicator.adaptive(),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  // Fallback to initials if the NetworkImage fails (e.g. CORS block)
                                  return Container(
                                    width: 120,
                                    height: 120,
                                    color: AppColors.primary.withValues(alpha: 0.1),
                                    alignment: Alignment.center,
                                    child: Text(
                                      initials,
                                      style: const TextStyle(
                                        fontSize: 40,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                width: 120,
                                height: 120,
                                color: AppColors.primary.withValues(alpha: 0.1),
                                alignment: Alignment.center,
                                child: Text(
                                  initials,
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            
                            // Uploading Overlay
                            if (_isPhotoLoading)
                              Container(
                                width: 120,
                                height: 120,
                                color: Colors.black.withValues(alpha: 0.4),
                                child: const Center(
                                  child: CircularProgressIndicator.adaptive(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isPhotoLoading ? null : _pickImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
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
                    ? const CircularProgressIndicator.adaptive(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
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
      );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator.adaptive())),
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
