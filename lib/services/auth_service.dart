import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final String _baseUrl = 'https://finance-flow-server-jjob.onrender.com/api';

  Stream<User?> get authStateChanges => _auth.userChanges();

  Future<void> updatePhoto(Uint8List bytes, String fileName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Extract file extension and determine correct content type
    final extension = fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
    
    debugPrint('Express Server: Attempting photo upload to MongoDB...');
    
    try {
      final token = await user.getIdToken();
      final response = await http.post(
        Uri.parse('$_baseUrl/users/profile-photo'),
        headers: {
          'Content-Type': mimeType,
          if (token != null) 'Authorization': 'Bearer $token',
          'x-user-id': user.uid, // Bypass header for local dev
        },
        body: bytes,
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception('Server rejected upload (Status ${response.statusCode}): ${response.body}');
      }

      final responseData = json.decode(response.body);
      final photoUrl = responseData['photoUrl'] as String;
      
      debugPrint('Express Server: Upload successful! Photo URL: $photoUrl');
      
      await user.updatePhotoURL(photoUrl);
      await user.reload();
    } catch (e, stack) {
      debugPrint('Express/MongoDB upload ERROR: $e');
      debugPrint('StackTrace: $stack');
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
