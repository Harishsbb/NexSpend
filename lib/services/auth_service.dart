import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<User?> get authStateChanges => _auth.userChanges();

  Future<void> updatePhoto(Uint8List bytes, String fileName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Extract file extension and determine correct content type
    final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
    
    // Construct a clean, timestamped filename inside the user's subfolder
    final cleanFileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.$extension';
    final ref = _storage.ref().child('user_photos').child(user.uid).child(cleanFileName);

    print('Firebase Storage: Attempting upload to bucket: ${_storage.app.options.storageBucket}');
    print('Firebase Storage: Full path: ${ref.fullPath}');
    
    try {
      // Upload with content type metadata and a 15-second timeout to prevent silent hangs on CORS/network errors
      final snapshot = await ref.putData(
        bytes,
        SettableMetadata(contentType: mimeType),
      ).timeout(const Duration(seconds: 15));

      if (snapshot.state != TaskState.success) {
        throw FirebaseException(
          plugin: 'firebase_storage',
          code: 'upload-failed',
          message: 'Upload did not complete successfully (state: ${snapshot.state})',
        );
      }

      // Use the original ref (not snapshot.ref) to get download URL
      final url = await ref.getDownloadURL();
      print('Firebase Storage: Upload successful! Download URL: $url');
      
      await user.updatePhotoURL(url);
      await user.reload();
    } on FirebaseException catch (e, stack) {
      print('Firebase Storage ERROR: [${e.code}] ${e.message}');
      print('Firebase Storage StackTrace: $stack');
      rethrow;
    } catch (e, stack) {
      print('General ERROR during photo upload: $e');
      print('StackTrace: $stack');
      rethrow;
    }
  }

  Future<UserCredential?> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      return credential;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserCredential?> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProfile(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
    await _auth.currentUser?.reload();
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
